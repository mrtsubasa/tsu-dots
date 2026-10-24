pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/*
 * Conteneurs Podman et Docker (moteurs locaux, droits de l'utilisateur).
 * Interrogés seulement pendant que le panneau est ouvert (toutes les 3 s).
 * Docker sans accès au socket (utilisateur hors du groupe docker) est
 * signalé au lieu d'échouer en silence.
 */
Singleton {
    id: root

    property int users: 0
    property var items: []            // [{ engine, id, name, image, running, status, ports }]
    property bool dockerDenied: false
    property bool hasPodman: true
    property bool hasDocker: true
    property var _podman: []
    property var _docker: []
    readonly property int running: items.filter(c => c.running).length

    function refresh() {
        if (!podProc.running && hasPodman) {
            podProc.buf = "";
            podProc.running = true;
        }
        if (!dockProc.running && hasDocker) {
            dockProc.acc = [];
            dockProc.err = "";
            dockProc.running = true;
        }
    }

    function merge() {
        items = _podman.concat(_docker).sort((a, b) => (b.running - a.running) || a.name.localeCompare(b.name));
    }

    function act(c, verb) {
        Quickshell.execDetached([c.engine, verb, c.id]);
        later.restart();
    }
    function logs(c) {
        PanelService.hide();
        Quickshell.execDetached(["alacritty", "--title", c.name + " · logs", "-e", c.engine, "logs", "-f", "--tail", "200", c.id]);
    }
    function shell(c) {
        PanelService.hide();
        Quickshell.execDetached(["alacritty", "--title", c.name + " · shell", "-e", c.engine, "exec", "-it", c.id, "sh", "-c", "command -v bash >/dev/null && exec bash || exec sh"]);
    }

    Timer {
        id: later
        interval: 900
        onTriggered: root.refresh()
    }
    Timer {
        interval: 3000
        repeat: true
        running: root.users > 0
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: podProc
        property string buf: ""
        command: ["podman", "ps", "-a", "--format", "json"]
        stdout: SplitParser { onRead: data => podProc.buf += data }
        onExited: code => {
            if (code === 127) {
                root.hasPodman = false;
                return;
            }
            try {
                const arr = JSON.parse(podProc.buf || "[]");
                root._podman = arr.map(c => ({
                    engine: "podman",
                    id: c.Id.slice(0, 12),
                    name: (c.Names || [c.Id.slice(0, 12)])[0],
                    image: c.Image || "",
                    running: c.State === "running",
                    status: c.Status || c.State || "",
                    ports: (c.Ports || []).map(p => (p.host_port ? p.host_port + "→" : "") + p.container_port).join(" ")
                }));
            } catch (e) {
                root._podman = [];
            }
            root.merge();
        }
    }

    Process {
        id: dockProc
        property var acc: []
        property string err: ""
        command: ["docker", "ps", "-a", "--format", "{{json .}}"]
        stdout: SplitParser { onRead: data => dockProc.acc.push(data) }
        stderr: SplitParser { onRead: data => dockProc.err += data }
        onExited: code => {
            if (code === 127) {
                root.hasDocker = false;
                return;
            }
            root.dockerDenied = dockProc.err.indexOf("permission denied") >= 0;
            const out = [];
            for (let i = 0; i < dockProc.acc.length; i++) {
                try {
                    const c = JSON.parse(dockProc.acc[i]);
                    out.push({ engine: "docker", id: c.ID, name: c.Names, image: c.Image, running: c.State === "running", status: c.Status, ports: c.Ports || "" });
                } catch (e) {
                }
            }
            root._docker = out;
            root.merge();
        }
    }
}
