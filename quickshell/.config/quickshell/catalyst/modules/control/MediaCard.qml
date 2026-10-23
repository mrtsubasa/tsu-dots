pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.rice
import qs.kit

// Carte média MPRIS : pochette, titre/artiste, progression (seek), contrôles,
// sélection du lecteur quand il y en a plusieurs. Gère l'absence de métadonnées
// et de pochette ; la progression n'avance que si la carte est visible.
Pane {
    id: root

    property bool large: false
    level: 3
    glass: false
    radius: Tokens.rLg
    implicitHeight: col.implicitHeight + 24

    // fond : pochette floutée très atténuée
    Item {
        anchors.fill: parent
        clip: true
        visible: Players.artUrl.length > 0
        opacity: 0.18
        Art {
            anchors.fill: parent
            source: Players.artUrl
            radius: root.radius
        }
    }

    // la position n'est rafraîchie que pendant que la carte est visible
    property bool _counted: false
    function _watch(on) {
        if (on === _counted)
            return;
        _counted = on;
        Players.posWatchers = Math.max(0, Players.posWatchers + (on ? 1 : -1));
    }
    onVisibleChanged: _watch(visible)
    Component.onCompleted: _watch(visible)
    Component.onDestruction: _watch(false)

    function fmt(s) {
        if (!(s > 0))
            return "0:00";
        const m = Math.floor(s / 60);
        const ss = Math.floor(s % 60);
        return m + ":" + (ss < 10 ? "0" : "") + ss;
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Art {
                Layout.preferredWidth: root.large ? 72 : 56
                Layout.preferredHeight: Layout.preferredWidth
                source: Players.artUrl
                radius: Tokens.rMd
                fallbackIcon: "music_note"
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Txt {
                    Layout.fillWidth: true
                    role: "overline"
                    text: Players.identity || "Lecteur"
                    color: Theme.accent
                }
                Txt {
                    Layout.fillWidth: true
                    role: "heading"
                    text: Players.title.length ? Players.title : "Aucun titre"
                }
                Txt {
                    Layout.fillWidth: true
                    role: "caption"
                    text: Players.artist.length ? Players.artist : (Players.album.length ? Players.album : "Artiste inconnu")
                }
            }

            IconButton {
                visible: Players.playerCount > 1
                Layout.alignment: Qt.AlignTop
                icon: "swap_horiz"
                size: 28
                iconSize: 17
                tooltip: "Lecteur suivant (" + Players.playerCount + ")"
                onClicked: Players.cycle()
            }
        }

        // progression
        ColumnLayout {
            Layout.fillWidth: true
            visible: Players.length > 0
            spacing: 4

            Item {
                Layout.fillWidth: true
                implicitHeight: 12

                Rectangle {
                    id: trackBg
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: seek.containsMouse || seek.pressed ? 6 : 4
                    radius: height / 2
                    color: Theme.s4
                    Behavior on height { NumberAnimation { duration: Motion.dur(Motion.fast) } }

                    Rectangle {
                        height: parent.height
                        radius: parent.radius
                        width: parent.width * Math.max(0, Math.min(1, (seek.pressed ? seek.dragFrac : Players.position / Math.max(1, Players.length))))
                        color: Theme.accent
                    }
                }

                MouseArea {
                    id: seek
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: Players.canSeek
                    cursorShape: Players.canSeek ? Qt.PointingHandCursor : Qt.ArrowCursor
                    property real dragFrac: 0
                    onPressed: mouse => dragFrac = Math.max(0, Math.min(1, mouse.x / width))
                    onPositionChanged: mouse => {
                        if (pressed)
                            dragFrac = Math.max(0, Math.min(1, mouse.x / width));
                    }
                    onReleased: Players.seekTo(dragFrac * Players.length)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Txt { role: "mono"; text: root.fmt(Players.position); color: Theme.textSub; font.pixelSize: 10 }
                Item { Layout.fillWidth: true }
                Txt { role: "mono"; text: root.fmt(Players.length); color: Theme.textSub; font.pixelSize: 10 }
            }
        }

        // contrôles
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            IconButton {
                visible: Players.shuffleSupported
                icon: "shuffle"
                size: 30
                iconSize: 17
                active: Players.shuffled
                tooltip: "Aléatoire"
                onClicked: Players.toggleShuffle()
            }
            Item { Layout.fillWidth: true }
            IconButton {
                icon: "skip_previous"
                size: 34
                disabled: !Players.canPrev
                tooltip: "Précédent"
                onClicked: Players.prev()
            }
            IconButton {
                icon: Players.playing ? "pause" : "play_arrow"
                variant: "filled"
                size: 42
                iconSize: 24
                tooltip: Players.playing ? "Pause" : "Lecture"
                onClicked: Players.playPause()
            }
            IconButton {
                icon: "skip_next"
                size: 34
                disabled: !Players.canNext
                tooltip: "Suivant"
                onClicked: Players.next()
            }
            Item { Layout.fillWidth: true }
            IconButton {
                visible: Players.loopSupported
                icon: Players.loop === MprisLoopState.Track ? "repeat_one" : "repeat"
                size: 30
                iconSize: 17
                active: Players.looping
                tooltip: "Répéter"
                onClicked: Players.cycleLoop()
            }
            IconButton {
                visible: Players.canRaise
                icon: "open_in_new"
                size: 30
                iconSize: 16
                tooltip: "Afficher le lecteur"
                onClicked: {
                    Players.raise();
                    PanelService.hide();
                }
            }
        }
    }
}
