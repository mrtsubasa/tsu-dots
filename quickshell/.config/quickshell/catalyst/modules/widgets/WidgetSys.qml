import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Système : jauges CPU / mémoire / température / disque (données /proc).
Item {
    id: root
    property string wid: ""
    readonly property real ring: Math.max(44, Math.min(78, (width - 36) / 4, height - 70))

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
        }

        Txt {
            Layout.fillWidth: true
            role: "caption"
            text: SysInfo.ramText + " · " + SysInfo.diskText
            color: Theme.textFaint
        }
    }
}
