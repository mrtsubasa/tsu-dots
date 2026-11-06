pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Fonds d'écran : bibliothèque du rice (wallpapers/sfw|nsfw pour les images,
// wallpapers/live/sfw|nsfw pour les animés ; hors git, ~/Images/Wallpapers y
// renvoie par lien), application globale via
// wallpaper.sh (awww + matugen, comportement existant inchangé) ou par écran
// via `awww img -o`. Le choix par écran est mémorisé et restauré au démarrage
// (scripts/catalyst-walls.sh restore). Aucun téléchargement automatique.
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.config/quickshell/catalyst/wallpapers"
    readonly property string sfwDir: dir + "/sfw"
    readonly property string nsfwDir: dir + "/nsfw"
    readonly property string liveDir: dir + "/live"
    readonly property string script: Quickshell.env("HOME") + "/.config/niri/scripts/wallpaper.sh"
    readonly property string cropScript: Quickshell.env("HOME") + "/.config/quickshell/catalyst/scripts/wallcrop.py"
    readonly property string mapPath: Quickshell.env("HOME") + "/.cache/catalyst/walls.json"

    // ---- cadrage (éditeur de recadrage avant application) ----
    property bool framing: false         // overlay éditeur ouvert
    property string framePath: ""        // image en cours de cadrage
    property string frameOutput: ""      // écran cible ("" = tous)
    property bool framingBusy: false     // rognage magick en cours
    property string frameError: ""

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

    // racine de catégorie : dir (images) ou dir/live (animés)
    function _root(p) {
        return p.indexOf(liveDir + "/") === 0 ? liveDir : dir;
    }
    function isNsfw(p) {
        return p.indexOf(_root(p) + "/nsfw/") === 0;
    }

    // reclasse un fond entre sfw/ et nsfw/ (même sous-dossier, même type), puis rescanne
    function reclassify(path, toNsfw) {
        const base = _root(path);
        const from = base + (toNsfw ? "/sfw" : "/nsfw");
        if (path.indexOf(from + "/") !== 0)
            return;
        const dest = base + (toNsfw ? "/nsfw" : "/sfw") + path.slice(from.length);
        mover.command = ["bash", "-c", "mkdir -p \"$(dirname \"$2\")\" && mv -n \"$1\" \"$2\"", "_", path, dest];
        mover.running = true;
    }
    Process {
        id: mover
        onExited: root.scan()
    }

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

    // ouvre l'éditeur de cadrage pour cette image / cet écran
    function frame(path, output) {
        if (!path)
            return;
        // vidéo : pas de cadrage possible, pose directe (mpvpaper via
        // wallpaper.sh, qui ne gère les vidéos qu'en global)
        if (isVideo(path)) {
            set(path, "");
            return;
        }
        framePath = path;
        frameOutput = output || "";
        frameError = "";
        framing = true;
    }
    function cancelFrame() {
        framing = false;
        framePath = "";
        frameError = "";
    }
    // rogne la zone normalisée (nx,ny,nw,nh) à la résolution tw×th puis applique
    function applyCrop(nx, ny, nw, nh, tw, th) {
        if (!framePath)
            return;
        framingBusy = true;
        frameError = "";
        cropper.out = frameOutput;
        cropper.buf = "";
        cropper.command = ["python3", cropScript, "crop", framePath,
            nx.toFixed(5), ny.toFixed(5), nw.toFixed(5), nh.toFixed(5),
            String(Math.round(tw)), String(Math.round(th))];
        cropper.running = true;
    }
    Process {
        id: cropper
        property string out: ""
        property string buf: ""
        stdout: SplitParser { onRead: d => cropper.buf += d }
        onExited: {
            root.framingBusy = false;
            let r = null;
            try { r = JSON.parse(cropper.buf); } catch (e) {}
            if (r && r.ok && r.path) {
                root.set(r.path, cropper.out);
                root.framing = false;
                root.framePath = "";
            } else {
                root.frameError = (r && r.error) ? r.error : "Échec du recadrage";
            }
        }
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
        // paquets Wallpaper Engine : vidéo jusqu'à 4 niveaux, aperçus exclus
        command: ["find", root.sfwDir, root.nsfwDir, root.liveDir, "-maxdepth", "5", "-type", "f", "-not", "-iname", "preview.*", "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", "-o", "-iname", "*.webp", "-o", "-iname", "*.mp4", "-o", "-iname", "*.webm", ")", "-not", "-path", "*/_corrupted/*", "-printf", "%T@\t%p\n"]
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
