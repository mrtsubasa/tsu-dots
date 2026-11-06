pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/*
 * SekaiPop — réglages du shell sekaipop-rs dans le Studio (scripts/sekaipop-config.py).
 * Les changements rapprochés sont groupés pour ne relancer le service qu'une fois.
 */
Singleton {
    id: root

    readonly property string script: Quickshell.env("HOME") + "/.config/quickshell/catalyst/scripts/sekaipop-config.py"

    property bool loaded: false
    property bool busy: false
    property bool active: false
    property string error: ""
    property var bar: ({})
    property var osd: ({})

    property var _pending: ({})

    function refresh() {
        if (!busy)
            run(["get"]);
    }

    function set(section, key, value) {
        const copy = Object.assign({}, root[section]);
        copy[key] = value;
        root[section] = copy;
        _pending[section + "." + key] = JSON.stringify(value);
        flush.restart();
    }

    function setService(on) {
        active = on;
        run(["service", on ? "on" : "off"]);
    }

    function openSettings() {
        Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/sekaipop-rs", "--config"]);
    }

    function run(args) {
        busy = true;
        proc.command = [script].concat(args);
        proc.running = true;
    }

    Timer {
        id: flush
        interval: 500
        onTriggered: {
            if (root.busy) {
                restart();
                return;
            }
            const pairs = Object.keys(root._pending).map(k => k + "=" + root._pending[k]);
            root._pending = {};
            if (pairs.length)
                root.run(["apply"].concat(pairs));
        }
    }

    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    root.active = d.active;
                    root.error = d.error;
                    root.bar = d.bar;
                    root.osd = d.osd;
                    root.loaded = true;
                } catch (e) {
                    root.error = "Réponse illisible du script";
                }
            }
        }
        onExited: root.busy = false
    }
}
