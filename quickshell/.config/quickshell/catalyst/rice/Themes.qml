pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/*
 * Themes — registre des thèmes complets (identité + palette + accents).
 *
 * Un thème = un preset JSON :
 *   tokens/presets/<id>.json       fourni avec le shell
 *   tokens/presets/user/<id>.json  créé par l'utilisateur (Sauvegarder)
 *
 * Schéma d'un preset :
 *   {
 *     "id": "catalyst-dark",
 *     "label": "Catalyst Dark",
 *     "description": "...",
 *     "identity": "tsubasa",        // -> tokens/themes/<id>.json (pack d'identité)
 *     "mode": "dark",
 *     "hyprland": { "active": "#..", "active2": "#..", "inactive": "#.." },
 *     "palette": { ... format lyne, cf. Palettes.lyneMapped ... }
 *   }
 *
 * Le moteur existant est préservé : l'identité (Theme.uiStyle) et la palette
 * (~/.local/themes) restent sélectionnables séparément dans l'Atelier. Choisir
 * un thème complet revient à figer ces deux réglages, plus les accents Hyprland.
 */
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.config/quickshell/catalyst/tokens/presets"
    readonly property string userDir: dir + "/user"
    readonly property string accentPath: Quickshell.env("HOME") + "/.cache/matugen/catalyst-accent.conf"

    // [{ id, label, description, identity, builtin, data }]
    property var presets: []
    property string active: ""
    property bool loaded: false
    property bool presetsReady: false

    readonly property bool hasActive: active.length > 0

    Component.onCompleted: refresh()

    function refresh() {
        scanProc._buf = "";
        scanProc.running = true;
    }

    function byId(id) {
        const all = presets;
        for (let i = 0; i < all.length; i++)
            if (all[i].id === id)
                return all[i];
        return null;
    }

    function index(id) {
        const all = presets;
        for (let i = 0; i < all.length; i++)
            if (all[i].id === id)
                return i;
        return -1;
    }

    function slug(label) {
        const s = String(label || "").toLowerCase()
            .replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
        return s.length ? s : "theme";
    }

    // ------------------------------------------------------------------
    // Application
    // ------------------------------------------------------------------
    function apply(id) {
        const p = byId(id);
        if (!p || !p.data) {
            console.log("[Themes] preset introuvable:", id);
            return;
        }
        applyData(id, p.data, true);
    }

    function applyData(id, data, persist) {
        if (!data || !data.palette)
            return;

        // 1. pack d'identité (géométrie, typographie, chrome)
        if (data.identity && data.identity.length)
            Chrome.setIdentity(data.identity);

        // 2. palette
        Theme.mode = "theme";
        Theme.applyMapped(Palettes.lyneMapped(data.palette));

        active = id || "";

        // 3. persistance via le mécanisme existant
        ShellCfg.paletteMode = id ? "theme" : "preset";
        ShellCfg.palette = id;
        ShellCfg.theme = id;
        if (persist !== false)
            ShellCfg.save();

        // 4. accents Hyprland (bordures de fenêtre)
        scheduleAccent();
    }

    // Revenir au mode Material You (palette tirée du fond d'écran)
    function setAuto() {
        active = "";
        Palettes.setAuto();
        scheduleAccent();
    }

    // ------------------------------------------------------------------
    // Presets utilisateur
    // ------------------------------------------------------------------
    function currentPalette() {
        function hex(c) {
            let s = c.toString();
            if (s.charAt(0) !== "#")
                s = "#" + s;
            return s.length > 7 ? s.substring(0, 7) : s;
        }
        return {
            background: hex(Theme.background),
            blueDark: hex(Theme.surfaceContainerLowest),
            surface0: hex(Theme.surfaceContainerLow),
            surface1: hex(Theme.surfaceContainer),
            surface2: hex(Theme.surfaceContainerHigh),
            surface3: hex(Theme.surfaceContainerHighest),
            text: hex(Theme.ink),
            textReverse: hex(Theme.inkPrimary),
            subtext: hex(Theme.inkMuted),
            subtextReverse: hex(Theme.inkSecondary),
            accent: hex(Theme.primary),
            electric: hex(Theme.electric),
            signature: hex(Theme.signature),
            greyBlue: hex(Theme.electric),
            success: hex(Theme.success),
            warning: hex(Theme.warning),
            error: hex(Theme.error),
            muted: hex(Theme.outline)
        };
    }

    function buildPreset(id, label) {
        return {
            id: id,
            label: label,
            description: "Thème enregistré depuis la configuration courante.",
            identity: Theme.uiStyle,
            mode: "dark",
            hyprland: {
                active: currentPalette().accent,
                active2: currentPalette().electric,
                inactive: currentPalette().surface3
            },
            palette: currentPalette()
        };
    }

    function saveCurrent(label) {
        const name = String(label || "").trim();
        if (!name.length)
            return;
        const id = slug(name);
        const data = buildPreset(id, name);
        writePreset(userDir + "/" + id + ".json", data, function () {
            refresh();
            active = id;
            ShellCfg.paletteMode = "theme";
            ShellCfg.palette = id;
            ShellCfg.theme = id;
            ShellCfg.save();
        });
    }

    function duplicate(id) {
        const p = byId(id);
        if (!p)
            return;
        let n = 1;
        let newId = p.id + "-copie";
        while (byId(newId)) {
            n++;
            newId = p.id + "-copie-" + n;
        }
        const data = JSON.parse(JSON.stringify(p.data));
        data.id = newId;
        data.label = p.label + " (copie)";
        writePreset(userDir + "/" + newId + ".json", data, refresh);
    }

    function remove(id) {
        const p = byId(id);
        if (!p || p.builtin)
            return;
        if (active === id)
            setAuto();
        rmProc.command = ["rm", "-f", "--", userDir + "/" + id + ".json"];
        rmProc.running = true;
        refresh();
    }

    function rename(id, newLabel) {
        const p = byId(id);
        if (!p || p.builtin)
            return;
        const nid = slug(newLabel);
        const data = JSON.parse(JSON.stringify(p.data));
        data.id = nid;
        data.label = newLabel;
        writePreset(userDir + "/" + nid + ".json", data, function () {
            rmProc.command = ["rm", "-f", "--", userDir + "/" + id + ".json"];
            rmProc.running = true;
            if (active === id) {
                active = nid;
                ShellCfg.palette = nid;
                ShellCfg.theme = nid;
                ShellCfg.save();
            }
            refresh();
        });
    }

    function writePreset(path, data, cb) {
        writeProc._cb = cb || null;
        writeProc.command = ["bash", "-c", "cat > '" + path + "' << 'EOF'\n" + JSON.stringify(data, null, 2) + "\nEOF"];
        writeProc.running = true;
    }

    // ------------------------------------------------------------------
    // Restauration au démarrage
    // ------------------------------------------------------------------
    function applyStored() {
        if (!ShellCfg.fileReady || !presetsReady)
            return;
        loaded = true;
        const id = ShellCfg.theme;
        if (!id || !id.length) {
            active = "";
            return;
        }
        const p = byId(id);
        if (!p) {
            // preset supprimé : retour propre au mode auto
            console.log("[Themes] preset stocké introuvable, retour Material You:", id);
            active = "";
            ShellCfg.paletteMode = "auto";
            ShellCfg.theme = "";
            ShellCfg.save();
            return;
        }
        applyData(id, p.data, false);
    }

    Connections {
        target: ShellCfg
        function onFileReadyChanged() {
            root.applyStored();
        }
    }

    // ------------------------------------------------------------------
    // Accents Hyprland — un seul fichier, écrit après un debounce pour
    // suivre aussi les changements de palette Material You.
    // ------------------------------------------------------------------
    function scheduleAccent() {
        accentTimer.restart();
    }

    function writeAccent() {
        function rgb(c) {
            let s = c.toString();
            if (s.charAt(0) !== "#")
                s = "#" + s;
            return s.substring(1, 7).toLowerCase();
        }
        const preset = root.active.length ? root.byId(root.active) : null;
        const hy = preset && preset.data && preset.data.hyprland ? preset.data.hyprland : null;
        const pick = (v, fallback) => {
            if (!v)
                return fallback;
            const t = String(v).replace("#", "");
            return t.substring(0, 6).toLowerCase() || fallback;
        };
        const a = pick(hy && hy.active, rgb(Theme.primary));
        const b = pick(hy && hy.active2, rgb(Theme.tertiary));
        const cIn = pick(hy && hy.inactive, rgb(Theme.outlineVariant));

        const body = [
            "# Généré par Tsubasa Catalyst (rice/Themes.qml) — ne pas éditer",
            "$primary = #" + a,
            "$col_active = rgba(" + a + "ff)",
            "$col_active2 = rgba(" + b + "ff)",
            "$col_inactive = rgba(" + cIn + "ff)",
            ""
        ].join("\n");

        accentProc.command = ["bash", "-c", "mkdir -p '" + Quickshell.env("HOME") + "/.cache/matugen' && cat > '" + root.accentPath + "' << 'EOF'\n" + body + "EOF\nhyprctl reload >/dev/null 2>&1 || true"];
        accentProc.running = true;
    }

    Timer {
        id: accentTimer
        interval: 700
        onTriggered: root.writeAccent()
    }

    Connections {
        target: Theme
        function onPrimaryChanged() { root.scheduleAccent() }
        function onTertiaryChanged() { root.scheduleAccent() }
        function onElectricChanged() { root.scheduleAccent() }
        function onModeChanged() { root.scheduleAccent() }
    }

    // ------------------------------------------------------------------
    // Processus
    // ------------------------------------------------------------------
    Process {
        id: scanProc
        property string _buf: ""
        command: ["bash", "-c", "for f in '" + root.dir + "'/*.json '" + root.userDir + "'/*.json; do [ -f \"$f\" ] || continue; echo \"---P:$(basename \"$f\" .json)|$(dirname \"$f\")---\"; cat \"$f\"; echo; echo '---S---'; done"]
        stdout: SplitParser {
            onRead: data => scanProc._buf += data + "\n"
        }
        onExited: {
            const chunks = scanProc._buf.split("---S---");
            const out = [];
            const seen = {};
            for (let i = 0; i < chunks.length; i++) {
                const chunk = chunks[i];
                const mark = chunk.indexOf("---P:");
                if (mark < 0)
                    continue;
                const end = chunk.indexOf("---", mark + 5);
                if (end < 0)
                    continue;
                const head = chunk.substring(mark + 5, end);
                const json = chunk.substring(end + 3).trim();
                const bar = head.indexOf("|");
                const fileId = bar > 0 ? head.substring(0, bar) : head;
                const dir = bar > 0 ? head.substring(bar + 1) : "";
                try {
                    const data = JSON.parse(json);
                    const id = data.id || fileId;
                    if (seen[id])
                        continue;
                    seen[id] = true;
                    out.push({
                        id: id,
                        label: data.label || id,
                        description: data.description || "",
                        identity: data.identity || "",
                        builtin: dir === root.dir,
                        data: data
                    });
                } catch (e) {
                    console.log("[Themes] parse error", fileId, e);
                }
            }
            out.sort((a, b) => {
                if (a.builtin !== b.builtin)
                    return a.builtin ? -1 : 1;
                return a.label < b.label ? -1 : (a.label > b.label ? 1 : 0);
            });
            scanProc._buf = "";
            root.presets = out;
            root.presetsReady = true;
            root.loaded = false;
            root.applyStored();
        }
    }

    Process {
        id: writeProc
        property var _cb: null
        onExited: {
            if (_cb)
                _cb();
            _cb = null;
        }
    }

    Process { id: rmProc }

    Process { id: accentProc }
}
