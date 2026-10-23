pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.rice
import qs.kit

// Galerie du kit (dev) : qs ipc … call panels toggle kit
PanelWindow {
    id: win
    visible: PanelService.active === "kit" && PanelService.onScreen(screen)
    screen: Quickshell.screens.length > 1 ? Quickshell.screens[1] : Quickshell.screens[0]
    implicitWidth: 760
    implicitHeight: 620
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "catalyst-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property bool t1: true
    property bool t2: false
    property real v: 0.6
    property string seg: "a"

    Pane {
        anchors.fill: parent
        anchors.margins: 20
        level: 2
        shadow: true
        glow: true
        radius: Tokens.rXl

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            RowLayout {
                Txt { role: "hero"; text: "Catalyst Kit" }
                Item { Layout.fillWidth: true }
                Txt { role: "mono"; text: SysInfo.clock; color: Theme.textSub }
                IconButton { icon: "close"; tooltip: "Fermer"; onClicked: PanelService.hide() }
            }
            SectionHeader { Layout.fillWidth: true; text: "Boutons"; actionText: "Tout effacer" }
            RowLayout {
                spacing: 8
                Button { text: "Primaire"; icon: "bolt"; variant: "primary" }
                Button { text: "Secondaire"; variant: "secondary" }
                Button { text: "Ghost"; variant: "ghost" }
                Button { text: "Danger"; icon: "power_settings_new"; variant: "danger" }
                Button { text: "Chargement"; busy: true }
                IconButton { icon: "wifi"; tooltip: "Réseau" }
                IconButton { icon: "bluetooth"; active: true; tooltip: "Bluetooth actif" }
                IconButton { icon: "tune"; variant: "tonal" }
                IconButton { icon: "add"; variant: "filled" }
            }
            SectionHeader { Layout.fillWidth: true; text: "Contrôles" }
            RowLayout {
                spacing: 16
                Toggle { checked: win.t1; onToggled: v => win.t1 = v }
                Toggle { checked: win.t2; onToggled: v => win.t2 = v }
                Segmented {
                    model: [{ id: "a", label: "Rapide", icon: "bolt" }, { id: "b", label: "Panneaux" }, { id: "c", label: "Thèmes" }]
                    current: win.seg
                    onSelected: id => win.seg = id
                }
                Badge { count: 3 }
                Badge { dot: true }
                Spinner {}
                Ring { value: 0.42; label: "42" }
                Ring { value: 0.93; label: "93"; size: 36 }
            }
            RowLayout {
                spacing: 12
                Slider { Layout.preferredWidth: 300; icon: "volume_up"; iconOff: "volume_off"; value: win.v; onMoved: v => win.v = v }
                Slider { Layout.preferredWidth: 300; icon: "brightness_6"; value: 0.3; muted: true; iconOff: "brightness_low" }
            }
            RowLayout {
                spacing: 10
                Tile { Layout.preferredWidth: 220; icon: "lan"; title: "Ethernet"; subtitle: "1 Gb/s"; active: true; expandable: true }
                Tile { Layout.preferredWidth: 220; icon: "bluetooth"; title: "Bluetooth"; subtitle: "Désactivé"; expandable: true }
                Tile { Layout.preferredWidth: 220; icon: "dark_mode"; title: "Lumière nocturne"; subtitle: "Indisponible"; unavailable: true }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true
                    ListItem { Layout.fillWidth: true; icon: "headphones"; title: "Casque AirPods"; subtitle: "Sortie active"; selected: true; checked: true }
                    ListItem { Layout.fillWidth: true; icon: "speaker"; title: "Haut-parleurs"; trailingText: "48 kHz" }
                }
                SearchField { Layout.preferredWidth: 280; placeholder: "Rechercher une application…" }
            }
            EmptyState { Layout.fillWidth: true; title: "Aucune notification"; text: "Tout est calme." }
        }
    }
}
