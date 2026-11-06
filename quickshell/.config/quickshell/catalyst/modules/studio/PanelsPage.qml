pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Interface : densité, animations (mouvement réduit), OSD, notifications.
ColumnLayout {
    id: root
    spacing: 16

    SectionHeader { Layout.fillWidth: true; text: "Profil" }

    Group {
        Layout.fillWidth: true

        SettingRow {
            Layout.fillWidth: true
            title: Identity.userName
            subtitle: Identity.userStatus.length ? Identity.userStatus : "Avatar, nom et statut (centre de contrôle, verrouillage)"
            Art {
                width: 44
                height: 44
                source: Identity.hasAvatar ? Identity.avatar : ""
                radius: Identity.avatarShape === "square" ? Tokens.rSm : (Identity.avatarShape === "soft" ? Tokens.rMd : 22)
                fallbackIcon: "person"
            }
            Button { variant: "secondary"; icon: "add_photo_alternate"; text: "Choisir…"; onClicked: Identity.pickAvatar() }
            IconButton { icon: "hide_image"; size: 32; iconSize: 17; tooltip: "Retirer l'avatar"; onClicked: Identity.studio("avatar:none") }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "badge"
            title: "Nom affiché"
            Field {
                width: 220
                placeholder: Identity.userName
                onAccepted: t => { if (t.trim().length) Identity.studio("name:" + t.trim()); text = ""; }
            }
        }
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
            icon: "chat_bubble"
            title: "Statut"
            Field {
                width: 220
                placeholder: Identity.userStatus || "ex. Développeur"
                onAccepted: t => { Identity.studio("status:" + t.trim()); text = ""; }
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "crop_square"
            title: "Forme de l'avatar"
            Segmented {
                compact: true
                model: [{ id: "circle", label: "Cercle" }, { id: "soft", label: "Doux" }, { id: "square", label: "Carré" }]
                current: Identity.avatarShape
                onSelected: id => Identity.studio("shape:" + id)
            }
        }
    }

    SectionHeader { Layout.fillWidth: true; text: "Interface" }

    Group {
        Layout.fillWidth: true

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
