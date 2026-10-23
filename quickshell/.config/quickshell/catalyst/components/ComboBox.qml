pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice

Rectangle {
    id: root
    property var model: []
    property int currentIndex: 0
    property bool open: false
    property bool openUpward: false
    signal selected(int index)

    readonly property string currentValue: (model && currentIndex >= 0 && currentIndex < model.length) ? model[currentIndex] : ""

    height: 40
    radius: 20
    color: Qt.alpha(Theme.surfaceContainerHigh, 0.85)
    border.width: 1
    border.color: open ? Theme.primary : Theme.hairline
    clip: false
    z: open ? 50 : 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 12
        spacing: 6
        Text {
            text: root.currentValue
            font.family: Theme.font
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: Theme.ink
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
        Text {
            text: root.open ? "󰅃" : "󰅀"
            font.family: Theme.font
            font.pixelSize: 12
            color: Theme.primary
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.open = !root.open
    }

    Rectangle {
        id: dropdown
        visible: root.open
        z: 200
        width: root.width
        readonly property int maxItems: 7
        readonly property int itemCount: root.model ? root.model.length : 0
        height: Math.min(itemCount, maxItems) * 34 + 12
        y: root.openUpward ? -(height + 6) : root.height + 6
        radius: 16
        color: Theme.surfaceContainerHighest
        border.width: 1
        border.color: Theme.primary
        clip: true

        Flickable {
            anchors.fill: parent
            anchors.margins: 6
            contentHeight: col.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: col
                width: parent.width
                spacing: 2
                Repeater {
                    model: root.model || []
                    delegate: Rectangle {
                        required property int index
                        required property var modelData
                        width: col.width
                        height: 30
                        radius: 10
                        color: {
                            if (index === root.currentIndex) return Theme.primary;
                            if (hov.hovered) return Qt.alpha(Theme.primary, 0.18);
                            return "transparent";
                        }
                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            text: modelData
                            font.family: Theme.font
                            font.pixelSize: 12
                            font.weight: index === root.currentIndex ? Font.Bold : Font.Normal
                            color: index === root.currentIndex ? Theme.inkPrimary : Theme.ink
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                        HoverHandler { id: hov }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.currentIndex = index;
                                root.open = false;
                                root.selected(index);
                            }
                        }
                    }
                }
            }
        }
    }

    // close when clicking outside
    MouseArea {
        visible: root.open
        z: -1
        anchors.fill: parent
        onClicked: root.open = false
    }
}
