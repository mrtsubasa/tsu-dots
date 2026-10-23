#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
import urllib.parse
import urllib.request
from pathlib import Path

HOME = Path.home()
CHAT_SH = HOME / ".config/niri/scripts/ai/chat.sh"
UA = "catalyst-pkgs/1.0"

CATALOG = [
    {
        "id": "web",
        "label": "Navigateurs",
        "glyph": "󰖟",
        "pkgs": [
            ("firefox", "Navigateur Mozilla"),
            ("firefox-developer-edition", "Firefox Developer"),
            ("chromium", "Chromium open source"),
            ("brave-bin", "Brave (AUR)"),
            ("librewolf-bin", "LibreWolf (AUR)"),
            ("zen-browser-bin", "Zen Browser (AUR)"),
            ("google-chrome", "Chrome (AUR)"),
            ("qutebrowser", "Navigateur clavier"),
        ],
    },
    {
        "id": "media",
        "label": "Média",
        "glyph": "󰝚",
        "pkgs": [
            ("mpv", "Lecteur vidéo minimal"),
            ("vlc", "VLC"),
            ("obs-studio", "Streaming / capture"),
            ("kdenlive", "Montage KDE"),
            ("shotcut", "Montage léger"),
            ("audacity", "Éditeur audio"),
            ("spotify", "Spotify (AUR/flatpak)"),
            ("strawberry", "Lecteur musique"),
            ("easyeffects", "Effets PipeWire"),
        ],
    },
    {
        "id": "office",
        "label": "Bureau",
        "glyph": "󰈙",
        "pkgs": [
            ("libreoffice-fresh", "Suite bureautique"),
            ("onlyoffice-bin", "OnlyOffice (AUR)"),
            ("obsidian", "Notes (AUR)"),
            ("logseq-desktop-bin", "Logseq (AUR)"),
            ("zathura", "Lecteur PDF clavier"),
            ("evince", "Documents GNOME"),
        ],
    },
    {
        "id": "comms",
        "label": "Comms",
        "glyph": "󰍩",
        "pkgs": [
            ("discord", "Discord"),
            ("telegram-desktop", "Telegram"),
            ("signal-desktop", "Signal"),
            ("element-desktop", "Matrix"),
            ("slack-desktop", "Slack (AUR)"),
            ("zoom", "Zoom (AUR)"),
        ],
    },
    {
        "id": "dev",
        "label": "Dev",
        "glyph": "󰅩",
        "pkgs": [
            ("code", "VS Code (Code OSS)"),
            ("visual-studio-code-bin", "VS Code (AUR)"),
            ("neovim", "Neovim"),
            ("git", "Git"),
            ("docker", "Docker"),
            ("lazygit", "Git TUI"),
            ("github-cli", "GitHub CLI"),
            ("python", "Python"),
            ("nodejs", "Node.js"),
            ("rustup", "Rust"),
        ],
    },
    {
        "id": "gfx",
        "label": "Graphisme",
        "glyph": "󰏘",
        "pkgs": [
            ("gimp", "Retouche photo"),
            ("krita", "Peinture"),
            ("inkscape", "Vectoriel"),
            ("blender", "3D / VFX"),
            ("darktable", "RAW"),
            ("figma-linux", "Figma (AUR)"),
        ],
    },
    {
        "id": "game",
        "label": "Jeux",
        "glyph": "󰊴",
        "pkgs": [
            ("steam", "Steam"),
            ("lutris", "Lutris"),
            ("heroic-games-launcher-bin", "Heroic (AUR)"),
            ("prismlauncher", "Minecraft"),
            ("gamemode", "GameMode"),
            ("mangohud", "HUD perf"),
        ],
    },
    {
        "id": "sys",
        "label": "Système",
        "glyph": "󰒓",
        "pkgs": [
            ("btop", "Moniteur"),
            ("fastfetch", "Neofetch moderne"),
            ("gparted", "Partitions"),
            ("timeshift", "Snapshots"),
            ("btrfs-assistant", "Btrfs GUI"),
            ("flatpak", "Flatpak"),
            ("qemu-full", "QEMU"),
            ("virt-manager", "Virt Manager"),
        ],
    },
]

