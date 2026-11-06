pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Spectre audio partagé (cava). Un seul process, lancé uniquement quand un
// visualiseur est affiché (compteur `users`, comme Gpu). `values` = barres 0..1.
Singleton {
    id: root

    property int bars: 24
    property int users: 0
    property var values: []
    readonly property bool active: users > 0

    readonly property string cfgPath: Quickshell.env("HOME") + "/.cache/catalyst/cava.conf"
    property bool cfgReady: false

    // écrit la config cava au démarrage (sortie brute ASCII sur stdout)
    Component.onCompleted: {
        const body = "[general]\n"
            + "bars = " + bars + "\n"
            + "framerate = 30\n"
            + "[input]\n"
            + "method = pipewire\n"
            + "source = auto\n"
            + "[output]\n"
            + "method = raw\n"
            + "raw_target = /dev/stdout\n"
            + "data_format = ascii\n"
            + "ascii_max_range = 100\n"
            + "channels = mono\n";
        writeProc.command = ["bash", "-c",
            "mkdir -p \"$(dirname " + shq(cfgPath) + ")\" && cat > " + shq(cfgPath) + " << 'EOF'\n" + body + "EOF"];
        writeProc.running = true;
    }
    function shq(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'"; }

    Process {
        id: writeProc
        onExited: root.cfgReady = true
    }

    Process {
        id: cava
        running: root.active && root.cfgReady
        command: ["cava", "-p", root.cfgPath]
        stdout: SplitParser {
            onRead: line => {
                const parts = line.split(";");
                const out = [];
                for (let i = 0; i < parts.length; i++) {
                    if (parts[i].length === 0) continue;
                    out.push(Math.max(0, Math.min(1, Number(parts[i]) / 100)));
                }
                if (out.length)
                    root.values = out;
            }
        }
        onRunningChanged: if (!running) root.values = [];
    }
}
