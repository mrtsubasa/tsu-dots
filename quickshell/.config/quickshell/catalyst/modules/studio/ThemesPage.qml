pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Thèmes : presets complets (aperçu), personnalisation live des accents et
// effets, sauvegarde en thème utilisateur, palettes classiques, Material You,
// géométrie (pack d'identité).
ColumnLayout {
    id: root
    spacing: 18

    property bool dirty: false
    readonly property var swatches: ["#A78BFA", "#8B5CF6", "#C084FC", "#78BFFF", "#8FD3FF", "#5EEAD4", "#6EE7B7", "#F5C46B", "#F38BCB", "#FF5FC8", "#FF8FA3", "#C8D0DC"]

    function same(a, b) {
        return String(a).toLowerCase().slice(-6) === String(b).toLowerCase().slice(-6);
    }

    // ---------------- thèmes complets ----------------
    SectionHeader { Layout.fillWidth: true; text: "Thèmes Catalyst" }

    Flow {
        Layout.fillWidth: true
        spacing: 12

        Repeater {
            model: Themes.presets

            Item {
                id: card
                required property var modelData
                readonly property var pal: modelData.data.palette || {}
                readonly property bool on: Themes.active === modelData.id
                width: 228
                height: 176

                Rectangle {
                    anchors.fill: parent
                    radius: Tokens.rLg
                    color: Theme.s3
                    border.width: card.on ? 2 : 1
                    border.color: card.on ? Theme.accent : Theme.border
                    scale: hov.pressed ? 0.98 : 1
                    Behavior on scale { NumberAnimation { duration: Motion.dur(Motion.instant) } }

                    // mini-bureau dans les couleurs du thème
                    Rectangle {
                        id: mini
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 8
                        height: 108
                        radius: Tokens.rMd
                        color: card.pal.background || "#000"
                        clip: true

                        Rectangle {
                            x: 6; y: 6
                            width: parent.width - 12
                            height: 12
                            radius: card.modelData.identity === "protocol" ? 2 : 6
                            color: card.pal.surface1 || "#222"
                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                x: 6
                                spacing: 3
                                Rectangle { width: 12; height: 5; radius: 2.5; color: card.pal.accent || "#fff" }
                                Rectangle { width: 5; height: 5; radius: 2.5; color: card.pal.subtext || "#888" }
                                Rectangle { width: 5; height: 5; radius: 2.5; color: card.pal.subtext || "#888"; opacity: 0.5 }
                            }
                            Rectangle { anchors.centerIn: parent; width: 22; height: 4; radius: 2; color: card.pal.text || "#fff"; opacity: 0.8 }
                            Rectangle { anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter; width: 4; height: 4; radius: 2; color: card.pal.signature || "#f0f" }
                        }
                        Rectangle {
                            x: parent.width - 84; y: 24
                            width: 78
                            height: 78
                            radius: card.modelData.identity === "protocol" ? 3 : 8
                            color: card.pal.surface2 || "#333"
                            border.width: 1
                            border.color: Qt.alpha(card.pal.text || "#fff", 0.08)
                            Column {
                                x: 7; y: 8
                                spacing: 5
                                Rectangle { width: 64; height: 9; radius: 3; color: card.pal.accent || "#fff" }
                                Rectangle { width: 46; height: 9; radius: 3; color: card.pal.surface3 || "#444" }
                                Rectangle { width: 64; height: 4; radius: 2; color: card.pal.electric || "#0ff" }
                                Rectangle { width: 30; height: 4; radius: 2; color: card.pal.subtext || "#888" }
                            }
                        }
                        Column {
                            x: 8; y: 30
                            spacing: 6
                            Rectangle { width: 70; height: 5; radius: 2; color: card.pal.text || "#fff"; opacity: 0.85 }
                            Rectangle { width: 52; height: 5; radius: 2; color: card.pal.subtext || "#888" }
                            Rectangle { width: 60; height: 5; radius: 2; color: card.pal.subtext || "#888"; opacity: 0.6 }
                        }
                    }

                    ColumnLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 12
                        spacing: 0
                        RowLayout {
                            Layout.fillWidth: true
                            Txt { role: "label"; text: card.modelData.label; font.weight: Font.DemiBold; Layout.fillWidth: true }
                            Icon { visible: card.on; name: "check_circle"; size: 16; fill: 1; color: Theme.accent }
                            Txt { visible: !card.modelData.builtin && !card.on; role: "overline"; text: "perso"; color: Theme.textFaint }
                        }
                        Txt {
                            Layout.fillWidth: true
                            role: "caption"
                            text: card.modelData.description
                        }
                    }

                    StateLayer {
                        id: hov
                        anchors.fill: parent
                        radius: parent.radius
                        hoverAlpha: 0.04
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton)
                                cardMenu.openAt(card);
                            else {
                                Themes.apply(card.modelData.id);
                                root.dirty = false;
                            }
                        }
                    }
                }

                Menu {
                    id: cardMenu
                    side: "bottom"
                    items: [
                        { label: "Appliquer", icon: "check", action: () => Themes.apply(card.modelData.id) },
                        { label: "Dupliquer", icon: "content_copy", action: () => Themes.duplicate(card.modelData.id) },
                        { separator: true },
                        { label: "Supprimer", icon: "delete", danger: true, enabled: !card.modelData.builtin, action: () => Themes.remove(card.modelData.id) }
                    ]
                }
            }
        }

        // Material You
        Item {
            width: 228
            height: 176
            readonly property bool on: Theme.mode === "auto"
            Rectangle {
                anchors.fill: parent
                radius: Tokens.rLg
                color: Theme.s3
                border.width: parent.on ? 2 : 1
                border.color: parent.on ? Theme.accent : Theme.border

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 8
                    height: 108
                    radius: Tokens.rMd
                    clip: true
                    color: Theme.s0
                    Art {
                        anchors.fill: parent
                        source: SysInfo.wallpaper.length ? "file://" + SysInfo.wallpaper : ""
                        radius: Tokens.rMd
                        fallbackIcon: "wallpaper"
                    }
                    Icon {
                        anchors.centerIn: parent
                        name: "auto_awesome"
                        size: 30
                        fill: 1
                        color: "white"
                        style: Text.Outline
                        styleColor: Qt.rgba(0, 0, 0, 0.35)
                    }
                }
                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 12
                    spacing: 0
                    Txt { role: "label"; text: "Material You"; font.weight: Font.DemiBold }
                    Txt { role: "caption"; text: "Palette tirée du fond d'écran (matugen)"; Layout.fillWidth: true }
                }
                StateLayer {
                    anchors.fill: parent
                    radius: parent.radius
                    hoverAlpha: 0.04
                    onClicked: Themes.setAuto()
                }
            }
        }
    }

    // ---------------- personnalisation ----------------
    SectionHeader {
        Layout.fillWidth: true
        text: "Personnaliser le thème actif"
        actionText: root.dirty ? "modifié" : ""
    }

    Group {
        Layout.fillWidth: true

        SettingRow {
            Layout.fillWidth: true
            icon: "format_color_fill"
            title: "Accent principal"
            subtitle: "Sélection, focus, éléments actifs, bordure de fenêtre"
            Row {
                spacing: 2
                Repeater {
                    model: root.swatches.slice(0, 8)
                    Swatch {
                        required property string modelData
                        color: modelData
                        size: 28
                        selected: root.same(Theme.primary, modelData)
                        onClicked: { Theme.primary = modelData; root.dirty = true; }
                    }
                }
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "bolt"
            title: "Accent secondaire"
            subtitle: "Informations, liens, jauges"
            Row {
                spacing: 2
                Repeater {
                    model: ["#78BFFF", "#8FD3FF", "#5EEAD4", "#67E8F9", "#A78BFA", "#FF5FC8", "#C8D0DC", "#6EE7B7"]
                    Swatch {
                        required property string modelData
                        color: modelData
                        size: 28
                        selected: root.same(Theme.electric, modelData)
                        onClicked: { Theme.electric = modelData; root.dirty = true; }
                    }
                }
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "favorite"
            title: "Signature"
            subtitle: "Rose Tsubasa : états importants, micro actif, compteurs"
            Row {
                spacing: 2
                Repeater {
                    model: ["#F38BCB", "#FF8AD8", "#FF6EC7", "#FF9AD0", "#B4A7FF", "#F5C46B", "#FF8FA3", "#5EEAD4"]
                    Swatch {
                        required property string modelData
                        color: modelData
                        size: 28
                        selected: root.same(Theme.signature, modelData)
                        onClicked: { Theme.signature = modelData; root.dirty = true; }
                    }
                }
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "edit"
            title: "Couleur exacte"
            subtitle: "Code hexadécimal de l'accent principal (#RRGGBB)"
            Field {
                id: hexField
                width: 120
                mono: true
                placeholder: Theme.hex(Theme.primary)
                validator: RegularExpressionValidator { regularExpression: /#?[0-9a-fA-F]{0,6}/ }
                onAccepted: t => {
                    const v = t.startsWith("#") ? t : "#" + t;
                    if (/^#[0-9a-fA-F]{6}$/.test(v)) {
                        Theme.primary = v;
                        root.dirty = true;
                        hexField.text = "";
                    }
                }
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "flare"
            title: "Halo néon"
            subtitle: "Lueur d'accent autour des surfaces flottantes (0 = aucune)"
            Slider {
                width: 220
                implicitHeight: 30
                icon: "flare"
                value: Theme.glow
                onMoved: v => { Theme.glow = v; root.dirty = true; }
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "blur_on"
            title: "Opacité du verre"
            subtitle: "Panneaux et barre ; plus bas = plus de fond visible (lisibilité réduite)"
            Slider {
                width: 220
                implicitHeight: 30
                icon: "opacity"
                value: Theme.glassAlpha
                onMoved: v => { Theme.glassAlpha = Math.max(0.55, v); root.dirty = true; }
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "save"
            title: "Enregistrer comme nouveau thème"
            subtitle: root.dirty ? "Les modifications sont appliquées mais pas encore enregistrées." : "Crée un thème à partir des couleurs et effets actuels."
            Field {
                id: nameField
                width: 170
                placeholder: "Nom du thème"
                onAccepted: t => saveBtn.clicked(null)
            }
            Button {
                id: saveBtn
                variant: "primary"
                icon: "save"
                text: "Enregistrer"
                disabled: nameField.text.trim().length === 0
                onClicked: {
                    Themes.saveCurrent(nameField.text.trim());
                    nameField.text = "";
                    root.dirty = false;
                }
            }
        }
    }

    // ---------------- palettes classiques ----------------
    SectionHeader { Layout.fillWidth: true; text: "Palettes classiques" }

    Flow {
        Layout.fillWidth: true
        spacing: 8
        Repeater {
            model: Palettes.available
            Item {
                id: pal
                required property string modelData
                readonly property var p: Palettes.previews[modelData] ? Palettes.previews[modelData].palette : ({})
                readonly property bool on: Theme.mode === "preset" && Palettes.current === modelData
                width: palRow.implicitWidth + 24
                height: 36
                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: pal.on ? Theme.stateActive : Theme.s3
                    border.width: 1
                    border.color: pal.on ? Theme.accent : Theme.border
                }
                StateLayer {
                    anchors.fill: parent
                    radius: height / 2
                    onClicked: Palettes.setPreset(pal.modelData)
                }
                Row {
                    id: palRow
                    anchors.centerIn: parent
                    spacing: 8
                    Row {
                        spacing: -4
                        anchors.verticalCenter: parent.verticalCenter
                        Repeater {
                            model: [pal.p.background, pal.p.accent, pal.p.success || pal.p.accent]
                            Rectangle {
                                required property var modelData
                                width: 14
                                height: 14
                                radius: 7
                                color: modelData || "#888"
                                border.width: 1
                                border.color: Theme.s3
                            }
                        }
                    }
                    Txt {
                        anchors.verticalCenter: parent.verticalCenter
                        role: "label"
                        text: Palettes.previews[pal.modelData] ? Palettes.previews[pal.modelData].name : pal.modelData
                    }
                }
            }
        }
    }

    // ---------------- géométrie ----------------
    SectionHeader { Layout.fillWidth: true; text: "Géométrie (identité)" }

    Flow {
        Layout.fillWidth: true
        spacing: 8
        Repeater {
            model: Chrome.identities
            Button {
                required property var modelData
                variant: Theme.uiStyle === modelData.id || Tokens.packId === modelData.id ? "primary" : "secondary"
                text: modelData.label
                onClicked: Chrome.setIdentity(modelData.id)
            }
        }
    }
    Txt {
        Layout.fillWidth: true
        role: "caption"
        wrapMode: Text.WordWrap
        color: Theme.textFaint
        text: "L'identité règle les rayons, le style de barre et la matière des surfaces. Chaque thème Catalyst en choisit une ; tu peux la changer ici sans toucher aux couleurs."
    }
}
