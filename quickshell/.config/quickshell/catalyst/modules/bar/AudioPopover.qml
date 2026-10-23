pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import "../../components"

Item {
    id: root
    implicitWidth: 308
    implicitHeight: col.implicitHeight + 28

    readonly property string sinkShort: {
        const n = Audio.sinkName || "sortie";
        const bit = n.split(/[\/,|]/)[0].trim();
        return bit.length ? bit : n;
    }

    component Fader: Item {
        id: fader
        property real value: 0
        property bool dimmed: false
        signal moved(real v)

        implicitHeight: 16
        Layout.fillWidth: true

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: drag.containsMouse || drag.pressed ? 6 : 4
            radius: 3
            color: Qt.alpha(Theme.ink, 0.2)
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, fader.dimmed ? 0 : fader.value))
                height: parent.height
                radius: parent.radius
                color: Theme.primary
            }
            Rectangle {
                x: Math.max(0, Math.min(parent.width - 10, (fader.dimmed ? 0 : fader.value) * parent.width - 5))
                anchors.verticalCenter: parent.verticalCenter
                width: 8
                height: 8
                radius: 4
                color: Theme.ink
                border.width: 2
                border.color: Theme.primary
            }
        }
        MouseArea {
            id: drag
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: event => fader.moved(Math.max(0, Math.min(1, event.x / width)))
            onPositionChanged: event => {
                if (pressed)
                    fader.moved(Math.max(0, Math.min(1, event.x / width)));
            }
        }
    }

    Surface {
        anchors.fill: parent
        elev: 3
        radius: Tokens.rLg
        photo: true
        border.color: Qt.alpha(Theme.primary, 0.22)

        ColumnLayout {
            id: col
            x: 14
            y: 14
            width: root.width - 28
            spacing: 10

            RowLayout {
                id: hdr
                width: col.width
                spacing: 8
                PanelHead {
                    icon: "󰕾"
                    title: root.sinkShort
                    Layout.fillWidth: true
                    Layout.minimumWidth: 44
                }
                Text {
                    text: "EQ"
                    font.family: Theme.font
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.letterSpacing: 1
                    color: eqBtn.containsMouse ? Theme.primary : Theme.inkMuted
                    MouseArea {
                        id: eqBtn
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: PanelService.popover = "eq"
                    }
                }
                Rectangle {
                    implicitWidth: Math.max(36, muteLab.implicitWidth + 16)
                    implicitHeight: 22
                    radius: 11
                    color: Audio.muted ? Theme.error : Qt.alpha(Theme.primary, 0.16)
                    border.width: 1
                    border.color: Qt.alpha(Audio.muted ? Theme.error : Theme.primary, 0.4)
                    Text {
                        id: muteLab
                        anchors.centerIn: parent
                        text: Audio.muted ? "muet" : Audio.glyph
                        font.family: Theme.font
                        font.pixelSize: 11
                        color: Audio.muted ? Theme.inkPrimary : Theme.primary
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Audio.toggleMute()
                    }
                }
            }

            Rectangle {
                id: devCard
                Layout.fillWidth: true
                Layout.preferredHeight: devCol.implicitHeight + 20
                visible: Audio.outputs.length > 1 || Audio.inputs.length > 1
                radius: 22
                color: Qt.alpha(Theme.surfaceContainerLow, 0.45)
                border.width: 1
                border.color: Qt.alpha(Theme.primary, 0.12)

                property string seg: "out"

                Column {
                    id: devCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.topMargin: 10
                    spacing: 4

                    RowLayout {
                        width: parent.width
                        spacing: 6
                        Text {
                            Layout.fillWidth: true
                            text: "PÉRIPHÉRIQUES"
                            elide: Text.ElideRight
                            font.family: Theme.uiFont
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            font.letterSpacing: 1.6
                            color: Theme.inkMuted
                        }
                        Item { Layout.fillWidth: true }
                        Chip {
                            Layout.fillWidth: false
                            Layout.preferredWidth: 58
                            label: "Sortie"
                            on: devCard.seg === "out"
                            onClicked: devCard.seg = "out"
                        }
                        Chip {
                            Layout.fillWidth: false
                            Layout.preferredWidth: 58
                            label: "Entrée"
                            on: devCard.seg === "in"
                            onClicked: devCard.seg = "in"
                        }
                    }

                    Repeater {
                        model: devCard.seg === "out" ? Audio.outputs : Audio.inputs
                        delegate: Rectangle {
                            id: devRow
                            required property var modelData
                            readonly property bool isOut: devCard.seg === "out"
                            readonly property bool isActive: {
                                const cur = isOut ? Audio.activeOutput : Audio.activeInput;
                                return cur.length > 0 && modelData && String(modelData.id) === cur;
                            }
                            width: devCol.width
                            height: 24
                            radius: 7
                            color: isActive ? Qt.alpha(Theme.primary, 0.16)
                                            : (rowHover.containsMouse ? Qt.alpha(Theme.surfaceContainerHigh, 0.7) : "transparent")

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: devRow.isActive ? Theme.primary : Qt.alpha(Theme.inkMuted, 0.55)
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 20
                                    text: Audio.nodeLabel(devRow.modelData)
                                    font.family: Theme.uiFont
                                    font.pixelSize: 11
                                    font.weight: devRow.isActive ? Font.DemiBold : Font.Normal
                                    color: devRow.isActive ? Theme.primary : Theme.ink
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                            MouseArea {
                                id: rowHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (devRow.isOut)
                                        Audio.setOutput(devRow.modelData);
                                    else
                                        Audio.setInput(devRow.modelData);
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 78

                Rectangle {
                    anchors.fill: parent
                    radius: 22
                    color: Qt.alpha(Theme.surfaceContainerLow, 0.45)
                    border.width: 1
                    border.color: Qt.alpha(Theme.primary, 0.12)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: Audio.muted ? "󰝟" : Audio.glyph
                                font.family: Theme.font
                                font.pixelSize: 16
                                color: Audio.muted ? Theme.error : Theme.primary
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Audio.toggleMute()
                                }
                            }
                            Text {
                                text: "Volume"
                                font.family: Theme.uiFont
                                font.pixelSize: 9
                                font.weight: Font.Bold
                                font.letterSpacing: 1.6
                                color: Theme.inkMuted
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: Audio.muted ? "—" : Audio.percentage + "%"
                                font.family: Theme.font
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: Audio.muted ? Theme.error : Theme.primary
                            }
                        }
                        Fader {
                            value: Audio.volume
                            dimmed: Audio.muted
                            onMoved: v => Audio.setVolume(v)
                        }
                    }
                    WheelHandler {
                        onWheel: event => {
                            Audio.nudge(event.angleDelta.y > 0 ? 0.05 : -0.05);
                            event.accepted = true;
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 78

                Rectangle {
                    anchors.fill: parent
                    radius: 22
                    color: Qt.alpha(Theme.surfaceContainerLow, 0.45)
                    border.width: 1
                    border.color: Qt.alpha(Theme.primary, 0.12)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: Bright.glyph
                                font.family: Theme.font
                                font.pixelSize: 16
                                color: Theme.primary
                            }
                            Text {
                                text: "Lumière"
                                font.family: Theme.uiFont
                                font.pixelSize: 9
                                font.weight: Font.Bold
                                font.letterSpacing: 1.6
                                color: Theme.inkMuted
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: Bright.percentage + "%"
                                font.family: Theme.font
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: Theme.primary
                            }
                        }
                        Fader {
                            value: Bright.value
                            onMoved: v => Bright.set(v)
                        }
                    }
                    WheelHandler {
                        onWheel: event => {
                            Bright.nudge(event.angleDelta.y > 0 ? 0.05 : -0.05);
                            event.accepted = true;
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 72
                visible: Players.has

                Rectangle {
                    anchors.fill: parent
                    radius: 22
                    color: Qt.alpha(Theme.surfaceContainerLow, 0.45)
                    border.width: 1
                    border.color: Qt.alpha(Theme.primary, 0.12)
                    clip: true

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 10
                        spacing: 10

                        Rectangle {
                            width: 52
                            height: 52
                            radius: 10
                            color: Qt.alpha(Theme.primary, 0.12)
                            clip: true
                            Image {
                                anchors.fill: parent
                                visible: Players.artUrl.length > 0 && status === Image.Ready
                                source: Players.artUrl
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: Players.artUrl.length === 0
                                text: "󰎈"
                                font.family: Theme.font
                                font.pixelSize: 18
                                color: Theme.primary
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: PanelService.popover = "media"
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                Layout.fillWidth: true
                                text: Players.title || "média"
                                font.family: Theme.uiFont
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: Theme.ink
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: Players.artist.length ? Players.artist : (Players.identity || "en lecture")
                                font.family: Theme.uiFont
                                font.pixelSize: 11
                                color: Theme.inkMuted
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            text: "󰒮"
                            font.family: Theme.font
                            font.pixelSize: 16
                            color: prevM.containsMouse ? Theme.primary : Theme.ink
                            opacity: Players.canPrev ? 1 : 0.28
                            MouseArea {
                                id: prevM
                                anchors.fill: parent
                                anchors.margins: -4
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Players.prev()
                            }
                        }
                        Rectangle {
                            width: 34
                            height: 34
                            radius: 17
                            color: playM.containsMouse ? Theme.primaryContainer : Theme.primary
                            Text {
                                anchors.centerIn: parent
                                text: Players.glyph
                                font.family: Theme.font
                                font.pixelSize: 14
                                color: Theme.inkPrimary
                            }
                            MouseArea {
                                id: playM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Players.playPause()
                            }
                        }
                        Text {
                            text: "󰒭"
                            font.family: Theme.font
                            font.pixelSize: 16
                            color: nextM.containsMouse ? Theme.primary : Theme.ink
                            opacity: Players.canNext ? 1 : 0.28
                            MouseArea {
                                id: nextM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Players.next()
                            }
                        }
                    }
                }
            }
        }
    }
}
