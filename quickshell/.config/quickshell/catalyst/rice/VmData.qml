pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    property var vms: []
    property var osList: []
    property var releases: []
    property bool downloading: false
    property string status: ""

    function refresh() {
        Bridge.call(["vm-list"], function (r) {
            if (!r || !r.ok)
                return;
            vms = r.items || [];
            if (r.osList)
                osList = r.osList;
            if (osList.length > 0 && releases.length === 0)
                osChanged(osList[0]);
        });
    }

    function osChanged(osName) {
        Bridge.call(["vm-releases", osName], function (r) {
            if (r && r.ok)
                releases = r.releases || [];
        });
    }

    function startVm(name) {
        Bridge.call(["vm-start", name], function (r) {
            if (r && r.items)
                vms = r.items;
            status = r.status || "";
        });
    }

    function deleteVm(name) {
        Bridge.call(["vm-delete", name], function (r) {
            if (r && r.items)
                vms = r.items;
            status = r.status || "";
        });
    }

    function createVm(osName, release) {
        if (!osName || !release) {
            status = "échec : choisis un OS et une version";
            return;
        }
        downloading = true;
        status = "téléchargement de " + osName + " " + release + "…";
        Bridge.call(["vm-create", osName, release], function (r) {
            downloading = false;
            if (r && r.ok) {
                status = r.status || "terminé";
                if (r.items) vms = r.items;
            } else {
                status = "échec : " + ((r && r.error) || "inconnu");
            }
        });
    }

    function openFolder() {
        Bridge.call(["vm-folder"], function () {});
    }
}
