pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.rice

Item {
    id: root
    property string iconName: ""
    property string appId: ""
    property string label: ""
    property int size: 40
    property bool plain: false
    width: size
    height: size
    clip: true

    readonly property var desk: root.lookup(appId || iconName)

    readonly property string resolvedIcon: {
        if (desk && desk.icon)
            return String(desk.icon);
        const ic = String(iconName || "").trim();
        if (ic.length)
            return ic;
        const id = String(appId || "").trim();
        if (!id.length)
            return "";
        const last = id.split(".").pop();
        return last || id;
    }

    readonly property string resolvedLabel: label || (desk && desk.name ? desk.name : "") || appId || iconName || "?"

    readonly property bool generic: {
        const s = String(resolvedIcon || "").toLowerCase();
        return !s
            || s === "blackarch"
            || s.indexOf("blackarch") >= 0
            || s === "application-x-executable"
            || s === "application-default-icon"
            || s === "applications-other";
    }

    readonly property string letters: {
        const n = String(resolvedLabel || "?").trim();
        const parts = n.replace(/[^A-Za-z0-9]+/g, " ").trim().split(/\s+/).filter(function (s) {
            return s.length > 0;
        });
        if (parts.length >= 2)
            return (parts[0][0] + parts[1][0]).toUpperCase();
        return n.slice(0, 2).toUpperCase();
    }

    readonly property color tile: {
        const n = resolvedLabel || resolvedIcon || "x";
        let h = 0;
        for (let i = 0; i < n.length; i++)
            h = (h * 33 + n.charCodeAt(i)) % 360;
        return Qt.hsla(h / 360, 0.58, 0.50, 1);
    }

    readonly property url src: {
        const ic = String(resolvedIcon || "");
        if (!ic || root.generic)
            return "";
        if (ic.startsWith("/"))
            return "file://" + ic;
        if (ic.indexOf("://") >= 0)
            return ic;
        return "image://icon/" + ic;
    }

    function lookup(id) {
        const raw = String(id || "").trim();
        if (!raw)
            return null;
        const last = raw.split(".").pop();
        const aliases = {
            "spotify": "spotify",
            "zen": "zen-browser",
            "vesktop": "vesktop",
            "cursor": "cursor",
            "org.telegram.desktop": "telegram",
            "telegram": "telegram",
            "org.wails.netbird": "netbird",
            "netbird": "netbird"
        };
        const tries = [raw, raw.toLowerCase(), last, String(last).toLowerCase()];
        const a = aliases[raw.toLowerCase()] || aliases[String(last).toLowerCase()];
        if (a)
            tries.push(a);
        for (let i = 0; i < tries.length; i++) {
            const t = tries[i];
            if (!t)
                continue;
            const d = DesktopEntries.heuristicLookup(t);
            if (d && d.icon)
                return d;
            const byId = DesktopEntries.byId(t);
            if (byId && byId.icon)
                return byId;
        }
        return null;
    }

    Rectangle {
        anchors.fill: parent
        radius: Math.max(7, root.size * 0.22)
        visible: img.status !== Image.Ready
        color: root.tile
        border.width: 1
        border.color: Qt.alpha(root.tile, 0.7)
    }

    Image {
        id: img
        anchors.fill: parent
        anchors.margins: root.plain ? 0 : Math.max(1, Math.round(root.size * 0.08))
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        mipmap: true
        cache: true
        sourceSize.width: Math.max(48, root.size * 2)
        sourceSize.height: Math.max(48, root.size * 2)
        source: root.src
        visible: status === Image.Ready
        smooth: true
    }

    Text {
        visible: img.status !== Image.Ready
        anchors.centerIn: parent
        text: root.letters
        font.family: Theme.font
        font.pixelSize: Math.max(9, Math.round(root.size * 0.34))
        font.weight: Font.Black
        color: "#0b0f11"
    }
}
