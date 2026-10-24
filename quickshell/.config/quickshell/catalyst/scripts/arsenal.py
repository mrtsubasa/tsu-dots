#!/usr/bin/env python3
"""Tsubasa Catalyst — Arsenal : catalogue des outils de sécurité installés.

Construit (et met en cache) la liste de tes outils issus des groupes
BlackArch, avec catégorie(s) et description, à la manière du menu Kali/Parrot.
Aucune connexion réseau, aucun sudo : lit seulement la base pacman locale.

  arsenal.py build          (re)génère le cache si la base pacman a changé
  arsenal.py cat            JSON { categories, total, generated } (métadonnées)
  arsenal.py path           chemin du fichier de catalogue (pour FileView)
  arsenal.py whatis <nom>   description longue + fichiers binaires (pacman -Qi/-Ql)

Le catalogue complet est écrit dans ~/.cache/catalyst/arsenal.json :
  { "generated": <epoch>, "db": <mtime>, "categories": [{id,label,count}],
    "tools": [{ "n": nom, "d": description, "c": [cat...], "gui": bool, "bin": "binaire" }] }
"""
import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

HOME = Path.home()
CACHE = HOME / ".cache/catalyst/arsenal.json"
PACMAN_DB = Path("/var/lib/pacman/local")
APPS_DIRS = [Path("/usr/share/applications"), HOME / ".local/share/applications"]

# libellés lisibles pour les catégories BlackArch
LABELS = {
    "scanner": "Scanners", "recon": "Reconnaissance", "webapp": "Web",
    "exploitation": "Exploitation", "networking": "Réseau", "windows": "Windows",
    "cracker": "Cassage", "fuzzer": "Fuzzing", "forensic": "Forensic",
    "binary": "Binaire", "crypto": "Cryptographie", "reversing": "Reverse",
    "automation": "Automatisation", "misc": "Divers", "sniffer": "Sniffing",
    "spoof": "Spoofing", "proxy": "Proxy", "dos": "DoS", "backdoor": "Backdoor",
    "defensive": "Défense", "mobile": "Mobile", "wireless": "Sans-fil",
    "social": "Ingénierie sociale", "malware": "Malware", "disassembler": "Désassemblage",
    "debugger": "Debug", "fingerprint": "Fingerprinting", "tunnel": "Tunneling",
    "code-audit": "Audit de code", "packer": "Packers", "anti-forensic": "Anti-forensic",
    "honeypot": "Honeypots", "ids": "IDS/IPS", "voip": "VoIP", "database": "Bases de données",
    "nfc": "NFC/RFID", "hardware": "Hardware", "automobile": "Automobile",
    "stego": "Stéganographie", "decompiler": "Décompilation", "unpacker": "Unpacking",
    "ai": "IA", "exploitation": "Exploitation", "cracker": "Cassage", "keylogger": "Keyloggers",
    "gpu": "GPU", "firmware": "Firmware", "config": "Config", "dropper": "Droppers",
}
# icône Material par catégorie
ICONS = {
    "scanner": "radar", "recon": "travel_explore", "webapp": "public",
    "exploitation": "bolt", "networking": "lan", "windows": "window",
    "cracker": "password", "fuzzer": "blur_on", "forensic": "fingerprint",
    "binary": "memory", "crypto": "enhanced_encryption", "reversing": "sync_alt",
    "automation": "smart_toy", "misc": "category", "sniffer": "network_check",
    "spoof": "theater_comedy", "proxy": "swap_horiz", "dos": "block",
    "backdoor": "door_back", "defensive": "shield", "mobile": "smartphone",
    "wireless": "wifi", "social": "groups", "malware": "coronavirus",
    "disassembler": "data_object", "debugger": "bug_report", "fingerprint": "fingerprint",
    "tunnel": "vpn_lock", "code-audit": "code", "packer": "inventory_2",
    "database": "database", "stego": "image", "hardware": "developer_board",
    "voip": "call", "ai": "neurology", "gpu": "developer_board",
}


def run(cmd, timeout=40):
    return subprocess.run(cmd, capture_output=True, text=True, timeout=timeout).stdout


def all_categories():
    cats = []
    for line in run(["pacman", "-Sg"]).splitlines():
        g = line.split()[0] if line.split() else ""
        if g.startswith("blackarch-"):
            cats.append(g[len("blackarch-"):])
    return sorted(set(cats))


def gui_binaries():
    """Noms d'exécutables lancés par un .desktop → outil « graphique »."""
    exe = set()
    for d in APPS_DIRS:
        if not d.is_dir():
            continue
        for f in d.glob("*.desktop"):
            try:
                for line in f.read_text(errors="ignore").splitlines():
                    if line.startswith("Exec="):
                        parts = line[5:].split()
                        if parts:
                            exe.add(Path(parts[0]).name)
                        break
            except OSError:
                pass
    return exe


