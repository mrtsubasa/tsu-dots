pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property color primary: "#a5dbff"
    Behavior on primary { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    property color inkPrimary: "#00344b"
    Behavior on inkPrimary { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    property color primaryContainer: "#6fc2f2"
    property color inkPrimaryContainer: "#003045"
    property color secondary: "#adcae0"
    property color inkSecondary: "#153344"
    property color tertiary: "#f1c5ff"
    property color inkTertiary: "#481c5d"
    property color error: "#ffb4ab"
    Behavior on error { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    property color inkError: "#690005"
    property color background: "#101417"
    Behavior on background { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    property color inkBg: "#e0e3e7"
    Behavior on inkBg { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    property color surface: "#101417"
    property color ink: "#e0e3e7"
    Behavior on ink { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    property color surfaceVariant: "#3f484e"
    property color inkMuted: "#bfc8cf"
    Behavior on inkMuted { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    property color surfaceDim: "#101417"
    property color surfaceBright: "#363a3d"
    property color surfaceContainerLowest: "#0b0f11"
    property color surfaceContainerLow: "#181c1f"
    Behavior on surfaceContainerLow { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    property color surfaceContainer: "#1c2023"
    Behavior on surfaceContainer { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    property color surfaceContainerHigh: "#272a2e"
    Behavior on surfaceContainerHigh { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    property color surfaceContainerHighest: "#313538"
    property color outline: "#899299"
    property color outlineVariant: "#3f484e"
    Behavior on outlineVariant { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    property color success: "#a6d189"
    Behavior on success { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    // --- semantic accents (DESIGN-V2 §2 / brief §4) ---
    property color warning: "#f5c46b"
    Behavior on warning { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    // ice blue : second highlight, liens, jauges, info
    property color electric: "#78bfff"
    Behavior on electric { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    // signature pink : états importants et sélection — ne doit pas dominer
    property color signature: "#f38bcb"
    Behavior on signature { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    // neutres : information / focus / indisponible
    readonly property color info: electric
    readonly property color focusRing: primary
    readonly property color disabledInk: Qt.alpha(ink, 0.38)
    readonly property color disabledSurface: Qt.alpha(surfaceContainerHigh, 0.38)
    readonly property color surfaceV2: surfaceContainer

    property string uiStyle: "islands"
    property string mode: "auto"
    // crossfade thème (écrit par Tokens en chargeant reducedMotion)
    property bool animated: true
    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property string uiFont: "Satoshi"
    readonly property real veil: 0.78

    readonly property color layer0: Qt.alpha(background, 0.78)
    readonly property color layer1: Qt.alpha(surfaceContainerLow, 0.92)
    readonly property color layer2: Qt.alpha(surfaceContainer, 0.94)
    readonly property color layer3: Qt.alpha(surfaceContainerHigh, 0.96)
    readonly property color hover: Qt.alpha(primary, 0.14)
    readonly property color hoverStrong: Qt.alpha(primary, 0.22)
    readonly property color hairline: Qt.alpha(outlineVariant, 0.7)
    readonly property color scrim: Qt.rgba(0, 0, 0, 0.42)

    function mix(a, b, t) {
        return Qt.rgba(a.r * (1 - t) + b.r * t, a.g * (1 - t) + b.g * t, a.b * (1 - t) + b.b * t, a.a * (1 - t) + b.a * t);
    }

    function c(obj, key, fallback) {
        const v = obj[key];
        return v && v.length ? v : fallback;
    }

    function applyMapped(obj) {
        apply(obj);
    }

    function reload() {
        // une palette forcée (preset / thème complet) ne doit jamais être
        // écrasée par un changement de fond d'écran
        if (mode !== "auto")
            return;
        try {
            const t = colorFile.text();
            if (t && t.length)
                apply(JSON.parse(t));
        } catch (e) {
            colorFile.reload();
        }
    }

    function apply(obj) {
        if (!obj)
            return;
        primary = c(obj, "primary", primary);
        inkPrimary = c(obj, "on_primary", inkPrimary);
        primaryContainer = c(obj, "primary_container", primaryContainer);
        inkPrimaryContainer = c(obj, "on_primary_container", inkPrimaryContainer);
        secondary = c(obj, "secondary", secondary);
        inkSecondary = c(obj, "on_secondary", inkSecondary);
        tertiary = c(obj, "tertiary", tertiary);
        inkTertiary = c(obj, "on_tertiary", inkTertiary);
        error = c(obj, "error", error);
        inkError = c(obj, "on_error", inkError);
        background = c(obj, "background", background);
        inkBg = c(obj, "on_background", inkBg);
        surface = c(obj, "surface", surface);
        ink = c(obj, "on_surface", ink);
        surfaceVariant = c(obj, "surface_variant", surfaceVariant);
        inkMuted = c(obj, "on_surface_variant", inkMuted);
        surfaceDim = c(obj, "surface_dim", surfaceDim);
        surfaceBright = c(obj, "surface_bright", surfaceBright);
        surfaceContainerLowest = c(obj, "surface_container_lowest", surfaceContainerLowest);
        surfaceContainerLow = c(obj, "surface_container_low", surfaceContainerLow);
        surfaceContainer = c(obj, "surface_container", surfaceContainer);
        surfaceContainerHigh = c(obj, "surface_container_high", surfaceContainerHigh);
        surfaceContainerHighest = c(obj, "surface_container_highest", surfaceContainerHighest);
        outline = c(obj, "outline", outline);
        outlineVariant = c(obj, "outline_variant", outlineVariant);
        success = c(obj, "success", success);
        warning = c(obj, "warning", warning);
        electric = c(obj, "electric", electric);
        signature = c(obj, "signature", signature);
    }

    FileView {
        id: colorFile
        path: Quickshell.env("HOME") + "/.cache/matugen/spell-colors.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            if (root.mode !== "auto")
                return;
            try {
                root.apply(JSON.parse(text()));
            } catch (e) {
                console.log("[Palette] parse error", e);
            }
        }
    }
}
