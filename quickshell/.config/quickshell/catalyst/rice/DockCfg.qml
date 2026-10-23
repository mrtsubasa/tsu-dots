pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string path: Quickshell.env("HOME") + "/.config/dock/dock.json"
    readonly property string ricePath: Quickshell.env("HOME") + "/.config/waybar/rice.json"

    property bool enabled: true
    property string position: "right"
    property string align: "center"
    property string monitors: "primary"
    property string theme: "apple"
    property int iconSize: 36
    property real zoom: 1.45
    property real magRange: 72
    property int gap: 10
    property int padding: 14
    property int margin: 8
    property real opacity: 0.62
    property bool showPill: true
    property bool showDots: true
    property string showLabels: "hover"
    property bool autohide: false
    property var apps: []

    readonly property bool vertical: position === "left" || position === "right"
    readonly property bool east: position === "right"
    readonly property bool west: position === "left"
    readonly property bool south: position === "bottom"
    readonly property bool north: position === "top"
    readonly property int thickness: padding * 2 + iconSize
    readonly property int hoverExtra: Math.round(iconSize * (Math.max(1, zoom) - 1) + (showLabels === "never" ? 12 : 92))

    function onScreen(scr) {
        if (!enabled || !scr)
            return false;
        if (!monitors || monitors === "all")
            return true;
        if (monitors === "primary")
            return Quickshell.screens.length ? scr.name === Quickshell.screens[0].name : true;
        return scr.name === monitors;
    }

    function pillRadius() {
        const t = theme || "apple";
        if (t === "lain" || t === "minimal")
            return 0;
        if (t === "silverwolf" || t === "initiald")
            return 6;
        if (t === "tsubasa")
            return 18;
        return Math.round(thickness * 0.45);
    }

    function apply(o) {
        if (!o)
            return;
        if (o.enabled !== undefined)
            enabled = !!o.enabled;
        if (o.position)
            position = String(o.position);
        if (o.align)
            align = String(o.align);
        if (o.monitors)
            monitors = String(o.monitors);
        if (o.theme)
            theme = String(o.theme);
        if (o.icon_size)
            iconSize = o.icon_size;
        if (o.max_scale)
            zoom = o.max_scale;
        if (o.mag_range)
            magRange = o.mag_range;
        if (o.gap !== undefined)
            gap = o.gap;
        if (o.padding !== undefined)
            padding = o.padding;
        if (o.margin_bottom !== undefined)
            margin = o.margin_bottom;
        if (o.opacity !== undefined)
            opacity = o.opacity;
        if (o.show_pill !== undefined)
            showPill = !!o.show_pill;
        if (o.show_dots !== undefined)
            showDots = !!o.show_dots;
        if (o.show_labels !== undefined)
            showLabels = String(o.show_labels);
        if (o.autohide !== undefined)
            autohide = !!o.autohide;
        if (Array.isArray(o.apps))
            apps = o.apps;
    }

    function dump() {
        return {
            enabled: enabled,
            align: align,
            apps: apps,
            gap: gap,
            icon_size: iconSize,
            mag_range: magRange,
            margin_bottom: margin,
            max_scale: zoom,
            monitors: monitors,
            opacity: opacity,
            padding: padding,
            position: position,
            show_dots: showDots,
            show_labels: showLabels,
            show_pill: showPill,
            autohide: autohide,
            theme: theme
        };
    }

    function save() {
        writeProc.command = ["bash", "-c", "cat > " + shellEscape(path) + " << 'EOF'\n" + JSON.stringify(dump(), null, 2) + "\nEOF"];
        writeProc.running = true;
    }

    function set(key, value) {
        root[key] = value;
        save();
        if (key === "enabled" || key === "theme")
            saveRice();
    }

    function toggle(key) {
        root[key] = !root[key];
        save();
        if (key === "enabled")
            saveRice();
    }

    function saveRice() {
        const py = "import json,pathlib\np=pathlib.Path.home()/'.config/waybar/rice.json'\nd=json.loads(p.read_text()) if p.is_file() else {}\nd['dock']=" + (enabled ? "True" : "False") + "\nd['dock_style']=" + JSON.stringify(theme) + "\np.write_text(json.dumps(d,indent=2)+'\\n')\n";
        riceProc.command = ["python3", "-c", py];
        riceProc.running = true;
    }

    function shellEscape(str) {
        return "'" + String(str).replace(/'/g, "'\\''") + "'";
    }

    function runningWins(app) {
        const cls = String((app && (app.wmclass || app.id)) || "").toLowerCase();
        if (!cls)
            return [];
        const all = Niri.windows;
        const out = [];
        for (let i = 0; i < all.length; i++) {
            const aid = String(all[i].app_id || "").toLowerCase();
            if (!aid)
                continue;
            if (aid === cls || aid.indexOf(cls) >= 0 || cls.indexOf(aid) >= 0)
                out.push(all[i]);
        }
        return out;
    }

    function launch(app, output) {
        if (!app)
            return;
        const cmd = String(app.exec || "");
        if (cmd.startsWith("spell:")) {
            PanelService.toggle(cmd.slice(6), output || "");
            return;
        }
        const wins = runningWins(app);
        if (wins.length) {
            // plusieurs fenêtres : on fait défiler la suivante à chaque clic
            let k = 0;
            for (let i = 0; i < wins.length; i++)
                if (wins[i].is_focused)
                    k = (i + 1) % wins.length;
            Niri.focusWindow(wins[k].id);
            return;
        }
        if (!cmd) {
            newInstance(app);
            return;
        }
        // execDetached détache vraiment le processus : aucune dépendance au
        // lanceur (Hyprland ou niri) et survit à un redémarrage du shell.
        Quickshell.execDetached(["bash", "-lc", cmd]);
    }

    // applications ouvertes qui ne sont pas épinglées : [{ appId, wins }]
    readonly property var unpinned: {
        const all = Niri.windows;
        const seen = {};
        const out = [];
        for (let i = 0; i < all.length; i++) {
            const aid = String(all[i].app_id || "");
            if (!aid.length || seen[aid.toLowerCase()])
                continue;
            seen[aid.toLowerCase()] = true;
            if (isPinned(aid))
                continue;
            out.push({ id: aid, wmclass: aid, name: "", icon: "", exec: "", transient: true });
        }
        return out;
    }

    function isPinned(appId) {
        const cls = String(appId || "").toLowerCase();
        const src = apps;
        for (let i = 0; i < src.length; i++) {
            const k = String(src[i].wmclass || src[i].id || "").toLowerCase();
            if (k.length && (k === cls || cls.indexOf(k) >= 0 || k.indexOf(cls) >= 0))
                return true;
        }
        return false;
    }

    // épingle une application à partir de sa classe de fenêtre
    function pin(appId) {
        if (!appId || isPinned(appId))
            return;
        const d = DesktopEntries.heuristicLookup(appId);
        const entry = {
            id: d ? d.id : appId,
            desktop: d ? d.id : "",
            name: d ? d.name : appId,
            icon: d ? d.icon : appId,
            exec: d ? "" : appId,
            wmclass: appId
        };
        // avant le premier séparateur (zone des applications)
        const next = apps.slice();
        let at = next.length;
        for (let i = 0; i < next.length; i++)
            if (next[i].type === "separator") {
                at = i;
                break;
            }
        next.splice(at, 0, entry);
        apps = next;
        save();
    }

    function move(index, delta) {
        const next = apps.slice();
        const j = index + delta;
        if (index < 0 || j < 0 || j >= next.length)
            return;
        const it = next.splice(index, 1)[0];
        next.splice(j, 0, it);
        apps = next;
        save();
    }

    function newInstance(app) {
        const d = app.desktop ? DesktopEntries.byId(app.desktop) : DesktopEntries.heuristicLookup(app.wmclass || app.id);
        if (d)
            d.execute();
        else if (app.exec)
            Quickshell.execDetached(["bash", "-lc", app.exec]);
    }

    function closeAll(app) {
        const w = runningWins(app);
        for (let i = 0; i < w.length; i++)
            Niri.closeWindow(w[i].id);
    }

    function unpin(index) {
        const next = [];
        const src = apps;
        for (let i = 0; i < src.length; i++) {
            if (i !== index)
                next.push(src[i]);
        }
        apps = next;
        save();
    }

    FileView {
        path: root.path
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.apply(JSON.parse(text()));
            } catch (e) {
            }
        }
    }

    Process { id: writeProc }
    Process { id: riceProc }
}
