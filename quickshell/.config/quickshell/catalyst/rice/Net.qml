pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

Singleton {
    id: root

    property bool wifiOn: true
    property bool wifiConnected: false
    property string ssid: ""
    property int signal: 0
    property var networks: []
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool btOn: adapter ? !!adapter.enabled : false
    readonly property string btGlyph: btOn ? "󰂯" : "󰂲"

    readonly property string glyph: {
        if (!wifiOn)
            return "󰖪";
        if (!wifiConnected)
            return "󰤮";
        if (signal >= 75)
            return "󰤨";
        if (signal >= 50)
            return "󰤥";
        if (signal >= 25)
            return "󰤢";
        return "󰤟";
    }

    function toggleWifi() {
        wifiProc.command = ["nmcli", "radio", "wifi", wifiOn ? "off" : "on"];
        wifiProc.running = true;
    }

    function toggleBt() {
        if (adapter)
            adapter.enabled = !adapter.enabled;
    }

    function refresh() {
        infoProc.running = true;
    }

    function listNetworks() {
        listProc.running = true;
    }

    function connectNetwork(ssid) {
        connProc.command = ["nmcli", "dev", "wifi", "connect", String(ssid)];
        connProc.running = true;
    }

    function askConnect(ssid) {
        Quickshell.execDetached(["alacritty", "-e", "nmcli", "--ask", "dev", "wifi", "connect", String(ssid)]);
    }

    function _parseNetLine(line) {
        const parts = [];
        let cur = "", esc = false;
        for (let i = 0; i < line.length; i++) {
            const ch = line[i];
            if (esc) {
                cur += ch;
                esc = false;
            } else if (ch === "\\") {
                esc = true;
            } else if (ch === ":") {
                parts.push(cur);
                cur = "";
            } else {
                cur += ch;
            }
        }
        parts.push(cur);
        return parts;
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: infoProc
        command: ["bash", "-c", "nmcli -t -f WIFI g; nmcli -t -f IN-USE,SIGNAL,SSID dev wifi | awk -F: '$1==\"yes\"{print $2 \":\" $3; exit}'; nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID dev wifi list"]
        property string buf: ""
        stdout: SplitParser {
            onRead: data => infoProc.buf += data + "\n"
        }
        onRunningChanged: if (running)
            buf = ""
        onExited: {
            const lines = buf.trim().split("\n");
            root.wifiOn = (lines[0] || "").toLowerCase().indexOf("enabled") >= 0 || lines[0] === "enabled";
            const active = (lines[1] || "").trim();
            if (active.indexOf(":") >= 0) {
                const p = active.split(":");
                root.signal = parseInt(p[0]) || 0;
                root.ssid = (p[1] || "").trim();
            } else {
                root.signal = 0;
                root.ssid = "";
            }
            root.wifiConnected = root.ssid.length > 0;

            const seen = {};
            const nets = [];
            for (let i = 2; i < lines.length; i++) {
                const raw = (lines[i] || "").trim();
                if (!raw || raw.indexOf(":") < 0)
                    continue;
                const parts = root._parseNetLine(raw);
                if (parts.length < 4)
                    continue;
                const inUse = parts[0] === "yes" || parts[0] === "*";
                const sig = parseInt(parts[1]) || 0;
                const sec = (parts[2] || "").trim();
                const name = parts[3] || "";
                if (!name.length)
                    continue;
                const key = name + "·" + sec;
                if (seen[key] !== undefined) {
                    if (inUse || sig > nets[seen[key]].signal) {
                        nets[seen[key]] = { ssid: name, signal: sig, security: sec, inUse: inUse || nets[seen[key]].inUse };
                    }
                    continue;
                }
                seen[key] = nets.length;
                nets.push({ ssid: name, signal: sig, security: sec, inUse: inUse });
            }
            nets.sort((a, b) => (b.inUse - a.inUse) || (b.signal - a.signal));
            root.networks = nets;
        }
    }

    Process {
        id: listProc
        command: ["nmcli", "dev", "wifi", "list", "if", "active"]
        onExited: root.refresh()
    }

    Process {
        id: connProc
        onExited: {
            root.refresh();
            root.listNetworks();
        }
    }

    Process {
        id: wifiProc
        onExited: root.refresh()
    }
}
