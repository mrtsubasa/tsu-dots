#!/usr/bin/env python3
"""
cam_scene.py — compositeur de scène pour la caméra virtuelle.

Assemble plusieurs calques (webcam, écrans via wf-recorder, images), chacun avec
sa position, son filtre et ses réglages, puis réémet le résultat vers la caméra
virtuelle via un pipe ffmpeg. La scène (JSON) est relue à chaud : le panneau la
modifie sans couper le flux. Une source n'est capturée que si un calque visible
l'utilise (scène sans webcam = webcam éteinte).

Lancé par cam-filter.sh (preset « scene »).

  cam_scene.py <webcam> <sink> <scene.json> <preview.jpg>

Calque : { id, source: "cam" | "screen:<sortie>" | "image:<chemin>", visible,
           x, y, w, h (0..1), fit: "cover"|"contain", filter, brightness (-1..1),
           contrast (0..2), saturation (0..2), opacity (0..1), radius (0..0.5),
           mirror, cutout }
"""
import ctypes
import json
import os
import signal
import subprocess
import sys
import threading
import time

import cv2
import numpy as np

HOME = os.path.expanduser("~")
MODEL = os.path.join(HOME, ".config/quickshell/catalyst/scripts/models/selfie.onnx")

SRC = sys.argv[1] if len(sys.argv) > 1 else "/dev/video1"
SINK = sys.argv[2] if len(sys.argv) > 2 else "/dev/video0"
SCENE = sys.argv[3] if len(sys.argv) > 3 else os.path.join(HOME, ".local/share/catalyst/cam-scene.json")
PREVIEW = sys.argv[4] if len(sys.argv) > 4 else ""

OW, OH = 1280, 720
FPS = 30
SCREEN_FPS = 20
PREVIEW_EVERY = 0.2
SEG = 256              # taille d'entrée du modèle de détourage

DEFAULT_SCENE = {"layers": [{"id": "cam", "source": "cam", "x": 0, "y": 0, "w": 1, "h": 1}]}
ANIMATED = {"vhs", "glitch"}


def _die_with_parent():
    # le capteur d'écran ne doit jamais survivre au compositeur
    ctypes.CDLL("libc.so.6").prctl(1, signal.SIGTERM)


# ---- sources ----------------------------------------------------------------
class Feed(threading.Thread):
    """Source en arrière-plan : garde la dernière image et un compteur."""

    def __init__(self):
        super().__init__(daemon=True)
        self.frame = None
        self.seq = 0
        self.alive = True

    def publish(self, frame):
        self.frame = frame
        self.seq += 1

    def close(self):
        self.alive = False


class CamFeed(Feed):
    def run(self):
        while self.alive:
            cap = cv2.VideoCapture(SRC, cv2.CAP_V4L2)
            cap.set(cv2.CAP_PROP_FOURCC, cv2.VideoWriter_fourcc(*"MJPG"))
            cap.set(cv2.CAP_PROP_FRAME_WIDTH, OW)
            cap.set(cv2.CAP_PROP_FRAME_HEIGHT, OH)
            cap.set(cv2.CAP_PROP_FPS, FPS)
            while self.alive:
                ok, frame = cap.read()
                if not ok:
                    break
                self.publish(frame)
            cap.release()
            if self.alive:
                time.sleep(1)


