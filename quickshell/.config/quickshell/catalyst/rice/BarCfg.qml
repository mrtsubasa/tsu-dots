pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string path: Quickshell.env("HOME") + "/.config/quickshell/catalyst/bar.json"
    property string output: "all"
    property int height: 0
    property real opacity: 0
    // arrondi des coins et marge au bord de l'écran (-1 = valeur du thème)
    property int radius: -1
    property int edge: -1
    // style de barre imposé ("" = celui du thème) : floating | islands | attached
    property string style: ""
    // métriques système dans la barre : auto (seulement en alerte) | always | off
    property string metrics: "auto"
    // style des workspaces : numbers | dots | kanji | roman | icons
    property string wsStyle: "numbers"
    readonly property var wsStyles: ["numbers", "dots", "kanji", "roman", "icons"]
    // ordre des éléments de droite (réordonnable depuis le Studio)
    property var rightOrder: ["media", "metrics", "tray", "status", "notif", "power"]
    readonly property var rightDefault: ["media", "metrics", "tray", "status", "notif", "power"]
    property var modules: ({
        menu: true,
        home: true,
        workspaces: true,
        window: true,
        clock: true,
        cpu: true,
        memory: true,
        gpu: true,
        temp: true,
        disk: true,
        media: true,
        ai: true,
        vm: true,
        scripts: true,
        chat: true,
        bots: true,
        ops: true,
        wall: true,
        clip: true,
        binds: true,
        pkgs: true,
        network: true,
        vpn: true,
        target: true,
        pulse: true,
        tray: true,
        notif: true,
        power: true,
        term: true,
        profile: true,
        mark: true,
        arsenal: true,
        sono: true,
        metrics: true,
        status: true,
        tools: false
    })

    function on(id) {
        return modules[id] !== false;
    }

    function toggle(id) {
        const next = {};
        const src = modules;
        for (const k in src)
            next[k] = src[k];
        next[id] = !on(id);
        modules = next;
        save();
    }

    function setOutput(id) {
        output = id || "all";
        save();
    }

    function setHeight(n) {
        height = n;
        save();
    }

    function setStyle(v) {
        style = v || "";
        save();
    }

    function setWsStyle(v) {
        wsStyle = wsStyles.indexOf(v) >= 0 ? v : "numbers";
        save();
    }

    function setMetrics(v) {
        metrics = v;
        save();
    }

    function setRightOrder(list) {
        rightOrder = list;
        save();
    }

    function move(id, delta) {
        const list = rightOrder.slice();
        const i = list.indexOf(id);
        const j = i + delta;
        if (i < 0 || j < 0 || j >= list.length)
            return;
        list.splice(i, 1);
        list.splice(j, 0, id);
        setRightOrder(list);
    }

    function setOpacity(v) {
        opacity = v;
        save();
    }

    function setRadius(v) {
        radius = v;
        save();
    }

    function setEdge(v) {
        edge = v;
        save();
    }

    function onScreen(scr) {
        if (!scr)
            return false;
        if (!output || output === "all")
            return true;
        if (output === "primary")
            return Quickshell.screens.length ? scr.name === Quickshell.screens[0].name : true;
        return scr.name === output;
    }

    function save() {
        const obj = {
            output: output,
            height: height,
            opacity: opacity,
            radius: radius,
            edge: edge,
            style: style,
            metrics: metrics,
            wsStyle: wsStyle,
            rightOrder: rightOrder,
            modules: modules
        };
        writeProc.command = ["bash", "-c", "cat > " + shellEscape(path) + " << 'EOF'\n" + JSON.stringify(obj, null, 2) + "\nEOF"];
        writeProc.running = true;
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
                const o = JSON.parse(text());
                if (o.output)
                    root.output = o.output;
                if (o.height !== undefined)
                    root.height = o.height;
                if (o.opacity !== undefined)
                    root.opacity = o.opacity;
                root.radius = o.radius !== undefined ? o.radius : -1;
                root.edge = o.edge !== undefined ? o.edge : -1;
                if (o.metrics)
                    root.metrics = o.metrics;
                root.style = o.style || "";
                root.wsStyle = root.wsStyles.indexOf(o.wsStyle) >= 0 ? o.wsStyle : "numbers";
                if (Array.isArray(o.rightOrder)) {
                    // garde les éléments connus + ajoute les nouveaux
                    const known = root.rightDefault;
                    const out = o.rightOrder.filter(k => known.indexOf(k) >= 0);
                    for (let i = 0; i < known.length; i++)
                        if (out.indexOf(known[i]) < 0)
                            out.push(known[i]);
                    root.rightOrder = out;
                }
                if (o.modules) {
                    const next = Object.assign({}, root.modules, o.modules);
                    root.modules = next;
                }
            } catch (e) {
            }
        }
    }

    Process { id: writeProc }
}
