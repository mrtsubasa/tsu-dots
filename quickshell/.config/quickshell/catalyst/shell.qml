//@ pragma Env QS_NO_RELOAD_POPUP=1
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.rice
import "./modules/bar/"
import "./modules/topbar/"
import "./modules/stage/"
import "./modules/notifs/"
import "./modules/osd/"
import "./modules/ai/"
import "./modules/vm/"
import "./modules/scripts/"
import "./modules/chat/"
import "./modules/bots/"
import "./modules/ops/"
import "./modules/wall/"
import "./modules/pkgs/"
import "./modules/dock/"
import "./modules/omarchy/"
import "./modules/blackarch/"
import "./modules/overview/"
import "./modules/widgets/"
import "./modules/dev/"

ShellRoot {
    // Instancie le moteur de thèmes dès le démarrage : c'est lui qui restaure
    // le thème complet (identité + palette + accents Hyprland) persisté.
    Component.onCompleted: Themes.refresh()

    TopBar {}
    Stage {}
    Toasts {}
    BarPopover {}
    Osd {}
    AiPanel {}
    VmPanel {}
    ScriptsPanel {}
    ChatPanel {}
    BotsPanel {}
    OpsPanel {}
    WallPanel {}
    PkgsPanel {}
    Dock {}
    OmarchyPanel {}
    BlackArchPanel {}
    Overview {}
    WidgetHost { layerKind: "desk" }
    WidgetHost { layerKind: "top" }
    WidgetEditor {}
    KitGallery {}

    IpcHandler {
        target: "panels"

        function ping(): string {
            return "ok";
        }

        function toggle(name: string): string {
            PanelService.toggle(name);
            return PanelService.active;
        }

        function show(name: string): string {
            PanelService.show(name);
            return PanelService.active;
        }

        function hide(): string {
            PanelService.hide();
            return "";
        }

        function setOutput(name: string): string {
            PanelService.setOutput(name);
            return PanelService.outputName;
        }

        function open(name: string, output: string): string {
            PanelService.open(name, output);
            return PanelService.active;
        }

        // ouvre le centre de contrôle sur une sous-page : net bt out in eq power
        function control(page: string): string {
            PanelService.controlPage = page || "";
            if (PanelService.active !== "control")
                PanelService.show("control");
            return PanelService.active;
        }

        // ouvre le Studio sur une page : themes wall bar dock desk panels profiles
        function studio(page: string): string {
            PanelService.studioPage = page || "";
            if (PanelService.active !== "studio")
                PanelService.show("studio");
            return PanelService.active;
        }

        function atelier(): string {
            PanelService.toggle("atelier");
            return PanelService.active;
        }

        function popover(id: string): string {
            PanelService.hidePopover();
            if (!id || !id.length)
                return "";
            const out = Niri.focusedOutput || (Quickshell.screens.length ? Quickshell.screens[0].name : "");
            PanelService.popoverGeom = { output: out, x: 0, w: 48 };
            PanelService.popover = id;
            return PanelService.popover;
        }
    }

    // touches média : l'état reste connu du shell (OSD, sliders)
    IpcHandler {
        target: "brightness"

        function up(): string {
            Bright.nudge(0.1);
            return String(Bright.percentage);
        }

        function down(): string {
            Bright.nudge(-0.1);
            return String(Bright.percentage);
        }

        function set(pct: string): string {
            Bright.set(Number(pct) / 100);
            return String(Bright.percentage);
        }
    }

    IpcHandler {
        target: "display"

        function truetone(state: string): string {
            Night.setTrueTone(state === "on" || state === "1" || state === "true");
            return Night.trueTone ? "on" : "off";
        }

        function night(state: string): string {
            if ((state === "on") !== Night.on)
                Night.toggle();
            return Night.on ? "on" : "off";
        }

        function status(): string {
            return JSON.stringify({ trueTone: Night.trueTone, night: Night.on, phase: Night.phase, elevation: Math.round(Night.elevation * 10) / 10, ambientK: Night.ambientK, targetK: Night.targetK, currentK: Night.currentK, ready: Night.ready, clouds: Weather.clouds });
        }
    }

    IpcHandler {
        target: "audio"

        function mic(): string {
            Audio.toggleMic();
            return Audio.micMuted ? "muted" : "live";
        }

        function processed(state: string): string {
            Mic.setProcessed(state === "on");
            return state;
        }

        function call(state: string): string {
            Mic.setCallMode(state === "on" ? true : (state === "off" ? false : !Mic.callMode));
            return Mic.callMode ? "on" : "off";
        }

        function status(): string {
            return JSON.stringify({ source: Audio.defaultSourceName, mic: Audio.sourceReady ? Audio.mic.name : "", muted: Audio.micMuted, processed: Mic.processed, ee: Mic.eeAvailable, call: Mic.callMode, micApps: Privacy.micApps, cam: Privacy.cameraApps, share: Privacy.screenShare });
        }
    }

    IpcHandler {
        target: "game"

        function toggle(): string {
            GameMode.toggle();
            return GameMode.active ? "on" : "off";
        }

        function status(): string {
            return JSON.stringify({ active: GameMode.active, manual: GameMode.manual, game: GameMode.game, dnd: Notifs.dnd, caffeine: Caffeine.on, profile: Power.current.key, auto: ShellCfg.autoGameMode });
        }
    }

    IpcHandler {
        target: "record"

        function toggle(mode: string): string {
            Recorder.toggle(mode || "region");
            return Recorder.recording ? "on" : "off";
        }

        function stop(): string {
            Recorder.stop();
            return "off";
        }
    }

    // qs ipc -p ~/.config/quickshell/catalyst call diag <fn> — état réel des services
    IpcHandler {
        target: "diag"

        function net(): string {
            return JSON.stringify({
                wired: Net.wired, wiredName: Net.wiredName, speed: Net.linkSpeed,
                hasWifi: Net.hasWifi, wifiOn: Net.wifiOn, ssid: Net.ssid,
                online: Net.online, label: Net.label, glyph: Net.glyph, nets: Net.networks.length,
                bt: Net.btOn
            });
        }

        function sys(): string {
            return JSON.stringify({ temp: SysInfo.temp, tempPath: SysInfo.tempPath, cpu: SysInfo.cpu, ram: SysInfo.ram, ramText: SysInfo.ramText, disk: SysInfo.diskText, up: SysInfo.uptime, clock: SysInfo.clock, date: SysInfo.date });
        }

        function streams(): string {
            const n = Pipewire.nodes.values || [];
            return JSON.stringify(n.filter(x => x.isStream).map(x => ({ name: x.name, desc: x.description, sink: x.isSink, type: String(x.type), props: x.properties ? Object.keys(x.properties).length : -1, mc: x.properties ? x.properties["media.class"] : null, app: x.properties ? x.properties["application.name"] : null })));
        }

        function arsenal(q: string): string {
            Arsenal.includeAvailable = true;
            Arsenal.query = q;
            return JSON.stringify({ inc: Arsenal.includeAvailable, query: Arsenal.query, remoteQuery: Arsenal.remoteQuery, remote: Arsenal.remote.length, searching: Arsenal.searching });
        }

        function search(q: string): string {
            Search.refreshDev();
            Search.setQuery(q);
            return JSON.stringify(Search.results.slice(0, 6).map(r => r.kind + " | " + r.title + " | " + (r.subtitle || "")));
        }

        function perf(): string {
            return JSON.stringify({ popups: Notifs.popupCount, held: Notifs.held.length, notifs: Notifs.count, posWatchers: Players.posWatchers, playing: Players.playing, sysFast: SysInfo.fastUsers, gpuUsers: Gpu.users, meter: Mic.meterUsers, monitoring: Mic.monitoring, ifacesFast: Ifaces.fastUsers, recording: Recorder.recording, active: PanelService.active, widgetsEdit: WidgetStore.edit });
        }

        function wm(): string {
            return JSON.stringify({ out: Niri.focusedOutput, title: Niri.focusedTitle, ws: Niri.workspaces.length, wins: Niri.windows.length });
        }
    }

    IpcHandler {
        target: "niri"

        function park(): string {
            Niri.parkFocused();
            return "ok";
        }

        function restore(id: string): string {
            Niri.restoreWindow(Number(id));
            return "ok";
        }
    }

    IpcHandler {
        target: "identity"

        function get(): string {
            return Theme.uiStyle;
        }

        function set(id: string): string {
            if (!id || !id.length)
                return Theme.uiStyle;
            Chrome.setIdentity(id);
            return Theme.uiStyle;
        }
    }

    // qs ipc -p ~/.config/quickshell/catalyst call theme <fn>
    IpcHandler {
        target: "widgets"

        function list(): string {
            return JSON.stringify(WidgetStore.items);
        }

        function add(type: string): string {
            return WidgetStore.add(type || "clock", "");
        }

        function remove(id: string): string {
            WidgetStore.remove(id);
            return "ok";
        }

        function edit(): string {
            WidgetStore.toggleEdit();
            return WidgetStore.edit ? "on" : "off";
        }

        function setedit(state: string): string {
            WidgetStore.setEdit(state === "on" || state === "1" || state === "true");
            return WidgetStore.edit ? "on" : "off";
        }
    }

    IpcHandler {
        target: "theme"

        function list(): string {
            const out = [];
            for (let i = 0; i < Themes.presets.length; i++)
                out.push(Themes.presets[i].id);
            return JSON.stringify(out);
        }

        function current(): string {
            return Themes.active;
        }

        function apply(id: string): string {
            Themes.apply(id);
            return Themes.active;
        }

        function auto(): string {
            Themes.setAuto();
            return "";
        }

        function save(label: string): string {
            Themes.saveCurrent(label);
            return "ok";
        }
    }

    IpcHandler {
        target: "eq"

        function status(): string {
            return JSON.stringify({
                enabled: Equalizer.enabled,
                ee: Equalizer.eeRunning,
                gains: Equalizer.gains,
                presets: Equalizer.presets,
                note: Equalizer.note,
                cfgReady: Equalizer.cfgReady,
                cfgLen: Equalizer.cfgText.length
            });
        }

        function on(): string {
            Equalizer.setEnabled(true);
            return Equalizer.enabled ? "on" : "off";
        }

        function off(): string {
            Equalizer.setEnabled(false);
            return Equalizer.enabled ? "on" : "off";
        }

        function gain(i: string, v: string): string {
            Equalizer.setGain(Number(i), Number(v));
            return JSON.stringify(Equalizer.gains);
        }

        function curve(id: string): string {
            Equalizer.applyCurve(id);
            return JSON.stringify(Equalizer.gains);
        }

        function save(label: string): string {
            return Equalizer.savePreset(label) || "";
        }

        function reload(): string {
            Equalizer.reloadCfg();
            return "reloading";
        }

        function load(name: string): string {
            Equalizer.loadPreset(name);
            return name;
        }
    }
}



// sync