class ScreenFeed(Feed):
    def __init__(self, output):
        super().__init__()
        self.output = output
        self.proc = None

    def size(self):
        out = subprocess.run(["hyprctl", "monitors", "-j"], capture_output=True, text=True, check=False)
        for m in json.loads(out.stdout or "[]"):
            if m.get("name") == self.output:
                w, h = m["width"], m["height"]
                if m.get("transform", 0) % 2:
                    w, h = h, w
                return OW, 2 * round(OW * h / w / 2)
        return None

    def run(self):
        while self.alive:
            try:
                size = self.size()
            except (OSError, ValueError, KeyError):
                size = None
            if size is None:      # écran débranché : on réessaie
                time.sleep(2)
                continue
            w, h = size
            length = w * h * 3
            self.proc = subprocess.Popen(
                ["wf-recorder", "-y", "-o", self.output, "-m", "rawvideo", "-c", "rawvideo",
                 "-x", "bgr24", "-F", f"scale={w}:{h},fps={SCREEN_FPS}", "-f", "/dev/stdout"],
                stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, preexec_fn=_die_with_parent)
            while self.alive:
                buf = bytearray(length)
                view = memoryview(buf)
                got = 0
                while got < length:
                    n = self.proc.stdout.readinto(view[got:])
                    if not n:
                        break
                    got += n
                if got < length:
                    break
                self.publish(np.frombuffer(buf, np.uint8).reshape(h, w, 3))
            self.stop_proc()
            if self.alive:
                time.sleep(1)

    def stop_proc(self):
        if self.proc:
            self.proc.terminate()
            try:
                self.proc.wait(timeout=2)
            except subprocess.TimeoutExpired:
                self.proc.kill()
            self.proc = None

    def close(self):
        super().close()
        self.stop_proc()


class ImageFeed(Feed):
    def __init__(self, path):
        super().__init__()
        self.path = path

    def run(self):
        img = cv2.imread(self.path, cv2.IMREAD_COLOR)
        if img is None:
            print("image illisible:", self.path, file=sys.stderr)
            return
        s = 1920 / max(img.shape[:2])
        if s < 1:
            img = cv2.resize(img, None, fx=s, fy=s, interpolation=cv2.INTER_AREA)
        self.publish(img)


def make_feed(source):
    if source == "cam":
        return CamFeed()
    if source.startswith("screen:"):
        return ScreenFeed(source[7:])
    if source.startswith("image:"):
        return ImageFeed(source[6:])
    return None


# ---- filtres ----------------------------------------------------------------
def rgb_split(img, d):
    b, g, r = cv2.split(img)
    return cv2.merge((np.roll(b, -d, axis=1), g, np.roll(r, d, axis=1)))


def edges(img, block=9, c=4):
    gray = cv2.medianBlur(cv2.cvtColor(img, cv2.COLOR_BGR2GRAY), 5)
    return cv2.adaptiveThreshold(gray, 255, cv2.ADAPTIVE_THRESH_MEAN_C, cv2.THRESH_BINARY, block, c)


def posterize(img, levels=5):
    step = 256 // levels
    return (img // step * step + step // 2).astype(np.uint8)


def scanlines(img, strength=0.72):
    out = img.copy()
    out[::3] = (out[::3] * strength).astype(np.uint8)
    return out


def adjust(img, brightness=0.0, contrast=1.0, saturation=1.0):
    if saturation != 1.0:
        hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV).astype(np.float32)
        hsv[..., 1] = np.clip(hsv[..., 1] * saturation, 0, 255)
        img = cv2.cvtColor(hsv.astype(np.uint8), cv2.COLOR_HSV2BGR)
    if brightness != 0.0 or contrast != 1.0:
        img = cv2.convertScaleAbs(img, alpha=contrast, beta=128 * (1 - contrast) + 110 * brightness)
    return img


def f_noir(img, _t):
    return cv2.cvtColor(adjust(cv2.cvtColor(img, cv2.COLOR_BGR2GRAY), contrast=1.2), cv2.COLOR_GRAY2BGR)


def f_sepia(img, _t):
    return cv2.transform(img, np.array([[0.131, 0.534, 0.272], [0.168, 0.686, 0.349], [0.189, 0.769, 0.393]]))


