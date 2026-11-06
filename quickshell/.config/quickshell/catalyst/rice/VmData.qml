pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/*
 * VmData — état du gestionnaire de VM (scripts/vmctl.py, libvirt).
 * L'état n'est sondé que panneau ouvert ou création en cours. Les créations
 * tournent hors du shell : elles survivent à un redémarrage de Catalyst.
 */
Singleton {
    id: root

    readonly property string script: Quickshell.env("HOME") + "/.config/quickshell/catalyst/scripts/vmctl.py"

    property var vms: []
    property var jobs: []
    property var isos: []
    property var host: null
    property bool loaded: false

    property string request: ""
    property var plan: null
    property bool planning: false
    property string planError: ""

    property string status: ""
    property bool statusError: false
    property string busyVm: ""
    property string selected: ""     // "" = écran de création

    readonly property var current: {
        for (let i = 0; i < vms.length; i++)
            if (vms[i].name === selected)
                return vms[i];
        return null;
    }
    readonly property var usableIsos: isos.filter(i => i.complete)
    readonly property int runningCount: vms.filter(v => v.running).length
    readonly property bool jobActive: jobs.some(j => j.state === "running")

    Component {
        id: procC
        Process {
            property var done: null
            property string buf: ""
            stdout: SplitParser { onRead: data => buf += data }
            onExited: {
                let r = null;
                try { r = JSON.parse(buf); } catch (e) {}
                if (done)
                    done(r || { ok: false, error: "réponse illisible de vmctl" });
                destroy();
            }
        }
    }

    function call(args, done) {
        const p = procC.createObject(root, { command: ["python3", script].concat(args), done: done });
        p.running = true;
    }

    function setStatus(text, isError) {
        status = text || "";
        statusError = !!isError;
    }

    property bool _refreshing: false
    function refresh() {
        if (_refreshing)
            return;
        _refreshing = true;
        call(["list"], r => {
            _refreshing = false;
            if (!r.ok) {
                setStatus(r.error, true);
                return;
            }
            vms = r.vms;
            jobs = r.jobs;
            isos = r.isos;
            host = r.host;
            loaded = true;
        });
    }

    Timer {
        // lent au repos : juste de quoi tenir à jour le compteur de la barre
        interval: PanelService.active === "vm" || root.jobActive ? 3000 : 30000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // Repart d'une demande vierge, y compris depuis l'écran de création lui-même.
    signal newVmRequested()
    function newVm() {
        selected = "";
        request = "";
        plan = null;
        planError = "";
        searchResults = null;
        searchError = "";
        setStatus("");
        newVmRequested();
    }

    // ---- plan proposé par l'IA ----
    function ask(text) {
        const t = (text || "").trim();
        if (planning)
            return;
        if (!t.length) {
            planError = "Écris d'abord un OS ou choisis un fichier : par exemple « kali pour du pentest ».";
            newVmRequested();
            return;
        }
        request = t;
        searchResults = null;
        searchError = "";
        mirrorsOpen = false;
        planning = true;
        planError = "";
        plan = null;
        call(["plan", t], onPlan);
    }

    // ---- recherche d'ISO sur le web ----
    property var searchResults: null    // { known, results, rejected }
    property bool searching: false
    property string searchError: ""

    function searchWeb(text) {
        const t = (text || "").trim();
        if (searching)
            return;
        if (!t.length) {
            searchError = "Écris le nom de l'OS à chercher.";
            newVmRequested();
            return;
        }
        request = t;
        plan = null;
        planError = "";
        searchError = "";
        searchResults = null;
        searching = true;
        call(["search", t], r => {
            searching = false;
            if (r.ok)
                searchResults = r;
            else
                searchError = r.error;
        });
    }

    function useResult(result) {
        if (planning)
            return;
        searchResults = null;
        planning = true;
        planError = "";
        plan = null;
        if (result.type === "quickget")
            call(["plan", result.name], onPlan);
        else
            call(["plan", "--source", JSON.stringify(result), result.name + " " + result.version], onPlan);
    }

    function refine(text) {
        const t = (text || "").trim();
        if (!t.length || planning || !plan)
            return;
        planning = true;
        planError = "";
        call(["plan", "--refine", JSON.stringify(plan), t], onPlan);
    }

    function onPlan(r) {
        planning = false;
        if (r.ok)
            plan = r.plan;
        else
            planError = r.error;
    }

    function tweak(key, value) {
        const next = Object.assign({}, plan);
        next[key] = value;
        plan = next;
    }

    // ---- serveur de téléchargement par pays ----
    property bool mirrorsOpen: false
    property var mirrorInfo: null
    property bool mirrorsLoading: false
    property string mirrorCountry: ""
    property var mirrorTests: ({})
    property var _testQueue: []
    property bool _testing: false
    readonly property bool mirrorTesting: _testing || _testQueue.length > 0

    readonly property var countryMirrors: {
        if (!mirrorInfo)
            return [];
        const c = mirrorInfo.countries.find(x => x.name === mirrorCountry);
        if (!c)
            return [];
        const tests = mirrorTests;
        // testés et joignables d'abord, du plus rapide au plus lent
        const score = m => {
            const t = tests[m.url];
            return t ? (t.reachable ? t.speed : -2) : -1;
        };
        return c.mirrors.slice().sort((a, b) => score(b) - score(a));
    }
    readonly property real bestSpeed: countryMirrors.reduce((best, m) => {
        const t = mirrorTests[m.url];
        return t && t.reachable ? Math.max(best, t.speed) : best;
    }, 0)
    readonly property real bestLatency: countryMirrors.reduce((best, m) => {
        const t = mirrorTests[m.url];
        return t && t.reachable ? Math.min(best, t.latencyMs) : best;
    }, Infinity)

    function loadMirrors() {
        if (!plan || plan.source.type !== "quickget")
            return;
        mirrorInfo = null;
        mirrorCountry = "";
        mirrorTests = {};
        _testQueue = [];
        mirrorsLoading = true;
        call(["mirrors", JSON.stringify(plan.source)], r => {
            mirrorsLoading = false;
            mirrorInfo = r.ok ? r : { supported: false, reason: r.error, countries: [] };
        });
    }

    function selectCountry(name) {
        mirrorCountry = name;
        const c = mirrorInfo.countries.find(x => x.name === name);
        _testQueue = c.mirrors.slice(0, 8).map(m => m.url).filter(u => !mirrorTests[u]);
        _nextTest();
    }

    function testMirror(url) {
        _testQueue = [url].concat(_testQueue.filter(u => u !== url));
        _nextTest();
    }

    function _nextTest() {
        if (_testing || !_testQueue.length || !plan)
            return;
        const url = _testQueue[0];
        _testQueue = _testQueue.slice(1);
        _testing = true;
        call(["mirror-test", JSON.stringify(plan.source), url], r => {
            _testing = false;
            const next = Object.assign({}, mirrorTests);
            next[url] = r.ok ? r : { reachable: false, error: r.error };
            mirrorTests = next;
            _nextTest();
        });
    }

    function chooseMirror(m) {
        const source = Object.assign({}, plan.source);
        if (m) {
            source.mirror = m.url;
            source.mirrorHost = m.host;
            source.mirrorCountry = m.country;
        } else {
            delete source.mirror;
            delete source.mirrorHost;
            delete source.mirrorCountry;
        }
        tweak("source", source);
    }

    function create() {
        if (!plan)
            return;
        call(["create", JSON.stringify(plan)], r => {
            if (!r.ok) {
                planError = r.error;
                return;
            }
            plan = null;
            request = "";
            setStatus("");
            refresh();
        });
    }

    function dismissJob(id) {
        call(["job-cancel", id], () => refresh());
    }

    // ---- actions sur une VM ----
    function act(name, args) {
        busyVm = name;
        call(args, r => {
            busyVm = "";
            setStatus(r.ok ? r.status : r.error, !r.ok);
            refresh();
        });
    }
    function start(name) { PanelService.hide(); act(name, ["start", name]); }
    function console_(name) { PanelService.hide(); act(name, ["console", name]); }
    function shutdown(name) { act(name, ["shutdown", name]); }
    function kill(name) { act(name, ["kill", name]); }
    function remove(name) {
        selected = "";
        act(name, ["delete", name]);
    }
    function snapshot(name, action, label) { act(name, ["snapshot", name, action, label]); }

    // ---- sélecteur de fichier : le Stage masquerait la fenêtre, on le ferme ----
    signal filePicked(string path)
    Process {
        id: picker
        property string buf: ""
        command: ["zenity", "--file-selection", "--title=Image ou disque de la VM",
            "--file-filter=Images de VM | *.iso *.qcow2 *.qcow *.vmdk *.vdi *.vhd *.vhdx *.ova *.img *.raw",
            "--file-filter=Tous les fichiers | *"]
        stdout: SplitParser { onRead: data => picker.buf += data }
        onExited: {
            PanelService.show("vm");
            const path = picker.buf.trim();
            if (path.length) {
                root.selected = "";
                root.ask(path);
            }
        }
    }
    function pickFile() {
        picker.buf = "";
        PanelService.hide();
        picker.running = true;
    }
    function deleteIso(path, detach) {
        call(["iso-delete", path].concat(detach ? ["--detach"] : []), r => {
            setStatus(r.ok ? r.status : r.error, !r.ok);
            refresh();
        });
    }

    function openFolder() {
        PanelService.hide();
        Quickshell.execDetached(["xdg-open", Quickshell.env("HOME") + "/VMs"]);
    }
}
