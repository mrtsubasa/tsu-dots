pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/*
 * Proton — navigateur ProtonVPN dans le panneau (scripts/pvpn.py).
 * Lit le cache de l'app officielle (serveurs classés par activité, charge live,
 * reco de l'optimal). La connexion en 1 clic génère une WireGuard « ProtonVPN »
 * (clé de session, côté Python) importée dans le hub Vpn et montée comme un WG.
 */
Singleton {
    id: root

    property bool ready: false
    property int tier: 0
    property int total: 0
    property int updatedAt: 0
    property var categories: []
    property var countries: []

    property string category: "rapide"      // catégorie sélectionnée
    property string query: ""                // recherche libre
    property var findResults: []
    property bool searching: false
    property string countryCode: ""          // pays ouvert (vue détaillée)
    property var countryServers: []

    property string busyId: ""               // serveur en cours de connexion
    property string activeId: ""             // serveur de la dernière connexion
    property string activeName: ""
    property string note: ""
    property bool noteError: false
    property int users: 0

    readonly property string script: Quickshell.env("HOME") + "/.config/quickshell/catalyst/scripts/pvpn.py"
    readonly property var current: categories.find(c => c.id === category) || null
    // connexion WireGuard « ProtonVPN » gérée par le hub (voir Vpn)
    readonly property var conn: Vpn.items.find(v => v.label === "ProtonVPN" && !v.external) || null
    readonly property bool connected: conn !== null && conn.active

    onUsersChanged: if (users > 0) refresh()

    function say(text, err) {
        note = text;
        noteError = !!err;
        noteT.restart();
    }
    Timer { id: noteT; interval: 9000; onTriggered: root.note = "" }

    // ---- liste classée ----
    function refresh() {
        srvProc.buf = "";
        srvProc.command = ["python3", script, "servers"];
        srvProc.running = true;
    }
    Process {
        id: srvProc
        property string buf: ""
        stdout: SplitParser { onRead: d => srvProc.buf += d }
        onExited: {
            try {
                const r = JSON.parse(srvProc.buf);
                if (r && r.categories) {
                    root.tier = r.tier;
                    root.total = r.total;
                    root.updatedAt = r.updated;
                    root.categories = r.categories;
                    root.countries = r.countries;
                    root.ready = true;
                }
            } catch (e) {
                console.log("[Proton] parse", e);
            }
        }
    }

    // ---- recherche ----
    onQueryChanged: findDebounce.restart()
    Timer {
        id: findDebounce
        interval: 300
        onTriggered: {
            const q = root.query.trim();
            if (q.length < 2) { root.findResults = []; return; }
            root.searching = true;
            findProc.buf = "";
            findProc.command = ["python3", root.script, "find", q];
            findProc.running = true;
        }
    }
    Process {
        id: findProc
        property string buf: ""
        stdout: SplitParser { onRead: d => findProc.buf += d }
        onExited: {
            root.searching = false;
            try {
                const r = JSON.parse(findProc.buf);
                root.findResults = (r && r.servers) ? r.servers : [];
            } catch (e) { root.findResults = []; }
        }
    }

    // ---- vue d'un pays ----
    function openCountry(cc) {
        countryCode = cc;
        countryServers = [];
        ctryProc.buf = "";
        ctryProc.command = ["python3", script, "country", cc];
        ctryProc.running = true;
    }
    function closeCountry() {
        countryCode = "";
        countryServers = [];
    }
    Process {
        id: ctryProc
        property string buf: ""
        stdout: SplitParser { onRead: d => ctryProc.buf += d }
        onExited: {
            try {
                const r = JSON.parse(ctryProc.buf);
                root.countryServers = (r && r.servers) ? r.servers : [];
            } catch (e) { root.countryServers = []; }
        }
    }

    // ---- connexion (génère la WG puis la monte via le hub Vpn) ----
    function connect(server) {
        busyId = server.id;
        say("Préparation de " + server.name + "…");
        connProc.serverName = server.name;
        connProc.serverId = server.id;
        connProc.buf = "";
        connProc.command = ["python3", script, "connect", server.id];
        connProc.running = true;
    }
    Process {
        id: connProc
        property string serverName: ""
        property string serverId: ""
        property string buf: ""
        stdout: SplitParser { onRead: d => connProc.buf += d }
        onExited: {
            let r = null;
            try { r = JSON.parse(connProc.buf); } catch (e) {}
            if (r && r.ok && r.uuid) {
                root.activeId = connProc.serverId;
                root.activeName = connProc.serverName;
                Vpn.refresh();
                // monte la connexion via le chemin éprouvé du hub
                Vpn.up({ uuid: r.uuid, label: "ProtonVPN · " + connProc.serverName });
                root.say("Connexion à " + connProc.serverName + "…");
            } else {
                root.busyId = "";
                root.say((r && r.error) ? r.error : "Échec de la préparation", true);
            }
        }
    }
    function disconnect() {
        if (conn)
            Vpn.down(conn);
    }

    // libère busyId quand l'état de connexion change
    onConnectedChanged: busyId = ""

    Timer {
        interval: 5000
        repeat: true
        running: root.users > 0
        onTriggered: Vpn.refresh()
    }

    Component.onCompleted: refresh()
}
