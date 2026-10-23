pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    property var apps: []
    property var convs: []
    property string status: "Prêt"
    property string dest: "telegram"
    property string chatId: ""
    property string chatName: ""

    readonly property bool hasConv: chatId.length > 0

    function refresh() {
        Bridge.call(["chat-apps"], function (r) {
            if (r && r.ok)
                apps = r.items || [];
        });
        status = "…";
        Bridge.call(["chat-convs"], function (r) {
            if (r && r.ok)
                convs = r.items || [];
            if (!chatId && convs.length) {
                dest = convs[0].dest || dest;
                chatId = convs[0].id || "";
                chatName = convs[0].name || "";
            }
            status = convs.length ? (convs.length + " convs") : "aucune conv";
        });
    }

    function pick(c) {
        if (!c)
            return;
        dest = c.dest || "telegram";
        chatId = String(c.id || "");
        chatName = c.name || chatId;
    }

    function selected(c) {
        return c && dest === c.dest && String(c.id) === chatId;
    }

    function openApp(id) {
        Bridge.call(["chat-open", id], function () {});
    }

    function send(text) {
        const t = String(text || "").trim();
        if (!t.length)
            return;
        status = "envoi…";
        Bridge.call(["chat-send", dest, chatId || "-", t], function (r) {
            if (r && r.items)
                convs = r.items;
            status = (r && (r.status || r.error)) ? (r.status || r.error) : "erreur";
        });
    }
}
