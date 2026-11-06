#!/usr/bin/env python3
"""Tsubasa Catalyst — navigateur ProtonVPN.

Lit le cache de l'app officielle (aucun appel réseau, aucun spoofing) et classe
les serveurs par activité. Pour la connexion en 1 clic, génère une configuration
WireGuard à partir de TA clé de session (trousseau) + la clé publique du serveur,
que le hub VPN importe et connecte comme n'importe quel WireGuard.

  proton.py servers                 JSON classé (catégories + reco + pays)
  proton.py country <CC>            serveurs d'un pays
  proton.py find <texte>            recherche par nom / pays / ville
  proton.py wgconfig <id|nom>       config WireGuard d'un serveur (stdout, debug)
  proton.py connect <id|nom>        (re)crée la connexion WireGuard « ProtonVPN »
  proton.py status                  tier + fraîcheur du cache

Le cache est celui de proton-vpn-gtk-app : ~/.cache/Proton/VPN/serverlist.json
(rafraîchi par l'app). La clé WireGuard n'est lue que pour « wgconfig ».
"""
import json
import os
import sys
import time
from pathlib import Path

CACHE = Path.home() / ".cache/Proton/VPN"
SERVERS = CACHE / "serverlist.json"
CLIENTCFG = CACHE / "clientconfig.json"
NAMES = CACHE / "location_names_fr.json"

# ServerFeatureEnum (proton.vpn.session.servers.types)
SECURE_CORE, TOR, P2P, STREAMING = 1, 2, 4, 8

# noms FR de pays via babel si dispo, sinon petit repli, sinon le code
_FR_FALLBACK = {
    "FR": "France", "US": "États-Unis", "GB": "Royaume-Uni", "DE": "Allemagne",
    "CH": "Suisse", "NL": "Pays-Bas", "ES": "Espagne", "IT": "Italie", "UK": "Royaume-Uni",
}
try:
    from babel import Locale as _Locale
    _TERR = _Locale("fr").territories
except Exception:
    _TERR = {}


def out(obj):
    print(json.dumps(obj, ensure_ascii=False))


def country_name(cc):
    return _TERR.get(cc) or _FR_FALLBACK.get(cc, cc)


def load_cache():
    if not SERVERS.is_file():
        raise RuntimeError("cache ProtonVPN absent — ouvre et connecte-toi une fois à l'app")
    d = json.loads(SERVERS.read_text())
    srv = d.get("LogicalServers", [])
    max_tier = d.get("MaxTier", 2)
    return srv, max_tier, d.get("LoadsExpirationTime", 0)


def brief(s):
    """Vue compacte d'un serveur logique pour l'interface."""
    f = s.get("Features", 0)
    return {
        "id": s.get("ID"),
        "name": s.get("Name"),
        "cc": s.get("ExitCountry"),
        "entry": s.get("EntryCountry"),
        "city": s.get("City") or "",
        "load": s.get("Load", 0),
        "score": round(s.get("Score", 0), 4),
        "tier": s.get("Tier", 0),
        "p2p": bool(f & P2P),
        "tor": bool(f & TOR),
        "sc": bool(f & SECURE_CORE),
        "stream": bool(f & STREAMING),
        "secure": bool(f & SECURE_CORE),
    }


def usable(srv, max_tier):
    return [s for s in srv if s.get("Status") == 1 and s.get("Tier", 0) <= max_tier]


def best_by_score(lst, n=1):
    s = sorted(lst, key=lambda x: x.get("Score", 9e9))
    return s[:n]


