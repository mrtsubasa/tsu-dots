pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string script: Quickshell.env("HOME") + "/.config/niri/scripts/brightness.sh"
    property real value: 0.7
    property int pendingPct: -1
    property bool applying: false
    readonly property int percentage: Math.round(value * 100)
    readonly property string glyph: value < 0.3 ? "󰃞" : (value < 0.7 ? "󰃟" : "󰃠")
    signal changed

    function set(v) {
        value = Math.max(0.01, Math.min(1, v));
        pendingPct = Math.round(value * 100);
        applyTimer.restart();
        changed();
    }

    function nudge(d) {
        set(value + d);
    }

    function refresh() {
        if (applying || applyTimer.running)
            return;
        getProc.running = true;
    }

    function flush() {
        if (pendingPct < 0)
            return;
        applying = true;
        const n = pendingPct;
        pendingPct = -1;
        setProc.command = [script, "set", String(n)];
        setProc.running = true;
    }

    Component.onCompleted: refresh()

    Timer {
        id: applyTimer
        interval: 140
        onTriggered: root.flush()
    }

    // les touches passent par l'IPC `brightness` (état connu du shell) :
    // relecture DDC lente, juste pour suivre un réglage fait sur l'écran
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: getProc
        command: [root.script, "get"]
        property string buf: ""
        stdout: SplitParser {
            onRead: data => getProc.buf += data
        }
        onRunningChanged: if (running)
            buf = ""
        onExited: {
            const n = parseInt(buf.trim(), 10);
            if (isFinite(n) && n >= 0)
                root.value = Math.max(0.01, Math.min(1, n / 100));
        }
    }

    Process {
        id: setProc
        onExited: root.applying = false
    }
}
