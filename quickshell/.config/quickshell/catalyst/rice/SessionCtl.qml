pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/*
 * Session : extinction programmée, mises à jour en attente, actions avancées.
 *
 *  - Extinction programmée : déléguée à systemd-logind (`shutdown +N`) — elle
 *    survit à un redémarrage du shell ; l'état est relu sur logind
 *    (ScheduledShutdown) à l'ouverture du menu et toutes les 10 s s'il y en a une.
 *  - Mises à jour : `checkupdates` (dépôts) + `paru -Qua` (AUR), lancés au plus
 *    toutes les 30 min, uniquement quand le menu de session s'ouvre.
 */
Singleton {
    id: root

    // extinction programmée
    property real shutdownAt: 0          // ms epoch, 0 = aucune
    property string shutdownKind: ""     // poweroff | reboot
    property int tick: 0
    readonly property bool scheduled: shutdownAt > 0
    readonly property int remaining: {
        tick;
        return scheduled ? Math.max(0, Math.round((shutdownAt - Date.now()) / 1000)) : 0;
    }
    readonly property string remainingText: {
        const s = remaining;
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        const ss = s % 60;
        return (h > 0 ? h + ":" + (m < 10 ? "0" : "") : "") + m + ":" + (ss < 10 ? "0" : "") + ss;
    }

    // mises à jour
    property int updatesRepo: -1
    property int updatesAur: -1
    readonly property int updates: Math.max(0, updatesRepo) + Math.max(0, updatesAur)
    property bool checking: false
    property real checkedAt: 0

    readonly property string updater: Quickshell.env("HOME") + "/.local/bin/cachyos-update"

    function schedule(minutes) {
        sched.command = ["shutdown", "--no-wall", "-h", "+" + Math.max(1, Math.round(minutes))];
        sched.running = true;
    }
    function cancelSchedule() {
        sched.command = ["shutdown", "--no-wall", "-c"];
        sched.running = true;
    }
    function readSchedule() {
        reader.running = true;
    }

    function checkUpdates(force) {
        if (checking || (!force && Date.now() - checkedAt < 1800000))
            return;
        checking = true;
        repoProc.running = true;
    }

    function update(rebootAfter) {
        PanelService.hide();
        const cmd = "'" + updater + "'" + (rebootAfter ? " && { echo; echo 'Redémarrage dans 10 s — Ctrl+C pour annuler'; sleep 10 && systemctl reboot; }" : "") + "; echo; read -n1 -rsp 'Touche pour fermer…'";
        Quickshell.execDetached(["alacritty", "-e", "bash", "-c", cmd]);
    }

    function screensOff() {
        PanelService.hide();
        // laisse le menu disparaître ; toute entrée rallume (misc:mouse_move_enables_dpms)
        Quickshell.execDetached(["sh", "-c", "sleep 0.6; hyprctl dispatch dpms off"]);
    }

    function rebootFirmware() {
        PanelService.hide();
        Quickshell.execDetached(["systemctl", "reboot", "--firmware-setup"]);
    }

    function restartShell() {
        PanelService.hide();
        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/catalyst/scripts/catalyst-session.sh", "restart"]);
    }

    function pauseMedia() {
        Quickshell.execDetached(["playerctl", "-a", "pause"]);
    }

    Process {
        id: sched
        onExited: root.readSchedule()
    }

    // ScheduledShutdown : (st) "<type>" <usec epoch>
    Process {
        id: reader
        command: ["busctl", "get-property", "org.freedesktop.login1", "/org/freedesktop/login1", "org.freedesktop.login1.Manager", "ScheduledShutdown"]
        stdout: SplitParser {
            onRead: data => {
                const m = data.match(/\(st\)\s+"([^"]*)"\s+(\d+)/);
                if (!m)
                    return;
                const usec = Number(m[2]);
                const valid = m[1].length > 0 && usec > 0 && usec < 1e18;
                root.shutdownKind = valid ? m[1] : "";
                root.shutdownAt = valid ? usec / 1000 : 0;
            }
        }
    }

    Process {
        id: repoProc
        command: ["sh", "-c", "checkupdates 2>/dev/null | wc -l"]
        stdout: SplitParser { onRead: data => root.updatesRepo = Number(data.trim()) || 0 }
        onExited: aurProc.running = true
    }
    Process {
        id: aurProc
        command: ["sh", "-c", "command -v paru >/dev/null && paru -Qua 2>/dev/null | wc -l || echo 0"]
        stdout: SplitParser { onRead: data => root.updatesAur = Number(data.trim()) || 0 }
        onExited: {
            root.checking = false;
            root.checkedAt = Date.now();
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.scheduled
        onTriggered: root.tick++
    }
    Timer {
        interval: 10000
        repeat: true
        running: root.scheduled
        onTriggered: root.readSchedule()
    }

    Component.onCompleted: readSchedule()
}
