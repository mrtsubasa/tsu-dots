pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/*
 * Mode jeu.
 *  - automatique (ShellCfg.autoGameMode) : quand la fenêtre active est un
 *    jeu en plein écran (Steam/Proton, Gamescope, Wine .exe, Lutris, Heroic,
 *    Minecraft…), sur événements Hyprland — aucune scrutation.
 *  - manuel : toggle().
 * Actif = Ne pas déranger, veille suspendue, profil Performance, et
 * `gamemoded -r <pid>` sur le processus du jeu si gamemode est installé.
 * L'état précédent est restauré à la sortie.
 */
Singleton {
    id: root

    property bool active: false
    property bool manual: false
    property string game: ""
    property int gamePid: 0
    property var _saved: null

    readonly property var pattern: /^(steam_app_\d+|gamescope|.*\.exe|lutris.*|heroic.*|minecraft.*|osu!?|retroarch|dolphin-emu|pcsx2.*|rpcs3|yuzu|ryujinx|cemu)$/i

    function enter(name, pid) {
        game = name || "";
        gamePid = pid || 0;
        if (active)
            return;
        _saved = { dnd: Notifs.dnd, caffeine: Caffeine.on, profile: Power.profile };
        if (!Notifs.dnd)
            Notifs.toggleDnd();
        Caffeine.on = true;
        if (Power.hasPerformance)
            Power.set(Power.profiles[Power.profiles.length - 1].id);
        if (gamePid > 0)
            Quickshell.execDetached(["sh", "-c", "command -v gamemoded >/dev/null && gamemoded -r" + gamePid + " >/dev/null 2>&1 || true"]);
        active = true;
    }

    function leave() {
        if (!active)
            return;
        const s = _saved || {};
        if (Notifs.dnd !== !!s.dnd)
            Notifs.toggleDnd();
        Caffeine.on = !!s.caffeine;
        if (s.profile !== undefined)
            Power.set(s.profile);
        active = false;
        manual = false;
        game = "";
        gamePid = 0;
    }

    function toggle() {
        if (active) {
            leave();
        } else {
            manual = true;
            enter("manuel", 0);
        }
    }

    // ---- détection automatique ----
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            const n = event.name;
            if (n === "fullscreen" || n === "activewindowv2" || n === "closewindow" || n === "workspacev2")
                probeT.restart();
        }
    }
    Timer {
        id: probeT
        interval: 250
        onTriggered: if (ShellCfg.autoGameMode && !root.manual) probe.running = true
    }
    Process {
        id: probe
        command: ["hyprctl", "activewindow", "-j"]
        property string buf: ""
        stdout: SplitParser { onRead: data => probe.buf += data }
        onRunningChanged: if (running) buf = ""
        onExited: {
            let w = null;
            try {
                w = JSON.parse(probe.buf);
            } catch (e) {
            }
            const cls = w && w["class"] ? String(w["class"]) : "";
            const isGame = !!w && w.fullscreen > 0 && root.pattern.test(cls);
            if (isGame)
                root.enter(w.title || cls, w.pid || 0);
            else if (root.active && !root.manual)
                root.leave();
        }
    }
}
