pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit

// Terminal : ce qui s'affiche à l'ouverture (bannière, fastfetch, gadget),
// apparence d'Alacritty / Kitty / Ghostty, et petits paquets « fun ».
// Tout réglage d'apparence laissé sur « défaut » ne touche pas aux terminaux.
ColumnLayout {
    id: root
    spacing: 16

    property bool pickingFont: false
    // case de couleur sélectionnée dans l'éditeur : "bg" | "fg" | "cursor" | "selection" | 0..15
    property var slot: "bg"

    readonly property var current: TermCfg.extraInfo(TermCfg.extra)
    readonly property bool extraMissing: current.cmd.length > 0 && !TermCfg.has(current.cmd)
    readonly property var style: TermCfg.styleInfo(TermCfg.bannerStyle)
    readonly property bool styleMissing: style.cmd.length > 0 && !TermCfg.has(style.cmd)

    Component.onCompleted: TermCfg.refreshTools()

    // ================= accueil =================
    SectionHeader { Layout.fillWidth: true; text: "Accueil" }

    Group {
        Layout.fillWidth: true

        SettingRow {
            Layout.fillWidth: true
            icon: "title"
            title: "Bannière"
            subtitle: "Texte en grandes lettres au-dessus de fastfetch"
            Toggle {
                checked: TermCfg.banner
                onToggled: v => TermCfg.set("banner", v)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            visible: TermCfg.banner
            icon: "text_fields"
            title: "Texte de la bannière"
            subtitle: "16 caractères max. Actuel : « " + ShellCfg.banner + " »"
            Field {
                width: 180
                placeholder: ShellCfg.banner
                onAccepted: t => { ShellCfg.setBanner(t); text = ""; }
            }
            IconButton {
                icon: "restart_alt"
                size: 30
                iconSize: 17
                tooltip: "Revenir à « tsu »"
                disabled: ShellCfg.banner === "tsu"
                onClicked: ShellCfg.setBanner("tsu")
            }
        }
        SettingRow {
            Layout.fillWidth: true
            visible: TermCfg.banner
            icon: "font_download"
            title: "Style de la bannière"
            subtitle: root.styleMissing ? "« " + root.style.label + " » demande " + root.style.cmd + " (en attendant : blocs)" : "Blocs : intégré · Penché, Petit, Grand : figlet · Future, Pagga : toilet"
            Segmented {
                compact: true
                model: TermCfg.bannerStyles.map(s => ({ id: s.id, label: s.label }))
                current: TermCfg.bannerStyle
                onSelected: id => TermCfg.set("bannerStyle", id)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            visible: TermCfg.banner
            icon: "format_color_fill"
            title: "Couleur de la bannière"
            subtitle: TermCfg.bannerColor === "rainbow" && !TermCfg.has("lolcat") ? "Arc-en-ciel demande lolcat (en attendant : bleu)" : "L'accent suit le thème actif"
            Segmented {
                compact: true
                model: [{ id: "blue", label: "Bleu" }, { id: "accent", label: "Accent" }, { id: "rainbow", label: "Arc-en-ciel" }]
                current: TermCfg.bannerColor
                onSelected: id => TermCfg.set("bannerColor", id)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "info"
            title: "Fastfetch"
            subtitle: TermCfg.has("fastfetch") ? "Infos système sous la bannière" : "fastfetch n'est pas installé"
            Toggle {
                checked: TermCfg.fetch
                onToggled: v => TermCfg.set("fetch", v)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            visible: TermCfg.fetch
            icon: "view_agenda"
            title: "Style de fastfetch"
            subtitle: TermCfg.fetchStyle === "classic" ? "Ta config ~/.config/fastfetch/config.jsonc, telle quelle" : "Encadré : boîte à icônes · Sections : groupes titrés · Minimal : icônes et valeurs"
            Segmented {
                compact: true
                model: [{ id: "box", label: "Encadré" }, { id: "sections", label: "Sections" }, { id: "minimal", label: "Minimal" }, { id: "classic", label: "Classique" }]
                current: TermCfg.fetchStyle
                onSelected: id => TermCfg.set("fetchStyle", id)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            visible: TermCfg.fetch && TermCfg.fetchStyle !== "classic"
            icon: "format_paint"
            title: "Couleurs de fastfetch"
            subtitle: TermCfg.fetchColor === "accent" ? "Accent et texte du thème du rice (suivent les changements de thème)" : "Couleurs ANSI du terminal"
            Segmented {
                compact: true
                model: [{ id: "accent", label: "Thème du rice" }, { id: "terminal", label: "Du terminal" }]
                current: TermCfg.fetchColor
                onSelected: id => TermCfg.set("fetchColor", id)
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.bottomMargin: 12
            visible: TermCfg.fetch && TermCfg.fetchStyle !== "classic"
            spacing: 8
            Txt { role: "overline"; text: "Infos affichées"; color: Theme.textFaint }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: TermCfg.fetchDefs
                    Button {
                        required property var modelData
                        readonly property bool on: TermCfg.moduleOn(modelData.id)
                        variant: on ? "primary" : "secondary"
                        icon: on ? "check" : "add"
                        text: modelData.label
                        onClicked: TermCfg.setModule(modelData.id, !on)
                    }
                }
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "auto_awesome"
            title: "Gadget"
            subtitle: TermCfg.extra === "random" ? "Un des gadgets installés, différent à chaque terminal" : (TermCfg.extra === "pokemon" && TermCfg.fetch ? "Le Pokémon remplace le logo de fastfetch" : "Un petit extra à chaque terminal")
            Segmented {
                compact: true
                model: TermCfg.extras.map(e => ({ id: e.id, label: e.label }))
                current: TermCfg.extra
                onSelected: id => TermCfg.set("extra", id)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            visible: TermCfg.extra === "pokemon" || TermCfg.extra === "random"
            icon: "sports_baseball"
            title: "Pokémon"
            subtitle: TermCfg.pokemon.length ? "Toujours « " + TermCfg.pokemon + " »" : "Au hasard — ou tape un nom anglais (pikachu, gengar, rayquaza…)"
            Field {
                width: 170
                placeholder: TermCfg.pokemon.length ? TermCfg.pokemon : "au hasard"
                onAccepted: t => { TermCfg.set("pokemon", t.trim().toLowerCase().replace(/[^a-z0-9-]/g, "")); text = ""; }
            }
            IconButton {
                icon: "shuffle"
                size: 30
                iconSize: 17
                tooltip: "Au hasard"
                disabled: TermCfg.pokemon.length === 0
                onClicked: TermCfg.set("pokemon", "")
            }
        }
        SettingRow {
            Layout.fillWidth: true
            visible: TermCfg.extra === "pokemon" || TermCfg.extra === "random"
            icon: "star"
            title: "Pokémon shiny"
            subtitle: "Version chromatique"
            Toggle {
                checked: TermCfg.shiny
                onToggled: v => TermCfg.set("shiny", v)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            visible: TermCfg.extra === "cowsay" || TermCfg.extra === "random"
            icon: "pets"
            title: "Personnage de cowsay"
            Segmented {
                compact: true
                model: TermCfg.cows.map(c => ({ id: c.id, label: c.label }))
                current: TermCfg.cow
                onSelected: id => TermCfg.set("cow", id)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "terminal"
            title: "Essayer"
            subtitle: "Ouvre un terminal avec les réglages actuels"
            Button {
                variant: "secondary"
                icon: "open_in_new"
                text: "Ouvrir un terminal"
                onClicked: Quickshell.execDetached(["alacritty"])
            }
        }
    }

    Banner {
        Layout.fillWidth: true
        visible: root.extraMissing
        icon: "download"
        text: "« " + root.current.label + " » a besoin du paquet " + root.current.pkg + ", qui n'est pas installé : rien ne s'affichera tant qu'il manque."
        Button {
            variant: "secondary"
            icon: "download"
            text: "Installer"
            onClicked: TermCfg.install(root.current.pkg)
        }
    }

    // ================= apparence =================
    SectionHeader { Layout.fillWidth: true; text: "Apparence" }

    Group {
        Layout.fillWidth: true

        SettingRow {
            Layout.fillWidth: true
            icon: "font_download"
            title: "Police"
            subtitle: TermCfg.fontFamily.length ? "Alacritty, Kitty et Ghostty" : "Défaut : celle de chaque terminal"
            Text {
                anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                text: TermCfg.fontFamily.length ? TermCfg.fontFamily : "défaut"
                font.family: TermCfg.fontFamily.length ? TermCfg.fontFamily : Theme.monoFont
                font.pixelSize: 14
                color: TermCfg.fontFamily.length ? Theme.text : Theme.textFaint
                width: Math.min(implicitWidth, 200)
                elide: Text.ElideRight
            }
            Button {
                variant: root.pickingFont ? "primary" : "secondary"
                icon: root.pickingFont ? "close" : "edit"
                text: root.pickingFont ? "Fermer" : "Changer"
                onClicked: root.pickingFont = !root.pickingFont
            }
        }
        Loader {
            active: root.pickingFont
            visible: active
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.bottomMargin: active ? 12 : 0
            Layout.preferredHeight: item ? item.implicitHeight : 0
            sourceComponent: FontPicker {
                monoOnly: true
                current: TermCfg.fontFamily
                defaultName: "celle du terminal"
                sample: "~/tsu ❯ ls -la  0O 1lI {}[] =>"
                onPicked: family => TermCfg.set("fontFamily", family)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "format_size"
            title: "Taille de police"
            Slider {
                width: 220
                implicitHeight: 30
                icon: "format_size"
                // 8 → 18 pt par pas de 0,5
                value: ((TermCfg.fontSize > 0 ? TermCfg.fontSize : 11) - 8) / 10
                valueText: TermCfg.fontSize > 0 ? TermCfg.fontSize.toFixed(1) + " pt" : "défaut"
                step: 0.05
                wheelAdjusts: false
                onMoved: v => TermCfg.set("fontSize", Math.round((8 + v * 10) * 2) / 2)
            }
            IconButton {
                icon: "restart_alt"; size: 30; iconSize: 17
                tooltip: "Taille de chaque terminal"
                disabled: TermCfg.fontSize <= 0
                onClicked: TermCfg.set("fontSize", 0)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "format_line_spacing"
            title: "Interligne"
            Slider {
                width: 220
                implicitHeight: 30
                icon: "format_line_spacing"
                // 80 % → 180 %
                value: ((TermCfg.lineHeight > 0 ? TermCfg.lineHeight : 100) - 80) / 100
                valueText: TermCfg.lineHeight > 0 ? TermCfg.lineHeight + " %" : "défaut"
                step: 0.05
                wheelAdjusts: false
                onMoved: v => TermCfg.set("lineHeight", Math.round((80 + v * 100) / 5) * 5)
            }
            IconButton {
                icon: "restart_alt"; size: 30; iconSize: 17
                tooltip: "Interligne de chaque terminal"
                disabled: TermCfg.lineHeight <= 0
                onClicked: TermCfg.set("lineHeight", 0)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "opacity"
            title: "Opacité du fond"
            subtitle: "Le flou derrière dépend de Hyprland"
            Slider {
                width: 220
                implicitHeight: 30
                icon: "opacity"
                // 50 % → 100 %
                value: ((TermCfg.opacity > 0 ? TermCfg.opacity : 1) - 0.5) / 0.5
                valueText: TermCfg.opacity > 0 ? Math.round(TermCfg.opacity * 100) + " %" : "défaut"
                step: 0.02
                wheelAdjusts: false
                onMoved: v => TermCfg.set("opacity", Math.round((0.5 + v * 0.5) * 100) / 100)
            }
            IconButton {
                icon: "restart_alt"; size: 30; iconSize: 17
                tooltip: "Opacité de chaque terminal"
                disabled: TermCfg.opacity <= 0
                onClicked: TermCfg.set("opacity", 0)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "padding"
            title: "Marges intérieures"
            Slider {
                width: 220
                implicitHeight: 30
                icon: "padding"
                // 0 → 32 px
                value: Math.max(0, TermCfg.padding) / 32
                valueText: TermCfg.padding >= 0 ? TermCfg.padding + " px" : "défaut"
                step: 1 / 32
                wheelAdjusts: false
                onMoved: v => TermCfg.set("padding", Math.round(v * 32))
            }
            IconButton {
                icon: "restart_alt"; size: 30; iconSize: 17
                tooltip: "Marges de chaque terminal"
                disabled: TermCfg.padding < 0
                onClicked: TermCfg.set("padding", -1)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "text_select_end"
            title: "Curseur"
            Segmented {
                compact: true
                model: [{ id: "", label: "Défaut" }, { id: "block", label: "Bloc" }, { id: "beam", label: "Barre" }, { id: "underline", label: "Souligné" }]
                current: TermCfg.cursorShape
                onSelected: id => TermCfg.set("cursorShape", id)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "flare"
            title: "Clignotement du curseur"
            Segmented {
                compact: true
                model: [{ id: "", label: "Défaut" }, { id: "on", label: "Oui" }, { id: "off", label: "Non" }]
                current: TermCfg.cursorBlink
                onSelected: id => TermCfg.set("cursorBlink", id)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "history"
            title: "Historique"
            subtitle: "Lignes gardées en mémoire (Alacritty, Kitty)"
            Segmented {
                compact: true
                model: [{ id: 0, label: "Défaut" }, { id: 1000, label: "1 000" }, { id: 10000, label: "10 000" }, { id: 100000, label: "100 000" }]
                current: TermCfg.scrollback
                onSelected: id => TermCfg.set("scrollback", id)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "content_copy"
            title: "Copier à la sélection"
            subtitle: "Le texte sélectionné à la souris part dans le presse-papiers"
            Toggle {
                checked: TermCfg.copyOnSelect
                onToggled: v => TermCfg.set("copyOnSelect", v)
            }
        }
    }

    // ================= couleurs =================
    SectionHeader { Layout.fillWidth: true; text: "Couleurs du terminal" }

    Group {
        Layout.fillWidth: true

        SettingRow {
            Layout.fillWidth: true
            icon: "palette"
            title: "Palette"
            subtitle: TermCfg.colors === "terminal" ? "Celle de chaque terminal (thème Omarchy / current-theme)" : (TermCfg.colors === "rice" ? "Tirée du thème actif, suit les changements de thème" : (TermCfg.colors === "preset" ? "Préréglage : " + (TermCfg.presets[TermCfg.colorPreset] ? TermCfg.presets[TermCfg.colorPreset].name : TermCfg.colorPreset) : "Ta palette, case par case"))
            Segmented {
                compact: true
                model: [{ id: "terminal", label: "Du terminal" }, { id: "rice", label: "Thème du rice" }, { id: "preset", label: "Préréglage" }, { id: "custom", label: "Perso" }]
                current: TermCfg.colors
                onSelected: id => {
                    if (id === "custom" && !TermCfg.palette)
                        TermCfg.startCustomFrom(TermCfg.editablePalette());
                    else
                        TermCfg.set("colors", id);
                }
            }
        }

        // ---- préréglages ----
        Flow {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.bottomMargin: 12
            visible: TermCfg.colors === "preset"
            spacing: 8
            Repeater {
                model: Object.keys(TermCfg.presets).sort()
                Rectangle {
                    id: card
                    required property string modelData
                    readonly property var pal: TermCfg.presets[modelData]
                    readonly property bool selected: TermCfg.colorPreset === modelData
                    width: 168
                    height: 62
                    radius: Tokens.rMd
                    color: pal.bg
                    border.width: selected ? 2 : 1
                    border.color: selected ? Theme.accent : Qt.alpha(pal.fg, 0.18)
                    Column {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8
                        Text {
                            text: card.pal.name
                            color: card.pal.fg
                            font.family: Theme.monoFont
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            width: parent.width
                        }
                        Row {
                            spacing: 4
                            Repeater {
                                model: [1, 2, 3, 4, 5, 6, 9, 13]
                                Rectangle {
                                    required property int modelData
                                    width: 13
                                    height: 13
                                    radius: 6.5
                                    color: card.pal.ansi[modelData]
                                }
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            TermCfg.colorPreset = card.modelData;
                            TermCfg.set("colors", "preset");
                        }
                    }
                }
            }
        }

        // ---- éditeur perso ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.bottomMargin: 12
            visible: TermCfg.colors === "custom"
            spacing: 10

            readonly property var pal: TermCfg.editablePalette()

            Row {
                spacing: 14
                Repeater {
                    model: [{ id: "bg", label: "Fond" }, { id: "fg", label: "Texte" }, { id: "cursor", label: "Curseur" }, { id: "selection", label: "Sélection" }]
                    Column {
                        required property var modelData
                        spacing: 4
                        Swatch {
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: TermCfg.editablePalette()[modelData.id]
                            selected: root.slot === modelData.id
                            size: 30
                            onClicked: root.slot = modelData.id
                        }
                        Txt { anchors.horizontalCenter: parent.horizontalCenter; role: "caption"; text: modelData.label }
                    }
                }
            }
            Repeater {
                model: [0, 8]
                Row {
                    id: ansiRow
                    required property int modelData
                    spacing: 8
                    Txt { width: 56; anchors.verticalCenter: parent.verticalCenter; role: "caption"; color: Theme.textFaint; text: ansiRow.modelData === 0 ? "normal" : "clair" }
                    Repeater {
                        model: 8
                        Column {
                            id: cell
                            required property int index
                            readonly property int n: ansiRow.modelData + index
                            spacing: 2
                            Swatch {
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: TermCfg.editablePalette().ansi[cell.n]
                                selected: root.slot === cell.n
                                size: 26
                                onClicked: root.slot = cell.n
                            }
                            Txt { anchors.horizontalCenter: parent.horizontalCenter; role: "caption"; font.pixelSize: 9; text: TermCfg.ansiNames[cell.index] }
                        }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Txt {
                    role: "label"
                    text: "Couleur « " + (typeof root.slot === "number" ? TermCfg.ansiNames[root.slot % 8] + (root.slot >= 8 ? " clair" : "") : ({ bg: "Fond", fg: "Texte", cursor: "Curseur", selection: "Sélection" })[root.slot]) + " »"
                }
                Field {
                    width: 120
                    placeholder: typeof root.slot === "number" ? TermCfg.editablePalette().ansi[root.slot] : TermCfg.editablePalette()[root.slot]
                    onAccepted: t => { if (TermCfg.setColor(root.slot, t)) text = ""; }
                }
                Txt { Layout.fillWidth: true; role: "caption"; color: Theme.textFaint; text: "hexadécimal, ex. #a78bfa"; elide: Text.ElideRight }
            }
            Flow {
                Layout.fillWidth: true
                spacing: 8
                Button {
                    variant: "secondary"
                    icon: "content_copy"
                    text: "Repartir du préréglage " + (TermCfg.presets[TermCfg.colorPreset] ? TermCfg.presets[TermCfg.colorPreset].name : "")
                    onClicked: TermCfg.startCustomFrom(TermCfg.presets[TermCfg.colorPreset] || TermCfg.ricePalette())
                }
                Button {
                    variant: "secondary"
                    icon: "auto_awesome"
                    text: "Repartir du thème du rice"
                    onClicked: TermCfg.startCustomFrom(TermCfg.ricePalette())
                }
            }
        }

        // ---- aperçu ----
        Rectangle {
            id: preview
            readonly property var pal: TermCfg.activePalette()
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.bottomMargin: 14
            visible: !!pal
            implicitHeight: previewCol.implicitHeight + 24
            radius: Tokens.rMd
            color: pal ? pal.bg : "black"
            border.width: 1
            border.color: Theme.border

            Column {
                id: previewCol
                x: 14
                y: 12
                spacing: 3
                readonly property var p: preview.pal || { bg: "#000000", fg: "#ffffff", cursor: "#ffffff", selection: "#444444", ansi: new Array(16).fill("#888888") }
                component Line: Text {
                    font.family: TermCfg.fontFamily.length ? TermCfg.fontFamily : Theme.monoFont
                    font.pixelSize: 13
                    textFormat: Text.StyledText
                }
                Line { text: "<font color='" + previewCol.p.ansi[2] + "'><b>tsu@catalyst</b></font> <font color='" + previewCol.p.ansi[4] + "'>~/projets</font> <font color='" + previewCol.p.ansi[5] + "'>❯</font> <font color='" + previewCol.p.fg + "'>ls -la</font>" }
                Line { text: "<font color='" + previewCol.p.ansi[4] + "'><b>docs/  src/</b></font>  <font color='" + previewCol.p.fg + "'>README.md</font>  <font color='" + previewCol.p.ansi[2] + "'><b>run.sh</b></font>  <font color='" + previewCol.p.ansi[6] + "'>lien -> src</font>" }
                Line { text: "<font color='" + previewCol.p.ansi[1] + "'>error:</font> <font color='" + previewCol.p.fg + "'>fichier introuvable</font>  <font color='" + previewCol.p.ansi[3] + "'>warning:</font> <font color='" + previewCol.p.ansi[8] + "'>variable inutilisée</font>" }
                Row {
                    spacing: 0
                    Line { text: "<font color='" + previewCol.p.ansi[2] + "'><b>tsu@catalyst</b></font> <font color='" + previewCol.p.ansi[5] + "'>❯</font> "; }
                    Rectangle { width: 8; height: 16; color: previewCol.p.cursor; anchors.verticalCenter: parent.verticalCenter }
                    Rectangle {
                        width: selTxt.implicitWidth + 6
                        height: 18
                        color: previewCol.p.selection
                        anchors.verticalCenter: parent.verticalCenter
                        Line { id: selTxt; x: 3; anchors.verticalCenter: parent.verticalCenter; text: "<font color='" + previewCol.p.fg + "'> texte sélectionné </font>" }
                    }
                }
                Row {
                    topPadding: 6
                    spacing: 3
                    Repeater {
                        model: 16
                        Rectangle {
                            required property int index
                            width: 22
                            height: 14
                            radius: 3
                            color: previewCol.p.ansi[index]
                        }
                    }
                }
            }
        }
    }

    Txt {
        Layout.fillWidth: true
        role: "caption"
        color: Theme.textFaint
        wrapMode: Text.Wrap
        text: "Alacritty et Kitty se mettent à jour en direct ; Ghostty applique les changements aux nouvelles fenêtres (ou Ctrl+Maj+, pour recharger). « Défaut » ne touche pas à la config de chaque terminal."
    }

    // ================= paquets =================
    SectionHeader { Layout.fillWidth: true; text: "Paquets fun" }

    Group {
        Layout.fillWidth: true

        Repeater {
            model: TermCfg.funPackages

            SettingRow {
                id: pkgRow
                required property var modelData
                readonly property bool installed: TermCfg.has(modelData.cmd)
                Layout.fillWidth: true
                icon: installed ? "check_circle" : "download"
                title: modelData.pkg
                subtitle: modelData.desc
                Badge {
                    visible: pkgRow.installed
                    label: "installé"
                }
                Button {
                    visible: !pkgRow.installed
                    variant: "secondary"
                    icon: "download"
                    text: "Installer"
                    onClicked: TermCfg.install(pkgRow.modelData.pkg)
                }
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "refresh"
            title: "Actualiser"
            subtitle: "Après une installation dans le terminal qui s'ouvre"
            IconButton {
                icon: "refresh"; size: 30; iconSize: 17
                tooltip: "Revérifier les paquets installés"
                onClicked: TermCfg.refreshTools()
            }
        }
    }
}
