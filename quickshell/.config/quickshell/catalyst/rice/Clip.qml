pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/*
 * Presse-papiers (cliphist, 100 % local).
 *  - liste / recherche / copie / suppression d'une entrée / effacement total
 *  - pause : arrête les deux veilleurs `wl-paste --watch cliphist store`
 *    (lancés par l'autostart Hyprland) ; reprise = relance à l'identique.
 * Les copies marquées « sensibles » par les gestionnaires de mots de passe
 * (CLIPBOARD_STATE=sensitive) ne sont jamais enregistrées par cliphist.
 */
Singleton {
    id: root

    property var entries: []      // [{ id, line, text, image }]
    property bool loading: false
    property bool paused: false
    readonly property int count: entries.length

    function refresh() {
        if (loading)
            return;
        loading = true;
        lister._acc = [];
        lister.running = true;
        probe.running = true;
    }

    function copy(e) {
        if (!e)
            return;
        Quickshell.execDetached(["bash", "-c", "printf '%s' \"$1\" | cliphist decode | wl-copy", "_", e.line]);
    }

    function remove(e) {
        if (!e)
            return;
        entries = entries.filter(x => x.id !== e.id);
        Quickshell.execDetached(["bash", "-c", "printf '%s' \"$1\" | cliphist delete", "_", e.line]);
    }

    function wipe() {
        entries = [];
        Quickshell.execDetached(["bash", "-c", "cliphist wipe; wl-copy --clear"]);
    }

    function setPaused(p) {
        if (p)
            Quickshell.execDetached(["pkill", "-f", "^wl-paste --type (text|image) --watch cliphist store$"]);
        else
            Quickshell.execDetached(["bash", "-c", "setsid -f wl-paste --type text --watch cliphist store; setsid -f wl-paste --type image --watch cliphist store"]);
        paused = p;
        recheck.restart();
    }

    Timer {
        id: recheck
        interval: 800
        onTriggered: probe.running = true
    }

    Process {
        id: probe
        command: ["pgrep", "-f", "wl-paste --type text --watch cliphist store"]
        onExited: code => root.paused = code !== 0
    }

    Process {
        id: lister
        command: ["cliphist", "list"]
        property var _acc: []
        stdout: SplitParser {
            onRead: data => {
                if (lister._acc.length < 400)
                    lister._acc.push(data);
            }
        }
        onExited: {
            const out = [];
            for (let i = 0; i < lister._acc.length; i++) {
                const line = lister._acc[i];
                const tab = line.indexOf("\t");
                if (tab < 0)
                    continue;
                const text = line.slice(tab + 1);
                const img = /^\[\[ binary data .* (png|jpe?g|webp|bmp|gif) /i.test(text);
                out.push({ id: line.slice(0, tab), line: line, text: img ? text.replace(/^\[\[ binary data /, "Image · ").replace(/ \]\]$/, "") : text, image: img });
            }
            root.entries = out;
            root.loading = false;
        }
    }

    Component.onCompleted: probe.running = true
}