NEED_HINTS = {
    "navigateur": ["firefox", "librewolf-bin", "brave-bin", "chromium"],
    "browser": ["firefox", "chromium", "brave-bin"],
    "video": ["mpv", "vlc", "kdenlive", "obs-studio"],
    "vidéo": ["mpv", "vlc", "kdenlive", "obs-studio"],
    "montage": ["kdenlive", "shotcut", "obs-studio"],
    "musique": ["spotify", "strawberry", "mpv", "easyeffects"],
    "spotify": ["spotify"],
    "vpn": ["tailscale", "mullvad-vpn", "wireguard-tools"],
    "chat": ["discord", "telegram-desktop", "signal-desktop"],
    "discord": ["discord"],
    "note": ["obsidian", "logseq-desktop-bin", "joplin-desktop"],
    "pdf": ["zathura", "evince", "okular"],
    "code": ["code", "neovim", "visual-studio-code-bin"],
    "ide": ["code", "neovim", "jetbrains-toolbox"],
    "photo": ["gimp", "krita", "darktable"],
    "3d": ["blender"],
    "jeu": ["steam", "lutris", "heroic-games-launcher-bin"],
    "game": ["steam", "lutris"],
    "vm": ["virt-manager", "qemu-full", "docker"],
    "docker": ["docker", "docker-compose"],
    "terminal": ["alacritty", "kitty", "foot"],
}


def which(bin_name):
    return shutil.which(bin_name) is not None


def read_json(path: Path, default):
    try:
        return json.loads(path.read_text())
    except Exception:
        return default


def run_capture(cmd, timeout=25):
    try:
        p = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=timeout,
        )
        return (p.stdout or "").strip()
    except Exception:
        return ""


def helper():
    for b in ("paru", "yay"):
        if which(b):
            return b
    return "pacman"


def spawn(*argv):
    if not argv:
        return
    subprocess.Popen(
        ["niri", "msg", "action", "spawn", "--", *argv],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def term(title, cmd):
    script = f"echo; echo '  {title}'; echo; {cmd}; echo; echo 'Entrée pour fermer…'; read -r _"
    spawn("alacritty", "-t", title, "-e", "bash", "-lc", script)


def safe_name(s):
    s = (s or "").strip()
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9@._+-]*", s):
        return ""
    return s


def installed_set():
    return set(run_capture(["pacman", "-Qq"], timeout=20).split())


def http_json(url, timeout=8):
    try:
        req = urllib.request.Request(url, headers={"User-Agent": UA})
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return json.loads(r.read().decode())
    except Exception:
        return None


def hit(name, repo="", ver="", desc="", installed=False, aur=False, pop=0, why=""):
    return {
        "name": name,
        "repo": repo or ("aur" if aur else "repo"),
        "ver": ver or "",
        "desc": desc or "",
        "installed": bool(installed),
        "aur": bool(aur),
        "pop": int(pop or 0),
        "why": why or "",
    }


def parse_ss(text):
    items = []
    cur = None
    for line in text.splitlines():
        if line.startswith("    ") or line.startswith("\t"):
            if cur is not None and not cur["desc"]:
                cur["desc"] = line.strip()
            continue
        parts = line.split()
        if not parts:
            continue
        ident = parts[0]
        if "/" in ident:
            repo, name = ident.split("/", 1)
        else:
            repo, name = "repo", ident
        ver = parts[1] if len(parts) > 1 else ""
        cur = hit(
            name,
            repo=repo,
            ver=ver,
            installed="[installed" in line,
            aur=repo.lower() == "aur",
        )
        items.append(cur)
    return items


def pacman_ss(q):
    q = (q or "").strip()
    if not q:
        return []
    return parse_ss(run_capture(["pacman", "-Ss", "--", q], timeout=20))


def paru_ss(q):
    h = helper()
    if h == "pacman":
        return []
    q = (q or "").strip()
    if not q:
        return []
    return parse_ss(run_capture([h, "-Ssa", "--", q], timeout=25))


