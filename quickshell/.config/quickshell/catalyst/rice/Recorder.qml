pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Enregistrement d'écran (wf-recorder). Le processus appartient au shell :
// l'état « en cours » est fiable et la barre affiche un voyant + la durée.
Singleton {
    id: root

    readonly property bool recording: proc.running
    property string file: ""
    property real startedAt: 0
    property int elapsed: 0
    readonly property string elapsedText: {
        const m = Math.floor(elapsed / 60);
        const s = elapsed % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    // mode : "region" | "screen"
    function start(mode) {
        if (recording)
            return;
        const dir = Quickshell.env("HOME") + "/Videos/Captures";
        file = dir + "/Capture_" + Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss") + ".mp4";
        const geo = mode === "region" ? "G=\"$(slurp)\" || exit 0; [ -z \"$G\" ] && exit 0; " : "G=\"\"; ";
        const out = mode === "region" ? "" : "-o \"$(hyprctl -j monitors | python3 -c 'import json,sys;print(next(m[\"name\"] for m in json.load(sys.stdin) if m[\"focused\"]))')\" ";
        proc.command = ["bash", "-c", "mkdir -p '" + dir + "'; " + geo + "exec wf-recorder " + (mode === "region" ? "-g \"$G\" " : out) + "-f '" + file + "'"];
        proc.running = true;
        startedAt = Date.now();
        elapsed = 0;
    }

    function stop() {
        if (recording)
            proc.signal(2);
    }

    function toggle(mode) {
        if (recording)
            stop();
        else
            start(mode || "region");
    }

    Process {
        id: proc
        onExited: code => {
            if (root.file.length)
                Quickshell.execDetached(["sh", "-c", "[ -s '" + root.file + "' ] && notify-send -a \"$(cat ~/.cache/catalyst/brand 2>/dev/null || echo catalyst)\" -i video-x-generic 'Enregistrement terminé' '" + root.file + "'"]);
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.recording
        onTriggered: root.elapsed = Math.round((Date.now() - root.startedAt) / 1000)
    }
}
