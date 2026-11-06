#!/bin/bash
sock="/tmp/${1:?panel}_ipc.sock"
shift
msg="${*:?}"
python3 - "$sock" "$msg" <<'PY'
import socket, sys
s = socket.socket(socket.AF_UNIX)
s.settimeout(1)
s.connect(sys.argv[1])
s.sendall(sys.argv[2].encode())
s.shutdown(socket.SHUT_WR)
s.close()
PY