def arch_web(q):
    q = (q or "").strip()
    if not q:
        return []
    data = http_json(
        "https://archlinux.org/packages/search/json/?q=" + urllib.parse.quote(q)
    )
    if not data:
        return []
    inst = installed_set()
    out = []
    for p in (data.get("results") or [])[:18]:
        name = p.get("pkgname") or ""
        if not name:
            continue
        out.append(
            hit(
                name,
                repo=p.get("repo") or "extra",
                ver=p.get("pkgver") or "",
                desc=p.get("pkgdesc") or "",
                installed=name in inst,
            )
        )
    return out


def aur_web(q):
    q = (q or "").strip()
    if not q:
        return []
    data = http_json(
        "https://aur.archlinux.org/rpc/v5/search/"
        + urllib.parse.quote(q)
        + "?by=name-desc"
    )
    if not data or data.get("type") == "error":
        return []
    inst = installed_set()
    rows = data.get("results") or []
    rows = sorted(rows, key=lambda p: int(p.get("Popularity") or 0), reverse=True)
    out = []
    for p in rows[:18]:
        name = p.get("Name") or ""
        if not name:
            continue
        out.append(
            hit(
                name,
                repo="aur",
                ver=p.get("Version") or "",
                desc=p.get("Description") or "",
                installed=name in inst,
                aur=True,
                pop=int(p.get("Popularity") or 0),
            )
        )
    return out


def merge(lists, prefer=None):
    prefer = prefer or []
    rank = {n: i for i, n in enumerate(prefer)}
    seen = {}
    for lst in lists:
        for p in lst:
            n = p.get("name")
            if not n:
                continue
            if n not in seen:
                seen[n] = p
            else:
                old = seen[n]
                for k, v in p.items():
                    if v and not old.get(k):
                        old[k] = v
                    if k == "installed" and v:
                        old["installed"] = True
    items = list(seen.values())
    inst = installed_set()
    for p in items:
        p["installed"] = p["name"] in inst or p.get("installed")

    def key(p):
        n = p["name"]
        return (
            0 if n in rank else 1,
            rank.get(n, 99),
            0 if p.get("installed") else 1,
            0 if not p.get("aur") else 1,
            -int(p.get("pop") or 0),
            n,
        )

    items.sort(key=key)
    return items[:40]


def extract_json(text):
    if not text:
        return None
    m = re.search(r"\{.*\}", text, re.S)
    if not m:
        return None
    try:
        return json.loads(m.group(0))
    except Exception:
        return None


def hint_names(query):
    q = (query or "").lower()
    names = []
    for k, pkgs in NEED_HINTS.items():
        if k in q:
            names.extend(pkgs)
    return list(dict.fromkeys(names))


def ai_plan(query):
    names = hint_names(query)
    keywords = [w for w in re.split(r"\s+", query.strip()) if len(w) > 2][:6]
    why = ""
    prompt = (
        "Tu es un assistant paquets Arch/CachyOS/AUR. "
        "L'utilisateur décrit un besoin (FR ou EN). "
        "Réponds UNIQUEMENT un JSON compact : "
        '{"keywords":["mot1","mot2"],"names":["paquet1","paquet2"],"why":"phrase courte FR"}. '
        "names = vrais noms de paquets (firefox, kdenlive, neovim…). Max 8 names, 5 keywords. "
        f"Besoin : {query}"
    )
    if CHAT_SH.is_file():
        try:
            p = subprocess.run(
                ["bash", str(CHAT_SH), "ollama", ""],
                input=prompt,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                timeout=40,
            )
            data = extract_json((p.stdout or "").strip())
            if isinstance(data, dict):
                kn = [str(x) for x in (data.get("keywords") or []) if str(x).strip()]
                nn = [safe_name(str(x)) for x in (data.get("names") or [])]
                nn = [x for x in nn if x]
                if kn:
                    keywords = kn[:6]
                if nn:
                    names = list(dict.fromkeys(nn + names))
                why = str(data.get("why") or "").strip()
        except Exception:
            pass
    return names, keywords, why


def filter_repo(items, repo):
    repo = (repo or "").strip().lower()
    if not repo or repo in ("all", "*", "any"):
        return items
    out = []
    for p in items:
        r = str(p.get("repo") or "").lower()
        aur = bool(p.get("aur"))
        if repo == "aur":
            if aur or r == "aur":
                out.append(p)
        elif r == repo or r.endswith("/" + repo):
            out.append(p)
        elif repo in r:
            out.append(p)
    return out


