pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/*
 * Equalizer — pont vers EasyEffects 8.3.
 *
 * Deux niveaux :
 *   1. État « marche/arrêt » + courbe  → ~/.config/easyeffects/db/easyeffectsrc
 *                                        (plugins= de [StreamOutputs])
 *                                        + ~/.config/easyeffects/db/equalizerrc
 *                                        (groupe [soe][Equalizer#0])
 *   2. Préréglages réutilisables      → ~/.local/share/easyeffects/output/*.json
 *                                        (format natif EE, visible dans son menu)
 *
 * EasyEffects ne rechargement pas sa configuration à chaud : les fichiers sont
 * écrits en continu, mais l'application effective demande un redémarrage
 * d'EasyEffects (bouton dédié, action explicite).
 */
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string eeDir: home + "/.config/easyeffects"
    readonly property string cfgPath: eeDir + "/db/easyeffectsrc"
    readonly property string dbPath: eeDir + "/db/equalizerrc"
    readonly property string presetsDir: home + "/.local/share/easyeffects/output"

    readonly property var freqs: [31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
    property var gains: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    property bool enabled: false
    property string note: ""
    property string savedName: ""
    property string cfgText: ""
    property bool cfgReady: false
    readonly property bool rawLoaded: cfgFile.loaded
    property bool pendingValid: false
    property bool pendingEnable: false

    // EasyEffects tourne-t-il ? (noeud virtuel easyeffects_* présent)
    readonly property bool eeRunning: {
        const v = Audio.nodes || [];
        for (let i = 0; i < v.length; i++) {
            const n = String((v[i] && v[i].name) || "");
            if (n.startsWith("easyeffects_"))
                return true;
        }
        return false;
    }

    readonly property var curves: [
        { id: "plat", label: "Plat", g: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0] },
        { id: "basses", label: "Basses", g: [6, 5, 3.5, 1.5, 0, -1, -1.5, -1, 0, 1] },
        { id: "voix", label: "Voix", g: [-3, -2.5, -1, 0, 2, 3.5, 3, 1.5, 0, -1] },
        { id: "cinema", label: "Cinéma", g: [5, 4, 2, 0, -1, -0.5, 1, 2.5, 4, 4.5] }
    ]

    function section(t, name) {
        const m = String(t || "").match(new RegExp("\\[" + name + "\\]([\\s\\S]*?)(\\n\\[|$)"));
        return m ? m[1] : "";
    }

    function parseCfg(t) {
        const sec = section(t, "StreamOutputs");
        const m = sec.match(/(^|\n)plugins=([^\n]*)/);
        if (!m) {
            enabled = false;
            return;
        }
        const list = m[2].split(",").map(x => x.trim()).filter(x => x.length);
        enabled = list.indexOf("equalizer#0") >= 0;
    }

    function parseEq(t) {
        const g = [];
        for (let i = 0; i < 10; i++) {
            const m = String(t || "").match(new RegExp("band" + i + "Gain=([-0-9.]+)"));
            g.push(m ? parseFloat(m[1]) : 0);
        }
        gains = g;
    }

    // ------------------------------------------------------------------
    // Écriture
    // ------------------------------------------------------------------
    function shellEscape(str) {
        return "'" + String(str).replace(/'/g, "'\\''") + "'";
    }

    function writeFile(path, body, cb) {
        if (!String(body || "").trim().length) {
            note = "Écriture annulée : source vide.";
            console.log("[Equalizer] écriture annulée (source vide) :", path);
            return false;
        }
        writeProc._cb = cb || null;
        const tmp = path + ".catalyst-tmp";
        writeProc.command = ["bash", "-c",
            "mkdir -p " + shellEscape(path.substring(0, path.lastIndexOf("/"))) + "\n"
            + "cat > " + shellEscape(tmp) + " << 'EOF'\n" + body
            + "EOF\n"
            + "mv -f " + shellEscape(tmp) + " " + shellEscape(path)];
        writeProc._path = path;
        writeProc._body = body;
        writeProc.running = true;
        return true;
    }

    function patchPlugins(t, on) {
        const lines = String(t || "").split("\n");
        const out = [];
        let sec = "";
        let patched = false;
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            const s = line.trim();
            if (s.length > 2 && s.startsWith("[") && s.endsWith("]")) {
                sec = s.substring(1, s.length - 1);
                out.push(line);
                if (on && !patched && sec === "StreamOutputs") {
                    out.push("plugins=equalizer#0");
                    patched = true;
                }
                continue;
            }
            if (sec === "StreamOutputs" && s.startsWith("plugins=")) {
                patched = true;
                if (!on)
                    continue;
                let list = s.substring(8).split(",").map(x => x.trim()).filter(x => x.length);
                if (list.indexOf("equalizer#0") < 0)
                    list.push("equalizer#0");
                out.push("plugins=" + list.join(","));
                continue;
            }
            out.push(line);
        }
        if (on && !patched)
            out.push("plugins=equalizer#0");
        return out.join("\n");
    }

    function dbBody() {
        const L = [];
        L.push("[soe][Equalizer#0]");
        L.push("bypass=false");
        L.push("mode=IIR");
        L.push("numBands=10");
        L.push("inputGain=0");
        L.push("outputGain=0");
        L.push("balance=0");
        L.push("pitchLeft=0");
        L.push("pitchRight=0");
        L.push("splitChannels=false");
        L.push("decramp=x2");
        for (let i = 0; i < 10; i++) {
            L.push("band" + i + "Frequency=" + freqs[i]);
            L.push("band" + i + "Gain=" + gains[i]);
            L.push("band" + i + "Q=4.36");
            L.push("band" + i + "Type=Bell");
            L.push("band" + i + "Mode=RLC (BT)");
            L.push("band" + i + "Mute=false");
            L.push("band" + i + "Solo=false");
            L.push("band" + i + "Slope=x1");
            L.push("band" + i + "Width=4");
        }
        L.push("");
        return L.join("\n");
    }

    function setEnabled(v) {
        const on = !!v;
        if (!cfgReady) {
            cfgFile.reload();
            pendingEnable = on;
            pendingValid = true;
            retryTimer.restart();
            note = "Lecture du fichier EasyEffects…";
            return;
        }
        pendingValid = false;
        const body = patchPlugins(cfgText, on);
        if (!writeFile(cfgPath, body, null))
            return;
        enabled = on;
        cfgText = body;
        cfgReady = true;
        if (on) {
            writeFile(dbPath, dbBody(), null);
            note = eeRunning ? "EasyEffects doit être relancé." : "Actif au prochain démarrage d'EasyEffects.";
        } else {
            note = "";
        }
    }

    function writeDb() {
        if (!enabled)
            return;
        writeFile(dbPath, dbBody(), null);
    }

    function setGain(i, v) {
        if (i < 0 || i > 9)
            return;
        const g = gains.slice();
        g[i] = Math.max(-12, Math.min(12, Math.round(v * 2) / 2));
        gains = g;
        dbTimer.restart();
    }

    function applyCurve(id) {
        for (let i = 0; i < curves.length; i++) {
            if (curves[i].id === id) {
                gains = curves[i].g.slice();
                if (enabled)
                    writeDb();
                else
                    note = "Activez l'égaliseur pour appliquer.";
                return;
            }
        }
    }

    function fmtFreq(f) {
        return f >= 1000 ? (f / 1000) + "k" : String(f);
    }

    function fmtGain(g) {
        return (g > 0 ? "+" : "") + g.toFixed(g % 1 ? 1 : 0);
    }

    // ------------------------------------------------------------------
    // Préréglages EE (format natif)
    // ------------------------------------------------------------------
    function bandMap() {
        const out = {};
        for (let i = 0; i < 10; i++) {
            out["band" + i] = {
                frequency: freqs[i],
                gain: gains[i],
                mode: "RLC (BT)",
                mute: false,
                q: 4.36,
                slope: "x1",
                solo: false,
                type: "Bell",
                width: 4
            };
        }
        return out;
    }

    function presetBody() {
        const bands = bandMap();
        return JSON.stringify({
            output: {
                blocklist: [],
                plugins_order: enabled ? ["equalizer#0"] : [],
                "equalizer#0": {
                    balance: 0,
                    bypass: false,
                    decramp: "x2",
                    "input-gain": 0,
                    left: bands,
                    mode: "IIR",
                    "num-bands": 10,
                    "output-gain": 0,
                    "pitch-left": 0,
                    "pitch-right": 0,
                    right: bands,
                    "split-channels": false
                }
            }
        }, null, 2) + "\n";
    }

    function savePreset(label) {
        const name = String(label || "").trim();
        if (!name.length)
            return "";
        const slug = name.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
        writeFile(presetsDir + "/" + (slug || "catalyst") + ".json", presetBody(), function () {
            savedName = name;
            note = "Préréglage « " + name + " » enregistré.";
            listProc._buf = "";
            listProc.running = true;
        });
        return name;
    }

    function loadPreset(name) {
        const n = String(name || "").trim();
        if (!n.length)
            return;
        loadProc._name = n;
        loadProc._buf = "";
        loadProc.command = ["cat", presetsDir + "/" + n + ".json"];
        loadProc.running = true;
    }

    function reloadCfg() {
        cfgFile.reload();
    }

    function restartEE() {
        note = "Redémarrage d'EasyEffects…";
        Quickshell.execDetached(["bash", "-c", "pkill -x easyeffects || true; sleep 1; setsid easyeffects >/dev/null 2>&1 &"]);
        restartTimer.restart();
    }

    // ------------------------------------------------------------------
    // Fichiers / processus
    // ------------------------------------------------------------------
    FileView {
        id: cfgFile
        path: root.cfgPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            root.cfgText = text();
            root.cfgReady = true;
            root.parseCfg(root.cfgText);
        }
    }

    FileView {
        id: dbFile
        path: root.dbPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parseEq(text())
    }

    Timer {
        id: dbTimer
        interval: 400
        onTriggered: root.writeDb()
    }

    Timer {
        id: restartTimer
        interval: 3500
        onTriggered: {
            root.note = root.eeRunning ? "EasyEffects relancé." : "EasyEffects ne semble pas démarré.";
            cfgFile.reload();
            dbFile.reload();
        }
    }

    Timer {
        id: retryTimer
        interval: 250
        onTriggered: {
            if (root.pendingValid) {
                const v = root.pendingEnable;
                root.pendingValid = false;
                root.setEnabled(v);
            }
        }
    }

    Process {
        id: loadProc
        property string _name: ""
        property string _buf: ""
        stdout: SplitParser {
            onRead: data => loadProc._buf += data
        }
        onExited: {
            try {
                const d = JSON.parse(loadProc._buf || "{}");
                const eq = d.output ? d.output["equalizer#0"] : null;
                const left = eq ? eq.left : null;
                if (!left)
                    throw new Error("pas de equalizer#0");
                const g = [];
                for (let i = 0; i < 10; i++) {
                    const b = left["band" + i];
                    g.push(b ? (b.gain || 0) : 0);
                }
                gains = g;
                note = "Préréglage « " + loadProc._name + " » chargé.";
                if (enabled)
                    writeDb();
            } catch (e) {
                note = "Lecture impossible : " + loadProc._name;
                console.log("[Equalizer] loadPreset", e);
            }
        }
    }

    Process {
        id: writeProc
        property var _cb: null
        property string _path: ""
        property string _body: ""
        onExited: {
            if (exitCode !== 0) {
                root.note = "Échec d'écriture (" + _path + ").";
                console.log("[Equalizer] écriture échouée", exitCode, _path);
                _cb = null;
                return;
            }
            if (_path === root.cfgPath) {
                root.cfgText = _body;
                root.cfgReady = true;
            }
            if (_cb)
                _cb();
            _cb = null;
        }
    }

    property var presets: []
    property bool presetsReady: false

    function refreshPresets() {
        listProc._buf = "";
        listProc.running = true;
    }

    Process {
        id: listProc
        property string _buf: ""
        command: ["bash", "-c", "for f in '" + root.presetsDir + "'/*.json; do [ -f \"$f\" ] || continue; basename \"$f\" .json; done"]
        stdout: SplitParser {
            onRead: data => listProc._buf += data + "\n"
        }
        onExited: {
            const out = [];
            const lines = listProc._buf.split("\n");
            for (let i = 0; i < lines.length; i++) {
                const s = lines[i].trim();
                if (s.length)
                    out.push(s);
            }
            root.presets = out;
            root.presetsReady = true;
        }
    }

    Component.onCompleted: refreshPresets()
}
