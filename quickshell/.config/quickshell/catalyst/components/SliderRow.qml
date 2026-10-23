pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice

RowLayout {
    id: root
    property string icon: ""
    property real value: 0
    property string text: ""
    property color accent: Theme.primary
    signal moved(real v)

    spacing: 10
    Layout.fillWidth: true

    Text {
        text: root.icon
        font.family: Theme.font
        font.pixelSize: 16
        color: root.accent
        Layout.preferredWidth: 22
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 18

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: drag.containsMouse || drag.pressed ? 8 : 5
            radius: 4
            color: Qt.alpha(Theme.ink, 0.16)
            Behavior on height { NumberAnimation { duration: Chrome.motionFast } }

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.value))
                height: parent.height
                radius: parent.radius
                color: root.accent
            }
            Rectangle {
                x: Math.max(0, Math.min(parent.width - 12, root.value * parent.width - 6))
                anchors.verticalCenter: parent.verticalCenter
                width: 12
                height: 12
                radius: 6
                color: root.accent
                border.width: 0
            }
        }

        MouseArea {
            id: drag
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: event => root.moved(Math.max(0, Math.min(1, event.x / width)))
            onPositionChanged: event => {
                if (pressed)
                    root.moved(Math.max(0, Math.min(1, event.x / width)));
            }
        }
    }

    Text {
        text: root.text
        font.family: Theme.uiFont
        font.pixelSize: 11
        font.weight: Font.DemiBold
        color: Theme.inkMuted
        Layout.preferredWidth: 40
        horizontalAlignment: Text.AlignRight
    }
}
