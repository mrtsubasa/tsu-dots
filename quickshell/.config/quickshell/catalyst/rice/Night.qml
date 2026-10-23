pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool on: false

    function refresh() {
        check.running = true;
    }

    function toggle() {
        if (on)
            Quickshell.execDetached(["pkill", "-x", "wlsunset"]);
        else if (Weather.lat && Weather.lon)
            Quickshell.execDetached(["wlsunset", "-l", String(Weather.lat), "-L", String(Weather.lon), "-t", "3800", "-T", "6500"]);
        else
            Quickshell.execDetached(["wlsunset", "-t", "3800", "-T", "6500"]);
        after.restart();
    }

    Component.onCompleted: refresh()

    Timer {
        id: after
        interval: 450
        onTriggered: root.refresh()
    }

    Timer {
        interval: 2500
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: check
        command: ["pgrep", "-x", "wlsunset"]
        onExited: code => root.on = (code === 0)
    }
}
