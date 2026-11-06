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
        color: root.on ? Qt.alpha(Theme.accent, 0.18) : Qt.alpha(Theme.text, 0.04)
        border.width: 1
        border.color: root.on ? Qt.alpha(Theme.accent, 0.55) : Theme.border
        Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
    }
    StateLayer {
        anchors.fill: parent
        radius: height / 2
        tone: root.on ? Theme.accent : Theme.text
        onClicked: root.clicked()
    }
    Txt {
        id: lab
        anchors.centerIn: parent
        role: "label"
        text: root.label
        strong: root.on
        color: root.on ? Qt.lighter(Theme.accent, 1.12) : Theme.textSub
    }
}