def f_cyber(img, _t):
    return adjust(rgb_split(img, max(2, img.shape[1] // 160)), contrast=1.15, saturation=1.5)


def f_cartoon(img, _t):
    small = cv2.resize(img, None, fx=0.5, fy=0.5, interpolation=cv2.INTER_AREA)
    color = cv2.resize(cv2.bilateralFilter(small, 7, 60, 7), (img.shape[1], img.shape[0]))
    return cv2.bitwise_and(posterize(color, 8), posterize(color, 8), mask=edges(img, 13, 6))


def f_comic(img, _t):
    return cv2.bitwise_and(p := posterize(adjust(img, saturation=1.4), 4), p, mask=edges(img, 11, 5))


def f_manga(img, _t):
    return cv2.cvtColor(edges(img, 11, 5), cv2.COLOR_GRAY2BGR)


def f_neon(img, _t):
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    e = cv2.dilate(cv2.Canny(cv2.GaussianBlur(gray, (5, 5), 0), 40, 110), None)
    glow = cv2.applyColorMap(gray, cv2.COLORMAP_COOL)
    return cv2.add(cv2.bitwise_and(glow, glow, mask=e), cv2.GaussianBlur(cv2.bitwise_and(glow, glow, mask=e), (0, 0), 6))


def f_pixel(img, _t):
    h, w = img.shape[:2]
    small = cv2.resize(img, (max(1, w // 14), max(1, h // 14)), interpolation=cv2.INTER_AREA)
    return cv2.resize(small, (w, h), interpolation=cv2.INTER_NEAREST)


def f_vhs(img, t):
    out = scanlines(rgb_split(adjust(img, saturation=0.75), max(2, img.shape[1] // 200)), 0.8)
    y = int(t * 90) % out.shape[0]
    out[y:y + 8] = np.roll(out[y:y + 8], 18, axis=1)
    return out


def f_glitch(img, t):
    out = rgb_split(img, max(2, img.shape[1] // 120))
    rng = np.random.default_rng(int(t * 8))
    h = out.shape[0]
    for _ in range(6):
        y = int(rng.integers(0, h))
        band = int(rng.integers(4, 28))
        out[y:y + band] = np.roll(out[y:y + band], int(rng.integers(-60, 60)), axis=1)
    return out


def f_matrix(img, _t):
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    zero = np.zeros_like(gray)
    return scanlines(cv2.merge((zero, gray, (gray // 3))))


FILTERS = {
    "noir": f_noir,
    "sepia": f_sepia,
    "cyber": f_cyber,
    "thermal": lambda i, _t: cv2.applyColorMap(cv2.cvtColor(i, cv2.COLOR_BGR2GRAY), cv2.COLORMAP_INFERNO),
    "invert": lambda i, _t: cv2.bitwise_not(i),
    "blur": lambda i, _t: cv2.GaussianBlur(i, (0, 0), 9),
    "pixel": f_pixel,
    "poster": lambda i, _t: posterize(i, 4),
    "cartoon": f_cartoon,
    "comic": f_comic,
    "manga": f_manga,
    "neon": f_neon,
    "crt": lambda i, _t: scanlines(i),
    "vhs": f_vhs,
    "glitch": f_glitch,
    "matrix": f_matrix,
}


# ---- détourage (chargé seulement si un calque le demande) ---------------------
class Segmenter:
    def __init__(self):
        self.sess = None
        self.failed = False

    def mask(self, img):
        if self.failed:
            return None
        if self.sess is None:
            try:
                import onnxruntime as ort
                so = ort.SessionOptions()
                so.log_severity_level = 3
                self.sess = ort.InferenceSession(
                    MODEL, so, providers=["CUDAExecutionProvider", "CPUExecutionProvider"])
                self.name = self.sess.get_inputs()[0].name
            except Exception as e:  # pylint: disable=broad-except
                print("détourage indisponible:", e, file=sys.stderr)
                self.failed = True
                return None
        inp = cv2.cvtColor(cv2.resize(img, (SEG, SEG)), cv2.COLOR_BGR2RGB).astype(np.float32) / 255.0
        alpha = np.squeeze(self.sess.run(None, {self.name: np.transpose(inp, (2, 0, 1))[None]})[0])
        alpha = cv2.resize(alpha.astype(np.float32), (img.shape[1], img.shape[0]))
        return np.clip(cv2.GaussianBlur(alpha, (0, 0), 3.0), 0.0, 1.0)


# ---- composition ------------------------------------------------------------
def fit_frame(frame, w, h, mode):
    """Adapte l'image à la boîte. Retourne (image, masque de remplissage|None)."""
    fh, fw = frame.shape[:2]
    if mode == "contain":
        s = min(w / fw, h / fh)
        nw, nh = max(1, round(fw * s)), max(1, round(fh * s))
        small = cv2.resize(frame, (nw, nh), interpolation=cv2.INTER_AREA if s < 1 else cv2.INTER_LINEAR)
        out = np.zeros((h, w, 3), np.uint8)
        mask = np.zeros((h, w), np.float32)
        x, y = (w - nw) // 2, (h - nh) // 2
        out[y:y + nh, x:x + nw] = small
        mask[y:y + nh, x:x + nw] = 1.0
        return out, mask
    s = max(w / fw, h / fh)
    cw, ch = min(fw, round(w / s)), min(fh, round(h / s))
    x, y = (fw - cw) // 2, (fh - ch) // 2
    return cv2.resize(frame[y:y + ch, x:x + cw], (w, h), interpolation=cv2.INTER_AREA if s < 1 else cv2.INTER_LINEAR), None


def rounded_mask(w, h, frac, cache={}):  # pylint: disable=dangerous-default-value
    key = (w, h, round(frac, 3))
    if key not in cache:
        if len(cache) > 32:
            cache.clear()
        r = int(frac * min(w, h))
        m = np.zeros((h, w), np.uint8)
        cv2.rectangle(m, (r, 0), (w - r - 1, h - 1), 255, -1)
        cv2.rectangle(m, (0, r), (w - 1, h - r - 1), 255, -1)
        for cx, cy in ((r, r), (w - r - 1, r), (r, h - r - 1), (w - r - 1, h - r - 1)):
            cv2.circle(m, (cx, cy), r, 255, -1, cv2.LINE_AA)
        cache[key] = m.astype(np.float32) / 255.0
    return cache[key]


def render_layer(layer, frame, w, h, t, seg):
    if layer.get("mirror"):
        frame = cv2.flip(frame, 1)
    img, alpha = fit_frame(frame, w, h, layer.get("fit", "cover"))
    if layer.get("cutout"):
        cut = seg.mask(img)
        if cut is not None:
            alpha = cut if alpha is None else alpha * cut
    fn = FILTERS.get(layer.get("filter", "none"))
    if fn:
        img = fn(img, t)
    img = adjust(img, float(layer.get("brightness", 0)), float(layer.get("contrast", 1)),
                 float(layer.get("saturation", 1)))
    radius = float(layer.get("radius", 0))
    if radius > 0:
        m = rounded_mask(w, h, radius)
        alpha = m if alpha is None else alpha * m
    return img, alpha


def blend(canvas, img, alpha, opacity, px, py):
    h, w = img.shape[:2]
    x0, y0, x1, y1 = max(px, 0), max(py, 0), min(px + w, OW), min(py + h, OH)
    if x0 >= x1 or y0 >= y1:
        return
    part = img[y0 - py:y1 - py, x0 - px:x1 - px]
    if alpha is None and opacity >= 1:
        canvas[y0:y1, x0:x1] = part
        return
    a = np.full(part.shape[:2], opacity, np.float32) if alpha is None else alpha[y0 - py:y1 - py, x0 - px:x1 - px] * opacity
    a = a[..., None]
    canvas[y0:y1, x0:x1] = (part * a + canvas[y0:y1, x0:x1] * (1 - a)).astype(np.uint8)


def load_scene(previous):
    try:
        with open(SCENE, encoding="utf-8") as f:
            scene = json.load(f)
        return scene if isinstance(scene.get("layers"), list) else previous
    except (OSError, ValueError, AttributeError):
        return previous


def write_preview(canvas):
    ok, jpg = cv2.imencode(".jpg", cv2.resize(canvas, (640, 360), interpolation=cv2.INTER_AREA),
                           [cv2.IMWRITE_JPEG_QUALITY, 72])
    if ok:
        tmp = PREVIEW + ".tmp"
        with open(tmp, "wb") as f:
            f.write(jpg.tobytes())
        os.replace(tmp, PREVIEW)


def main():
    os.umask(0o077)       # l'aperçu peut montrer le contenu de l'écran
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))

    ff = subprocess.Popen(
        ["ffmpeg", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "bgr24",
         "-s", f"{OW}x{OH}", "-r", str(FPS), "-i", "-",
         "-f", "v4l2", "-pix_fmt", "yuyv422", SINK],
        stdin=subprocess.PIPE, preexec_fn=_die_with_parent)

    feeds = {}
    rendered = {}
    seg = Segmenter()
    scene = DEFAULT_SCENE
    mtime = None
    next_scene = next_preview = 0.0
    canvas = np.zeros((OH, OW, 3), np.uint8)
    start = time.monotonic()
    tick = start

    try:
        while True:
            now = time.monotonic()
            if now >= next_scene:
                next_scene = now + 0.15
                try:
                    m = os.stat(SCENE).st_mtime_ns
                except OSError:
                    m = None
                if m != mtime:
                    mtime = m
                    scene = load_scene(scene)

            layers = [l for l in scene["layers"] if l.get("visible", True) and l.get("source")]

            # n'ouvre que les sources réellement affichées
            wanted = {l["source"] for l in layers}
            for key in list(feeds):
                if key not in wanted:
                    feeds.pop(key).close()
            for key in wanted - feeds.keys():
                feed = make_feed(key)
                if feed:
                    feed.start()
                    feeds[key] = feed

            canvas[:] = (12, 10, 10)
            seen = set()
            for layer in layers:
                feed = feeds.get(layer["source"])
                if feed is None or feed.frame is None:
                    continue
                w = max(2, round(float(layer.get("w", 1)) * OW))
                h = max(2, round(float(layer.get("h", 1)) * OH))
                px = round(float(layer.get("x", 0)) * OW)
                py = round(float(layer.get("y", 0)) * OH)
                lid = layer.get("id", layer["source"])
                seen.add(lid)
                # image inchangée + filtre statique : pas de recalcul
                sig = (json.dumps(layer, sort_keys=True), feed.seq)
                hit = rendered.get(lid)
                if hit and hit[0] == sig and layer.get("filter") not in ANIMATED:
                    img, alpha = hit[1], hit[2]
                else:
                    img, alpha = render_layer(layer, feed.frame, w, h, now - start, seg)
                    rendered[lid] = (sig, img, alpha)
                blend(canvas, img, alpha, float(layer.get("opacity", 1)), px, py)
            for lid in list(rendered):
                if lid not in seen:
                    del rendered[lid]

            ff.stdin.write(canvas.tobytes())

            if PREVIEW and now >= next_preview:
                next_preview = now + PREVIEW_EVERY
                write_preview(canvas)

            tick = max(tick + 1 / FPS, time.monotonic() - 0.2)
            time.sleep(max(0.0, tick - time.monotonic()))
    except (BrokenPipeError, KeyboardInterrupt):
        pass
    finally:
        for feed in feeds.values():
            feed.close()
        if PREVIEW:
            try:
                os.remove(PREVIEW)
            except OSError:
                pass
        try:
            ff.stdin.close()
            ff.wait(timeout=2)
        except Exception:  # pylint: disable=broad-except
            ff.kill()
    return 0


if __name__ == "__main__":
    sys.exit(main())
