pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice

Rectangle {
    id: root
    property string icon: ""
    property string label: ""
    property int iconSize: 22
    signal clicked

    height: 50
    radius: 18
    color: hover.containsMouse ? Qt.alpha(Theme.primary, 0.14) : Qt.alpha(Theme.surfaceContainerLow, 0.72)
    border.width: 1
    border.color: hover.containsMouse ? Qt.alpha(Theme.primary, 0.85) : Qt.alpha(Theme.outlineVariant, 0.7)

    Behavior on color { ColorAnimation { duration: 90 } }
    Behavior on border.color { ColorAnimation { duration: 90 } }

    Rectangle {
        width: 2
        height: parent.height - 12
        radius: 1
        anchors.verticalCenter: parent.verticalCenter
        x: 6
        color: Theme.primary
        opacity: hover.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 90 } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 12
        spacing: 10
        Text {
            text: root.icon
            font.family: Theme.font
            font.pixelSize: root.iconSize
            color: Theme.primary
            Layout.alignment: Qt.AlignVCenter
        }
        Text {
            text: root.label
            font.family: Theme.font
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: hover.containsMouse ? Theme.primary : Theme.ink
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
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
