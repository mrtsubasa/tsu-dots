import QtQuick
import qs.rice

// Pastille de couleur sélectionnable.
Item {
    id: root
    property color color: "white"
    property bool selected: false
    property real size: 30
    signal clicked()

    implicitWidth: size
    implicitHeight: size

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: 2
        border.color: root.selected ? Theme.text : "transparent"
        Behavior on border.color { ColorAnimation { duration: Motion.dur(Motion.fast) } }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            radius: width / 2
            color: root.color
            scale: area.containsMouse ? 1.08 : 1
            Behavior on scale { NumberAnimation { duration: Motion.dur(Motion.fast) } }
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
