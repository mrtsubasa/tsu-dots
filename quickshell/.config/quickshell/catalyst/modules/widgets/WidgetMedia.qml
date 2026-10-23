pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import "../../components"

Item {
    id: root

    property string wid: ""
    readonly property bool has: Players.has

    function fmt(sec) {
        if (!isFinite(sec) || sec < 0)
            return "0:00";
        const s = Math.floor(sec);
        const m = Math.floor(s / 60);
        const r = s % 60;
        return m + ":" + (r < 10 ? "0" : "") + r;
    }

    // État vide -------------------------------------------------------------
    ColumnLayout {
        anchors.fill: parent
        spacing: 8
        visible: !root.has

        Item { Layout.fillHeight: true }

        Text {
            text: "󰝚"
            font.family: Theme.font
            font.pixelSize: 26
            color: Qt.alpha(Theme.inkMuted, 0.5)
            Layout.alignment: Qt.AlignHCenter
        }
        Text {
            text: "Aucun média"
            font.family: Theme.uiFont
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: Theme.inkMuted
            Layout.alignment: Qt.AlignHCenter
        }

        Item { Layout.fillHeight: true }
    }

    // Lecteur ---------------------------------------------------------------
    RowLayout {
        anchors.fill: parent
        spacing: 14
        visible: root.has

        Rectangle {
            width: 78
            height: 78
            radius: 17
            color: Qt.alpha(Theme.surfaceContainerHighest, 0.7)
            border.width: 1
            border.color: Qt.alpha(Theme.outlineVariant, 0.6)
            clip: true

            Image {
                anchors.fill: parent
                anchors.margins: 1
                source: Players.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                visible: status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                text: "󰝚"
                font.family: Theme.font
                font.pixelSize: 24
                color: Qt.alpha(Theme.inkMuted, 0.45)
                visible: Players.artUrl.length === 0
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 5

            Text {
                text: Players.title
                font.family: Theme.uiFont
                font.pixelSize: 15
                font.weight: Font.Bold
                color: Theme.ink
                Layout.fillWidth: true
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                text: Players.artist.length ? Players.artist : (Players.identity || "")
                font.family: Theme.uiFont
                font.pixelSize: 12
                color: Theme.inkMuted
                Layout.fillWidth: true
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 14
                Layout.topMargin: 2

                Rectangle {
                    id: track
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 5
                    radius: 3
                    color: Qt.alpha(Theme.surfaceContainerHighest, 0.85)

                    Rectangle {
                        width: parent.width * (Players.length > 0 ? Math.min(1, Players.position / Players.length) : 0)
                        height: parent.height
                        radius: parent.radius
                        color: Theme.primary
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: Players.canSeek && Players.length > 0
                    onClicked: mouse => {
                        const ratio = Math.max(0, Math.min(1, mouse.x / Math.max(1, track.width)));
                        Players.seekTo(ratio * Players.length);
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.fmt(Players.position) + " / " + root.fmt(Players.length)
                    font.family: Theme.font
                    font.pixelSize: 10
                    color: Qt.alpha(Theme.inkMuted, 0.85)
                    style: Text.Outline
                    styleColor: Qt.alpha(Theme.background, 0.9)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                IconBtn {
                    icon: "󰒮"
                    visible: Players.canPrev
                    onClicked: Players.prev()
                }
                IconBtn {
                    icon: Players.playing ? "󰏤" : "󰐊"
                    accent: Theme.primary
                    onClicked: Players.playPause()
                }
                IconBtn {
                    icon: "󰒭"
                    visible: Players.canNext
                    onClicked: Players.next()
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: Players.volGlyph
                    font.family: Theme.font
                    font.pixelSize: 15
                    color: Players.muted ? Qt.alpha(Theme.inkMuted, 0.5) : Theme.electric
                    Layout.alignment: Qt.AlignVCenter
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -7
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Players.toggleMute()
                    }
                }
            }
        }
    }
}
