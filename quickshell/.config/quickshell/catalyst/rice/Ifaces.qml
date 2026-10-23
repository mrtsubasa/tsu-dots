pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/*
 * Interfaces réseau, adresses IP, débit, cible (pentest).
 *  - `ip -j addr` toutes les 10 s (2 s quand un panneau réseau est ouvert) :
 *    couvre aussi les tunnels non gérés par NetworkManager (openvpn → tun0).
 *  - débit : /proc/net/dev (lecture fichier, aucun processus), 1 s quand affiché.
 *  - cible : ~/.config/waybar/target.txt (partagé avec le panneau Ops).
 */
Singleton {
    id: root

    property var list: []          // [{ name, kind, label, ipv4, ipv6, up }]
    property int fastUsers: 0
    property string target: ""
    readonly property string targetPath: Quickshell.env("HOME") + "/.config/waybar/target.txt"

    // débit (octets/s) de l'interface principale + total
    property real rxRate: 0
    property real txRate: 0
    property var _prev: null

    readonly property var vpn: list.find(i => i.kind === "vpn" && i.ipv4.length) || null
    readonly property var mesh: list.filter(i => i.kind === "mesh" && i.ipv4.length)
    readonly property var primary: list.find(i => i.kind === "lan" && i.ipv4.length) || null
    readonly property string lhost: vpn ? vpn.ipv4[0] : (primary ? primary.ipv4[0] : "")

    function kindOf(name, type) {
        if (/^(tun|tap|wg|ppp|proton|nordlynx|mullvad|vpn)/.test(name)) return "vpn";
        if (/^(tailscale|wt|zt|nebula|netbird)/.test(name)) return "mesh";
        if (/^(docker|br-|veth|virbr|vnet|podman|cni|lxc)/.test(name)) return "virt";
        if (name === "lo") return "lo";
        return "lan";
    }
    function labelOf(name, kind) {
        if (kind === "vpn") return "VPN · " + name;
        if (name.startsWith("tailscale")) return "Tailscale";
        if (name.startsWith("wt")) return "NetBird";
        if (name.startsWith("zt")) return "ZeroTier";
        if (name.startsWith("docker")) return "Docker";
        if (name.startsWith("br-")) return "Docker (réseau " + name.slice(3, 9) + ")";
        if (name.startsWith("virbr")) return "libvirt";
        if (name.startsWith("wl")) return "Wi-Fi · " + name;
        if (name.startsWith("en") || name.startsWith("eth")) return "Ethernet · " + name;
        return name;
    }

    function human(bps) {
        if (bps >= 1048576) return (bps / 1048576).toFixed(1) + " Mo/s";
        if (bps >= 1024) return (bps / 1024).toFixed(0) + " ko/s";
        return Math.round(bps) + " o/s";
    }

    function copy(text) {
        if (!text)
            return;
        Quickshell.execDetached(["bash", "-c", "printf '%s' \"$1\" | wl-copy && notify-send -a \"$(cat ~/.cache/catalyst/brand 2>/dev/null || echo catalyst)\" -i edit-copy 'Copié' \"$1\"", "_", text]);
    }

    function setTarget(v) {
        const t = String(v || "").trim();
        target = t;
        writer.command = ["bash", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s\\n' \"$2\" > \"$1\"", "_", targetPath, t];
        writer.running = true;
    }

    function refresh() {
        ipProc.running = true;
    }

    Process { id: writer }

    Process {
        id: ipProc
        command: ["ip", "-j", "addr"]
        property string buf: ""
        stdout: SplitParser { onRead: data => ipProc.buf += data }
        onRunningChanged: if (running) buf = ""
        onExited: {
            try {
                const arr = JSON.parse(ipProc.buf);
                const out = [];
                for (let i = 0; i < arr.length; i++) {
                    const it = arr[i];
                    const kind = root.kindOf(it.ifname, it.link_type);
                    if (kind === "lo")
                        continue;
                    const a = it.addr_info || [];
                    out.push({
                        name: it.ifname,
                        kind: kind,
                        label: root.labelOf(it.ifname, kind),
                        ipv4: a.filter(x => x.family === "inet").map(x => x.local),
                        ipv6: a.filter(x => x.family === "inet6" && x.scope === "global").map(x => x.local),
                        up: (it.flags || []).indexOf("UP") >= 0
                    });
                }
                const order = { vpn: 0, lan: 1, mesh: 2, virt: 3 };
                out.sort((x, y) => order[x.kind] - order[y.kind]);
                root.list = out;
            } catch (e) {
            }
        }
    }

    Timer {
        interval: root.fastUsers > 0 ? 2000 : 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    FileView {
        id: netdev
        path: "/proc/net/dev"
        onLoaded: {
            const name = root.primary ? root.primary.name : "";
            const lines = text().split("\n");
            for (let i = 2; i < lines.length; i++) {
                const m = lines[i].trim().match(/^([^:]+):\s*(.*)$/);
                if (!m || m[1] !== name)
                    continue;
                const f = m[2].split(/\s+/).map(Number);
                const now = Date.now();
                const p = root._prev;
                if (p && p.name === name && now > p.t) {
                    const dt = (now - p.t) / 1000;
                    root.rxRate = Math.max(0, (f[0] - p.rx) / dt);
                    root.txRate = Math.max(0, (f[8] - p.tx) / dt);
                }
                root._prev = { name: name, t: now, rx: f[0], tx: f[8] };
            }
        }
    }
    Timer {
        interval: 1000
        repeat: true
        running: root.fastUsers > 0
        onTriggered: netdev.reload()
    }

    FileView {
        path: root.targetPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.target = text().split("\n")[0].trim()
        onLoadFailed: root.target = ""
    }
}
