pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    property string cwd: home
    property var history: []
    property var lines: []
    property bool busy: false
    property int histIndex: -1
    property string draft: ""

    readonly property string cwdPretty: {
        const h = home;
        if (cwd === h)
            return "~";
        if (cwd.startsWith(h + "/"))
            return "~" + cwd.slice(h.length);
        return cwd;
    }

    function pushLine(kind, text) {
        const t = String(text);
        if (!t.length)
            return;
        const next = lines.concat([{ k: kind, t: t }]);
        lines = next.length > 90 ? next.slice(next.length - 90) : next;
    }

    function remember(cmd) {
        const c = cmd.trim();
        if (!c.length)
            return;
        const cur = history.filter(x => x !== c);
        cur.unshift(c);
        history = cur.slice(0, 40);
        histIndex = -1;
        draft = "";
        save();
    }

    function histPrev(current) {
        if (!history.length)
            return current;
        if (histIndex < 0)
            draft = current;
        if (histIndex < history.length - 1)
            histIndex++;
        return history[histIndex] || current;
    }

    function histNext() {
        if (histIndex <= 0) {
            histIndex = -1;
            return draft;
        }
        histIndex--;
        return history[histIndex] || draft;
    }

    function clearLog() {
        lines = [];
    }

    function kill() {
        if (job.running)
            job.running = false;
        busy = false;
    }

    function spawn() {
        Quickshell.execDetached(["alacritty", "--working-directory", cwd || home]);
    }

    function spawnCmd(cmd) {
        const c = cmd.trim();
        if (!c.length) {
            spawn();
            return;
        }
        remember(c);
        pushLine("cmd", cwdPretty + "  ▸  " + c);
        Quickshell.execDetached(["alacritty", "--working-directory", cwd || home, "-e", "bash", "-lc", c + "; echo; exec bash"]);
    }

    function run(cmd) {
        const c = String(cmd || "").trim();
        if (!c.length)
            return;
        if (c === "clear") {
            clearLog();
            remember(c);
            return;
        }
        if (c === "exit") {
            PanelService.hidePopover();
            return;
        }
        const cd = c.match(/^cd(?:\s+(.*))?$/);
        if (cd) {
            remember(c);
            goCd((cd[1] || "~").trim() || "~");
            return;
        }
        if (job.running)
            job.running = false;
        remember(c);
        pushLine("cmd", cwdPretty + "  ▸  " + c);
        busy = true;
        job.workingDirectory = cwd || home;
        job.command = ["bash", "-lc", c];
        job.running = true;
    }

    function goCd(arg) {
        let target = arg;
        if (target === "~" || target === "")
            target = home;
        else if (target.startsWith("~/"))
            target = home + target.slice(1);
        const q = s => "'" + String(s).replace(/'/g, "'\\''") + "'";
        cdProc.command = ["bash", "-lc", "cd -- " + q(cwd || home) + " && cd -- " + q(target) + " && pwd -P"];
        cdProc.running = true;
        pushLine("cmd", cwdPretty + "  ▸  cd " + arg);
    }

    function save() {
        writeProc.command = ["bash", "-c", "mkdir -p \"$HOME/.cache/catalyst\" && cat > \"$HOME/.cache/catalyst/term-history.json\" << 'EOF'\n" + JSON.stringify({ cwd: cwd, history: history }) + "\nEOF"];
        writeProc.running = true;
    }

    FileView {
        path: root.home + "/.cache/catalyst/term-history.json"
        watchChanges: true
        onLoaded: {
            try {
                const o = JSON.parse(text());
                if (o.cwd)
                    root.cwd = o.cwd;
                if (o.history && o.history.length)
                    root.history = o.history;
            } catch (e) {
            }
        }
    }

    Process {
        id: job
        property string buf: ""
        stdout: SplitParser {
            onRead: data => root.pushLine("out", data)
        }
        stderr: SplitParser {
            onRead: data => root.pushLine("err", data)
        }
        onRunningChanged: if (running)
            buf = ""
        onExited: code => {
            root.busy = false;
            if (code !== 0)
                root.pushLine("err", "↵ " + code);
        }
    }

    Process {
        id: cdProc
        property string buf: ""
        stdout: SplitParser {
            onRead: data => cdProc.buf += data
        }
        onRunningChanged: if (running)
            buf = ""
        onExited: code => {
            const p = cdProc.buf.trim();
            if (code === 0 && p.length) {
                root.cwd = p;
                root.pushLine("out", p.replace(root.home, "~"));
                root.save();
            } else {
                root.pushLine("err", "cd : dossier introuvable");
            }
        }
    }

    Process { id: writeProc }
}
