import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit

// GPU : utilisation (anneau), VRAM, température et puissance. Lecture via Gpu
// (n'interroge le GPU que tant que le widget est affiché).
Item {
    id: root
    property string wid: ""

    property bool _counted: false
    function _watch(on) {
        if (on === _counted) return;
        _counted = on;
        Gpu.users = Math.max(0, Gpu.users + (on ? 1 : -1));
    }
    readonly property bool onScreen: visible && QsWindow.window !== null && QsWindow.window.visible
    onOnScreenChanged: _watch(onScreen)
    Component.onCompleted: _watch(onScreen)
    Component.onDestruction: _watch(false)

    component Stat: ColumnLayout {
        property string k: ""
        property string v: ""
        spacing: -1
        Txt { role: "mono"; text: parent.v; color: Theme.text; font.weight: Font.DemiBold }
        Txt { role: "overline"; text: parent.k; color: Theme.textFaint }
    }

    EmptyState {
        anchors.centerIn: parent
        visible: !Gpu.available
        icon: "developer_board_off"
        title: "GPU indisponible"
    }

    RowLayout {
        anchors.fill: parent
        visible: Gpu.available
        spacing: 16

        Ring {
            Layout.alignment: Qt.AlignVCenter
            size: Math.min(root.height - 36, root.width * 0.42, 110)
            thickness: Math.max(6, size * 0.08)
            value: Gpu.util
            tone: Theme.signature
            alert: true
            label: Math.round(Gpu.util * 100) + "%"
            sub: "GPU"
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 8

            Txt {
                role: "overline"
                text: "// " + (Gpu.name || "gpu")
                color: Theme.accent
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            GridLayout {
                columns: 2
                columnSpacing: 20
                rowSpacing: 8
                Stat { k: "VRAM"; v: Gpu.memText }
                Stat { k: "Temp"; v: Math.round(Gpu.temp) + "°" }
                Stat { k: "Charge"; v: Math.round(Gpu.util * 100) + "%" }
                Stat { k: "Conso"; v: Math.round(Gpu.power) + " W" }
            }
        }
    }
}
