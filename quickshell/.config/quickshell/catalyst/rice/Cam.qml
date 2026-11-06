pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/*
 * Cam — filtres webcam en temps réel (scripts/cam-filter.sh).
 * Applique une chaîne GStreamer à la vraie webcam et réexpose le flux sur une
 * caméra virtuelle (v4l2loopback) que Discord/navigateur sélectionnent.
 * Le toggle de barre (BarCam) et le panneau (CamPanel) pilotent cet état.
 */
Singleton {
    id: root

    readonly property string script: Quickshell.env("HOME") + "/.config/quickshell/catalyst/scripts/cam-filter.sh"

    property bool on: false
    property string preset: "cyber"
    property string sink: ""
    property string image: ""        // image choisie (fond chroma / mode Image)
    property string note: ""
    property bool noteError: false
    property int users: 0

    // presets groupés (id, libellé, icône, groupe)
    readonly property var presets: [
        { id: "scene",   label: "Scène",        icon: "dashboard",     group: "Scène" },
        // --- Rendu ---
        { id: "cyber",   label: "Cyberpunk",    icon: "bolt",          group: "Rendu" },
        { id: "noir",    label: "Noir & blanc", icon: "contrast",      group: "Rendu" },
        { id: "retouch", label: "Retouche",     icon: "auto_fix_high", group: "Rendu" },
        { id: "sepia",   label: "Sépia",        icon: "filter_vintage",group: "Rendu" },
        { id: "thermal", label: "Thermique",    icon: "thermostat",    group: "Rendu" },
        // --- Fond ---
        { id: "bgblur",  label: "Fond flou",    icon: "blur_linear",   group: "Fond", ai: true },
        { id: "bgimage", label: "Fond image",   icon: "wallpaper",     group: "Fond", ai: true },
        { id: "chroma",  label: "Fond vert",    icon: "panorama",      group: "Fond" },
        { id: "image",   label: "Image fixe",   icon: "image",         group: "Fond" },
        // --- Dessin ---
        { id: "aianime", label: "Anime IA",     icon: "auto_awesome",  group: "Dessin", ai: true },
        { id: "cartoon", label: "Cartoon",      icon: "brush",         group: "Dessin" },
        { id: "anime",   label: "Anime",        icon: "animation",     group: "Dessin" },
        { id: "manga",   label: "Manga",        icon: "draw",          group: "Dessin" },
        { id: "comic",   label: "Comics",       icon: "grain",         group: "Dessin" },
        { id: "pixel",   label: "Pixel",        icon: "grid_view",     group: "Dessin" },
        // --- Déformation ---
        { id: "mirror",  label: "Miroir",       icon: "flip",          group: "Déformation" },
        { id: "fisheye", label: "Fisheye",      icon: "lens",          group: "Déformation" },
        { id: "kaleid",  label: "Kaléido",      icon: "auto_awesome",  group: "Déformation" },
        { id: "water",   label: "Eau",          icon: "water",         group: "Déformation" },
        { id: "pixsort", label: "Pixel-sort",   icon: "sort",          group: "Déformation" },
        { id: "distort", label: "Distorsion",   icon: "waves",         group: "Déformation" },
        { id: "emboss",  label: "Relief",       icon: "landscape",     group: "Déformation" },
        // --- Fun ---
        { id: "neon",    label: "Néon",         icon: "blur_on",       group: "Fun" },
        { id: "glitch",  label: "Glitch",       icon: "bolt",          group: "Fun" },
        { id: "vhs",     label: "VHS",          icon: "videocam",      group: "Fun" },
        { id: "crt",     label: "CRT",          icon: "tv",            group: "Fun" },
        { id: "matrix",  label: "Matrix",       icon: "terminal",      group: "Fun" }
    ]
    readonly property var groups: ["Rendu", "Fond", "Dessin", "Déformation", "Fun"]
    // presets qui consomment l'image choisie (chroma = fond vert, image = plein cadre)
    readonly property var imagePresets: ["chroma", "image", "bgimage"]
    function presetsOf(g) { return presets.filter(p => p.group === g); }
    function labelOf(id) { const p = presets.find(x => x.id === id); return p ? p.label : id; }

    function say(text, err) {
        note = text;
        noteError = !!err;
        noteT.restart();
    }
    Timer { id: noteT; interval: 7000; onTriggered: root.note = "" }

    // ---- contrôle ----
    function start(p) {
        if (p && p.length)
            preset = p;
        ctl.buf = "";
        ctl.command = ["bash", script, "start", preset];
        ctl.running = true;
    }
    function stop() {
        ctl.buf = "";
        ctl.command = ["bash", script, "stop"];
        ctl.running = true;
    }
    function toggle() {
        if (on) stop(); else start(preset);
    }
    function select(p) {
        // choisir un preset : (re)démarre dessus
        start(p);
    }

    // ---- image de fond / source ----
    function setImage(path) {
        if (!path || !path.length)
            return;
        imgProc.buf = "";
        imgProc.command = ["bash", script, "setimg", path];
        imgProc.running = true;
    }
    Process {
        id: imgProc
        property string buf: ""
        stdout: SplitParser { onRead: d => imgProc.buf += d }
        onExited: {
            let r = null;
            try { r = JSON.parse(imgProc.buf); } catch (e) {}
            if (r && r.error) { root.say(r.error, true); return; }
            // si un preset qui utilise l'image est actif, le relancer pour l'appliquer
            if (root.on && root.imagePresets.indexOf(root.preset) >= 0)
                root.start(root.preset);
            else
                root.refresh();
        }
    }
    // sélecteur de fichier (zenity) pour choisir l'image
    function pickImage() {
        pickProc.target = "";
        pickProc.buf = "";
        pickProc.command = ["zenity", "--file-selection", "--title=Image pour la caméra",
            "--file-filter=Images | *.png *.jpg *.jpeg *.webp *.bmp"];
        pickProc.running = true;
    }
    Process {
        id: pickProc
        property string buf: ""
        property string target: ""      // "" = image globale, "+" = nouveau calque, sinon id de calque
        stdout: SplitParser { onRead: d => pickProc.buf += d }
        onExited: {
            const p = pickProc.buf.trim();
            if (!p.length) return;
            if (pickProc.target === "") root.setImage(p);
            else if (pickProc.target === "+") root.addLayer("image:" + p);
            else root.updateLayer(pickProc.target, { source: "image:" + p });
        }
    }

    Process {
        id: ctl
        property string buf: ""
        stdout: SplitParser { onRead: d => ctl.buf += d }
        onExited: {
            let r = null;
            try { r = JSON.parse(ctl.buf); } catch (e) {}
            if (r && r.error)
                root.say(r.error, true);
            else if (r && r.ok && r.preset)
                root.say("Filtre « " + root.labelOf(r.preset) + " » actif", false);
            refresh();
        }
    }

    // ---- statut ----
    function refresh() {
        stat.buf = "";
        stat.command = ["bash", script, "status"];
        stat.running = true;
    }
    Process {
        id: stat
        property string buf: ""
        stdout: SplitParser { onRead: d => stat.buf += d }
        onExited: {
            try {
                const r = JSON.parse(stat.buf);
                root.on = !!r.on;
                if (r.preset) root.preset = r.preset;
                root.sink = r.sink || "";
                root.image = r.image || "";
            } catch (e) {}
        }
    }

    // ---- scène multi-sources (scripts/cam_scene.py, relue à chaud) ----
    readonly property string previewPath: (Quickshell.env("XDG_RUNTIME_DIR") || (Quickshell.env("HOME") + "/.cache/catalyst")) + "/catalyst-cam-preview.jpg"
    readonly property bool sceneOn: on && preset === "scene"
    readonly property var screens: Quickshell.screens.map(s => s.name)
    readonly property var sceneFilters: [
        { id: "none",    label: "Aucun" },
        { id: "noir",    label: "Noir & blanc" },
        { id: "sepia",   label: "Sépia" },
        { id: "cyber",   label: "Cyberpunk" },
        { id: "thermal", label: "Thermique" },
        { id: "invert",  label: "Négatif" },
        { id: "blur",    label: "Flou" },
        { id: "pixel",   label: "Pixel" },
        { id: "poster",  label: "Poster" },
        { id: "cartoon", label: "Cartoon" },
        { id: "comic",   label: "Comics" },
        { id: "manga",   label: "Manga" },
        { id: "neon",    label: "Néon" },
        { id: "crt",     label: "CRT" },
        { id: "vhs",     label: "VHS" },
        { id: "glitch",  label: "Glitch" },
        { id: "matrix",  label: "Matrix" }
    ]
    property var layers: []
    property var layerIds: []           // ne change qu'à l'ajout/retrait/réordre (le glisser garde ses délégués)
    property string selected: ""

    function layer(id) { return layers.find(l => l.id === id) || null; }
    function sourceLabel(src) {
        if (src === "cam") return "Webcam";
        if (src.indexOf("screen:") === 0) return "Écran " + src.slice(7);
        return src.split("/").pop();
    }
    function sourceIcon(src) {
        if (src === "cam") return "videocam";
        return src.indexOf("screen:") === 0 ? "desktop_windows" : "image";
    }
    function _setLayers(next, save) {
        layers = next;
        const ids = next.map(l => l.id);
        if (ids.join("|") !== layerIds.join("|"))
            layerIds = ids;
        if (!layer(selected))
            selected = next.length ? next[next.length - 1].id : "";
        if (save)
            saveT.restart();
    }
    function updateLayer(id, patch) {
        _setLayers(layers.map(l => l.id === id ? Object.assign({}, l, patch) : l), true);
    }
    function addLayer(source) {
        let id = "l" + Date.now();
        while (layer(id))
            id += "x";
        // nouveau calque en incrustation, décalé pour ne pas recouvrir le précédent
        const n = layers.length % 4;
        _setLayers(layers.concat([{ id: id, source: source, visible: true, x: 0.05 + n * 0.08, y: 0.05 + n * 0.08, w: 0.4, h: 0.4,
                                    fit: "cover", filter: "none", brightness: 0, contrast: 1, saturation: 1,
                                    opacity: 1, radius: 0, mirror: false, cutout: false }]), true);
        selected = id;
    }
    function removeLayer(id) { _setLayers(layers.filter(l => l.id !== id), true); }
    function moveLayer(id, delta) {
        const i = layers.findIndex(l => l.id === id);
        const j = i + delta;
        if (i < 0 || j < 0 || j >= layers.length) return;
        const next = layers.slice();
        next.splice(j, 0, next.splice(i, 1)[0]);
        _setLayers(next, true);
    }
    function pickLayerImage(id) {
        pickProc.target = id;
        pickProc.buf = "";
        pickProc.command = ["zenity", "--file-selection", "--title=Image du calque",
            "--file-filter=Images | *.png *.jpg *.jpeg *.webp *.bmp"];
        pickProc.running = true;
    }
    // dispositions rapides, appliquées aux calques visibles
    function arrange(mode) {
        const shown = layers.filter(l => l.visible !== false);
        if (!shown.length) return;
        const pos = {};
        const hide = [];
        const put = (l, x, y, w, h, radius) => pos[l.id] = { x: x, y: y, w: w, h: h, radius: radius };
        if (mode === "solo") {
            const main = layer(selected) || shown[0];
            put(main, 0, 0, 1, 1, 0);
            shown.forEach(l => { if (l.id !== main.id) hide.push(l.id); });
        } else if (mode === "pip") {
            // la webcam passe en incrustation de préférence
            const small = shown.filter(l => l.source === "cam");
            const large = shown.filter(l => l.source !== "cam");
            const main = large.length ? large[0] : small.shift();
            large.slice(1).forEach(l => small.push(l));
            put(main, 0, 0, 1, 1, 0);
            small.forEach((l, i) => put(l, 0.71, 0.69 - i * 0.31, 0.27, 0.28, 0.08));
        } else {
            const cols = mode === "split" ? shown.length : Math.ceil(Math.sqrt(shown.length));
            const rows = Math.ceil(shown.length / cols);
            shown.forEach((l, i) => {
                const r = Math.floor(i / cols);
                const inRow = r === rows - 1 ? shown.length - cols * (rows - 1) : cols;
                put(l, (i % cols) / inRow, r / rows, 1 / inRow, 1 / rows, 0);
            });
        }
        _setLayers(layers.map(l => {
            if (hide.indexOf(l.id) >= 0) return Object.assign({}, l, { visible: false });
            return pos[l.id] ? Object.assign({}, l, pos[l.id]) : l;
        }), true);
    }
    Timer {
        id: saveT
        interval: 120
        onTriggered: sceneFile.setText(JSON.stringify({ layers: root.layers }, null, 2))
    }
    FileView {
        id: sceneFile
        path: Quickshell.env("HOME") + "/.local/share/catalyst/cam-scene.json"
        printErrors: false
        onLoaded: {
            try {
                root._setLayers(JSON.parse(text()).layers || [], false);
            } catch (e) {
                console.log("[Cam] scène illisible", e);
            }
        }
        onLoadFailed: {
            // première utilisation : écran principal + webcam en incrustation
            if (root.screens.length)
                root.addLayer("screen:" + root.screens[0]);
            root.addLayer("cam");
            root.arrange("pip");
        }
    }

    onUsersChanged: if (users > 0) refresh()
    Component.onCompleted: refresh()
}
