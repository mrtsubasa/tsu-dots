pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice

Item {
    id: root
    property var notif: null
    property bool popup: false
    property bool compact: false
    property int idx: -1

    readonly property color accent: Notifs.urgencyColor(notif)
    readonly property var acts: Notifs.visibleActions(notif)
    readonly property string img: Notifs.imageUrl(notif)
    readonly property string app: (notif && notif.appName) ? notif.appName : "notification"
    readonly property string summary: notif ? (notif.summary || "") : ""
    readonly property string body: notif ? (notif.body || "") : ""
    readonly property string iconSrc: Notifs.toUrl(Notifs.iconName(notif))

    implicitWidth: 400
    implicitHeight: surf.implicitHeight

    Surface {
        id: surf
        anchors.left: parent.left
        anchors.right: parent.right
        elev: root.popup ? 3 : (root.compact ? 1 : 2)
        radius: root.compact ? 16 : 22
        implicitHeight: inner.implicitHeight + (root.popup ? 22 : (root.compact ? 12 : 16))

        HoverHandler {
            id: hover
            enabled: root.popup
            onHoveredChanged: {
                if (!root.popup || !root.notif)
                    return;
                if (hovered)
                    Notifs.hold(root.notif);
                else
                    Notifs.release(root.notif);
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 3
            color: root.accent
            radius: 2
        }

        ColumnLayout {
            id: inner
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: root.compact ? 10 : 14
            anchors.rightMargin: root.compact ? 8 : 12
            anchors.topMargin: root.compact ? 8 : 12
            spacing: root.compact ? 6 : 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Item {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    Layout.alignment: Qt.AlignTop

                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: Qt.alpha(root.accent, 0.16)
                        border.width: 1
                        border.color: Qt.alpha(root.accent, 0.35)
                        clip: true

                        Image {
                            id: extra
                            anchors.fill: parent
                            visible: status === Image.Ready
                            source: root.img.length ? root.img : root.iconSrc
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: 80
                            sourceSize.height: 80
                        }
                        Text {
                            visible: extra.status !== Image.Ready
                            anchors.centerIn: parent
                            text: "󰂚"
                            font.family: Theme.font
                            font.pixelSize: 18
                            color: root.accent
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Text {
                            text: root.app
                            font.family: Theme.uiFont
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.6
                            color: root.accent
                            elide: Text.ElideRight
                        }
                        Text {
                            visible: !root.popup && root.idx >= 0
                            text: "·  " + Notifs.ago(root.idx)
                            font.family: Theme.uiFont
                            font.pixelSize: 10
                            color: Theme.inkMuted
                        }
                        Item { Layout.fillWidth: true }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: root.summary.length > 0
                        text: root.summary
                        font.family: Theme.uiFont
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        color: Theme.ink
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        textFormat: Text.StyledText
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: root.body.length > 0
                        text: root.body
                        font.family: Theme.uiFont
                        font.pixelSize: 12
                        color: Theme.inkMuted
                        wrapMode: Text.Wrap
                        maximumLineCount: root.popup ? 4 : 2
                        elide: Text.ElideRight
                        textFormat: Text.StyledText
                        onLinkActivated: link => Qt.openUrlExternally(link)
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignTop
                    width: 28
                    height: 28
                    radius: 8
                    color: closeArea.containsMouse ? Qt.alpha(Theme.error, 0.22) : Qt.alpha(Theme.surfaceContainerHigh, 0.55)
                    border.width: 1
                    border.color: closeArea.containsMouse ? Theme.error : Theme.hairline
                    z: 2
                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: Theme.font
                        font.pixelSize: 13
                        color: closeArea.containsMouse ? Theme.error : Theme.inkMuted
                    }
                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.dismiss(root.notif)
                    }
                }
            }

            Flow {
                Layout.fillWidth: true
                spacing: 6
                visible: root.acts.length > 0

                Repeater {
                    model: root.acts.length
                    delegate: Rectangle {
                        required property int index
                        readonly property var modelData: root.acts[index]
                        implicitWidth: Math.max(64, actLab.implicitWidth + 18)
                        implicitHeight: 26
                        radius: 8
                        color: actMouse.containsMouse ? Theme.primary : Qt.alpha(Theme.primary, 0.16)
                        border.width: 1
                        border.color: Qt.alpha(Theme.primary, 0.4)

                        Text {
                            id: actLab
                            anchors.centerIn: parent
                            text: Notifs.actionLabel(parent.modelData)
                            font.family: Theme.uiFont
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: actMouse.containsMouse ? Theme.inkPrimary : Theme.primary
                        }
                        MouseArea {
                            id: actMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Notifs.invokeAction(root.notif, parent.modelData)
                        }
                    }
                }
            }
        }

        Rectangle {
            visible: root.popup
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 3
            color: Qt.alpha(root.accent, 0.14)
            Rectangle {
                height: parent.height
                width: parent.width * Notifs.remain(root.notif)
                color: hover.hovered ? Theme.tertiary : root.accent
                Behavior on width { NumberAnimation { duration: 80 } }
            }
        }

        MouseArea {
            anchors.fill: parent
            anchors.rightMargin: 42
            anchors.bottomMargin: root.acts.length > 0 ? 40 : 0
            z: -1
            cursorShape: Qt.PointingHandCursor
            onClicked: Notifs.invokeDefault(root.notif)
        }
    }
}
