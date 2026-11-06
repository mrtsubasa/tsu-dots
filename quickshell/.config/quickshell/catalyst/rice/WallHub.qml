pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/*
 * WallHub — navigateur de fonds d'écran en ligne (scripts/walls_api.py).
 * Plusieurs API (Wallhaven + boorus anime ; MotionBGs + Gelbooru pour les
 * fonds animés), grille de miniatures, recherche, pagination. L'application
 * télécharge le plein format dans wallpapers/[live/]sfw|nsfw/<Source>/ (selon
 * le type et la note du site) puis le pose via le pipeline Walls habituel.
 * Tout est verrouillé SFW côté script (purity / rating).
 */
Singleton {
    id: root

    readonly property string script: Quickshell.env("HOME") + "/.config/quickshell/catalyst/scripts/walls_api.py"

    // sources proposées (ordre = affichage) ; image / live = types servis
    readonly property var sources: [
        { id: "wallhaven", label: "Wallhaven", icon: "image", anime: false, image: true, live: false },
        { id: "konachan",  label: "Konachan",  icon: "auto_awesome", anime: true, image: true, live: false },
        { id: "yandere",   label: "Yande.re",  icon: "auto_awesome", anime: true, image: true, live: false },
        { id: "gelbooru",  label: "Gelbooru",  icon: "auto_awesome", anime: true, image: true, live: true },
        { id: "safebooru", label: "Safebooru", icon: "auto_awesome", anime: true, image: true, live: false },
        { id: "motionbgs", label: "MotionBGs", icon: "movie", anime: false, image: false, live: true }
    ]

    property string kind: "image"     // image | live (fonds animés, vidéo)
    readonly property var shownSources: sources.filter(s => kind === "live" ? s.live : s.image)
    property string source: "wallhaven"
    property string query: ""
    property string rating: "safe"    // safe | nsfw | all
    property int page: 1

    // presets de tags cliquables (remplissent la recherche)
    readonly property var presets: [
        { label: "Paysage", q: "scenery" },
        { label: "Ville", q: "cityscape" },
        { label: "Ciel de nuit", q: "night sky" },
        { label: "Cyberpunk", q: "cyberpunk" },
        { label: "Minimal", q: "minimalism" },
        { label: "Espace", q: "space stars" },
        { label: "Sombre", q: "dark" },
        { label: "Fleurs", q: "flowers" }
    ]
    property var items: []
    property bool loading: false
    property bool more: false
    property string error: ""
    property string busyId: ""        // item en cours de téléchargement

    readonly property var srcMeta: sources.find(s => s.id === source) || sources[0]

    // ---- recherche / pagination ----
    function search(reset) {
        if (reset) {
            page = 1;
            items = [];
        }
        error = "";
        loading = true;
        srch.buf = "";
        srch.reset = reset;
        srch.command = ["python3", script, "search", source, String(page), rating, kind, query.trim()];
        srch.running = true;
    }
    function setSource(s) {
        if (s === source) return;
        source = s;
        search(true);
    }
    function setKind(k) {
        if (k === kind) return;
        kind = k;
        if (!shownSources.some(s => s.id === source))
            source = shownSources[0].id;
        search(true);
    }
    function setRating(r) {
        if (r === rating) return;
        rating = r;
        search(true);
    }
    function usePreset(q) {
        query = q;   // déclenche la recherche via le debounce
    }
    function loadMore() {
        if (loading || !more) return;
        page += 1;
        search(false);
    }

    onQueryChanged: qDebounce.restart()
    Timer {
        id: qDebounce
        interval: 350
        onTriggered: root.search(true)
    }

    Process {
        id: srch
        property string buf: ""
        property bool reset: true
        stdout: SplitParser { onRead: d => srch.buf += d }
        onExited: {
            root.loading = false;
            let r = null;
            try { r = JSON.parse(srch.buf); } catch (e) {}
            if (!r) { root.error = "Réponse illisible"; return; }
            if (r.error) { root.error = r.error; if (reset) root.items = []; return; }
            root.more = !!r.more;
            // marque la source d'origine sur chaque item (pour le téléchargement)
            const add = (r.items || []).map(it => Object.assign({ src: root.source }, it));
            root.items = reset ? add : root.items.concat(add);
        }
    }

    // ---- application (télécharge puis pose) ----
    function apply(item, output) {
        busyId = item.src + ":" + item.id;
        dl.output = output || "";
        dl.buf = "";
        dl.command = ["python3", script, "dl", item.src, String(item.id), item.full, item.nsfw ? "nsfw" : "sfw"];
        dl.running = true;
    }
    Process {
        id: dl
        property string output: ""
        property string buf: ""
        stdout: SplitParser { onRead: d => dl.buf += d }
        onExited: {
            root.busyId = "";
            let r = null;
            try { r = JSON.parse(dl.buf); } catch (e) {}
            if (r && r.ok && r.path) {
                Walls.scan();
                // ouvre l'éditeur de cadrage sur l'image fraîchement téléchargée
                Walls.frame(r.path, dl.output);
            } else {
                root.error = (r && r.error) ? r.error : "Échec du téléchargement";
            }
        }
    }
}
