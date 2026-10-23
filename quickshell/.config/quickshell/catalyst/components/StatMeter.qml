pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice

Rectangle {
    id: root
    property real value: 0
    property string glyph: ""
    property string label: ""
    property string valueText: ""

    Layout.fillWidth: true
    height: 92
    radius: 18
    color: Qt.alpha(Theme.surfaceContainerLow, 0.72)
    border.width: 1
    border.color: Qt.alpha(Theme.outlineVariant, 0.7)

    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6
        Text {
            text: root.glyph
            font.family: Theme.font
            font.pixelSize: 14
            color: root.value > 0.85 ? Theme.error : Theme.primary
        }
        Text {
            text: root.valueText
            font.family: Theme.font
            font.pixelSize: 18
            font.weight: Font.Black
            color: Theme.ink
        }
        Text {
            text: root.label
            font.family: Theme.font
            font.pixelSize: 10
            color: Theme.inkMuted
        }
        Rectangle {
            width: parent.width
            height: 3
            radius: 2
            color: Theme.surfaceContainerHighest
            Rectangle {
                width: parent.width * Math.min(1, Math.max(0, root.value))
                height: parent.height
                radius: 2
                color: root.value > 0.85 ? Theme.error : Theme.primary
                Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
            }
        }
    }
}
