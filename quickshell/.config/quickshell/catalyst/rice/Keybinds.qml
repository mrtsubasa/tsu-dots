pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/*
 * Raccourcis réels, lus dans la configuration Hyprland (keybinds.conf +
 * local/extra_keybinds.conf), relus à chaque modification du fichier.
 * Sections = blocs « # ==== / # TITRE / # ==== ». Description = commentaire
 * placé juste au-dessus, sinon déduite de la commande. Les combinaisons
 * attribuées plusieurs fois sont signalées (`conflicts`).
 */
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.config/hypr/"
    property string mainText: ""
    property string extraText: ""
    property var vars: ({})

    readonly property var binds: parse(mainText, "conf.d/keybinds.conf").concat(parse(extraText, "local/extra_keybinds.conf"))
    readonly property var conflicts: {
        const seen = {};
        const out = [];
        for (let i = 0; i < binds.length; i++) {
            const k = binds[i].combo;
            if (seen[k] === undefined)
                seen[k] = i;
            else if (out.indexOf(k) < 0)
                out.push(k);
        }
        return out;
    }

    readonly property var panelNames: ({
        launcher: "Launcher", dashboard: "Centre de contrôle", control: "Centre de contrôle", atelier: "Studio", studio: "Studio",
        ai: "Panneau IA", vm: "Machines virtuelles", scripts: "Scripts", chat: "Chat", bots: "Bots", ops: "Ops (pentest)",
        pkgs: "Paquets", blackarch: "HUD BlackArch", omarchy: "Menu Omarchy", clip: "Presse-papiers", overview: "Vue d'ensemble",
        wall: "Fonds d'écran", binds: "Raccourcis", power: "Session", sysmon: "Moniteur système"
    })

    function prettyKey(k) {
        const map = { Return: "Entrée", Space: "Espace", Comma: ",", Period: ".", Minus: "-", Equal: "=", grave: "²", Print: "Impr", Tab: "Tab",
            Left: "←", Right: "→", Up: "↑", Down: "↓", Escape: "Échap", Delete: "Suppr", BackSpace: "Retour",
            mouse_down: "Molette ↓", mouse_up: "Molette ↑", "mouse:272": "Clic gauche", "mouse:273": "Clic droit" };
        if (map[k])
            return map[k];
        if (k.startsWith("XF86"))
            return k.replace("XF86", "").replace("Audio", "Audio ").replace("MonBrightness", "Luminosité ");
        return k.length === 1 ? k.toUpperCase() : k;
    }
    function prettyMods(m) {
        return m.replace(/\$mainMod/g, "SUPER").split(/[\s_]+/).filter(x => x.length).map(x => {
            const u = x.toUpperCase();
            return u === "SUPER" || u === "WIN" || u === "LOGO" ? "Super" : (u === "CTRL" || u === "CONTROL" ? "Ctrl" : (u === "SHIFT" ? "Maj" : (u === "ALT" ? "Alt" : x)));
        }).join(" + ");
    }

    function describe(disp, args) {
        const a = args.trim();
        let m = a.match(/spell-toggle\.sh\s+(\w+)/) || a.match(/call panels (?:toggle|open|show) (\w+)/);
        if (m)
            return "Ouvrir : " + (panelNames[m[1]] || m[1]);
        if (/call audio mic/.test(a)) return "Couper / rétablir le micro";
        if (/call audio call/.test(a)) return "Mode visio";
        if (/call brightness up/.test(a)) return "Luminosité +";
        if (/call brightness down/.test(a)) return "Luminosité −";
        if (/quick_shot\.sh region/.test(a)) return "Capture de zone";
        if (/quick_shot\.sh full/.test(a)) return "Capture de l'écran";
        if (/hyprlock/.test(a)) return "Verrouiller";
        if (/catalyst-session\.sh restart/.test(a)) return "Relancer le shell";
        if (/set-volume.*\+/.test(a)) return "Volume +";
        if (/set-volume.*-/.test(a)) return "Volume −";
        if (/set-mute.*SINK/.test(a)) return "Couper le son";
        if (/set-mute.*SOURCE/.test(a)) return "Couper le micro";
        if (/playerctl play-pause/.test(a)) return "Lecture / pause";
        if (/playerctl next/.test(a)) return "Piste suivante";
        if (/playerctl previous/.test(a)) return "Piste précédente";
        if (/playerctl stop/.test(a)) return "Arrêter la lecture";
        const d = disp.trim();
        const simple = { killactive: "Fermer la fenêtre", exit: "Quitter Hyprland", togglefloating: "Fenêtre flottante",
            fullscreen: a === "1" ? "Plein écran (garde la barre)" : "Plein écran", pseudo: "Pseudo-tiling", togglesplit: "Basculer la découpe",
            pin: "Épingler la fenêtre", centerwindow: "Centrer la fenêtre", togglegroup: "Grouper les fenêtres" };
        if (simple[d])
            return simple[d];
        if (d === "movefocus") return "Focus " + ({ l: "←", r: "→", u: "↑", d: "↓" }[a] || a);
        if (d === "movewindow") return "Déplacer la fenêtre " + ({ l: "←", r: "→", u: "↑", d: "↓" }[a] || a);
        if (d === "resizeactive") return "Redimensionner (" + a + ")";
        if (d === "workspace") return "Workspace " + a;
        if (d === "movetoworkspace") return "Envoyer vers le workspace " + a;
        if (d === "movetoworkspacesilent") return "Envoyer (sans suivre) vers " + a;
        if (d === "togglespecialworkspace") return "Workspace spécial " + (a || "");
        if (d === "movewindowpixel" || d === "movewindow") return "Déplacer la fenêtre";
        if (d === "exec") {
            const cmd = expand(a).replace(/^.*\//, "").split(/\s+/).slice(0, 3).join(" ");
            return "Lancer " + cmd;
        }
        return d + (a.length ? " " + a : "");
    }

    function expand(s) {
        return s.replace(/\$(\w+)/g, (m0, v) => vars[v] !== undefined ? vars[v] : m0);
    }

    function parse(text, file) {
        const out = [];
        if (!text)
            return out;
        const lines = text.split("\n");
        let section = "Général";
        let lastComment = "";
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (/^#\s*=+\s*$/.test(line) && i + 2 < lines.length && /^#\s*=+\s*$/.test(lines[i + 2].trim())) {
                section = lines[i + 1].replace(/^#\s*/, "").trim();
                i += 2;
                lastComment = "";
                continue;
            }
            if (line.startsWith("#")) {
                lastComment = line.replace(/^#+\s*/, "");
                continue;
            }
            const m = line.match(/^bind([a-z]*)\s*=\s*([^,]*),\s*([^,]+),\s*([^,]+)(?:,\s*(.*))?$/);
            if (!m) {
                if (!line.length)
                    lastComment = "";
                continue;
            }
            const mods = prettyMods(m[2]);
            const key = prettyKey(m[3].trim());
            const args = (m[5] || "").trim();
            // un commentaire « Touche : description » est souvent le meilleur libellé
            const fromComment = lastComment.length && lastComment.length < 90 && !/^niri\s*:/i.test(lastComment) ? lastComment.replace(/^[^:]*:\s*/, "") : "";
            out.push({
                section: section,
                combo: (mods.length ? mods + " + " : "") + key,
                desc: (function () {
                    const d = root.describe(m[4], args);
                    // commande générique : le commentaire de l'auteur est plus parlant
                    return d.startsWith("Lancer ") && fromComment.length ? fromComment : d;
                })(),
                hint: fromComment,
                cmd: expand(m[4].trim() + (args.length ? " " + args : "")),
                file: file,
                line: i + 1
            });
        }
        return out;
    }

    FileView {
        path: root.dir + "conf.d/keybinds.conf"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.mainText = text()
    }
    FileView {
        path: root.dir + "local/extra_keybinds.conf"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.extraText = text()
    }
    FileView {
        path: root.dir + "conf.d/variables.conf"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const v = {};
            const ls = text().split("\n");
            for (let i = 0; i < ls.length; i++) {
                const m = ls[i].match(/^\$(\w+)\s*=\s*(.+?)\s*(#.*)?$/);
                if (m)
                    v[m[1]] = m[2];
            }
            root.vars = v;
        }
    }
}
