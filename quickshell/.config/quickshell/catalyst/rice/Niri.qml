pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string parkName: "park"
    property var workspaces: []
    property var windows: []
    property var parked: []
    property string focusedOutput: ""
    property string focusedTitle: ""
    property string focusedApp: ""
    property int focusedWindowId: 0
    property int lastWindowId: 0
    property string lastWindowOutput: ""
    property string _wsRaw: ""
    property string _winRaw: ""

    // ---- Hyprland backend (double backend : niri + hyprctl) ----
    readonly property bool hyprland: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE").length > 0
    property var _hyprWs: []
    property var _hyprMons: []
    property var _hyprWins: []
    property string _hyprActiveAddr: ""

    readonly property int windowCount: windows.length
    readonly property int parkedCount: parkedList.length
    readonly property int liveCount: liveList.length

    readonly property var visWs: {
        workspaces;
        return root.workspacesOn("");
    }

    readonly property var parkedList: {
        windows;
        parked;
        workspaces;
        return root.listParked();
    }

    readonly property var liveList: {
        windows;
        parked;
        workspaces;
        return root.listLive();
    }

    function isParkWs(ws) {
        return !!ws && String(ws.name || "") === parkName;
    }

    function wsById(wid) {
        const all = workspaces;
        for (let i = 0; i < all.length; i++) {
            if (all[i].id === wid)
                return all[i];
        }
        return null;
    }

    function winById(wid) {
        const all = windows;
        for (let i = 0; i < all.length; i++) {
            if (all[i].id === wid)
                return all[i];
        }
        return null;
    }

    function isParked(wid) {
        const w = winById(wid);
        if (w && isParkWs(wsById(w.workspace_id)))
            return true;
        const ids = parked;
        for (let i = 0; i < ids.length; i++) {
            if (ids[i] === wid)
                return true;
        }
        return false;
    }

    function markedParked(wid) {
        if (isParked(wid))
            return true;
        const ids = parked;
        for (let i = 0; i < ids.length; i++) {
            if (ids[i] === wid)
                return true;
        }
        return false;
    }

    function windowOnOutput(wid, outputName) {
        const w = winById(wid);
        if (!w || isParked(wid))
            return null;
        const ws = wsById(w.workspace_id);
        if (!ws || (outputName && ws.output !== outputName))
            return null;
        return w;
    }

    function visWindow(outputName) {
        const all = workspaces;
        let active = null;
        for (let i = 0; i < all.length; i++) {
            const s = all[i];
            if (isParkWs(s) || (outputName && s.output !== outputName))
                continue;
            if (s.is_focused) {
                active = s;
                break;
            }
            if (!active && s.is_active)
                active = s;
        }
        if (active && active.active_window_id) {
            const hit = windowOnOutput(active.active_window_id, outputName);
            if (hit)
                return hit;
        }
        const wins = windows;
        for (let i = 0; i < wins.length; i++) {
            if (wins[i].is_focused) {
                const hit = windowOnOutput(wins[i].id, outputName);
                if (hit)
                    return hit;
            }
        }
        const last = windowOnOutput(lastWindowId, outputName);
        if (last)
            return last;
        const live = windowsOn(outputName);
        return live.length ? live[0] : null;
    }

    function titleWindow(outputName) {
        return visWindow(outputName);
    }

    function listParked() {
        const all = windows;
        const out = [];
        for (let i = 0; i < all.length; i++) {
            if (markedParked(all[i].id))
                out.push(all[i]);
        }
        return out;
    }

    function listLive() {
        const all = windows;
        const out = [];
        for (let i = 0; i < all.length; i++) {
            if (!isParked(all[i].id))
                out.push(all[i]);
        }
        return out;
    }

    function workspacesOn(outputName) {
        const all = workspaces;
        let mine = [];
        for (let i = 0; i < all.length; i++) {
            if (isParkWs(all[i]))
                continue;
            if (!outputName || all[i].output === outputName)
                mine.push(all[i]);
        }
        mine.sort(function (a, b) {
            return (a.idx || 0) - (b.idx || 0);
        });
        return mine;
    }

    function windowsOn(outputName) {
        const spaces = workspacesOn(outputName);
        const ids = {};
        for (let i = 0; i < spaces.length; i++)
            ids[spaces[i].id] = true;
        const out = [];
        const all = windows;
        for (let i = 0; i < all.length; i++) {
            if (isParked(all[i].id))
                continue;
            if (ids[all[i].workspace_id])
                out.push(all[i]);
        }
        return out;
    }

    function activeIdx(outputName) {
        const all = workspaces;
        let fallback = 1;
        for (let i = 0; i < all.length; i++) {
            if (isParkWs(all[i]))
                continue;
            if (outputName && all[i].output !== outputName)
                continue;
            fallback = all[i].idx || fallback;
            if (all[i].is_focused || all[i].is_active)
                return all[i].idx;
        }
        return fallback;
    }

    function markParked(wid) {
        if (!wid || isParked(wid))
            return;
        parked = parked.concat([wid]);
    }

    function unmarkParked(wid) {
        const ids = parked;
        const next = [];
        for (let i = 0; i < ids.length; i++) {
            if (ids[i] !== wid)
                next.push(ids[i]);
        }
        if (next.length !== ids.length)
            parked = next;
    }

    function pruneParked(list) {
        const live = {};
        for (let i = 0; i < list.length; i++)
            live[list[i].id] = true;
        const ids = parked;
        const next = [];
        for (let i = 0; i < ids.length; i++) {
            if (live[ids[i]])
                next.push(ids[i]);
        }
        if (next.length !== ids.length)
            parked = next;
    }

    readonly property string parkBin: Quickshell.env("HOME") + "/.config/quickshell/catalyst/scripts/win-park.sh"

    function parkWindow(wid) {
        if (!wid)
            wid = focusedWindowId || lastWindowId;
        if (!wid) {
            Quickshell.execDetached(["bash", parkBin, "park"]);
            return;
        }
        const w = winById(wid);
        if (w && isParkWs(wsById(w.workspace_id)))
            return;
        markParked(wid);
        Quickshell.execDetached(["bash", parkBin, "park", String(wid)]);
    }

    function parkFocused() {
        const w = visWindow(focusedOutput);
        parkWindow(w ? w.id : (focusedWindowId || lastWindowId));
    }

    function restoreWindow(wid) {
        if (!wid)
            return;
        unmarkParked(wid);
        Quickshell.execDetached(["bash", parkBin, "restore", String(wid)]);
    }

    readonly property string dynWsBin: Quickshell.env("HOME") + "/.local/scripts/Workspace-Manager/dyn-ws.sh"

    function closeWindow(wid) {
        if (!wid)
            wid = focusedWindowId;
        if (!wid)
            return;
        unmarkParked(wid);
        if (hyprland) {
            const w = winById(wid);
            if (w && w.address)
                Quickshell.execDetached(["bash", "-c", "hyprctl dispatch focuswindow address:" + w.address + " && hyprctl dispatch killactive"]);
            return;
        }
        Quickshell.execDetached(["niri", "msg", "action", "close-window", "--id", String(wid)]);
    }

    function focusWindow(wid) {
        if (!wid)
            return;
        if (isParked(wid)) {
            restoreWindow(wid);
            return;
        }
        if (hyprland) {
            const w = winById(wid);
            if (w && w.address)
                Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "address:" + w.address]);
            return;
        }
        Quickshell.execDetached(["niri", "msg", "action", "focus-window", "--id", String(wid)]);
    }

    function addWorkspace() {
        if (hyprland) {
            Quickshell.execDetached([dynWsBin, "new"]);
            return;
        }
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/niri/scripts/ws.sh", "add"]);
    }

    function focusWorkspace(outputName, idx) {
        if (hyprland) {
            const args = [dynWsBin, "switch", String(idx)];
            if (outputName && outputName.length)
                args.push(outputName);
            Quickshell.execDetached(args);
            return;
        }
        const cmds = [];
        if (outputName && outputName.length)
            cmds.push("niri msg action focus-monitor " + outputName);
        cmds.push("niri msg action focus-workspace " + idx);
        actProc.command = ["bash", "-c", cmds.join(" && ")];
        actProc.running = true;
    }

    function workspaceUp() {
        if (hyprland) {
            Quickshell.execDetached([dynWsBin, "prev"]);
            return;
        }
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace-up"]);
    }

    function workspaceDown() {
        if (hyprland) {
            Quickshell.execDetached([dynWsBin, "next"]);
            return;
        }
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace-down"]);
    }

    function refresh() {
        if (hyprland) {
            hyprWsProc.running = true;
            hyprWinProc.running = true;
            hyprMonProc.running = true;
            hyprActiveProc.running = true;
            return;
        }
        wsProc.running = true;
        winProc.running = true;
        outProc.running = true;
    }

    function _addrToInt(addr) {
        if (!addr || typeof addr !== "string" || addr.indexOf("0x") !== 0)
            return 0;
        return Number(addr);
    }

    function _applyHypr() {
        const mons = _hyprMons;
        const wsInfo = {};
        let focusedOut = "";
        for (let i = 0; i < mons.length; i++) {
            const m = mons[i];
            if (m.focused)
                focusedOut = m.name;
            const aw = m.activeWorkspace;
            if (aw)
                wsInfo[aw.id] = { active: true, focused: !!m.focused };
        }

        const byMon = {};
        for (let i = 0; i < _hyprWs.length; i++) {
            const w = _hyprWs[i];
            if (w.id < 1)
                continue;
            if (!byMon[w.monitor])
                byMon[w.monitor] = [];
            byMon[w.monitor].push(w);
        }
        for (const mon in byMon)
            byMon[mon].sort((a, b) => a.id - b.id);

        const winByAddr = {};
        for (let i = 0; i < _hyprWins.length; i++)
            winByAddr[_hyprWins[i].address] = _hyprWins[i];

        const wsOut = [];
        for (let i = 0; i < _hyprWs.length; i++) {
            const w = _hyprWs[i];
            if (w.id < 1)
                continue;
            const info = wsInfo[w.id] || {};
            const list = byMon[w.monitor] || [];
            let pos = 0;
            for (let j = 0; j < list.length; j++) {
                if (list[j].id === w.id) {
                    pos = j + 1;
                    break;
                }
            }
            let awid = 0;
            if (w.lastwindow && w.lastwindow !== "0x0" && winByAddr[w.lastwindow])
                awid = _addrToInt(w.lastwindow);
            wsOut.push({
                id: w.id,
                name: w.name,
                output: w.monitor,
                idx: pos,
                windows: w.windows,
                is_active: !!info.active,
                is_focused: !!info.focused,
                is_urgent: false,
                active_window_id: awid,
                is_persistent: !!w.ispersistent
            });
        }

        const winOut = [];
        for (let i = 0; i < _hyprWins.length; i++) {
            const c = _hyprWins[i];
            const nid = _addrToInt(c.address);
            winOut.push({
                id: nid,
                address: c.address,
                title: c.title || "",
                app_id: c.class || "",
                workspace_id: c.workspace ? c.workspace.id : 0,
                is_focused: c.address === _hyprActiveAddr,
                is_floating: !!c.floating,
                pid: c.pid || 0
            });
        }

        const raw = JSON.stringify(wsOut);
        if (raw !== root._wsRaw) {
            root._wsRaw = raw;
            root.workspaces = wsOut;
        }
        const rawW = JSON.stringify(winOut);
        if (rawW !== root._winRaw) {
            root._winRaw = rawW;
            root.windows = winOut;
            root.pruneParked(winOut);
        }
        root.focusedOutput = focusedOut;

        let focused = null;
        for (let i = 0; i < winOut.length; i++) {
            if (winOut[i].is_focused) {
                focused = winOut[i];
                break;
            }
        }
        if (focused) {
            root.focusedTitle = focused.title || "";
            root.focusedApp = focused.app_id || "";
            root.focusedWindowId = focused.id || 0;
            root.lastWindowId = focused.id || root.lastWindowId;
            for (let i = 0; i < wsOut.length; i++) {
                if (wsOut[i].id === focused.workspace_id && wsOut[i].output)
                    root.lastWindowOutput = wsOut[i].output;
            }
        } else {
            root.focusedTitle = "";
            root.focusedApp = "";
            root.focusedWindowId = 0;
        }
    }

    function _parseList(buf) {
        try {
            const data = JSON.parse(buf);
            return Array.isArray(data) ? data : [];
        } catch (e) {
            return null;
        }
    }

    Timer {
        interval: 400
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: wsProc
        command: ["niri", "msg", "--json", "workspaces"]
        property string buf: ""
        stdout: SplitParser {
            onRead: data => wsProc.buf += data
        }
        onRunningChanged: if (running)
            buf = ""
        onExited: {
            const data = root._parseList(buf);
            if (!data)
                return;
            const raw = JSON.stringify(data);
            if (raw === root._wsRaw)
                return;
            root._wsRaw = raw;
            root.workspaces = data;
        }
    }

    Process {
        id: winProc
        command: ["niri", "msg", "--json", "windows"]
        property string buf: ""
        stdout: SplitParser {
            onRead: data => winProc.buf += data
        }
        onRunningChanged: if (running)
            buf = ""
        onExited: {
            const data = root._parseList(buf);
            if (!data)
                return;
            const raw = JSON.stringify(data);
            if (raw === root._winRaw)
                return;
            root._winRaw = raw;
            root.windows = data;
            root.pruneParked(data);
            let focused = null;
            for (let i = 0; i < data.length; i++) {
                if (data[i].is_focused) {
                    focused = data[i];
                    break;
                }
            }
            if (focused) {
                root.focusedTitle = focused.title || "";
                root.focusedApp = focused.app_id || "";
                root.focusedWindowId = focused.id || 0;
                root.lastWindowId = focused.id || root.lastWindowId;
                const ws = root.wsById(focused.workspace_id);
                if (ws && ws.output)
                    root.lastWindowOutput = ws.output;
            } else {
                root.focusedTitle = "";
                root.focusedApp = "";
                root.focusedWindowId = 0;
            }
        }
    }

    Process {
        id: outProc
        command: ["niri", "msg", "--json", "focused-output"]
        property string buf: ""
        stdout: SplitParser {
            onRead: data => outProc.buf += data
        }
        onRunningChanged: if (running)
            buf = ""
        onExited: {
            try {
                const data = JSON.parse(buf);
                if (typeof data === "string")
                    root.focusedOutput = data;
                else if (data && (data.name || data.output))
                    root.focusedOutput = data.name || data.output;
            } catch (e) {
            }
        }
    }

    Process {
        id: actProc
    }

    // ---- Hyprland backend processes ----
    Process {
        id: hyprWsProc
        command: ["hyprctl", "workspaces", "-j"]
        property string buf: ""
        stdout: SplitParser {
            onRead: data => hyprWsProc.buf += data
        }
        onRunningChanged: if (running)
            buf = ""
        onExited: {
            try {
                root._hyprWs = JSON.parse(buf || "[]");
            } catch (e) {
                root._hyprWs = [];
            }
            root._applyHypr();
        }
    }

    Process {
        id: hyprWinProc
        command: ["hyprctl", "clients", "-j"]
        property string buf: ""
        stdout: SplitParser {
            onRead: data => hyprWinProc.buf += data
        }
        onRunningChanged: if (running)
            buf = ""
        onExited: {
            try {
                root._hyprWins = JSON.parse(buf || "[]");
            } catch (e) {
                root._hyprWins = [];
            }
            root._applyHypr();
        }
    }

    Process {
        id: hyprMonProc
        command: ["hyprctl", "monitors", "-j"]
        property string buf: ""
        stdout: SplitParser {
            onRead: data => hyprMonProc.buf += data
        }
        onRunningChanged: if (running)
            buf = ""
        onExited: {
            try {
                root._hyprMons = JSON.parse(buf || "[]");
            } catch (e) {
                root._hyprMons = [];
            }
            root._applyHypr();
        }
    }

    Process {
        id: hyprActiveProc
        command: ["hyprctl", "activewindow", "-j"]
        property string buf: ""
        stdout: SplitParser {
            onRead: data => hyprActiveProc.buf += data
        }
        onRunningChanged: if (running)
            buf = ""
        onExited: {
            try {
                const d = JSON.parse(buf || "{}");
                root._hyprActiveAddr = (d && d.address) ? d.address : "";
            } catch (e) {
                root._hyprActiveAddr = "";
            }
            root._applyHypr();
        }
    }
}
