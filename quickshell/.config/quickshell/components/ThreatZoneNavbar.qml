pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config

Rectangle {
    id: root

    property var items: ["CORE", "NET", "SEC", "KERNEL", "LOGS"]
    property int activeIndex: 0
    property string brand: "THREAT.ZONE"
    property string statusText: "SYS ONLINE"
    property color accentColor: "#ff4d4d"
    property color accentSoft: "#ff9e3d"
    property color panelColor: Qt.alpha("#120d13", 0.95)
    property color panelAlt: Qt.alpha("#1a1419", 0.9)
    property color borderColor: Qt.alpha("#ff4d4d", 0.7)

    signal sectionSelected(int index)

    implicitHeight: 42
    implicitWidth: 520
    radius: 12
    color: panelColor
    border.width: 1
    border.color: borderColor

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 6
        color: root.accentColor
        border.width: 0
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 10

        Rectangle {
            width: 12
            height: 12
            radius: 6
            color: root.accentColor
            border.width: 1
            border.color: Qt.lighter(root.accentColor, 1.25)

            SequentialAnimation on opacity {
                running: true
                loops: Animation.Infinite
                NumberAnimation { from: 0.4; to: 1; duration: 700 }
                NumberAnimation { from: 1; to: 0.4; duration: 700 }
            }
        }

        Text {
            text: root.brand
            font.family: Config.font
            font.pixelSize: Config.fontSizeSmall
            font.bold: true
            color: "#f7f1eb"
            letterSpacing: 1.5
        }

        Rectangle {
            width: 1
            height: 22
            color: Qt.alpha("#ffffff", 0.2)
        }

        Repeater {
            model: root.items

            Rectangle {
                id: navItem
                required property int index
                required property string modelData

                property bool isActive: root.activeIndex === index
                implicitWidth: Math.max(84, label.implicitWidth + 22)
                implicitHeight: 28
                radius: 8
                color: isActive ? Qt.alpha(root.accentColor, 0.22) : Qt.alpha("#2b1a1d", 0.75)
                border.width: isActive ? 1 : 0
                border.color: isActive ? Qt.alpha(root.accentColor, 0.8) : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: Config.animDurationShort
                    }
                }

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: navItem.modelData
                    font.family: Config.font
                    font.pixelSize: Config.fontSizeSmall
                    font.bold: navItem.isActive
                    color: navItem.isActive ? "#fff4e6" : "#d6b9a5"
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.activeIndex = navItem.index
                        root.sectionSelected(navItem.index)
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            width: 1
            height: 22
            color: Qt.alpha("#ffffff", 0.2)
        }

        RowLayout {
            spacing: 8

            Rectangle {
                width: 8
                height: 8
                radius: 4
                color: "#62ff9d"
                border.width: 1
                border.color: "#b4ffd6"
            }

            Text {
                text: root.statusText
                font.family: Config.font
                font.pixelSize: Config.fontSizeSmall
                color: "#8bffb2"
                font.bold: true
                letterSpacing: 1.2
            }
        }
    }
}
