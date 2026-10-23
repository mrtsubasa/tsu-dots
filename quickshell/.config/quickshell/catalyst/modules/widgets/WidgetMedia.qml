import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Lecteur : pochette, titre, artiste, progression, contrôles (MPRIS).
// Sans lecteur actif : état vide discret.
Item {
    id: root
    property string wid: ""

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

    EmptyState {
        anchors.centerIn: parent
        visible: !Players.has
        icon: "music_off"
        title: "Aucune lecture"
    }

    RowLayout {
        anchors.fill: parent
        visible: Players.has
        spacing: 16

        Art {
            Layout.preferredWidth: Math.min(root.height, 140)
            Layout.preferredHeight: Layout.preferredWidth
            source: Players.artUrl
            radius: Tokens.rLg
            fallbackIcon: "music_note"
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2
            Txt { role: "overline"; text: Players.identity || "Lecteur"; color: Theme.accent; Layout.fillWidth: true }
            Txt { role: "title"; text: Players.title || "Sans titre"; Layout.fillWidth: true }
            Txt { role: "caption"; text: Players.artist || "Artiste inconnu"; Layout.fillWidth: true }
            Item { Layout.fillHeight: true }
            Rectangle {
                Layout.fillWidth: true
                visible: Players.length > 0
                height: 4
                radius: 2
                color: Theme.s4
                Rectangle {
                    height: parent.height
                    radius: 2
                    width: parent.width * Math.min(1, Players.position / Math.max(1, Players.length))
                    color: Theme.accent
                }
            }
            RowLayout {
                spacing: 4
                Layout.topMargin: 4
                IconButton { icon: "skip_previous"; size: 32; onClicked: Players.prev() }
                IconButton { icon: Players.playing ? "pause" : "play_arrow"; variant: "filled"; size: 38; onClicked: Players.playPause() }
                IconButton { icon: "skip_next"; size: 32; onClicked: Players.next() }
            }
        }
    }
}
