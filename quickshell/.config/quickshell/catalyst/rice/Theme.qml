pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/*
 * Theme — couleurs et typographie du shell (Tsubasa Catalyst v3).
 *
 * Deux couches :
 *   1. rôles « matériaux » (primary, surfaceContainer*, ink…) : remplis par la
 *      palette active — preset complet (Themes), palette tsu (Palettes) ou
 *      Material You (matugen, mode "auto"). Les anciens modules les lisent.
 *   2. tokens sémantiques (accent, text*, s0..s4, border, glass…) : dérivés de
 *      la couche 1. Tout nouveau composant (kit/) ne lit QUE ceux-là.
 */
Singleton {
    id: root

    // =====================================================================
    // 1. Rôles matériaux (écrits par apply())
    // =====================================================================
    property color primary: "#a78bfa"
    Behavior on primary { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    property color inkPrimary: "#0b0a12"
    Behavior on inkPrimary { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    property color primaryContainer: "#a78bfa"
    property color inkPrimaryContainer: "#0b0a12"
    property color secondary: "#a49caf"
    property color inkSecondary: "#5c5675"
    property color tertiary: "#f38bcb"
    Behavior on tertiary { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    property color inkTertiary: "#0b0a12"
    property color error: "#ff8fa3"
    Behavior on error { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    property color inkError: "#0b0a12"
    property color background: "#0b0a12"
    Behavior on background { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    property color inkBg: "#f4f1fa"
    property color surface: "#0b0a12"
    property color ink: "#f4f1fa"
    Behavior on ink { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    property color surfaceVariant: "#201b2c"
    property color inkMuted: "#a49caf"
    Behavior on inkMuted { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    property color surfaceDim: "#06050c"
    property color surfaceBright: "#201b2c"
    property color surfaceContainerLowest: "#06050c"
    Behavior on surfaceContainerLowest { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    property color surfaceContainerLow: "#100e18"
    Behavior on surfaceContainerLow { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    property color surfaceContainer: "#15131f"
    Behavior on surfaceContainer { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    property color surfaceContainerHigh: "#201b2c"
    Behavior on surfaceContainerHigh { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    property color surfaceContainerHighest: "#2a2440"
    Behavior on surfaceContainerHighest { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    property color outline: "#3a3450"
    property color outlineVariant: "#201b2c"
    Behavior on outlineVariant { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    property color success: "#6ee7b7"
    Behavior on success { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    property color warning: "#f5c46b"
    Behavior on warning { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    // bleu glace : second highlight, info, jauges
    property color electric: "#78bfff"
    Behavior on electric { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }
    // rose signature : états importants, sélection forte — jamais en aplat large
    property color signature: "#f38bcb"
    Behavior on signature { enabled: root.animated; ColorAnimation { duration: 400; easing.type: Easing.InOutCubic } }

    // effets du thème (preset.effects) — 0 = sobre, 1 = néon assumé
    property real glow: 0.25
    Behavior on glow { enabled: root.animated; NumberAnimation { duration: 400 } }
    property real glassAlpha: 0.86

    property string uiStyle: "tsubasa"
    property string mode: "auto"
    property bool animated: true

    // =====================================================================
    // 2. Tokens sémantiques
    // =====================================================================
    // texte
    readonly property color text: ink
    readonly property color textSub: inkMuted
    readonly property color textFaint: Qt.alpha(ink, 0.42)
    readonly property color onAccent: inkPrimary

    // accents
    readonly property color accent: primary
    readonly property color accent2: electric
    readonly property color info: electric
    readonly property color focusRing: primary
    readonly property color selection: Qt.alpha(primary, 0.18)

    // surfaces : s0 (fond le plus bas) → s4 (le plus élevé)
    readonly property color bg: background
    readonly property color s0: surfaceContainerLowest
    readonly property color s1: surfaceContainerLow
    readonly property color s2: surfaceContainer
    readonly property color s3: surfaceContainerHigh
    readonly property color s4: surfaceContainerHighest
    readonly property color glass: Qt.alpha(surfaceContainer, glassAlpha)

    // lignes : blanc translucide → s'adapte à toutes les palettes sombres
    readonly property color border: Qt.alpha(ink, 0.075)
    readonly property color borderStrong: Qt.alpha(ink, 0.14)
    readonly property color divider: Qt.alpha(ink, 0.06)

    // états interactifs (couches posées sur un fond)
    readonly property color stateHover: Qt.alpha(ink, 0.06)
    readonly property color statePress: Qt.alpha(ink, 0.10)
    readonly property color stateActive: Qt.alpha(primary, 0.16)

    readonly property color disabledInk: Qt.alpha(ink, 0.38)
    readonly property color disabledSurface: Qt.alpha(surfaceContainerHigh, 0.38)

    // compat anciens modules
    readonly property color surfaceV2: surfaceContainer
    readonly property color surface2: surfaceContainerHigh
    readonly property real veil: 0.78
    readonly property color layer0: Qt.alpha(background, 0.78)
    readonly property color layer1: Qt.alpha(surfaceContainerLow, 0.92)
    readonly property color layer2: Qt.alpha(surfaceContainer, 0.94)
    readonly property color layer3: Qt.alpha(surfaceContainerHigh, 0.96)
    readonly property color hover: Qt.alpha(primary, 0.14)
    readonly property color hoverStrong: Qt.alpha(primary, 0.22)
    readonly property color hairline: border
    readonly property color scrim: Qt.rgba(0, 0, 0, 0.42)

    // =====================================================================
    // Typographie
    // =====================================================================
    // valeurs par défaut du design system ; Studio → Polices peut les remplacer
    readonly property string defaultUiFont: "Inter"
    readonly property string defaultDisplayFont: "Space Grotesk"
    readonly property string defaultMonoFont: "JetBrainsMono Nerd Font"
    readonly property string uiFont: ShellCfg.fontUi.length ? ShellCfg.fontUi : defaultUiFont
    readonly property string displayFont: ShellCfg.fontDisplay.length ? ShellCfg.fontDisplay : defaultDisplayFont
    readonly property string monoFont: ShellCfg.fontMono.length ? ShellCfg.fontMono : defaultMonoFont
    readonly property string iconFont: "Material Symbols Rounded"
    // glyphes Nerd Font des anciens modules
    readonly property string font: "JetBrainsMono Nerd Font"

    // =====================================================================
    // Helpers
    // =====================================================================
    function mix(a, b, t) {
        return Qt.rgba(a.r * (1 - t) + b.r * t, a.g * (1 - t) + b.g * t, a.b * (1 - t) + b.b * t, a.a * (1 - t) + b.a * t);
    }

    function hex(c) {
        const s = String(c);
        return s.length > 7 ? "#" + s.substring(s.length - 6) : s;
    }

    // couleur sémantique par nom (presets, widgets, notifs)
    function role(name) {
        switch (name) {
        case "accent": return primary;
        case "accent2": case "electric": case "info": return electric;
        case "signature": return signature;
        case "success": return success;
        case "warning": return warning;
        case "error": case "danger": return error;
        case "muted": return inkMuted;
        default: return ink;
        }
    }

    function c(obj, key, fallback) {
        const v = obj[key];
        return v && v.length ? v : fallback;
    }

    function applyMapped(obj) {
        apply(obj);
    }

    function applyEffects(fx) {
        glow = fx && fx.glow !== undefined ? fx.glow : 0.25;
        glassAlpha = fx && fx.glass !== undefined ? fx.glass : 0.86;
    }

    function reload() {
        // une palette forcée (preset / thème complet) ne doit jamais être
        // écrasée par un changement de fond d'écran
        if (mode !== "auto")
            return;
        try {
            const t = colorFile.text();
            if (t && t.length)
                applyAuto(JSON.parse(t));
        } catch (e) {
            colorFile.reload();
        }
    }

    // Material You : matugen ne fournit ni electric ni signature ni warning —
    // on les dérive pour que le mode auto reste cohérent avec la charte.
    function applyAuto(obj) {
        if (!obj)
            return;
        const o = Object.assign({}, obj);
        if (!o.electric)
            o.electric = o.secondary || o.primary;
        if (!o.signature)
            o.signature = o.tertiary || o.primary;
        if (!o.warning)
            o.warning = "#f5c46b";
        if (!o.success)
            o.success = "#6ee7b7";
        apply(o);
        applyEffects(null);
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
                root.applyAuto(JSON.parse(text()));
            } catch (e) {
                console.log("[Theme] parse error", e);
            }
        }
    }
}
