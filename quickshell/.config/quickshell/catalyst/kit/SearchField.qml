import QtQuick
import QtQuick.Layouts
import qs.rice

// Champ de recherche / saisie. Expose `input` pour le focus et les touches.
Item {
    id: root

    property alias text: input.text
    property alias input: input
    property string placeholder: "Rechercher…"
    property string icon: "search"
    property real fieldHeight: Tokens.ctrlLg
    property bool large: false
    default property alias trailing: trail.data

    signal accepted()

    implicitWidth: 320
    implicitHeight: large ? 52 : fieldHeight

    function focusInput() {
        input.forceActiveFocus();
    }

    Rectangle {
        anchors.fill: parent
        radius: root.large ? Tokens.rLg : Tokens.rMd
        color: root.large ? "transparent" : Theme.s1
        border.width: root.large ? 0 : 1
        border.color: input.activeFocus ? Qt.alpha(Theme.accent, 0.55) : Theme.border
        Behavior on border.color { ColorAnimation { duration: Motion.dur(Motion.fast) } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.large ? 6 : 12
            anchors.rightMargin: 8
            spacing: root.large ? 12 : 8

            Icon {
                name: root.icon
                size: root.large ? Tokens.iconLg : Tokens.iconSm + 2
                color: input.activeFocus ? Theme.accent : Theme.textSub
            }

            TextInput {
                id: input
                Layout.fillWidth: true
                Layout.fillHeight: true
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.text
                selectionColor: Theme.selection
                selectedTextColor: Theme.text
                font.family: Theme.uiFont
                font.pixelSize: root.large ? 18 : Tokens.fBody
                clip: true
                onAccepted: root.accepted()

                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: input.text.length === 0
                    role: "body"
                    text: root.placeholder
                    color: Theme.textFaint
                    font.pixelSize: input.font.pixelSize
                }
            }

            Row {
                id: trail
                spacing: 6
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
