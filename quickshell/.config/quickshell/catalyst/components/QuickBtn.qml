pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice

Rectangle {
    id: root
    property string icon: ""
    property string label: ""
    property color accent: Theme.primary
    property int boxRadius: 18
    signal clicked

    Layout.fillWidth: true
    height: 64
    radius: boxRadius
    color: hover.containsMouse ? Qt.alpha(accent, 0.18) : Qt.alpha(Theme.surfaceContainerLow, 0.45)
    border.width: 1
    border.color: hover.containsMouse ? accent : Qt.alpha(accent, 0.28)
    scale: hover.containsMouse ? 1.03 : 1

    Behavior on color { ColorAnimation { duration: 90 } }
    Behavior on border.color { ColorAnimation { duration: 90 } }
    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

    Column {
        anchors.centerIn: parent
        spacing: 4
        Text {
            text: root.icon
            font.family: Theme.font
            font.pixelSize: 18
            color: hover.containsMouse ? root.accent : Theme.inkMuted
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Text {
            text: root.label
            font.family: Theme.uiFont
            font.pixelSize: 10
            font.weight: Font.DemiBold
            color: hover.containsMouse ? root.accent : Theme.ink
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
