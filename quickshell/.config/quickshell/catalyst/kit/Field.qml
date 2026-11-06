import QtQuick
import qs.rice

// Champ texte compact (nom de thème, couleur hex…). `accepted(text)` sur Entrée.
Rectangle {
    id: root
    property alias text: input.text
    property alias echoMode: input.echoMode
    property string placeholder: ""
    property bool mono: false
    property var validator: null
    signal accepted(string text)

    implicitWidth: 180
    implicitHeight: Tokens.ctrl
    radius: Tokens.rMd
    color: Theme.s1
    border.width: 1
    border.color: input.activeFocus ? Qt.alpha(Theme.accent, 0.6) : Theme.border

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.text
        selectionColor: Theme.selection
        font.family: root.mono ? Theme.monoFont : Theme.uiFont
        font.pixelSize: Tokens.fLabel + 1
        clip: true
        validator: root.validator
        onAccepted: root.accepted(text)

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text.length === 0
            text: root.placeholder
            color: Theme.textFaint
            font: input.font
        }
    }
}