def list_sync_repo(repo, q=""):
    repo = (repo or "").strip()
    if not repo:
        return []
    if repo.lower() == "aur":
        if not q.strip():
            return []
        return paru_ss(q) or aur_web(q)
    raw = run_capture(["pacman", "-Sl", "--", repo], timeout=30)
    inst = installed_set()
    qn = (q or "").strip().lower()
    items = []
    for line in raw.splitlines():
        parts = line.split()
        if len(parts) < 2:
            continue
        rname = parts[0]
        name = parts[1]
        ver = parts[2] if len(parts) > 2 else ""
        if qn and qn not in name.lower() and qn not in " ".join(parts).lower():
            continue
        items.append(
            hit(
                name,
                repo=rname,
                ver=ver,
                desc="",
                installed=name in inst or "[installed" in line,
                aur=rname.lower() == "aur",
            )
        )
        if len(items) >= 250:
            break
    if qn and len(items) < 40:
        extra = filter_repo(pacman_ss(q) + paru_ss(q), repo)
        items = merge([items, extra])
    return items


def sources_list():
    live = sorted(pacman_repos())
    items = [{"id": "all", "label": "Tous", "glyph": "󰀻"}]
    if helper() != "pacman":
        items.append({"id": "aur", "label": "AUR", "glyph": "󰣇"})
    prefer = [
        "blackarch",
        "chaotic-aur",
        "archlinuxcn",
        "cachyos",
        "cachyos-extra-v3",
        "cachyos-v3",
        "extra",
        "core",
        "multilib",
    ]
    ordered = [r for r in prefer if r in live] + [r for r in live if r not in prefer]
    glyphs = {
        "blackarch": "󰒃",
        "chaotic-aur": "󰏗",
        "archlinuxcn": "󰇧",
        "multilib": "󰕓",
        "core": "󰣇",
        "extra": "󰣇",
    }
    for r in ordered:
        items.append(
            {
                "id": r,
                "label": r,
                "glyph": glyphs.get(r, "󰏒"),
            }
        )
    return {"ok": True, "items": items, "helper": helper(), "mode": "sources"}


def mark(items):
    inst = installed_set()
    for p in items:
        p["installed"] = p["name"] in inst
    return items


def search_name(q, repo=""):
    q = (q or "").strip()
    repo = (repo or "").strip()
    if not q and repo and repo.lower() not in ("all", "", "aur"):
        items = list_sync_repo(repo, "")
        return {
            "ok": True,
            "items": items,
            "why": "",
            "mode": "name",
            "source": repo,
        }
    if not q:
        return {"ok": True, "items": [], "why": "", "mode": "name", "source": repo}
    if repo and repo.lower() not in ("all", ""):
        items = list_sync_repo(repo, q)
        return {
            "ok": True,
            "items": items,
            "why": "",
            "mode": "name",
            "source": repo,
        }
    items = merge([pacman_ss(q), arch_web(q), aur_web(q), paru_ss(q)])
    return {"ok": True, "items": items, "why": "", "mode": "name", "source": ""}


def search_need(q, repo=""):
    q = (q or "").strip()
    repo = (repo or "").strip()
    if not q:
        return {"ok": True, "items": [], "why": "", "mode": "need", "source": repo}
    names, keywords, why = ai_plan(q)
    lists = []
    for n in names[:8]:
        lists.append(pacman_ss("^" + re.escape(n) + "$") or pacman_ss(n)[:3])
        lists.append(arch_web(n)[:4])
    for k in keywords[:4]:
        lists.append(pacman_ss(k)[:8])
        lists.append(arch_web(k)[:8])
        lists.append(aur_web(k)[:8])
    if not any(lists):
        lists.append(pacman_ss(q))
        lists.append(arch_web(q))
        lists.append(aur_web(q))
    extra = []
    inst = installed_set()
    for n in names:
        if not any(p.get("name") == n for lst in lists for p in lst):
            extra.append(
                hit(n, repo="?", desc="suggéré par l’IA", installed=n in inst)
            )
    items = merge(lists + [extra], prefer=names)
    for p in items:
        if p["name"] in names and why:
            p["why"] = why
    if repo and repo.lower() not in ("all", ""):
        filtered = filter_repo(items, repo)
        if not filtered:
            filtered = list_sync_repo(repo, q) or list_sync_repo(repo, keywords[0] if keywords else "")
        items = filtered
    return {
        "ok": True,
        "items": items,
        "why": why,
        "mode": "need",
        "source": repo,
    }


