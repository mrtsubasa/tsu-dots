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

    implicitWidth: 392
    implicitHeight: col.implicitHeight + 32

    property var procs: []

    readonly property int histLen: 40
    property var cpuHist: []
    property var ramHist: []
    property var gpuHist: []
    property var vramHist: []
    property var rxHist: []
    property var txHist: []
    function push(arr, v) {
        const a = arr.concat([v]);
        return a.length > histLen ? a.slice(a.length - histLen) : a;
    }
    Connections {
        target: SysInfo
        function onCpuChanged() { root.cpuHist = root.push(root.cpuHist, SysInfo.cpu); }
        function onRamChanged() { root.ramHist = root.push(root.ramHist, SysInfo.ram); }
    }
    Connections {
        target: Gpu
        function onUtilChanged() { root.gpuHist = root.push(root.gpuHist, Gpu.util); }
        function onMemChanged() { root.vramHist = root.push(root.vramHist, Gpu.mem); }
    }
    // débits bruts ; tracés normalisés sur le pic de la fenêtre
    readonly property real netPeak: Math.max(1024, ...rxHist, ...txHist)
    Connections {
        target: Ifaces
        function onRxRateChanged() {
            root.rxHist = root.push(root.rxHist, Ifaces.rxRate);
            root.txHist = root.push(root.txHist, Ifaces.txRate);
        }
    }


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
        spacing: 12

        // ---- en-tête ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: Tokens.rMd
                color: Qt.alpha(Theme.accent, 0.14)
                border.width: 1
                border.color: Qt.alpha(Theme.accent, 0.3)
                Icon { anchors.centerIn: parent; name: "monitoring"; size: 18; fill: 1; color: Theme.accent }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Txt { role: "overline"; text: "// " + Identity.hostName; color: Theme.accent }
                Txt { role: "title"; text: "Système" }
            }
            Rectangle {
                height: 22
                width: up.implicitWidth + 16
                radius: 11
                color: Qt.alpha(Theme.text, 0.05)
                border.width: 1
                border.color: Theme.border
                Row {
                    id: up
                    anchors.centerIn: parent
                    spacing: 5
                    Icon { anchors.verticalCenter: parent.verticalCenter; name: "schedule"; size: 13; color: Theme.textSub }
                    Txt { anchors.verticalCenter: parent.verticalCenter; role: "mono"; font.pixelSize: 10; text: SysInfo.uptime; color: Theme.textSub }
                }
            }
        }

        // ---- jauges ----
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 8
            rowSpacing: 8

            Repeater {
                model: [
                    { label: "CPU", value: Math.round(SysInfo.cpu * 100) + "%", sub: SysInfo.hasTemp ? Math.round(SysInfo.temp) + "°C" : "", frac: SysInfo.cpu, tone: Theme.accent, hist: root.cpuHist, show: true },
                    { label: "RAM", value: Math.round(SysInfo.ram * 100) + "%", sub: SysInfo.ramText, frac: SysInfo.ram, tone: Theme.accent2, hist: root.ramHist, show: true },
                    { label: "GPU", value: Math.round(Gpu.util * 100) + "%", sub: (Gpu.temp > 0 ? Math.round(Gpu.temp) + "°C · " : "") + Math.round(Gpu.power) + " W", frac: Gpu.util, tone: Theme.signature, hist: root.gpuHist, show: Gpu.available },
                    { label: "VRAM", value: Math.round(Gpu.mem * 100) + "%", sub: Gpu.memText, frac: Gpu.mem, tone: Theme.warning, hist: root.vramHist, show: Gpu.available && Gpu.memTotal > 0 },
                    { label: "Disque", value: Math.round(SysInfo.disk * 100) + "%", sub: SysInfo.diskText, frac: SysInfo.disk, tone: Theme.success, hist: null, show: true }
                ].filter(m => m.show)

                Rectangle {
                    id: tile
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.columnSpan: index === 4 || (index === 2 && !Gpu.available) ? 2 : 1
                    implicitHeight: meter.implicitHeight + 20
                    radius: Tokens.rLg
                    color: Theme.s2
                    border.width: 1
                    border.color: meter.hot ? Qt.alpha(Theme.error, 0.4) : Theme.border
                    DashMeter {
                        id: meter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 11
                        label: tile.modelData.label
                        value: tile.modelData.value
                        sub: tile.modelData.sub
                        frac: tile.modelData.frac
                        tone: tile.modelData.tone
                        hist: tile.modelData.hist
                        capacity: root.histLen
                    }
                }
            }
        }
        Txt {
            Layout.fillWidth: true
            visible: Gpu.available && Gpu.name.length > 0
            role: "caption"
            color: Theme.textFaint
            text: Gpu.name
        }

        // ---- réseau ----
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 62
            radius: Tokens.rLg
            color: Theme.s2
            border.width: 1
            border.color: Theme.border

            RowLayout {
                anchors.fill: parent
                anchors.margins: 11
                spacing: 12
                ColumnLayout {
                    spacing: 2
                    Txt { role: "overline"; text: "Réseau"; color: Theme.textSub }
                    Txt { role: "caption"; text: Ifaces.primary ? Ifaces.primary.label : "hors ligne"; color: Theme.textFaint }
                }
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    DashSpark {
                        anchors.fill: parent
                        values: root.rxHist.map(v => v / root.netPeak)
                        capacity: root.histLen
                        tone: Theme.accent2
                    }
                    DashSpark {
                        anchors.fill: parent
                        values: root.txHist.map(v => v / root.netPeak)
                        capacity: root.histLen
                        tone: Theme.accent
                        opacity: 0.8
                    }
                }
                ColumnLayout {
                    spacing: 1
                    Txt { Layout.alignment: Qt.AlignRight; role: "mono"; font.pixelSize: 11; text: "↓ " + Ifaces.human(Ifaces.rxRate); color: Theme.accent2 }
                    Txt { Layout.alignment: Qt.AlignRight; role: "mono"; font.pixelSize: 11; text: "↑ " + Ifaces.human(Ifaces.txRate); color: Theme.accent }
                }
            }
        }

        // ---- processus ----
        SectionHeader {
            Layout.fillWidth: true
            Layout.topMargin: 2
            text: "Processus"
            actionText: "btop"
            actionIcon: "open_in_new"
            onAction: {
                Quickshell.execDetached(["alacritty", "-e", "btop"]);
                PanelService.hide();
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Repeater {
                model: root.procs
                Item {
                    id: pr
                    required property var modelData
                    required property int index
                    readonly property real frac: Math.min(1, modelData.cpu / 100)
                    readonly property color tone: modelData.cpu > 80 ? Theme.warning : Theme.accent
                    Layout.fillWidth: true
                    implicitHeight: 30

                    Rectangle {
                        anchors.fill: parent
                        radius: Tokens.rMd
                        color: Qt.alpha(Theme.text, 0.03)
                    }
                    // part de CPU en fond
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: Math.max(4, parent.width * pr.frac)
                        radius: Tokens.rMd
                        color: Qt.alpha(pr.tone, 0.13)
                        Behavior on width { NumberAnimation { duration: Motion.dur(Motion.slow) } }
                    }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8
                        Txt { role: "mono"; font.pixelSize: 10; text: String(pr.index + 1).padStart(2, "0"); color: Theme.textFaint }
                        Txt { role: "label"; text: pr.modelData.name; Layout.fillWidth: true }
                        Txt { role: "mono"; text: pr.modelData.mem.toFixed(1) + " G"; color: Theme.textSub; font.pixelSize: 11; Layout.preferredWidth: 46; horizontalAlignment: Text.AlignRight }
                        Txt {
                            role: "mono"
                            text: pr.modelData.cpu.toFixed(0) + "%"
                            color: pr.modelData.cpu > 80 ? Theme.warning : Theme.text
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            Layout.preferredWidth: 38
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }
        }
    }
}
