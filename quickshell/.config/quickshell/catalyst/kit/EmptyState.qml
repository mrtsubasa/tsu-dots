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

        Icon {
            Layout.alignment: Qt.AlignHCenter
            name: root.icon
            size: Tokens.iconXl
            weight: 300
            color: root.kind === "error" ? Theme.error : Theme.textFaint
        }
        Txt {
            Layout.fillWidth: true
            visible: root.title.length > 0
            horizontalAlignment: Text.AlignHCenter
            role: "label"
            text: root.title
            color: Theme.textSub
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
