pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Polices installées (fontconfig), pour les sélecteurs du Studio.
// `all` = toutes les familles, `mono` = familles à chasse fixe.
Singleton {
    id: root

    property var all: []
    property var mono: []
    property bool loaded: false

    function refresh() {
        allProc.buf = "";
        allProc.running = true;
        monoProc.buf = "";
        monoProc.running = true;
    }

    // « Nom,Alias » → « Nom », sans doublons, tri insensible à la casse
    function parse(text) {
        const seen = {};
        const out = [];
        text.split("\n").forEach(l => {
            const n = l.split(",")[0].trim();
            if (n.length && !n.startsWith(".") && !seen[n]) {
                seen[n] = true;
                out.push(n);
            }
        });
        return out.sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()));
    }

    Process {
        id: allProc
        property string buf: ""
        command: ["fc-list", ":", "family"]
        stdout: SplitParser {
            onRead: line => allProc.buf += line + "\n"
        }
        onExited: {
            root.all = root.parse(allProc.buf);
            root.loaded = true;
        }
    }

    Process {
        id: monoProc
        property string buf: ""
        command: ["fc-list", ":spacing=mono", "family"]
        stdout: SplitParser {
            onRead: line => monoProc.buf += line + "\n"
        }
        onExited: root.mono = root.parse(monoProc.buf)
    }
}
