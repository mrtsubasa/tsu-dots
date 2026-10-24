pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool dnd: false
    property var items: []
    property var times: []
    property var life: []
    property var leftMs: []
    property var held: []
    property int tick: 0
    readonly property int lifeMs: 6000
    property int popupGen: 0
    readonly property int count: items.length
    readonly property int popupCount: {
        items;
        popupGen;
        return root.countPopups();
    }
    readonly property int unread: popupCount

    function countPopups() {
        const cur = items;
        let n = 0;
        for (let i = 0; i < cur.length; i++) {
            if (cur[i] && cur[i].popup)
                n++;
        }
        return n;
    }

    function popupAt(i) {
        const cur = items;
        let k = 0;
        for (let j = 0; j < cur.length; j++) {
            if (cur[j] && cur[j].popup) {
                if (k === i)
                    return cur[j];
                k++;
            }
        }
        return null;
    }

    function itemAt(i) {
        const cur = items;
        if (i < 0 || i >= cur.length)
            return null;
        return cur[i];
    }

    function recentAt(i) {
        const cur = items;
        const idx = cur.length - 1 - i;
        if (idx < 0 || idx >= cur.length)
            return null;
        return cur[idx];
    }

    function toggleDnd() {
        dnd = !dnd;
        if (dnd)
            clearPopups();
    }

    function clearPopups() {
        const cur = items;
        for (let i = 0; i < cur.length; i++) {
            if (cur[i] && cur[i].popup)
                cur[i].popup = false;
        }
        held = [];
        popupGen++;
    }

    function hold(n) {
        if (!n || held.indexOf(n) >= 0)
            return;
        held = held.concat([n]);
    }

    function release(n) {
        held = held.filter(x => x !== n);
    }

    function hasInvoke(n) {
        return !!(n && n.actions && n.actions.length > 0);
    }

    function lifeFor(n) {
        return hasInvoke(n) ? 12000 : 6500;
    }

    function remain(n) {
        tick;
        const i = items.indexOf(n);
        if (i < 0 || !life[i])
            return 0;
        return Math.max(0, leftMs[i] / life[i]);
    }

    function toUrl(src) {
        if (!src || !String(src).length)
            return "";
        const s = String(src);
        if (s.startsWith("file://") || s.startsWith("image://") || s.startsWith("http"))
            return s;
        if (s.startsWith("/"))
            return "file://" + s;
        return "image://icon/" + s;
    }

    function iconName(n) {
        if (!n)
            return "";
        return n.appIcon || n.desktopEntry || "";
    }

    function imageUrl(n) {
        if (!n)
            return "";
        return toUrl(n.image || "");
    }

    function urgencyColor(n) {
        if (!n)
            return Theme.primary;
        const u = n.urgency;
        const s = ("" + u).toLowerCase();
        if (s.indexOf("crit") >= 0 || u === 2)
            return Theme.error;
        if (s.indexOf("low") >= 0 || u === 0)
            return Theme.inkMuted;
        return Theme.primary;
    }

    function actionLabel(a) {
        if (!a)
            return "Ouvrir";
        const t = a.text || "";
        if (t.length)
            return t;
        const id = (a.identifier || "").toLowerCase();
        if (id === "default" || id === "activate")
            return "Ouvrir";
        return id.length ? id : "Ouvrir";
    }

    function visibleActions(n) {
        if (!n || !n.actions)
            return [];
        const acts = n.actions;
        const out = [];
        for (let i = 0; i < acts.length; i++) {
            const a = acts[i];
            if (!a)
                continue;
            const id = (a.identifier || "").toLowerCase();
            const text = a.text || "";
            if ((id === "default" || id === "activate") && text === "") {
                out.push(a);
                continue;
            }
            if (text !== "")
                out.push(a);
        }
        if (out.length === 0 && acts.length > 0)
            out.push(acts[0]);
        return out;
    }

    function invokeDefault(n) {
        if (!n)
            return;
        const acts = n.actions || [];
        let picked = null;
        for (let i = 0; i < acts.length; i++) {
            const a = acts[i];
            if (!a)
                continue;
            if ((a.identifier || "").toLowerCase() === "default") {
                picked = a;
                break;
            }
            if (!picked)
                picked = a;
        }
        if (picked) {
            try {
                picked.invoke();
            } catch (e) {
            }
        }
        hidePopup(n);
    }

    function invokeAction(n, a) {
        if (a) {
            try {
                a.invoke();
            } catch (e) {
            }
        }
        hidePopup(n);
    }

    function hidePopup(n) {
        if (!n)
            return;
        n.popup = false;
        held = held.filter(x => x !== n);
        popupGen++;
    }

    function dropAt(i) {
        if (i < 0)
            return;
        times.splice(i, 1);
        life.splice(i, 1);
        leftMs.splice(i, 1);
    }

    function forget(n) {
        const i = items.indexOf(n);
        if (i < 0)
            return;
        dropAt(i);
        held = held.filter(x => x !== n);
        items = items.filter(x => x !== n);
        popupGen++;
    }

    function dismiss(n) {
        if (!n)
            return;
        try {
            n.dismiss();
        } catch (e) {
        }
        const i = items.indexOf(n);
        if (i >= 0)
            dropAt(i);
        held = held.filter(x => x !== n);
        items = items.filter(x => x !== n);
    }

    function dismissAll() {
        const cur = items.slice();
        for (let i = 0; i < cur.length; i++)
            dismiss(cur[i]);
        times = [];
        life = [];
        leftMs = [];
        held = [];
    }

    function ago(i) {
        tick;
        if (i < 0 || i >= times.length)
            return "";
        const ms = Date.now() - times[i];
        const m = Math.floor(ms / 60000);
        if (m < 1)
            return "à l'instant";
        if (m < 60)
            return m + " min";
        const h = Math.floor(m / 60);
        if (h < 24)
            return h + " h";
        return Math.floor(h / 24) + " j";
    }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        actionIconsSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            // fermée par l'application (ou expirée côté serveur) : l'objet va
            // être détruit — on le retire tout de suite de toutes les listes,
            // sinon une vue qui se reconstruit lirait un objet détruit (crash)
            n.closed.connect(() => root.forget(n));
            n.popup = !root.dnd;
            const ms = root.lifeFor(n);
            root.times = root.times.concat([Date.now()]);
            root.life = root.life.concat([ms]);
            root.leftMs = root.leftMs.concat([ms]);
            root.items = root.items.concat([n]);
        }
    }

    Timer {
        interval: 80
        running: root.popupCount > 0
        repeat: true
        onTriggered: {
            const cur = root.items;
            let dirty = false;
            for (let i = 0; i < cur.length; i++) {
                const n = cur[i];
                if (!n || !n.popup)
                    continue;
                if (root.held.indexOf(n) >= 0)
                    continue;
                root.leftMs[i] = Math.max(0, (root.leftMs[i] || 0) - 80);
                if (root.leftMs[i] <= 0) {
                    n.popup = false;
                    dirty = true;
                }
            }
            root.tick++;
            if (dirty)
                root.popupGen++;
        }
    }
}
