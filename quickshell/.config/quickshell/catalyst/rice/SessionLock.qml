pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property bool locked: false

    onLockedChanged: if (locked) {
        PanelService.hide();
    }

    Process {
        id: probe
        running: false
        command: ["sh", "-c", "pidof hyprlock swaylock waylock >/dev/null 2>&1 && echo locked || echo free"]
        stdout: SplitParser {
            onRead: data => {
                const want = data === "locked";
                if (root.locked !== want)
                    root.locked = want;
            }
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: if (!probe.running)
            probe.running = true;
    }

    Component.onCompleted: probe.running = true
}
