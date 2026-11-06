pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Interface : densité, animations (mouvement réduit), OSD, notifications.
ColumnLayout {
    id: root
    spacing: 16

    SectionHeader { Layout.fillWidth: true; text: "Interface" }

    Group {
        Layout.fillWidth: true

        SettingRow {
            Layout.fillWidth: true
            icon: "diamond"
            title: "Mot de marque"
            subtitle: "Affiché dans les en-têtes, le launcher, le Studio, les notifications et l'écran de verrouillage. Actuel : « " + ShellCfg.brand + " »"
            Field {
                width: 180
                placeholder: ShellCfg.brand
                onAccepted: t => { ShellCfg.setBrand(t); text = ""; }
            }
            IconButton {
                icon: "restart_alt"
                size: 30
                iconSize: 17
                tooltip: "Revenir à « catalyst »"
                disabled: ShellCfg.brand === "catalyst"
                onClicked: ShellCfg.setBrand("catalyst")
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "apps"
            title: "Style du launcher"
            subtitle: "Liste détaillée, barre compacte type Spotlight, grille d'icônes, grille plein écran ou console façon terminal"
            Segmented {
                compact: true
                model: [{ id: "list", label: "Liste" }, { id: "compact", label: "Compact" }, { id: "grid", label: "Grille" }, { id: "full", label: "Plein écran" }, { id: "console", label: "Console" }]
                current: ShellCfg.launcherStyle
                onSelected: id => ShellCfg.set("launcherStyle", id)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "open_with"
            title: "Position du launcher"
            subtitle: ShellCfg.launcherStyle === "full" ? "Le style plein écran est toujours centré" : "Où il s'ouvre sur l'écran"
            Segmented {
                compact: true
                model: [{ id: "top", label: "Haut" }, { id: "center", label: "Centre" }, { id: "bottom", label: "Bas" }, { id: "left", label: "Gauche" }, { id: "right", label: "Droite" }]
                current: ShellCfg.launcherPos
                onSelected: id => ShellCfg.set("launcherPos", id)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "density_medium"
            title: "Densité"
            subtitle: "Hauteur de la barre et espacements"
            Segmented {
                compact: true
                model: [{ id: "compact", label: "Compacte" }, { id: "regular", label: "Normale" }, { id: "air", label: "Aérée" }]
                current: Tokens.density
                onSelected: id => Tokens.setDensity(id)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "wb_twilight"
            title: "True Tone"
            subtitle: Night.trueTone ? "Blanc adapté à la lumière estimée · actuellement " + Night.currentK + " K (" + Night.phase + ")" : "Adapte le blanc de l'écran à la lumière du moment, sans capteur"
            Slider {
                visible: Night.trueTone
                width: 160
                implicitHeight: 30
                icon: "tune"
                value: Night.strength
                onMoved: v => Night.setStrength(v)
            }
            Toggle {
                checked: Night.trueTone
                onToggled: v => Night.setTrueTone(v)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "sports_esports"
            title: "Mode jeu automatique"
            subtitle: "Jeu en plein écran : Ne pas déranger, pas de veille, profil Performance" + (GameMode.active ? " · actif : " + GameMode.game : "")
            Toggle {
                checked: ShellCfg.autoGameMode
                onToggled: v => ShellCfg.set("autoGameMode", v)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "code"
            title: "Éditeur des projets"
            subtitle: "Commande lancée depuis le launcher pour ouvrir un projet git (actuel : " + ShellCfg.editor + ")"
            Segmented {
                compact: true
                model: [{ id: "code", label: "VS Code" }, { id: "cursor", label: "Cursor" }, { id: "zed", label: "Zed" }, { id: "alacritty -e nvim", label: "Neovim" }]
                current: ShellCfg.editor
                onSelected: id => ShellCfg.set("editor", id)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "animation"
            title: "Réduire les animations"
            subtitle: "Ouvertures instantanées, aucun déplacement ; les fondus restent"
            Toggle {
                checked: Tokens.reducedMotion
                onToggled: v => Tokens.setReducedMotion(v)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "picture_in_picture"
            title: "Indicateur à l'écran (OSD)"
            subtitle: "Volume, micro et luminosité lors d'un changement"
            Toggle {
                checked: ShellCfg.osd
                onToggled: v => ShellCfg.set("osd", v)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "do_not_disturb_on"
            title: "Ne pas déranger"
            subtitle: "Les notifications arrivent dans l'historique sans s'afficher"
            Toggle {
                checked: Notifs.dnd
                onToggled: Notifs.toggleDnd()
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "toolbar"
            title: "Barre supérieure"
            subtitle: "Désactiver uniquement pour un poste sans barre"
            Toggle {
                checked: ShellCfg.bar
                onToggled: v => ShellCfg.set("bar", v)
            }
        }
    }

    SectionHeader { Layout.fillWidth: true; text: "Curseur" }

    Group {
        Layout.fillWidth: true

        SettingRow {
            Layout.fillWidth: true
            icon: "mouse"
            title: "Thème"
            subtitle: Cursor.ready ? (Cursor.theme.length ? Cursor.theme : "défaut") + " · " + Cursor.themes.length + " installés" : "chargement…"
            Button {
                id: curBtn
                variant: "secondary"
                icon: "expand_more"
                text: Cursor.theme.length ? Cursor.theme : "Choisir…"
                onClicked: curMenu.openAt(curBtn)
            }
            Menu {
                id: curMenu
                side: "bottom"
                items: Cursor.themes.map(t => ({
                    label: t.name + (t.hypr ? "  (hypr)" : ""),
                    icon: Cursor.theme === t.name ? "check" : "mouse",
                    action: () => Cursor.setTheme(t.name)
                }))
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "photo_size_select_small"
            title: "Taille"
            subtitle: Cursor.size + " px"
            Slider {
                width: 200
                implicitHeight: 30
                icon: "aspect_ratio"
                maximum: 64
                value: Cursor.size
                step: 2
                valueText: Cursor.size + " px"
                onMoved: v => Cursor.setSize(Math.round(v))
            }
            IconButton {
                icon: "restart_alt"
                size: 30
                tooltip: "24 px"
                disabled: Cursor.size === 24
                onClicked: Cursor.setSize(24)
            }
        }
    }

    SectionHeader { Layout.fillWidth: true; text: "Notifications" }

    Group {
        Layout.fillWidth: true

        SettingRow {
            Layout.fillWidth: true
            icon: "picture_in_picture_alt"
            title: "Coin d'affichage"
            subtitle: "Où les notifications apparaissent à l'écran"
            Segmented {
                compact: true
                model: [
                    { id: "top-left", label: "Haut G." },
                    { id: "top-center", label: "Haut C." },
                    { id: "top-right", label: "Haut D." },
                    { id: "bottom-left", label: "Bas G." },
                    { id: "bottom-right", label: "Bas D." }
                ]
                current: ShellCfg.notifPos
                onSelected: id => ShellCfg.set("notifPos", id)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "timer"
            title: "Durée"
            subtitle: "Temps d'affichage d'une notification (celles avec actions restent plus longtemps)"
            Slider {
                width: 200
                implicitHeight: 30
                icon: "timer"
                maximum: 15
                value: ShellCfg.notifDuration
                step: 1
                valueText: ShellCfg.notifDuration + " s"
                onMoved: v => ShellCfg.set("notifDuration", Math.round(v))
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "stacked_bar_chart"
            title: "Nombre empilé"
            subtitle: "Combien de notifications visibles à la fois (les suivantes attendent)"
            Slider {
                width: 200
                implicitHeight: 30
                icon: "stacked_bar_chart"
                maximum: 5
                value: ShellCfg.notifMax
                step: 1
                valueText: String(ShellCfg.notifMax)
                onMoved: v => ShellCfg.set("notifMax", Math.round(v))
            }
        }
    }

    SectionHeader { Layout.fillWidth: true; text: "Raccourcis utiles" }

    Group {
        Layout.fillWidth: true
        Repeater {
            model: [
                { k: "Clic sur la marque ◆", d: "Launcher (clic droit : Studio)" },
                { k: "Super + D / Super + G", d: "Launcher" },
                { k: "Super + Y", d: "Centre de contrôle" },
                { k: "Super + Shift + ,", d: "Studio" },
                { k: "Super + Shift + O", d: "Vue d'ensemble" },
                { k: "Clic milieu sur l'état", d: "Couper / rétablir le son" },
                { k: "Clic droit sur la cloche", d: "Ne pas déranger" }
            ]
            SettingRow {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 44
                title: modelData.d
                Txt {
                    role: "mono"
                    text: modelData.k
                    color: Theme.accent
                }
            }
        }
    }
}
