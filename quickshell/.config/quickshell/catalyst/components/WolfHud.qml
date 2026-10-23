pragma ComponentBehavior: Bound
import QtQuick
import qs.rice

Item {
    id: root
    property color cyan: Theme.primary
    property color magenta: Theme.tertiary
    property color voidC: Theme.background

    Rectangle {
        anchors.fill: parent
        radius: 4
        color: Qt.alpha(root.voidC, 0.84)
        border.width: 1
        border.color: root.cyan
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        radius: 2
        color: "transparent"
        border.width: 1
        border.color: Qt.alpha(root.magenta, 0.55)
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 2
        color: root.cyan
    }
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 3
        color: root.magenta
    }

    Repeater {
        model: 4
        delegate: Item {
            required property int index
            width: 18
            height: 18
            x: index % 2 === 0 ? 8 : root.width - 26
            y: index < 2 ? 8 : root.height - 26
            Rectangle {
                width: 18
                height: 2
                color: index < 2 ? root.cyan : root.magenta
                anchors.left: parent.left
                anchors.top: index < 2 ? parent.top : undefined
                anchors.bottom: index >= 2 ? parent.bottom : undefined
            }
            Rectangle {
                width: 2
                height: 18
                color: index < 2 ? root.cyan : root.magenta
                anchors.top: parent.top
                anchors.left: index % 2 === 0 ? parent.left : undefined
                anchors.right: index % 2 === 1 ? parent.right : undefined
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 6
        radius: 2
        z: 2
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.alpha(root.cyan, 0.07) }
            GradientStop { position: 0.45; color: "#00000000" }
            GradientStop { position: 1.0; color: Qt.alpha(root.magenta, 0.08) }
        }
    }
}
