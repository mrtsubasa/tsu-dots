pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/*
 * Search — moteur du launcher Catalyst.
 *
 *   (vide)    récents + commandes favorites
 *   texte     applications (recherche floue + fréquence d'usage) puis commandes
 *   =expr     calculatrice (Entrée copie le résultat)
 *   >cmd      commande shell dans le terminal
 *   :texte    commandes Catalyst uniquement (panneaux, thèmes, outils)
 *
 * Résultat : { kind, title, subtitle, icon (material) | appId, action() }
 */
Singleton {
    id: root

    property string query: ""
    property int selected: 0
    property var results: []
    readonly property string mode: query.startsWith("=") ? "calc" : (query.startsWith(">") ? "shell" : (query.startsWith(":") ? "cmd" : "app"))

    // fréquence : { appId: { n, last } }
    property var usage: ({})
    readonly property string usagePath: Quickshell.env("HOME") + "/.cache/catalyst/launcher-usage.json"
    readonly property string tools: Quickshell.env("HOME") + "/.config/quickshell/catalyst/scripts/catalyst-tools.sh"

    // ------------------------------------------------------------------
    // Commandes Catalyst
    // ------------------------------------------------------------------
    function panel(name) {
        return () => PanelService.show(name);
    }
    function sh(cmd) {
        return () => {
            PanelService.hide();
            Quickshell.execDetached(["bash", "-c", cmd]);
        };
    }
    function later(cmd) {
        // laisse la surface se fermer avant une capture d'écran
        return () => {
            PanelService.hide();
            Quickshell.execDetached(["bash", "-c", "sleep 0.35; " + cmd]);
        };
    }

    readonly property var commands: {
        const t = root.tools;
        const list = [
            { id: "control", title: "Centre de contrôle", subtitle: "Réseau, son, notifications", icon: "tune", kw: "control settings quick reglages", action: panel("control") },
            { id: "studio", title: "Studio", subtitle: "Personnaliser le bureau, la barre, les thèmes", icon: "palette", kw: "atelier theme customize personnaliser editeur", action: panel("studio") },
            { id: "overview", title: "Vue d'ensemble", subtitle: "Workspaces et fenêtres", icon: "grid_view", kw: "overview expose fenetres", action: panel("overview") },
            { id: "sysmon", title: "Moniteur système", subtitle: "CPU, mémoire, processus", icon: "monitoring", kw: "htop btop cpu ram process", action: panel("sysmon") },
            { id: "clip", title: "Presse-papiers", subtitle: "Historique cliphist", icon: "content_paste", kw: "clipboard cliphist copier", action: panel("clip") },
            { id: "wall", title: "Fonds d'écran", subtitle: "Choisir un fond", icon: "wallpaper", kw: "wallpaper fond image", action: panel("wall") },
            { id: "binds", title: "Raccourcis clavier", subtitle: "Aide-mémoire", icon: "keyboard", kw: "keybinds shortcuts touches", action: panel("binds") },
            { id: "ai", title: "Panneau IA", subtitle: "Assistants", icon: "smart_toy", kw: "ai claude llm", action: panel("ai") },
            { id: "vpn", title: "VPN", subtitle: Vpn.activeVpn ? "Connecté : " + Vpn.activeVpn.label : "Connecter, importer, exporter", icon: "vpn_key", kw: "vpn openvpn wireguard htb thm tryhackme hackthebox ovpn", action: () => { PanelService.controlPage = "vpn"; PanelService.show("control"); } },
            { id: "containers", title: "Conteneurs", subtitle: "Podman / Docker : état, journaux, shell", icon: "deployed_code", kw: "docker podman container conteneur lazydocker", action: panel("containers") },
            { id: "vm", title: "Machines virtuelles", subtitle: "VM", icon: "dns", kw: "vm qemu virt", action: panel("vm") },
            { id: "scripts", title: "Scripts", subtitle: "Lanceur de scripts", icon: "terminal", kw: "scripts", action: panel("scripts") },
            { id: "chat", title: "Chat", subtitle: "Messagerie", icon: "forum", kw: "chat", action: panel("chat") },
            { id: "bots", title: "Bots", subtitle: "Bots Discord", icon: "robot_2", kw: "bots discord oracle", action: panel("bots") },
            { id: "ops", title: "Ops", subtitle: "VPN, cibles", icon: "radar", kw: "ops vpn htb target", action: panel("ops") },
            { id: "pkgs", title: "Paquets", subtitle: "Gestion des paquets", icon: "package_2", kw: "packages pacman aur paquets", action: panel("pkgs") },
            { id: "archstrike", title: "Ajouter le dépôt ArchStrike", subtitle: "Outils de sécurité en plus de BlackArch (ouvre un terminal, sudo)", icon: "library_add", kw: "archstrike depot repo securite outils ajouter", action: later(Quickshell.env("HOME") + "/.config/quickshell/catalyst/scripts/add-archstrike.sh; echo; read -n1 -rs") },
            { id: "arsenal", title: "Arsenal", subtitle: Arsenal.total + " outils de sécurité : rechercher, lancer", icon: "security", kw: "arsenal outils tools blackarch pentest securite kali parrot", action: panel("arsenal") },
            { id: "blackarch", title: "BlackArch", subtitle: "Outils de sécurité", icon: "security", kw: "blackarch pentest securite", action: panel("blackarch") },
            { id: "omarchy", title: "Omarchy", subtitle: "Menu Omarchy", icon: "apps", kw: "omarchy", action: panel("omarchy") },
            { id: "shot", title: "Capture de zone", subtitle: "PNG + presse-papiers", icon: "screenshot_region", kw: "screenshot capture grim", action: later(t + " shot") },
            { id: "shotfull", title: "Capture de l'écran", subtitle: "Écran complet", icon: "screenshot_monitor", kw: "screenshot capture full", action: later(t + " shot-full") },
            { id: "ocr", title: "Extraire du texte (OCR)", subtitle: "Zone → texte copié, traité localement", icon: "document_scanner", kw: "ocr tesseract texte", action: later(t + " ocr") },
            { id: "pick", title: "Pipette", subtitle: "Couleur → #hex copié", icon: "colorize", kw: "color picker couleur hyprpicker", action: later(t + " pick") },
            { id: "rec", title: Recorder.recording ? "Arrêter l'enregistrement" : "Enregistrer une zone", subtitle: Recorder.recording ? Recorder.elapsedText : "wf-recorder → ~/Videos/Captures", icon: Recorder.recording ? "stop_circle" : "screen_record", kw: "record video enregistrer wf-recorder", action: () => { PanelService.hide(); Recorder.toggle("region"); } },
            { id: "recscreen", title: "Enregistrer l'écran", subtitle: "Écran actif complet", icon: "videocam", kw: "record video screen", action: () => { PanelService.hide(); Recorder.toggle("screen"); } },
            { id: "dnd", title: Notifs.dnd ? "Désactiver Ne pas déranger" : "Ne pas déranger", subtitle: "Notifications", icon: "do_not_disturb_on", kw: "dnd silence notifications", action: () => Notifs.toggleDnd() },
            { id: "caffeine", title: Caffeine.on ? "Autoriser la veille" : "Rester éveillé", subtitle: "Inhibe la mise en veille", icon: "coffee", kw: "caffeine awake veille", action: () => Caffeine.toggle() },
            { id: "truetone", title: Night.trueTone ? "Désactiver True Tone" : "True Tone", subtitle: "Blanc de l'écran adapté à la lumière du moment", icon: "wb_twilight", kw: "true tone ecran couleur blanc temperature", action: () => Night.setTrueTone(!Night.trueTone) },
            { id: "night", title: Night.on ? "Désactiver la lumière nocturne" : "Lumière nocturne", subtitle: "Écran chaud, " + ShellCfg.nightTemp + " K", icon: "nightlight", kw: "night light nocturne bleu", action: () => Night.toggle() },
            { id: "display", title: "Réglages de l'écran", subtitle: "True Tone, lumière nocturne, luminosité", icon: "display_settings", kw: "ecran display luminosite", action: () => { PanelService.controlPage = "display"; PanelService.show("control"); } },
            { id: "screensoff", title: "Éteindre les écrans", subtitle: "Toute entrée les rallume", icon: "desktop_access_disabled", kw: "dpms ecran off eteindre moniteur", action: () => SessionCtl.screensOff() },
            { id: "sched30", title: "Éteindre dans 30 min", subtitle: "Extinction programmée (annulable)", icon: "timer", kw: "shutdown timer minuterie extinction programmee", action: () => { SessionCtl.schedule(30); PanelService.hide(); } },
            { id: "sched60", title: "Éteindre dans 1 h", subtitle: "Extinction programmée (annulable)", icon: "timer", kw: "shutdown timer minuterie extinction programmee heure", action: () => { SessionCtl.schedule(60); PanelService.hide(); } },
            { id: "schedcancel", title: SessionCtl.scheduled ? "Annuler l'extinction programmée" : "Aucune extinction programmée", subtitle: SessionCtl.scheduled ? "Dans " + SessionCtl.remainingText : "", icon: "timer_off", kw: "annuler cancel shutdown extinction", action: () => SessionCtl.cancelSchedule() },
            { id: "updates", title: "Mettre à jour le système", subtitle: SessionCtl.updates > 0 ? SessionCtl.updates + " mises à jour" : "cachyos-update", icon: "system_update_alt", kw: "update mise a jour pacman paru cachyos", action: () => SessionCtl.update(false) },
            { id: "game", title: GameMode.active ? "Quitter le mode jeu" : "Mode jeu", subtitle: "NPD, éveillé, profil Performance", icon: "sports_esports", kw: "game jeu gaming gamemode performance", action: () => GameMode.toggle() },
            { id: "lock", title: "Verrouiller", subtitle: "hyprlock", icon: "lock", kw: "lock verrouiller", action: sh("loginctl lock-session") },
            { id: "power", title: "Session", subtitle: "Veille, redémarrer, éteindre", icon: "power_settings_new", kw: "power shutdown reboot logout eteindre", action: panel("power") },
            { id: "terminal", title: "Terminal", subtitle: "alacritty", icon: "terminal", kw: "terminal shell console", action: sh("alacritty") },
            { id: "miniterm", title: "Mini-terminal", subtitle: "Commande rapide sous la barre", icon: "keyboard_command_key", kw: "term mini commande rapide", action: () => { PanelService.hide(); PanelService.popoverGeom = { output: PanelService.outputName || Niri.focusedOutput, x: 0, w: 48 }; PanelService.popover = "term"; } },
            { id: "restart", title: "Relancer le shell", subtitle: "Recharge Quickshell", icon: "restart_alt", kw: "reload restart quickshell", action: sh(Quickshell.env("HOME") + "/.config/quickshell/catalyst/scripts/catalyst-session.sh restart") }
        ];
        const ps = Themes.presets;
        for (let i = 0; i < ps.length; i++) {
            const p = ps[i];
            list.push({ id: "theme-" + p.id, title: "Thème : " + p.label, subtitle: Themes.active === p.id ? "Thème actif" : (p.description || ""), icon: "format_paint", kw: "theme couleur " + p.id, action: (id => () => Themes.apply(id))(p.id) });
        }
        list.push({ id: "theme-auto", title: "Thème : Material You", subtitle: "Couleurs tirées du fond d'écran", icon: "auto_awesome", kw: "theme matugen auto wallpaper", action: () => Themes.setAuto() });
        return list;
    }

    // ------------------------------------------------------------------
    // Projets (dossiers git fréquents selon zoxide) & hôtes SSH
    // ------------------------------------------------------------------
    property var projects: []
    property var sshHosts: []
    property real _devAt: 0

    function refreshDev() {
        if (Date.now() - _devAt < 300000 || projProc.running)
            return;
        _devAt = Date.now();
        projProc._acc = [];
        projProc.running = true;
    }

    Process {
        id: projProc
        property var _acc: []
        command: ["bash", "-c", "command -v zoxide >/dev/null || exit 0; zoxide query -l 2>/dev/null | head -120 | while read -r d; do [ -d \"$d/.git\" ] && echo \"$d\"; done | head -30"]
        stdout: SplitParser { onRead: data => projProc._acc.push(data.trim()) }
        onExited: root.projects = projProc._acc.filter(x => x.length)
    }

    FileView {
        path: Quickshell.env("HOME") + "/.ssh/config"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const out = [];
            const ls = text().split("\n");
            for (let i = 0; i < ls.length; i++) {
                const m = ls[i].match(/^\s*Host\s+(.+)$/i);
                if (!m)
                    continue;
                const names = m[1].trim().split(/\s+/);
                for (let j = 0; j < names.length; j++)
                    if (names[j].indexOf("*") < 0 && names[j].indexOf("?") < 0 && out.indexOf(names[j]) < 0)
                        out.push(names[j]);
            }
            root.sshHosts = out;
        }
    }

    function projectResult(dir, score) {
        const home = Quickshell.env("HOME");
        const name = dir.split("/").pop();
        return { kind: "project", id: "p:" + dir, title: name, subtitle: dir.replace(home, "~") + "  ·  ouvrir dans " + ShellCfg.editor, icon: "folder_code", score: score,
            action: () => { PanelService.hide(); Quickshell.execDetached(["bash", "-lc", ShellCfg.editor + " \"$1\"", "_", dir]); } };
    }
    function sshResult(host, score) {
        return { kind: "ssh", id: "s:" + host, title: "ssh " + host, subtitle: "Connexion SSH dans un terminal", icon: "terminal", score: score,
            action: () => { PanelService.hide(); Quickshell.execDetached(["alacritty", "-e", "ssh", host]); } };
    }

    // ------------------------------------------------------------------
    // Scoring
    // ------------------------------------------------------------------
    function fuzzy(hay, q) {
        if (!q.length)
            return 0;
        const h = hay.toLowerCase();
        if (h === q) return 120;
        if (h.startsWith(q)) return 100 - Math.min(20, h.length - q.length);
        const wi = h.indexOf(" " + q);
        if (wi >= 0) return 80;
        const ci = h.indexOf(q);
        if (ci >= 0) return 60 - Math.min(20, ci);
        // sous-séquence (initiales : « vsc » → Visual Studio Code)
        let j = 0, gaps = 0, last = -1;
        for (let i = 0; i < h.length && j < q.length; i++) {
            if (h[i] === q[j]) {
                if (last >= 0 && i - last > 1) gaps++;
                last = i;
                j++;
            }
        }
        return j === q.length ? Math.max(5, 40 - gaps * 6) : 0;
    }

    function frecency(id) {
        const u = usage[id];
        if (!u)
            return 0;
        const days = (Date.now() - u.last) / 86400000;
        return Math.min(30, u.n * 3) * (days < 1 ? 1 : (days < 7 ? 0.7 : 0.4));
    }

    function appId(a) {
        return a.id || a.name || "";
    }

    function appResult(a, score) {
        return {
            kind: "app",
            id: appId(a),
            title: a.name || appId(a),
            subtitle: a.genericName || a.comment || "",
            appId: appId(a),
            icon: a.icon || "",
            terminal: !!a.runInTerminal,
            score: score,
            entry: a,
            action: () => root.launch(a)
        };
    }

    function cmdResult(c, score) {
        return { kind: "cmd", id: c.id, title: c.title, subtitle: c.subtitle, icon: c.icon, score: score, action: c.action };
    }

    // calcul : chiffres, opérateurs, parenthèses et fonctions Math listées —
    // tout autre identifiant est refusé avant évaluation
    readonly property var mathFns: ["sqrt", "abs", "round", "floor", "ceil", "sin", "cos", "tan", "log", "log2", "log10", "exp", "min", "max", "pow", "pi"]
    function calc(expr) {
        let e = expr.replace(/,/g, ".").replace(/\^/g, "**").replace(/×/g, "*").replace(/÷/g, "/").trim();
        if (!e.length)
            return null;
        const words = e.match(/[a-z_]+[0-9]*/gi) || [];
        for (let i = 0; i < words.length; i++)
            if (mathFns.indexOf(words[i].toLowerCase()) < 0)
                return null;
        if (!/^[\d\s.+\-*/%()a-z0-9]*$/i.test(e))
            return null;
        e = e.replace(/\b(sqrt|abs|round|floor|ceil|sin|cos|tan|log2|log10|log|exp|min|max|pow)\b/gi, m => "Math." + m.toLowerCase()).replace(/\bpi\b/gi, "Math.PI");
        try {
            const v = (new Function("return (" + e + ");"))();
            if (typeof v !== "number" || !isFinite(v))
                return null;
            return Math.round(v * 1e10) / 1e10;
        } catch (err) {
            return null;
        }
    }

    function rebuild() {
        const raw = query;
        const out = [];
        if (mode === "calc" || (/^[\d\s.,+\-*/^()%]+$/.test(raw) && /[+\-*/^%]/.test(raw) && /\d/.test(raw))) {
            const expr = mode === "calc" ? raw.slice(1) : raw;
            const v = calc(expr.trim());
            if (v !== null)
                out.push({ kind: "calc", id: "calc", title: String(v).replace(".", ","), subtitle: expr.trim() + "  ·  Entrée pour copier", icon: "calculate", score: 999, action: () => { Quickshell.execDetached(["bash", "-c", "printf '%s' \"$1\" | wl-copy", "_", String(v)]); PanelService.hide(); } });
            if (mode === "calc") {
                results = out;
                selected = 0;
                return;
            }
        }
        if (mode === "shell") {
            const cmd = raw.slice(1).trim();
            if (cmd.length)
                out.push({ kind: "shell", id: "shell", title: cmd, subtitle: "Exécuter dans le terminal", icon: "terminal", score: 999, action: () => { PanelService.hide(); Quickshell.execDetached(["alacritty", "--hold", "-e", "bash", "-lc", cmd]); } });
            results = out;
            selected = 0;
            return;
        }

        const q = (mode === "cmd" ? raw.slice(1) : raw).trim().toLowerCase();

        if (!q.length && mode === "app") {
            // récents puis commandes utiles
            const ids = Object.keys(usage).sort((a, b) => usage[b].last - usage[a].last).slice(0, 6);
            for (let i = 0; i < ids.length; i++) {
                const a = DesktopEntries.byId(ids[i]);
                if (a && !a.noDisplay)
                    out.push(appResult(a, 0));
            }
            for (let i = 0; i < Math.min(3, projects.length); i++)
                out.push(projectResult(projects[i], 0));
            const fav = ["control", "studio", "shot", "ocr", "pick", "clip", "sysmon"];
            for (let i = 0; i < commands.length; i++)
                if (fav.indexOf(commands[i].id) >= 0)
                    out.push(cmdResult(commands[i], 0));
            results = out;
            selected = 0;
            return;
        }

        if (mode === "app") {
            const apps = DesktopEntries.applications.values;
            const hits = [];
            for (let i = 0; i < apps.length; i++) {
                const a = apps[i];
                if (a.noDisplay)
                    continue;
                let s = fuzzy(a.name || "", q) * 1.0;
                if (s < 60) {
                    const extra = Math.max(fuzzy(a.genericName || "", q) * 0.6, (a.keywords || []).some(k => String(k).toLowerCase().startsWith(q)) ? 45 : 0, String(a.comment || "").toLowerCase().indexOf(q) >= 0 ? 25 : 0);
                    s = Math.max(s, extra);
                }
                if (s <= 0)
                    continue;
                // pénalise les outils console sans icône (paquets BlackArch…)
                if (a.runInTerminal)
                    s -= 30;
                hits.push(appResult(a, s + frecency(appId(a))));
            }
            hits.sort((x, y) => y.score - x.score || x.title.localeCompare(y.title, "fr"));
            for (let i = 0; i < Math.min(40, hits.length); i++)
                out.push(hits[i]);
        }

        if (mode === "app") {
            for (let i = 0; i < projects.length; i++) {
                const sc = Math.max(fuzzy(projects[i].split("/").pop(), q), fuzzy(projects[i], q) * 0.6);
                if (sc > 0)
                    out.push(projectResult(projects[i], sc - 12));
            }
            const sq = q.replace(/^ssh\s*/, "");
            for (let i = 0; i < sshHosts.length; i++) {
                const sc = q.startsWith("ssh") ? 90 + fuzzy(sshHosts[i], sq) / 10 : fuzzy(sshHosts[i], q);
                if (sc > 0)
                    out.push(sshResult(sshHosts[i], sc - 8));
            }
        }

        const cmds = [];
        for (let i = 0; i < commands.length; i++) {
            const c = commands[i];
            const s = q.length ? Math.max(fuzzy(c.title, q), fuzzy(c.kw, q) * 0.8) : 50;
            if (s > 0)
                cmds.push(cmdResult(c, s - (mode === "cmd" ? 0 : 10)));
        }
        cmds.sort((x, y) => y.score - x.score);
        // en mode app : commandes intercalées selon leur score, 6 max
        const merged = mode === "cmd" ? cmds : out.concat(cmds.slice(0, 6)).sort((x, y) => y.score - x.score);
        results = merged.slice(0, 50);
        selected = 0;
    }

    function setQuery(q) {
        query = q;
        rebuild();
    }

    function reset() {
        refreshDev();
        query = "";
        rebuild();
    }

    function move(d) {
        if (!results.length)
            return;
        selected = (selected + d + results.length) % results.length;
    }

    function activate(i) {
        const r = results[i === undefined ? selected : i];
        if (r && r.action)
            r.action();
    }

    function launch(a) {
        const id = appId(a);
        const u = Object.assign({}, usage);
        u[id] = { n: (u[id] ? u[id].n : 0) + 1, last: Date.now() };
        usage = u;
        saveUsage();
        PanelService.hide();
        a.execute();
    }

    function saveUsage() {
        // garde les 200 plus récents
        const ids = Object.keys(usage).sort((a, b) => usage[b].last - usage[a].last).slice(0, 200);
        const out = {};
        for (let i = 0; i < ids.length; i++)
            out[ids[i]] = usage[ids[i]];
        writer.command = ["bash", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"", "_", usagePath, JSON.stringify(out)];
        writer.running = true;
    }

    Process { id: writer }

    FileView {
        path: root.usagePath
        onLoaded: {
            try {
                root.usage = JSON.parse(text()) || {};
            } catch (e) {
                root.usage = {};
            }
        }
        onLoadFailed: {
            // migration depuis l'historique de l'ancien launcher
            migrate.running = true;
        }
    }

    FileView {
        id: migrate
        property bool running: false
        path: running ? Quickshell.env("HOME") + "/.cache/spell-shell/recent.json" : ""
        onLoaded: {
            try {
                const ids = JSON.parse(text());
                const u = {};
                const now = Date.now();
                for (let i = 0; i < ids.length; i++)
                    u[ids[i]] = { n: Math.max(1, 6 - i), last: now - i * 60000 };
                root.usage = u;
                root.saveUsage();
            } catch (e) {
            }
        }
    }
}
