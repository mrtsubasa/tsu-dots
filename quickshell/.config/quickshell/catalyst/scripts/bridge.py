#!/usr/bin/env python3
"""Backend for catalyst Quickshell panels. Prints one JSON object to stdout."""
from __future__ import annotations

import json
import os
import re
import shlex
import shutil
import socket
import subprocess
import sys
import time
from pathlib import Path

HOME = Path.home()
_SCRIPT_DIR = Path(__file__).resolve().parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))
import pkgs_backend
PANEL_JSON = HOME / ".config/spell-shell/panel.json"
RICE_JSON = HOME / ".config/waybar/rice.json"
COMMS_JSON = HOME / ".config/spell-shell/comms.json"
COMMS_RECENT = HOME / ".cache/catalyst/comms-recent.json"
BOTS_JSON = HOME / ".config/spell-shell/bots.json"
TARGET_TXT = HOME / ".config/waybar/target.txt"
WALL_FILE = HOME / ".cache/matugen/current-wallpaper"
COLORS = HOME / ".cache/matugen/spell-colors.json"
RECENT = HOME / ".cache/spell-shell/recent.json"
VM_DIR = HOME / "VMs"
SCRIPTS_CUSTOM = HOME / "Scripts"
CHAT_SH = HOME / ".config/niri/scripts/ai/chat.sh"
IMAGE_SH = HOME / ".config/niri/scripts/ai/image.sh"
NOTES = HOME / ".config/spell-shell/notes.md"


def out(obj):
    sys.stdout.write(json.dumps(obj, ensure_ascii=False))
    sys.stdout.flush()


def fail(msg):
    out({"ok": False, "error": str(msg)})
    sys.exit(0)


def run_capture(cmd, timeout=20):
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


