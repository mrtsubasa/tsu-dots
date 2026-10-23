import QtQuick
import QtQuick.Layouts
import qs.rice

// Ligne de réglage : icône, titre, description, contrôle à droite.
Item {
    id: root
    property string icon: ""
    property string title: ""
    property string subtitle: ""
    default property alias control: slot.data

    implicitHeight: Math.max(52, col.implicitHeight + 20)
    implicitWidth: 400

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 14

        Icon {
            visible: root.icon.length > 0
            name: root.icon
            size: Tokens.iconMd
            color: Theme.textSub
        }
        ColumnLayout {
            id: col
            Layout.fillWidth: true
            spacing: 2
            Txt { Layout.fillWidth: true; role: "body"; text: root.title; font.weight: Font.Medium }
            Txt {
                Layout.fillWidth: true
                visible: text.length > 0
                role: "caption"
                text: root.subtitle
                wrapMode: Text.WordWrap
                maximumLineCount: 3
            }
        }
        Row {
            id: slot
            spacing: 8
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
