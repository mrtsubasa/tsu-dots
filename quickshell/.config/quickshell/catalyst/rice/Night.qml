pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/*
 * Température de l'écran (hyprsunset, possédé par le shell).
 *
 *  True Tone : un PC fixe n'a pas de capteur de lumière ambiante. On l'estime
 *  à partir de la hauteur réelle du soleil (heure + latitude/longitude de la
 *  météo) et de la couverture nuageuse : plein jour ≈ neutre, heure dorée et
 *  crépuscule plus chauds, soirée ≈ éclairage intérieur chaud. Le blanc de
 *  l'écran suit cette estimation, atténuée par `strength`, par petits pas
 *  imperceptibles (≤ 40 K toutes les 2 s).
 *
 *  Lumière nocturne : température fixe (nightTemp), prioritaire sur True Tone.
 *
 *  Réglages persistés dans shell.json (ShellCfg). L'API historique
 *  (on, toggle()) est conservée pour les tuiles et le launcher.
 */
Singleton {
    id: root

    readonly property bool on: ShellCfg.nightLight
    readonly property bool trueTone: ShellCfg.trueTone
    readonly property real strength: ShellCfg.trueToneStrength
    readonly property bool active: on || trueTone

    property real elevation: 0       // degrés au-dessus de l'horizon
    property int ambientK: 6500      // lumière ambiante estimée
    property int targetK: 6500       // blanc visé pour l'écran
    property int currentK: 6500      // blanc appliqué
    property bool ready: false       // hyprsunset prêt à recevoir l'IPC

    readonly property string phase: {
        if (elevation >= 15) return Weather.clouds >= 70 ? "Jour couvert" : "Plein jour";
        if (elevation >= 0) return "Heure dorée";
        if (elevation >= -6) return "Crépuscule";
        return "Soirée · éclairage intérieur";
    }

    function toggle() {
        ShellCfg.set("nightLight", !ShellCfg.nightLight);
    }
    function setTrueTone(v) {
        ShellCfg.set("trueTone", !!v);
    }
    function setStrength(v) {
        ShellCfg.set("trueToneStrength", Math.max(0.1, Math.min(1, v)));
    }
    function setNightTemp(k) {
        ShellCfg.set("nightTemp", Math.round(Math.max(2500, Math.min(5500, k)) / 50) * 50);
    }
    function refresh() {
        recompute();
    }

    // ---- soleil (approximation NOAA, précision ~0,5°) ----
    function sunElevation(ms, lat, lon) {
        const rad = Math.PI / 180;
        const d = ms / 86400000 + 2440587.5 - 2451545.0;
        const g = (357.529 + 0.98560028 * d) % 360;
        const q = (280.459 + 0.98564736 * d) % 360;
        const L = q + 1.915 * Math.sin(g * rad) + 0.020 * Math.sin(2 * g * rad);
        const e = 23.439 - 0.00000036 * d;
        const ra = Math.atan2(Math.cos(e * rad) * Math.sin(L * rad), Math.cos(L * rad)) / rad;
        const dec = Math.asin(Math.sin(e * rad) * Math.sin(L * rad)) / rad;
        const gmst = (18.697374558 + 24.06570982441908 * d) % 24;
        const h = gmst * 15 + lon - ra;
        return Math.asin(Math.sin(lat * rad) * Math.sin(dec * rad) + Math.cos(lat * rad) * Math.cos(dec * rad) * Math.cos(h * rad)) / rad;
    }

    function lerp(a, b, t) {
        return a + (b - a) * Math.max(0, Math.min(1, t));
    }

    function recompute() {
        // repli : nord de la France si la météo n'a pas encore de position
        const lat = Weather.lat || 49.25;
        const lon = Weather.lon || 2.47;
        elevation = sunElevation(Date.now(), lat, lon);
        const e = elevation;
        let k;
        if (e >= 15)
            k = 6500;
        else if (e >= 0)
            k = lerp(5600, 6500, e / 15);
        else if (e >= -6)
            k = lerp(5000, 5600, (e + 6) / 6);
        else
            k = 4900;
        // ciel couvert : lumière du jour plus froide → blanc plus neutre
        if (e >= 0)
            k = Math.min(6500, k + Weather.clouds * 4);
        ambientK = Math.round(k);

        if (on)
            targetK = ShellCfg.nightTemp;
        else if (trueTone)
            targetK = Math.round(6500 - (6500 - ambientK) * strength);
        else
            targetK = 6500;
        step.restart();
    }

    function push(k) {
        if (!ready)
            return;
        if (k >= 6495)
            Quickshell.execDetached(["hyprctl", "hyprsunset", "identity"]);
        else
            Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature", String(k)]);
    }

    onOnChanged: recompute()
    onTrueToneChanged: recompute()
    onStrengthChanged: recompute()
    Connections {
        target: ShellCfg
        function onNightTempChanged() { root.recompute() }
    }
    Connections {
        target: Weather
        function onReadyChanged() { root.recompute() }
        function onCloudsChanged() { root.recompute() }
    }

    // daemon : ne tourne que si un mode est actif (ou le temps de revenir au neutre)
    Process {
        id: daemon
        running: root.active || root.currentK < 6495
        command: ["hyprsunset", "-i"]
        onRunningChanged: {
            if (running) {
                root.currentK = 6500;
                readyT.restart();
            } else {
                root.ready = false;
            }
        }
    }
    Timer {
        id: readyT
        interval: 700
        onTriggered: {
            root.ready = true;
            step.restart();
        }
    }

    // transition : pas fins vers la cible (rapide pour la lumière nocturne)
    Timer {
        id: step
        // grand écart (changement de mode) = transition rapide ~2 s ;
        // petite dérive (soleil) = pas imperceptibles
        readonly property bool big: Math.abs(root.targetK - root.currentK) > 300
        interval: big ? 120 : 2000
        repeat: true
        running: false
        onTriggered: {
            if (!root.ready)
                return;
            const diff = root.targetK - root.currentK;
            if (Math.abs(diff) < 1) {
                stop();
                return;
            }
            const maxStep = step.big ? 150 : 40;
            root.currentK += Math.sign(diff) * Math.min(Math.abs(diff), maxStep);
            root.push(root.currentK);
        }
    }

    // nouvelle estimation toutes les 2 min (le soleil bouge lentement)
    Timer {
        interval: 120000
        repeat: true
        running: root.trueTone
        onTriggered: root.recompute()
    }

    // migration : l'ancienne lumière nocturne utilisait wlsunset
    Process {
        running: true
        command: ["sh", "-c", "pgrep -x wlsunset >/dev/null && pkill -x wlsunset && echo was-on"]
        stdout: SplitParser {
            onRead: data => {
                if (data.trim() === "was-on" && !ShellCfg.nightLight)
                    ShellCfg.set("nightLight", true);
            }
        }
    }

    Component.onCompleted: recompute()
}
