pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice

Rectangle {
    id: root
    property string label: ""
    property bool on: false
    signal clicked

    implicitWidth: Math.max(52, lab.implicitWidth + 20)
    implicitHeight: 30
    Layout.fillWidth: true
    Layout.preferredHeight: 30
    radius: 16
    color: on ? Theme.primary : Qt.alpha(Theme.surfaceContainerHigh, 0.85)
    border.width: 1
    border.color: on ? Theme.primary : Qt.alpha(Theme.outlineVariant, 0.6)

    Text {
        id: lab
        anchors.centerIn: parent
        text: root.label
        font.family: Theme.uiFont
        font.pixelSize: 11
        font.weight: Font.DemiBold
        color: root.on ? Theme.inkPrimary : Theme.ink
    }

    MouseArea {
        anchors.fill: parent
        z: 2
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
