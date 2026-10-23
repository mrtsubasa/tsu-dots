pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.rice
import "../../components"

Item {
    id: root
    implicitWidth: Players.has ? 448 : 280
    implicitHeight: Players.has ? 188 : 108

    readonly property real progress: {
        const len = Players.length;
        if (len <= 0)
            return 0;
        return Math.max(0, Math.min(1, Players.position / len));
    }
    readonly property string byline: {
        const a = Players.artist;
        const b = Players.album;
        if (a.length && b.length && b !== Players.title)
            return a + "  ·  " + b;
        if (a.length)
            return a;
        if (b.length && b !== Players.title)
            return b;
        return "—";
    }

    function fmt(sec) {
        if (!isFinite(sec) || sec < 0)
            sec = 0;
        const m = Math.floor(sec / 60);
        const s = Math.floor(sec % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    function seekAt(x, w) {
        if (!Players.canSeek || w <= 0 || Players.length <= 0)
            return;
        Players.seekTo((Math.max(0, Math.min(1, x / w))) * Players.length);
    }

    WheelHandler {
        enabled: Players.has
        onWheel: event => {
            Players.nudgeVolume(event.angleDelta.y > 0 ? 0.05 : -0.05);
            event.accepted = true;
        }
    }

    Surface {
        anchors.fill: parent
        elev: 3
        radius: Tokens.rLg
        border.color: Qt.alpha(Theme.primary, 0.22)

        Image {
            visible: Players.has && Players.artUrl.length > 0
            anchors.fill: parent
            source: Players.artUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            opacity: 0.22
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 0.95
                blurMax: 48
            }
        }
        Rectangle {
            visible: Players.has
            anchors.fill: parent
            color: Qt.alpha(Theme.background, 0.62)
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0
            visible: Players.has

            Item {
                Layout.preferredWidth: 188
                Layout.fillHeight: true
                clip: true

                Image {
                    anchors.fill: parent
                    visible: Players.artUrl.length > 0 && status === Image.Ready
                    source: Players.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 376
                    sourceSize.height: 376
                }
                Text {
                    anchors.centerIn: parent
                    visible: Players.artUrl.length === 0
                    text: "󰎈"
                    font.family: Theme.font
                    font.pixelSize: 36
                    color: Theme.primary
                }
                Rectangle {
                    anchors.right: parent.right
                    width: 72
                    height: parent.height
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#00000000" }
                        GradientStop { position: 1.0; color: Qt.alpha(Theme.background, 0.78) }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Players.playPause()
                    onDoubleClicked: Players.raise()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: 6
                Layout.rightMargin: 16
                Layout.topMargin: 16
                Layout.bottomMargin: 14
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: Players.title || "aucun média"
                        font.family: Theme.uiFont
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                        color: Theme.ink
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                    }
                    Rectangle {
                        visible: Players.identity.length > 0
                        implicitWidth: idLab.implicitWidth + 16
                        implicitHeight: 20
                        radius: 10
                        color: idMouse.containsMouse ? Theme.primary : Qt.alpha(Theme.primary, 0.16)
                        border.width: 1
                        border.color: Qt.alpha(Theme.primary, 0.4)

                        Text {
                            id: idLab
                            anchors.centerIn: parent
                            text: Players.identity
                            font.family: Theme.uiFont
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            color: idMouse.containsMouse ? Theme.inkPrimary : Theme.primary
                        }
                        MouseArea {
                            id: idMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: event => {
                                if (event.button === Qt.RightButton && Players.playerCount > 1)
                                    Players.cycle();
                                else
                                    Players.raise();
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.byline
                    font.family: Theme.uiFont
                    font.pixelSize: 13
                    color: Theme.inkMuted
                    elide: Text.ElideRight
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: Players.length > 0

                    Text {
                        text: root.fmt(Players.position)
                        font.family: Theme.uiFont
                        font.pixelSize: 10
                        color: Theme.inkMuted
                        Layout.preferredWidth: 32
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 16

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: seekArea.containsMouse || seekArea.pressed ? 6 : 4
                            radius: 3
                            color: Qt.alpha(Theme.ink, 0.22)

                            Rectangle {
                                width: parent.width * root.progress
                                height: parent.height
                                radius: parent.radius
                                color: Theme.primary
                            }
                            Rectangle {
                                x: Math.max(0, Math.min(parent.width - 10, root.progress * parent.width - 5))
                                anchors.verticalCenter: parent.verticalCenter
                                width: seekArea.containsMouse || seekArea.pressed ? 12 : 8
                                height: width
                                radius: width / 2
                                color: Theme.ink
                                border.width: 2
                                border.color: Theme.primary
                            }
                        }

                        MouseArea {
                            id: seekArea
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: Players.canSeek
                            cursorShape: Players.canSeek ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: event => root.seekAt(event.x, width)
                            onPositionChanged: event => {
                                if (pressed)
                                    root.seekAt(event.x, width);
                            }
                        }
                    }

                    Text {
                        text: "−" + root.fmt(Math.max(0, Players.length - Players.position))
                        font.family: Theme.uiFont
                        font.pixelSize: 10
                        color: Theme.inkMuted
                        horizontalAlignment: Text.AlignRight
                        Layout.preferredWidth: 36
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Item { Layout.fillWidth: true }

                    Text {
                        visible: Players.shuffleSupported
                        text: "󰒝"
                        font.family: Theme.font
                        font.pixelSize: 15
                        color: Players.shuffled ? Theme.primary : Theme.inkMuted
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Players.toggleShuffle()
                        }
                    }

                    Text {
                        text: "󰒮"
                        font.family: Theme.font
                        font.pixelSize: 18
                        color: prevMouse.containsMouse ? Theme.primary : Theme.ink
                        opacity: Players.canPrev ? 1 : 0.28
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        MouseArea {
                            id: prevMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Players.prev()
                        }
                    }

                    Rectangle {
                        width: 44
                        height: 44
                        radius: 22
                        color: playMouse.containsMouse ? Theme.primaryContainer : Theme.primary
                        Text {
                            anchors.centerIn: parent
                            text: Players.glyph
                            font.family: Theme.font
                            font.pixelSize: 18
                            color: Theme.inkPrimary
                        }
                        MouseArea {
                            id: playMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Players.playPause()
                        }
                    }

                    Text {
                        text: "󰒭"
                        font.family: Theme.font
                        font.pixelSize: 18
                        color: nextMouse.containsMouse ? Theme.primary : Theme.ink
                        opacity: Players.canNext ? 1 : 0.28
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        MouseArea {
                            id: nextMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Players.next()
                        }
                    }

                    Text {
                        visible: Players.loopSupported
                        text: Players.loopGlyph
                        font.family: Theme.font
                        font.pixelSize: 15
                        color: Players.looping ? Theme.primary : Theme.inkMuted
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Players.cycleLoop()
                        }
                    }

                    Item { Layout.fillWidth: true }
                }
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            visible: !Players.has
            spacing: 8
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "󰎈"
                font.family: Theme.font
                font.pixelSize: 28
                color: Theme.inkMuted
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "rien ne joue"
                font.family: Theme.uiFont
                font.pixelSize: 12
                color: Theme.inkMuted
            }
        }
    }
}
