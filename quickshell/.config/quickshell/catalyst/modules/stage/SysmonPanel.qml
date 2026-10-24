pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.rice
import qs.kit

// Moniteur système compact : jauges CPU / RAM / température / disque et
// processus les plus gourmands. Rafraîchissement 1 s et `ps` uniquement
// pendant que le panneau est ouvert.
Item {
    id: root

    implicitWidth: 360
    implicitHeight: col.implicitHeight + 32

    property var procs: []

    Component.onCompleted: {
        SysInfo.fastUsers++;
        Gpu.users++;
        Ifaces.fastUsers++;
        ps.running = true;
    }
    Component.onDestruction: {
        SysInfo.fastUsers = Math.max(0, SysInfo.fastUsers - 1);
        Gpu.users = Math.max(0, Gpu.users - 1);
        Ifaces.fastUsers = Math.max(0, Ifaces.fastUsers - 1);
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: ps.running = true
    }

    Process {
        id: ps
        command: ["ps", "-eo", "pid,pcpu,rss,comm", "--sort=-pcpu", "--no-headers"]
        property var buf: []
        stdout: SplitParser {
            onRead: data => {
                const f = data.trim().split(/\s+/);
                // exclut la commande de mesure elle-même
                if (ps.buf.length < 5 && f[3] !== "ps")
                    ps.buf.push(f);
            }
        }
        onRunningChanged: if (running) buf = []
        onExited: root.procs = ps.buf.map(p => ({ pid: p[0], cpu: Number(p[1]) || 0, mem: (Number(p[2]) || 0) / 1048576, name: p.slice(3).join(" ") }))
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            Txt { role: "title"; text: "Système"; Layout.fillWidth: true }
            Txt { role: "mono"; text: "up " + SysInfo.uptime; color: Theme.textSub }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            component Gauge: ColumnLayout {
                id: g
                property real value: 0
                property string label: ""
                property string caption: ""
                Layout.fillWidth: true
                spacing: 6
                Ring {
                    Layout.alignment: Qt.AlignHCenter
                    size: 62
                    thickness: 5
                    value: g.value
                    label: g.label
                }
                Txt {
                    Layout.alignment: Qt.AlignHCenter
                    role: "overline"
                    text: g.caption
                }
            }

            Gauge { value: SysInfo.cpu; label: Math.round(SysInfo.cpu * 100) + "%"; caption: "CPU" }
            Gauge { value: SysInfo.ram; label: Math.round(SysInfo.ram * 100) + "%"; caption: "Mémoire" }
            Gauge { visible: SysInfo.hasTemp; value: SysInfo.temp / 100; label: Math.round(SysInfo.temp) + "°"; caption: "Temp." }
            Gauge { value: SysInfo.disk; label: Math.round(SysInfo.disk * 100) + "%"; caption: "Disque" }
        }

        // GPU
        RowLayout {
            Layout.fillWidth: true
            visible: Gpu.available && Gpu.memTotal > 0
            spacing: 0
            Gauge { value: Gpu.util; label: Math.round(Gpu.util * 100) + "%"; caption: "GPU" }
            Gauge { value: Gpu.mem; label: Math.round(Gpu.mem * 100) + "%"; caption: "VRAM" }
            Gauge { value: Gpu.temp / 100; label: Math.round(Gpu.temp) + "°"; caption: "GPU temp." }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Txt { role: "mono"; text: Math.round(Gpu.power) + " W"; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.alignment: Qt.AlignHCenter }
                Txt { role: "overline"; text: "conso"; Layout.alignment: Qt.AlignHCenter }
            }
        }
        Txt {
            Layout.fillWidth: true
            visible: Gpu.available && Gpu.memTotal > 0
            role: "caption"
            text: Gpu.name + " · VRAM " + Gpu.memText
        }

        // réseau
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Icon { name: "swap_vert"; size: 16; color: Theme.textSub }
            Txt { role: "mono"; text: "↓ " + Ifaces.human(Ifaces.rxRate); color: Theme.accent2 }
            Txt { role: "mono"; text: "↑ " + Ifaces.human(Ifaces.txRate); color: Theme.accent }
            Item { Layout.fillWidth: true }
            Txt { role: "caption"; text: Ifaces.primary ? Ifaces.primary.label : "" }
        }

        RowLayout {
            Layout.fillWidth: true
            Txt { role: "caption"; text: "RAM " + SysInfo.ramText; Layout.fillWidth: true }
            Txt { role: "caption"; text: SysInfo.diskText }
        }

        SectionHeader { Layout.fillWidth: true; text: "Processus" }

        Repeater {
            model: root.procs
            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 8
                Txt { role: "mono"; text: modelData.name; Layout.fillWidth: true; font.pixelSize: 11 }
                Txt { role: "mono"; text: modelData.mem.toFixed(1) + " G"; color: Theme.textSub; font.pixelSize: 11; Layout.preferredWidth: 48; horizontalAlignment: Text.AlignRight }
                Txt {
                    role: "mono"
                    text: modelData.cpu.toFixed(0) + "%"
                    color: modelData.cpu > 80 ? Theme.warning : Theme.text
                    font.pixelSize: 11
                    Layout.preferredWidth: 42
                    horizontalAlignment: Text.AlignRight
                }
            }
        }

        Button {
            Layout.alignment: Qt.AlignRight
            variant: "quiet"
            icon: "monitoring"
            text: "Ouvrir btop"
            onClicked: {
                Quickshell.execDetached(["alacritty", "-e", "btop"]);
                PanelService.hide();
            }
        }
    }
}
