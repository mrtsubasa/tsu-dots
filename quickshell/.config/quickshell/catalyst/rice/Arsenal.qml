pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/*
 * Arsenal — catalogue des outils de sécurité installés (scripts/arsenal.py).
 * Charge ~/.cache/catalyst/arsenal.json (reconstruit si la base pacman a
 * changé). Recherche floue par nom + description, filtrage par catégorie,
 * favoris et récents persistés. Rien n'est lancé sans action explicite.
 */
Singleton {
    id: root

    property var categories: []
    property var tools: []
    property int total: 0
    property bool ready: false
    property string catPath: ""

    property string category: ""      // "" = tous
    property string query: ""

    property var favorites: []
    property var recents: []
    readonly property string statePath: Quickshell.env("HOME") + "/.cache/catalyst/arsenal-state.json"
    readonly property string script: Quickshell.env("HOME") + "/.config/quickshell/catalyst/scripts/arsenal.py"

    function esc(s) {
        return String(s).toLowerCase();
    }

    // résultats filtrés + triés (favoris puis pertinence)
    readonly property var results: {
        if (!ready)
            return [];
        const q = query.trim().toLowerCase();
        const cat = category;
        const fav = favorites;
        const out = [];
        for (let i = 0; i < tools.length; i++) {
            const t = tools[i];
            if (cat.length && t.c.indexOf(cat) < 0)
                continue;
            let score = 0;
            if (q.length) {
                const n = t.n.toLowerCase();
                if (n === q)
                    score = 100;
                else if (n.startsWith(q))
                    score = 80;
                else if (n.indexOf(q) >= 0)
                    score = 60;
                else if (t.d && t.d.toLowerCase().indexOf(q) >= 0)
                    score = 30;
                else
                    continue;
            }
            if (fav.indexOf(t.n) >= 0)
                score += 1000;
            out.push({ t: t, score: score });
        }
        out.sort((a, b) => b.score - a.score || a.t.n.localeCompare(b.t.n));
        // sans recherche ni catégorie : limite l'affichage initial
        const lim = (!q.length && !cat.length) ? 400 : 2000;
        return out.slice(0, lim).map(x => x.t);
    }
    readonly property int resultCount: {
        if (!ready)
            return 0;
        const q = query.trim().toLowerCase();
        const cat = category;
        if (!q.length && !cat.length)
            return total;
        let n = 0;
        for (let i = 0; i < tools.length; i++) {
            const t = tools[i];
            if (cat.length && t.c.indexOf(cat) < 0)
                continue;
            if (!q.length || t.n.toLowerCase().indexOf(q) >= 0 || (t.d && t.d.toLowerCase().indexOf(q) >= 0))
                n++;
        }
        return n;
    }

    function isFav(name) {
        return favorites.indexOf(name) >= 0;
    }
    function toggleFav(name) {
        const f = favorites.slice();
        const i = f.indexOf(name);
        if (i >= 0)
            f.splice(i, 1);
        else
            f.unshift(name);
        favorites = f;
        saveState();
    }
    function pushRecent(name) {
        const r = recents.filter(x => x !== name);
        r.unshift(name);
        recents = r.slice(0, 24);
        saveState();
    }

    // ---- lancement (toujours à la demande) ----
    function runInTerminal(bin) {
        pushRecent(bin);
        PanelService.hide();
        Quickshell.execDetached(["alacritty", "--title", bin + " · arsenal", "-e", "bash", "-c",
            "printf '\\033[1;35m%s\\033[0m\\n' \"$1 — Ctrl+C pour arrêter, touche pour fermer\"; \"$1\"; echo; read -n1 -rs", "_", bin]);
    }
    function help(bin) {
        pushRecent(bin);
        PanelService.hide();
        Quickshell.execDetached(["alacritty", "--title", bin + " · aide", "-e", "bash", "-c",
            "\"$1\" --help 2>&1 | less -R || man \"$1\" || { \"$1\" -h 2>&1 | less -R; }; ", "_", bin]);
    }
    function manpage(bin) {
        PanelService.hide();
        Quickshell.execDetached(["alacritty", "--title", "man " + bin, "-e", "man", bin]);
    }
    function launchGui(bin) {
        pushRecent(bin);
        PanelService.hide();
        Quickshell.execDetached(["bash", "-lc", bin]);
    }
    function copyName(name) {
        Quickshell.execDetached(["bash", "-c", "printf '%s' \"$1\" | wl-copy", "_", name]);
    }

    // détails d'un outil (binaires, version, url) — à la demande
    property var detail: null
    property string detailFor: ""
    function loadDetail(name) {
        if (detailFor === name && detail)
            return;
        detailFor = name;
        detail = null;
        detailProc.command = ["python3", script, "whatis", name];
        detailProc.buf = "";
        detailProc.running = true;
    }
    Process {
        id: detailProc
        property string buf: ""
        stdout: SplitParser { onRead: data => detailProc.buf += data }
        onExited: {
            try {
                root.detail = JSON.parse(detailProc.buf);
            } catch (e) {
                root.detail = null;
            }
        }
    }

    function refresh() {
        builder.running = true;
    }
    function saveState() {
        writer.command = ["bash", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"",
            "_", statePath, JSON.stringify({ favorites: favorites, recents: recents })];
        writer.running = true;
    }

    Process { id: writer }

    // build : met à jour le cache si besoin, puis on (re)lit le JSON
    Process {
        id: builder
        command: ["python3", root.script, "path"]
        stdout: SplitParser { onRead: data => { if (data.trim().length) root.catPath = data.trim(); } }
        onExited: catFile.reload()
    }

    FileView {
        id: catFile
        path: root.catPath
        onLoaded: {
            try {
                const d = JSON.parse(text());
                root.categories = d.categories || [];
                root.tools = d.tools || [];
                root.total = d.total || 0;
                root.ready = true;
            } catch (e) {
                console.log("[Arsenal] parse", e);
            }
        }
    }

    FileView {
        path: root.statePath
        onLoaded: {
            try {
                const d = JSON.parse(text());
                root.favorites = d.favorites || [];
                root.recents = d.recents || [];
            } catch (e) {
            }
        }
    }

    Component.onCompleted: refresh()
}
