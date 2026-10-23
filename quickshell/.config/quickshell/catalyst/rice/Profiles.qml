pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Profils de configuration (scripts/profiles.py). Les fichiers de réglages
// étant surveillés par leurs services, un chargement s'applique en direct.
Singleton {
    id: root

    property var items: []
    property string note: ""
    property bool busy: false
    readonly property var user: items.filter(p => !p.internal)
    readonly property bool canUndo: items.some(p => p.id === "_previous")
    readonly property string script: Quickshell.env("HOME") + "/.config/quickshell/catalyst/scripts/profiles.py"

    function refresh() {
        run(["list"], r => {
            if (Array.isArray(r))
                root.items = r;
        });
    }

    function save(name) {
        if (!String(name || "").trim().length)
            return;
        run(["save", name], r => {
            root.note = r && r.ok ? "Profil « " + name + " » enregistré." : "Échec de l'enregistrement.";
            refresh();
        });
    }

    function load(id) {
        run(["load", id], r => {
            root.note = r && r.ok ? "Profil appliqué. « Annuler » restaure l'état précédent." : "Profil introuvable.";
            refresh();
        });
    }

    function undo() {
        run(["undo"], r => {
            root.note = r && r.ok ? "État précédent restauré." : "Rien à annuler.";
            refresh();
        });
    }

    function duplicate(id) {
        run(["duplicate", id], () => refresh());
    }

    function rename(id, name) {
        run(["rename", id, name], () => refresh());
    }

    function remove(id) {
        run(["delete", id], () => refresh());
    }

    function defaults() {
        run(["defaults"], r => {
            root.note = r && r.ok ? "Réglages par défaut restaurés. « Annuler » est disponible." : "Échec.";
            refresh();
        });
    }

    // file d'attente : une commande à la fois
    property var _queue: []
    function run(args, cb) {
        _queue.push({ args: args, cb: cb });
        _pump();
    }
    function _pump() {
        if (proc.running || !_queue.length)
            return;
        const job = _queue.shift();
        proc._cb = job.cb;
        proc._buf = "";
        proc.command = ["python3", script].concat(job.args);
        busy = true;
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
            root.busy = false;
            const cb = proc._cb;
            proc._cb = null;
            if (cb)
                cb(r);
            root._pump();
        }
    }

    Component.onCompleted: refresh()
}
