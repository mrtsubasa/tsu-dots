pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Terminal (Studio → Terminal) : accueil de zsh (bannière, fastfetch, gadget) et
// apparence d'Alacritty / Kitty / Ghostty. Les réglages vivent dans terminal.json ;
// à chaque changement on régénère ce que lisent `tsu greet` (greet.env) et les
// terminaux (catalyst.toml / catalyst.conf, hors git).
Singleton {
    id: root

    property bool banner: true
    property string bannerColor: "blue"   // blue | accent | rainbow
    property bool fetch: true
    property string extra: "none"         // none | pokemon | fortune | cowsay | bonsai
    property bool shiny: false
    // apparence : 0 / -1 = « défaut » (on ne touche pas à la config du terminal)
    property real fontSize: 0
    property real opacity: 0
    property int padding: -1
    property bool fileReady: false

    // commandes présentes sur le système (rempli par refreshTools)
    property var tools: ({})

    // gadgets d'accueil : commande à tester + paquet qui l'installe
    readonly property var extras: [
        { id: "none", label: "Aucun", cmd: "", pkg: "" },
        { id: "pokemon", label: "Pokémon", cmd: "pokemon-colorscripts", pkg: "pokemon-colorscripts-git" },
        { id: "fortune", label: "Citation", cmd: "fortune", pkg: "fortune-mod" },
        { id: "cowsay", label: "Vache", cmd: "cowsay", pkg: "cowsay" },
        { id: "bonsai", label: "Bonsaï", cmd: "cbonsai", pkg: "cbonsai" }
    ]
    // tous les paquets « fun » proposés dans la page
    readonly property var funPackages: [
        { cmd: "pokemon-colorscripts", pkg: "pokemon-colorscripts-git", desc: "Pokémon en couleurs (≈ 900, shiny compris)" },
        { cmd: "fortune", pkg: "fortune-mod", desc: "Citations et proverbes aléatoires" },
        { cmd: "cowsay", pkg: "cowsay", desc: "Une vache (ou autre) qui parle" },
        { cmd: "cbonsai", pkg: "cbonsai", desc: "Bonsaï généré en ASCII" },
        { cmd: "lolcat", pkg: "lolcat", desc: "Bannière arc-en-ciel" },
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

    function apply(o) {
        if (!o)
            return;
        if (o.banner !== undefined)
            banner = !!o.banner;
        bannerColor = ["blue", "accent", "rainbow"].indexOf(o.bannerColor) >= 0 ? o.bannerColor : "blue";
        if (o.fetch !== undefined)
            fetch = !!o.fetch;
        extra = extras.some(e => e.id === o.extra) ? o.extra : "none";
        if (o.shiny !== undefined)
            shiny = !!o.shiny;
        const fs = Number(o.fontSize) || 0;
        fontSize = fs > 0 ? Math.max(7, Math.min(24, fs)) : 0;
        const op = Number(o.opacity) || 0;
        opacity = op > 0 ? Math.max(0.3, Math.min(1, op)) : 0;
        const pad = o.padding === undefined ? -1 : Math.round(Number(o.padding));
        padding = pad >= 0 ? Math.min(48, pad) : -1;
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
            fetch: fetch,
            extra: extra,
            shiny: shiny,
            fontSize: fontSize,
            opacity: opacity,
            padding: padding
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

    function writeAll() {
        const greet = "# Généré par Studio → Terminal\n"
            + "GREET_BANNER=" + (banner ? 1 : 0) + "\n"
            + "GREET_BANNER_COLOR=" + bannerColor + "\n"
            + "GREET_ACCENT=\"" + accentRgb() + "\"\n"
            + "GREET_FETCH=" + (fetch ? 1 : 0) + "\n"
            + "GREET_EXTRA=" + extra + "\n"
            + "GREET_SHINY=" + (shiny ? 1 : 0) + "\n";
        // seuls les réglages modifiés dans le Studio sont écrits ; le reste garde la config du terminal
        const head = "# Généré par Studio → Terminal — ne pas éditer\n";
        const size = fontSize > 0 ? fontSize.toFixed(1) : "";
        const op = opacity > 0 ? opacity.toFixed(2) : "";
        const pad = padding >= 0 ? String(padding) : "";
        let win = (op ? "opacity = " + op + "\n" : "") + (pad ? "padding = { x = " + pad + ", y = " + pad + " }\n" : "");
        const alacritty = head + (win ? "[window]\n" + win + "\n" : "") + (size ? "[font]\nsize = " + size + "\n" : "");
        const kitty = head + (op ? "background_opacity " + op + "\n" : "") + (size ? "font_size " + size + "\n" : "") + (pad ? "window_padding_width " + pad + "\n" : "");
        const ghostty = head + (op ? "background-opacity = " + op + "\n" : "") + (size ? "font-size = " + size + "\n" : "") + (pad ? "window-padding-x = " + pad + "\nwindow-padding-y = " + pad + "\n" : "");
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
            cfg + "alacritty", alacritty,
            cfg + "kitty", kitty,
            cfg + "ghostty", ghostty];
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

    // la couleur « accent » de la bannière suit le thème
    Connections {
        target: Theme
        function onAccentChanged() {
            if (root.fileReady && root.bannerColor === "accent")
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
