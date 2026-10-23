pragma ComponentBehavior: Bound
import QtQuick
import qs.rice

Rectangle {
    id: root
    property string icon: ""
    property color accent: Theme.inkMuted
    signal clicked

    width: 34
    height: 34
    radius: 17
    color: hover.containsMouse ? Qt.alpha(Theme.primary, 0.22) : Qt.alpha(Theme.surfaceContainerHigh, 0.42)
    border.width: 1
    border.color: hover.containsMouse ? Theme.primary : "#00000000"

    Behavior on color { ColorAnimation { duration: 90 } }

    Text {
        anchors.centerIn: parent
        text: root.icon
        font.family: Theme.font
        font.pixelSize: 16
        color: hover.containsMouse ? Theme.primary : root.accent
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
