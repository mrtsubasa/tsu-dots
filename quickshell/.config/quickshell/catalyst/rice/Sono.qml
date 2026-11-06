pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/*
 * Sono — pilote le moteur de VoxMix par son socket de contrôle, sans processus
 * par mise à jour. Lancé à l'allumage, arrêté à l'extinction : éteint, VoxMix ne
 * tient plus le micro. La fenêtre du mixeur peut reprendre le moteur à tout moment.
 */
Singleton {
    id: root

    readonly property string binary: Quickshell.env("HOME") + "/.local/bin/voxmix"
    readonly property bool panelOpen: PanelService.active === "sono"
    readonly property bool running: sock.connected

    property var state: null
    readonly property bool on: running && state !== null && state.on === true
    readonly property bool muted: running && state !== null && state.muted === true
    readonly property string host: state ? state.host : ""
    readonly property string scene: state && state.scene ? state.scene : ""
    readonly property var scenes: state && state.scenes ? state.scenes : ["Salon", "Bar", "Club", "Hangar", "Stade"]
    // tout le son du PC passe dans la sono : la sortie par défaut est celle de VoxMix
    readonly property var labEffects: state && state.lab ? state.lab : []
    readonly property var voiceGroups: state && state.voiceGroups ? state.voiceGroups : []
    readonly property bool systemWide: running && Audio.sink !== null && String(Audio.sink.name).startsWith("voxmix_")
    readonly property string systemScript: Quickshell.env("HOME") + "/.config/quickshell/catalyst/scripts/sono-system.sh"
    property string error: ""
    property bool starting: false
    // VoxMix lancé avant cette version : il faut l'éteindre et le rallumer
    readonly property bool outdated: state !== null && (state.version || 0) < 15
    readonly property var mic: state && state.mic ? state.mic : null

    // niveau du micro en dB, retombe doucement pour rester lisible
    property real micDb: -90
    property string tab: "sono"

    function toDb(v) {
        return 20 * Math.log(Math.max(v, 1e-5)) / Math.LN10;
    }

    // TAP : l'écho se cale sur le tempo tapé (croche pointée, l'écho classique des DJ)
    property var _taps: []
    property real bpm: 0
    function tap() {
        const now = Date.now();
        let t = _taps.length && now - _taps[_taps.length - 1] > 2000 ? [] : _taps.slice();
        t.push(now);
        t = t.slice(-5);
        _taps = t;
        if (t.length >= 2) {
            const beat = (now - t[0]) / (t.length - 1);
            bpm = 60000 / beat;
            set("echo.time", Math.max(10, Math.min(2000, beat * 0.75)));
        }
    }

    // ---- calibration : quelques secondes de silence, puis de voix ----
    property string calibPhase: ""      // "" | silence | voix
    property real calibLeft: 0
    property string calibResult: ""
    property var _calibNoise: []
    property var _calibVoice: []
    readonly property int calibSilenceMs: 3000
    readonly property int calibVoiceMs: 6000

    function percentile(list, q) {
        const sorted = list.slice().sort((a, b) => a - b);
        return sorted[Math.min(sorted.length - 1, Math.floor(sorted.length * q))];
    }

    function startCalibration() {
        calibResult = "";
        _calibNoise = [];
        _calibVoice = [];
        calibPhase = "silence";
        calibTimer.interval = calibSilenceMs;
        calibTimer.restart();
    }

    function finishCalibration(noise, voice) {
        const noiseDb = percentile(noise, 0.9);
        const voiceDb = percentile(voice, 0.95);
        if (voiceDb < noiseDb + 10) {
            calibResult = "Ta voix ressort trop peu du bruit (" + Math.round(voiceDb) + " dB contre " + Math.round(noiseDb) + " dB). Rapproche-toi du micro et recommence.";
            return false;
        }
        const gain = Math.max(-12, Math.min(24, -12 - voiceDb));
        // Le seuil s'ouvre au-dessus du bruit, et toujours bien en dessous de la voix.
        const gate = Math.max(-70, Math.min(-24, noiseDb + gain + 6));
        set("mic.gain", gain);
        set("mic.gate", gate);
        send({ cmd: "mic.fx", fx: "gate", on: true });
        calibResult = "Réglé : gain " + (gain > 0 ? "+" : "") + gain.toFixed(1) + " dB, seuil " + gate.toFixed(0) + " dB.";
        return true;
    }

    Timer {
        id: calibTimer
        onTriggered: {
            if (root.calibPhase === "silence") {
                root.calibPhase = "voix";
                interval = root.calibVoiceMs;
                restart();
            } else {
                root.calibPhase = "";
                root.finishCalibration(root._calibNoise, root._calibVoice);
            }
        }
    }

    // ---- test de voix ----
    property string voiceTest: ""       // "" | record | play
    readonly property string micScript: Quickshell.env("HOME") + "/.config/quickshell/catalyst/scripts/sono-mictest.sh"
    readonly property int voiceTestSeconds: 5
    function testVoice() {
        if (voiceTest.length || !running)
            return;
        error = "";
        voiceTest = "record";
        const p = testC.createObject(root, { command: [micScript, "record", String(voiceTestSeconds)], next: true });
        p.running = true;
    }

    // ---- applis qui écoutent un micro ----
    property var micUsers: []
    Process {
        id: whoProc
        property string buf: ""
        command: [root.micScript, "who"]
        stdout: SplitParser { onRead: data => whoProc.buf += data }
        onExited: {
            try { root.micUsers = JSON.parse(whoProc.buf); } catch (e) {}
            whoProc.buf = "";
        }
    }
    Timer {
        interval: 3000
        repeat: true
        running: root.panelOpen
        triggeredOnStart: true
        onTriggered: whoProc.running = true
    }

    Component {
        id: testC
        Process {
            property bool next: false
            stderr: SplitParser { onRead: data => root.error = data }
            onExited: code => {
                // pw-record arrêté par timeout finit en 124 : c'est le cas normal.
                if (next && (code === 0 || code === 124)) {
                    root.voiceTest = "play";
                    const p = testC.createObject(root, { command: [root.micScript, "play"], next: false });
                    p.running = true;
                } else {
                    root.voiceTest = "";
                }
                destroy();
            }
        }
    }

    function _collectMic() {
        if (!mic)
            return;
        const db = toDb(mic.input);
        micDb = Math.max(db, micDb - 1.5);
        if (calibPhase === "silence")
            _calibNoise.push(db);
        else if (calibPhase === "voix")
            _calibVoice.push(db);
    }

    property int _powerRetries: 0
    readonly property int maxRetries: 12

    function send(obj) {
        if (!sock.connected)
            return;
        sock.write(JSON.stringify(obj) + "\n");
        sock.flush();
    }

    function set(key, value) {
        send({ cmd: "set", key: key, value: value });
    }
    function setScene(name) { send({ cmd: "scene", name: name }); }
    function setMuted(on) { send({ cmd: "mute", on: on }); }
    function setThrow(on) { send({ cmd: "throw", on: on }); }
    function setCut(on) { send({ cmd: "cut", on: on }); }

    function powerOn() {
        error = "";
        _powerRetries = maxRetries;
        if (sock.connected) {
            send({ cmd: "power", on: true });
            return;
        }
        starting = true;
        Quickshell.execDetached([binary, "--headless"]);
        reconnect.restart();
    }

    function _system(action) {
        const p = systemC.createObject(root, { command: [systemScript, action] });
        p.running = true;
    }

    function setSystemWide(on) {
        _system(on ? "on" : "off");
    }

    function powerOff() {
        _powerRetries = 0;
        _system("stop");
        send({ cmd: "power", on: false });
        // Seul le moteur en arrière-plan s'arrête : la fenêtre, elle, reste ouverte.
        if (host === "headless")
            send({ cmd: "quit" });
    }

    function openMixer() {
        PanelService.hide();
        Quickshell.execDetached([binary]);
    }

    function _onReply(r) {
        if (r.cmd === "state") {
            state = r;
            _collectMic();
            return;
        }
        if (r.cmd === "power" && !r.ok && _powerRetries > 0) {
            // Au premier lancement, micro et casque ne sont connus qu'après un instant.
            _powerRetries--;
            if (_powerRetries > 0) {
                powerRetry.restart();
                return;
            }
        }
        if (r.cmd === "power" && r.ok && _powerRetries > 0) {
            _powerRetries = 0;
            _system("auto");
        }
        if (!r.ok)
            error = r.error || "VoxMix a refusé la commande";
    }

    Component {
        id: systemC
        Process {
            stderr: SplitParser { onRead: data => root.error = data }
            onExited: destroy()
        }
    }

    Socket {
        id: sock
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/voxmix.sock"
        parser: SplitParser {
            onRead: data => {
                let r = null;
                try { r = JSON.parse(data); } catch (e) {}
                if (r)
                    root._onReply(r);
            }
        }
        onConnectedChanged: {
            root.starting = false;
            if (connected) {
                root.error = "";
                if (root._powerRetries > 0)
                    root.send({ cmd: "power", on: true });
                root.send({ cmd: "state" });
            } else {
                root.state = null;
            }
        }
    }

    Timer {
        id: powerRetry
        interval: 500
        onTriggered: root.send({ cmd: "power", on: true })
    }

    // connexion : réessai lent au repos (pour le voyant de la barre), rapide au démarrage
    Timer {
        id: reconnect
        interval: root.starting ? 150 : 4000
        repeat: true
        running: !sock.connected
        triggeredOnStart: true
        onTriggered: sock.connected = true
    }

    Timer {
        interval: root.panelOpen ? 66 : 2000
        repeat: true
        running: sock.connected
        onTriggered: root.send({ cmd: "state" })
    }
}