def cat_items(cid):
    inst = installed_set()
    for c in CATALOG:
        if c["id"] != cid:
            continue
        items = []
        for name, desc in c["pkgs"]:
            items.append(
                hit(
                    name,
                    repo="catalog",
                    desc=desc,
                    installed=name in inst,
                    aur=name.endswith("-bin") or name in ("spotify", "obsidian", "zoom"),
                )
            )
        return {"ok": True, "items": items, "why": "", "mode": "cat"}
    return {"ok": True, "items": [], "why": "", "mode": "cat"}


def installed_items(repo=""):
    repo = (repo or "").strip().lower()
    allow = None
    if repo and repo not in ("all", ""):
        if repo == "aur":
            allow = set(run_capture(["pacman", "-Qqm"], timeout=20).split())
        else:
            allow = set()
            for line in run_capture(["pacman", "-Sl", "--", repo], timeout=30).splitlines():
                parts = line.split()
                if len(parts) >= 2:
                    allow.add(parts[1])
    raw = run_capture(["expac", "-Q", "%n\t%v\t%d"], timeout=20)
    inst = []
    if raw:
        for line in raw.splitlines():
            parts = line.split("\t", 2)
            if len(parts) < 1:
                continue
            name = parts[0]
            if allow is not None and name not in allow:
                continue
            inst.append(
                hit(
                    name,
                    repo=repo if repo and repo not in ("all", "") else "local",
                    ver=parts[1] if len(parts) > 1 else "",
                    desc=parts[2] if len(parts) > 2 else "",
                    installed=True,
                    aur=repo == "aur",
                )
            )
    else:
        names = run_capture(["pacman", "-Qqe"], timeout=20).split()
        for n in names:
            if allow is not None and n not in allow:
                continue
            inst.append(hit(n, repo=repo or "local", installed=True, aur=repo == "aur"))
    inst.sort(key=lambda p: p["name"])
    return {
        "ok": True,
        "items": inst[:500],
        "why": "",
        "mode": "installed",
        "source": repo,
    }


def updates_items(repo=""):
    h = helper()
    cmd = [h, "-Qu"] if h != "pacman" else ["pacman", "-Qu"]
    raw = run_capture(cmd, timeout=40)
    repo = (repo or "").strip().lower()
    allow = None
    if repo and repo not in ("all", ""):
        if repo == "aur":
            allow = set(run_capture(["pacman", "-Qqm"], timeout=20).split())
        else:
            allow = set()
            for line in run_capture(["pacman", "-Sl", "--", repo], timeout=30).splitlines():
                parts = line.split()
                if len(parts) >= 2:
                    allow.add(parts[1])
    items = []
    for line in raw.splitlines():
        parts = line.split()
        if len(parts) < 1:
            continue
        name = parts[0]
        if allow is not None and name not in allow:
            continue
        ver = " → ".join(parts[1:4]) if len(parts) > 1 else ""
        rname = repo if repo and repo not in ("all", "") else "update"
        p = hit(name, repo=rname, ver=ver, desc="mise à jour dispo", installed=True)
        p["update"] = True
        if repo == "aur":
            p["aur"] = True
        items.append(p)
    return {
        "ok": True,
        "items": items,
        "why": "",
        "mode": "updates",
        "count": len(items),
        "source": repo,
    }


def cats():
    inst = installed_set()
    out = []
    for c in CATALOG:
        n_on = sum(1 for name, _ in c["pkgs"] if name in inst)
        out.append(
            {
                "id": c["id"],
                "label": c["label"],
                "glyph": c["glyph"],
                "have": n_on,
                "total": len(c["pkgs"]),
            }
        )
    return {"ok": True, "cats": out, "helper": helper()}


