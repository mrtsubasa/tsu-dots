pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property string st: Theme.uiStyle
    readonly property bool preset: ["catalyst", "protocol", "pulse", "apple", "islands", "silverwolf", "lain", "tsubasa", "initiald", "brume", "signal", "eclipse"].indexOf(st) >= 0

    readonly property bool islands: Tokens.barIslands
    readonly property bool continuous: !islands

    // --- géométrie : source = tokens/themes/<id>.json + densité ---
    readonly property int radius: Tokens.rLg
    readonly property int islandRadius: Tokens.rLg
    readonly property int borderW: Tokens.hairline
    readonly property int barHeight: Tokens.barHeight
    readonly property real barOpacity: Tokens.barOpacity
    readonly property int marginTop: Tokens.marginTop
    readonly property int marginX: Tokens.marginX
    readonly property int groupPad: Tokens.s2
    readonly property int exclusive: Tokens.exclusive
    readonly property bool blurBackdrop: Tokens.blurBackdrop

    // --- motion (compat anciens appels) ---
    readonly property int motion: Motion.slow
    readonly property int motionFast: Motion.fast

    // --- filets d'identité (barre seulement) ---
    readonly property color borderC: {
        if (st === "lain") return Qt.alpha(Theme.tertiary, 0.6);
        if (st === "signal") return Qt.alpha(Theme.secondary, 0.6);
        if (st === "eclipse") return Qt.alpha(Theme.tertiary, 0.6);
        if (st === "initiald") return Qt.alpha(Theme.error, 0.7);
        return Tokens.borderOf();
    }
    readonly property color accentHairline: Theme.primary
    readonly property color accentHairline2: Theme.tertiary
    readonly property bool barTop: Tokens.barTopHairline.length > 0
    readonly property bool barBottom: Tokens.barBottomHairline.length > 0
    readonly property string barTopHairline: Tokens.barTopHairline
    readonly property string barBottomHairline: Tokens.barBottomHairline

    readonly property int shadowBlur: Tokens.elevShadow(3).blur
    readonly property color shadowC: Qt.rgba(0, 0, 0, Tokens.elevShadow(3).alpha)
    readonly property int shadowY: Tokens.elevShadow(3).y
    readonly property bool brackets: st === "silverwolf" || st === "lain" || st === "initiald"

    readonly property string mark: {
        if (st === "catalyst" || st === "protocol" || st === "pulse") return "◆";
        if (st === "silverwolf") return "SW";
        if (st === "lain") return "LN";
        if (st === "tsubasa") return "TS";
        if (st === "signal") return "∿";
        if (st === "eclipse") return "◌";
        if (st === "brume") return "";
        return "●";
    }

    readonly property string displayName: {
        if (st === "catalyst") return "Catalyst";
        if (st === "protocol") return "Protocol";
        if (st === "pulse") return "Pulse";
        if (st === "silverwolf") return "Wolf";
        if (st === "islands") return "Îlots";
        if (st === "lain") return "Lain";
        if (st === "tsubasa") return "Tsubasa";
        if (st === "brume") return "Brume";
        if (st === "signal") return "Signal";
        if (st === "eclipse") return "Eclipse";
        if (st === "apple") return "Apple";
        if (st === "initiald") return "Initial D";
        return st;
    }

    readonly property var identities: [
        { id: "catalyst", label: "Catalyst" },
        { id: "protocol", label: "Protocol" },
        { id: "pulse", label: "Pulse" },
        { id: "islands", label: "Îlots" },
        { id: "silverwolf", label: "Wolf" },
        { id: "lain", label: "Lain" },
        { id: "tsubasa", label: "Tsubasa" },
        { id: "brume", label: "Brume" },
        { id: "signal", label: "Signal" },
        { id: "eclipse", label: "Eclipse" }
    ]

    function setIdentity(id) {
        Theme.uiStyle = id;
        Identity.style = id;
        Identity.studio("identity:" + id);
    }
}
