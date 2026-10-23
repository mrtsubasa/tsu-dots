pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    // Durées (ms) — DESIGN-V2 §11
    readonly property int fast: 150      // hover color/border
    readonly property int base: 220      // appear overlay, side shell, toast
    readonly property int slow: 280      // dashboard / launcher / atelier, veil
    readonly property int themeDuration: 400 // crossfade identité
    readonly property int hoverDock: 180
    readonly property int osdIn: 180
    readonly property int osdOut: 120

    // Apparition : translate + fade, jamais de scale
    readonly property int appearDy: 12
    readonly property int appearDx: 16
    readonly property real appearFrom: 0.0

    readonly property bool reduced: Tokens.reducedMotion

    // Easing
    readonly property int ease: Easing.OutCubic
    readonly property int easeInOut: Easing.InOutCubic

    // Durée effective (reduced motion = instantané, opacité seule)
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
