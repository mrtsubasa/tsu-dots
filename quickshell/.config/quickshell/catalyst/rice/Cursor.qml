pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Curseur : thème et taille (Studio → Interface → Curseur). Le store est
// gsettings + le bloc marqué de ~/.config/hypr/local/extra_environment.lua
// (fichier user-local, non suivi par git) via scripts/cursor.py — rien dans
// le dépôt, et la config Hyprland suivie n'est jamais touchée.
Singleton {
    id: root

    property var themes: []
    property string theme: ""
    property int size: 24
    property bool ready: false

    readonly property string script: Quickshell.env("HOME") + "/.config/quickshell/catalyst/scripts/cursor.py"

    function refresh() {
        listProc.buf = "";
        listProc.running = true;
    }

    // taille seule : on garde le thème courant
    function setSize(n) {
        apply(theme || "default", n);
    }

    function setTheme(name) {
        apply(name, size);
    }

    function apply(name, n) {
        size = Math.max(8, Math.min(96, Math.round(n)));
        theme = name;
        applyProc.command = ["python3", script, "apply", name, String(size)];
        applyProc.running = true;
    }

    Process {
        id: listProc
        property string buf: ""
        command: ["python3", root.script, "list"]
        stdout: SplitParser { onRead: d => listProc.buf += d }
        onExited: {
            try {
                const o = JSON.parse(listProc.buf);
                root.themes = o.themes || [];
                if (o.current) {
                    root.theme = o.current.theme || "";
                    root.size = o.current.size || 24;
                }
                root.ready = true;
            } catch (e) {
                console.log("[Cursor] list", e);
                root.ready = true;
            }
        }
    }

    Process { id: applyProc }

    Component.onCompleted: refresh()
}
