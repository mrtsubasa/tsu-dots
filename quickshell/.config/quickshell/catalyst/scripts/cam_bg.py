#!/usr/bin/env python3
"""
cam_bg.py — fond flou / remplacé par IA, SANS fond vert (MediaPipe Selfie
Segmentation, ONNX Runtime GPU). Segmente la personne puis recompose sur un
fond flou (mode « blur ») ou sur une image choisie (mode « image »).

Lancé par cam-filter.sh (presets « bgblur » / « bgimage ») avec le venv dédié
et le LD_LIBRARY_PATH cuDNN/cuBLAS positionnés.

  cam_bg.py <src> <sink> <mode:blur|image> [image_de_fond]
"""
import os
import subprocess
import sys

import cv2
import numpy as np
import onnxruntime as ort

HOME = os.path.expanduser("~")
MODEL = os.path.join(HOME, ".config/quickshell/catalyst/scripts/models/selfie.onnx")

SRC = sys.argv[1] if len(sys.argv) > 1 else "/dev/video1"
SINK = sys.argv[2] if len(sys.argv) > 2 else "/dev/video0"
MODE = sys.argv[3] if len(sys.argv) > 3 else "blur"
BG = sys.argv[4] if len(sys.argv) > 4 else ""

OW, OH = 1280, 720
SEG = 256              # taille d'entrée du modèle
FPS = 30


def main():
    if not os.path.isfile(MODEL):
        print("modèle introuvable:", MODEL, file=sys.stderr)
        return 1

    so = ort.SessionOptions()
    so.log_severity_level = 3
    sess = ort.InferenceSession(
        MODEL, so, providers=["CUDAExecutionProvider", "CPUExecutionProvider"])
    name = sess.get_inputs()[0].name

    bg_img = None
    if MODE == "image" and BG and os.path.isfile(BG):
        b = cv2.imread(BG)
        if b is not None:
            bg_img = cv2.resize(b, (OW, OH))

    cap = cv2.VideoCapture(SRC, cv2.CAP_V4L2)
    cap.set(cv2.CAP_PROP_FOURCC, cv2.VideoWriter_fourcc(*"MJPG"))
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, OW)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, OH)
    cap.set(cv2.CAP_PROP_FPS, FPS)
    if not cap.isOpened():
        print("webcam non ouverte:", SRC, file=sys.stderr)
        return 1

    ff = subprocess.Popen(
        ["ffmpeg", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "bgr24",
         "-s", f"{OW}x{OH}", "-r", str(FPS), "-i", "-",
         "-f", "v4l2", "-pix_fmt", "yuyv422", SINK],
        stdin=subprocess.PIPE)

    try:
        while True:
            ok, frame = cap.read()
            if not ok:
                break
            if frame.shape[1] != OW or frame.shape[0] != OH:
                frame = cv2.resize(frame, (OW, OH))

            # masque de la personne
            inp = cv2.resize(frame, (SEG, SEG))
            inp = cv2.cvtColor(inp, cv2.COLOR_BGR2RGB).astype(np.float32) / 255.0
            inp = np.transpose(inp, (2, 0, 1))[None]
            alpha = np.squeeze(sess.run(None, {name: inp})[0])
            alpha = cv2.resize(alpha.astype(np.float32), (OW, OH))
            alpha = cv2.GaussianBlur(alpha, (0, 0), 3.0)   # adoucit les bords
            alpha = np.clip(alpha, 0.0, 1.0)[..., None]

            if bg_img is not None:
                back = bg_img
            else:
                back = cv2.GaussianBlur(frame, (0, 0), 15.0)

            comp = (frame.astype(np.float32) * alpha +
                    back.astype(np.float32) * (1.0 - alpha)).astype(np.uint8)
            ff.stdin.write(comp.tobytes())
    except (BrokenPipeError, KeyboardInterrupt):
        pass
    finally:
        cap.release()
        try:
            ff.stdin.close()
            ff.wait(timeout=2)
        except Exception:
            ff.kill()
    return 0


if __name__ == "__main__":
    sys.exit(main())
