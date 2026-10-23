pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Métriques système sans processus : /proc lu via FileView, horloge via
// SystemClock. Seul `df` tourne, une fois par minute.
Singleton {
    id: root

    property real cpu: 0
    property real ram: 0
    property string ramText: ""
    property real disk: 0
    property string diskText: ""
    property string uptime: ""
    property string wallpaper: ""
    // température CPU (°C) — capteur k10temp / coretemp / zenpower trouvé au démarrage
    property real temp: 0
    property string tempPath: ""
    readonly property bool hasTemp: tempPath.length > 0

    // nombre de consommateurs qui veulent un rafraîchissement rapide (1 s)
    // — sinon 3 s : la barre n'affiche les métriques qu'au survol / alerte
    property int fastUsers: 0
    readonly property int interval: fastUsers > 0 ? 1000 : 3000

    property var _prevCpu: null

    readonly property string clock: {
        const d = clk.date;
        if (Identity.clock12)
            return Qt.formatTime(d, Identity.clockSec ? "h:mm:ss AP" : "h:mm AP");
        return Qt.formatTime(d, Identity.clockSec ? "HH:mm:ss" : "HH:mm");
    }
    readonly property string date: {
        const s = Qt.locale().toString(clk.date, "dddd dd/MM/yyyy");
        return s.charAt(0).toUpperCase() + s.slice(1);
    }
    readonly property date now: clk.date

    // compat : l'ancien service se rafraîchissait à la demande
    function refresh() {
        stat.reload();
        mem.reload();
        up.reload();
        if (hasTemp)
            tempFile.reload();
    }

    function _cpu(text) {
        const line = text.split("\n")[0].trim().split(/\s+/);
        const v = line.slice(1).map(Number);
        const idle = v[3] + (v[4] || 0);
        let total = 0;
        for (let i = 0; i < v.length; i++)
            total += v[i];
        const p = _prevCpu;
        _prevCpu = { t: total, i: idle };
        if (p && total > p.t)
            cpu = Math.max(0, Math.min(1, 1 - (idle - p.i) / (total - p.t)));
    }

    function _mem(text) {
        const kv = {};
        const lines = text.split("\n");
        for (let i = 0; i < lines.length; i++) {
            const m = lines[i].match(/^(\w+):\s+(\d+)/);
            if (m)
                kv[m[1]] = Number(m[2]);
        }
        const total = kv.MemTotal || 0;
        const used = total - (kv.MemAvailable || 0);
        if (total > 0) {
            ram = used / total;
            ramText = (used / 1048576).toFixed(1) + "/" + (total / 1048576).toFixed(1) + " GiB";
        }
    }

    function _uptime(text) {
        const secs = Number(text.split(" ")[0]) || 0;
        const h = Math.floor(secs / 3600);
        const m = Math.floor((secs % 3600) / 60);
        uptime = h + "h" + (m < 10 ? "0" : "") + m + "min";
    }

    SystemClock {
        id: clk
        precision: Identity.clockSec ? SystemClock.Seconds : SystemClock.Minutes
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: root._cpu(text())
    }

    FileView {
        id: mem
        path: "/proc/meminfo"
        onLoaded: root._mem(text())
    }

    FileView {
        id: up
        path: "/proc/uptime"
        onLoaded: root._uptime(text())
    }

    FileView {
        path: Quickshell.env("HOME") + "/.cache/matugen/current-wallpaper"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.wallpaper = text().trim()
    }

    FileView {
        id: tempFile
        path: root.tempPath
        onLoaded: root.temp = (Number(text().trim()) || 0) / 1000
    }

    Process {
        running: true
        command: ["sh", "-c", "for h in /sys/class/hwmon/hwmon*; do case \"$(cat $h/name)\" in k10temp|coretemp|zenpower|cpu_thermal) echo $h/temp1_input; exit;; esac; done"]
        stdout: SplitParser {
            onRead: data => root.tempPath = data.trim()
        }
    }

    Timer {
        interval: root.interval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: df
        command: ["df", "-B1", "--output=size,avail", "/"]
        property string buf: ""
        stdout: SplitParser {
            onRead: data => df.buf += data + "\n"
        }
        onRunningChanged: if (running) buf = ""
        onExited: {
            const f = df.buf.trim().split("\n").pop().trim().split(/\s+/).map(Number);
            if (f.length === 2 && f[0] > 0) {
                root.disk = 1 - f[1] / f[0];
                root.diskText = Math.round(f[1] / 1073741824) + " Go libres";
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: df.running = true
    }
}
