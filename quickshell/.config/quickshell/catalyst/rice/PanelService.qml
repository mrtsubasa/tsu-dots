pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string active: ""
    property string outputName: ""

    // ---- bar-anchored popovers (end-4 style) ----
    property string popover: ""
    property var popoverGeom: null

    function showPopover(id, win, item) {
        const g = { output: "", x: 0, w: 48 };
        if (win && win.outputName !== undefined)
            g.output = win.outputName || "";
        if (item) {
            const p = item.mapToItem(null, 0, 0);
            g.x = p.x;
            g.w = item.width;
        }
        popoverGeom = g;
        active = "";
        popover = id;
    }

    function hidePopover() {
        popover = "";
        popoverGeom = null;
    }

    function togglePopover(id, win, item) {
        if (popover === id)
            hidePopover();
        else
            showPopover(id, win, item);
    }

    function setOutput(name) {
        outputName = name || "";
    }

    function outputOf(src) {
        if (src === undefined || src === null)
            return "";
        if (typeof src === "string")
            return src;
        if (src.outputName)
            return String(src.outputName);
        if (src.screen && src.screen.name)
            return String(src.screen.name);
        if (src.modelData && src.modelData.name)
            return String(src.modelData.name);
        if (src.name)
            return String(src.name);
        return "";
    }

    function pin(src) {
        const n = outputOf(src);
        if (n.length)
            outputName = n;
    }

    function onScreen(scr) {
        if (!scr)
            return false;
        let want = outputName;
        if (!want || !want.length)
            want = Niri.focusedOutput || "";
        if (!want || !want.length)
            return Quickshell.screens.length ? scr.name === Quickshell.screens[0].name : true;
        const screens = Quickshell.screens;
        let known = false;
        for (let i = 0; i < screens.length; i++) {
            if (screens[i].name === want)
                known = true;
        }
        if (!known)
            return scr.name === (Niri.focusedOutput || want);
        return scr.name === want;
    }

    function hide() {
        active = "";
        hidePopover();
    }

    // anciens noms de panneaux → surfaces v3
    readonly property var aliases: ({ dashboard: "control", home: "control", notifications: "control" })

    function resolve(name) {
        return aliases[name] || name;
    }

    // section du centre de contrôle à afficher à l'ouverture (ex. "notifs")
    property string focusSection: ""
    // sous-page demandée pour le centre de contrôle (net, bt, out, in, eq, power)
    property string controlPage: ""

    // ancrage horizontal (coordonnées écran) de la surface ouverte depuis un
    // élément de barre : { x: centre, w: largeur }
    property var anchor: null

    function openAt(name, win, item, section) {
        name = resolve(name);
        const n = outputOf(win);
        if (active === name && (!n.length || n === outputName)) {
            hide();
            return;
        }
        if (item) {
            const p = item.mapToItem(null, 0, 0);
            anchor = { x: p.x + item.width / 2, w: item.width };
        } else {
            anchor = null;
        }
        focusSection = section || "";
        show(name, win);
    }

    function show(name, src) {
        hidePopover();
        name = resolve(name);
        if (!name || name === "none") {
            hide();
            return;
        }
        pin(src);
        if (!outputName && Niri.focusedOutput)
            outputName = Niri.focusedOutput;
        if (!outputName)
            refreshOutput();
        active = name;
    }

    function toggle(name, src) {
        name = resolve(name);
        const n = outputOf(src);
        if (active === name && (!n.length || n === outputName)) {
            hide();
            return;
        }
        show(name, src);
    }

    function open(name, output) {
        toggle(name, output && output !== "none" ? output : undefined);
    }

    function refreshOutput() {
        if (Niri.hyprland) {
            // Niri.focusedOutput est déjà rafraîchi par le backend hyprctl :
            // évite de lancer une commande niri qui échouerait sur Hyprland.
            if (Niri.focusedOutput && Niri.focusedOutput.length)
                outputName = Niri.focusedOutput;
            return;
        }
        focusProc.running = true;
    }

    Process {
        id: focusProc
        command: ["niri", "msg", "--json", "focused-output"]
        property string buf: ""
        stdout: SplitParser {
            onRead: data => focusProc.buf += data
        }
        onRunningChanged: if (running) buf = ""
        onExited: {
            try {
                const data = JSON.parse(buf);
                if (typeof data === "string")
                    root.outputName = data;
                else if (data && (data.name || data.output))
                    root.outputName = data.name || data.output;
            } catch (e) {
            }
        }
    }

    function openPanel(name) {
        show(name);
    }

    function toggleAtelier() {
        toggle("atelier");
    }
}
