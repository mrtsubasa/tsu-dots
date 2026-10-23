pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// GPU NVIDIA : un seul `nvidia-smi -lms` en boucle, uniquement tant qu'un
// consommateur (moniteur, widget, barre en mode « toujours ») l'affiche.
Singleton {
    id: root

    property int users: 0
    property bool available: true
    property string name: ""
    property real util: 0          // 0..1
    property real memUsed: 0       // Mio
    property real memTotal: 0
    property real temp: 0          // °C
    property real power: 0         // W
    readonly property real mem: memTotal > 0 ? memUsed / memTotal : 0
    readonly property string memText: (memUsed / 1024).toFixed(1) + "/" + (memTotal / 1024).toFixed(0) + " Gio"

    Process {
        id: smi
        running: root.users > 0 && root.available
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw,name", "--format=csv,noheader,nounits", "-lms", "1500"]
        stdout: SplitParser {
            onRead: data => {
                const f = data.split(",").map(x => x.trim());
                if (f.length < 5)
                    return;
                root.util = (Number(f[0]) || 0) / 100;
                root.memUsed = Number(f[1]) || 0;
                root.memTotal = Number(f[2]) || 0;
                root.temp = Number(f[3]) || 0;
                root.power = Number(f[4]) || 0;
                root.name = f.slice(5).join(",").replace("NVIDIA GeForce ", "");
            }
        }
        onExited: code => {
            if (code === 127 || code === 9)
                root.available = false;
        }
    }
}
