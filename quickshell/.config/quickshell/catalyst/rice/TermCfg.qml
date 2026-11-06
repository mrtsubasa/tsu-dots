pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Terminal (Studio → Terminal) : accueil de zsh (bannière, fastfetch, gadget) et
// apparence d'Alacritty / Kitty / Ghostty. Les réglages vivent dans terminal.json ;
// à chaque changement on régénère ce que lisent `tsu greet` (greet.env) et les
// terminaux (catalyst.toml / catalyst.conf, hors git).
// Règle : une valeur « défaut » (0, -1, "") n'est jamais écrite, la config de
// chaque terminal reste alors maîtresse.
Singleton {
    id: root

    // ---- accueil ----
    property bool banner: true
    property string bannerColor: "blue"   // blue | accent | rainbow
    property string bannerStyle: "blocks" // blocks | slant | small | big | future | pagga
    property bool fetch: true
    property string extra: "none"         // none | random | pokemon | fortune | cowsay | bonsai
    property bool shiny: false
    property string pokemon: ""           // nom précis, "" = au hasard
    property string cow: "default"        // personnage de cowsay

    // ---- apparence ----
    property string fontFamily: ""
    property real fontSize: 0
    property real opacity: 0
    property int padding: -1
    property int lineHeight: 0            // % (100 = normal), 0 = défaut
    property string cursorShape: ""       // block | beam | underline
    property string cursorBlink: ""       // on | off
    property int scrollback: 0            // lignes, 0 = défaut
    property bool copyOnSelect: false
    property string colors: "terminal"    // terminal | rice

    property bool fileReady: false

    // commandes présentes sur le système (rempli par refreshTools)
    property var tools: ({})

    // gadgets d'accueil : commande à tester + paquet qui l'installe
    readonly property var extras: [
        { id: "none", label: "Aucun", cmd: "", pkg: "" },
        { id: "random", label: "Au hasard", cmd: "", pkg: "" },
        { id: "pokemon", label: "Pokémon", cmd: "pokemon-colorscripts", pkg: "pokemon-colorscripts-git" },
        { id: "fortune", label: "Citation", cmd: "fortune", pkg: "fortune-mod" },
        { id: "cowsay", label: "Vache", cmd: "cowsay", pkg: "cowsay" },
        { id: "bonsai", label: "Bonsaï", cmd: "cbonsai", pkg: "cbonsai" }
    ]
    readonly property var bannerStyles: [
        { id: "blocks", label: "Blocs", cmd: "" },
        { id: "slant", label: "Penché", cmd: "figlet" },
        { id: "small", label: "Petit", cmd: "figlet" },
        { id: "big", label: "Grand", cmd: "figlet" },
        { id: "future", label: "Future", cmd: "toilet" },
        { id: "pagga", label: "Pagga", cmd: "toilet" }
    ]
    readonly property var cows: [
        { id: "default", label: "Vache" },
        { id: "tux", label: "Tux" },
        { id: "dragon", label: "Dragon" },
        { id: "stegosaurus", label: "Stégo" },
        { id: "sheep", label: "Mouton" }
    ]
    // tous les paquets « fun » proposés dans la page
    readonly property var funPackages: [
        { cmd: "pokemon-colorscripts", pkg: "pokemon-colorscripts-git", desc: "Pokémon en couleurs (≈ 900, shiny compris)" },
        { cmd: "fortune", pkg: "fortune-mod", desc: "Citations et proverbes aléatoires" },
        { cmd: "cowsay", pkg: "cowsay", desc: "Une vache (ou Tux, un dragon…) qui parle" },
        { cmd: "cbonsai", pkg: "cbonsai", desc: "Bonsaï généré en ASCII" },
        { cmd: "lolcat", pkg: "lolcat", desc: "Bannière arc-en-ciel" },
        { cmd: "figlet", pkg: "figlet", desc: "Styles de bannière Penché, Petit, Grand" },
        { cmd: "toilet", pkg: "toilet", desc: "Styles de bannière Future, Pagga" },
        { cmd: "cmatrix", pkg: "cmatrix", desc: "Pluie façon Matrix (à lancer à la main)" },
        { cmd: "pipes.sh", pkg: "pipes.sh", desc: "Tuyaux animés (à lancer à la main)" }
    ]

    readonly property string home: Quickshell.env("HOME")
    readonly property string path: home + "/.config/quickshell/catalyst/terminal.json"

    function has(cmd) {
        return !!tools[cmd];
    }

    function extraInfo(id) {
        return extras.find(e => e.id === id) || extras[0];
    }

    function styleInfo(id) {
        return bannerStyles.find(e => e.id === id) || bannerStyles[0];
    }

    function oneOf(v, list, def) {
        return list.indexOf(v) >= 0 ? v : def;
    }

    function apply(o) {
        if (!o)
            return;
        if (o.banner !== undefined)
            banner = !!o.banner;
        bannerColor = oneOf(o.bannerColor, ["blue", "accent", "rainbow"], "blue");
        bannerStyle = oneOf(o.bannerStyle, bannerStyles.map(s => s.id), "blocks");
        if (o.fetch !== undefined)
            fetch = !!o.fetch;
        extra = oneOf(o.extra, extras.map(e => e.id), "none");
        if (o.shiny !== undefined)
            shiny = !!o.shiny;
        pokemon = String(o.pokemon || "").replace(/[^A-Za-z0-9-]/g, "").toLowerCase();
        cow = oneOf(o.cow, cows.map(c => c.id), "default");

        fontFamily = String(o.fontFamily || "");
        const fs = Number(o.fontSize) || 0;
        fontSize = fs > 0 ? Math.max(7, Math.min(24, fs)) : 0;
        const op = Number(o.opacity) || 0;
        opacity = op > 0 ? Math.max(0.3, Math.min(1, op)) : 0;
        const pad = o.padding === undefined ? -1 : Math.round(Number(o.padding));
        padding = pad >= 0 ? Math.min(48, pad) : -1;
        const lh = Math.round(Number(o.lineHeight) || 0);
        lineHeight = lh > 0 ? Math.max(80, Math.min(180, lh)) : 0;
        cursorShape = oneOf(o.cursorShape, ["block", "beam", "underline"], "");
        cursorBlink = oneOf(o.cursorBlink, ["on", "off"], "");
        const sb = Math.round(Number(o.scrollback) || 0);
        scrollback = sb > 0 ? Math.min(200000, sb) : 0;
        copyOnSelect = !!o.copyOnSelect;
        colors = oneOf(o.colors, ["terminal", "rice"], "terminal");
        writeAll();
    }

    function set(key, value) {
        root[key] = value;
        save();
        writeAll();
    }

    function dump() {
        return JSON.stringify({
            banner: banner,
            bannerColor: bannerColor,
            bannerStyle: bannerStyle,
            fetch: fetch,
            extra: extra,
            shiny: shiny,
            pokemon: pokemon,
            cow: cow,
            fontFamily: fontFamily,
            fontSize: fontSize,
            opacity: opacity,
            padding: padding,
            lineHeight: lineHeight,
            cursorShape: cursorShape,
            cursorBlink: cursorBlink,
            scrollback: scrollback,
            copyOnSelect: copyOnSelect,
            colors: colors
        }, null, 2) + "\n";
    }

    // écriture atomique (tmp + mv) : le FileView ne lit jamais un fichier à moitié écrit
    function save() {
        saveProc.command = ["sh", "-c", "printf '%s' \"$2\" > \"$1.tmp\" && mv \"$1.tmp\" \"$1\"", "_", path, dump()];
        saveProc.running = true;
    }

    function accentRgb() {
        const c = Theme.accent;
        return Math.round(c.r * 255) + ";" + Math.round(c.g * 255) + ";" + Math.round(c.b * 255);
    }

    // palette ANSI tirée du thème du rice : 0-7 normal, 8-15 clair
    function ricePalette() {
        const bg = Theme.background, fg = Theme.ink, white = Qt.rgba(1, 1, 1, 1);
        const cyan = Theme.mix(Theme.electric, Theme.success, 0.5);
        const normal = [Theme.mix(bg, fg, 0.18), Theme.error, Theme.success, Theme.warning, Theme.electric, Theme.primary, cyan, Theme.mix(bg, fg, 0.8)];
        const bright = [Theme.mix(bg, fg, 0.42)].concat(normal.slice(1, 7).map(c => Theme.mix(c, white, 0.25))).concat([fg]);
        return {
            bg: Theme.hex(bg),
            fg: Theme.hex(fg),
            cursor: Theme.hex(Theme.accent),
            selection: Theme.hex(Theme.mix(bg, Theme.accent, 0.35)),
            ansi: normal.concat(bright).map(c => Theme.hex(c))
        };
    }

    function q(s) {
        return "\"" + String(s).replace(/\\/g, "\\\\").replace(/"/g, "\\\"") + "\"";
    }

    function alacrittyConf(p) {
        const sec = {};
        const add = (k, line) => (sec[k] = (sec[k] || "") + line + "\n");
        if (opacity > 0)
            add("window", "opacity = " + opacity.toFixed(2));
        if (padding >= 0)
            add("window", "padding = { x = " + padding + ", y = " + padding + " }");
        if (fontSize > 0)
            add("font", "size = " + fontSize.toFixed(1));
        if (fontFamily.length)
            add("font", "normal = { family = " + q(fontFamily) + " }");
        if (lineHeight > 0)
            add("font", "offset = { x = 0, y = " + Math.round((lineHeight - 100) / 100 * (fontSize > 0 ? fontSize : 11) * 1.33) + " }");
        if (cursorShape.length || cursorBlink.length) {
            const shape = { block: "Block", beam: "Beam", underline: "Underline" }[cursorShape] || "Block";
            add("cursor", "style = { shape = " + q(shape) + ", blinking = " + q(cursorBlink === "on" ? "On" : (cursorBlink === "off" ? "Off" : "Off")) + " }");
        }
        if (scrollback > 0)
            add("scrolling", "history = " + Math.min(100000, scrollback));
        if (copyOnSelect)
            add("selection", "save_to_clipboard = true");
        if (p) {
            add("colors.primary", "background = " + q(p.bg) + "\nforeground = " + q(p.fg));
            add("colors.cursor", "cursor = " + q(p.cursor) + "\ntext = " + q(p.bg));
            add("colors.selection", "background = " + q(p.selection) + "\ntext = " + q(p.fg));
            const names = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"];
            add("colors.normal", names.map((n, i) => n + " = " + q(p.ansi[i])).join("\n"));
            add("colors.bright", names.map((n, i) => n + " = " + q(p.ansi[i + 8])).join("\n"));
        }
        return Object.keys(sec).map(k => "[" + k + "]\n" + sec[k]).join("\n");
    }

    function kittyConf(p) {
        let s = "";
        if (opacity > 0)
            s += "background_opacity " + opacity.toFixed(2) + "\n";
        if (fontSize > 0)
            s += "font_size " + fontSize.toFixed(1) + "\n";
        if (fontFamily.length)
            s += "font_family " + fontFamily + "\n";
        if (padding >= 0)
            s += "window_padding_width " + padding + "\n";
        if (lineHeight > 0)
            s += "modify_cell_height " + lineHeight + "%\n";
        if (cursorShape.length)
            s += "cursor_shape " + cursorShape + "\n";
        if (cursorBlink.length)
            s += "cursor_blink_interval " + (cursorBlink === "on" ? "-1" : "0") + "\n";
        if (scrollback > 0)
            s += "scrollback_lines " + scrollback + "\n";
        if (copyOnSelect)
            s += "copy_on_select clipboard\n";
        if (p) {
            s += "background " + p.bg + "\nforeground " + p.fg + "\ncursor " + p.cursor + "\n";
            s += "selection_background " + p.selection + "\nselection_foreground " + p.fg + "\n";
            for (let i = 0; i < 16; i++)
                s += "color" + i + " " + p.ansi[i] + "\n";
        }
        return s;
    }

    function ghosttyConf(p) {
        let s = "";
        if (opacity > 0)
            s += "background-opacity = " + opacity.toFixed(2) + "\n";
        if (fontSize > 0)
            s += "font-size = " + fontSize.toFixed(1) + "\n";
        if (fontFamily.length)
            s += "font-family = " + q(fontFamily) + "\n";
        if (padding >= 0)
            s += "window-padding-x = " + padding + "\nwindow-padding-y = " + padding + "\n";
        if (lineHeight > 0)
            s += "adjust-cell-height = " + (lineHeight - 100) + "%\n";
        if (cursorShape.length)
            s += "cursor-style = " + (cursorShape === "beam" ? "bar" : cursorShape) + "\n";
        if (cursorBlink.length)
            s += "cursor-style-blink = " + (cursorBlink === "on") + "\n";
        if (copyOnSelect)
            s += "copy-on-select = clipboard\n";
        if (p) {
            s += "background = " + p.bg + "\nforeground = " + p.fg + "\ncursor-color = " + p.cursor + "\nselection-background = " + p.selection + "\n";
            for (let i = 0; i < 16; i++)
                s += "palette = " + i + "=" + p.ansi[i] + "\n";
        }
        return s;
    }

    function writeAll() {
        const greet = "# Généré par Studio → Terminal\n"
            + "GREET_BANNER=" + (banner ? 1 : 0) + "\n"
            + "GREET_BANNER_COLOR=" + bannerColor + "\n"
            + "GREET_BANNER_STYLE=" + bannerStyle + "\n"
            + "GREET_ACCENT=\"" + accentRgb() + "\"\n"
            + "GREET_FETCH=" + (fetch ? 1 : 0) + "\n"
            + "GREET_EXTRA=" + extra + "\n"
            + "GREET_SHINY=" + (shiny ? 1 : 0) + "\n"
            + "GREET_POKEMON=" + pokemon + "\n"
            + "GREET_COW=" + cow + "\n";
        const head = "# Généré par Studio → Terminal — ne pas éditer\n";
        const p = colors === "rice" ? ricePalette() : null;
        const cfg = home + "/.config/";
        writeProc.command = ["sh", "-c",
            "w() { mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1.tmp\" && mv \"$1.tmp\" \"$1\"; }; "
            + "w \"$1\" \"$2\"; "
            + "[ -d \"$3\" ] && w \"$3/catalyst.toml\" \"$4\"; "
            + "[ -d \"$5\" ] && w \"$5/catalyst.conf\" \"$6\"; "
            + "[ -d \"$7\" ] && w \"$7/catalyst.conf\" \"$8\"; "
            // Kitty relit sa config sur SIGUSR1 ; Alacritty surveille ses fichiers ; Ghostty : nouvelles fenêtres
            + "pkill -USR1 -x kitty 2>/dev/null; true",
            "_", home + "/.cache/catalyst/greet.env", greet,
            cfg + "alacritty", head + alacrittyConf(p),
            cfg + "kitty", head + kittyConf(p),
            cfg + "ghostty", head + ghosttyConf(p)];
        writeProc.running = true;
    }

    function refreshTools() {
        const cmds = funPackages.map(p => p.cmd).concat(["fastfetch"]);
        toolsProc.buf = "";
        toolsProc.command = ["sh", "-c", "for c in \"$@\"; do command -v \"$c\" >/dev/null 2>&1 && echo \"$c\"; done; true", "_"].concat(cmds);
        toolsProc.running = true;
    }

    function install(pkg) {
        Bridge.call(["pkgs-install", pkg], () => {});
    }

    // l'accent de la bannière et la palette « rice » suivent le thème
    Connections {
        target: Theme
        function onAccentChanged() {
            if (root.fileReady && (root.bannerColor === "accent" || root.colors === "rice"))
                root.writeAll();
        }
        function onBackgroundChanged() {
            if (root.fileReady && root.colors === "rice")
                root.writeAll();
        }
    }

    FileView {
        path: root.path
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.apply(JSON.parse(text()));
            } catch (e) {
                console.log("[TermCfg] parse error", e);
            }
            root.fileReady = true;
        }
        onLoadFailed: {
            // pas encore de terminal.json : valeurs par défaut
            root.fileReady = true;
            root.writeAll();
        }
    }

    Process { id: saveProc }
    Process { id: writeProc }
    Process {
        id: toolsProc
        property string buf: ""
        stdout: SplitParser {
            onRead: line => toolsProc.buf += line + "\n"
        }
        onExited: {
            const t = {};
            toolsProc.buf.split("\n").forEach(l => {
                if (l.length)
                    t[l] = true;
            });
            root.tools = t;
        }
    }

    Component.onCompleted: refreshTools()
}
