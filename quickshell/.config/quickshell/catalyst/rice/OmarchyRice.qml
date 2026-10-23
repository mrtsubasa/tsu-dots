pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    property string path: ""
    property string title: "Omarchy"
    property var items: []
    property string current: ""
    property string status: ""
    property bool busy: false

    function reload() {
        Bridge.call(["omarchy-menu", path], function (r) {
            if (!r || !r.ok)
                return;
            root.title = r.title || "Omarchy";
            root.items = r.items || [];
            root.current = r.current || "";
        });
    }

    function reset() {
        path = "";
        status = "";
        reload();
    }

    function back() {
        if (!path.length) {
            PanelService.hide();
            return;
        }
        if (path === "__themes__") {
            path = "style";
            reload();
            return;
        }
        const i = path.lastIndexOf(".");
        path = i >= 0 ? path.slice(0, i) : "";
        reload();
    }

    function enter(id) {
        path = id;
        status = "";
        reload();
    }

    function activate(item) {
        if (!item || !item.id)
            return;
        const kind = item.kind || "";
        if (kind === "submenu" || kind === "empty") {
            enter(item.id);
            return;
        }
        if (kind === "themes") {
            path = "__themes__";
            reload();
            return;
        }
        if (kind === "launcher") {
            PanelService.show("launcher");
            return;
        }
        if (kind === "wall") {
            PanelService.show("wall");
            return;
        }
        if (kind === "fonts") {
            status = "Fonts: omarchy font list (CLI)";
            Quickshell.execDetached(["alacritty", "-t", "Omarchy Fonts", "-e", "bash", "-lc", "export OMARCHY_PATH=$HOME/.local/share/omarchy; export PATH=$OMARCHY_PATH/bin:$PATH; omarchy font list; echo; echo Entrée…; read"]);
            return;
        }
        if (kind === "hyprland") {
            status = "Hyprland only — skip sur Niri";
            return;
        }
        if (kind === "theme" || kind === "matugen" || kind === "action") {
            if (busy)
                return;
            busy = true;
            Bridge.call(["omarchy-menu-run", item.id], function (r) {
                root.busy = false;
                if (!r) {
                    root.status = "erreur";
                    return;
                }
                if (r.nav) {
                    root.path = r.nav;
                    root.reload();
                    return;
                }
                if (r.blocked) {
                    root.status = r.error || "bloqué";
                    return;
                }
                if (!r.ok) {
                    root.status = r.error || "échec";
                    return;
                }
                if (kind === "theme" || kind === "matugen") {
                    root.current = r.current || root.current;
                    root.reload();
                    return;
                }
                PanelService.hide();
            });
        }
    }

    Component.onCompleted: reload()
}
