pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string themesDir: Quickshell.env("HOME") + "/.local/themes"
    property var available: []
    property var previews: ({})
    property string current: "tokyonight"
    readonly property bool isAuto: ShellCfg.paletteMode === "auto"

    Component.onCompleted: {
        listThemes();
        Qt.callLater(function () {
            if (ShellCfg.paletteMode === "preset" && ShellCfg.palette)
                setPreset(ShellCfg.palette);
        });
    }

    function listThemes() {
        listProc._collected = [];
        listProc.running = true;
    }

    function setAuto() {
        Theme.mode = "auto";
        ShellCfg.paletteMode = "auto";
        ShellCfg.theme = "";
        ShellCfg.save();
        Theme.reload();
    }

    function setPreset(name) {
        current = name;
        Theme.mode = "preset";
        ShellCfg.palette = name;
        ShellCfg.paletteMode = "preset";
        ShellCfg.theme = "";
        ShellCfg.save();
        loadProc._name = name;
        loadProc._buffer = "";
        loadProc.command = ["cat", themesDir + "/" + name + ".json"];
        loadProc.running = true;
    }

    // Cartographie d'une palette « lyne » vers les rôles M3 du shell.
    // Les clés optionnelles (signature / electric / info) sont ignorées par les
    // palettes existantes : comportement inchangé pour l'utilisateur actuel.
    function lyneMapped(p) {
        return {
            primary: p.accent,
            on_primary: p.textReverse,
            primary_container: p.accent,
            on_primary_container: p.textReverse,
            secondary: p.subtext,
            on_secondary: p.textReverse,
            tertiary: p.signature || p.warning || p.accent,
            on_tertiary: p.textReverse,
            error: p.error,
            on_error: p.textReverse,
            background: p.background,
            on_background: p.text,
            surface: p.background,
            on_surface: p.text,
            surface_variant: p.surface2,
            on_surface_variant: p.subtext,
            surface_dim: p.blueDark || p.background,
            surface_bright: p.surface2,
            surface_container_lowest: p.blueDark || p.background,
            surface_container_low: p.surface0,
            surface_container: p.surface1,
            surface_container_high: p.surface2,
            surface_container_highest: p.surface3,
            outline: p.muted,
            outline_variant: p.surface2,
            success: p.success,
            warning: p.warning,
            electric: p.electric || p.greyBlue || p.accent,
            signature: p.signature || p.warning || p.accent
        };
    }

    function applyLyne(data, name) {
        if (!data || !data.palette)
            return;
        const p = data.palette;
        Theme.applyMapped(lyneMapped(p));
        if (p.success)
            Theme.success = p.success;
        current = name || current;
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/niri/scripts/palette-apply.sh"]);
    }

    Process {
        id: listProc
        command: ["bash", "-c", "ls -1 '" + root.themesDir + "'/*.json 2>/dev/null | sed 's|.*/||;s|\\.json$||' | sort"]
        property var _collected: []
        stdout: SplitParser {
            onRead: data => {
                const name = data.trim();
                if (name)
                    listProc._collected.push(name);
            }
        }
        onExited: {
            root.available = listProc._collected;
            previewProc._buffer = "";
            previewProc.running = true;
        }
    }

    Process {
        id: previewProc
        command: ["bash", "-c", "for f in '" + root.themesDir + "'/*.json; do echo \"---NAME:$(basename \"$f\" .json)---\"; cat \"$f\"; echo '---SEP---'; done"]
        property string _buffer: ""
        stdout: SplitParser {
            onRead: data => previewProc._buffer += data + "\n"
        }
        onExited: {
            const chunks = _buffer.split("---SEP---");
            var map = {};
            for (var i = 0; i < chunks.length; i++) {
                var chunk = chunks[i].trim();
                if (!chunk)
                    continue;
                var mark = chunk.indexOf("---NAME:");
                if (mark < 0)
                    continue;
                var end = chunk.indexOf("---", mark + 8);
                if (end < 0)
                    continue;
                var name = chunk.substring(mark + 8, end).trim();
                var jsonStr = chunk.substring(end + 3).trim();
                try {
                    var data = JSON.parse(jsonStr);
                    map[name] = {
                        name: data.name || name,
                        palette: data.palette || {},
                        variant: data.variant || "dark"
                    };
                } catch (e) {
                }
            }
            root.previews = map;
            _buffer = "";
        }
    }

    Process {
        id: loadProc
        property string _name: ""
        property string _buffer: ""
        stdout: SplitParser {
            onRead: data => loadProc._buffer += data + "\n"
        }
        onExited: exitCode => {
            if (exitCode !== 0)
                return;
            try {
                root.applyLyne(JSON.parse(_buffer.trim()), _name);
            } catch (e) {
                console.log("[Palettes] parse error", e);
            }
            _buffer = "";
        }
    }
}