REPO_LABEL = {
    "cachyos-v3": "cachyos", "cachyos-core-v3": "cachyos", "cachyos-extra-v3": "cachyos",
    "cachyos": "cachyos", "core": "core", "extra": "extra", "multilib": "multilib",
    "chaotic-aur": "chaotic", "blackarch": "blackarch", "archstrike": "archstrike",
}


def config_repo_order():
    order = []
    try:
        for line in Path("/etc/pacman.conf").read_text().splitlines():
            m = re.match(r"^\[([a-z0-9-]+)\]\s*$", line.strip())
            if m and m.group(1) != "options":
                order.append(m.group(1))
    except OSError:
        pass
    return order


def origin_map():
    """nom -> dépôt d'origine : premier dépôt (ordre pacman.conf) qui fournit
    la version installée. Reflète d'où pacman a réellement pris le paquet."""
    order = config_repo_order()
    rank = {r: i for i, r in enumerate(order)}
    best = {}
    for line in run(["pacman", "-Sl"]).splitlines():
        parts = line.split()
        if len(parts) < 4 or "[inst" not in parts[3].lower() and "[install" not in line:
            # ligne installée ? le marqueur varie selon la locale -> teste large
            if "install" not in line and "inst" not in line:
                continue
        if len(parts) < 2:
            continue
        repo, name = parts[0], parts[1]
        r = rank.get(repo, 999)
        if name not in best or r < best[name][0]:
            best[name] = (r, repo)
    return {n: REPO_LABEL.get(v[1], v[1]) for n, v in best.items()}


# Outils de sécurité « classiques » fournis par les dépôts Arch officiels
# (extra/multilib/cachyos), que BlackArch ne repackage pas. Inclus seulement
# s'ils sont installés. name -> catégories.
MAINSTREAM = {
    "nmap": ["scanner", "recon"], "sqlmap": ["webapp", "exploitation"],
    "wireshark-qt": ["sniffer", "networking"], "wireshark-cli": ["sniffer", "networking"],
    "tcpdump": ["sniffer", "networking"], "john": ["cracker"], "hashcat": ["cracker"],
    "hydra": ["cracker"], "aircrack-ng": ["wireless", "cracker"], "bettercap": ["sniffer", "spoof"],
    "ettercap": ["sniffer", "spoof"], "metasploit": ["exploitation"], "nikto": ["webapp", "scanner"],
    "wpscan": ["webapp", "scanner"], "gobuster": ["webapp", "fuzzer"], "ffuf": ["webapp", "fuzzer"],
    "dirb": ["webapp"], "masscan": ["scanner"], "netcat": ["networking"], "socat": ["networking"],
    "proxychains-ng": ["proxy"], "tor": ["proxy", "tunnel"], "torsocks": ["proxy"],
    "openvpn": ["networking", "tunnel"], "wireguard-tools": ["networking", "tunnel"],
    "radare2": ["reversing", "disassembler"], "rizin": ["reversing", "disassembler"],
    "ghidra": ["reversing", "disassembler"], "gdb": ["debugger", "reversing"],
    "binwalk": ["forensic", "firmware"], "foremost": ["forensic"], "sleuthkit": ["forensic"],
    "autopsy": ["forensic"], "volatility3": ["forensic"], "steghide": ["stego"],
    "exiftool": ["forensic", "recon"], "hashid": ["crypto"], "hashcat-utils": ["cracker"],
    "yara": ["malware"], "clamav": ["defensive", "malware"], "rkhunter": ["defensive"],
    "lynis": ["defensive", "code-audit"], "nuclei": ["scanner", "webapp"],
    "subfinder": ["recon"], "amass": ["recon"], "httpx": ["recon", "webapp"],
    "whatweb": ["recon", "webapp"], "dnsrecon": ["recon"], "dnsenum": ["recon"],
    "fierce": ["recon"], "theharvester": ["recon"], "recon-ng": ["recon"],
    "responder": ["spoof", "networking"], "impacket": ["exploitation", "windows"],
    "crackmapexec": ["windows", "exploitation"], "evil-winrm": ["windows"],
    "enum4linux": ["windows", "recon"], "smbclient": ["windows", "networking"],
    "frida": ["reversing", "mobile"], "apktool": ["mobile", "reversing"],
    "jadx": ["mobile", "reversing"], "burpsuite": ["webapp", "proxy"],
    "zaproxy": ["webapp", "proxy"], "mitmproxy": ["proxy", "sniffer"],
    "aircrack-ng": ["wireless"], "reaver": ["wireless", "cracker"], "kismet": ["wireless", "sniffer"],
    "hcxtools": ["wireless", "cracker"], "hcxdumptool": ["wireless"],
    "cewl": ["cracker", "recon"], "crunch": ["cracker"], "medusa": ["cracker"],
    "patator": ["cracker"], "chisel": ["tunnel", "networking"], "ligolo-ng": ["tunnel"],
    "seclists": ["misc", "fuzzer"], "exploitdb": ["exploitation"],
}


