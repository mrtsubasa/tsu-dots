pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Fonds d'écran : bibliothèque ~/Images/Wallpapers, application globale via
// wallpaper.sh (awww + matugen, comportement existant inchangé) ou par écran
// via `awww img -o`. Le choix par écran est mémorisé et restauré au démarrage
// (scripts/catalyst-walls.sh restore). Aucun téléchargement automatique.
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/Images/Wallpapers"
    readonly property string script: Quickshell.env("HOME") + "/.config/niri/scripts/wallpaper.sh"
    readonly property string mapPath: Quickshell.env("HOME") + "/.cache/catalyst/walls.json"

    property var files: []          // chemins absolus (images + vidéos)
    property bool scanning: false
    property var perOutput: ({})    // { "DP-2": "/chemin.jpg" }
    // miniatures prêtes (cache ~/.cache/catalyst/thumbs, scripts/thumbs.sh)
    property var thumbs: ({})
    readonly property string thumbDir: Quickshell.env("HOME") + "/.cache/catalyst/thumbs/"
    property var _pending: []

    function thumbOf(path) {
        return thumbs[path] ? "file://" + thumbDir + Qt.md5(path) + ".jpg" : "";
    }
    readonly property string current: SysInfo.wallpaper

    function isVideo(p) {
        return /\.(mp4|webm|mkv|mov|m4v|avi)$/i.test(p);
    }

    function scan() {
        if (scanning)
            return;
        scanning = true;
        lister._acc = [];
        lister.running = true;
    }

    // output "" = tous les écrans (pipeline complet : matugen, hyprlock…)
    function set(path, output) {
        if (!path)
            return;
        if (!output || !output.length) {
            perOutput = {};
            saveMap();
            Quickshell.execDetached(["bash", script, "set", path]);
            return;
        }
        const m = Object.assign({}, perOutput);
        m[output] = path;
        perOutput = m;
        saveMap();
        Quickshell.execDetached(["awww", "img", "-o", output, path, "--transition-type", "fade", "--transition-duration", "0.8", "--transition-fps", "60"]);
    }

    function random() {
        Quickshell.execDetached(["bash", script, "random"]);
    }

    function wallFor(output) {
        return perOutput[output] || current;
    }

    function saveMap() {
        writer.command = ["bash", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"", "_", mapPath, JSON.stringify(perOutput)];
        writer.running = true;
    }

    Process { id: writer }

    Process {
        id: lister
        property var _acc: []
        command: ["find", root.dir, "-maxdepth", "2", "-type", "f", "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", "-o", "-iname", "*.webp", "-o", "-iname", "*.mp4", "-o", "-iname", "*.webm", ")", "-not", "-path", "*/_corrupted/*", "-printf", "%T@\t%p\n"]
        stdout: SplitParser {
            onRead: data => lister._acc.push(data)
        }
        onExited: {
            // plus récents d'abord
            const rows = lister._acc.map(l => l.split("\t")).filter(r => r.length === 2);
            rows.sort((a, b) => Number(b[0]) - Number(a[0]));
            root.files = rows.map(r => r[1]);
            root.scanning = false;
            thumber.command = ["bash", Quickshell.env("HOME") + "/.config/quickshell/catalyst/scripts/thumbs.sh"].concat(root.files);
            thumber.running = true;
        }
    }

    Process {
        id: thumber
        stdout: SplitParser {
            onRead: data => {
                root._pending.push(data);
                if (!flush.running)
                    flush.start();
            }
        }
        onExited: flush.triggered()
    }

    // regroupe les mises à jour (une réaffectation par 300 ms)
    Timer {
        id: flush
        interval: 300
        onTriggered: {
            if (!root._pending.length)
                return;
            const t = Object.assign({}, root.thumbs);
            for (let i = 0; i < root._pending.length; i++)
                t[root._pending[i]] = true;
            root._pending = [];
            root.thumbs = t;
        }
    }

    FileView {
        path: root.mapPath
        onLoaded: {
            try {
                root.perOutput = JSON.parse(text()) || {};
            } catch (e) {
                root.perOutput = {};
            }
        }
    }
}
