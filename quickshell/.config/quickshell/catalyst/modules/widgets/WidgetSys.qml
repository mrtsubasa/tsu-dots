import QtQuick
import Quickshell
import QtQuick.Layouts
import qs.rice
import qs.kit

// Système : jauges CPU / mémoire / température / disque (données /proc).
Item {
    id: root
    property string wid: ""
    readonly property bool showGpu: Gpu.available
    readonly property real ring: Math.max(40, Math.min(78, (width - 36) / (showGpu ? 5 : 4), height - 70))

    property bool _counted: false
    function _watch(on) {
        if (on === _counted)
            return;
        _counted = on;
        Gpu.users = Math.max(0, Gpu.users + (on ? 1 : -1));
    }
    // compte seulement si la fenêtre du bureau est réellement affichée
    readonly property bool onScreen: visible && QsWindow.window !== null && QsWindow.window.visible
    onOnScreenChanged: _watch(onScreen && showGpu)
    Component.onCompleted: _watch(onScreen && showGpu)
    Component.onDestruction: _watch(false)

    component Gauge: ColumnLayout {
        id: g
        property real v: 0
        property string t: ""
        property string c: ""
        Layout.fillWidth: true
        spacing: 6
        Ring { Layout.alignment: Qt.AlignHCenter; size: root.ring; thickness: 5; value: g.v; label: g.t }
        Txt { Layout.alignment: Qt.AlignHCenter; role: "overline"; text: g.c }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Txt { role: "overline"; text: "// système"; color: Theme.accent; Layout.fillWidth: true }
            Txt { role: "mono"; text: Identity.hostName; color: Theme.textFaint; font.pixelSize: 11 }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Gauge { v: SysInfo.cpu; t: Math.round(SysInfo.cpu * 100) + "%"; c: "CPU" }
            Gauge { v: SysInfo.ram; t: Math.round(SysInfo.ram * 100) + "%"; c: "RAM" }
            Gauge { visible: SysInfo.hasTemp; v: SysInfo.temp / 100; t: Math.round(SysInfo.temp) + "°"; c: "Temp" }
            Gauge { v: SysInfo.disk; t: Math.round(SysInfo.disk * 100) + "%"; c: "Disque" }
            Gauge { visible: root.showGpu && Gpu.memTotal > 0; v: Gpu.util; t: Math.round(Gpu.util * 100) + "%"; c: "GPU" }
        }

        Txt {
            Layout.fillWidth: true
            role: "caption"
            text: SysInfo.ramText + " · " + SysInfo.diskText
            color: Theme.textFaint
        }
    }
}
