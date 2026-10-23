pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice

Item {
    id: root

    property string wid: ""

    component Meter: ColumnLayout {
        id: meter
        property string glyph: ""
        property string label: ""
        property real value: 0
        property string valueText: ""
        property color accent: Theme.primary
        spacing: 7

        readonly property color barColor: meter.value > 0.85 ? Theme.error : meter.accent

        RowLayout {
            Layout.fillWidth: true
            spacing: 7

            Text {
                text: meter.glyph
                font.family: Theme.font
                font.pixelSize: 14
                color: meter.barColor
            }
            Text {
                text: meter.label
                font.family: Theme.uiFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: Theme.ink
            }
            Item {
                Layout.fillWidth: true
            }
            Text {
                text: meter.valueText
                font.family: Theme.font
                font.pixelSize: 12
                font.weight: Font.Bold
                color: Theme.inkMuted
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 7
            radius: 4
            color: Qt.alpha(Theme.surfaceContainerHighest, 0.7)

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, meter.value))
                height: parent.height
                radius: parent.radius
                color: meter.barColor

                Behavior on width {
                    NumberAnimation { duration: 420; easing.type: Easing.OutCubic }
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 18

        RowLayout {
            Layout.fillWidth: true
            spacing: 7

            Rectangle {
                width: 7
                height: 7
                radius: 4
                color: Theme.success

                Rectangle {
                    anchors.centerIn: parent
                    width: 15
                    height: 15
                    radius: 8
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.alpha(Theme.success, 0.45)
                }
            }

            Text {
                text: "SYSTÈME"
                font.family: Theme.font
                font.pixelSize: 11
                font.weight: Font.Bold
                color: Theme.inkMuted
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                text: SysInfo.uptime
                font.family: Theme.font
                font.pixelSize: 11
                color: Qt.alpha(Theme.inkMuted, 0.7)
            }
        }

        Meter {
            Layout.fillWidth: true
            glyph: "󰻠"
            label: "CPU"
            value: SysInfo.cpu
            valueText: Math.round(SysInfo.cpu * 100) + "%"
            accent: Theme.primary
        }

        Meter {
            Layout.fillWidth: true
            glyph: "󰍛"
            label: "Mémoire"
            value: SysInfo.ram
            valueText: SysInfo.ramText || (Math.round(SysInfo.ram * 100) + "%")
            accent: Theme.electric
        }

        Meter {
            Layout.fillWidth: true
            glyph: "󰋊"
            label: "Disque"
            value: SysInfo.disk
            valueText: SysInfo.diskText || (Math.round(SysInfo.disk * 100) + "%")
            accent: Theme.tertiary
        }
    }
}
