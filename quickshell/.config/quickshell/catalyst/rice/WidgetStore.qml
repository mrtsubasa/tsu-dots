pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Mode édition (poignées de déplacement/redimensionnement).
    property bool edit: false
    // true une fois le premier chargement terminé
    property bool ready: false

    // source de vérité géométrique — change à chaque mutation
    property var items: []
    // liste d'identifiants stable : ne change qu'à l'ajout/suppression,
    // pour que Repeater ne recrée pas les cartes à chaque déplacement.
    property var ids: []
    property int seq: 1

    readonly property string path: Quickshell.env("HOME") + "/.config/quickshell/catalyst/widgets.json"
    readonly property var emptyIds: []
    readonly property var fallback: ({
        id: "",
        type: "clock",
        screen: "",
        x: 0,
        y: 0,
        w: 320,
        h: 180,
        visible: false,
        props: ({})
    })

    readonly property var types: [
        { type: "clock", label: "Horloge", glyph: "󰥔", icon: "schedule", w: 380, h: 200 },
        { type: "calendar", label: "Calendrier", glyph: "󰃭", icon: "calendar_month", w: 300, h: 300 },
        { type: "sys", label: "Système", glyph: "󰒳", icon: "monitoring", w: 340, h: 220 },
        { type: "media", label: "Lecteur", glyph: "󰝚", icon: "music_note", w: 400, h: 190 },
        { type: "focus", label: "Minuteur", glyph: "󰔛", icon: "timer", w: 300, h: 240 },
        { type: "notes", label: "Notes", glyph: "󰎚", icon: "sticky_note_2", w: 320, h: 240 },
        { type: "weather", label: "Météo", glyph: "󰖐", icon: "partly_cloudy_day", w: 300, h: 150 },
        { type: "launch", label: "Raccourcis dev", glyph: "󰘔", icon: "rocket_launch", w: 320, h: 170 },
        { type: "image", label: "Image", glyph: "󰋩", icon: "image", w: 300, h: 300 }
    ]

    function defOf(type) {
        for (let i = 0; i < types.length; i++)
            if (types[i].type === type)
                return types[i];
        return types[0];
    }

    function labelOf(type) {
        return defOf(type).label;
    }

    function get(id) {
        const list = items;
        for (let i = 0; i < list.length; i++)
            if (list[i].id === id)
                return list[i];
        return fallback;
    }

    function indexOf(id) {
        const list = items;
        for (let i = 0; i < list.length; i++)
            if (list[i].id === id)
                return i;
        return -1;
    }

    function count() {
        return items.length;
    }

    function nextSlot() {
        // placement en cascade discret, jamais collé au bord
        const n = items.length;
        return {
            x: 40 + (n % 4) * 34,
            y: 92 + (n % 4) * 34
        };
    }

    function add(type, screen) {
        const d = defOf(type);
        const slot = nextSlot();
        const it = {
            id: "w" + seq,
            type: d.type,
            screen: screen || "",
            x: slot.x,
            y: slot.y,
            w: d.w,
            h: d.h,
            visible: true,
            props: ({})
        };
        seq++;
        items = items.concat([it]);
        ids = ids.concat([it.id]);
        save();
        return it.id;
    }

    function remove(id) {
        items = items.filter(i => i.id !== id);
        ids = ids.filter(i => i !== id);
        save();
    }

    function patch(id, p) {
        let hit = false;
        const next = items.map(i => {
            if (i.id !== id)
                return i;
            hit = true;
            return Object.assign({}, i, p);
        });
        if (!hit)
            return;
        items = next;
        save();
    }

    function setPos(id, x, y) {
        patch(id, {
            x: Math.round(x),
            y: Math.round(y)
        });
    }

    function setSize(id, w, h) {
        patch(id, {
            w: Math.round(w),
            h: Math.round(h)
        });
    }

    // premier plan : z le plus haut + 1 (persisté)
    function bringToFront(id) {
        let top = 0;
        const list = items;
        for (let i = 0; i < list.length; i++)
            top = Math.max(top, list[i].z || 0);
        if ((get(id).z || 0) < top || top === 0)
            patch(id, { z: top + 1 });
    }

    function moveToScreen(id, screen) {
        patch(id, { screen: screen });
    }

    function toggleVisible(id) {
        patch(id, {
            visible: !get(id).visible
        });
    }

    function setProps(id, p) {
        let hit = false;
        const next = items.map(i => {
            if (i.id !== id)
                return i;
            hit = true;
            const c = Object.assign({}, i);
            c.props = Object.assign({}, i.props || {}, p);
            return c;
        });
        if (!hit)
            return;
        items = next;
        save();
    }

    function duplicate(id) {
        const src = get(id);
        if (!src || !src.id)
            return;
        const d = defOf(src.type);
        const it = {
            id: "w" + seq,
            type: src.type,
            screen: src.screen,
            x: src.x + 28,
            y: src.y + 28,
            w: d.w,
            h: src.h,
            visible: src.visible,
            props: Object.assign({}, src.props || {})
        };
        seq++;
        items = items.concat([it]);
        ids = ids.concat([it.id]);
        save();
    }

    function setEdit(v) {
        edit = !!v;
    }

    // true si une fenêtre occupe le bureau actif de cet écran (règle V2 :
    // les widgets du fond n'apparaissent que sur un bureau vide).
    function busyOn(outputName) {
        const spaces = Niri.workspacesOn(outputName);
        const active = {};
        let any = false;
        for (let i = 0; i < spaces.length; i++) {
            const s = spaces[i];
            if (s.is_focused || s.is_active) {
                active[s.id] = true;
                any = true;
            }
        }
        if (!any) {
            for (let i = 0; i < spaces.length; i++)
                active[spaces[i].id] = true;
        }
        const all = Niri.windows;
        for (let i = 0; i < all.length; i++) {
            if (Niri.isParked(all[i].id))
                continue;
            if (active[all[i].workspace_id])
                return true;
        }
        return false;
    }

    function toggleEdit() {
        edit = !edit;
    }

    function dump() {
        return JSON.stringify({
            seq: seq,
            items: items
        }, null, 2) + "\n";
    }

    function save() {
        saveT.restart();
    }

    function writeNow() {
        writeProc.command = ["bash", "-c", "cat > " + shellEscape(path) + " << 'EOF'\n" + dump() + "EOF"];
        writeProc.running = true;
    }

    function shellEscape(str) {
        return "'" + String(str).replace(/'/g, "'\\''") + "'";
    }

    function apply(obj) {
        if (!obj || !Array.isArray(obj.items))
            return;
        const valid = [];
        const idList = [];
        let maxSeq = 1;
        for (let i = 0; i < obj.items.length; i++) {
            const raw = obj.items[i];
            if (!raw || typeof raw.id !== "string" || !raw.id.length)
                continue;
            let known = false;
            for (let t = 0; t < types.length; t++)
                if (types[t].type === raw.type)
                    known = true;
            if (!known)
                continue;
            valid.push({
                id: raw.id,
                type: raw.type,
                screen: typeof raw.screen === "string" ? raw.screen : "",
                x: Number(raw.x) || 0,
                y: Number(raw.y) || 0,
                w: Number(raw.w) || defOf(raw.type).w,
                h: Number(raw.h) || defOf(raw.type).h,
                visible: raw.visible !== false,
                z: Number(raw.z) || 0,
                props: (raw.props && typeof raw.props === "object") ? raw.props : ({})
            });
            idList.push(raw.id);
            const n = Number(String(raw.id).replace(/[^0-9]/g, ""));
            if (n >= maxSeq)
                maxSeq = n + 1;
        }
        items = valid;
        ids = idList;
        seq = Math.max(Number(obj.seq) || 1, maxSeq);
    }

    Timer {
        id: saveT
        interval: 350
        onTriggered: root.writeNow()
    }

    FileView {
        path: root.path
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.apply(JSON.parse(text()));
            } catch (e) {
                console.log("[WidgetStore] parse error", e);
            }
            root.ready = true;
        }
    }

    Process {
        id: writeProc
    }
}
