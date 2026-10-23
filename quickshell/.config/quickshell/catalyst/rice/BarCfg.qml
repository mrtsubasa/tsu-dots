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
        profile: true
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

    function setOpacity(v) {
        opacity = v;
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
