pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool bar: true
    property bool osd: true
    property bool atelier: true
    property bool replaceWaybar: true
    property bool widgets: true
    // "desk" = couche fond, masqués dès qu'une fenêtre occupe l'écran
    // "top"  = toujours visibles, au-dessus des fenêtres
    property string widgetsLayer: "desk"
    property string paletteMode: "auto"
    property string palette: "tokyonight"
    // id du thème complet (identity + palette) appliqué, "" = custom/auto
    property string theme: ""
    // mot de marque affiché dans l'interface (en-têtes, launcher, verrouillage…)
    property string brand: "catalyst"
    // affichage : True Tone (blanc adapté à la lumière estimée), lumière nocturne
    property bool trueTone: false
    property real trueToneStrength: 0.7
    property bool nightLight: false
    property int nightTemp: 3800
    // vie privée / audio
    property bool dndOnShare: true
    property string rawMic: ""          // dernier micro physique choisi (node.name)
    // mode jeu automatique quand un jeu passe en plein écran
    property bool autoGameMode: true
    readonly property string brandPath: Quickshell.env("HOME") + "/.cache/catalyst/brand"
    // true une fois le premier chargement terminé (sécurise Themes/Atelier)
    property bool fileReady: false

    readonly property string path: Quickshell.env("HOME") + "/.config/quickshell/catalyst/shell.json"

    function apply(obj) {
        if (!obj)
            return;
        if (obj.bar !== undefined)
            bar = !!obj.bar;
        if (obj.osd !== undefined)
            osd = !!obj.osd;
        if (obj.atelier !== undefined)
            atelier = !!obj.atelier;
        if (obj.replaceWaybar !== undefined)
            replaceWaybar = !!obj.replaceWaybar;
        if (obj.widgets !== undefined)
            widgets = !!obj.widgets;
        if (obj.widgetsLayer)
            widgetsLayer = obj.widgetsLayer === "top" ? "top" : "desk";
        if (obj.paletteMode)
            paletteMode = obj.paletteMode;
        if (obj.palette)
            palette = obj.palette;
        theme = obj.theme || "";
        if (obj.trueTone !== undefined)
            trueTone = !!obj.trueTone;
        if (obj.trueToneStrength !== undefined)
            trueToneStrength = Math.max(0.1, Math.min(1, Number(obj.trueToneStrength) || 0.7));
        if (obj.nightLight !== undefined)
            nightLight = !!obj.nightLight;
        if (obj.nightTemp !== undefined)
            nightTemp = Math.max(2500, Math.min(5500, Number(obj.nightTemp) || 3800));
        if (obj.dndOnShare !== undefined)
            dndOnShare = !!obj.dndOnShare;
        if (obj.rawMic !== undefined)
            rawMic = String(obj.rawMic || "");
        if (obj.autoGameMode !== undefined)
            autoGameMode = !!obj.autoGameMode;
        brand = obj.brand !== undefined && String(obj.brand).trim().length ? String(obj.brand).trim() : "catalyst";
        writeBrand();
    }

    // copie lisible par les scripts et hyprlock
    function writeBrand() {
        brandProc.command = ["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"", "_", brandPath, brand];
        brandProc.running = true;
    }

    function setBrand(v) {
        const t = String(v || "").trim().slice(0, 32);
        brand = t.length ? t : "catalyst";
        save();
        writeBrand();
    }

    function dump() {
        return JSON.stringify({
            bar: bar,
            osd: osd,
            atelier: atelier,
            replaceWaybar: replaceWaybar,
            widgets: widgets,
            widgetsLayer: widgetsLayer,
            paletteMode: paletteMode,
            palette: palette,
            theme: theme,
            brand: brand,
            trueTone: trueTone,
            trueToneStrength: trueToneStrength,
            nightLight: nightLight,
            nightTemp: nightTemp,
            dndOnShare: dndOnShare,
            rawMic: rawMic,
            autoGameMode: autoGameMode
        }, null, 2) + "\n";
    }

    function save() {
        writeProc.command = ["bash", "-c", "cat > " + shellEscape(path) + " << 'EOF'\n" + dump() + "EOF"];
        writeProc.running = true;
    }

    function set(key, value) {
        root[key] = value;
        save();
    }

    function shellEscape(str) {
        return "'" + String(str).replace(/'/g, "'\\''") + "'";
    }

    FileView {
        path: root.path
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.apply(JSON.parse(text()));
            } catch (e) {
                console.log("[ShellCfg] parse error", e);
            }
            root.fileReady = true;
        }
    }

    Process {
        id: writeProc
    }

    Process {
        id: brandProc
    }
}
