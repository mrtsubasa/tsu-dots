import QtQuick
import QtQuick.Layouts
import qs.rice

// En-tête de section : micro-label mono « // TITRE » + action optionnelle.
// La barre oblique est la signature typographique Catalyst.
Item {
    id: root

    property string text: ""
    property string actionText: ""
    property string actionIcon: ""
    property bool slash: true
    signal action()

    implicitHeight: 22
    implicitWidth: 200

    RowLayout {
        anchors.fill: parent
        spacing: 6

        Txt {
            visible: root.slash
            role: "overline"
            text: "//"
            color: Theme.accent
            opacity: 0.8
        }
        Txt {
            Layout.fillWidth: true
            role: "overline"
            text: root.text
        }

        Item {
            visible: root.actionText.length > 0 || root.actionIcon.length > 0
            Layout.preferredHeight: 22
            Layout.preferredWidth: act.implicitWidth + 12

            StateLayer {
                id: actLayer
                anchors.fill: parent
                radius: Tokens.rSm
                onClicked: root.action()
            }
            Row {
                id: act
                anchors.centerIn: parent
                spacing: 4
                Icon {
                    visible: root.actionIcon.length > 0
                    name: root.actionIcon
                    size: Tokens.iconXs
                    color: actLayer.containsMouse ? Theme.text : Theme.textSub
                    anchors.verticalCenter: parent.verticalCenter
                }
                Txt {
                    visible: root.actionText.length > 0
                    role: "caption"
                    text: root.actionText
                    color: actLayer.containsMouse ? Theme.text : Theme.textSub
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
