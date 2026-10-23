pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    readonly property bool sinkReady: sink !== null && sink.audio !== null
    readonly property bool sourceReady: source !== null && source.audio !== null
    readonly property bool muted: sinkReady ? (sink.audio.muted ?? false) : false
    readonly property bool micMuted: sourceReady ? (source.audio.muted ?? false) : true
    readonly property string sinkName: sinkReady ? (sink.description || sink.name || "sortie audio") : "sortie audio"
    // amplification autorisée jusqu'à 150 % (même limite que les raccourcis wpctl -l 1.5)
    readonly property real maxVolume: 1.5
    readonly property real volume: {
        if (!sinkReady)
            return 0;
        return Math.max(0, Math.min(maxVolume, sink.audio.volume));
    }
    readonly property real micVolume: sourceReady ? Math.max(0, Math.min(maxVolume, source.audio.volume)) : 0
    readonly property int percentage: Math.round(volume * 100)

    readonly property string glyph: {
        if (!sinkReady || muted || volume <= 0)
            return "󰝟";
        if (volume < 0.34)
            return "󰕿";
        if (volume < 0.67)
            return "󰖀";
        return "󰕾";
    }

    // ------------------------------------------------------------------
    // Périphériques PipeWire (sélecteur de sortie / entrée)
    // ------------------------------------------------------------------
    readonly property var nodes: Pipewire.nodes.values || []
    function isReal(n) {
        const nm = (n && n.name) ? String(n.name) : "";
        return nm.startsWith("alsa_output.") || nm.startsWith("bluez_output.")
            || nm.startsWith("alsa_input.") || nm.startsWith("bluez_input.");
    }
    readonly property var outputs: {
        const out = [];
        for (let i = 0; i < nodes.length; i++) {
            const n = nodes[i];
            if (n && n.isSink && !n.isStream && isReal(n))
                out.push(n);
        }
        return out;
    }
    readonly property var inputs: {
        const out = [];
        for (let i = 0; i < nodes.length; i++) {
            const n = nodes[i];
            if (n && !n.isSink && !n.isStream && isReal(n))
                out.push(n);
        }
        return out;
    }
    readonly property string inputName: sourceReady ? (source.description || source.name || "micro") : "micro"
    readonly property string activeInput: sourceReady ? (source.id || "") : ""
    readonly property string activeOutput: sinkReady ? (sink.id || "") : ""

    function nodeLabel(n) {
        if (!n)
            return "";
        const d = n.nickname && n.nickname.length ? n.nickname : (n.description || n.name || "");
        return d;
    }

    function setOutput(node) {
        if (!node)
            return;
        try {
            Pipewire.preferredDefaultAudioSink = node;
        } catch (e) {
            console.log("[Audio] setOutput KO:", e);
        }
    }

    function setInput(node) {
        if (!node)
            return;
        try {
            Pipewire.preferredDefaultAudioSource = node;
        } catch (e) {
            console.log("[Audio] setInput KO:", e);
        }
    }

    signal changed

    onVolumeChanged: changed()
    onMutedChanged: changed()

    function setVolume(v) {
        if (!sinkReady)
            return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(maxVolume, v));
    }

    function setMicVolume(v) {
        if (!sourceReady)
            return;
        source.audio.muted = false;
        source.audio.volume = Math.max(0, Math.min(maxVolume, v));
    }

    function toggleMute() {
        if (sinkReady)
            sink.audio.muted = !sink.audio.muted;
    }

    function toggleMic() {
        if (sourceReady)
            source.audio.muted = !source.audio.muted;
    }

    function nudge(delta) {
        setVolume(volume + delta);
    }
}
