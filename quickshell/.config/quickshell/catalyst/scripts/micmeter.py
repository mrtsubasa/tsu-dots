#!/usr/bin/env python3
"""Tsubasa Catalyst — vumètre micro (local, rien n'est enregistré).

  micmeter.py [cible]   imprime le niveau crête 0..1 toutes les 50 ms

Lit 16 kHz mono via pw-record depuis la source PipeWire donnée (ou la source
par défaut). Le processus ne tourne que pendant que le vumètre est affiché.
"""
import array
import subprocess
import sys

RATE = 16000
CHUNK = RATE // 20  # 50 ms

cmd = ["pw-record", "--rate", str(RATE), "--channels", "1", "--format", "s16",
       "-P", "{ node.name = catalyst_micmeter }"]
if len(sys.argv) > 1 and sys.argv[1]:
    cmd += ["--target", sys.argv[1]]
cmd.append("-")

proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
try:
    while True:
        buf = proc.stdout.read(CHUNK * 2)
        if not buf:
            break
        samples = array.array("h", buf[: len(buf) // 2 * 2])
        peak = max((abs(x) for x in samples), default=0) / 32768.0
        print(f"{peak:.3f}", flush=True)
except (KeyboardInterrupt, BrokenPipeError):
    pass
finally:
    proc.terminate()
