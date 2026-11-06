import QtQuick
import qs.rice

// Ligne d'aide clavier : [{ keys: ["↑", "↓"], text: "choisir" }, …]
Row {
    id: root
    property var hints: []
    spacing: 14

    Repeater {
        model: root.hints
        Row {
            id: hint
            required property var modelData
            spacing: 4
            Repeater {
                model: hint.modelData.keys || []
                Kbd {
                    required property string modelData
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData
                }
            }
            Txt {
                anchors.verticalCenter: parent.verticalCenter
                role: "caption"
                font.pixelSize: 10
                text: hint.modelData.text
                color: Theme.textFaint
            }
        }
    }
}
