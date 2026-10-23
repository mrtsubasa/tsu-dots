pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    property string view: "home"
    property string title: "BlackArch"
    property string target: ""
    property string status: ""
    property string cat: ""
    property string osintKind: ""
    property string query: ""
    property var items: []

    function load() {
        let args = ["ba-home"];
        if (view === "categories")
            args = ["ba-categories"];
        else if (view === "tools")
            args = ["ba-tools", cat];
        else if (view === "search")
            args = ["ba-tools", "search", query];
        else if (view === "recents")
            args = ["ba-tools", "recents"];
        else if (view === "osint")
            args = ["ba-osint"];
        else if (view === "osint-tools")
            args = ["ba-osint-tools", osintKind];

        Bridge.call(args, function (r) {
            if (!r || !r.ok)
                return;
            root.items = r.items || [];
            root.target = r.target || root.target;
            if (r.title)
                root.title = r.title;
        });
    }

    function reset() {
        view = "home";
        title = "BlackArch";
        cat = "";
        osintKind = "";
        query = "";
        status = "";
        load();
    }

    function back() {
        if (view === "home") {
            PanelService.hide();
            return;
        }
        if (view === "tools" || view === "search" || view === "recents" || view === "osint") {
            view = "home";
            title = "BlackArch";
            load();
            return;
        }
        if (view === "osint-tools") {
            view = "osint";
            load();
            return;
        }
        view = "home";
        load();
    }

    function setTarget(v) {
        Bridge.call(["ops-target", v || ""], function (r) {
            if (r) {
                root.target = r.target || "";
                root.status = r.status || "";
            }
        });
    }

    function search(q) {
        query = q || "";
        view = "search";
        title = "Recherche";
        load();
    }

    function activate(item) {
        if (!item || !item.id)
            return;
        const kind = item.kind || "";
        if (kind === "info") {
            status = "Cible : " + (target || "aucune");
            return;
        }
        if (kind === "ops") {
            PanelService.show("ops");
            return;
        }
        if (kind === "nav") {
            if (item.id === "search") {
                view = "search";
                title = "Recherche";
                query = "";
                load();
                return;
            }
            if (item.id === "categories") {
                view = "categories";
                title = "Catégories";
                load();
                return;
            }
            if (item.id === "osint") {
                view = "osint";
                title = "OSINT";
                load();
                return;
            }
            if (item.id === "recents") {
                view = "recents";
                title = "Récents";
                load();
                return;
            }
        }
        if (kind === "category") {
            cat = item.id;
            view = "tools";
            title = item.id;
            load();
            return;
        }
        if (kind === "osint-kind") {
            osintKind = item.id;
            view = "osint-tools";
            title = "OSINT · " + item.id;
            load();
            return;
        }
        if (kind === "tool") {
            Bridge.call(["ba-launch", item.id], function (r) {
                root.status = (r && r.status) ? r.status : ((r && r.error) || "");
                if (r && r.ok)
                    PanelService.hide();
            });
            return;
        }
        if (kind === "osint-tool") {
            if (item.ready === false) {
                status = (item.label || item.id) + " absent";
                return;
            }
            const q = target || query || "";
            Bridge.call(["ba-osint-run", item.osint || osintKind, item.id, q], function (r) {
                root.status = (r && r.status) ? r.status : ((r && r.error) || "");
                if (r && r.ok)
                    PanelService.hide();
            });
        }
    }

    function refreshCache() {
        Bridge.call(["ba-refresh"], function (r) {
            root.status = (r && r.status) ? r.status : "";
            load();
        });
    }

    Component.onCompleted: load()
}
