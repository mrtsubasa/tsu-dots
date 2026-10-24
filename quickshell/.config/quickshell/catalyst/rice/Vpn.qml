pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/*
 * VPN via NetworkManager (scripts/vpn.py) : liste, connexion, import (fichier,
 * configuration collée, WireGuard manuel), export, options, réparation.
 * Rafraîchi toutes les 3 s tant qu'un panneau VPN est ouvert, et après chaque
 * action. Les configurations sont transmises en argument (jamais interpolées
 * dans une commande shell).
 */
Singleton {
    id: root

    property var items: []
    property var types: ["openvpn", "wireguard"]
    property int users: 0
    property string busyUuid: ""
    property string note: ""
    property bool noteError: false
    property string needSecrets: ""      // uuid d'un VPN qui demande des identifiants
    readonly property string script: Quickshell.env("HOME") + "/.config/quickshell/catalyst/scripts/vpn.py"
    readonly property string exportDir: Quickshell.env("HOME") + "/Documents/VPN"
    readonly property var userVpns: items.filter(v => !v.external)
    readonly property var activeVpn: items.find(v => v.active && !v.external) || null

    function say(text, err) {
        note = text;
        noteError = !!err;
        noteT.restart();
    }
    Timer {
        id: noteT
        interval: 9000
        onTriggered: root.note = ""
    }

    // ---- file d'appels au script ----
    property var _queue: []
    function run(args, cb, stdinText) {
        _queue.push({ args: args, cb: cb, stdin: stdinText });
        _pump();
    }
    function _pump() {
        if (proc.running || !_queue.length)
            return;
        const j = _queue.shift();
        proc._cb = j.cb;
        proc._buf = "";
        if (j.stdin !== undefined)
            proc.command = ["bash", "-c", "printf '%s' \"$1\" | python3 \"$2\" \"${@:3}\"", "_", j.stdin, script].concat(j.args);
        else
            proc.command = ["python3", script].concat(j.args);
        proc.running = true;
    }
    Process {
        id: proc
        property var _cb: null
        property string _buf: ""
        stdout: SplitParser { onRead: data => proc._buf += data }
        onExited: {
            let r = null;
            try {
                r = JSON.parse(proc._buf);
            } catch (e) {
            }
            const cb = proc._cb;
            proc._cb = null;
            if (cb)
                cb(r);
            root._pump();
        }
    }

    function refresh() {
        run(["list"], r => {
            if (Array.isArray(r))
                root.items = r;
        });
    }
    function loadTypes() {
        run(["types"], r => {
            if (Array.isArray(r))
                root.types = r;
        });
    }
    function done(okText) {
        return r => {
            if (r && r.ok)
                root.say(okText);
            else
                root.say((r && r.error) ? r.error : "Échec", true);
            root.refresh();
        };
    }

    // ---- connexion ----
    function up(v) {
        busyUuid = v.uuid;
        needSecrets = "";
        upProc.uuid = v.uuid;
        upProc.name = v.label;
        upProc.err = "";
        upProc.command = ["nmcli", "--wait", "45", "connection", "up", "uuid", v.uuid];
        upProc.running = true;
    }
    function down(v) {
        busyUuid = v.uuid;
        Quickshell.execDetached(["nmcli", "connection", "down", "uuid", v.uuid]);
        later.restart();
    }
    function upInteractive(uuid) {
        needSecrets = "";
        Quickshell.execDetached(["alacritty", "--title", "Connexion VPN", "-e", "bash", "-c", "nmcli --ask connection up uuid \"$1\"; echo; read -n1 -rsp 'Touche pour fermer…'", "_", uuid]);
        later.restart();
    }
    Process {
        id: upProc
        property string uuid: ""
        property string name: ""
        property string err: ""
        stderr: SplitParser { onRead: data => upProc.err += data + " " }
        onExited: code => {
            root.busyUuid = "";
            if (code === 0) {
                root.say("Connecté à " + upProc.name);
            } else if (/secret|password|mot de passe|agent|identifiant/i.test(upProc.err)) {
                root.needSecrets = upProc.uuid;
                root.say(upProc.name + " demande des identifiants.", true);
            } else {
                root.say("Connexion impossible : " + upProc.err.replace(/^Error:\s*/i, "").slice(0, 180), true);
            }
            root.refresh();
        }
    }
    Timer {
        id: later
        interval: 1500
        onTriggered: {
            root.busyUuid = "";
            root.refresh();
        }
    }

    // ---- gestion ----
    function importFile(path, name) {
        run(["import", path, name || ""], done("VPN importé."));
    }
    function paste(name, ext, text) {
        run(["paste", name, ext], done("VPN « " + name + " » ajouté."), text);
    }
    function wgManual(obj) {
        run(["wg-manual"], done("WireGuard « " + obj.name + " » créé."), JSON.stringify(obj));
    }
    function genkey(cb) {
        run(["genkey"], cb);
    }
    function exportTo(v, dir) {
        run(["export", v.uuid, dir || exportDir], r => {
            if (r && r.ok) {
                const miss = r.missing && r.missing.length ? " — attention : " + r.missing.length + " fichier(s) de certificat introuvable(s), répare le VPN" : "";
                root.say("Exporté : " + r.path.replace(Quickshell.env("HOME"), "~") + miss, miss.length > 0);
            } else {
                root.say((r && r.error) ? r.error : "Échec de l'export", true);
            }
        });
    }
    function setOpt(v, prop, on) {
        run(["set", v.uuid, prop, on ? "on" : "off"], () => root.refresh());
    }
    function rename(v, name) {
        run(["rename", v.uuid, name], done("Renommé."));
    }
    function remove(v) {
        run(["delete", v.uuid], done("« " + v.label + " » supprimé."));
    }
    function replace(v, path) {
        run(["replace", v.uuid, path], done("« " + v.label + " » réparé."));
    }

    // sélecteurs de fichiers (KDE / GTK)
    function pickFile(cb) {
        picker._cb = cb;
        picker.command = ["sh", "-c", "if command -v kdialog >/dev/null; then kdialog --getopenfilename \"$HOME\" 'Configurations VPN (*.ovpn *.conf *.pcf)'; else zenity --file-selection --file-filter='VPN | *.ovpn *.conf *.pcf'; fi"];
        picker.running = true;
    }
    function pickDir(cb) {
        picker._cb = cb;
        picker.command = ["sh", "-c", "mkdir -p \"$1\"; if command -v kdialog >/dev/null; then kdialog --getexistingdirectory \"$1\"; else zenity --file-selection --directory --filename=\"$1/\"; fi", "_", exportDir];
        picker.running = true;
    }
    Process {
        id: picker
        property var _cb: null
        stdout: SplitParser {
            onRead: data => {
                const p = data.trim();
                if (p.length && picker._cb)
                    picker._cb(p);
            }
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: root.users > 0
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: {
        loadTypes();
        refresh();
    }
}
