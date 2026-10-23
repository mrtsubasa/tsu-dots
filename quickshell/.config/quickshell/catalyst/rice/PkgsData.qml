pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    property string page: "need"
    property string catId: ""
    property string query: ""
    property string why: ""
    property string status: ""
    property bool busy: false
    property string helper: "paru"
    property int updates: 0
    property var items: []
    property var cats: []
    property var repos: []
    property var sources: []
    property string source: "all"
    property string repoQuery: ""
    readonly property int count: items.length
    readonly property int catCount: cats.length
    readonly property int repoCount: repos.length
    readonly property int sourceCount: sources.length

    readonly property var pages: [
        { id: "need", label: "Besoin", glyph: "󱚣" },
        { id: "name", label: "Nom", glyph: "󰍉" },
        { id: "installed", label: "Installés", glyph: "󰏗" },
        { id: "updates", label: "Mises à jour", glyph: "󰚰" },
        { id: "repos", label: "Repos", glyph: "󰏒" }
    ]

    function at(i) {
        const cur = items;
        if (i < 0 || i >= cur.length)
            return null;
        return cur[i];
    }

    function catAt(i) {
        const cur = cats;
        if (i < 0 || i >= cur.length)
            return null;
        return cur[i];
    }

    function repoAt(i) {
        const cur = repos;
        if (i < 0 || i >= cur.length)
            return null;
        return cur[i];
    }

    function sourceAt(i) {
        const cur = sources;
        if (i < 0 || i >= cur.length)
            return null;
        return cur[i];
    }

    function srcArg() {
        const s = (source || "all").trim();
        return (!s.length || s === "all") ? "" : s;
    }

    function apply(r) {
        busy = false;
        if (!r || r.ok === false) {
            status = (r && r.error) ? r.error : "échec";
            return;
        }
        if (r.mode === "repos") {
            repos = r.items || [];
            if (r.helper)
                helper = r.helper;
            status = repos.length ? (repos.length + " sources") : "aucune source";
            if (r.total !== undefined && r.total !== repos.length)
                status = repos.length + " / " + r.total + " sources";
            return;
        }
        if (r.mode === "sources") {
            sources = r.items || [];
            if (r.helper)
                helper = r.helper;
            return;
        }
        items = r.items || [];
        why = r.why || "";
        if (r.helper)
            helper = r.helper;
        if (r.count !== undefined)
            updates = r.count;
        else if (r.mode === "updates")
            updates = items.length;
        const tag = srcArg() ? (" · " + srcArg()) : "";
        status = items.length ? (items.length + " paquets" + tag) : ("rien trouvé" + tag);
    }

    function loadCats() {
        Bridge.call(["pkgs-cats"], function (r) {
            if (!r || !r.ok)
                return;
            cats = r.cats || [];
            if (r.helper)
                helper = r.helper;
        });
        Bridge.call(["pkgs-sources"], function (r) {
            if (r && r.ok)
                sources = r.items || [];
        });
        Bridge.call(["pkgs-updates"], function (r) {
            if (r && r.ok)
                updates = r.count || (r.items ? r.items.length : 0);
        });
    }

    function setPage(id) {
        page = id;
        catId = "";
        why = "";
        items = [];
        if (id === "installed" || id === "updates" || id === "repos")
            refresh();
        else if (id === "name" && srcArg().length && srcArg() !== "aur")
            refresh();
        else
            status = id === "need" ? "décris un besoin" : "cherche un nom";
    }

    function setSource(id) {
        source = id || "all";
        if (page === "repos")
            return;
        if (page === "installed" || page === "updates")
            refresh();
        else if (page === "name" || page === "need" || page === "cat")
            refresh();
    }

    function setCat(id) {
        page = "cat";
        catId = id;
        why = "";
        refresh();
    }

    function refresh() {
        const src = srcArg();
        if (page === "need") {
            if (!query.trim().length) {
                items = [];
                status = "décris un besoin";
                return;
            }
            runNeed(query);
            return;
        }
        if (page === "name") {
            if (!query.trim().length && !src.length) {
                items = [];
                status = "cherche un nom";
                return;
            }
            if (!query.trim().length && src === "aur") {
                items = [];
                status = "AUR : tape un nom";
                return;
            }
            runName(query);
            return;
        }
        if (page === "installed") {
            busy = true;
            status = "lecture…";
            if (src.length)
                Bridge.call(["pkgs-installed", src], apply);
            else
                Bridge.call(["pkgs-installed"], apply);
            return;
        }
        if (page === "updates") {
            busy = true;
            status = "cherche les MAJ…";
            if (src.length)
                Bridge.call(["pkgs-updates", src], apply);
            else
                Bridge.call(["pkgs-updates"], apply);
            return;
        }
        if (page === "repos") {
            busy = true;
            status = "repos…";
            if (repoQuery.trim().length)
                Bridge.call(["pkgs-repos", repoQuery], apply);
            else
                Bridge.call(["pkgs-repos"], apply);
            return;
        }
        if (page === "cat" && catId.length) {
            busy = true;
            status = "catalogue…";
            Bridge.call(["pkgs-cat", catId], function (r) {
                if (r && r.ok && src.length)
                    r.items = (r.items || []).filter(function (p) {
                        const rr = String(p.repo || "").toLowerCase();
                        if (src === "aur")
                            return !!p.aur || rr === "aur";
                        return rr === src || rr.indexOf(src) >= 0;
                    });
                apply(r);
            });
        }
    }

    function runNeed(q) {
        query = q;
        page = "need";
        catId = "";
        busy = true;
        status = "l’IA cherche…";
        const src = srcArg();
        if (src.length)
            Bridge.call(["pkgs-need", src, q], apply);
        else
            Bridge.call(["pkgs-need", q], apply);
    }

    function runName(q) {
        query = q;
        page = "name";
        catId = "";
        busy = true;
        status = "recherche…";
        const src = srcArg();
        if (src.length)
            Bridge.call(["pkgs-search", src, q || ""], apply);
        else
            Bridge.call(["pkgs-search", q], apply);
    }

    function install(name) {
        Bridge.call(["pkgs-install", name], function () {});
        status = "terminal : install " + name;
    }

    function remove(name) {
        Bridge.call(["pkgs-remove", name], function () {});
        status = "terminal : retire " + name;
    }

    function upgrade() {
        Bridge.call(["pkgs-upgrade"], function () {});
        status = "terminal : tout mettre à jour";
    }

    function upgradeOne(name) {
        Bridge.call(["pkgs-upgrade-one", name], function () {});
        status = "terminal : maj " + name;
    }

    function setRepoQuery(q) {
        repoQuery = q || "";
        if (page === "repos")
            refresh();
    }

    function enableRepo(id) {
        Bridge.call(["pkgs-repo-enable", id], function (r) {
            if (r && r.ok === false)
                status = r.error || "échec repo";
            else
                status = (r && r.status) ? r.status : ("terminal : activer " + id);
            if (page === "repos")
                refresh();
            Bridge.call(["pkgs-sources"], function (s) {
                if (s && s.ok)
                    sources = s.items || [];
            });
        });
    }

    function addRepo(name, src) {
        const n = (name || "").trim();
        const s = (src || "").trim();
        if (!n.length || !s.length) {
            status = "nom + Include/Server requis";
            return;
        }
        Bridge.call(["pkgs-repo-add", n, s], function (r) {
            if (r && r.ok === false)
                status = r.error || "échec";
            else
                status = "terminal : ajouter " + n;
            if (page === "repos")
                refresh();
        });
    }

    function reset() {
        if (cats.length === 0 || sources.length === 0)
            loadCats();
        if (page === "need" && !query.length)
            status = "décris un besoin";
    }
}
