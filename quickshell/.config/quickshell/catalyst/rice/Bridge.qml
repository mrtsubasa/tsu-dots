pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string script: Qt.resolvedUrl("../scripts/bridge.py").toString().replace("file://", "")
    property var _queue: []
    property var _cb: null
    property bool _busy: false

    function call(args, cb) {
        _queue.push({ args: args, cb: cb });
        _pump();
    }

    function _pump() {
        if (_busy || _queue.length === 0)
            return;
        const job = _queue.shift();
        _cb = job.cb;
        _busy = true;
        proc.stdoutBuf = "";
        proc.stderrBuf = "";
        proc.command = ["python3", script].concat(job.args);
        proc.running = true;
    }

    Process {
        id: proc
        property string stdoutBuf: ""
        property string stderrBuf: ""

        stdout: SplitParser {
            onRead: data => proc.stdoutBuf += data
        }
        stderr: SplitParser {
            onRead: data => proc.stderrBuf += data
        }

        onExited: code => {
            let result = null;
            try {
                result = JSON.parse(proc.stdoutBuf);
            } catch (e) {
                result = { ok: false, error: proc.stderrBuf || proc.stdoutBuf || ("exit " + code) };
            }
            const cb = root._cb;
            root._cb = null;
            root._busy = false;
            if (cb)
                cb(result);
            root._pump();
        }
    }
}
