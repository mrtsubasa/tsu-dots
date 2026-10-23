pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice

Rectangle {
    id: root
    property string icon: ""
    property string label: ""
    property string sub: ""
    property bool on: false
    property int span: 1
    property color accent: Theme.primary
    property color accentInk: Theme.inkPrimary
    property int boxRadius: 18
    signal clicked

    Layout.fillWidth: true
    Layout.columnSpan: span
    Layout.preferredHeight: 62
    radius: boxRadius
    color: on ? accent : (hover.containsMouse ? Qt.alpha(accent, 0.14) : Qt.alpha(Theme.surfaceContainerLow, 0.55))
    border.width: 1
    border.color: on ? accent : (hover.containsMouse ? Qt.alpha(accent, 0.55) : Qt.alpha(accent, 0.22))

    Behavior on color { ColorAnimation { duration: Chrome.motionFast } }
    Behavior on border.color { ColorAnimation { duration: Chrome.motionFast } }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 11
        spacing: 10
        Rectangle {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            radius: Math.max(4, root.boxRadius - 4)
            color: root.on ? Qt.alpha(root.accentInk, 0.16) : Qt.alpha(root.accent, 0.14)
            Text {
                anchors.centerIn: parent
                text: root.icon
                font.family: Theme.font
                font.pixelSize: 16
                color: root.on ? root.accentInk : root.accent
            }
        }
        Column {
            Layout.fillWidth: true
            spacing: 1
            Text {
                text: root.label
                font.family: Theme.uiFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: root.on ? root.accentInk : Theme.ink
                elide: Text.ElideRight
                width: parent.width
            }
            Text {
                visible: root.sub.length > 0
                text: root.sub
                font.family: Theme.uiFont
                font.pixelSize: 10
                color: root.on ? Qt.alpha(root.accentInk, 0.7) : Theme.inkMuted
                elide: Text.ElideRight
                width: parent.width
            }
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
