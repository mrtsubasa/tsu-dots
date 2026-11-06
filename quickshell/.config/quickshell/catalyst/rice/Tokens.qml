pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/*
 * Tokens — géométrie du design system (Tsubasa Catalyst v3).
 *
 * Sources :
 *   tokens/shell.json            réglages globaux (densité, reduced motion…)
 *   tokens/themes/<pack>.json    pack d'identité choisi par le thème
 *                                (rayons, barre, verre, effets)
 * Aucune valeur de géométrie ne doit être codée en dur dans un composant.
 */
Singleton {
    id: root

    // --- identity pack file name (legacy ids mapped to v2 packs) ---
    readonly property string packId: {
        const s = Theme.uiStyle;
        if (s === "islands") return "ilots";
        if (s === "silverwolf") return "wolf";
        if (s === "apple" || s === "initiald") return s;
        if (["catalyst", "protocol", "pulse", "lain", "tsubasa", "brume", "signal", "eclipse", "wolf", "ilots"].indexOf(s) >= 0) return s;
        return "catalyst";
    }
    readonly property string baseDir: Quickshell.env("HOME") + "/.config/quickshell/catalyst/tokens"
    readonly property string shellPath: baseDir + "/shell.json"
    readonly property string packPath: baseDir + "/themes/" + packId + ".json"

    // --- shell.json ---
    property string density: "regular"
    property bool reducedMotion: false
    property real shellBarOpacity: 0.86
    property real shellVeil: 0.78
    property bool shellBlurBackdrop: true
    property bool shellReady: false

    // --- identity pack (null = built-in defaults) ---
    property var pack: null

    // =====================================================================
    // SPACING — unité 4 px
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
    // TYPE SCALE (kit v3) — plancher 11 px
    // =====================================================================
    readonly property int fDisplay: Math.round(44 * ShellCfg.textScale)     // horloge écran de verrouillage / widget
    readonly property int fHero: Math.round(28 * ShellCfg.textScale)        // titres de panneaux larges
    readonly property int fTitle: Math.round(17 * ShellCfg.textScale)       // titre de panneau
    readonly property int fHeading: Math.round(14 * ShellCfg.textScale)     // titre de carte / section
    readonly property int fBody: Math.round(13 * ShellCfg.textScale)        // texte courant
    readonly property int fLabel: Math.round(12 * ShellCfg.textScale)       // libellés de contrôles
    readonly property int fCaption: Math.round(11 * ShellCfg.textScale)     // méta, sous-titres
    readonly property int fOverline: Math.round(11 * ShellCfg.textScale)    // MICRO-LABELS en capitales, tracking large
    readonly property real trackOverline: 1.4

    // compat v2
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
    // ICÔNES & CONTRÔLES
    // =====================================================================
    readonly property int iconXs: 14
    readonly property int iconSm: 16
    readonly property int iconMd: 20
    readonly property int iconLg: 24
    readonly property int iconXl: 32

    readonly property int ctrlSm: 28       // icon-button compact (barre)
    readonly property int ctrl: 34         // bouton standard
    readonly property int ctrlLg: 40       // champ de recherche, bouton principal
    readonly property int rowH: 44         // ligne de liste
    readonly property int tileH: 60        // tuile de réglage rapide
    readonly property int sliderH: 36      // piste de slider « épaisse »
    readonly property int panelPad: 16
    readonly property int sectionGap: 14

    // =====================================================================
    // DENSITY
    // =====================================================================
    readonly property bool isCompact: density === "compact"
    readonly property bool isRegular: density === "regular"
    readonly property int densityDelta: isCompact ? -4 : (isRegular ? -2 : 0)
    readonly property real densityScale: isCompact ? 0.7 : (isRegular ? 0.85 : 1.0)
    function dens(px) {
        return Math.max(4, Math.round(px * densityScale / 4) * 4);
    }

    // =====================================================================
    // RADIUS (pack d'identité)
    // =====================================================================
    readonly property var _r: {
        const p = pack && pack.chrome && pack.chrome.radius ? pack.chrome.radius : null;
        return p ? p : { sm: 8, md: 12, lg: 16, pill: 14, full: 999 };
    }
    readonly property int rXs: Math.max(2, Math.round(_r.sm / 2))
    readonly property int rSm: _r.sm
    readonly property int rMd: _r.md
    readonly property int rLg: _r.lg
    readonly property int rXl: _r.xl !== undefined ? _r.xl : _r.lg + 6
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
    //   mode : "floating" (une capsule) | "islands" (3 îlots) | "attached" (bord à bord)
    // =====================================================================
    readonly property var _bar: pack && pack.bar ? pack.bar : { mode: "floating", height: 34, marginTop: 6, marginX: 8, gap: 8, opacity: 0.86 }
    readonly property string packBarMode: _bar.mode === "continuous" ? (_bar.marginX > 0 ? "floating" : "attached") : (_bar.mode || "floating")
    // le Studio peut imposer un style de barre indépendamment du thème
    readonly property string barMode: BarCfg.style.length ? BarCfg.style : packBarMode
    readonly property bool barIslands: barMode === "islands"
    readonly property bool barAttached: barMode === "attached"
    readonly property int barBase: BarCfg.height > 0 ? BarCfg.height : _bar.height
    readonly property int barHeight: Math.max(26, barBase + densityDelta)
    readonly property int marginTop: barAttached ? 0 : (BarCfg.edge >= 0 ? BarCfg.edge : (_bar.marginTop > 0 ? _bar.marginTop : 6))
    readonly property int marginX: barAttached ? 0 : (BarCfg.edge >= 0 ? BarCfg.edge : (_bar.marginX > 0 ? _bar.marginX : 8))
    readonly property int barGap: _bar.gap
    readonly property real barOpacity: _bar.opacity !== undefined ? _bar.opacity : shellBarOpacity
    readonly property int exclusive: marginTop + barHeight
    readonly property string barTopHairline: _bar.topHairline || ""
    readonly property string barBottomHairline: _bar.bottomHairline || ""
    readonly property bool barClockSeconds: _bar.clockSeconds === true
    readonly property int barRadius: barAttached ? 0 : (BarCfg.radius >= 0 ? BarCfg.radius : (barIslands ? rLg : Math.min(rLg, Math.round(barHeight / 2))))
    // taille des cibles cliquables dans la barre (jamais < 24)
    readonly property int barItem: Math.max(24, barHeight - 8)

    readonly property int overlayMargin: dens(16)
    readonly property int pillH: isCompact ? 36 : (isRegular ? 40 : 44)
    readonly property int dockIcon: isCompact ? 28 : (isRegular ? 32 : 36)

    // position verticale des panneaux sous la barre
    readonly property int belowBar: exclusive + 8

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

    function borderOf(alphaMul) {
        return Qt.alpha(Theme.ink, 0.075 * (alphaMul === undefined ? 1 : alphaMul) / 0.55 * borderAlpha);
    }

    // =====================================================================
    // Persistance
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

    function setBarOpacity(v) {
        shellBarOpacity = v;
        saveShell();
    }

    function setIdentity(id) {
        saveShell();
    }

    function saveShell() {
        if (!shellReady)
            return;
        const obj = {
            "$schema": "catalyst.shell/v3",
            identity: packId,
            density: density,
            reducedMotion: reducedMotion,
            bar: { opacity: shellBarOpacity },
            chrome: { veil: shellVeil, blurBackdrop: shellBlurBackdrop }
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
        shellReady = true;
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
                root.shellReady = true;
            }
        }
        onLoadFailed: root.shellReady = true
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
