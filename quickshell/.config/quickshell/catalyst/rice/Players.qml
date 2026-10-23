pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var players: Mpris.players.values
    property var active: null
    readonly property bool has: active !== null
    readonly property string title: active ? (active.trackTitle || "") : ""
    readonly property string artist: active ? (active.trackArtist || "") : ""
    readonly property string album: active ? (active.trackAlbum || "") : ""
    readonly property string identity: active ? (active.identity || "") : ""
    readonly property string art: active ? (active.trackArtUrl || "") : ""
    readonly property bool playing: active ? !!active.isPlaying : false
    readonly property string glyph: playing ? "󰏤" : "󰐊"
    readonly property bool canNext: !active || active.canGoNext !== false
    readonly property bool canPrev: !active || active.canGoPrevious !== false
    readonly property bool canRaise: active ? !!active.canRaise : false
    readonly property bool shuffleSupported: active ? !!active.shuffleSupported : false
    readonly property bool loopSupported: active ? !!active.loopSupported : false
    readonly property bool shuffled: active ? !!active.shuffle : false
    readonly property int loop: active ? active.loopState : MprisLoopState.None
    readonly property bool looping: loop !== MprisLoopState.None
    readonly property string loopGlyph: loop === MprisLoopState.Track ? "󰑘" : "󰑖"
    readonly property int playerCount: players ? players.length : 0
    readonly property bool volumeSupported: active ? !!active.volumeSupported : false
    readonly property real volume: {
        if (active && volumeSupported)
            return Math.max(0, Math.min(1, active.volume ?? 0));
        return Audio.volume;
    }
    readonly property bool muted: {
        if (active && volumeSupported)
            return volume <= 0.001;
        return Audio.muted;
    }
    readonly property string volGlyph: {
        if (muted || volume <= 0)
            return "󰝟";
        if (volume < 0.34)
            return "󰕿";
        if (volume < 0.67)
            return "󰖀";
        return "󰕾";
    }
    property real lastVol: 0.7
    property int posTick: 0

    // consommateurs de la position (cartes visibles) : le minuteur ne tourne
    // que s'il y en a au moins un
    property int posWatchers: 0

    Timer {
        interval: 1000
        running: root.playing && root.has && root.posWatchers > 0
        repeat: true
        onTriggered: root.posTick++
    }

    Instantiator {
        model: Mpris.players
        delegate: QtObject {
            required property var modelData
            property bool isPlaying: modelData.isPlaying ?? false
            onIsPlayingChanged: root.pick()
        }
        onObjectAdded: root.pick()
        onObjectRemoved: root.pick()
    }

    function pick() {
        const list = Mpris.players.values;
        if (!list || list.length === 0) {
            active = null;
            return;
        }
        const playingNow = list.find(p => p && p.isPlaying);
        if (playingNow) {
            active = playingNow;
            return;
        }
        if (active && list.indexOf(active) >= 0)
            return;
        active = list[0];
    }

    function playPause() {
        if (active)
            active.togglePlaying();
    }
    readonly property real position: {
        root.posTick;
        return active && active.positionSupported ? (active.position ?? 0) : 0;
    }
    readonly property real length: active && active.lengthSupported ? (active.length ?? 0) : 0
    readonly property bool canSeek: active ? !!active.canSeek : false
    readonly property string artUrl: {
        if (!art.length)
            return "";
        if (art.startsWith("file://") || art.startsWith("image://") || art.startsWith("http"))
            return art;
        if (art.startsWith("/"))
            return "file://" + art;
        return "image://icon/" + art;
    }

    function seekTo(sec) {
        if (active && canSeek)
            active.position = Math.max(0, sec);
    }

    function next() {
        if (active)
            active.next();
    }
    function prev() {
        if (active)
            active.previous();
    }

    function raise() {
        if (active && canRaise)
            active.raise();
    }

    function toggleShuffle() {
        if (active && shuffleSupported)
            active.shuffle = !active.shuffle;
    }

    function cycleLoop() {
        if (!active || !loopSupported)
            return;
        if (loop === MprisLoopState.None)
            active.loopState = MprisLoopState.Playlist;
        else if (loop === MprisLoopState.Playlist)
            active.loopState = MprisLoopState.Track;
        else
            active.loopState = MprisLoopState.None;
    }

    function setVolume(v) {
        v = Math.max(0, Math.min(1, v));
        if (v > 0.001)
            lastVol = v;
        if (active && volumeSupported)
            active.volume = v;
        else
            Audio.setVolume(v);
    }

    function nudgeVolume(d) {
        setVolume(volume + d);
    }

    function toggleMute() {
        if (active && volumeSupported) {
            if (volume > 0.001)
                setVolume(0);
            else
                setVolume(lastVol > 0.001 ? lastVol : 0.5);
            return;
        }
        Audio.toggleMute();
    }

    function cycle() {
        const list = Mpris.players.values;
        if (!list || list.length < 2)
            return;
        const i = list.indexOf(active);
        active = list[(i < 0 ? 0 : i + 1) % list.length];
    }

    Component.onCompleted: pick()
}