def spawn(*argv):
    if not argv:
        return
    env = os.environ
    if env.get("HYPRLAND_INSTANCE_SIGNATURE"):
        subprocess.Popen(
            list(argv),
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
        return
    subprocess.Popen(
        ["niri", "msg", "action", "spawn", "--", *argv],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def term(title, cmd):
    script = f"echo; echo '  {title}'; echo; {cmd}; echo; exec bash"
    spawn("alacritty", "-t", title, "-e", "bash", "-lc", script)


def which(bin_name):
    return shutil.which(bin_name) is not None


def read_json(path: Path, default):
    try:
        return json.loads(path.read_text())
    except Exception:
        return default


def write_json(path: Path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")


def copy_text(s: str):
    try:
        p = subprocess.Popen(["wl-copy"], stdin=subprocess.PIPE)
        p.communicate((s or "").encode(), timeout=3)
    except Exception:
        pass


def login_name():
    return run_capture(["whoami"]) or os.environ.get("USER", "user")


def gecos_name():
    login = login_name()
    line = run_capture(["getent", "passwd", login])
    parts = line.split(":")
    gecos = parts[4].split(",")[0].strip() if len(parts) > 4 else ""
    return gecos or login


def host_name():
    return run_capture(["hostname"]) or "host"


def os_pretty():
    txt = Path("/etc/os-release").read_text() if Path("/etc/os-release").exists() else ""
    for key in ("PRETTY_NAME=", "NAME="):
        for line in txt.splitlines():
            if line.startswith(key):
                return line[len(key) :].strip().strip('"') or "Linux"
    return "Linux"


def kernel():
    return run_capture(["uname", "-r"])


def session_wm():
    return "Hyprland" if os.environ.get("HYPRLAND_INSTANCE_SIGNATURE") else "niri"


def uptime():
    try:
        secs = float(Path("/proc/uptime").read_text().split()[0])
    except Exception:
        secs = 0
    h = int(secs // 3600)
    m = int((secs % 3600) // 60)
    return f"{h}h{m:02d}min"


def default_avatar():
    login = login_name()
    for p in [
        HOME / ".config/spell-shell/avatar.png",
        HOME / ".config/spell-shell/avatar.jpg",
        HOME / ".face",
        HOME / ".face.icon",
        Path(f"/var/lib/AccountsService/icons/{login}"),
    ]:
        if p.is_file():
            return str(p)
    return ""


def current_wallpaper():
    try:
        p = WALL_FILE.read_text().strip()
        return p if p and Path(p).is_file() else ""
    except Exception:
        return ""


def load_panel():
    cfg = {
        "slot": "mr",
        "width": 360,
        "bg": "follow",
        "veil": 0.58,
        "grain": 0.12,
        "vignette": True,
        "halo": True,
        "show_clock": True,
        "show_stats": True,
        "show_actions": True,
        "show_power": True,
        "display_name": "",
        "avatar": "",
        "os_label": "",
        "show_os": True,
        "radius": 16,
        "glow": "soft",
        "border": "accent",
        "density": "normal",
        "avatar_shape": "circle",
        "clock12": False,
        "clock_sec": False,
        "clock_size": "m",
        "show_user": True,
        "show_meta": True,
        "show_date": True,
        "status": "",
        "height_mode": "auto",
        "bar_style": "apple",
        "panel_style": "follow",
    }
    cfg.update(read_json(PANEL_JSON, {}))
    return cfg


def rice_style():
    rice = read_json(RICE_JSON, {})
    return rice.get("style") or "islands"


def resolve_panel_style(cfg):
    p = cfg.get("panel_style") or "follow"
    return rice_style() if p == "follow" else p


def resolve_bg(cfg):
    bg = cfg.get("bg") or "follow"
    if bg in ("follow", ""):
        return current_wallpaper()
    if bg == "none":
        return ""
    return bg if Path(bg).is_file() else current_wallpaper()


def resolve_avatar(cfg):
    av = cfg.get("avatar") or ""
    if av == "none":
        return ""
    if av and Path(av).is_file():
        return av
    return default_avatar()


def identity():
    cfg = load_panel()
    name = (cfg.get("display_name") or "").strip() or gecos_name()
    os_label = ""
    if cfg.get("show_os", True):
        os_label = (cfg.get("os_label") or "").strip() or os_pretty()
    av = resolve_avatar(cfg)
    bg = resolve_bg(cfg)
    login = login_name()
    return {
        "ok": True,
        "cfg": cfg,
        "userName": name,
        "userLogin": login,
        "userInitial": (name[:1].upper() if name else "?"),
        "hostName": host_name(),
        "osText": os_label,
        "showOs": bool(cfg.get("show_os", True)),
        "kernelText": kernel(),
        "wmText": session_wm(),
        "uptimeText": uptime(),
        "userStatus": (cfg.get("status") or "").strip(),
        "avatar": av,
        "hasAvatar": bool(av),
        "bg": bg,
        "hasBg": bool(bg),
        "wallpaper": current_wallpaper(),
        "style": resolve_panel_style(cfg),
        "grain": str(HOME / ".cache/spell-shell/grain.png"),
    }


def clock_text(hour12, seconds):
    fmt = {
        (False, False): "+%H:%M",
        (False, True): "+%H:%M:%S",
        (True, False): "+%-I:%M %p",
        (True, True): "+%-I:%M:%S %p",
    }[(bool(hour12), bool(seconds))]
    now = run_capture(["date", fmt])
    date = run_capture(["date", "+%A %d/%m/%Y"])
    return now, date


def cpu_ram_disk():
    cpu = 0.0
    try:
        def read():
            line = Path("/proc/stat").read_text().splitlines()[0]
            v = [int(x) for x in line.split()[1:]]
            idle = v[3] + (v[4] if len(v) > 4 else 0)
            return sum(v), idle
        cache = HOME / ".cache/spell-shell/cpu-prev.json"
        now = read()
        prev = read_json(cache, None)
        write_json(cache, {"t": now[0], "i": now[1]})
        if prev:
            dt = now[0] - int(prev.get("t", 0))
            di = now[1] - int(prev.get("i", 0))
            if dt > 0:
                cpu = max(0.0, min(1.0, 1.0 - di / dt))
    except Exception:
        cpu = 0.0
    ram_p, ram_t = 0.0, "N/A"
    try:
        mi = Path("/proc/meminfo").read_text()
        kv = {}
        for line in mi.splitlines():
            k, v, *_ = line.replace(":", " ").split()
            kv[k] = int(v)
        total = kv.get("MemTotal", 0)
        avail = kv.get("MemAvailable", 0)
        used = total - avail
        if total:
            ram_p = used / total
            ram_t = f"{used/1048576:.1f}/{total/1048576:.1f} GiB"
    except Exception:
        pass
    disk_p, disk_t = 0.0, "N/A"
    try:
        line = run_capture(["df", "-B1", "/"]).splitlines()[1]
        f = line.split()
        total = float(f[1])
        avail = float(f[3])
        if total:
            disk_p = 1.0 - avail / total
            disk_t = f"{avail/1073741824:.0f} Go libres"
    except Exception:
        pass
    return cpu, ram_p, ram_t, disk_p, disk_t


def sysinfo():
    cfg = load_panel()
    clock, date = clock_text(cfg.get("clock12"), cfg.get("clock_sec"))
    cpu, ram_p, ram_t, disk_p, disk_t = cpu_ram_disk()
    return {
        "ok": True,
        "clock": clock,
        "date": date,
        "uptime": uptime(),
        "cpu": cpu,
        "ram": ram_p,
        "ramText": ram_t,
        "disk": disk_p,
        "diskText": disk_t,
        "wallpaper": current_wallpaper(),
    }


def studio(cmd: str):
    cfg = load_panel()
    if cmd.startswith("slot:"):
        cfg["slot"] = cmd.split(":", 1)[1]
    elif cmd.startswith("panel:style:"):
        cfg["panel_style"] = cmd.split(":", 2)[2]
    elif cmd.startswith("identity:"):
        style = cmd.split(":", 1)[1].strip()
        cfg["panel_style"] = style
        cfg["bar_style"] = style
        rice = read_json(RICE_JSON, {})
        waybar_styles = {"apple", "islands", "silverwolf", "lain", "tsubasa", "initiald", "custom"}
        rice["style"] = style if style in waybar_styles else "islands"
        write_json(RICE_JSON, rice)
    elif cmd.startswith("name:"):
        cfg["display_name"] = cmd.split(":", 1)[1].strip()
    elif cmd.startswith("status:"):
        cfg["status"] = cmd.split(":", 1)[1].strip()
    elif cmd == "os:auto":
        cfg["os_label"] = ""
        cfg["show_os"] = True
    elif cmd == "os:hide":
        cfg["show_os"] = False
    elif cmd.startswith("os:"):
        cfg["os_label"] = cmd.split(":", 1)[1].strip()
        cfg["show_os"] = True
    elif cmd == "avatar:none":
        cfg["avatar"] = "none"
    elif cmd == "avatar:auto":
        cfg["avatar"] = ""
    elif cmd.startswith("avatar:set:"):
        cfg["avatar"] = cmd.split(":", 2)[2]
    elif cmd == "bg:none":
        cfg["bg"] = "none"
    elif cmd == "bg:follow":
        cfg["bg"] = "follow"
    elif cmd.startswith("bg:set:"):
        cfg["bg"] = cmd.split(":", 2)[2]
    elif cmd.startswith("veil:"):
        try:
            cfg["veil"] = float(cmd.split(":", 1)[1])
        except ValueError:
            pass
    elif cmd.startswith("grain:"):
        try:
            cfg["grain"] = float(cmd.split(":", 1)[1])
        except ValueError:
            pass
    elif cmd.startswith("width:"):
        try:
            cfg["width"] = int(cmd.split(":", 1)[1])
        except ValueError:
            pass
    elif cmd.startswith("radius:"):
        try:
            cfg["radius"] = int(cmd.split(":", 1)[1])
        except ValueError:
            pass
    elif cmd.startswith("glow:"):
        cfg["glow"] = cmd.split(":", 1)[1]
    elif cmd.startswith("border:"):
        cfg["border"] = cmd.split(":", 1)[1]
    elif cmd.startswith("density:"):
        cfg["density"] = cmd.split(":", 1)[1]
    elif cmd.startswith("shape:"):
        cfg["avatar_shape"] = cmd.split(":", 1)[1]
    elif cmd.startswith("clock-size:"):
        cfg["clock_size"] = cmd.split(":", 1)[1]
    elif cmd == "clock12:on":
        cfg["clock12"] = True
    elif cmd == "clock12:off":
        cfg["clock12"] = False
    elif cmd == "tog:clocksec":
        cfg["clock_sec"] = not cfg.get("clock_sec")
    elif cmd.startswith("tog:"):
        key = {
            "clock": "show_clock",
            "stats": "show_stats",
            "actions": "show_actions",
            "power": "show_power",
            "vignette": "vignette",
            "halo": "halo",
            "user": "show_user",
            "meta": "show_meta",
            "date": "show_date",
        }.get(cmd.split(":", 1)[1])
        if key:
            cfg[key] = not bool(cfg.get(key, True))
    elif cmd.startswith("height:"):
        cfg["height_mode"] = cmd.split(":", 1)[1]
    elif cmd.startswith("bar:style:"):
        style = cmd.split(":", 2)[2].strip()
        cfg["bar_style"] = style
        cfg["panel_style"] = style
        rice = read_json(RICE_JSON, {})
        rice["style"] = style if style in {"apple", "islands", "silverwolf", "lain", "tsubasa", "initiald", "custom"} else "islands"
        write_json(RICE_JSON, rice)
    elif cmd.startswith("bar:mons:"):
        rice = read_json(RICE_JSON, {})
        rice["bar_output"] = cmd.split(":", 2)[2].strip()
        write_json(RICE_JSON, rice)
    elif cmd.startswith("bar:height:"):
        try:
            cfg["bar_height"] = int(cmd.split(":", 2)[2])
        except ValueError:
            pass
    elif cmd.startswith("bar:opacity:"):
        try:
            cfg["bar_opacity"] = float(cmd.split(":", 2)[2])
        except ValueError:
            pass
    elif cmd.startswith("bar:font:"):
        try:
            cfg["bar_font"] = int(cmd.split(":", 2)[2])
        except ValueError:
            pass
    elif cmd == "bar:tog:border":
        cfg["bar_border"] = not bool(cfg.get("bar_border", True))
    elif cmd.startswith("bar:tog:"):
        key = cmd.split(":", 2)[2]
        rice = read_json(RICE_JSON, {})
        mods = rice.get("modules") if isinstance(rice.get("modules"), dict) else {}
        mods[key] = not bool(mods.get(key, True))
        rice["modules"] = mods
        write_json(RICE_JSON, rice)
    elif cmd == "dock:on":
        rice = read_json(RICE_JSON, {})
        rice["dock"] = True
        write_json(RICE_JSON, rice)
        d = read_json(HOME / ".config/dock/dock.json", {})
        d["enabled"] = True
        write_json(HOME / ".config/dock/dock.json", d)
    elif cmd == "dock:off":
        rice = read_json(RICE_JSON, {})
        rice["dock"] = False
        write_json(RICE_JSON, rice)
        d = read_json(HOME / ".config/dock/dock.json", {})
        d["enabled"] = False
        write_json(HOME / ".config/dock/dock.json", d)
    elif cmd.startswith("dock:style:"):
        style = cmd.split(":", 2)[2].strip()
        patch_dock("theme", style)
        rice = read_json(RICE_JSON, {})
        rice["dock_style"] = style
        write_json(RICE_JSON, rice)
    elif cmd.startswith("dock:size:"):
        try:
            patch_dock("icon_size", int(cmd.split(":", 2)[2]))
        except ValueError:
            pass
    elif cmd.startswith("dock:zoom:"):
        try:
            patch_dock("max_scale", float(cmd.split(":", 2)[2]))
        except ValueError:
            pass
    elif cmd.startswith("dock:pos:"):
        patch_dock("position", cmd.split(":", 2)[2].strip())
    elif cmd.startswith("dock:align:"):
        patch_dock("align", cmd.split(":", 2)[2].strip())
    elif cmd.startswith("dock:opacity:"):
        try:
            patch_dock("opacity", float(cmd.split(":", 2)[2]))
        except ValueError:
            pass
    elif cmd.startswith("dock:margin:"):
        try:
            patch_dock("margin_bottom", int(cmd.split(":", 2)[2]))
        except ValueError:
            pass
    elif cmd.startswith("dock:gap:"):
        try:
            patch_dock("gap", int(cmd.split(":", 2)[2]))
        except ValueError:
            pass
    elif cmd.startswith("dock:pad:"):
        try:
            patch_dock("padding", int(cmd.split(":", 2)[2]))
        except ValueError:
            pass
    elif cmd.startswith("dock:labels:"):
        patch_dock("show_labels", cmd.split(":", 2)[2].strip())
    elif cmd == "dock:tog:pill":
        d = read_json(HOME / ".config/dock/dock.json", {})
        patch_dock("show_pill", not bool(d.get("show_pill", True)))
    elif cmd == "dock:tog:dots":
        d = read_json(HOME / ".config/dock/dock.json", {})
        patch_dock("show_dots", not bool(d.get("show_dots", True)))
    elif cmd == "dock:tog:autohide":
        d = read_json(HOME / ".config/dock/dock.json", {})
        patch_dock("autohide", not bool(d.get("autohide", False)))
    write_json(PANEL_JSON, cfg)
    return identity()


def patch_dock(key, value):
    path = HOME / ".config/dock/dock.json"
    data = read_json(path, {})
    data[key] = value
    write_json(path, data)


def omarchy_path() -> Path:
    return Path(os.environ.get("OMARCHY_PATH") or (HOME / ".local/share/omarchy"))


def omarchy_env():
    env = os.environ.copy()
    root = str(omarchy_path())
    env["OMARCHY_PATH"] = root
    bin_dir = f"{root}/bin"
    path = env.get("PATH", "")
    if bin_dir not in path.split(":"):
        env["PATH"] = f"{bin_dir}:{HOME}/.local/bin:{path}"
    return env


_OMARCHY_MENU = None


def omarchy_menu_raw():
    global _OMARCHY_MENU
    if _OMARCHY_MENU is not None:
        return _OMARCHY_MENU
    path = omarchy_path() / "default/omarchy/omarchy-menu.jsonc"
    if not path.is_file():
        _OMARCHY_MENU = {}
        return _OMARCHY_MENU
    text = path.read_text(encoding="utf-8", errors="replace")
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    text = re.sub(r"(?m)^\s*//.*?$", "", text)
    text = re.sub(r",\s*([}\]])", r"\1", text)
    try:
        _OMARCHY_MENU = json.loads(text)
    except Exception:
        _OMARCHY_MENU = {}
    return _OMARCHY_MENU


def omarchy_has_children(menu: dict, item_id: str) -> bool:
    prefix = f"{item_id}."
    return any(k.startswith(prefix) for k in menu)


def omarchy_action_kind(action: str | None) -> str:
    if not action:
        return "none"
    a = action
    if "omarchy-shell" in a or "hyprctl" in a or "omarchy-hyprland" in a:
        return "hyprland"
    if "hyprland" in a.lower() and "omarchy-refresh-hyprland" in a:
        return "hyprland"
    if "/hypr/" in a or "looknfeel.lua" in a or "bindings.lua" in a:
        return "hyprland"
    return "ok"


def omarchy_adapt_action(action: str) -> str:
    a = action.strip()
    a = re.sub(
        r"omarchy-launch-floating-terminal-with-presentation\s+'([^']+)'",
        r"\1",
        a,
    )
    a = re.sub(
        r"omarchy-launch-floating-terminal-with-presentation\s+(\S+)",
        r"\1",
        a,
    )
    a = re.sub(r"xdg-terminal-exec\s+--app-id=org\.omarchy\.terminal\s+", "", a)
    a = re.sub(r"uwsm-app\s+--\s+", "", a)
    return a.strip()


def omarchy_needs_term(cmd: str) -> bool:
    keys = (
        "omarchy-install",
        "omarchy-remove",
        "omarchy-pkg-",
        "omarchy-update",
        "omarchy-channel",
        "omarchy-refresh",
        "omarchy-setup",
        "omarchy-theme-install",
        "omarchy-theme-update",
        "omarchy-theme-remove",
        "omarchy-webapp",
        "omarchy-tui-",
        "omarchy-windows-vm",
        "omarchy-drive-password",
        "omarchy-sudo",
        "omarchy-voxtype",
        "passwd",
        "omarchy-install-dev-env",
        "omarchy-remove-dev-env",
        "omarchy-install-font",
        "omarchy-install-browser",
        "omarchy-install-terminal",
        "omarchy-install-and-launch",
        "omarchy-install-app",
        "omarchy-install-preinstalls",
        "omarchy-remove-preinstalls",
        "omarchy-update-firmware",
        "omarchy-update-time",
        "omarchy-restart-",
        "omarchy-system-factory-reset",
        "omarchy-plugin-add",
    )
    return any(k in cmd for k in keys)


def omarchy_run_shell(cmd: str, title: str = "Omarchy"):
    env = omarchy_env()
    if omarchy_needs_term(cmd):
        script = f"export OMARCHY_PATH={shlex.quote(env['OMARCHY_PATH'])}; export PATH={shlex.quote(env['PATH'])}; echo; echo '  {title}'; echo; {cmd}; echo; echo 'Entrée pour fermer…'; read -r _"
        spawn("alacritty", "-t", title, "-e", "bash", "-lc", script)
        return
    subprocess.Popen(
        ["bash", "-lc", cmd],
        env=env,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )


def omarchy_menu_list(path: str = ""):
    menu = omarchy_menu_raw()
    path = (path or "").strip()
    items = []
    if path == "__themes__":
        themes = omarchy_themes()
        for name in themes.get("items", []):
            items.append(
                {
                    "id": f"__theme__:{name}",
                    "icon": "󰸌",
                    "label": name,
                    "kind": "theme",
                    "on": name == themes.get("current"),
                }
            )
        items.insert(
            0,
            {
                "id": "__matugen__",
                "icon": "󰋩",
                "label": "Matugen (wallpaper)",
                "kind": "matugen",
                "on": False,
            },
        )
        return {
            "ok": True,
            "path": path,
            "title": "Theme",
            "items": items,
            "current": themes.get("current", ""),
        }

    if path:
        prefix = f"{path}."
        for kid, meta in menu.items():
            if not kid.startswith(prefix):
                continue
            rest = kid[len(prefix) :]
            if "." in rest:
                continue
            items.append(omarchy_menu_item(kid, meta or {}, menu))
    else:
        for kid, meta in menu.items():
            if "." in kid:
                continue
            items.append(omarchy_menu_item(kid, meta or {}, menu))

    title = "Omarchy"
    if path and path in menu:
        title = (menu[path] or {}).get("title") or (menu[path] or {}).get("label") or path

    return {
        "ok": True,
        "path": path,
        "title": title,
        "items": items,
        "current": omarchy_themes().get("current", ""),
    }


def omarchy_menu_item(item_id: str, meta: dict, menu: dict) -> dict:
    action = meta.get("action")
    provider = meta.get("provider")
    kids = omarchy_has_children(menu, item_id)
    kind = "submenu"
    if provider == "apps":
        kind = "launcher"
    elif provider == "fonts":
        kind = "fonts"
    elif item_id == "style.theme":
        kind = "themes"
    elif item_id == "style.background":
        kind = "wall"
    elif action and not kids:
        ak = omarchy_action_kind(action)
        kind = "hyprland" if ak == "hyprland" else "action"
    elif action and kids:
        kind = "submenu"
    elif not kids and not action and not provider:
        kind = "empty"

    return {
        "id": item_id,
        "icon": meta.get("icon") or "󰣇",
        "label": meta.get("label") or item_id.split(".")[-1],
        "kind": kind,
        "on": False,
    }


def omarchy_menu_run(item_id: str):
    item_id = (item_id or "").strip()
    if item_id == "__matugen__":
        return dash_cmd("matugen")
    if item_id.startswith("__theme__:"):
        return omarchy_theme_set(item_id.split(":", 1)[1])

    menu = omarchy_menu_raw()
    meta = menu.get(item_id) or {}
    action = meta.get("action")

    if item_id == "system.lock":
        return dash_cmd("lock")
    if item_id == "system.logout":
        return _omarchy_logout()
    if item_id == "system.reboot":
        return dash_cmd("reboot")
    if item_id == "system.shutdown":
        return dash_cmd("poweroff")
    if item_id == "system.suspend":
        spawn("systemctl", "suspend")
        return {"ok": True}
    if item_id == "trigger.capture.screenshot":
        home = str(HOME)
        spawn(
            "bash",
            "-c",
            f'D=~/Images/Screenshots/$(date +%Y-%m-%d) && mkdir -p "$D" && F="$D/Screenshot_$(date +%H%M%S).png" && grim -g "$(slurp)" "$F" && wl-copy < "$F" && notify-send Screenshot "Saved: $F" -i "$F"',
        )
        return {"ok": True}
    if item_id == "trigger.capture.color":
        if which("hyprpicker"):
            spawn("bash", "-c", "pkill hyprpicker || hyprpicker -a")
            return {"ok": True}
        return {"ok": False, "error": "hyprpicker manquant"}

    if not action:
        return {"ok": False, "error": "pas d'action"}

    if omarchy_action_kind(action) == "hyprland":
        return {"ok": False, "error": "Hyprland only — skip sur Niri", "blocked": True}

    cmd = omarchy_adapt_action(action)
    if "omarchy-theme-set" in cmd and "theme-switcher" in action:
        return {"ok": True, "nav": "__themes__"}
    if cmd.startswith("omarchy-theme-set "):
        name = cmd.split(None, 1)[1].strip().strip("\"'")
        return omarchy_theme_set(name)

    title = meta.get("label") or item_id
    omarchy_run_shell(cmd, title=f"Omarchy · {title}")
    return {"ok": True}


def _omarchy_logout():
    spawn("niri", "msg", "action", "quit", "--skip-confirmation")
    return {"ok": True}


def omarchy_themes():
    themes = HOME / ".local/share/tsu-rice/themes"
    user = HOME / ".config/tsu-rice/themes"
    names = set()
    for base in (themes, user):
        if not base.is_dir():
            continue
        for p in base.iterdir():
            if p.is_dir() and (p / "colors.toml").is_file():
                names.add(p.name)
    current = ""
    name_file = HOME / ".cache/tsu-rice/theme.name"
    if name_file.is_file():
        current = name_file.read_text(encoding="utf-8", errors="replace").strip()
    return {"ok": True, "items": sorted(names), "current": current}


def omarchy_theme_set(name: str):
    name = (name or "").strip()
    if not name:
        return {"ok": False, "error": "theme manquant"}
    apply = HOME / ".config/niri/scripts/theme_switch.sh"
    spawn("bash", str(apply), "apply", name)
    return {"ok": True, "current": name}


def dash_cmd(cmd: str):
    home = str(HOME)
    mapping = {
        "wallpaper": ["bash", f"{home}/.config/niri/scripts/wallpaper.sh", "random"],
        "wallmenu": ["bash", f"{home}/.config/niri/scripts/wallpaper_menu.sh"],
        "clipboard": ["bash", f"{home}/.config/niri/scripts/clipboard-picker.sh"],
        "lock": ["hyprlock"],
        "reloadbar": ["bash", f"{home}/.config/waybar/launch.sh"],
        "hud": ["bash", f"{home}/.config/niri/scripts/blackarch_hud.sh"],
        "dpms": ["bash", f"{home}/.config/niri/scripts/idle-dpms.sh", "off"],
        "poweroff": ["systemctl", "poweroff"],
        "reboot": ["systemctl", "reboot"],
        "matugen": ["bash", f"{home}/.config/niri/scripts/wallpaper.sh", "random"],
    }
    if cmd == "logout":
        if os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
            spawn("hyprctl", "dispatch", "exit")
        else:
            spawn("niri", "msg", "action", "quit", "--skip-confirmation")
        return {"ok": True}
    argv = mapping.get(cmd)
    if argv:
        spawn(*argv)
        return {"ok": True}
    return {"ok": False, "error": f"unknown cmd {cmd}"}


WEATHER_CACHE = HOME / ".cache/catalyst/weather.json"
WMO = {
    0: ("ciel clair", "󰖙"),
    1: ("plutôt clair", "󰖕"),
    2: ("nuageux", "󰖐"),
    3: ("couvert", "󰖐"),
    45: ("brouillard", "󰖑"),
    48: ("brouillard", "󰖑"),
    51: ("bruine", "󰖗"),
    53: ("bruine", "󰖗"),
    55: ("bruine", "󰖗"),
    61: ("pluie", "󰖖"),
    63: ("pluie", "󰖖"),
    65: ("forte pluie", "󰖖"),
    71: ("neige", "󰼶"),
    73: ("neige", "󰼶"),
    75: ("neige", "󰼶"),
    80: ("averses", "󰖖"),
    81: ("averses", "󰖖"),
    82: ("averses", "󰖖"),
    95: ("orage", "󰖓"),
    96: ("orage", "󰖓"),
    99: ("orage", "󰖓"),
}


def weather():
    now = time.time()
    cached = read_json(WEATHER_CACHE, {})
    if cached.get("ts") and now - float(cached["ts"]) < 900 and cached.get("city"):
        cached["ok"] = True
        return cached
    loc_raw = run_capture(
        ["curl", "-sS", "--max-time", "5", "http://ip-api.com/json/?fields=lat,lon,city,country"],
        timeout=6,
    )
    try:
        loc = json.loads(loc_raw) if loc_raw else {}
    except Exception:
        loc = {}
    lat = loc.get("lat")
    lon = loc.get("lon")
    city = loc.get("city") or ""
    if lat is None or lon is None:
        if cached.get("city"):
            cached["ok"] = True
            return cached
        return {"ok": False, "error": "météo indisponible"}
    url = (
        "https://api.open-meteo.com/v1/forecast"
        f"?latitude={lat}&longitude={lon}"
        "&current=temperature_2m,weather_code,apparent_temperature"
        "&daily=temperature_2m_max,temperature_2m_min"
        "&timezone=auto&forecast_days=1"
    )
    raw = run_capture(["curl", "-sS", "--max-time", "8", url], timeout=10)
    try:
        data = json.loads(raw) if raw else {}
    except Exception:
        data = {}
    cur = data.get("current") or {}
    daily = data.get("daily") or {}
    if cur.get("temperature_2m") is None:
        if cached.get("city"):
            cached["ok"] = True
            return cached
        return {"ok": False, "error": "météo indisponible"}
    code = int(cur.get("weather_code") or 0)
    desc, glyph = WMO.get(code, ("variable", "󰖕"))
    highs = daily.get("temperature_2m_max") or [None]
    lows = daily.get("temperature_2m_min") or [None]
    outp = {
        "ok": True,
        "ts": now,
        "city": city,
        "country": loc.get("country") or "",
        "lat": lat,
        "lon": lon,
        "temp": round(float(cur.get("temperature_2m") or 0)),
        "feel": round(float(cur.get("apparent_temperature") or 0)),
        "high": round(float(highs[0] or 0)),
        "low": round(float(lows[0] or 0)),
        "code": code,
        "desc": desc,
        "glyph": glyph,
    }
    write_json(WEATHER_CACHE, outp)
    return outp


# ----- scripts -----
def scan_scripts(filt: str):
    items = []

    def push(path: Path, tag: str):
        if path.name.startswith("."):
            return
        items.append({"name": path.name, "dir": tag, "path": str(path)})

    def scan(root: Path, tag: str, recursive: bool, only_exec: bool):
        if not root.is_dir():
            return
        try:
            entries = list(root.iterdir())
        except OSError:
            return
        for p in entries:
            if p.is_dir():
                if recursive and not p.name.startswith("."):
                    scan(p, tag, True, only_exec)
                continue
            if not p.is_file():
                continue
            if only_exec and not (p.name.endswith((".sh", ".py")) or p.name == "run.sh"):
                continue
            push(p, tag)

    scan(HOME / ".config/niri/scripts", "niri", False, False)
    scan(HOME / ".local/scripts", "local", True, True)
    scan(SCRIPTS_CUSTOM, "custom", False, False)
    f = (filt or "").lower()
    if f:
        items = [s for s in items if f in s["name"].lower() or f in s["dir"]]
    items.sort(key=lambda s: (s["dir"], s["name"].lower()))
    return items


def scripts_new(name: str):
    name = (name or "").strip()
    if not name:
        fail("nom vide")
    if not name.endswith(".sh"):
        name += ".sh"
    SCRIPTS_CUSTOM.mkdir(parents=True, exist_ok=True)
    path = SCRIPTS_CUSTOM / name
    if path.exists():
        fail("existe déjà")
    path.write_text('#!/bin/bash\nset -euo pipefail\n\necho "Hello from script"\n')
    path.chmod(0o755)
    spawn("alacritty", "-e", "nvim", str(path))
    return {"ok": True, "path": str(path)}


# ----- vms -----
OS_CATALOG = [
    "kali", "parrotsec", "tails", "archlinux", "ubuntu", "debian", "fedora",
    "popos", "linuxmint", "opensuse", "nixos", "windows", "macos",
    "freebsd", "alpine",
]
_QGET_LIST_CACHE = {"ts": 0, "lines": []}


def vm_running(name: str):
    return bool(run_capture(["pgrep", "-f", f"{name}.qcow2"]))


def vm_list():
    VM_DIR.mkdir(parents=True, exist_ok=True)
    vms = []
    for p in sorted(VM_DIR.glob("*.conf")):
        name = p.stem
        vms.append({"name": name, "running": vm_running(name)})
    return vms


def vm_qget_list():
    now = time.time()
    if _QGET_LIST_CACHE["lines"] and now - _QGET_LIST_CACHE["ts"] < 600:
        return _QGET_LIST_CACHE["lines"]
    outp = run_capture(["quickget", "--list"], timeout=30)
    lines = [l for l in outp.splitlines() if l.strip()]
    if lines:
        _QGET_LIST_CACHE["lines"] = lines
        _QGET_LIST_CACHE["ts"] = now
    return lines


def vm_releases(os_name: str):
    seen = []
    for line in vm_qget_list():
        parts = line.split()
        if len(parts) >= 2 and parts[0] == os_name:
            rel = parts[1]
            if len(parts) > 2:
                rel = parts[1] + " " + " ".join(parts[2:])
            if rel not in seen:
                seen.append(rel)
    return seen or ["latest"]


# ----- bots -----
def load_bots_cfg():
    cfg = read_json(BOTS_JSON, None)
    if not cfg:
        cfg = {
            "roots": [
                str(HOME / "Bureau/Devs"),
                str(HOME / "Bureau/Devs/Clandestina/Bots"),
            ]
        }
        write_json(BOTS_JSON, cfg)
    return cfg


def looks_like_bot(d: Path):
    return any((d / n).is_file() for n in (".env", "package.json", "main.py", "bot.py", "index.js"))


def kind_of(d: Path):
    if (d / "package.json").is_file() or (d / "index.js").is_file():
        return "node"
    if (d / "main.py").is_file() or (d / "bot.py").is_file():
        return "python"
    if (d / ".env").is_file():
        return "env"
    return "bot"


def token_from_dir(d: Path):
    envp = d / ".env"
    if envp.is_file():
        for line in envp.read_text(errors="ignore").splitlines():
            line = line.strip()
            if line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            if k.strip() in ("TOKEN", "DISCORD_TOKEN", "BOT_TOKEN", "TELEGRAM_TOKEN"):
                v = v.strip().strip("\"'")
                if v:
                    return v
    cfgp = d / "config.json"
    if cfgp.is_file():
        try:
            data = json.loads(cfgp.read_text())
            for key in ("token", "TOKEN", "discord_token", "bot_token"):
                t = data.get(key)
                if t:
                    return str(t)
        except Exception:
            pass
    return None


def mask(tok: str):
    return "••••" if len(tok) <= 4 else "••••" + tok[-4:]


def bot_running(d: str):
    outp = run_capture(["pgrep", "-af", d])
    return any(("node" in l or "python" in l or "npm" in l) for l in outp.splitlines())


def scan_bots(root: Path, depth: int, acc: list):
    if depth <= 0 or not root.is_dir() or len(acc) >= 40:
        return
    try:
        entries = list(root.iterdir())
    except OSError:
        return
    for p in entries:
        if not p.is_dir():
            continue
        name = p.name
        if name.startswith(".") or name in ("node_modules", "target"):
            continue
        if looks_like_bot(p):
            tok = token_from_dir(p)
            acc.append({
                "name": name,
                "dir": str(p),
                "kind": kind_of(p),
                "running": bot_running(str(p)),
                "tokenHint": mask(tok) if tok else "pas de token",
            })
        elif depth > 1:
            scan_bots(p, depth - 1, acc)
        if len(acc) >= 40:
            return


def bots_list():
    acc = []
    for r in load_bots_cfg().get("roots", []):
        scan_bots(Path(r), 2, acc)
    acc.sort(key=lambda b: b["name"].lower())
    return acc


def bot_cmd(d: Path):
    if (d / "package.json").is_file():
        return "npm start"
    if (d / "main.py").is_file():
        return "python main.py"
    if (d / "bot.py").is_file():
        return "python bot.py"
    if (d / "index.js").is_file():
        return "node index.js"
    return None


# ----- chat -----
def comms_apps():
    def running(bin_name):
        return subprocess.run(["pgrep", "-x", bin_name], stdout=subprocess.DEVNULL).returncode == 0

    return [
        {"id": "telegram", "icon": "󰓺", "label": "Telegram", "running": running("Telegram")},
        {"id": "vesktop", "icon": "󰙯", "label": "Vesktop", "running": running("vesktop")},
        {"id": "discord", "icon": "󰊌", "label": "Discord", "running": running("discord")},
        {"id": "element", "icon": "󰭹", "label": "Element", "running": running("element-desktop")},
    ]


def tg_chat_name(chat: dict):
    if not isinstance(chat, dict):
        return ""
    title = chat.get("title") or ""
    if title:
        return str(title)
    parts = [chat.get("first_name") or "", chat.get("last_name") or ""]
    name = " ".join(p for p in parts if p).strip()
    if name:
        return name
    return str(chat.get("username") or chat.get("id") or "")


def remember_conv(dest: str, cid: str, name: str, preview: str):
    data = read_json(COMMS_RECENT, {"items": []})
    items = [
        i for i in (data.get("items") or [])
        if not (i.get("dest") == dest and str(i.get("id")) == str(cid))
    ]
    items.insert(0, {
        "dest": dest,
        "id": str(cid),
        "name": name or str(cid),
        "preview": (preview or "")[:80],
        "ts": int(time.time()),
    })
    write_json(COMMS_RECENT, {"items": items[:24]})


def telegram_updates(token: str):
    if not token:
        return []
    url = f"https://api.telegram.org/bot{token}/getUpdates?limit=40"
    raw = run_capture(["curl", "-sS", "--max-time", "8", url], timeout=10)
    try:
        data = json.loads(raw) if raw else {}
    except Exception:
        return []
    if not data.get("ok"):
        return []
    found = {}
    for upd in data.get("result") or []:
        msg = upd.get("message") or upd.get("edited_message") or upd.get("channel_post") or {}
        chat = msg.get("chat") or {}
        cid = chat.get("id")
        if cid is None:
            continue
        preview = str(msg.get("text") or msg.get("caption") or "")
        found[str(cid)] = {
            "dest": "telegram",
            "id": str(cid),
            "name": tg_chat_name(chat) or str(cid),
            "preview": preview[:80],
            "ts": int(msg.get("date") or time.time()),
        }
    return list(found.values())


def chat_convs():
    cfg = read_json(COMMS_JSON, {})
    recents = read_json(COMMS_RECENT, {"items": []}).get("items") or []
    pinned = cfg.get("chats") or []
    live = telegram_updates(cfg.get("telegram_token") or "")
    merged = {}
    for src in (pinned, live, recents):
        for it in src:
            if not isinstance(it, dict):
                continue
            dest = it.get("dest") or "telegram"
            cid = str(it.get("id") or it.get("chat_id") or "")
            if not cid:
                continue
            key = dest + ":" + cid
            prev = merged.get(key) or {}
            merged[key] = {
                "dest": dest,
                "id": cid,
                "name": it.get("name") or prev.get("name") or cid,
                "preview": it.get("preview") or prev.get("preview") or "",
                "ts": int(it.get("ts") or prev.get("ts") or 0),
                "icon": "󰓺" if dest == "telegram" else "󰙯",
            }
    hook = cfg.get("discord_webhook") or ""
    if hook:
        key = "discord:webhook"
        if key not in merged:
            merged[key] = {
                "dest": "discord",
                "id": "webhook",
                "name": cfg.get("discord_name") or "Discord",
                "preview": "",
                "ts": 0,
                "icon": "󰙯",
            }
    tg_id = str(cfg.get("telegram_chat_id") or "")
    if tg_id and ("telegram:" + tg_id) not in merged:
        merged["telegram:" + tg_id] = {
            "dest": "telegram",
            "id": tg_id,
            "name": cfg.get("telegram_chat_name") or "Telegram",
            "preview": "",
            "ts": 0,
            "icon": "󰓺",
        }
    items = list(merged.values())
    items.sort(key=lambda x: x.get("ts") or 0, reverse=True)
    return items[:20]


def chat_send(dest: str, text: str, chat_id: str = ""):
    text = (text or "").strip()
    if not text:
        fail("message vide")
    cfg = read_json(COMMS_JSON, {})
    dest = dest or "telegram"
    if dest == "telegram":
        token = cfg.get("telegram_token") or ""
        cid = chat_id or str(cfg.get("telegram_chat_id") or "")
        if not token or not cid:
            fail("choisis une conv ou remplis telegram_token / telegram_chat_id")
        url = f"https://api.telegram.org/bot{token}/sendMessage"
        p = subprocess.run(
            ["curl", "-sS", "-X", "POST", url, "-d", f"chat_id={cid}",
             "--data-urlencode", f"text={text}"],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=20,
        )
        if p.returncode != 0:
            fail(p.stderr.strip() or "telegram fail")
        remember_conv("telegram", cid, cid, text)
        return {"ok": True, "status": "envoyé", "items": chat_convs()}
    if dest == "discord":
        hook = cfg.get("discord_webhook") or ""
        if not hook:
            fail("remplis discord_webhook dans comms.json")
        body = json.dumps({"content": text})
        p = subprocess.run(
            ["curl", "-sS", "-H", "Content-Type: application/json", "-d", body, hook],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=20,
        )
        if p.returncode != 0:
            fail(p.stderr.strip() or "discord fail")
        remember_conv("discord", "webhook", cfg.get("discord_name") or "Discord", text)
        return {"ok": True, "status": "envoyé", "items": chat_convs()}
    fail("destination inconnue")


# ----- ops -----
def have(bin_name):
    return which(bin_name)


def tile(tid, icon, label, hint, bin_name):
    return {
        "id": tid,
        "icon": icon,
        "label": label,
        "hint": hint,
        "ready": (not bin_name) or have(bin_name),
    }


def ops_tiles(cat: str):
    cats = {
        "web": [
            tile("ffuf", "󰕙", "ffuf", "fuzz web", "ffuf"),
            tile("gobuster", "󰕙", "gobuster", "dirs / vhosts", "gobuster"),
            tile("ferox", "󰕙", "feroxbuster", "recursive fuzz", "feroxbuster"),
            tile("nuclei", "󱎫", "nuclei", "templates vulns", "nuclei"),
            tile("nikto", "󱚟", "nikto", "scan web", "nikto"),
            tile("sqlmap", "󰆼", "sqlmap", "SQLi", "sqlmap"),
            tile("burp", "󰒓", "Burp Suite", "proxy", "burpsuite"),
        ],
        "net": [
            tile("wireshark", "󰈀", "Wireshark", "capture", "wireshark"),
            tile("tshark", "󰈀", "tshark", "pcap CLI", "tshark"),
            tile("tcpdump", "󰈀", "tcpdump", "sniff", "tcpdump"),
            tile("chisel", "󰞒", "chisel", "tunnel", "chisel"),
            tile("proxychains", "󰒍", "proxychains", "pivot", "proxychains4"),
            tile("tor", "󰈿", "tor", "anonymat", "tor"),
        ],
        "creds": [
            tile("hydra", "󰌆", "hydra", "bruteforce", "hydra"),
            tile("john", "󰌆", "john", "hashes", "john"),
            tile("hashcat", "󰌆", "hashcat", "GPU crack", "hashcat"),
            tile("responder", "󰖪", "responder", "LLMNR / NBT", "responder"),
        ],
        "ad": [
            tile("netexec", "󰌘", "netexec", "AD / SMB", "netexec"),
            tile("cme", "󰌘", "crackmapexec", "legacy CME", "crackmapexec"),
            tile("bloodhound", "󰓡", "BloodHound", "graph AD", "bloodhound"),
            tile("impacket", "󰆼", "secretsdump", "NTDS / SAM", "impacket-secretsdump"),
        ],
        "rev": [
            tile("ghidra", "󰘳", "Ghidra", "disasm", "ghidra"),
            tile("radare2", "󰘳", "radare2", "RE CLI", "radare2"),
            tile("gdb", "󰘳", "gdb", "debug", "gdb"),
            tile("msf", "󰓁", "msfconsole", "exploit", "msfconsole"),
        ],
        "listen": [
            tile("http", "󰖟", "HTTP :8000", "python http.server", "python3"),
            tile("nc", "󰣀", "nc :4444", "reverse shell", "nc"),
            tile("notes", "󰂺", "Notes ops", "markdown", ""),
        ],
        "sys": [
            tile("hud", "󰣇", "BlackArch HUD", "arsenal", ""),
            tile("osint", "󰭔", "OSINT menu", "recon perso", ""),
            tile("ip", "󰩠", "IP publique", "copier", "curl"),
            tile("tun", "󰒍", "IP locale", "copier", ""),
            tile("htb", "󰖂", "OpenVPN HTB", "lab", "openvpn"),
            tile("term", "󰆍", "Terminal cible", "alacritty", "alacritty"),
        ],
        "recon": [
            tile("nmap", "󰈐", "nmap", "scan ports", "nmap"),
            tile("rustscan", "󰈐", "rustscan", "ports rapides", "rustscan"),
            tile("httpx", "󰖟", "httpx", "probes HTTP", "httpx"),
            tile("subfinder", "󰖟", "subfinder", "sous-domaines", "subfinder"),
            tile("amass", "󰖟", "amass", "enum DNS", "amass"),
            tile("hud", "󰣇", "BlackArch HUD", "toutes les cats", ""),
        ],
    }
    return cats.get(cat, cats["recon"])


def ops_target():
    try:
        return TARGET_TXT.read_text().splitlines()[0].strip()
    except Exception:
        return ""


def ops_set_target(v: str):
    TARGET_TXT.parent.mkdir(parents=True, exist_ok=True)
    TARGET_TXT.write_text((v or "").strip() + "\n")
    return {"ok": True, "target": ops_target(), "status": "cible enregistrée"}


BA_CACHE = Path("/tmp/ba-tools.cache")
BA_RECENTS = HOME / ".cache/blackarch-recent"

OSINT_KINDS = [
    {"id": "username", "icon": "󰀉", "label": "Username"},
    {"id": "email", "icon": "󰇮", "label": "Email"},
    {"id": "phone", "icon": "󰏲", "label": "Phone"},
    {"id": "domain", "icon": "󰖟", "label": "Domain"},
    {"id": "ip", "icon": "󰩠", "label": "IP"},
    {"id": "suites", "icon": "󰭔", "label": "Suites"},
]

OSINT_TOOLS = {
    "username": ["sherlock", "maigret", "socialscan", "holehe", "osintgram"],
    "email": ["holehe", "socialscan", "theharvester", "sherlock"],
    "phone": ["phoneinfoga", "socialscan"],
    "domain": [
        "whois", "dig", "subfinder", "amass", "httpx", "whatweb",
        "wpscan", "waybackurls", "gau", "theharvester",
    ],
    "ip": ["whois", "nmap", "httpx", "dig"],
    "suites": ["maltego", "spiderfoot", "recon-ng", "sn0int"],
}


def ba_refresh_cache(force: bool = False):
    if (
        not force
        and BA_CACHE.is_file()
        and time.time() - BA_CACHE.stat().st_mtime < 3600
    ):
        return
    raw = run_capture(["pacman", "-Qg"], timeout=60)
    lines = []
    for line in raw.splitlines():
        parts = line.split()
        if len(parts) >= 2 and parts[0].startswith("blackarch-"):
            lines.append(f"{parts[0]}\t{parts[1]}")
    BA_CACHE.write_text("\n".join(sorted(set(lines))) + ("\n" if lines else ""))


def ba_rows():
    ba_refresh_cache()
    if not BA_CACHE.is_file():
        return []
    out = []
    for line in BA_CACHE.read_text(encoding="utf-8", errors="replace").splitlines():
        if "\t" not in line:
            continue
        g, tool = line.split("\t", 1)
        out.append((g, tool))
    return out


def ba_categories():
    counts = {}
    for g, _ in ba_rows():
        cat = g.removeprefix("blackarch-")
        counts[cat] = counts.get(cat, 0) + 1
    items = [
        {"id": c, "icon": "󰏖", "label": c, "sub": str(counts[c]), "kind": "category"}
        for c in sorted(counts)
    ]
    return {"ok": True, "items": items, "target": ops_target()}


def ba_tools(cat: str = "", query: str = "", recents: bool = False):
    items = []
    if recents:
        if BA_RECENTS.is_file():
            for name in BA_RECENTS.read_text(encoding="utf-8", errors="replace").splitlines():
                name = name.strip()
                if name:
                    items.append({"id": name, "icon": "󰓊", "label": name, "kind": "tool"})
        return {"ok": True, "items": items, "target": ops_target(), "title": "Récents"}

    q = (query or "").strip().lower()
    want = f"blackarch-{cat}" if cat else ""
    seen = set()
    for g, tool in ba_rows():
        if want and g != want:
            continue
        if q and q not in tool.lower():
            continue
        if tool in seen:
            continue
        seen.add(tool)
        items.append({"id": tool, "icon": "󰆧", "label": tool, "kind": "tool"})
    title = cat or ("Recherche" if q else "Outils")
    return {"ok": True, "items": items, "target": ops_target(), "title": title}


def ba_home():
    tgt = ops_target() or "aucune"
    items = [
        {"id": "search", "icon": "󰍉", "label": "Chercher un outil", "kind": "nav"},
        {"id": "categories", "icon": "󰏖", "label": "Catégories", "kind": "nav"},
        {"id": "osint", "icon": "󰭔", "label": "Menu OSINT", "kind": "nav"},
        {"id": "recents", "icon": "󰓊", "label": "Récents", "kind": "nav"},
        {"id": "ops", "icon": "󰗚", "label": "Ops (tiles)", "kind": "ops"},
        {"id": "target-info", "icon": "󰁪", "label": f"Cible : {tgt}", "kind": "info"},
    ]
    return {"ok": True, "items": items, "target": ops_target(), "title": "BlackArch"}


def ba_is_gui(tool: str) -> bool:
    prefixes = (
        "wireshark", "burpsuite", "maltego", "zaproxy", "zap",
        "bloodhound", "ghidra", "spiderfoot",
    )
    if any(tool.startswith(p) for p in prefixes):
        return True
    apps = Path("/usr/share/applications")
    if apps.is_dir() and any(apps.glob(f"*{tool}*")):
        return True
    return False


def ba_remember(tool: str):
    BA_RECENTS.parent.mkdir(parents=True, exist_ok=True)
    prev = []
    if BA_RECENTS.is_file():
        prev = [
            l.strip()
            for l in BA_RECENTS.read_text(encoding="utf-8", errors="replace").splitlines()
            if l.strip() and l.strip() != tool
        ]
    BA_RECENTS.write_text("\n".join([tool] + prev[:11]) + "\n")


def ba_bin(tool: str) -> str:
    if which(tool):
        return tool
    if which(f"ba-{tool}"):
        return f"ba-{tool}"
    return tool


def ba_launch(tool: str, extra: str = ""):
    tool = (tool or "").strip()
    if not tool:
        return {"ok": False, "error": "outil manquant"}
    ba_remember(tool)
    binary = ba_bin(tool)
    target = ops_target()
    if ba_is_gui(tool) or ba_is_gui(binary):
        if which(binary):
            spawn(binary)
        else:
            apps = sorted(Path("/usr/share/applications").glob(f"*{tool}*"))
            if apps:
                spawn("gtk-launch", apps[0].stem)
            else:
                return {"ok": False, "error": f"{tool} introuvable"}
        return {"ok": True, "status": f"{tool} lancé"}

    if target:
        banner = f"printf '\\e[1;31m  cible : %s\\e[0m\\n\\n' {shlex.quote(target)}"
    else:
        banner = "printf '\\e[1;33m  pas de cible\\e[0m\\n\\n'"

    if extra:
        body = f"{banner}; printf '\\e[1;36m  $ %s\\e[0m\\n\\n' {shlex.quote(extra)}; {extra}; echo; exec bash"
    else:
        body = (
            f"{banner}; printf '\\e[1;36m  outil : %s\\e[0m\\n\\n' {shlex.quote(binary)}; "
            f"{shlex.quote(binary)} --help 2>/dev/null | head -n 40 || "
            f"{shlex.quote(binary)} -h 2>/dev/null | head -n 40 || true; "
            "echo; echo 'prêt — tape ta commande'; exec bash"
        )
    spawn("alacritty", "-t", f"BlackArch - {tool}", "-e", "bash", "-lc", body)
    return {"ok": True, "status": f"{tool} ouvert"}


def ba_osint_kinds():
    return {"ok": True, "items": [{**k, "kind": "osint-kind"} for k in OSINT_KINDS], "target": ops_target(), "title": "OSINT"}


def ba_osint_tools(kind: str):
    kind = (kind or "").strip()
    tools = OSINT_TOOLS.get(kind, [])
    items = []
    for name in tools:
        ready = which(name)
        items.append({
            "id": name,
            "icon": "󰆧",
            "label": name if ready else f"{name}  ·  absent",
            "kind": "osint-tool",
            "ready": ready,
            "osint": kind,
        })
    return {"ok": True, "items": items, "target": ops_target(), "title": f"OSINT · {kind}"}


def ba_osint_run(kind: str, tool: str, query: str = ""):
    tool = (tool or "").strip()
    kind = (kind or "").strip()
    q = (query or "").strip() or ops_target()
    if kind == "suites":
        return ba_launch(tool)
    if not q:
        return {"ok": False, "error": "renseigne une cible / query"}
    if not which(tool):
        return {"ok": False, "error": f"{tool} absent"}
    qq = shlex.quote(q)
    cmds = {
        "sherlock": f"sherlock {qq}",
        "maigret": f"maigret {qq}",
        "socialscan": f"socialscan {qq}",
        "holehe": f"holehe {qq}",
        "osintgram": f"osintgram {qq}",
        "phoneinfoga": f"phoneinfoga scan -n {qq}",
        "theharvester": f"theharvester -d {qq} -b all",
        "whois": f"whois {qq}",
        "dig": f"dig {qq} ANY +noall +answer",
        "subfinder": f"subfinder -d {qq}",
        "amass": f"amass enum -d {qq}",
        "httpx": f"echo {qq} | httpx -title -status-code -tech-detect",
        "whatweb": f"whatweb {qq}",
        "wpscan": f"wpscan --url {qq}",
        "waybackurls": f"echo {qq} | waybackurls | head",
        "gau": f"gau {qq} | head",
        "nmap": f"nmap -sV -sC {qq}",
    }
    cmdline = cmds.get(tool)
    if not cmdline:
        return ba_launch(tool)
    ba_remember(tool)
    body = f"printf '\\e[1;36m  $ %s\\e[0m\\n\\n' {shlex.quote(cmdline)}; {cmdline}; echo; exec bash"
    spawn("alacritty", "-t", f"OSINT - {tool}", "-e", "bash", "-lc", body)
    return {"ok": True, "status": f"{tool} lancé"}


def ops_run(tid: str):
    t = ops_target()
    tgt = t or "127.0.0.1"
    home = str(HOME)
    actions = {
        "nmap": lambda: term("nmap", f"nmap -sC -sV {tgt}") or "nmap lancé",
        "rustscan": lambda: term("rustscan", f"rustscan -a {tgt} -- -sV") or "rustscan lancé",
        "httpx": lambda: term("httpx", f"echo {tgt} | httpx -title -status-code") or "httpx lancé",
        "subfinder": lambda: term("subfinder", f"subfinder -d {tgt}") or "subfinder lancé",
        "amass": lambda: term("amass", f"amass enum -d {tgt}") or "amass lancé",
        "ffuf": lambda: term("ffuf", f"ffuf -u {tgt}/FUZZ -w /usr/share/seclists/Discovery/Web-Content/common.txt") or "ffuf lancé",
        "gobuster": lambda: term("gobuster", f"gobuster dir -u {tgt} -w /usr/share/seclists/Discovery/Web-Content/common.txt") or "gobuster lancé",
        "ferox": lambda: term("feroxbuster", f"feroxbuster -u {tgt}") or "ferox lancé",
        "nuclei": lambda: term("nuclei", f"nuclei -u {tgt}") or "nuclei lancé",
        "nikto": lambda: term("nikto", f"nikto -h {tgt}") or "nikto lancé",
        "sqlmap": lambda: term("sqlmap", f"sqlmap -u {tgt}") or "sqlmap lancé",
        "burp": lambda: spawn("burpsuite") or "Burp",
        "wireshark": lambda: spawn("wireshark") or "Wireshark",
        "tshark": lambda: term("tshark", "sudo tshark -i any") or "tshark",
        "tcpdump": lambda: term("tcpdump", "sudo tcpdump -i any -nn") or "tcpdump",
        "chisel": lambda: term("chisel", "chisel") or "chisel",
        "proxychains": lambda: term("proxychains", "proxychains4 bash") or "proxychains",
        "tor": lambda: term("tor", "systemctl --user status tor || tor") or "tor",
        "hydra": lambda: term("hydra", f"hydra -h ; echo cible={tgt}") or "hydra",
        "john": lambda: term("john", "john") or "john",
        "hashcat": lambda: term("hashcat", "hashcat -h | head") or "hashcat",
        "responder": lambda: term("responder", "sudo responder -I tun0") or "responder",
        "netexec": lambda: term("netexec", f"netexec smb {tgt}") or "netexec",
        "cme": lambda: term("crackmapexec", f"crackmapexec smb {tgt}") or "cme",
        "bloodhound": lambda: spawn("bloodhound") or "BloodHound",
        "impacket": lambda: term("secretsdump", "impacket-secretsdump -h") or "secretsdump",
        "ghidra": lambda: spawn("ghidra") or "Ghidra",
        "radare2": lambda: term("radare2", "r2 -") or "radare2",
        "gdb": lambda: term("gdb", "gdb") or "gdb",
        "msf": lambda: term("msfconsole", "msfconsole") or "msfconsole",
        "http": lambda: term("http.server", "python3 -m http.server 8000") or "HTTP :8000",
        "nc": lambda: term("nc", "nc -lvnp 4444") or "nc :4444",
        "hud": lambda: spawn("bash", f"{home}/.config/niri/scripts/blackarch_hud.sh") or "HUD",
        "osint": lambda: spawn("bash", f"{home}/.config/niri/scripts/osint_menu.sh") or "OSINT",
        "htb": lambda: term("HTB VPN", f"sudo openvpn '{home}/.config/openvpn/htb.ovpn'") or "OpenVPN HTB",
        "term": lambda: spawn("alacritty", "-t", "Ops", "-e", "bash", "-lc",
                              (f"echo 'cible: {t}'; exec bash" if t else "exec bash")) or "terminal",
    }
    if tid == "notes":
        if not NOTES.exists():
            NOTES.write_text("# Ops notes\n\n")
        spawn("alacritty", "-e", "nvim", str(NOTES))
        return {"ok": True, "status": "notes"}
    if tid == "ip":
        ip = run_capture(["curl", "-sS", "--max-time", "4", "https://ifconfig.me"])
        copy_text(ip)
        return {"ok": True, "status": f"IP publique copiée: {ip}"}
    if tid == "tun":
        ip = run_capture(["bash", "-lc", "ip -4 -o addr show scope global | awk '{print $2,$4}'"])
        copy_text(ip)
        return {"ok": True, "status": "interfaces copiées"}
    fn = actions.get(tid)
    if not fn:
        return {"ok": False, "status": "inconnu"}
    status = fn()
    return {"ok": True, "status": status}


# ----- ai -----
def ai_providers():
    v = ["ollama"]
    if which("claude"):
        v.append("claude")
    v += ["gemini", "openai", "groq", "openrouter"]
    return v


def ai_models(provider: str):
    if provider == "ollama":
        outp = run_capture(["ollama", "list"])
        models = [l.split()[0] for l in outp.splitlines()[1:] if l.split()]
        return models or ["qwen3.5:35b"]
    return {
        "claude": ["sonnet", "opus", "haiku"],
        "gemini": ["gemini-2.5-flash", "gemini-2.5-pro", "gemini-2.0-flash"],
        "openai": ["gpt-5", "gpt-5-mini", "gpt-4.1-mini"],
        "groq": ["llama-3.3-70b-versatile", "moonshotai/kimi-k2-instruct", "qwen/qwen3-32b", "openai/gpt-oss-120b"],
        "openrouter": [
            "anthropic/claude-sonnet-4", "google/gemini-2.5-flash",
            "openai/gpt-4.1-mini", "qwen/qwen3-32b", "deepseek/deepseek-chat",
        ],
    }.get(provider, ["default"])


def ai_chat(provider: str, model: str, prompt: str):
    prompt = prompt or sys.stdin.read()
    p = subprocess.run(
        ["bash", str(CHAT_SH), provider, model],
        input=prompt,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        timeout=320,
    )
    stdout = (p.stdout or "").strip()
    if p.returncode != 0 or not stdout:
        err = (p.stderr or "").strip() or "réponse vide du provider"
        fail(err)
    return {"ok": True, "text": stdout}


def ai_image(model: str, prompt: str):
    p = subprocess.run(
        ["bash", str(IMAGE_SH), model, prompt],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        timeout=180,
    )
    stdout = (p.stdout or "").strip()
    if p.returncode != 0:
        fail((p.stderr or "").strip() or "échec de la génération")
    return {"ok": True, "path": stdout}


def pick_file():
    p = subprocess.run(
        ["zenity", "--file-selection", "--title", "Choisir un fichier"],
        stdout=subprocess.PIPE, text=True, timeout=120,
    )
    path = (p.stdout or "").strip()
    return {"ok": bool(path), "path": path}


def pick_avatar():
    p = subprocess.run(
        [
            "zenity",
            "--file-selection",
            "--title",
            "Photo de profil",
            "--file-filter=Images | *.png *.jpg *.jpeg *.webp *.gif *.bmp *.tif *.tiff",
        ],
        stdout=subprocess.PIPE,
        text=True,
        timeout=180,
    )
    path = (p.stdout or "").strip()
    if not path or not Path(path).is_file():
        return identity()
    cfg = load_panel()
    cfg["avatar"] = path
    write_json(PANEL_JSON, cfg)
    return identity()


def dispatch(cmd, args):
    if cmd == "identity":
        return identity()
    if cmd == "pick-avatar":
        return pick_avatar()
    if cmd == "sysinfo":
        return sysinfo()
    if cmd == "studio":
        return studio(args[0] if args else "")
    if cmd == "dash":
        return dash_cmd(args[0] if args else "")
    if cmd == "omarchy-themes":
        return omarchy_themes()
    if cmd == "omarchy-theme-set":
        return omarchy_theme_set(args[0] if args else "")
    if cmd == "omarchy-menu":
        return omarchy_menu_list(args[0] if args else "")
    if cmd == "omarchy-menu-run":
        return omarchy_menu_run(args[0] if args else "")
    if cmd == "weather":
        return weather()
    if cmd == "scripts-list":
        return {"ok": True, "items": scan_scripts(args[0] if args else "")}
    if cmd == "scripts-run":
        spawn("bash", args[0])
        return {"ok": True}
    if cmd == "scripts-term":
        spawn("alacritty", "-e", "bash", args[0])
        return {"ok": True}
    if cmd == "scripts-edit":
        spawn("alacritty", "-e", "nvim", args[0])
        return {"ok": True}
    if cmd == "scripts-delete":
        path = args[0] if args else ""
        if path.startswith(str(SCRIPTS_CUSTOM)):
            try:
                Path(path).unlink()
            except OSError:
                pass
        return {"ok": True, "items": scan_scripts("")}
    if cmd == "scripts-new":
        r = scripts_new(args[0] if args else "")
        r["items"] = scan_scripts("")
        return r
    if cmd == "scripts-folder":
        spawn("thunar", str(SCRIPTS_CUSTOM))
        return {"ok": True}
    if cmd == "vm-list":
        return {"ok": True, "items": vm_list(), "osList": OS_CATALOG}
    if cmd == "vm-releases":
        return {"ok": True, "releases": vm_releases(args[0] if args else "kali")}
    if cmd == "vm-start":
        name = args[0]
        subprocess.Popen(
            ["quickemu", "--vm", f"{name}.conf"],
            cwd=str(VM_DIR),
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
        return {"ok": True, "items": vm_list(), "status": f"{name} lancée"}
    if cmd == "vm-delete":
        name = args[0]
        for p in [VM_DIR / f"{name}.conf", VM_DIR / f"{name}.qcow2"]:
            try:
                p.unlink()
            except OSError:
                pass
        shutil.rmtree(VM_DIR / name, ignore_errors=True)
        shutil.rmtree(VM_DIR / f"{name}-vm-disk", ignore_errors=True)
        return {"ok": True, "items": vm_list(), "status": f"{name} supprimée"}
    if cmd == "vm-create":
        os_name = args[0] if args else ""
        release = args[1] if len(args) > 1 else "latest"
        if not os_name:
            fail("OS manquant")
        VM_DIR.mkdir(parents=True, exist_ok=True)
        qargs = ["quickget", os_name] + release.split(None, 1)
        p = subprocess.run(
            qargs,
            cwd=str(VM_DIR),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=3600,
        )
        if p.returncode != 0:
            err = (p.stderr or p.stdout or "").strip()
            lines = [l.strip() for l in err.splitlines() if l.strip() and not l.strip().startswith("#") and "%" not in l]
            fail(lines[-1] if lines else "échec quickget")
        return {"ok": True, "items": vm_list(), "status": f"{os_name} {release} téléchargée"}
    if cmd == "vm-folder":
        spawn("thunar", str(VM_DIR))
        return {"ok": True}
    if cmd == "bots-list":
        return {"ok": True, "items": bots_list()}
    if cmd == "bots-start":
        d = Path(args[0])
        c = bot_cmd(d)
        if not c:
            spawn("thunar", str(d))
        else:
            title = f"Bot - {d.name}"
            script = f"cd {json.dumps(str(d))} && {c}; exec bash"
            spawn("alacritty", "-t", title, "-e", "bash", "-lc", script)
        return {"ok": True, "items": bots_list(), "status": "start"}
    if cmd == "bots-stop":
        subprocess.run(["pkill", "-f", args[0]], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return {"ok": True, "items": bots_list(), "status": "stop"}
    if cmd == "bots-open":
        spawn("thunar", args[0])
        return {"ok": True}
    if cmd == "bots-copy":
        tok = token_from_dir(Path(args[0]))
        if not tok:
            fail("aucun token trouvé")
        copy_text(tok)
        return {"ok": True, "status": "token copié"}
    if cmd == "bots-edit":
        spawn("alacritty", "-e", "nvim", str(BOTS_JSON))
        return {"ok": True}
    if cmd == "chat-apps":
        return {"ok": True, "items": comms_apps()}
    if cmd == "chat-convs":
        return {"ok": True, "items": chat_convs()}
    if cmd == "chat-open":
        mapping = {
            "telegram": "Telegram",
            "vesktop": "vesktop",
            "discord": "discord",
            "element": "element-desktop",
        }
        bin_name = mapping.get(args[0] if args else "")
        if bin_name:
            spawn(bin_name)
        return {"ok": True}
    if cmd == "chat-send":
        dest = args[0] if args else "telegram"
        chat_id = args[1] if len(args) > 1 else ""
        if chat_id == "-":
            chat_id = ""
        text = " ".join(args[2:]) if len(args) > 2 else ""
        return chat_send(dest, text, chat_id)
    if cmd == "ops-tiles":
        cat = args[0] if args else "recon"
        return {"ok": True, "items": ops_tiles(cat), "target": ops_target(), "cat": cat}
    if cmd == "ops-target":
        return ops_set_target(args[0] if args else "")
    if cmd == "ops-run":
        return ops_run(args[0] if args else "")
    if cmd == "ba-home":
        return ba_home()
    if cmd == "ba-categories":
        return ba_categories()
    if cmd == "ba-tools":
        mode = args[0] if args else ""
        if mode == "recents":
            return ba_tools(recents=True)
        if mode == "search":
            return ba_tools(query=args[1] if len(args) > 1 else "")
        return ba_tools(cat=mode)
    if cmd == "ba-launch":
        return ba_launch(args[0] if args else "", args[1] if len(args) > 1 else "")
    if cmd == "ba-osint":
        return ba_osint_kinds()
    if cmd == "ba-osint-tools":
        return ba_osint_tools(args[0] if args else "")
    if cmd == "ba-osint-run":
        return ba_osint_run(
            args[0] if args else "",
            args[1] if len(args) > 1 else "",
            args[2] if len(args) > 2 else "",
        )
    if cmd == "ba-refresh":
        ba_refresh_cache(force=True)
        return {"ok": True, "status": "cache outils rafraîchi"}
    if cmd == "ai-providers":
        provs = ai_providers()
        return {"ok": True, "providers": provs, "models": ai_models(provs[0])}
    if cmd == "ai-models":
        return {"ok": True, "models": ai_models(args[0] if args else "ollama")}
    if cmd == "ai-chat":
        provider = args[0] if args else "ollama"
        model = args[1] if len(args) > 1 else ""
        prompt = " ".join(args[2:]) if len(args) > 2 else ""
        return ai_chat(provider, model, prompt)
    if cmd == "ai-image":
        model = args[0] if args else ""
        prompt = " ".join(args[1:]) if len(args) > 1 else ""
        return ai_image(model, prompt)
    if cmd == "pick-file":
        return pick_file()
    if cmd == "focused-output":
        raw = run_capture(["niri", "msg", "--json", "focused-output"])
        name = ""
        try:
            data = json.loads(raw) if raw else None
            if isinstance(data, str):
                name = data
            elif isinstance(data, dict):
                name = data.get("name") or data.get("output") or ""
        except Exception:
            name = raw
        return {"ok": True, "name": name}
    if cmd == "ping":
        return {"ok": True}
    if cmd.startswith("pkgs"):
        return pkgs_backend.dispatch(cmd, args)
    fail(f"unknown command {cmd}")


def main():
    if len(sys.argv) < 2:
        fail("usage: bridge.py <cmd> [args]")
    try:
        result = dispatch(sys.argv[1], sys.argv[2:])
        out(result)
    except SystemExit:
        raise
    except Exception as e:
        fail(e)


if __name__ == "__main__":
    main()
