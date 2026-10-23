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
            brand: brand
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
