pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var cfg: ({})
    property string userName: "user"
    property string userLogin: "user"
    property string userInitial: "?"
    property string hostName: "host"
    property string osText: ""
    property bool showOs: true
    property string kernelText: ""
    property string wmText: "niri"
    property string uptimeText: ""
    property string avatar: ""
    property bool hasAvatar: false
    property string userStatus: ""
    property string avatarShape: "circle"
    property string avatarRaw: ""
    property string bg: ""
    property bool hasBg: false
    property string wallpaper: ""
    property string grain: ""
    property string style: "islands"

    readonly property string slot: cfg.slot || "mr"
    readonly property int width: cfg.width || 360
    readonly property real veil: cfg.veil ?? 0.78
    readonly property real grainAmt: cfg.grain ?? 0.12
    readonly property bool vignette: cfg.vignette !== false
    readonly property bool halo: cfg.halo !== false
    readonly property bool showClock: cfg.show_clock !== false
    readonly property bool showStats: cfg.show_stats !== false
    readonly property bool showActions: cfg.show_actions !== false
    readonly property bool showPower: cfg.show_power !== false
    readonly property int radius: cfg.radius ?? 16
    readonly property string glow: cfg.glow || "neon"
    readonly property string borderMode: cfg.border || "accent"
    readonly property string density: cfg.density || "air"
    readonly property bool clock12: !!cfg.clock12
    readonly property bool clockSec: !!cfg.clock_sec
    readonly property string clockSize: cfg.clock_size || "l"
    readonly property bool showUser: cfg.show_user !== false
    readonly property bool showMeta: cfg.show_meta !== false
    readonly property bool showDate: cfg.show_date !== false
    readonly property string heightMode: cfg.height_mode || "auto"
    readonly property string panelStyle: cfg.panel_style || "follow"
    property bool dockOn: true
    property string dockTheme: "lain"
    property string dockPos: "bottom"
    property int dockSize: 40
    property real dockZoom: 1.45
    property real dockOpacity: 0.75
    property string barOutput: "all"
    property int inflight: 0

    function apply(r) {
        if (!r || r.ok === false)
            return;
        cfg = r.cfg || cfg;
        const c = cfg || {};
        userName = r.userName || userName;
        userLogin = r.userLogin || userLogin;
        userInitial = r.userInitial || userInitial;
        hostName = r.hostName || hostName;
        osText = r.osText || "";
        showOs = r.showOs !== false;
        kernelText = r.kernelText || kernelText;
        wmText = r.wmText || wmText;
        uptimeText = r.uptimeText || uptimeText;
        avatar = r.avatar || "";
        hasAvatar = !!r.hasAvatar;
        userStatus = r.userStatus !== undefined ? r.userStatus : userStatus;
        if (c.avatar_shape && c.avatar_shape.length)
            avatarShape = c.avatar_shape;
        avatarRaw = c.avatar !== undefined && c.avatar !== null ? String(c.avatar) : "";
        bg = r.bg || "";
        hasBg = !!r.hasBg;
        wallpaper = r.wallpaper || wallpaper;
        grain = r.grain || grain;
        style = r.style || style;
        Theme.uiStyle = style;
    }

    function reload() {
        if (inflight > 0)
            return;
        Bridge.call(["identity"], apply);
    }

    function studio(cmd) {
        inflight++;
        if (cmd.indexOf("shape:") === 0)
            avatarShape = cmd.slice(6);
        else if (cmd.indexOf("status:") === 0)
            userStatus = cmd.slice(7);
        else if (cmd.indexOf("name:") === 0 && cmd.length > 5)
            userName = cmd.slice(5);
        else if (cmd === "avatar:auto")
            avatarRaw = "";
        else if (cmd === "avatar:none")
            avatarRaw = "none";
        Bridge.call(["studio", cmd], function (r) {
            apply(r);
            inflight = Math.max(0, inflight - 1);
        });
    }

    function dash(cmd) {
        Bridge.call(["dash", cmd], function () {});
    }

    function pickAvatar() {
        inflight++;
        Bridge.call(["pick-avatar"], function (r) {
            apply(r);
            inflight = Math.max(0, inflight - 1);
        });
    }

    readonly property int avatarRadius: avatarShape === "square" ? 6 : (avatarShape === "soft" ? 12 : 99)

    FileView {
        path: Quickshell.env("HOME") + "/.config/spell-shell/panel.json"
        watchChanges: true
        onFileChanged: {
            if (root.inflight <= 0)
                root.reload();
        }
        onLoaded: root.reload()
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/waybar/rice.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const o = JSON.parse(text());
                root.dockOn = o.dock !== false;
                if (o.dock_style)
                    root.dockTheme = o.dock_style;
                root.barOutput = o.bar_output || "all";
            } catch (e) {
            }
        }
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/dock/dock.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const o = JSON.parse(text());
                if (o.theme)
                    root.dockTheme = o.theme;
                if (o.position)
                    root.dockPos = o.position;
                if (o.icon_size)
                    root.dockSize = o.icon_size;
                if (o.max_scale)
                    root.dockZoom = o.max_scale;
                if (o.opacity !== undefined)
                    root.dockOpacity = o.opacity;
            } catch (e) {
            }
        }
    }

    Component.onCompleted: reload()
}
