#!/usr/bin/env python3
"""A5: prove a built XMCP binary starts and speaks MCP.

    python3 probe-handshake.py "<path to XMCP or XMCP.exe>" [--call get_project_info]

Exits 0 on a serverInfo reply, 1 otherwise. Works on macOS and Windows.
The server does not exit when stdin closes, so this kills it rather than
leaving a stray process behind.
"""
import json, subprocess, sys, threading, time

if len(sys.argv) < 2:
    print(__doc__); sys.exit(2)
binary = sys.argv[1]
call = sys.argv[sys.argv.index("--call") + 1] if "--call" in sys.argv else None

# A4 first: a file that is not an executable cannot answer anything, and the
# OS error for that ("Permission denied") does not explain why.
import os
if not os.path.exists(binary):
    print(f"FAIL (A4): no such file: {binary}"); sys.exit(1)
with open(binary, "rb") as fh:
    magic = fh.read(4)
MACHO = {b"\xcf\xfa\xed\xfe", b"\xce\xfa\xed\xfe", b"\xca\xfe\xba\xbe", b"\xbe\xba\xfe\xca"}
if magic[:2] == b"MZ":
    pass                                  # Windows PE
elif magic in MACHO:
    pass                                  # Mach-O, thin or universal
else:
    size = os.path.getsize(binary)
    print(f"FAIL (A4): {binary} is not an executable ({size} bytes, starts {magic!r}).")
    try:
        head = open(binary, "r", errors="replace").read(120).replace("\n", " ")
        print(f"          It looks like text: {head!r}")
        print("          On macOS Universal builds a CopyFilesBuildStep overwrites the")
        print("          binary with a copied file. Build build_type 24 or 16 instead.")
    except Exception:
        pass
    sys.exit(1)
if not os.access(binary, os.X_OK):
    print(f"FAIL (A4): {binary} is not marked executable."); sys.exit(1)

try:
    p = subprocess.Popen([binary], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE, text=True, bufsize=1)
except OSError as e:
    print(f"FAIL: cannot start {binary}: {e}"); sys.exit(1)

out = []
threading.Thread(target=lambda: [out.append(l.strip()) for l in p.stdout], daemon=True).start()

def send(o):
    p.stdin.write(json.dumps(o) + "\n"); p.stdin.flush()

send({"jsonrpc": "2.0", "id": 1, "method": "initialize",
      "params": {"protocolVersion": "2024-11-05", "capabilities": {},
                 "clientInfo": {"name": "probe", "version": "1"}}})
want = 1
if call:
    time.sleep(2)
    send({"jsonrpc": "2.0", "id": 2, "method": "tools/call",
          "params": {"name": call, "arguments": {}}})
    want = 2

deadline = time.time() + 25
while time.time() < deadline and len(out) < want:
    time.sleep(0.5)
p.kill()

ok = False
for line in out:
    try: d = json.loads(line)
    except ValueError: print("RAW:", line[:200]); continue
    if d.get("id") == 1:
        si = d.get("result", {}).get("serverInfo")
        print("A5 handshake:", si if si else d); ok = bool(si)
    elif d.get("id") == 2:
        c = d.get("result", {}).get("content", [{}])
        print("A6 tools/call:", (c[0].get("text", "") if c else str(d))[:300].replace("\n", " | "))

if not out:
    print("FAIL: no response at all")
err = p.stderr.read()[:400]
if err: print("--- stderr ---\n" + err)
sys.exit(0 if ok else 1)
