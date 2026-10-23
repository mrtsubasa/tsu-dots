pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // --- identity pack file name (legacy ids mapped to v2 packs) ---
    readonly property string packId: {
        const s = Theme.uiStyle;
        if (s === "islands") return "ilots";
        if (s === "silverwolf") return "wolf";
        if (s === "apple" || s === "initiald") return s;
        if (["lain", "tsubasa", "brume", "signal", "eclipse"].indexOf(s) >= 0) return s;
        return "ilots";
    }
    readonly property string baseDir: Quickshell.env("HOME") + "/.config/quickshell/catalyst/tokens"
    readonly property string shellPath: baseDir + "/shell.json"
    readonly property string packPath: baseDir + "/themes/" + packId + ".json"

    // --- shell.json ---
    property string density: "air"
    property bool reducedMotion: false
    property real shellBarOpacity: 0.82
    property real shellVeil: 0.78
    property bool shellBlurBackdrop: true

    // --- identity pack (null = built-in defaults) ---
    property var pack: null

    // =====================================================================
    // SPACING SCALE — unité 4px, rien en dehors
    // =====================================================================
    readonly property int s0: 0
    readonly property int s1: 4
    readonly property int s2: 8
    readonly property int s3: 12
    readonly property int s4: 16
    readonly property int s5: 20
    readonly property int s6: 24
    readonly property int s8: 32
    readonly property int s10: 40
    readonly property int s12: 48

    function space(n) {
        return n * 4;
    }

    // =====================================================================
    // TYPE SCALE — plancher 11px
    // =====================================================================
    readonly property int tDisplay: 34
    readonly property int tTitle: 22
    readonly property int tSection: 11
    readonly property int tBody: 13
    readonly property int tBodyStrong: 13
    readonly property int tMeta: 11
    readonly property int tBar: 13
    readonly property int tBarSmall: 11
    readonly property int tMono: 12
    readonly property int tIcon: 14
    readonly property int tIconSmall: 11

    // =====================================================================
    // DENSITY
    // =====================================================================
    readonly property bool isCompact: density === "compact"
    readonly property bool isRegular: density === "regular"
    readonly property int densityDelta: isCompact ? -4 : (isRegular ? -2 : 0)
    readonly property real densityScale: isCompact ? 0.7 : (isRegular ? 0.85 : 1.0)
    // padding pills / overlays suivent la densité (arrondi au multiple de 4)
    function dens(px) {
        return Math.max(4, Math.round(px * densityScale / 4) * 4);
    }

    // =====================================================================
    // RADIUS SCALE (pack identité, défaut = Îlots)
    // =====================================================================
    readonly property var _r: {
        const p = pack && pack.chrome && pack.chrome.radius ? pack.chrome.radius : null;
        return p ? p : { sm: 8, md: 12, lg: 16, pill: 14, full: 999 };
    }
    readonly property int rSm: _r.sm
    readonly property int rMd: _r.md
    readonly property int rLg: _r.lg
    readonly property int rPill: _r.pill
    readonly property int rFull: _r.full

    // =====================================================================
    // HAIRLINE / VEIL / BLUR
    // =====================================================================
    readonly property int hairline: (pack && pack.chrome && pack.chrome.hairline) ? pack.chrome.hairline : 1
    readonly property real borderAlpha: (pack && pack.chrome && pack.chrome.borderAlpha !== undefined) ? pack.chrome.borderAlpha : 0.55
    readonly property real topHighlight: (pack && pack.chrome && pack.chrome.topHighlight !== undefined) ? pack.chrome.topHighlight : 0.12
    readonly property real veil: (pack && pack.chrome && pack.chrome.veil !== undefined) ? pack.chrome.veil : shellVeil
    readonly property real grain: (pack && pack.chrome && pack.chrome.grain !== undefined) ? pack.chrome.grain : 0.08
    readonly property bool blurBackdrop: (pack && pack.chrome && pack.chrome.blurBackdrop !== undefined) ? pack.chrome.blurBackdrop : shellBlurBackdrop

    // =====================================================================
    // BAR GEOMETRY — exclusiveZone = marginTop + barHeight
    // =====================================================================
    readonly property var _bar: pack && pack.bar ? pack.bar : { mode: "islands", height: 28, marginTop: 8, marginX: 12, gap: 8, opacity: 0.82 }
    readonly property string barMode: _bar.mode
    readonly property bool barIslands: barMode === "islands"
    readonly property int barBase: _bar.height
    readonly property int barHeight: Math.max(24, barBase + densityDelta)
    readonly property int marginTop: _bar.marginTop
    readonly property int marginX: _bar.marginX
    readonly property int barGap: _bar.gap
    readonly property real barOpacity: _bar.opacity !== undefined ? _bar.opacity : shellBarOpacity
    readonly property int exclusive: marginTop + barHeight
    readonly property string barTopHairline: _bar.topHairline || ""
    readonly property string barBottomHairline: _bar.bottomHairline || ""
    readonly property bool barClockSeconds: _bar.clockSeconds === true

    readonly property int overlayMargin: dens(16)
    readonly property int pillH: isCompact ? 36 : (isRegular ? 40 : 44)
    readonly property int dockIcon: isCompact ? 28 : (isRegular ? 32 : 36)

    // =====================================================================
    // ELEVATION e0..e4
    // =====================================================================
    function elevFill(e) {
        if (e <= 0) return Qt.rgba(0, 0, 0, 0);
        if (e === 1) return Qt.alpha(Theme.surfaceContainer, barOpacity);
        if (e === 2) return Qt.alpha(Theme.surfaceContainer, 0.72);
        if (e === 3) return Qt.alpha(Theme.surfaceContainer, 0.78);
        return Qt.alpha(Theme.surfaceContainer, 0.88);
    }

    function elevDockFill() {
        return Qt.alpha(Theme.surfaceContainer, 0.55);
    }

    function elevShadow(e) {
        if (e <= 1) return { blur: 0, alpha: 0, y: 0 };
        if (e === 2) return { blur: 28, alpha: 0.35, y: 8 };
        if (e === 3) return { blur: 40, alpha: 0.40, y: 12 };
        return { blur: 48, alpha: 0.45, y: 16 };
    }

    // bordure externe commune e1+
    function borderOf(alphaMul) {
        return Qt.alpha(Theme.outlineVariant, borderAlpha * (alphaMul === undefined ? 1 : alphaMul));
    }

    // =====================================================================
    // MIGRATION : lit l'existant (panel.json / rice.json) au premier lancement
    // =====================================================================
    Component.onCompleted: reloadShell()

    function reloadShell() {
        shellFile.reload();
    }

    function setDensity(v) {
        density = v;
        saveShell();
    }

    function setReducedMotion(v) {
        reducedMotion = v;
        Theme.animated = !v;
        saveShell();
    }

    function setIdentity(id) {
        saveShell();
    }

    function saveShell() {
        const obj = {
            "$schema": "catalyst.shell/v2",
            identity: packId,
            legacyIdentities: false,
            density: density,
            reducedMotion: reducedMotion,
            bar: { layout: barMode, opacity: shellBarOpacity },
            chrome: { veil: shellVeil, blurBackdrop: shellBlurBackdrop },
            motion: { fast: Motion.fast, base: Motion.base, slow: Motion.slow, theme: Motion.themeDuration }
        };
        shellWrite.command = ["bash", "-c", "cat > '" + shellPath + "' << 'EOF'\n" + JSON.stringify(obj, null, 2) + "\nEOF"];
        shellWrite.running = true;
    }

    function applyShell(obj) {
        if (!obj) return;
        if (obj.density) density = obj.density;
        if (obj.reducedMotion !== undefined) reducedMotion = !!obj.reducedMotion;
        if (obj.bar && obj.bar.opacity !== undefined) shellBarOpacity = obj.bar.opacity;
        if (obj.chrome && obj.chrome.veil !== undefined) shellVeil = obj.chrome.veil;
        if (obj.chrome && obj.chrome.blurBackdrop !== undefined) shellBlurBackdrop = !!obj.chrome.blurBackdrop;
        Theme.animated = !reducedMotion;
    }

    function applyPack(obj) {
        pack = obj || null;
    }

    FileView {
        id: shellFile
        path: root.shellPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.applyShell(JSON.parse(text()));
            } catch (e) {
                console.log("[Tokens] shell.json parse error", e);
            }
        }
    }

    FileView {
        id: packFile
        path: root.packPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.applyPack(JSON.parse(text()));
            } catch (e) {
                console.log("[Tokens] pack parse error", e);
            }
        }
    }

    Connections {
        target: Theme
        function onUiStyleChanged() {
            packFile.reload();
            root.saveShell();
        }
    }

    Process { id: shellWrite }
}
