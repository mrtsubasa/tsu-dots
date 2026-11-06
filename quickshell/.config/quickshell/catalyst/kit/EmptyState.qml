import QtQuick
import QtQuick.Layouts
import qs.rice

// État vide / indisponible / erreur. kind : empty | unavailable | error
Item {
    id: root

    property string icon: kind === "error" ? "error" : (kind === "unavailable" ? "block" : "inbox")
    property string title: ""
    property string text: ""
    property string kind: "empty"
    property string actionText: ""
    signal action()

    implicitHeight: col.implicitHeight + 24
    implicitWidth: 260

    ColumnLayout {
        id: col
        anchors.centerIn: parent
        width: Math.min(parent.width - 24, 300)
        spacing: 6

        // médaillon : halo doux + anneau, teinte rouge en erreur
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 6
            implicitWidth: 64
            implicitHeight: 64
            readonly property color tone: root.kind === "error" ? Theme.error : Theme.accent
            Rectangle {
                anchors.fill: parent
                radius: 32
                color: Qt.alpha(parent.tone, 0.07)
                border.width: 1
                border.color: Qt.alpha(parent.tone, 0.18)
            }
            Rectangle {
                anchors.centerIn: parent
                width: 44
                height: 44
                radius: 22
                color: Qt.alpha(parent.tone, 0.10)
                border.width: 1
                border.color: Qt.alpha(parent.tone, 0.30)
                Icon {
                    anchors.centerIn: parent
                    name: root.icon
                    size: 22
                    color: root.kind === "error" ? Theme.error : Qt.lighter(Theme.accent, 1.1)
                }
            }
        }
        Txt {
            Layout.fillWidth: true
            visible: root.title.length > 0
            horizontalAlignment: Text.AlignHCenter
            role: "label"
            strong: true
            text: root.title
            color: Theme.text
        }
        Txt {
            Layout.fillWidth: true
            visible: root.text.length > 0
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            role: "caption"
            text: root.text
            color: Theme.textFaint
        }
        Button {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 4
            visible: root.actionText.length > 0
            variant: "secondary"
            text: root.actionText
            onClicked: root.action()
        }
    }
}
