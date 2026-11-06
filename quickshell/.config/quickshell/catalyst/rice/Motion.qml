pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

/*
 * Motion — langage d'animation Catalyst v3.
 * Rapide, décéléré, jamais de rebond. Les panneaux glissent de 8–12 px
 * depuis leur point d'ancrage en fondu ; aucun mouvement décoratif continu.
 */
Singleton {
    id: root

    // Durées (ms)
    readonly property int instant: 90     // état pressé
    readonly property int fast: 140       // hover, couleur, bordure
    readonly property int base: 200       // ouverture popover / toast
    readonly property int slow: 260       // panneau plein (centre de contrôle, launcher)
    readonly property int themeDuration: 400
    readonly property int hoverDock: 160
    readonly property int osdIn: 160
    readonly property int osdOut: 220

    // Apparition : translation + fondu
    readonly property int appearDy: 10
    readonly property int appearDx: 14
    readonly property real appearFrom: 0.0

    readonly property bool reduced: Tokens.reducedMotion

    // Easing (compat)
    readonly property int ease: Easing.OutCubic
    readonly property int easeInOut: Easing.InOutCubic

    // Courbes de Bézier (easing.type: Easing.BezierSpline)
    // standard : déplacements dans un même plan
    readonly property var curveStd: [0.2, 0, 0, 1, 1, 1]
    // emphasized decelerate : entrée de surfaces
    readonly property var curveIn: [0.05, 0.7, 0.1, 1, 1, 1]
    // accelerate : sortie de surfaces
    readonly property var curveOut: [0.3, 0, 0.8, 0.15, 1, 1]

    // --- Material 3 Expressive : ressort doux pour l'ouverture des panneaux ---
    // (le « feel » caelestia : dépliage avec léger dépassement élastique)
    // Désactivé automatiquement en mouvement réduit.
    property bool springPanels: !reduced
    readonly property int springIn: 460            // durée d'entrée ressort
    readonly property int springOut: 320           // sortie (sans rebond)
    // spatial par défaut (0.38, 1.21, …) : le 1.21 > 1 crée le dépassement
    readonly property var curveSpring: [0.38, 1.21, 0.22, 1, 1, 1]
    // spatial rapide, rebond plus marqué (petits éléments)
    readonly property var curveSpringFast: [0.42, 1.67, 0.21, 0.9, 1, 1]

    // Durée effective (reduced motion = quasi instantané, opacité seule)
    function dur(ms) {
        return reduced ? 1 : ms;
    }

    function dy(px) {
        return reduced ? 0 : px;
    }

    function dx(px) {
        return reduced ? 0 : px;
    }
}