def pacman_repos():
    try:
        return set(run_capture(["pacman-conf", "--repo-list"], timeout=10).split())
    except Exception:
        return set()


def pacman_conf_text():
    try:
        return Path("/etc/pacman.conf").read_text()
    except Exception:
        return ""


def repo_enabled(section: str):
    repos = pacman_repos()
    if section in repos:
        return True
    txt = pacman_conf_text()
    return bool(re.search(rf"(?m)^\s*\[\s*{re.escape(section)}\s*\]", txt))


KNOWN_REPOS = [
    {
        "id": "aur",
        "label": "AUR",
        "glyph": "󰣇",
        "kind": "helper",
        "desc": "Arch User Repository via paru/yay (build local)",
    },
]


def load_repo_catalog():
    path = Path(__file__).resolve().parent / "pkgs_repos.json"
    raw = read_json(path, [])
    if isinstance(raw, list) and raw:
        return raw
    return list(KNOWN_REPOS)


def repos_list(query: str = ""):
    h = helper()
    live = pacman_repos()
    catalog = load_repo_catalog()
    q = (query or "").strip().lower()
    items = []
    seen = set()

    for r in catalog:
        rid = str(r.get("id") or "").strip()
        if not rid:
            continue
        section = str(r.get("section") or rid)
        row = {
            "id": rid,
            "label": r.get("label") or section,
            "glyph": r.get("glyph") or "󰏒",
            "kind": r.get("kind") or "pacman",
            "section": section,
            "desc": r.get("desc") or "",
            "group": r.get("group") or "community",
            "servers": r.get("servers") or [],
            "include": r.get("include") or "",
            "enable": r.get("enable") or "generic",
            "title": r.get("title") or "",
        }
        if row["kind"] == "helper":
            row["enabled"] = h != "pacman"
            row["status"] = f"helper · {h}" if h != "pacman" else "installe paru ou yay"
        else:
            on = section in live or repo_enabled(section)
            row["enabled"] = on
            row["status"] = "actif" if on else "dispo · wiki Arch"
        hay = " ".join(
            [
                row["id"],
                row["label"],
                row["desc"],
                row["group"],
                row.get("title") or "",
                section,
            ]
        ).lower()
        if q and q not in hay:
            continue
        items.append(row)
        seen.add(section.lower())
        seen.add(rid.lower())

    for name in sorted(live):
        if name.lower() in seen:
            continue
        if q and q not in name.lower():
            continue
        items.append(
            {
                "id": name,
                "label": name,
                "glyph": "󰏗",
                "kind": "pacman",
                "section": name,
                "desc": "déjà dans ton pacman.conf",
                "group": "local",
                "servers": [],
                "include": "",
                "enable": "none",
                "enabled": True,
                "status": "actif (local)",
            }
        )

    items.sort(
        key=lambda x: (
            0 if x.get("enabled") else 1,
            {"official": 0, "distro": 1, "helper": 2, "security": 3, "perf": 4}.get(
                x.get("group"), 9
            ),
            str(x.get("label") or "").lower(),
        )
    )
    return {
        "ok": True,
        "items": items,
        "helper": h,
        "mode": "repos",
        "total": len(items),
        "live": sorted(live),
    }


