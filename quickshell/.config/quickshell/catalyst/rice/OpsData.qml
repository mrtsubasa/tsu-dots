pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    property string target: ""
    property string cat: "recon"
    property var tiles: []
    property string status: ""

    function refresh() {
        Bridge.call(["ops-tiles", cat], function (r) {
            if (!r || !r.ok)
                return;
            tiles = r.items || [];
            target = r.target || target;
            status = "ok";
        });
    }

    function setCat(c) {
        cat = c;
        refresh();
    }

    function setTarget(v) {
        Bridge.call(["ops-target", v], function (r) {
            if (r) {
                target = r.target || v;
                status = r.status || "";
            }
        });
    }

    function run(id) {
        Bridge.call(["ops-run", id], function (r) {
            status = (r && r.status) ? r.status : "";
        });
    }
}
