pragma ComponentBehavior: Bound
import QtQuick
import qs.rice

Item {
    id: root
    property bool flipX: false
    property bool flipY: false
    property color accent: Theme.primary
    width: 16
    height: 16

    Rectangle {
        x: root.flipX ? parent.width - 2 : 0
        y: 0
        width: 2
        height: 16
        color: root.accent
    }
    Rectangle {
        x: 0
        y: root.flipY ? parent.height - 2 : 0
        width: 16
        height: 2
        color: root.accent
    }
}
