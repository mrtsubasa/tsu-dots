import QtQuick
import qs.rice

// Surface transitoire animée (centre de contrôle, calendrier, launcher…).
// open → entrée décélérée (glisse depuis `from` + fondu) ; fermeture plus
// courte, accélérée. `shown` reste vrai pendant la sortie pour que la fenêtre
// hôte ne disparaisse pas avant la fin de l'animation.
Item {
    id: root

    property bool open: false
    property string from: "top"      // top | bottom | left | right | center
    property real distance: Motion.appearDy
    property alias pane: surface
    property real radius: Tokens.rXl
    property bool glow: true
    default property alias content: surface.content

    // ressort expressif (façon caelestia) ; se replie proprement sans rebond
    property bool spring: Motion.springPanels
    property real progress: open ? 1 : 0
    readonly property bool shown: progress > 0.001

    Behavior on progress {
        NumberAnimation {
            duration: Motion.dur(root.open ? (root.spring ? Motion.springIn : Motion.slow) : (root.spring ? Motion.springOut : Motion.base))
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.open ? (root.spring ? Motion.curveSpring : Motion.curveIn) : Motion.curveOut
        }
    }

    visible: shown
    opacity: Math.min(1, progress * 1.4)
    // base < 1 quand ressort → léger « pop » à l'ouverture (dépassement inclus)
    readonly property real scaleFrom: from === "center" ? (spring ? 0.92 : 0.97) : (spring ? 0.985 : 1)
    scale: scaleFrom + (1 - scaleFrom) * progress
    transform: Translate {
        x: root.from === "left" ? -(1 - root.progress) * Motion.dx(root.distance) : (root.from === "right" ? (1 - root.progress) * Motion.dx(root.distance) : 0)
        y: root.from === "top" ? -(1 - root.progress) * Motion.dy(root.distance) : (root.from === "bottom" ? (1 - root.progress) * Motion.dy(root.distance) : 0)
    }

    // absorbe les clics : un clic dans la surface ne ferme jamais le panneau
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onWheel: wheel => wheel.accepted = true
    }

    Pane {
        id: surface
        anchors.fill: parent
        level: 2
        radius: root.radius
        shadow: true
        glow: root.glow
    }
}