def enable_repo(rid: str):
    rid = (rid or "").strip()
    catalog = load_repo_catalog()
    known = {str(r.get("id") or "").lower(): r for r in catalog}
    r = known.get(rid.lower())
    if not r:
        return {"ok": False, "error": "repo inconnu"}
    kind = r.get("kind") or "pacman"
    section = str(r.get("section") or r.get("id") or "")
    enable = r.get("enable") or ("helper" if kind == "helper" else "generic")

    if kind == "helper" or rid.lower() == "aur":
        if helper() != "pacman":
            return {"ok": True, "status": "AUR déjà dispo via " + helper()}
        term(
            "Installer paru",
            "sudo pacman -S --needed base-devel git && "
            "cd /tmp && rm -rf paru && git clone https://aur.archlinux.org/paru.git && "
            "cd paru && makepkg -si",
        )
        return {"ok": True}

    if rid.lower() == "blackarch" or section == "blackarch":
        if repo_enabled("blackarch"):
            return {"ok": True, "status": "BlackArch déjà actif"}
        term(
            "Activer BlackArch",
            "set -e; "
            "curl -O https://blackarch.org/strap.sh; "
            "chmod +x strap.sh; "
            "sudo ./strap.sh; "
            "sudo pacman -Sy",
        )
        return {"ok": True}

    if rid.lower() == "chaotic-aur" or section == "chaotic-aur":
        if repo_enabled("chaotic-aur"):
            return {"ok": True, "status": "Chaotic déjà actif"}
        term(
            "Activer Chaotic-AUR",
            "set -e; "
            "sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com; "
            "sudo pacman-key --lsign-key 3056513887B78AEB; "
            "sudo pacman -U --noconfirm "
            "'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' "
            "'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'; "
            "grep -q '\\[chaotic-aur\\]' /etc/pacman.conf || "
            "printf '\\n[chaotic-aur]\\nInclude = /etc/pacman.d/chaotic-mirrorlist\\n' | sudo tee -a /etc/pacman.conf; "
            "sudo pacman -Sy",
        )
        return {"ok": True}

    if rid.lower() == "archlinuxcn" or section == "archlinuxcn":
        if repo_enabled("archlinuxcn"):
            return {"ok": True, "status": "ArchLinuxCN déjà actif"}
        term(
            "Activer ArchLinuxCN",
            "set -e; "
            "grep -q '\\[archlinuxcn\\]' /etc/pacman.conf || "
            "printf '\\n[archlinuxcn]\\nServer = https://repo.archlinuxcn.org/\\$arch\\n' | sudo tee -a /etc/pacman.conf; "
            "sudo pacman -Sy --needed archlinuxcn-keyring; "
            "sudo pacman -Sy",
        )
        return {"ok": True}

    if rid.lower() == "multilib" or section == "multilib":
        if repo_enabled("multilib"):
            return {"ok": True, "status": "Multilib déjà actif"}
        term(
            "Activer Multilib",
            "set -e; "
            "sudo sed -i '/^\\s*#\\s*\\[multilib\\]/,/^\\s*$/{s/^\\s*#\\s*//}' /etc/pacman.conf; "
            "grep -q '^\\[multilib\\]' /etc/pacman.conf || "
            "printf '\\n[multilib]\\nInclude = /etc/pacman.d/mirrorlist\\n' | sudo tee -a /etc/pacman.conf; "
            "sudo pacman -Sy",
        )
        return {"ok": True}

    if enable == "alhp":
        if repo_enabled(section):
            return {"ok": True, "status": section + " déjà actif"}
        inc = r.get("include") or "/etc/pacman.d/alhp-mirrorlist"
        term(
            "Activer ALHP " + section,
            "set -e; "
            "sudo pacman -S --needed alhp-keyring alhp-mirrorlist || "
            "paru -S --needed alhp-keyring alhp-mirrorlist; "
            f"grep -q '\\[{section}\\]' /etc/pacman.conf || "
            f"printf '\\n[{section}]\\nInclude = {inc}\\n' | sudo tee -a /etc/pacman.conf; "
            "sudo pacman -Sy",
        )
        return {"ok": True}

    if section.startswith("cachyos") or rid.lower().startswith("cachyos"):
        if repo_enabled(section):
            return {"ok": True, "status": section + " déjà actif"}
        return {
            "ok": False,
            "error": "Repos Cachy : via setup CachyOS / cachyos-rate-mirrors",
        }

    if section in ("core", "extra"):
        return {"ok": True, "status": section + " est un repo officiel Arch"}

    if repo_enabled(section):
        return {"ok": True, "status": section + " déjà actif"}

    servers = r.get("servers") or []
    include = (r.get("include") or "").strip()
    if not servers and not include:
        return {"ok": False, "error": "pas de Server/Include pour " + section}

    lines = [f"[{section}]"]
    if include:
        lines.append(f"Include = {include}")
    for s in servers[:3]:
        lines.append(f"Server = {s}")
    block = "\\n".join(lines).replace("'", "'\\''")
    term(
        "Activer " + section,
        "set -e; "
        f"grep -q '\\[{section}\\]' /etc/pacman.conf && echo 'déjà présent' && exit 0; "
        f"printf '\\n{block}\\n' | sudo tee -a /etc/pacman.conf; "
        "echo; echo 'Note: certains repos demandent une clé PGP (wiki Arch).'; "
        "sudo pacman -Sy || true",
    )
    return {"ok": True}


