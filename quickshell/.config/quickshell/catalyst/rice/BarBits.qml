pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string vpn: ""
    property string target: ""
    property string gpu: ""
    property real gpuVal: 0
    property string temp: ""
    property real tempVal: 0

    Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            vpnProc.running = true;
            tgtProc.running = true;
            gpuProc.running = true;
            tempProc.running = true;
        }
    }

    Process {
        id: vpnProc
        command: ["bash", Quickshell.env("HOME") + "/.config/waybar/scripts/vpn.sh"]
        property string buf: ""
        stdout: SplitParser { onRead: data => vpnProc.buf += data }
        onRunningChanged: if (running) buf = ""
        onExited: {
            try {
                const o = JSON.parse(buf);
                root.vpn = o.class === "on" ? (o.text || "VPN") : "";
            } catch (e) { root.vpn = ""; }
        }
    }

    Process {
        id: tgtProc
        command: ["bash", Quickshell.env("HOME") + "/.config/waybar/scripts/target.sh"]
        property string buf: ""
        stdout: SplitParser { onRead: data => tgtProc.buf += data }
        onRunningChanged: if (running) buf = ""
        onExited: {
            try {
                const o = JSON.parse(buf);
                root.target = o.class === "set" ? (o.text || "") : "";
            } catch (e) { root.target = ""; }
        }
    }

    Process {
        id: tempProc
        command: ["bash", "-c", "for f in /sys/class/hwmon/hwmon*/temp1_input; do awk '{printf \"%d\", $1/1000}' \"$f\"; exit 0; done"]
        property string buf: ""
        stdout: SplitParser { onRead: data => tempProc.buf += data }
        onRunningChanged: if (running) buf = ""
        onExited: {
            const n = parseInt(buf);
            if (isNaN(n)) {
                root.temp = "";
                root.tempVal = 0;
            } else {
                root.temp = n + "°";
                root.tempVal = Math.min(1, n / 100);
            }
        }
    }
    Process {
        id: gpuProc
        command: ["bash", Quickshell.env("HOME") + "/.config/waybar/scripts/gpu.sh"]
        property string buf: ""
        stdout: SplitParser { onRead: data => gpuProc.buf += data }
        onRunningChanged: if (running) buf = ""
        onExited: {
            try {
                const o = JSON.parse(buf);
                root.gpu = o.text || "";
                const m = String(o.text || "").match(/(\d+)/);
                root.gpuVal = m ? parseInt(m[1]) / 100 : 0;
            } catch (e) {
                root.gpu = "";
                root.gpuVal = 0;
            }
        }
    }
}