def mainstream_installed():
    names = list(MAINSTREAM)
    present = set()
    r = run(["pacman", "-Qq"] + names).splitlines() if names else []
    # pacman -Qq échoue si un paquet manque : on filtre un par un via -T
    missing = set()
    for line in run(["pacman", "-T"] + names).splitlines():
        missing.add(line.strip())
    return [n for n in names if n not in missing]


def build(force=False):
    db_mtime = PACMAN_DB.stat().st_mtime if PACMAN_DB.exists() else 0
    if not force and CACHE.is_file():
        try:
            cur = json.loads(CACHE.read_text())
            if abs(cur.get("db", 0) - db_mtime) < 1:
                return cur
        except (OSError, ValueError):
            pass

    cats = all_categories()
    groups = ["blackarch-" + c for c in cats]
    # name -> set(categories) via les groupes installés (source fiable)
    tool_cats = {}
    for line in run(["pacman", "-Qg"] + groups).splitlines():
        parts = line.split()
        if len(parts) < 2 or not parts[0].startswith("blackarch-"):
            continue
        cat = parts[0][len("blackarch-"):]
        tool_cats.setdefault(parts[1], set()).add(cat)

    for name in mainstream_installed():
        tool_cats.setdefault(name, set()).update(MAINSTREAM[name])

    # descriptions
    desc = {}
    names = list(tool_cats)
    if names:
        for line in run(["expac", "-Q", "%n\t%d"] + names).splitlines():
            if "\t" in line:
                n, d = line.split("\t", 1)
                desc[n] = d

    guis = gui_binaries()
    origin = origin_map()
    tools = []
    for name in sorted(tool_cats):
        c = sorted(tool_cats[name])
        tools.append({
            "n": name,
            "d": desc.get(name, ""),
            "c": c,
            "gui": name in guis,
            "r": origin.get(name, "blackarch"),
        })

    counts = {}
    for t in tools:
        for c in t["c"]:
            counts[c] = counts.get(c, 0) + 1
    categories = [{"id": c, "label": LABELS.get(c, c.replace("-", " ").title()),
                   "icon": ICONS.get(c, "category"), "count": counts.get(c, 0)}
                  for c in cats if counts.get(c)]
    categories.sort(key=lambda x: -x["count"])

    out = {"generated": int(time.time()), "db": db_mtime,
           "categories": categories, "total": len(tools), "tools": tools}
    CACHE.parent.mkdir(parents=True, exist_ok=True)
    tmp = CACHE.with_suffix(".tmp")
    tmp.write_text(json.dumps(out, ensure_ascii=False))
    tmp.replace(CACHE)
    return out


def whatis(name):
    if not re.fullmatch(r"[A-Za-z0-9@._+-]+", name or ""):
        return {"ok": False}
    info = run(["pacman", "-Qi", name])
    long_desc = ""
    url = ""
    version = ""
    for line in info.splitlines():
        if line.startswith("Description") and ":" in line:
            long_desc = line.split(":", 1)[1].strip()
        elif line.startswith(("URL", "URL ")) and ":" in line:
            url = line.split(":", 1)[1].strip()
        elif line.startswith(("Version", "Versio")) and ":" in line:
            version = line.split(":", 1)[1].strip()
    bins = []
    bindirs = ("/usr/bin/", "/usr/sbin/", "/bin/")
    for line in run(["pacman", "-Ql", name]).splitlines():
        if " " not in line:
            continue
        path = line.split(" ", 1)[1]
        if any(path.startswith(b) for b in bindirs) and not path.endswith("/"):
            base = Path(path).name
            if base and os.access(path, os.X_OK):
                bins.append(base)
    # dédup en gardant l'ordre
    seen, ordered = set(), []
    for b in bins:
        if b not in seen:
            seen.add(b)
            ordered.append(b)
    return {"ok": True, "name": name, "desc": long_desc, "url": url,
            "version": version, "bins": ordered[:12]}


def main(a):
    if len(a) < 2:
        print(__doc__)
        return 2
    cmd = a[1]
    if cmd == "build":
        d = build(force="--force" in a)
        print(json.dumps({"ok": True, "total": d["total"], "categories": len(d["categories"])}))
    elif cmd == "cat":
        d = build()
        print(json.dumps({"ok": True, "categories": d["categories"],
                          "total": d["total"], "generated": d["generated"]}, ensure_ascii=False))
    elif cmd == "path":
        build()
        print(str(CACHE))
    elif cmd == "whatis" and len(a) >= 3:
        print(json.dumps(whatis(a[2]), ensure_ascii=False))
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
