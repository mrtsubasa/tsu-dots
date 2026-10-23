pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice

RowLayout {
    id: root
    property string icon: ""
    property string title: ""
    property bool closable: false
    default property alias extras: extra.data
    signal closed

    Layout.fillWidth: true
    spacing: 8

    Rectangle {
        id: pill
        implicitWidth: Math.max(36, (iconT.visible ? iconT.implicitWidth + 8 : 0) + titleT.implicitWidth + 28)
        Layout.fillWidth: true
        Layout.maximumWidth: implicitWidth
        Layout.minimumWidth: Math.min(implicitWidth, 120)
        Layout.preferredHeight: 36
        radius: 18
        clip: true
        color: Qt.alpha(Theme.primary, 0.18)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 11
            anchors.rightMargin: 11
            spacing: 8

            Text {
                id: iconT
                visible: root.icon.length > 0
                text: root.icon
                font.family: Theme.font
                font.pixelSize: 14
                color: Theme.primary
            }
            Text {
                id: titleT
                Layout.fillWidth: true
                text: root.title
                font.family: Theme.uiFont
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: Theme.ink
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    Item { Layout.fillWidth: true }

    Row {
        id: extra
        spacing: 6
        Layout.alignment: Qt.AlignVCenter
    }

    IconBtn {
        visible: root.closable
        icon: "󰅖"
        onClicked: root.closed()
    }
}