def cmd_servers():
    srv, max_tier, exp = load_cache()
    on = usable(srv, max_tier)
    std = [s for s in on if not (s.get("Features", 0) & (SECURE_CORE | TOR))]
    p2p = [s for s in on if s.get("Features", 0) & P2P]
    stream = [s for s in on if s.get("Features", 0) & STREAMING]
    sc = [s for s in on if s.get("Features", 0) & SECURE_CORE]
    tor = [s for s in on if s.get("Features", 0) & TOR]
    fr_fast = [s for s in std if s.get("ExitCountry") == "FR"]

    def cat(cid, label, icon, desc, pool, top=40):
        ranked = best_by_score(pool, top)
        return {
            "id": cid, "label": label, "icon": icon, "desc": desc,
            "count": len(pool),
            "reco": brief(ranked[0]) if ranked else None,
            "servers": [brief(s) for s in ranked],
        }

    cats = [
        cat("rapide", "Navigation rapide", "bolt",
            "Le serveur le moins chargé, pour l'usage quotidien", std),
        cat("jeu", "Jeu / faible latence", "sports_esports",
            "Le plus proche et le moins chargé (France) pour minimiser le ping", fr_fast or std),
        cat("streaming", "Streaming", "smart_display",
            "Serveurs optimisés déblocage (Netflix, etc.)", stream),
        cat("p2p", "Téléchargement P2P", "swap_vert",
            "Serveurs autorisant le torrent / P2P", p2p),
        cat("securecore", "Secure Core", "shield",
            "Double saut via un pays à confidentialité renforcée", sc),
        cat("tor", "Tor / anonymat", "travel_explore",
            "Accès au réseau Tor via le VPN (dark web, censure)", tor),
    ]

    # meilleur serveur par pays (vue « Tous les pays »)
    by_cc = {}
    for s in std:
        cc = s.get("ExitCountry")
        if cc not in by_cc or s.get("Score", 9e9) < by_cc[cc].get("Score", 9e9):
            by_cc[cc] = s
    countries = sorted(
        ({"cc": cc, "name": country_name(cc), "count": sum(1 for x in on if x.get("ExitCountry") == cc),
          "best": brief(s)} for cc, s in by_cc.items()),
        key=lambda c: c["name"])

    out({
        "tier": max_tier,
        "updated": int(SERVERS.stat().st_mtime),
        "total": len(on),
        "categories": cats,
        "countries": countries,
    })


def cmd_country(cc):
    srv, max_tier, _ = load_cache()
    cc = cc.upper()
    lst = [s for s in usable(srv, max_tier) if s.get("ExitCountry") == cc]
    lst.sort(key=lambda x: x.get("Score", 9e9))
    out({"cc": cc, "name": country_name(cc), "count": len(lst),
         "servers": [brief(s) for s in lst]})


def cmd_find(q):
    srv, max_tier, _ = load_cache()
    q = q.strip().lower()
    hits = []
    for s in usable(srv, max_tier):
        hay = f"{s.get('Name','')} {s.get('ExitCountry','')} {country_name(s.get('ExitCountry',''))} {s.get('City','')}".lower()
        if q in hay:
            hits.append(s)
    hits.sort(key=lambda x: x.get("Score", 9e9))
    out({"query": q, "count": len(hits), "servers": [brief(s) for s in hits[:200]]})


def cmd_status():
    try:
        srv, max_tier, _ = load_cache()
        out({"ok": True, "tier": max_tier, "total": len(usable(srv, max_tier)),
             "updated": int(SERVERS.stat().st_mtime),
             "age_min": int((time.time() - SERVERS.stat().st_mtime) / 60)})
    except Exception as e:
        out({"ok": False, "error": str(e)})


def wg_ports():
    try:
        cc = json.loads(CLIENTCFG.read_text())
        dp = cc.get("DefaultPorts", {}).get("WireGuard", {})
        udp = dp.get("UDP", [])
        return udp[0] if udp else 51820
    except Exception:
        return 51820


def find_server(srv, key):
    for s in srv:
        if s.get("ID") == key or s.get("Name") == key:
            return s
    kl = key.lower()
    for s in srv:
        if s.get("Name", "").lower() == kl:
            return s
    return None


def session_wg_key():
    """Lit la clé WireGuard de la session ProtonVPN (trousseau). Ta clé, ton compte."""
    from functools import partial
    from proton.sso import ProtonSSO
    from proton.vpn.session import VPNSession
    sso = ProtonSSO(appversion="linux-vpn-gui@5.8.7+x86-64",
                    user_agent="ProtonVPN/4.18.7 (Linux; arch)")
    s = sso.get_default_session(override_class=partial(VPNSession))
    if not getattr(s, "authenticated", False):
        raise RuntimeError("session Proton non connectée — connecte-toi dans l'app d'abord")
    acc = s.vpn_account
    return acc.vpn_credentials.pubkey_credentials.wg_private_key


