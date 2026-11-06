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
        SettingRow {
            Layout.fillWidth: true
            icon: "palette"
            title: "Couleurs"
            subtitle: TermCfg.colors === "rice" ? "Fond, texte et 16 couleurs ANSI tirés du thème actif (suit les changements de thème)" : "Celles de chaque terminal (thème Omarchy / current-theme)"
            Segmented {
                compact: true
                model: [{ id: "terminal", label: "Du terminal" }, { id: "rice", label: "Thème du rice" }]
                current: TermCfg.colors
                onSelected: id => TermCfg.set("colors", id)
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
