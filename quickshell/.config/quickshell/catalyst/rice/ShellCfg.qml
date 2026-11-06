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
    // texte de la bannière en lettres blocs affichée à l'ouverture d'un terminal (tsu banner)
    property string banner: "tsu"
    // style du launcher : "list" (liste détaillée), "compact" (type Spotlight), "grid" (tuiles), "full" (grille plein écran), "console" (terminal)
    property string launcherStyle: "list"
    // polices du rice ("" = celle du design system) et échelle du texte
    property string fontUi: ""
    property string fontDisplay: ""
    property string fontMono: ""
    property real textScale: 1.0
    // position du launcher : "top" | "center" | "bottom" | "left" | "right" (le plein écran est toujours centré)
    property string launcherPos: "top"
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
    // éditeur pour ouvrir un projet depuis le launcher (commande)
    property string editor: "code"
    readonly property string brandPath: Quickshell.env("HOME") + "/.cache/catalyst/brand"
    readonly property string bannerPath: Quickshell.env("HOME") + "/.cache/catalyst/banner"
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
        if (obj.editor)
            editor = String(obj.editor);
        if (obj.autoGameMode !== undefined)
            autoGameMode = !!obj.autoGameMode;
        launcherStyle = ["list", "compact", "grid", "full", "console"].indexOf(obj.launcherStyle) >= 0 ? obj.launcherStyle : "list";
        launcherPos = ["top", "center", "bottom", "left", "right"].indexOf(obj.launcherPos) >= 0 ? obj.launcherPos : "top";
        fontUi = String(obj.fontUi || "");
        fontDisplay = String(obj.fontDisplay || "");
        fontMono = String(obj.fontMono || "");
        textScale = Math.max(0.8, Math.min(1.4, Number(obj.textScale) || 1));
        brand = obj.brand !== undefined && String(obj.brand).trim().length ? String(obj.brand).trim() : "catalyst";
        writeBrand();
        banner = obj.banner !== undefined && String(obj.banner).trim().length ? String(obj.banner).trim() : "tsu";
        writeBanner();
    }

    // copie lisible par les scripts et hyprlock
    function writeBrand() {
        brandProc.command = ["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"", "_", brandPath, brand];
        brandProc.running = true;
    }

    // copie lue par `tsu banner` au lancement de zsh
    function writeBanner() {
        bannerProc.command = ["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"", "_", bannerPath, banner];
        bannerProc.running = true;
    }

    function setBanner(v) {
        const t = String(v || "").trim().slice(0, 16);
        banner = t.length ? t : "tsu";
        save();
        writeBanner();
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
            banner: banner,
            launcherStyle: launcherStyle,
            launcherPos: launcherPos,
            fontUi: fontUi,
            fontDisplay: fontDisplay,
            fontMono: fontMono,
            textScale: textScale,
            trueTone: trueTone,
            trueToneStrength: trueToneStrength,
            nightLight: nightLight,
            nightTemp: nightTemp,
            dndOnShare: dndOnShare,
            rawMic: rawMic,
            autoGameMode: autoGameMode,
            editor: editor
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

    Process {
        id: bannerProc
    }
}
