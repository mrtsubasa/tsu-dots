pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit

// Terminal : ce qui s'affiche à l'ouverture (bannière, fastfetch, gadget),
// apparence d'Alacritty / Kitty / Ghostty, et petits paquets « fun ».
ColumnLayout {
    id: root
    spacing: 16

    readonly property var current: TermCfg.extraInfo(TermCfg.extra)
    readonly property bool extraMissing: current.cmd.length > 0 && !TermCfg.has(current.cmd)

    Component.onCompleted: TermCfg.refreshTools()

    SectionHeader { Layout.fillWidth: true; text: "Accueil" }

    Group {
        Layout.fillWidth: true

        SettingRow {
            Layout.fillWidth: true
            icon: "title"
            title: "Bannière"
            subtitle: "Texte en lettres blocs au-dessus de fastfetch"
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
            subtitle: "A-Z, 0-9, 16 caractères max. Actuel : « " + ShellCfg.banner + " »"
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
            subtitle: TermCfg.extra === "pokemon" && TermCfg.fetch ? "Le Pokémon remplace le logo de fastfetch" : "Un petit extra à chaque terminal"
            Segmented {
                compact: true
                model: TermCfg.extras.map(e => ({ id: e.id, label: e.label }))
                current: TermCfg.extra
                onSelected: id => TermCfg.set("extra", id)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            visible: TermCfg.extra === "pokemon"
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

    SectionHeader { Layout.fillWidth: true; text: "Apparence" }

    Group {
        Layout.fillWidth: true

        SettingRow {
            Layout.fillWidth: true
            icon: "format_size"
            title: "Taille de police"
            subtitle: "Alacritty, Kitty et Ghostty — « défaut » garde la config de chaque terminal"
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
                icon: "restart_alt"
                size: 30
                iconSize: 17
                tooltip: "Taille de chaque terminal"
                disabled: TermCfg.fontSize <= 0
                onClicked: TermCfg.set("fontSize", 0)
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
                icon: "restart_alt"
                size: 30
                iconSize: 17
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
                icon: "restart_alt"
                size: 30
                iconSize: 17
                tooltip: "Marges de chaque terminal"
                disabled: TermCfg.padding < 0
                onClicked: TermCfg.set("padding", -1)
            }
        }
    }

    Txt {
        Layout.fillWidth: true
        role: "caption"
        color: Theme.textFaint
        wrapMode: Text.Wrap
        text: "Alacritty et Kitty se mettent à jour en direct ; Ghostty applique les changements aux nouvelles fenêtres (ou Ctrl+Maj+, pour recharger)."
    }

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
                icon: "refresh"
                size: 30
                iconSize: 17
                tooltip: "Revérifier les paquets installés"
                onClicked: TermCfg.refreshTools()
            }
        }
    }
}
