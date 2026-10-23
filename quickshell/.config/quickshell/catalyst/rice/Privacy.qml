pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Vie privée (PipeWire, piloté par événements) : quelles applications
// captent le micro, une caméra ou l'écran en ce moment.
//   micro   : flux « Stream/Input/Audio » (hors EasyEffects / outils internes)
//   écran   : source vidéo du portail Hyprland (xdph) en cours de partage
//   caméra  : flux « Stream/Input/Video » qui ne viennent pas du partage d'écran
// Une application qui ouvre /dev/videoN sans PipeWire n'est pas visible ici.
Singleton {
    id: root

    readonly property var nodes: Pipewire.nodes.values || []

    // PwNodeType (masque) : Audio 1 · Video 2 · Stream 4 · Source 8 · Sink 16
    // capture micro = Audio|Stream|Source (13) ; capture vidéo = Video|Stream|Source
    function flags(n) {
        return Number(n.type) || 0;
    }
    function appOf(n) {
        const p = n.properties || {};
        return p["application.name"] || n.description || n.name || "Application";
    }
    function internal(n) {
        const name = String(n.name || "").toLowerCase();
        return name.startsWith("ee_") || name.startsWith("easyeffects") || name.startsWith("catalyst_")
            || name.indexOf("pavucontrol") >= 0 || name.indexOf("quickshell") >= 0;
    }
    function uniq(list) {
        const out = [];
        for (let i = 0; i < list.length; i++)
            if (out.indexOf(list[i]) < 0)
                out.push(list[i]);
        return out;
    }

    readonly property bool screenShare: nodes.some(n => String(n.name || "").indexOf("xdph") >= 0 && (flags(n) & 2))

    readonly property var micApps: uniq(nodes.filter(n => flags(n) === 13 && !internal(n)).map(appOf))
    readonly property var videoStreams: nodes.filter(n => (flags(n) & 14) === 14 && !internal(n))
    readonly property var screenApps: screenShare ? uniq(videoStreams.map(appOf)) : []
    readonly property var cameraApps: screenShare ? [] : uniq(videoStreams.map(appOf))

    readonly property bool micInUse: micApps.length > 0
    readonly property bool cameraInUse: cameraApps.length > 0
    readonly property bool any: micInUse || cameraInUse || screenShare

    readonly property string summary: {
        const parts = [];
        if (micInUse)
            parts.push("Micro : " + micApps.join(", "));
        if (cameraInUse)
            parts.push("Caméra : " + cameraApps.join(", "));
        if (screenShare)
            parts.push("Écran partagé" + (screenApps.length ? " : " + screenApps.join(", ") : ""));
        return parts.join("  ·  ");
    }

    // Ne pas déranger automatique pendant un partage d'écran (évite d'exposer
    // des notifications en démo / stream). Restauré à la fin du partage.
    property bool _autoDnd: false
    onScreenShareChanged: {
        if (!ShellCfg.dndOnShare)
            return;
        if (screenShare && !Notifs.dnd) {
            Notifs.toggleDnd();
            _autoDnd = true;
        } else if (!screenShare && _autoDnd) {
            if (Notifs.dnd)
                Notifs.toggleDnd();
            _autoDnd = false;
        }
    }
}
