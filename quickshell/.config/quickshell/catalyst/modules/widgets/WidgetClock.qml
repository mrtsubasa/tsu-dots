pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice

Item {
    id: root

    property string wid: ""
    property string hhmm: "00:00"
    property string ss: "00"
    property string day: ""

    function tick() {
        const d = new Date();
        root.hhmm = Qt.formatTime(d, "HH:mm");
        root.ss = Qt.formatTime(d, "ss");
        root.day = Qt.formatDate(d, Locale.LongFormat);
    }

    Component.onCompleted: root.tick()

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.tick()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        RowLayout {
            spacing: 8
            Layout.bottomMargin: 2

            Text {
                text: root.hhmm
                font.family: Theme.uiFont
                font.pixelSize: 66
                font.weight: Font.Black
                color: Theme.ink
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: root.ss
                font.family: Theme.font
                font.pixelSize: 17
                font.weight: Font.Bold
                color: Theme.primary
                Layout.alignment: Qt.AlignVCenter
                Layout.bottomMargin: 8
            }
        }

        Text {
            text: root.day.toUpperCase()
            font.family: Theme.font
            font.pixelSize: 12
            font.weight: Font.Medium
            color: Theme.inkMuted
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        Item {
            Layout.fillHeight: true
        }

        RowLayout {
            spacing: 7
            Layout.fillWidth: true

            Rectangle {
                width: 7
                height: 7
                radius: 4
                color: Theme.success
            }

            Text {
                text: SysInfo.uptime.length ? ("UP " + SysInfo.uptime) : "UP —"
                font.family: Theme.font
                font.pixelSize: 11
                color: Theme.inkMuted
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                text: SysInfo.date
                font.family: Theme.font
                font.pixelSize: 11
                color: Qt.alpha(Theme.inkMuted, 0.7)
                Layout.alignment: Qt.AlignRight
            }
        }
    }
}
