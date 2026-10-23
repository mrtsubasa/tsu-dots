import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Horloge : heure en Space Grotesk, jour, date ; mise à l'échelle avec la carte.
Item {
    id: root
    property string wid: ""
    readonly property real k: Math.max(0.6, Math.min(width / 340, height / 160))

    ColumnLayout {
        anchors.fill: parent
        spacing: 2

        Txt {
            role: "overline"
            text: "// " + Qt.locale().toString(SysInfo.now, "dddd")
            color: Theme.accent
        }
        Text {
            text: Identity.clock12 ? Qt.formatTime(SysInfo.now, "h:mm") : Qt.formatTime(SysInfo.now, "HH:mm")
            color: Theme.text
            font.family: Theme.displayFont
            font.pixelSize: Math.round(76 * root.k)
            font.weight: Font.Medium
            font.letterSpacing: -2 * root.k
            font.features: ({ "tnum": 1 })
        }
        Item { Layout.fillHeight: true }
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Txt {
                role: "body"
                text: Qt.locale().toString(SysInfo.now, "d MMMM yyyy")
                color: Theme.textSub
                Layout.fillWidth: true
            }
            Rectangle { width: 6; height: 6; radius: 3; color: Theme.success }
            Txt { role: "mono"; text: "up " + SysInfo.uptime; color: Theme.textFaint; font.pixelSize: 11 }
        }
    }
}
