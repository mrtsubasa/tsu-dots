pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit
import "../stage"

// Profil : identité (avatar, nom, pronoms, statut), bannière, bio, liens et
// centres d'intérêt, avec la carte en aperçu. Les infos étendues sont gardées
// hors du dépôt (~/.config/catalyst/profile.json).
ColumnLayout {
    id: root
    spacing: 16

    // ---- aperçu ----
    Item {
        Layout.fillWidth: true
        implicitHeight: card.implicitHeight
        ProfileCard {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width, 440)
        }
    }
    Txt {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        role: "caption"
        color: Theme.textFaint
        text: "Aperçu de ta carte — elle s'ouvre en cliquant sur ton avatar dans le centre de contrôle."
    }

    // ================= identité =================
    SectionHeader { Layout.fillWidth: true; text: "Identité" }

    Group {
        Layout.fillWidth: true

        SettingRow {
            Layout.fillWidth: true
            icon: "account_circle"
            title: "Avatar"
            subtitle: "Centre de contrôle, verrouillage, carte de profil"
            Button { variant: "secondary"; icon: "add_photo_alternate"; text: "Choisir…"; onClicked: Identity.pickAvatar() }
            IconButton { icon: "hide_image"; size: 32; iconSize: 17; tooltip: "Retirer l'avatar"; onClicked: Identity.studio("avatar:none") }
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
            icon: "record_voice_over"
            title: "Pronoms"
            subtitle: "Affichés en pastille sur la carte (ex. il/lui, elle, iel)"
            Field {
                width: 160
                placeholder: Profile.pronouns.length ? Profile.pronouns : "aucun"
                onAccepted: t => { Profile.set("pronouns", t.trim().slice(0, 24)); text = ""; }
            }
            IconButton {
                icon: "close"; size: 30; iconSize: 16
                tooltip: "Effacer"
                disabled: Profile.pronouns.length === 0
                onClicked: Profile.set("pronouns", "")
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "chat_bubble"
            title: "Statut"
            subtitle: "Une ligne sous ton nom"
            Field {
                width: 220
                placeholder: Identity.userStatus || "ex. Développeur"
                onAccepted: t => { Identity.studio("status:" + t.trim()); text = ""; }
            }
        }
    }

    // ================= bannière =================
    SectionHeader { Layout.fillWidth: true; text: "Bannière" }

    Group {
        Layout.fillWidth: true

        SettingRow {
            Layout.fillWidth: true
            icon: "panorama"
            title: "Image"
            subtitle: Profile.hasBanner ? "Copiée dans ~/.config/catalyst" : "Sans image : dégradé aux couleurs du thème"
            Button { variant: "secondary"; icon: "add_photo_alternate"; text: "Choisir…"; onClicked: Profile.pickBanner() }
            Button { variant: "secondary"; icon: "wallpaper"; text: "Fond d'écran actuel"; onClicked: Profile.useWallpaper() }
            IconButton {
                icon: "hide_image"; size: 32; iconSize: 17
                tooltip: "Retirer la bannière"
                disabled: !Profile.hasBanner
                onClicked: Profile.clearBanner()
            }
        }
        SettingRow {
            Layout.fillWidth: true
            visible: Profile.hasBanner
            icon: "vertical_align_center"
            title: "Cadrage"
            subtitle: "Partie de l'image visible dans la bannière"
            Slider {
                width: 220
                implicitHeight: 30
                icon: "vertical_align_center"
                value: Profile.bannerY
                valueText: Profile.bannerY < 0.2 ? "haut" : (Profile.bannerY > 0.8 ? "bas" : "centre")
                step: 0.05
                wheelAdjusts: false
                onMoved: v => Profile.set("bannerY", Math.round(v * 20) / 20)
            }
        }
    }

    // ================= à propos =================
    SectionHeader { Layout.fillWidth: true; text: "À propos" }

    Group {
        Layout.fillWidth: true

        SettingRow {
            Layout.fillWidth: true
            icon: "notes"
            title: "Bio"
            subtitle: Profile.bio.length ? Profile.bio : "Quelques mots sur toi (200 caractères max)"
            Field {
                width: 260
                placeholder: Profile.bio.length ? "remplacer la bio…" : "ta bio…"
                onAccepted: t => { Profile.set("bio", t.trim().slice(0, 200)); text = ""; }
            }
            IconButton {
                icon: "close"; size: 30; iconSize: 16
                tooltip: "Effacer"
                disabled: Profile.bio.length === 0
                onClicked: Profile.set("bio", "")
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "location_on"
            title: "Localisation"
            subtitle: "Facultatif — reste sur ta machine, mais visible sur ta carte (captures d'écran !)"
            Field {
                width: 200
                placeholder: Profile.location.length ? Profile.location : "ex. France"
                onAccepted: t => { Profile.set("location", t.trim().slice(0, 40)); text = ""; }
            }
            IconButton {
                icon: "close"; size: 30; iconSize: 16
                tooltip: "Effacer"
                disabled: Profile.location.length === 0
                onClicked: Profile.set("location", "")
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "language"
            title: "Site web"
            Field {
                width: 240
                placeholder: Profile.website.length ? Profile.websiteLabel() : "ex. monsite.dev"
                onAccepted: t => { Profile.set("website", t.trim().slice(0, 120)); text = ""; }
            }
            IconButton {
                icon: "close"; size: 30; iconSize: 16
                tooltip: "Effacer"
                disabled: Profile.website.length === 0
                onClicked: Profile.set("website", "")
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "sell"
            title: "Centres d'intérêt"
            subtitle: Profile.tags.length + " / 10 — Entrée pour ajouter"
            Field {
                width: 200
                placeholder: "ex. Linux, anime, cyber…"
                onAccepted: t => { Profile.addTag(t); text = ""; }
            }
        }
        Flow {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.bottomMargin: 12
            visible: Profile.tags.length > 0
            spacing: 6
            Repeater {
                model: Profile.tags
                Button {
                    required property string modelData
                    variant: "secondary"
                    icon: "close"
                    text: modelData
                    onClicked: Profile.removeTag(modelData)
                }
            }
        }
    }

    // ================= réseaux =================
    SectionHeader { Layout.fillWidth: true; text: "Réseaux" }

    Group {
        Layout.fillWidth: true

        Repeater {
            model: Profile.networks

            SettingRow {
                id: netRow
                required property var modelData
                Layout.fillWidth: true
                title: modelData.label
                subtitle: Profile.link(modelData.id).length ? (Profile.urlFor(modelData) || "copié dans le presse-papiers au clic") : modelData.hint
                Text {
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                    text: netRow.modelData.glyph
                    font.family: Theme.font
                    font.pixelSize: 18
                    color: Profile.link(netRow.modelData.id).length ? Theme.accent : Theme.textFaint
                }
                Field {
                    width: 200
                    placeholder: Profile.link(netRow.modelData.id).length ? Profile.link(netRow.modelData.id) : "—"
                    onAccepted: t => { Profile.setLink(netRow.modelData.id, t); text = ""; }
                }
                IconButton {
                    icon: "close"; size: 30; iconSize: 16
                    tooltip: "Retirer"
                    disabled: Profile.link(netRow.modelData.id).length === 0
                    onClicked: Profile.setLink(netRow.modelData.id, "")
                }
            }
        }
    }
}
