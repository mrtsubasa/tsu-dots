pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

/*
 * Micro & visio.
 *  - micro traité : la source par défaut devient `easyeffects_source` (chaîne
 *    d'entrée EasyEffects : réduction de bruit, autogain…). EasyEffects est
 *    démarré en mode service s'il ne tourne pas. Micro brut = dernier micro
 *    physique choisi (ShellCfg.rawMic).
 *  - vumètre : scripts/micmeter.py (pw-record), seulement quand affiché.
 *  - retour d'écoute : pw-loopback source → sortie, pour régler son micro.
 *  - mode visio : NPD, musique en pause, micro traité et actif ; l'état
 *    précédent est restauré en sortie.
 */
Singleton {
    id: root

    readonly property var eeSource: {
        const n = Pipewire.nodes.values || [];
        for (let i = 0; i < n.length; i++)
            if (n[i].name === "easyeffects_source")
                return n[i];
        return null;
    }
    readonly property bool eeAvailable: eeSource !== null
    readonly property bool processed: Audio.defaultSourceName === "easyeffects_source"
    readonly property var rawNode: {
        const ins = Audio.inputs;
        for (let i = 0; i < ins.length; i++)
            if (ins[i].name === ShellCfg.rawMic)
                return ins[i];
        return ins.length ? ins[0] : null;
    }
    property bool starting: false
    property bool wantProcessed: false

    // ---------------- micro traité ----------------
    function setProcessed(on) {
        if (on) {
            if (Audio.defaultSourceName.length && Audio.defaultSourceName !== "easyeffects_source")
                ShellCfg.set("rawMic", Audio.defaultSourceName);
            if (eeSource) {
                Audio.setInput(eeSource);
                return;
            }
            wantProcessed = true;
            starting = true;
            Quickshell.execDetached(["easyeffects", "--service-mode", "--hide-window"]);
            eeTimeout.restart();
        } else {
            wantProcessed = false;
            if (rawNode)
                Audio.setInput(rawNode);
        }
    }
    function toggleProcessed() {
        setProcessed(!processed);
    }
    onEeSourceChanged: {
        if (eeSource && wantProcessed) {
            wantProcessed = false;
            starting = false;
            Audio.setInput(eeSource);
        }
    }
    Timer {
        id: eeTimeout
        interval: 8000
        onTriggered: {
            root.starting = false;
            root.wantProcessed = false;
        }
    }

    // ---------------- vumètre ----------------
    property int meterUsers: 0
    property real level: 0
    property real peakHold: 0
    Process {
        id: meter
        running: root.meterUsers > 0 && Audio.sourceReady
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/catalyst/scripts/micmeter.py", Audio.defaultSourceName]
        stdout: SplitParser {
            onRead: data => {
                const v = Math.min(1, Number(data) || 0);
                root.level = v;
                if (v > root.peakHold)
                    root.peakHold = v;
            }
        }
        onRunningChanged: if (!running) root.level = 0
    }
    Timer {
        interval: 120
        repeat: true
        running: meter.running
        onTriggered: root.peakHold = Math.max(root.level, root.peakHold - 0.03)
    }

    // ---------------- retour d'écoute ----------------
    property bool monitoring: false
    Process {
        id: loop
        running: root.monitoring && Audio.sourceReady
        command: ["pw-loopback", "-n", "catalyst_monitor", "-c", "1", "-m", "[ MONO ]", "-l", "40", "-C", Audio.defaultSourceName]
        onRunningChanged: if (!running) root.monitoring = false
    }

    // ---------------- mode visio ----------------
    property bool callMode: false
    property var _saved: null
    function setCallMode(on) {
        if (on === callMode)
            return;
        if (on) {
            _saved = { dnd: Notifs.dnd, processed: processed, micMuted: Audio.micMuted };
            if (!Notifs.dnd)
                Notifs.toggleDnd();
            Quickshell.execDetached(["playerctl", "-a", "pause"]);
            if (!processed)
                setProcessed(true);
            if (Audio.micMuted)
                Audio.toggleMic();
            callMode = true;
        } else {
            const s = _saved || {};
            if (Notifs.dnd !== !!s.dnd)
                Notifs.toggleDnd();
            if (!s.processed && processed)
                setProcessed(false);
            callMode = false;
            monitoring = false;
        }
    }

    // ---------------- caméra virtuelle OBS ----------------
    function startVirtualCam() {
        Quickshell.execDetached(["sh", "-c", "pgrep -x obs >/dev/null || exec obs --startvirtualcam --minimize-to-tray"]);
    }
}
