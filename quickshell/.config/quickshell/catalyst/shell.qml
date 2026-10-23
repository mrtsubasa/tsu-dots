//@ pragma Env QS_NO_RELOAD_POPUP=1
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.rice
import "./modules/bar/"
import "./modules/atelier/"
import "./modules/osd/"
import "./modules/notifications/"
import "./modules/dashboard/"
import "./modules/launcher/"
import "./modules/ai/"
import "./modules/vm/"
import "./modules/scripts/"
import "./modules/chat/"
import "./modules/bots/"
import "./modules/ops/"
import "./modules/clip/"
import "./modules/wall/"
import "./modules/binds/"
import "./modules/pkgs/"
import "./modules/dock/"
import "./modules/omarchy/"
import "./modules/blackarch/"
import "./modules/overview/"
import "./modules/widgets/"

ShellRoot {
    // Instancie le moteur de thèmes dès le démarrage : c'est lui qui restaure
    // le thème complet (identité + palette + accents Hyprland) persisté.
    Component.onCompleted: Themes.refresh()

    Bar {}
    BarPopover {}
    Atelier {}
    Osd {}
    NotifPopup {}
    Dashboard {}
    Launcher {}
    AiPanel {}
    VmPanel {}
    ScriptsPanel {}
    ChatPanel {}
    BotsPanel {}
    OpsPanel {}
    ClipPanel {}
    WallPanel {}
    BindsPanel {}
    PkgsPanel {}
    Dock {}
    OmarchyPanel {}
    BlackArchPanel {}
    Overview {}
    WidgetHost { layerKind: "desk" }
    WidgetHost { layerKind: "top" }
    WidgetEditor {}

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
