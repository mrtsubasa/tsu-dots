#!/usr/bin/env python3
"""
cam_anime.py — filtre « Anime IA » temps réel (AnimeGANv3, ONNX Runtime GPU).

Capture la webcam, passe chaque image dans le réseau AnimeGANv3 sur le GPU, et
réémet le flux stylisé vers la caméra virtuelle via un pipe ffmpeg (yuyv422).
Lancé par cam-filter.sh (preset « aianime ») avec le venv dédié et le
LD_LIBRARY_PATH cuDNN/cuBLAS positionnés.

  cam_anime.py [src] [sink] [model.onnx]
"""
import os
import subprocess
import sys

import cv2
import numpy as np
import onnxruntime as ort

HOME = os.path.expanduser("~")
MODELS = os.path.join(HOME, ".config/quickshell/catalyst/scripts/models")

SRC = sys.argv[1] if len(sys.argv) > 1 else "/dev/video1"
SINK = sys.argv[2] if len(sys.argv) > 2 else "/dev/video0"
MODEL = sys.argv[3] if len(sys.argv) > 3 else os.path.join(MODELS, "AnimeGANv3_Hayao_36.onnx")

IW, IH = 512, 288      # taille d'inférence (16:9, multiples de 8)
OW, OH = 1280, 720     # sortie webcam virtuelle
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
            small = cv2.resize(frame, (IW, IH))
            rgb = cv2.cvtColor(small, cv2.COLOR_BGR2RGB).astype(np.float32) / 127.5 - 1.0
            y = sess.run(None, {name: rgb[None]})[0]
            out = ((np.squeeze(y) + 1.0) / 2.0 * 255.0).clip(0, 255).astype(np.uint8)
            out = cv2.cvtColor(out, cv2.COLOR_RGB2BGR)
            out = cv2.resize(out, (OW, OH))
            ff.stdin.write(out.tobytes())
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
