pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Profil étendu (Studio → Profil) : bannière, pronoms, bio, localisation, site,
// réseaux, centres d'intérêt. Nom, avatar et statut restent dans Identity.
// Stocké HORS du dépôt (~/.config/catalyst/profile.json) : ce sont des infos
// perso, elles ne doivent pas partir sur GitHub avec les dotfiles.
Singleton {
    id: root

    property string banner: ""     // chemin de l'image (copiée dans ~/.config/catalyst)
    property real bannerY: 0.5     // cadrage vertical 0 (haut) → 1 (bas)
    property string pronouns: ""
    property string bio: ""
    property string location: ""
    property string website: ""
    property var links: ({})       // id réseau → identifiant
    property var tags: []

    readonly property string dir: Quickshell.env("HOME") + "/.config/catalyst"
    readonly property string path: dir + "/profile.json"

    // réseaux : glyphe Nerd Font (vérifié dans la police), lien construit depuis l'identifiant
    readonly property var networks: [
        { id: "github", label: "GitHub", glyph: "", url: "https://github.com/%s", hint: "pseudo" },
        { id: "discord", label: "Discord", glyph: "", url: "", hint: "pseudo (copié au clic)" },
        { id: "x", label: "X / Twitter", glyph: "", url: "https://x.com/%s", hint: "pseudo sans @" },
        { id: "youtube", label: "YouTube", glyph: "", url: "https://youtube.com/@%s", hint: "nom de chaîne sans @" },
        { id: "twitch", label: "Twitch", glyph: "", url: "https://twitch.tv/%s", hint: "pseudo" },
        { id: "instagram", label: "Instagram", glyph: "", url: "https://instagram.com/%s", hint: "pseudo" },
        { id: "bluesky", label: "Bluesky", glyph: "", url: "https://bsky.app/profile/%s", hint: "handle (moi.bsky.social)" },
        { id: "reddit", label: "Reddit", glyph: "", url: "https://reddit.com/u/%s", hint: "pseudo" },
        { id: "steam", label: "Steam", glyph: "", url: "https://steamcommunity.com/id/%s", hint: "id personnalisé" }
    ]
    readonly property string webGlyph: "󰖟"      // U+F059F globe
    readonly property string locationGlyph: "󰍎" // U+F034E pin

    readonly property var activeLinks: networks.filter(n => (links[n.id] || "").length > 0)
    readonly property bool hasBanner: banner.length > 0

    function link(id) {
        return links[id] || "";
    }

    function urlFor(net) {
        const v = link(net.id);
        if (!v.length || !net.url.length)
            return "";
        if (/^https?:\/\//.test(v))
            return v;
        return net.url.replace("%s", encodeURIComponent(v.replace(/^@/, "")));
    }

    function websiteUrl() {
        if (!website.length)
            return "";
        return /^https?:\/\//.test(website) ? website : "https://" + website;
    }

    function websiteLabel() {
        return website.replace(/^https?:\/\//, "").replace(/\/$/, "");
    }

    function set(key, value) {
        root[key] = value;
        save();
    }

    function setLink(id, value) {
        const l = Object.assign({}, links);
        const v = String(value || "").trim();
        if (v.length)
            l[id] = v;
        else
            delete l[id];
        links = l;
        save();
    }

    function addTag(t) {
        const v = String(t || "").trim().slice(0, 24);
        if (!v.length || tags.indexOf(v) >= 0 || tags.length >= 10)
            return;
        tags = tags.concat([v]);
        save();
    }

    function removeTag(t) {
        tags = tags.filter(x => x !== t);
        save();
    }

    // ouvre un lien / copie l'identifiant (Discord n'a pas d'URL publique par pseudo)
    function openNet(net) {
        const u = urlFor(net);
        if (u.length)
            Quickshell.execDetached(["xdg-open", u]);
        else
            Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | wl-copy && notify-send 'Profil' \"$2 copié : $1\"", "_", link(net.id), net.label]);
    }

    function openWebsite() {
        if (website.length)
            Quickshell.execDetached(["xdg-open", websiteUrl()]);
    }

    function dump() {
        return JSON.stringify({
            banner: banner,
            bannerY: bannerY,
            pronouns: pronouns,
            bio: bio,
            location: location,
            website: website,
            links: links,
            tags: tags
        }, null, 2) + "\n";
    }

    function save() {
        saveProc.command = ["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1.tmp\" && mv \"$1.tmp\" \"$1\"", "_", path, dump()];
        saveProc.running = true;
    }

    // copie l'image choisie (nom horodaté : pas de cache d'image périmé) et retire l'ancienne
    function useImage(src) {
        bannerProc.command = ["sh", "-c",
            "[ -f \"$1\" ] || exit 1; mkdir -p \"$2\"; ext=\"${1##*.}\"; dst=\"$2/banner-$(date +%s).$ext\"; "
            + "cp -- \"$1\" \"$dst\" && find \"$2\" -maxdepth 1 -name 'banner-*' ! -path \"$dst\" -delete; printf '%s' \"$dst\"",
            "_", src, dir];
        bannerProc.running = true;
    }

    // l'image affichée par awww sur le premier écran
    function useWallpaper() {
        bannerProc.command = ["sh", "-c",
            "src=$(awww query 2>/dev/null | sed -n 's/.*image: //p' | head -1); [ -f \"$src\" ] || exit 1; "
            + "mkdir -p \"$1\"; ext=\"${src##*.}\"; dst=\"$1/banner-$(date +%s).$ext\"; "
            + "cp -- \"$src\" \"$dst\" && find \"$1\" -maxdepth 1 -name 'banner-*' ! -path \"$dst\" -delete; printf '%s' \"$dst\"",
            "_", dir];
        bannerProc.running = true;
    }

    function pickBanner() {
        pickProc.running = true;
    }

    function clearBanner() {
        bannerProc.command = ["sh", "-c", "find \"$1\" -maxdepth 1 -name 'banner-*' -delete", "_", dir];
        bannerProc.running = true;
        set("banner", "");
    }

    FileView {
        path: root.path
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const o = JSON.parse(text());
                root.banner = String(o.banner || "");
                root.bannerY = Math.max(0, Math.min(1, Number(o.bannerY ?? 0.5)));
                root.pronouns = String(o.pronouns || "");
                root.bio = String(o.bio || "");
                root.location = String(o.location || "");
                root.website = String(o.website || "");
                root.links = (o.links && typeof o.links === "object") ? o.links : ({});
                root.tags = Array.isArray(o.tags) ? o.tags.map(String) : [];
            } catch (e) {
                console.log("[Profile] parse error", e);
            }
        }
    }

    Process { id: saveProc }

    Process {
        id: pickProc
        property string out: ""
        command: ["zenity", "--file-selection", "--title", "Bannière du profil", "--file-filter=Images | *.png *.jpg *.jpeg *.webp *.gif *.bmp"]
        stdout: SplitParser {
            onRead: line => pickProc.out = line.trim()
        }
        onStarted: out = ""
        onExited: {
            if (pickProc.out.length)
                root.useImage(pickProc.out);
        }
    }

    Process {
        id: bannerProc
        property string out: ""
        stdout: SplitParser {
            onRead: line => bannerProc.out = line.trim()
        }
        onStarted: out = ""
        onExited: code => {
            if (code === 0 && bannerProc.out.length)
                root.set("banner", bannerProc.out);
        }
    }
}
