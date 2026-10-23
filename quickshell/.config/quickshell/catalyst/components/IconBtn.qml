pragma ComponentBehavior: Bound
import QtQuick
import qs.rice
import qs.kit

// Bouton glyphe hérité (Nerd Font) — états du kit v3.
Item {
    id: root
    property string icon: ""
    property color accent: Theme.textSub
    property real radius: width / 2
    signal clicked

    width: 34
    height: 34

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Theme.s3
        border.width: 1
        border.color: Theme.border
    }
    StateLayer {
        id: layer
        anchors.fill: parent
        radius: root.radius
        onClicked: root.clicked()
    }
    Text {
        anchors.centerIn: parent
        text: root.icon
        font.family: Theme.font
        font.pixelSize: 16
        color: layer.containsMouse ? Theme.accent : root.accent
        Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
    }
}
