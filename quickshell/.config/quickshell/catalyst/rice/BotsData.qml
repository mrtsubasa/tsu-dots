pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    property var bots: []
    property string status: ""

    function refresh() {
        Bridge.call(["bots-list"], function (r) {
            if (r && r.ok)
                bots = r.items || [];
            status = "rafraîchi";
        });
    }

    function startBot(dir) {
        Bridge.call(["bots-start", dir], function (r) {
            if (r && r.items)
                bots = r.items;
            status = r.status || "start";
        });
    }

    function stopBot(dir) {
        Bridge.call(["bots-stop", dir], function (r) {
            if (r && r.items)
                bots = r.items;
            status = r.status || "stop";
        });
    }

    function openBot(dir) { Bridge.call(["bots-open", dir], function () {}); }
    function copyToken(dir) {
        Bridge.call(["bots-copy", dir], function (r) {
            status = (r && (r.status || r.error)) ? (r.status || r.error) : "";
        });
    }
    function editConfig() { Bridge.call(["bots-edit"], function () {}); }
}
