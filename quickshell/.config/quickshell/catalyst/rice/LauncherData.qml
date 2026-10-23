pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string query: ""
    property string category: "all"
    property int page: 1
    property int selected: 0
    readonly property bool searching: query.trim().length > 0
    readonly property int cols: 6
    readonly property int pageSize: searching ? 8 : 24

    readonly property var categories: [
        { id: "all", label: "Tous", glyph: "󰀻" },
        { id: "recent", label: "Récents", glyph: "󰥔" },
        { id: "game", label: "Jeux", glyph: "󰊴" },
        { id: "web", label: "Internet", glyph: "󰖟" },
        { id: "dev", label: "Dev", glyph: "󰅩" },
        { id: "gfx", label: "Graphisme", glyph: "󰏘" },
        { id: "media", label: "Média", glyph: "󰕾" },
        { id: "office", label: "Bureau", glyph: "󰈙" },
        { id: "sys", label: "Système", glyph: "󰒓" },
        { id: "util", label: "Outils", glyph: "󰴉" },
        { id: "edu", label: "Sciences", glyph: "󰑴" },
        { id: "sec", label: "BlackArch", glyph: "󰒃" }
    ]

    readonly property var baCats: [
        { id: "ba-scan", label: "Scanner", key: "X-BlackArch-Scanner", glyph: "󰐷" },
        { id: "ba-web", label: "Webapp", key: "X-BlackArch-Webapp", glyph: "󰖟" },
        { id: "ba-recon", label: "Recon", key: "X-BlackArch-Recon", glyph: "󰭎" },
        { id: "ba-exploit", label: "Exploit", key: "X-BlackArch-Exploitation", glyph: "󰯁" },
        { id: "ba-win", label: "Windows", key: "X-BlackArch-Windows", glyph: "󰖳" },
        { id: "ba-fuzz", label: "Fuzzer", key: "X-BlackArch-Fuzzer", glyph: "󰈸" },
        { id: "ba-net", label: "Net", key: "X-BlackArch-Networking", glyph: "󰛳" },
        { id: "ba-auto", label: "Auto", key: "X-BlackArch-Automation", glyph: "󰚩" },
        { id: "ba-forensic", label: "Forensic", key: "X-BlackArch-Forensic", glyph: "󰌹" },
        { id: "ba-bin", label: "Binary", key: "X-BlackArch-Binary", glyph: "󰡯" },
        { id: "ba-rev", label: "Rev", key: "X-BlackArch-Reversing", glyph: "󰑓" },
        { id: "ba-crack", label: "Crack", key: "X-BlackArch-Cracker", glyph: "󰌆" },
        { id: "ba-sniff", label: "Sniff", key: "X-BlackArch-Sniffer", glyph: "󰛐" },
        { id: "ba-door", label: "Backdoor", key: "X-BlackArch-Backdoor", glyph: "󰌾" },
        { id: "ba-fp", label: "Finger", key: "X-BlackArch-Fingerprint", glyph: "󰈿" },
        { id: "ba-def", label: "Defense", key: "X-BlackArch-Defensive", glyph: "󰒃" },
        { id: "ba-proxy", label: "Proxy", key: "X-BlackArch-Proxy", glyph: "󰒒" },
        { id: "ba-misc", label: "Misc", key: "X-BlackArch-Misc", glyph: "󰀻" }
    ]

    readonly property bool baMode: category === "sec" || category.indexOf("ba-") === 0

    property var recent: []
    property var filtered: []
    property var pageApps: []
    readonly property int resultCount: filtered.length
    readonly property int pageCount: Math.max(1, Math.ceil(resultCount / pageSize))
    readonly property int safePage: Math.max(1, Math.min(page, pageCount))

    function catsOf(app) {
        const raw = app.categories || [];
        const out = [];
        for (let i = 0; i < raw.length; i++) {
            const c = String(raw[i] || "").trim();
            if (c)
                out.push(c);
        }
        return out;
    }

    function hasCat(cats, key) {
        for (let i = 0; i < cats.length; i++) {
            if (cats[i] === key || cats[i].indexOf(key) === 0)
                return true;
        }
        return false;
    }

    function baId(cats) {
        for (let i = 0; i < baCats.length; i++) {
            if (hasCat(cats, baCats[i].key))
                return baCats[i].id;
        }
        return "";
    }

    function catOf(app) {
        const cats = catsOf(app);
        if (hasCat(cats, "X-BlackArch") || hasCat(cats, "Security") || hasCat(cats, "NetworkSecurity"))
            return "sec";
        if (hasCat(cats, "Game"))
            return "game";
        if (hasCat(cats, "Network") || hasCat(cats, "WebBrowser") || hasCat(cats, "Email") || hasCat(cats, "InstantMessaging") || hasCat(cats, "Chat"))
            return "web";
        if (hasCat(cats, "Development") || hasCat(cats, "IDE") || hasCat(cats, "Debugger") || hasCat(cats, "GuiDesigner"))
            return "dev";
        if (hasCat(cats, "Graphics") || hasCat(cats, "Photography") || hasCat(cats, "2DGraphics") || hasCat(cats, "3DGraphics"))
            return "gfx";
        if (hasCat(cats, "AudioVideo") || hasCat(cats, "Audio") || hasCat(cats, "Video") || hasCat(cats, "Player"))
            return "media";
        if (hasCat(cats, "Office") || hasCat(cats, "WordProcessor") || hasCat(cats, "Spreadsheet") || hasCat(cats, "Presentation"))
            return "office";
        if (hasCat(cats, "System") || hasCat(cats, "Settings") || hasCat(cats, "PackageManager") || hasCat(cats, "DesktopSettings"))
            return "sys";
        if (hasCat(cats, "Education") || hasCat(cats, "Science") || hasCat(cats, "Math"))
            return "edu";
        return "util";
    }

    function glyphOf(cat) {
        const all = categories.concat(baCats);
        for (let i = 0; i < all.length; i++) {
            if (all[i].id === cat)
                return all[i].glyph;
        }
        return "󰀻";
    }

    function appId(app) {
        return app.id || app.name;
    }

    function genericIcon(app) {
        const s = String(app.icon || "").toLowerCase();
        return !s || s.indexOf("blackarch") >= 0 || s === "application-x-executable" || s === "application-default-icon";
    }

    function rank(app) {
        if (app.runInTerminal && genericIcon(app))
            return 3;
        if (catOf(app) === "sec" && genericIcon(app))
            return 2;
        if (app.runInTerminal)
            return 1;
        return 0;
    }

    function hay(app) {
        let s = (app.name || "") + " " + (app.comment || "") + " " + (app.genericName || "");
        const kw = app.keywords || [];
        for (let i = 0; i < kw.length; i++)
            s += " " + kw[i];
        const cats = catsOf(app);
        for (let i = 0; i < cats.length; i++)
            s += " " + cats[i];
        return s.toLowerCase();
    }

    function inCategory(app, id) {
        if (id === "all" || id === "recent")
            return true;
        if (id === "sec")
            return catOf(app) === "sec";
        if (id.indexOf("ba-") === 0) {
            const cats = catsOf(app);
            for (let i = 0; i < baCats.length; i++) {
                if (baCats[i].id === id)
                    return hasCat(cats, baCats[i].key);
            }
            return false;
        }
        return catOf(app) === id;
    }

    function rebuild() {
        const apps = DesktopEntries.applications.values;
        const q = query.trim().toLowerCase();
        let list = [];
        if (category === "recent") {
            for (let i = 0; i < recent.length; i++) {
                const rec = recent[i];
                let hit = DesktopEntries.byId(rec);
                if (!hit) {
                    for (let j = 0; j < apps.length; j++) {
                        if (appId(apps[j]) === rec || apps[j].name === rec) {
                            hit = apps[j];
                            break;
                        }
                    }
                }
                if (hit && !hit.noDisplay)
                    list.push(hit);
            }
            if (q)
                list = list.filter(a => hay(a).indexOf(q) >= 0);
        } else {
            for (let i = 0; i < apps.length; i++) {
                const a = apps[i];
                if (a.noDisplay)
                    continue;
                if (!inCategory(a, category))
                    continue;
                if (q && hay(a).indexOf(q) < 0)
                    continue;
                list.push(a);
            }
            list.sort((a, b) => {
                const ra = rank(a);
                const rb = rank(b);
                if (ra !== rb)
                    return ra - rb;
                return (a.name || "").localeCompare(b.name || "", "fr", { sensitivity: "base" });
            });
        }
        filtered = list;
        const p = Math.max(1, Math.min(page, Math.max(1, Math.ceil(list.length / pageSize))));
        const start = (p - 1) * pageSize;
        pageApps = list.slice(start, start + pageSize);
        if (selected >= pageApps.length)
            selected = Math.max(0, pageApps.length - 1);
    }

    function reset() {
        query = "";
        category = "all";
        page = 1;
        selected = 0;
        loadRecent();
        rebuild();
    }

    function setQuery(q) {
        query = q;
        page = 1;
        selected = 0;
        rebuild();
    }

    function setCategory(id) {
        category = id;
        page = 1;
        selected = 0;
        rebuild();
    }

    function prevPage() {
        page = Math.max(1, safePage - 1);
        selected = 0;
        rebuild();
    }

    function nextPage() {
        page = Math.min(pageCount, safePage + 1);
        selected = 0;
        rebuild();
    }

    function moveSel(dx, dy) {
        const n = pageApps.length;
        if (!n)
            return;
        const c = searching ? 1 : cols;
        const delta = dx + dy * c;
        let i = selected + delta;
        if (i < 0) {
            if (safePage > 1) {
                page = safePage - 1;
                rebuild();
                selected = Math.max(0, pageApps.length + i);
            } else {
                selected = 0;
            }
            return;
        }
        if (i >= n) {
            if (safePage < pageCount) {
                const over = i - n;
                page = safePage + 1;
                rebuild();
                selected = Math.min(over, Math.max(0, pageApps.length - 1));
            } else {
                selected = n - 1;
            }
            return;
        }
        selected = i;
    }

    function launch(app) {
        if (!app)
            return;
        try {
            app.execute();
        } catch (e) {
            let cmd = app.execString || "";
            cmd = cmd.replace(/%[uUfFdDnNickvm]/g, "").replace(/\s+/g, " ").trim();
            if (!cmd)
                return;
            if (app.runInTerminal)
                Quickshell.execDetached(["alacritty", "-e", "bash", "-lc", cmd]);
            else
                Quickshell.execDetached(["sh", "-c", cmd]);
        }
        const id = appId(app);
        recent = [id].concat(recent.filter(x => x !== id)).slice(0, 32);
        saveRecent();
        PanelService.hide();
    }

    function launchSelected() {
        if (pageApps.length > 0)
            launch(pageApps[Math.max(0, Math.min(selected, pageApps.length - 1))]);
    }

    function isRunning(app) {
        const id = String(appId(app) || "").toLowerCase();
        const name = String(app.name || "").toLowerCase();
        const wins = Niri.windows;
        for (let i = 0; i < wins.length; i++) {
            const aid = String(wins[i].app_id || "").toLowerCase();
            if (!aid)
                continue;
            if (aid === id || id.indexOf(aid) >= 0 || aid.indexOf(id) >= 0 || aid.indexOf(name) >= 0)
                return true;
        }
        return false;
    }

    function loadRecent() {
        recentFile.reload();
    }

    function saveRecent() {
        Quickshell.execDetached(["bash", "-c", "mkdir -p \"$HOME/.cache/spell-shell\" && cat > \"$HOME/.cache/spell-shell/recent.json\" <<'EOF'\n" + JSON.stringify(recent) + "\nEOF"]);
    }

    FileView {
        id: recentFile
        path: Quickshell.env("HOME") + "/.cache/spell-shell/recent.json"
        onLoaded: {
            try {
                const v = JSON.parse(text());
                if (Array.isArray(v))
                    root.recent = v;
            } catch (e) {
            }
            root.rebuild();
        }
    }

    Component.onCompleted: {
        loadRecent();
        rebuild();
    }
}
