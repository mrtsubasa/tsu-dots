pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    property var scripts: []
    property string filter: ""

    function refresh(f) {
        if (f !== undefined)
            filter = f;
        Bridge.call(["scripts-list", filter], function (r) {
            if (r && r.ok)
                scripts = r.items || [];
        });
    }

    function run(path) { Bridge.call(["scripts-run", path], function () {}); }
    function term(path) { Bridge.call(["scripts-term", path], function () {}); }
    function edit(path) { Bridge.call(["scripts-edit", path], function () {}); }
    function remove(path) {
        Bridge.call(["scripts-delete", path], function (r) {
            if (r && r.items)
                scripts = r.items;
        });
    }
    function create(name) {
        Bridge.call(["scripts-new", name], function (r) {
            if (r && r.items)
                scripts = r.items;
        });
    }
    function openFolder() { Bridge.call(["scripts-folder"], function () {}); }
}
