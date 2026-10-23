import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Météo (service Weather existant, rafraîchi toutes les 15 min).
Item {
    id: root
    property string wid: ""

    EmptyState {
        anchors.centerIn: parent
        visible: !Weather.ready
        icon: "cloud_off"
        title: "Météo indisponible"
    }

    RowLayout {
        anchors.fill: parent
        visible: Weather.ready
        spacing: 16

        Text {
            text: Weather.glyph
            font.family: Theme.font
            font.pixelSize: Math.min(root.height * 0.7, 64)
            color: Theme.accent2
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Txt { role: "overline"; text: "// " + (Weather.city || "météo"); color: Theme.accent }
            Text {
                text: Weather.temp + "°"
                color: Theme.text
                font.family: Theme.displayFont
                font.pixelSize: Math.min(root.height * 0.45, 48)
                font.weight: Font.Medium
            }
            Txt { role: "caption"; text: Weather.desc.charAt(0).toUpperCase() + Weather.desc.slice(1) + " · ressenti " + Weather.feel + "°"; Layout.fillWidth: true }
            Txt { role: "mono"; text: "↑ " + Weather.high + "°   ↓ " + Weather.low + "°"; color: Theme.textSub; font.pixelSize: 11 }
        }
    }
}
