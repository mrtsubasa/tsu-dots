pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    // Quickshell ignore les sources virtuelles (EasyEffects) comme source par
    // défaut : on suit le nom réel (pactl) et on retrouve le nœud nous-mêmes.
    property string defaultSourceName: ""
    readonly property var source: {
        const d = Pipewire.defaultAudioSource;
        if (d && (!defaultSourceName.length || d.name === defaultSourceName))
            return d;
        const n = Pipewire.nodes.values || [];
        for (let i = 0; i < n.length; i++)
            if (n[i].name === defaultSourceName)
                return n[i];
        return d;
    }

    // Quickshell plante si le tracker reçoit un nœud pendant sa suppression (micro
    // USB recréé en boucle par WirePlumber) : on met à jour après coup, nœuds vivants seulement.
    readonly property var trackWanted: [sink, source, mic]
    property var tracked: []
    onTrackWantedChanged: trackTimer.restart()

    Timer {
        id: trackTimer
        interval: 150
        running: true
        onTriggered: {
            const live = Pipewire.nodes.values || [];
            root.tracked = root.trackWanted.filter(n => n && live.indexOf(n) >= 0);
        }
    }

    PwObjectTracker {
        objects: root.tracked
    }

    readonly property bool sinkReady: sink !== null && sink.audio !== null
    // micro réellement réglable : la source par défaut si elle expose son audio,
    // sinon (source virtuelle EasyEffects) le micro physique qui l'alimente
    readonly property var mic: {
        if (source && source.audio)
            return source;
        const ins = inputs;
        for (let i = 0; i < ins.length; i++)
            if (ins[i].name === ShellCfg.rawMic)
                return ins[i];
        return ins.length ? ins[0] : source;
    }
    readonly property bool sourceReady: mic !== null && mic !== undefined && mic.audio !== null
    readonly property bool muted: sinkReady ? (sink.audio.muted ?? false) : false
    readonly property bool micMuted: sourceReady ? (mic.audio.muted ?? false) : true
    readonly property string sinkName: sinkReady ? (sink.description || sink.name || "sortie audio") : "sortie audio"
    // amplification autorisée jusqu'à 150 % (même limite que les raccourcis wpctl -l 1.5)
    readonly property real maxVolume: 1.5
    readonly property real volume: {
        if (!sinkReady)
            return 0;
        return Math.max(0, Math.min(maxVolume, sink.audio.volume));
    }
    readonly property real micVolume: sourceReady ? Math.max(0, Math.min(maxVolume, mic.audio.volume)) : 0
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
    readonly property string inputName: sourceReady ? ((source && source.name === "easyeffects_source" ? "EasyEffects · " : "") + (mic.description || mic.name || "micro")) : "micro"
    readonly property string activeInput: source ? (source.id || "") : ""
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
        setInputName(node.name);
    }
    function setInputName(name) {
        if (!name)
            return;
        defaultSourceName = name;
        Quickshell.execDetached(["pactl", "set-default-source", name]);
    }

    function refreshDefaults() {
        srcQuery.running = true;
    }
    Process {
        id: srcQuery
        command: ["pactl", "get-default-source"]
        stdout: SplitParser { onRead: data => root.defaultSourceName = data.trim() }
    }
    // événements serveur PulseAudio/PipeWire → relit la source par défaut
    Process {
        running: true
        command: ["pactl", "subscribe"]
        stdout: SplitParser {
            onRead: data => {
                if (data.indexOf("on server") >= 0 && !debounce.running)
                    debounce.start();
            }
        }
    }
    Timer {
        id: debounce
        interval: 150
        onTriggered: root.refreshDefaults()
    }
    Component.onCompleted: refreshDefaults()

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
        mic.audio.muted = false;
        mic.audio.volume = Math.max(0, Math.min(maxVolume, v));
    }

    function toggleMute() {
        if (sinkReady)
            sink.audio.muted = !sink.audio.muted;
    }

    function toggleMic() {
        if (sourceReady)
            mic.audio.muted = !mic.audio.muted;
    }

    function nudge(delta) {
        setVolume(volume + delta);
    }
}
