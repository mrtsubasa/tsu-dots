#!/usr/bin/env python3
"""Tsubasa Catalyst — VPN via NetworkManager (aucun sudo, tout reste local).

  vpn.py list                         JSON des VPN (OpenVPN, WireGuard, plugins)
  vpn.py types                        types importables (plugins installés)
  vpn.py import <fichier> [nom]       importe .ovpn / .conf WireGuard / autre plugin
  vpn.py paste <nom> <ext>            importe la configuration lue sur stdin
  vpn.py wg-manual                    crée un WireGuard depuis un JSON (stdin)
  vpn.py genkey                       paire de clés WireGuard (JSON)
  vpn.py export <uuid> <dossier>      exporte en fichier réutilisable (chemin en sortie)
  vpn.py set <uuid> neverdefault|autoconnect on|off
  vpn.py rename <uuid> <nom>
  vpn.py replace <uuid> <fichier>     répare : réimporte le fichier sous le même nom
  vpn.py creds <uuid> <identifiant>   OpenVPN : enregistre login (arg) + mot de passe (stdin)
  vpn.py clearcreds <uuid>            OpenVPN : oublie le mot de passe enregistré
  vpn.py delete <uuid>

Une copie de chaque configuration importée est gardée dans
~/.local/share/catalyst/vpn (droits 600) pour l'export.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

STORE = Path.home() / ".local/share/catalyst/vpn"
PLUGINS = Path("/usr/lib/NetworkManager/VPN")
SHORT = {
    "org.freedesktop.NetworkManager.openvpn": "openvpn",
    "org.freedesktop.NetworkManager.openconnect": "openconnect",
    "org.freedesktop.NetworkManager.vpnc": "vpnc",
    "org.freedesktop.NetworkManager.l2tp": "l2tp",
    "org.freedesktop.NetworkManager.pptp": "pptp",
    "org.freedesktop.NetworkManager.strongswan": "strongswan",
    "org.freedesktop.NetworkManager.fortisslvpn": "fortisslvpn",
    "org.freedesktop.NetworkManager.sstp": "sstp",
    "org.freedesktop.NetworkManager.protun": "protonvpn",
}


def out(obj):
    print(json.dumps(obj, ensure_ascii=False))


def nm(*args, input_text=None, check=True):
    r = subprocess.run(["nmcli", *args], capture_output=True, text=True, input=input_text, timeout=60)
    if check and r.returncode != 0:
        raise RuntimeError((r.stderr or r.stdout).strip() or "échec nmcli")
    return r.stdout


def esc_split(line):
    """Découpe une ligne `nmcli -t` (séparateur « : », échappement « \\: »)."""
    parts, cur, esc = [], "", False
    for ch in line:
        if esc:
            cur += ch
            esc = False
        elif ch == "\\":
            esc = True
        elif ch == ":":
            parts.append(cur)
            cur = ""
        else:
            cur += ch
    parts.append(cur)
    return parts


def external_devices():
    ext = set()
    for line in nm("-t", "-f", "DEVICE,STATE", "device").splitlines():
        p = esc_split(line)
        if len(p) >= 2 and "extern" in p[1]:
            ext.add(p[0])
    return ext


def cmd_list():
    ext = external_devices()
    items = []
    for line in nm("-t", "-f", "NAME,UUID,TYPE,ACTIVE,AUTOCONNECT,DEVICE", "connection", "show").splitlines():
        name, uuid, ctype, active, auto, dev = (esc_split(line) + [""] * 6)[:6]
        if ctype not in ("vpn", "wireguard"):
            continue
        kind = "wireguard"
        if ctype == "vpn":
            st = nm("-g", "vpn.service-type", "connection", "show", uuid, check=False).strip()
            kind = SHORT.get(st, st.split(".")[-1] or "vpn")
        nd = nm("-g", "ipv4.never-default", "connection", "show", uuid, check=False).strip()
        # fichiers (certificats, clés) référencés mais disparus → VPN inutilisable
        missing = []
        need_login = False
        has_login = False
        if ctype == "vpn":
            data = nm("-g", "vpn.data", "connection", "show", uuid, check=False)
            for m in re.finditer(r"(?:^|,\s*)(?:ca|cert|key|ta|tls-crypt)\s*=\s*(/[^,]+)", data):
                if not Path(m.group(1).strip()).is_file():
                    missing.append(m.group(1).strip())
            # OpenVPN à mot de passe (ProtonVPN, PIA…) : login/mot de passe requis
            if kind == "openvpn":
                mct = re.search(r"connection-type\s*=\s*([a-z-]+)", data)
                need_login = (mct.group(1) if mct else "") in ("password", "password-tls")
                has_login = bool(re.search(r"(?:^|,)\s*username\s*=\s*\S", data))
        # ProtonVPN *de l'app officielle* : plugin NM « protun » → lecture seule
        # (l'app gère le serveur). La WireGuard « ProtonVPN » que le hub génère
        # lui-même reste une connexion normale, toggleable (pas marquée proton ici).
        is_proton = (kind == "protonvpn") or dev == "protun"
        wg_external = ctype == "wireguard" and (dev in ext or name in ext)
        external = wg_external or is_proton
        if is_proton:
            label = "ProtonVPN"
        elif wg_external and name.startswith("wt"):
            label = "NetBird"
        elif wg_external and name.startswith("tailscale"):
            label = "Tailscale"
        else:
            label = name
        items.append({
            "name": name, "uuid": uuid, "type": kind, "active": active == "yes",
            "autoconnect": auto == "yes", "neverDefault": nd in ("yes", "oui"),
            "external": external, "proton": is_proton, "device": dev, "missing": missing,
            "needLogin": need_login, "hasLogin": has_login, "label": label,
        })
    items.sort(key=lambda x: (x["external"], not x["active"], x["name"].lower()))
    out(items)


def available_types():
    types = ["wireguard"]
    if PLUGINS.is_dir():
        for f in PLUGINS.glob("*.name"):
            txt = f.read_text(errors="ignore")
            m = re.search(r"service=(\S+)", txt)
            if m:
                types.append(SHORT.get(m.group(1), m.group(1).split(".")[-1]))
    return sorted(set(types))


def detect(text, ext):
    if re.search(r"^\s*\[Interface\]", text, re.M) and re.search(r"PrivateKey", text):
        return "wireguard"
    if ext in (".ovpn",) or re.search(r"^\s*(client|remote\s+\S+|dev\s+tun|<ca>)", text, re.M):
        return "openvpn"
    if ext == ".pcf":
        return "vpnc"
    return None


def safe_ifname(name):
    s = re.sub(r"[^A-Za-z0-9_=+.-]", "", name)[:15]
    return s or "wgcatalyst"


def do_import(path, name=None):
    path = Path(path)
    text = path.read_text(errors="ignore")
    kind = detect(text, path.suffix.lower())
    if not kind:
        raise RuntimeError("format non reconnu (OpenVPN .ovpn, WireGuard .conf, Cisco .pcf…)")
    if kind not in available_types():
        raise RuntimeError(f"plugin NetworkManager « {kind} » absent : installe networkmanager-{kind}")
    base = name or path.stem
    STORE.mkdir(parents=True, exist_ok=True, mode=0o700)
    with tempfile.TemporaryDirectory() as td:
        if kind == "wireguard":
            src = Path(td) / (safe_ifname(base) + ".conf")
        else:
            src = Path(td) / path.name
        shutil.copy(path, src)
        res = nm("connection", "import", "type", kind, "file", str(src))
    m = re.search(r"\(([0-9a-f-]{36})\)", res)
    uuid = m.group(1) if m else ""
    if uuid and name:
        nm("connection", "modify", uuid, "connection.id", name, check=False)
    if uuid:
        # par défaut : pas de connexion automatique au démarrage
        nm("connection", "modify", uuid, "connection.autoconnect", "no", check=False)
        keep = STORE / f"{uuid}{'.conf' if kind == 'wireguard' else path.suffix or '.ovpn'}"
        shutil.copy(path, keep)
        os.chmod(keep, 0o600)
    out({"ok": True, "uuid": uuid, "type": kind})


def cmd_paste(name, ext):
    text = sys.stdin.read()
    with tempfile.TemporaryDirectory() as td:
        p = Path(td) / (re.sub(r"[^\w.-]", "_", name) + (ext if ext.startswith(".") else "." + ext))
        p.write_text(text)
        do_import(p, name)


def cmd_genkey():
    priv = subprocess.run(["wg", "genkey"], capture_output=True, text=True, check=True).stdout.strip()
    pub = subprocess.run(["wg", "pubkey"], input=priv, capture_output=True, text=True, check=True).stdout.strip()
    out({"private": priv, "public": pub})


def cmd_wg_manual():
    d = json.loads(sys.stdin.read())
    need = ["name", "privateKey", "address", "peerPublicKey", "endpoint"]
    miss = [k for k in need if not str(d.get(k, "")).strip()]
    if miss:
        raise RuntimeError("champs manquants : " + ", ".join(miss))
    lines = ["[Interface]", f"PrivateKey = {d['privateKey'].strip()}", f"Address = {d['address'].strip()}"]
    if d.get("dns"):
        lines.append(f"DNS = {d['dns'].strip()}")
    lines += ["", "[Peer]", f"PublicKey = {d['peerPublicKey'].strip()}"]
    if d.get("presharedKey"):
        lines.append(f"PresharedKey = {d['presharedKey'].strip()}")
    lines.append(f"Endpoint = {d['endpoint'].strip()}")
    lines.append(f"AllowedIPs = {(d.get('allowedIps') or '0.0.0.0/0, ::/0').strip()}")
    if d.get("keepalive"):
        lines.append(f"PersistentKeepalive = {int(d['keepalive'])}")
    with tempfile.TemporaryDirectory() as td:
        p = Path(td) / (safe_ifname(d["name"]) + ".conf")
        p.write_text("\n".join(lines) + "\n")
        do_import(p, d["name"])


MISSING = []


def inline_ovpn(text):
    """Remplace les références ca/cert/key/tls-auth/tls-crypt par des blocs inline."""
    out_lines = []
    for line in text.splitlines():
        # NetworkManager ajoute « user/group nm-openvpn » : inexistants ailleurs
        if re.match(r"^\s*(user|group)\s+nm-openvpn\s*$", line):
            continue
        m = re.match(r"^\s*(ca|cert|key|tls-auth|tls-crypt|tls-crypt-v2)\s+(\S+)(\s+\d)?\s*$", line)
        fpath = m.group(2).strip("'\"") if m else ""
        if m and not Path(fpath).is_file():
            MISSING.append(fpath)
        if m and Path(fpath).is_file():
            tag = m.group(1)
            body = Path(fpath).read_text(errors="ignore").strip()
            if tag == "tls-auth" and m.group(3):
                out_lines.append(f"key-direction {m.group(3).strip()}")
            out_lines.append(f"<{tag}>\n{body}\n</{tag}>")
        else:
            out_lines.append(line)
    return "\n".join(out_lines) + "\n"


def wg_from_nm(uuid):
    show = nm("-s", "connection", "show", uuid)
    vals = {}
    for line in show.splitlines():
        if ":" in line:
            k, v = line.split(":", 1)
            vals[k.strip()] = v.strip()
    priv = vals.get("wireguard.private-key", "")
    if not priv or priv == "--":
        raise RuntimeError("clé privée indisponible (VPN géré par une autre application ?)")
    lines = ["[Interface]", f"PrivateKey = {priv}"]
    addr = nm("-g", "ipv4.addresses", "connection", "show", uuid, check=False).strip()
    addr6 = nm("-g", "ipv6.addresses", "connection", "show", uuid, check=False).strip()
    a = ", ".join(x for x in [addr.replace(" ", ""), addr6.replace(" ", "")] if x)
    if a:
        lines.append(f"Address = {a}")
    dns = nm("-g", "ipv4.dns", "connection", "show", uuid, check=False).strip()
    if dns:
        lines.append(f"DNS = {dns}")
    if vals.get("wireguard.listen-port", "0") not in ("0", ""):
        lines.append(f"ListenPort = {vals['wireguard.listen-port']}")
    # pairs (format nmcli) : « <clé> allowed-ips=a;b endpoint=h:p persistent-keepalive=n », séparés par « , »
    peers_line = vals.get("wireguard.peers", "")
    for chunk in filter(None, re.split(r",\s*(?=[A-Za-z0-9+/]{43}=)", peers_line)):
        tok = chunk.split()
        if not tok or not re.match(r"^[A-Za-z0-9+/]{43}=$", tok[0]):
            continue
        attrs = dict(t.split("=", 1) for t in tok[1:] if "=" in t)
        lines += ["", "[Peer]", f"PublicKey = {tok[0]}"]
        if attrs.get("preshared-key"):
            lines.append(f"PresharedKey = {attrs['preshared-key']}")
        if attrs.get("endpoint"):
            lines.append(f"Endpoint = {attrs['endpoint'].replace(chr(92), '')}")
        if attrs.get("allowed-ips"):
            lines.append(f"AllowedIPs = {', '.join(attrs['allowed-ips'].split(';'))}")
        if attrs.get("persistent-keepalive"):
            lines.append(f"PersistentKeepalive = {attrs['persistent-keepalive']}")
    return "\n".join(lines) + "\n"


def cmd_export(uuid, dest_dir):
    dest = Path(dest_dir).expanduser()
    dest.mkdir(parents=True, exist_ok=True)
    name = nm("-g", "connection.id", "connection", "show", uuid).strip()
    ctype = nm("-g", "connection.type", "connection", "show", uuid).strip()
    safe = re.sub(r"[^\w.-]", "_", name) or "vpn"
    if ctype == "wireguard":
        target = dest / f"{safe}.conf"
        try:
            text = wg_from_nm(uuid)
        except RuntimeError:
            kept = STORE / f"{uuid}.conf"
            if not kept.is_file():
                raise
            text = kept.read_text()
        target.write_text(text)
    else:
        st = nm("-g", "vpn.service-type", "connection", "show", uuid, check=False).strip()
        kind = SHORT.get(st, "vpn")
        target = dest / f"{safe}.{'ovpn' if kind == 'openvpn' else 'conf'}"
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td) / target.name
            r = subprocess.run(["nmcli", "connection", "export", uuid, str(tmp)], capture_output=True, text=True)
            if r.returncode == 0 and tmp.is_file():
                text = tmp.read_text(errors="ignore")
                target.write_text(inline_ovpn(text) if kind == "openvpn" else text)
            else:
                kept = next(iter(STORE.glob(f"{uuid}.*")), None)
                if not kept:
                    raise RuntimeError("le plugin " + kind + " ne sait pas exporter et aucune copie d'origine n'existe")
                shutil.copy(kept, target)
    os.chmod(target, 0o600)
    out({"ok": True, "path": str(target), "missing": MISSING})


def cmd_creds(uuid, username):
    """Enregistre les identifiants d'un OpenVPN à mot de passe (ProtonVPN, PIA…).
    Login en argument, mot de passe lu sur stdin (jamais en argv du shell).
    password-flags=0 : NetworkManager garde le secret, la connexion devient silencieuse.
    """
    pwd = sys.stdin.readline().rstrip("\n")
    nm("connection", "modify", uuid, "+vpn.data", f"username={username}")
    nm("connection", "modify", uuid, "+vpn.data", "password-flags=0")
    nm("connection", "modify", uuid, "vpn.secrets", f"password={pwd}")
    out({"ok": True})


def cmd_clearcreds(uuid):
    nm("connection", "modify", uuid, "-vpn.data", "username", check=False)
    nm("connection", "modify", uuid, "+vpn.data", "password-flags=1", check=False)
    nm("connection", "modify", uuid, "vpn.secrets", "", check=False)
    out({"ok": True})


def main(a):
    try:
        if len(a) < 2:
            print(__doc__)
            return 2
        c = a[1]
        if c == "list":
            cmd_list()
        elif c == "types":
            out(available_types())
        elif c == "import" and len(a) >= 3:
            do_import(a[2], a[3] if len(a) > 3 and a[3] else None)
        elif c == "paste" and len(a) >= 4:
            cmd_paste(a[2], a[3])
        elif c == "wg-manual":
            cmd_wg_manual()
        elif c == "genkey":
            cmd_genkey()
        elif c == "export" and len(a) >= 4:
            cmd_export(a[2], a[3])
        elif c == "set" and len(a) >= 5:
            prop = {"neverdefault": ["ipv4.never-default", "ipv6.never-default"], "autoconnect": ["connection.autoconnect"]}[a[3]]
            args = []
            for p in prop:
                args += [p, "yes" if a[4] == "on" else "no"]
            nm("connection", "modify", a[2], *args)
            out({"ok": True})
        elif c == "creds" and len(a) >= 4:
            cmd_creds(a[2], a[3])
        elif c == "clearcreds" and len(a) >= 3:
            cmd_clearcreds(a[2])
        elif c == "replace" and len(a) >= 4:
            name = nm("-g", "connection.id", "connection", "show", a[2]).strip()
            nm("connection", "delete", a[2])
            for f in STORE.glob(f"{a[2]}.*"):
                f.unlink()
            do_import(a[3], name)
        elif c == "rename" and len(a) >= 4:
            nm("connection", "modify", a[2], "connection.id", a[3])
            out({"ok": True})
        elif c == "delete" and len(a) >= 3:
            nm("connection", "delete", a[2])
            for f in STORE.glob(f"{a[2]}.*"):
                f.unlink()
            out({"ok": True})
        else:
            print(__doc__)
            return 2
    except Exception as e:  # message lisible pour l'interface
        out({"ok": False, "error": str(e)})
        return 1
    return 0


if __name__ == "__main__":
    # les fichiers écrits ici contiennent des clés privées : jamais lisibles par les autres
    os.umask(0o077)
    sys.exit(main(sys.argv))
