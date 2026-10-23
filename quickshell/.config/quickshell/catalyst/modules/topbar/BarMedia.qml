import QtQuick
import qs.rice
import qs.kit

// Lecture en cours : pochette + titre. Visible uniquement quand un lecteur
// MPRIS a une piste. Clic = carte média ; clic milieu = lecture/pause ;
// molette = piste suivante/précédente.
BarItem {
    id: root

    property var barWin: null
    property int maxText: 200

    want: BarCfg.on("media") && Players.has && Players.title.length > 0
    tooltip: Players.artist.length ? Players.title + " — " + Players.artist : Players.title
    padX: 6
    spacing: 8
    active: PanelService.active === "media" && PanelService.outputName === (barWin ? barWin.outputName : "")

    onClicked: mouse => {
        if (mouse.button === Qt.MiddleButton)
            Players.playPause();
        else
            PanelService.openAt("media", root.barWin, root);
    }
    onWheel: w => {
        if (w.angleDelta.y > 0)
            Players.prev();
        else
            Players.next();
    }

    Item {
        width: 20
        height: 20
        anchors.verticalCenter: parent.verticalCenter

        Art {
            anchors.fill: parent
            source: Players.artUrl
            radius: 5
            fallbackIcon: "music_note"
        }
        // état lecture : petit voyant animé uniquement pendant la lecture
        Rectangle {
            visible: !Players.playing
            anchors.fill: parent
            radius: 5
            color: Qt.rgba(0, 0, 0, 0.45)
            Icon {
                anchors.centerIn: parent
                name: "pause"
                size: 13
                fill: 1
                color: "white"
            }
        }
    }

    Txt {
        anchors.verticalCenter: parent.verticalCenter
        role: "label"
        text: Players.title
        color: Players.playing ? Theme.text : Theme.textSub
        width: Math.min(implicitWidth, root.maxText)
    }
}
