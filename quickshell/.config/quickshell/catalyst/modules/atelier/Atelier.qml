pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.rice
import "../../components"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            visible: ShellCfg.atelier && PanelService.active === "atelier" && PanelService.onScreen(modelData)
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            implicitWidth: 456
            WlrLayershell.namespace: "catalyst-atelier"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            anchors { top: true; bottom: true; left: true; right: true }

            property string tab: "home"
            property real appear: visible ? 1 : 0
            Behavior on appear { NumberAnimation { duration: 340; easing.type: Easing.OutCubic } }

            readonly property color wolfCyan: Theme.primary
            readonly property color wolfMagenta: Theme.tertiary
            readonly property color wolfVoid: Theme.inkPrimary
            readonly property color wolfInk: Theme.ink
            readonly property color wolfMuted: Theme.inkMuted

            readonly property var tabs: [
                { id: "home", icon: "󰍹", label: "Quick" },
                { id: "panel", icon: "󰉼", label: "Panel" },
                { id: "bar", icon: "󰛐", label: "Barre" },
                { id: "dock", icon: "󰕬", label: "Dock" },
                { id: "desk", icon: "󰢔", label: "Bureau" },
                { id: "theme", icon: "󰏘", label: "Thème" }
            ]

            onTabChanged: WidgetStore.setEdit(tab === "desk")

            onVisibleChanged: {
                if (visible) {
                    Identity.reload();
                    Palettes.listThemes();
                    SysInfo.refresh();
                    tabReq.reload();
                    // l'onglet peut ne pas changer : on resynchronise l'édition
                    WidgetStore.setEdit(win.tab === "desk");
                } else {
                    WidgetStore.setEdit(false);
                }
            }

            FileView {
                id: tabReq
                path: Quickshell.env("HOME") + "/.cache/catalyst/atelier-tab"
                onLoaded: {
                    const t = text().trim();
                    if (t.length)
                        win.tab = t;
                    Quickshell.execDetached(["rm", "-f", path]);
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: PanelService.hide()
            }

            Item {
                id: hud
                width: 456
                height: parent.height - 32
                x: parent.width - width - 14 + (1 - win.appear) * (width + 28)
                y: 16
                opacity: win.appear

                MouseArea { anchors.fill: parent }

                Surface {
                    anchors.fill: parent
                    elev: 3
                    photo: true
                    radius: Tokens.rLg
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    anchors.topMargin: 18
                    anchors.bottomMargin: 20
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Rectangle {
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 48
                            radius: 24
                            clip: true
                            color: Theme.primary
                            Image {
                                visible: Identity.hasAvatar
                                anchors.fill: parent
                                source: Identity.avatar ? "file://" + Identity.avatar : ""
                                fillMode: Image.PreserveAspectCrop
                            }
                            Text {
                                visible: !Identity.hasAvatar
                                anchors.centerIn: parent
                                text: Identity.userInitial
                                font.family: Theme.uiFont
                                font.pixelSize: 16
                                font.weight: Font.Black
                                color: Theme.inkPrimary
                            }
                        }
                        Column {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "Atelier"
                                font.family: Theme.uiFont
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                                color: Theme.ink
                            }
                            Text {
                                text: Identity.userName + "  ·  " + SysInfo.uptime
                                font.family: Theme.uiFont
                                font.pixelSize: 11
                                color: Theme.inkMuted
                            }
                        }
                        IconBtn { icon: "󰅖"; onClicked: PanelService.hide() }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 44
                        radius: 22
                        color: Qt.alpha(Theme.surfaceContainerLow, 0.55)
                        border.width: 1
                        border.color: Qt.alpha(Theme.primary, 0.12)
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 4
                            Repeater {
                                model: win.tabs
                                delegate: Rectangle {
                                    id: tabCell
                                    required property var modelData
                                    readonly property bool on: win.tab === modelData.id
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 18
                                    color: on ? Qt.alpha(Theme.primary, 0.22) : (tabHover.containsMouse ? Theme.hover : "transparent")
                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 1
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: tabCell.modelData.icon
                                            font.family: Theme.font
                                            font.pixelSize: 13
                                            color: tabCell.on ? Theme.primary : Theme.inkMuted
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: tabCell.modelData.label
                                            font.family: Theme.uiFont
                                            font.pixelSize: 9
                                            font.weight: Font.DemiBold
                                            color: tabCell.on ? Theme.ink : Theme.inkMuted
                                        }
                                    }
                                    MouseArea {
                                        id: tabHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: win.tab = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    Flickable {
                        visible: win.tab === "home"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentHeight: homeCol.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds
                        ColumnLayout {
                            id: homeCol
                            width: parent.width
                            spacing: 12

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: vitals.implicitHeight + 20
                                radius: 18
                                color: Qt.alpha(Theme.surfaceContainerLow, 0.7)
                                border.width: 1
                                border.color: Qt.alpha(win.wolfCyan, 0.35)
                                ColumnLayout {
                                    id: vitals
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: 12
                                    spacing: 10
                                    SliderRow {
                                        icon: Audio.glyph
                                        value: Audio.volume
                                        text: Audio.percentage + "%"
                                        accent: win.wolfCyan
                                        onMoved: v => Audio.setVolume(v)
                                    }
                                    SliderRow {
                                        icon: Bright.glyph
                                        value: Bright.value
                                        text: Bright.percentage + "%"
                                        accent: win.wolfMagenta
                                        onMoved: v => Bright.set(v)
                                    }
                                }
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                columnSpacing: 8
                                rowSpacing: 8
                                ToggleTile {
                                    icon: Net.glyph
                                    label: "Wi‑Fi"
                                    sub: Net.ssid || (Net.wifiOn ? "On" : "Off")
                                    on: Net.wifiOn
                                    accent: win.wolfCyan
                                    accentInk: win.wolfVoid
                                    boxRadius: 18
                                    onClicked: Net.toggleWifi()
                                }
                                ToggleTile {
                                    icon: Net.btGlyph
                                    label: "Bluetooth"
                                    sub: Net.btOn ? "On" : "Off"
                                    on: Net.btOn
                                    accent: win.wolfCyan
                                    accentInk: win.wolfVoid
                                    boxRadius: 18
                                    onClicked: Net.toggleBt()
                                }
                                ToggleTile {
                                    icon: Audio.muted ? "󰝟" : "󰕾"
                                    label: "Audio"
                                    sub: Audio.muted ? "Muet" : (Audio.percentage + "%")
                                    on: !Audio.muted
                                    accent: win.wolfCyan
                                    accentInk: win.wolfVoid
                                    boxRadius: 18
                                    onClicked: Audio.toggleMute()
                                }
                                ToggleTile {
                                    icon: Notifs.dnd ? "󰂛" : "󰂚"
                                    label: "DND"
                                    sub: Notifs.dnd ? "Silencieux" : (Notifs.count + " notifs")
                                    on: Notifs.dnd
                                    accent: win.wolfCyan
                                    accentInk: win.wolfVoid
                                    boxRadius: 18
                                    onClicked: Notifs.toggleDnd()
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                QuickBtn { icon: "󱙺"; label: "IA"; accent: win.wolfCyan; onClicked: PanelService.show("ai", win) }
                                QuickBtn { icon: "󰆧"; label: "VM"; accent: win.wolfCyan; onClicked: PanelService.show("vm", win) }
                                QuickBtn { icon: "󰯁"; label: "Scripts"; accent: win.wolfCyan; onClicked: PanelService.show("scripts", win) }
                                QuickBtn { icon: "󰗚"; label: "Ops"; accent: win.wolfCyan; onClicked: PanelService.show("ops", win) }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "NOTIFICATIONS"
                                    font.family: Theme.font
                                    font.pixelSize: 9
                                    font.weight: Font.Black
                                    font.letterSpacing: 1.8
                                    color: win.wolfCyan
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    visible: Notifs.count > 0
                                    text: "tout effacer"
                                    font.family: Theme.uiFont
                                    font.pixelSize: 10
                                    color: clearHover.containsMouse ? Theme.error : Theme.inkMuted
                                    MouseArea {
                                        id: clearHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Notifs.dismissAll()
                                    }
                                }
                            }
                            Column {
                                Layout.fillWidth: true
                                spacing: 6
                                visible: Notifs.count > 0
                                Repeater {
                                    model: Notifs.count
                                    delegate: NotifCard {
                                        required property int index
                                        width: homeCol.width
                                        notif: Notifs.recentAt(index)
                                        popup: false
                                        compact: true
                                        idx: Notifs.count - 1 - index
                                    }
                                }
                            }
                            Text {
                                visible: Notifs.count === 0
                                Layout.alignment: Qt.AlignHCenter
                                text: "Rien pour l’instant"
                                font.family: Theme.uiFont
                                font.pixelSize: 12
                                color: Theme.inkMuted
                            }

                            Text {
                                text: "IDENTITÉ  ·  " + Chrome.displayName
                                font.family: Theme.font
                                font.pixelSize: 9
                                font.weight: Font.Black
                                font.letterSpacing: 1.8
                                color: win.wolfCyan
                            }
                            GridLayout {
                                Layout.fillWidth: true
                                columns: 4
                                columnSpacing: 6
                                rowSpacing: 6
                                Repeater {
                                    model: Chrome.identities
                                    delegate: Chip {
                                        required property var modelData
                                        label: modelData.label
                                        on: Theme.uiStyle === modelData.id
                                        onClicked: Chrome.setIdentity(modelData.id)
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: calWrap.implicitHeight + 20
                                radius: 18
                                color: Qt.alpha(Theme.surfaceContainerLow, 0.7)
                                border.width: 1
                                border.color: Qt.alpha(win.wolfCyan, 0.35)
                                CalGrid {
                                    id: calWrap
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 12
                                }
                            }
                        }
                    }

                    StudioPanel { visible: win.tab === "panel"; Layout.fillWidth: true; Layout.fillHeight: true }
                    StudioBar { visible: win.tab === "bar"; Layout.fillWidth: true; Layout.fillHeight: true }
                    StudioDock { visible: win.tab === "dock"; Layout.fillWidth: true; Layout.fillHeight: true }
                    StudioDesk { visible: win.tab === "desk"; Layout.fillWidth: true; Layout.fillHeight: true }

                    Flickable {
                        visible: win.tab === "theme"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentHeight: themeCol.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds
                        ColumnLayout {
                            id: themeCol
                            width: parent.width
                            spacing: 12
                            Text {
                                text: "THÈMES"
                                font.family: Theme.uiFont
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                font.letterSpacing: 1.6
                                color: Theme.inkMuted
                            }
                            Text {
                                width: parent.width
                                text: {
                                    if (!Themes.hasActive)
                                        return "ACTIF  ·  MATERIAL YOU";
                                    const p = Themes.byId(Themes.active);
                                    return "ACTIF  ·  " + (p ? p.label : Themes.active).toUpperCase();
                                }
                                font.family: Theme.font
                                font.pixelSize: 9
                                font.letterSpacing: 1.2
                                color: Themes.hasActive ? Theme.primary : Qt.alpha(Theme.inkMuted, 0.8)
                                elide: Text.ElideRight
                            }
                            GridLayout {
                                Layout.fillWidth: true
                                columns: 1
                                columnSpacing: 8
                                rowSpacing: 8
                                Repeater {
                                    model: Themes.presets
                                    delegate: Rectangle {
                                        id: themeCard
                                        required property var modelData
                                        readonly property var pal: (modelData.data && modelData.data.palette) || {}
                                        readonly property bool activeNow: Themes.active === modelData.id
                                        readonly property bool isUser: !modelData.builtin
                                        property bool renaming: false

                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 48
                                        radius: 12
                                        color: activeNow ? Qt.alpha(Theme.primary, 0.16) : Qt.alpha(Theme.surfaceContainer, 0.72)
                                        border.width: activeNow ? 2 : 1
                                        border.color: activeNow ? Theme.primary : Qt.alpha(Theme.outlineVariant, 0.6)

                                        MouseArea {
                                            anchors.fill: parent
                                            z: 0
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Themes.apply(themeCard.modelData.id)
                                        }

                                        Row {
                                            id: swRow
                                            z: 1
                                            anchors.left: parent.left
                                            anchors.leftMargin: 12
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 3
                                            Repeater {
                                                model: [themeCard.pal.background, themeCard.pal.accent, themeCard.pal.error, themeCard.pal.success]
                                                delegate: Rectangle {
                                                    required property var modelData
                                                    width: 9
                                                    height: 20
                                                    radius: 3
                                                    color: modelData || Theme.surface2
                                                    border.width: 1
                                                    border.color: Qt.alpha(Theme.outlineVariant, 0.8)
                                                }
                                            }
                                        }

                                        Column {
                                            z: 1
                                            anchors.left: swRow.right
                                            anchors.leftMargin: 10
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: parent.width - swRow.width - 104

                                            TextInput {
                                                id: labelInput
                                                width: parent.width
                                                visible: themeCard.renaming
                                                text: themeCard.modelData.label
                                                color: Theme.ink
                                                font.family: Theme.uiFont
                                                font.pixelSize: 13
                                                font.weight: Font.DemiBold
                                                selectByMouse: true
                                                clip: true
                                                onAccepted: {
                                                    Themes.rename(themeCard.modelData.id, text);
                                                    themeCard.renaming = false;
                                                }
                                                onEditingFinished: themeCard.renaming = false
                                            }
                                            Text {
                                                width: parent.width
                                                visible: !themeCard.renaming
                                                text: themeCard.modelData.label
                                                color: Theme.ink
                                                font.family: Theme.uiFont
                                                font.pixelSize: 13
                                                font.weight: Font.DemiBold
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                width: parent.width
                                                visible: !themeCard.renaming
                                                text: (themeCard.modelData.identity || "—") + (themeCard.isUser ? "  ·  utilisateur" : "  ·  intégré")
                                                color: Qt.alpha(Theme.inkMuted, 0.9)
                                                font.family: Theme.font
                                                font.pixelSize: 9
                                                font.letterSpacing: 0.8
                                                elide: Text.ElideRight
                                            }
                                        }

                                        Row {
                                            id: actsRow
                                            z: 2
                                            anchors.right: parent.right
                                            anchors.rightMargin: 10
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 7
                                            Repeater {
                                                model: themeCard.isUser
                                                    ? [{ g: "󰉼", k: "ren" }, { g: "󰆴", k: "dup" }, { g: "󰜗", k: "del" }, { g: "󰐊", k: "ok" }]
                                                    : [{ g: "󰆴", k: "dup" }, { g: "󰐊", k: "ok" }]
                                                delegate: Item {
                                                    id: act
                                                    required property var modelData
                                                    width: 15
                                                    height: 15
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: act.modelData.g
                                                        font.family: Theme.font
                                                        font.pixelSize: 12
                                                        color: act.modelData.k === "del"
                                                            ? Qt.alpha(Theme.error, 0.9)
                                                            : (themeCard.renaming && act.modelData.k === "ren") ? Theme.primary : Theme.inkMuted
                                                    }
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            const k = act.modelData.k;
                                                            if (k === "ren") { themeCard.renaming = true; labelInput.forceActiveFocus(); labelInput.selectAll(); }
                                                            else if (k === "dup") Themes.duplicate(themeCard.modelData.id);
                                                            else if (k === "del") Themes.remove(themeCard.modelData.id);
                                                            else Themes.apply(themeCard.modelData.id);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 34
                                radius: 17
                                color: Theme.layer2
                                border.width: 1
                                border.color: Theme.hairline
                                TextInput {
                                    id: newThemeName
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    color: Theme.ink
                                    font.family: Theme.font
                                    font.pixelSize: 12
                                    selectByMouse: true
                                    clip: true
                                    onAccepted: {
                                        Themes.saveCurrent(text);
                                        text = "";
                                    }
                                    Text {
                                        visible: !newThemeName.text.length && !newThemeName.activeFocus
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Enregistrer la configuration courante…"
                                        color: Qt.alpha(Theme.inkMuted, 0.85)
                                        font.family: Theme.font
                                        font.pixelSize: 12
                                    }
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                Chip {
                                    Layout.fillWidth: false
                                    Layout.preferredWidth: 118
                                    label: "Enregistrer"
                                    onClicked: {
                                        Themes.saveCurrent(newThemeName.text);
                                        newThemeName.text = "";
                                    }
                                }
                                Chip {
                                    Layout.fillWidth: false
                                    Layout.preferredWidth: 118
                                    label: "Material You"
                                    on: !Themes.hasActive && Palettes.isAuto
                                    onClicked: Themes.setAuto()
                                }
                                Item { Layout.fillWidth: true }
                                Chip {
                                    Layout.fillWidth: false
                                    Layout.preferredWidth: 92
                                    label: "Rafraîchir"
                                    onClicked: Themes.refresh()
                                }
                            }

                            Text {
                                text: "IDENTITÉ"
                                font.family: Theme.uiFont
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                font.letterSpacing: 1.6
                                color: Theme.inkMuted
                            }
                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                columnSpacing: 8
                                rowSpacing: 8
                                Repeater {
                                    model: Chrome.identities
                                    delegate: Chip {
                                        required property var modelData
                                        label: modelData.label
                                        on: Theme.uiStyle === modelData.id
                                        onClicked: Chrome.setIdentity(modelData.id)
                                    }
                                }
                            }
                            Text {
                                text: "PALETTE"
                                font.family: Theme.uiFont
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                font.letterSpacing: 1.6
                                color: Theme.inkMuted
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Chip { label: "Material You"; on: Palettes.isAuto; onClicked: Palettes.setAuto() }
                                Chip {
                                    label: "Preset"
                                    on: !Palettes.isAuto
                                    onClicked: {
                                        if (Palettes.isAuto)
                                            Palettes.setPreset(ShellCfg.palette || "tokyonight");
                                    }
                                }
                            }
                            Flow {
                                visible: !Palettes.isAuto
                                Layout.fillWidth: true
                                spacing: 6
                                Repeater {
                                    model: Palettes.available
                                    delegate: Rectangle {
                                        required property string modelData
                                        readonly property var preview: Palettes.previews[modelData] || {}
                                        width: 72
                                        height: 72
                                        radius: 12
                                        color: Theme.layer2
                                        border.width: ShellCfg.palette === modelData ? 2 : 1
                                        border.color: ShellCfg.palette === modelData ? Theme.primary : Theme.hairline
                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 6
                                            Row {
                                                spacing: 4
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                Repeater {
                                                    model: [
                                                        (preview.palette && preview.palette.background) || "#1a1b26",
                                                        (preview.palette && preview.palette.accent) || "#7aa2f7",
                                                        (preview.palette && preview.palette.error) || "#f7768e"
                                                    ]
                                                    delegate: Rectangle {
                                                        required property string modelData
                                                        width: 10
                                                        height: 10
                                                        radius: 5
                                                        color: modelData
                                                    }
                                                }
                                            }
                                            Text {
                                                text: (preview.name || modelData).split(" ")[0]
                                                font.family: Theme.uiFont
                                                font.pixelSize: 10
                                                color: Theme.ink
                                                anchors.horizontalCenter: parent.horizontalCenter
                                            }
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Palettes.setPreset(modelData)
                                        }
                                    }
                                }
                            }
                            Chip {
                                label: "Fonds d’écran"
                                onClicked: PanelService.show("wall", win)
                            }
                        }
                    }

                    Text {
                        visible: win.tab === "home"
                        Layout.alignment: Qt.AlignHCenter
                        text: "// ACCESS GRANTED  ·  catalyst"
                        font.family: Theme.font
                        font.pixelSize: 8
                        font.letterSpacing: 1.6
                        color: Qt.alpha(win.wolfCyan, 0.4)
                    }
                }
            }

            FocusScope {
                anchors.fill: parent
                focus: win.visible
                Keys.onEscapePressed: PanelService.hide()
            }
        }
    }
}