def build_conf(key):
    """(config WireGuard, nom du serveur). Lit la clé de session (trousseau)."""
    srv, max_tier, _ = load_cache()
    s = find_server(srv, key)
    if not s:
        raise RuntimeError(f"serveur introuvable : {key}")
    if s.get("Tier", 0) > max_tier:
        raise RuntimeError(f"{s.get('Name')} nécessite un abonnement supérieur")
    phys = [p for p in s.get("Servers", []) if p.get("Status") == 1] or s.get("Servers", [])
    if not phys:
        raise RuntimeError(f"aucun serveur physique en ligne pour {s.get('Name')}")
    p = min(phys, key=lambda x: x.get("Load", 0) if isinstance(x.get("Load"), int) else 0)
    priv = session_wg_key()
    port = wg_ports()
    conf = "\n".join([
        "[Interface]",
        f"PrivateKey = {priv}",
        # Adresse v4 + v6 : sans l'adresse IPv6, NetworkManager n'installe PAS
        # la route ::/0 dans le tunnel → l'IPv6 réel fuit hors VPN et crée un
        # chemin v4/v6 scindé qui casse le vocal Discord (« connecté, 0 son »).
        "Address = 10.2.0.2/32, fd00::2/128",
        "DNS = 10.2.0.1",
        "",
        "[Peer]",
        f"PublicKey = {p['X25519PublicKey']}",
        f"Endpoint = {p['EntryIP']}:{port}",
        "AllowedIPs = 0.0.0.0/0, ::/0",
        "",
    ])
    return conf, s.get("Name")


def cmd_wgconfig(key):
    conf, _ = build_conf(key)
    sys.stdout.write(conf)


def nm(*args, input_text=None, check=True):
    import subprocess
    r = subprocess.run(["nmcli", *args], capture_output=True, text=True, input=input_text, timeout=60)
    if check and r.returncode != 0:
        raise RuntimeError((r.stderr or r.stdout).strip() or "échec nmcli")
    return r.stdout


def cmd_connect(key):
    """(Re)crée la connexion WireGuard « ProtonVPN » pour ce serveur, SANS la monter.
    La clé privée ne transite que vers NetworkManager via un fichier temporaire 0600.
    """
    import re
    import tempfile
    conf, server = build_conf(key)
    # supprime les anciennes connexions « ProtonVPN »
    for line in nm("-t", "-f", "NAME,UUID", "connection", "show").splitlines():
        parts = line.rsplit(":", 1)
        if len(parts) == 2 and parts[0] == "ProtonVPN":
            nm("connection", "delete", parts[1], check=False)
    with tempfile.TemporaryDirectory() as td:
        f = Path(td) / "ProtonVPN.conf"
        f.write_text(conf)
        os.chmod(f, 0o600)
        res = nm("connection", "import", "type", "wireguard", "file", str(f))
    m = re.search(r"\(([0-9a-f-]{36})\)", res)
    uuid = m.group(1) if m else ""
    if uuid:
        nm("connection", "modify", uuid, "connection.id", "ProtonVPN", check=False)
        nm("connection", "modify", uuid, "connection.autoconnect", "no", check=False)
        # MTU abaissé : sans ça les gros paquets UDP entrants (voix Discord,
        # RTP ~1200+ o.) dépassent le tunnel et sont droppés → « connecté mais
        # 0 son ». 1280 est le plancher sûr qui fait toujours passer la voix.
        nm("connection", "modify", uuid, "wireguard.mtu", "1280", check=False)
        # Garantit la capture de l'IPv6 par le tunnel (anti-fuite + anti-split
        # qui casse le vocal). Explicite au cas où l'import NM retombe sur auto.
        nm("connection", "modify", uuid,
           "ipv6.method", "manual", "ipv6.addresses", "fd00::2/128", check=False)
    out({"ok": True, "uuid": uuid, "server": server})


def main(a):
    try:
        if len(a) < 2:
            print(__doc__)
            return 2
        c = a[1]
        if c == "servers":
            cmd_servers()
        elif c == "country" and len(a) >= 3:
            cmd_country(a[2])
        elif c == "find" and len(a) >= 3:
            cmd_find(a[2])
        elif c == "status":
            cmd_status()
        elif c == "wgconfig" and len(a) >= 3:
            cmd_wgconfig(a[2])
        elif c == "connect" and len(a) >= 3:
            cmd_connect(a[2])
        else:
            print(__doc__)
            return 2
    except Exception as e:
        out({"ok": False, "error": str(e)})
        return 1
    return 0


if __name__ == "__main__":
    # les fichiers écrits ici contiennent des clés privées : jamais lisibles par les autres
    os.umask(0o077)
    sys.exit(main(sys.argv))
