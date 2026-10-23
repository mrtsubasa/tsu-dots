pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Puce sélectionnable héritée — états du kit v3.
Item {
    id: root
    property string label: ""
    property bool on: false
    signal clicked

    implicitWidth: Math.max(52, lab.implicitWidth + 22)
    implicitHeight: 30
    Layout.fillWidth: true
    Layout.preferredHeight: 30

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.on ? Theme.accent : Theme.s3
        border.width: 1
        border.color: root.on ? Theme.accent : Theme.border
        Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
    }
    StateLayer {
        anchors.fill: parent
        radius: height / 2
        tone: root.on ? Theme.onAccent : Theme.text
        onClicked: root.clicked()
    }
    Txt {
        id: lab
        anchors.centerIn: parent
        role: "label"
        text: root.label
        color: root.on ? Theme.onAccent : Theme.text
    }
}
