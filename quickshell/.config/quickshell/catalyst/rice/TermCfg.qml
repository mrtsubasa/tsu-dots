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
    property string colors: "terminal"    // terminal | rice | preset | custom
    property string colorPreset: "catppuccin-mocha"
    // palette perso : { bg, fg, cursor, selection, ansi: [16] }
    property var palette: null

    // ---- fastfetch ----
    property string fetchStyle: "box"     // box | sections | minimal | classic (config.jsonc de l'utilisateur)
    property string fetchColor: "accent"  // accent (thème du rice) | terminal (couleurs ANSI)
    property var fetchModules: ({})       // id → bool, complété par les défauts de fetchDefs

    // préréglages de palettes (.data/themes/*.json + intégrés), rempli au démarrage
    property var presets: ({})

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

    // infos fastfetch proposées : groupe (pour le style sections), icône Nerd Font, module
    readonly property var fetchDefs: [
        { id: "os", label: "distro", group: "système", icon: "󰣇", on: true, mod: { type: "os", format: "{pretty-name}" } },
        { id: "kernel", label: "noyau", group: "système", icon: "", on: true, mod: { type: "kernel", format: "{release}" } },
        { id: "wm", label: "wm", group: "système", icon: "", on: true, mod: { type: "wm", format: "{pretty-name}" } },
        { id: "terminal", label: "term", group: "système", icon: "", on: true, mod: { type: "terminal", format: "{pretty-name}" } },
        { id: "shell", label: "shell", group: "système", icon: "", on: true, mod: { type: "shell", format: "{pretty-name}" } },
        { id: "packages", label: "paquets", group: "système", icon: "󰏖", on: true, mod: { type: "packages", format: "{pacman} pacman · {flatpak-all} flatpak" } },
        { id: "uptime", label: "uptime", group: "système", icon: "󰅐", on: true, mod: { type: "uptime", format: "{days}j {hours}h {minutes}min" } },
        { id: "osage", label: "âge", group: "système", icon: "󱦟", on: true, mod: { type: "command", shell: "/bin/sh", text: "echo $(( ($(date +%s) - $(stat -c %W /)) / 86400 )) jours" } },
        { id: "cpu", label: "cpu", group: "matériel", icon: "󰻠", on: true, mod: { type: "cpu", format: "{name}" } },
        { id: "gpu", label: "gpu", group: "matériel", icon: "󰍛", on: true, mod: { type: "gpu", format: "{name}" } },
        { id: "memory", label: "mémoire", group: "matériel", icon: "", on: true, mod: { type: "memory" } },
        { id: "disk", label: "disque", group: "matériel", icon: "󰋊", on: true, mod: { type: "disk", folders: "/", format: "{size-used} / {size-total} ({size-percentage})" } },
        { id: "display", label: "écran", group: "matériel", icon: "󰍹", on: false, mod: { type: "display", format: "{width}x{height} @ {refresh-rate} Hz" } },
        { id: "battery", label: "batterie", group: "matériel", icon: "󰁹", on: false, mod: { type: "battery" } },
        { id: "media", label: "musique", group: "extras", icon: "󰎆", on: false, mod: { type: "media" } },
        { id: "localip", label: "ip locale", group: "extras", icon: "󰩟", on: false, mod: { type: "localip" } },
        { id: "colors", label: "couleurs", group: "", icon: "", on: true, mod: null }
    ]
    readonly property var ansiNames: ["noir", "rouge", "vert", "jaune", "bleu", "magenta", "cyan", "blanc"]

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
        colors = oneOf(o.colors, ["terminal", "rice", "preset", "custom"], "terminal");
        colorPreset = String(o.colorPreset || "catppuccin-mocha");
        palette = validPalette(o.palette) ? o.palette : null;
        fetchStyle = oneOf(o.fetchStyle, ["box", "sections", "minimal", "classic"], "box");
        fetchColor = oneOf(o.fetchColor, ["accent", "terminal"], "accent");
        fetchModules = (o.fetchModules && typeof o.fetchModules === "object") ? o.fetchModules : ({});
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
            colors: colors,
            colorPreset: colorPreset,
            palette: palette,
            fetchStyle: fetchStyle,
            fetchColor: fetchColor,
            fetchModules: fetchModules
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

    function validPalette(p) {
        const hx = v => typeof v === "string" && /^#[0-9a-fA-F]{6}$/.test(v);
        return !!p && hx(p.bg) && hx(p.fg) && hx(p.cursor) && hx(p.selection) && Array.isArray(p.ansi) && p.ansi.length === 16 && p.ansi.every(hx);
    }

    // palette effectivement appliquée aux terminaux (null = celle de chaque terminal)
    function activePalette() {
        if (colors === "rice")
            return ricePalette();
        if (colors === "preset")
            return presets[colorPreset] || null;
        if (colors === "custom")
            return palette || ricePalette();
        return null;
    }

    // palette éditable : la perso, sinon celle affichée actuellement
    function editablePalette() {
        return palette || activePalette() || presets[colorPreset] || ricePalette();
    }

    function copyPalette(p) {
        return { bg: p.bg, fg: p.fg, cursor: p.cursor, selection: p.selection, ansi: p.ansi.slice() };
    }

    // slot : "bg" | "fg" | "cursor" | "selection" | 0..15
    function setColor(slot, hexValue) {
        const v = String(hexValue).trim().replace(/^#?/, "#").toLowerCase();
        if (!/^#[0-9a-f]{6}$/.test(v))
            return false;
        const p = copyPalette(editablePalette());
        if (typeof slot === "number")
            p.ansi[slot] = v;
        else
            p[slot] = v;
        palette = p;
        colors = "custom";
        save();
        writeAll();
        return true;
    }

    function startCustomFrom(p) {
        palette = copyPalette(p);
        colors = "custom";
        save();
        writeAll();
    }

    function moduleOn(id) {
        const d = fetchDefs.find(f => f.id === id);
        return fetchModules[id] !== undefined ? !!fetchModules[id] : (d ? d.on : false);
    }

    function setModule(id, on) {
        const m = Object.assign({}, fetchModules);
        m[id] = on;
        set("fetchModules", m);
    }

    // config fastfetch générée (styles box / sections / minimal)
    function fetchConfig() {
        const rgb = c => Math.round(c.r * 255) + ";" + Math.round(c.g * 255) + ";" + Math.round(c.b * 255);
        const useTheme = fetchColor === "accent";
        const A = useTheme ? "{#1;38;2;" + rgb(Theme.accent) + "}" : "{#1;34}";
        const A2 = useTheme ? "{#38;2;" + rgb(Theme.electric) + "}" : "{#36}";
        const F = useTheme ? "{#38;2;" + rgb(Theme.mix(Theme.background, Theme.accent, 0.6)) + "}" : "{#34}";
        const K = useTheme ? "{#38;2;" + rgb(Theme.textSub) + "}" : "{#37}";
        const R = "{#}";
        const out = useTheme ? "38;2;" + rgb(Theme.ink) : "default";
        const pad = (t, n) => t + " ".repeat(Math.max(0, n - t.length));
        const on = fetchDefs.filter(d => d.mod && moduleOn(d.id));
        const showColors = moduleOn("colors");
        const mods = [];
        const mod = (d, key) => Object.assign({}, d.mod, { key: key });
        const header = { type: "title", format: A + "{user-name}" + R + K + "@" + R + A2 + "{host-name}" + R };

        if (fetchStyle === "box") {
            const w = 12;
            mods.push(Object.assign({}, header, { key: F + "╭" + "─".repeat(w) + "╮" + R }));
            on.forEach(d => mods.push(mod(d, F + "│ " + R + A + d.icon + R + " " + K + pad(d.label, 8) + R + F + " │" + R)));
            if (showColors) {
                mods.push({ type: "custom", key: F + "├" + "─".repeat(w) + "┤" + R, format: "" });
                mods.push({ type: "colors", key: F + "│ " + R + A + "" + R + " " + K + pad("couleurs", 8) + R + F + " │" + R, symbol: "circle" });
            }
            mods.push({ type: "custom", key: F + "╰" + "─".repeat(w) + "╯" + R, format: "" });
        } else if (fetchStyle === "sections") {
            mods.push(Object.assign({}, header, { key: " " }));
            let group = "";
            on.forEach(d => {
                if (d.group !== group) {
                    group = d.group;
                    mods.push({ type: "custom", format: F + "── " + R + A + group + R + " " + F + "─".repeat(Math.max(2, 26 - group.length)) + R });
                }
                mods.push(mod(d, "  " + A + d.icon + R + "  " + K + pad(d.label, 9) + R));
            });
            if (showColors) {
                mods.push({ type: "custom", format: F + "─".repeat(31) + R });
                mods.push({ type: "colors", key: " ", symbol: "circle" });
            }
        } else {
            mods.push(Object.assign({}, header, { key: " " }));
            on.forEach(d => mods.push(mod(d, " " + A + d.icon + R)));
            if (showColors)
                mods.push({ type: "colors", key: " ", symbol: "circle" });
        }
        mods.push("break");
        return JSON.stringify({
            "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
            logo: { type: "none", padding: { right: 2 } },
            display: { separator: "  ", color: { keys: "default", output: out } },
            modules: mods
        }, null, 2) + "\n";
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
            + "GREET_COW=" + cow + "\n"
            + "GREET_FETCH_STYLE=" + fetchStyle + "\n";
        const head = "# Généré par Studio → Terminal — ne pas éditer\n";
        const p = activePalette();
        const cfg = home + "/.config/";
        writeProc.command = ["sh", "-c",
            "w() { mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1.tmp\" && mv \"$1.tmp\" \"$1\"; }; "
            + "w \"$1\" \"$2\"; "
            + "[ -d \"$3\" ] && w \"$3/catalyst.toml\" \"$4\"; "
            + "[ -d \"$5\" ] && w \"$5/catalyst.conf\" \"$6\"; "
            + "[ -d \"$7\" ] && w \"$7/catalyst.conf\" \"$8\"; "
            + "w \"$9\" \"${10}\"; "
            // Kitty relit sa config sur SIGUSR1 ; Alacritty surveille ses fichiers ; Ghostty : nouvelles fenêtres
            + "pkill -USR1 -x kitty 2>/dev/null; true",
            "_", home + "/.cache/catalyst/greet.env", greet,
            cfg + "alacritty", head + alacrittyConf(p),
            cfg + "kitty", head + kittyConf(p),
            cfg + "ghostty", head + ghosttyConf(p),
            home + "/.cache/catalyst/fastfetch.jsonc", fetchConfig()];
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
            if (root.fileReady && (root.bannerColor === "accent" || root.colors === "rice" || root.fetchColor === "accent"))
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

    // palettes des thèmes livrés (.data/themes) + Silver Wolf
    function loadPresets() {
        presetProc.buf = "";
        presetProc.running = true;
    }

    Process {
        id: presetProc
        property string buf: ""
        command: ["python3", "-c", "import json,glob,os,sys\nout={}\nfor f in sorted(glob.glob(os.path.expanduser('~/.tsu-dots/.data/themes/*.json'))):\n    try:\n        d=json.load(open(f)); t=d['terminal']\n        out[os.path.basename(f)[:-5]]={'name':d.get('name',os.path.basename(f)[:-5]),'bg':t['background'],'fg':t['foreground'],'cursor':t.get('cursor',t['foreground']),'selection':t.get('selectionBackground',t['background']),'ansi':[t['color%d'%i] for i in range(16)]}\n    except Exception: pass\nprint(json.dumps(out))"]
        stdout: SplitParser {
            onRead: line => presetProc.buf += line
        }
        onExited: {
            let p = {};
            try {
                p = JSON.parse(presetProc.buf);
            } catch (e) {}
            p["silver-wolf"] = { name: "Silver Wolf", bg: "#0a0c16", fg: "#cdd6f9", cursor: "#00e5d8", selection: "#7b5cff", ansi: ["#11131f", "#ff5f8f", "#5cf2c4", "#f7c873", "#00b4d8", "#7b5cff", "#00e5d8", "#cdd6f9", "#3a3f5c", "#ff8fb3", "#8efadb", "#ffe0a3", "#5cc8ff", "#a98bff", "#6ff3ec", "#eaf0ff"] };
            root.presets = p;
            if (root.fileReady && root.colors === "preset")
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

    Component.onCompleted: {
        refreshTools();
        loadPresets();
    }
}
