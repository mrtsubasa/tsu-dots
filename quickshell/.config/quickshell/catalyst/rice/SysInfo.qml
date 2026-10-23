pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string clock: "00:00"
    property string date: ""
    property string uptime: ""
    property real cpu: 0
    property real ram: 0
    property string ramText: ""
    property real disk: 0
    property string diskText: ""
    property string wallpaper: ""
    property string mediaStatus: "Stopped"
    property string mediaArtist: ""
    property string mediaTitle: ""
    readonly property bool mediaPlaying: mediaStatus === "Playing"

    function refresh() {
        Bridge.call(["sysinfo"], function (r) {
            if (!r || r.ok === false)
                return;
            clock = r.clock || clock;
            date = r.date || date;
            uptime = r.uptime || uptime;
            cpu = r.cpu ?? cpu;
            ram = r.ram ?? ram;
            ramText = r.ramText || ramText;
            disk = r.disk ?? disk;
            diskText = r.diskText || diskText;
            wallpaper = r.wallpaper || wallpaper;
        });
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.refresh();
            mediaProc.running = true;
        }
    }

    Process {
        id: mediaProc
        command: ["playerctl", "metadata", "--format", "{{status}}\t{{artist}}\t{{title}}"]
        property string buf: ""
        stdout: SplitParser {
            onRead: data => mediaProc.buf += data
        }
        onRunningChanged: if (running) buf = ""
        onExited: {
            const p = buf.split("\t");
            root.mediaStatus = (p[0] || "Stopped").trim();
            root.mediaArtist = (p[1] || "").trim();
            root.mediaTitle = (p[2] || "").trim();
        }
    }
}