def add_custom_repo(name: str, include_or_server: str):
    name = safe_name(name)
    src = (include_or_server or "").strip()
    if not name or not src:
        return {"ok": False, "error": "nom + Include/Server requis"}
    if re.search(r"[;&|`$]", src):
        return {"ok": False, "error": "caractères interdits"}
    if src.startswith("Include") or src.startswith("Server"):
        line = src
    elif src.startswith("/") or src.startswith("http"):
        line = ("Include = " if src.startswith("/") else "Server = ") + src
    else:
        return {"ok": False, "error": "chemin Include ou URL Server"}
    if repo_enabled(name):
        return {"ok": True, "status": name + " déjà présent"}
    esc_line = line.replace("'", "'\\''")
    term(
        "Ajouter repo " + name,
        "set -e; "
        f"printf '\\n[{name}]\\n{esc_line}\\n' | sudo tee -a /etc/pacman.conf; "
        "sudo pacman -Sy",
    )
    return {"ok": True}


def install(name):
    name = safe_name(name)
    if not name:
        return {"ok": False, "error": "nom invalide"}
    h = helper()
    if h == "pacman":
        term("Installer " + name, f"sudo pacman -S --needed {name}")
    else:
        term("Installer " + name, f"{h} -S --needed {name}")
    return {"ok": True}


def remove(name):
    name = safe_name(name)
    if not name:
        return {"ok": False, "error": "nom invalide"}
    h = helper()
    if h == "pacman":
        term("Retirer " + name, f"sudo pacman -Rns {name}")
    else:
        term("Retirer " + name, f"{h} -Rns {name}")
    return {"ok": True}


def upgrade():
    h = helper()
    if h == "pacman":
        term("Mise à jour", "sudo pacman -Syu")
    else:
        term("Mise à jour", f"{h} -Syu")
    return {"ok": True}


def upgrade_one(name):
    name = safe_name(name)
    if not name:
        return {"ok": False, "error": "nom invalide"}
    h = helper()
    if h == "pacman":
        term("MAJ " + name, f"sudo pacman -S --needed {name}")
    else:
        term("MAJ " + name, f"{h} -S --needed {name}")
    return {"ok": True}


def dispatch(cmd, args):
    args = list(args or [])
    if cmd == "pkgs-cats":
        return cats()
    if cmd == "pkgs-sources":
        return sources_list()
    if cmd == "pkgs-search":
        if len(args) >= 2:
            return search_name(args[1], args[0])
        return search_name(args[0] if args else "", "")
    if cmd == "pkgs-need":
        if len(args) >= 2:
            return search_need(args[1], args[0])
        return search_need(args[0] if args else "", "")
    if cmd == "pkgs-cat":
        return cat_items(args[0] if args else "")
    if cmd == "pkgs-installed":
        return installed_items(args[0] if args else "")
    if cmd == "pkgs-updates":
        return updates_items(args[0] if args else "")
    if cmd == "pkgs-repos":
        return repos_list(" ".join(args).strip() if args else "")
    if cmd == "pkgs-repo-enable":
        return enable_repo(args[0] if args else "")
    if cmd == "pkgs-repo-add":
        if len(args) < 2:
            return {"ok": False, "error": "usage: name Include|Server"}
        return add_custom_repo(args[0], " ".join(args[1:]))
    if cmd == "pkgs-install":
        return install(args[0] if args else "")
    if cmd == "pkgs-remove":
        return remove(args[0] if args else "")
    if cmd == "pkgs-upgrade":
        return upgrade()
    if cmd == "pkgs-upgrade-one":
        return upgrade_one(args[0] if args else "")
    return {"ok": False, "error": "unknown " + cmd}
