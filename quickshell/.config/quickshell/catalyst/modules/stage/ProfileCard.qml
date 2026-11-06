pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.rice
import qs.kit

// Carte de profil façon réseau social : bannière, avatar qui chevauche, nom,
// pronoms, statut, bio, localisation / site, centres d'intérêt, réseaux.
// Utilisée en aperçu dans le Studio et en panneau (clic sur l'avatar du
// centre de contrôle).
Rectangle {
    id: root

    property bool interactive: true
    readonly property int bannerH: 132
    readonly property int avatarSize: 84

    implicitWidth: 400
    implicitHeight: body.y + body.implicitHeight + 18
    radius: Tokens.rXl
    color: Theme.s1
    border.width: 1
    border.color: Theme.border
    clip: true

    // coins arrondis aussi pour la bannière (clip ne suit pas le rayon)
    layer.enabled: true
    layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: cardMask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }
    Rectangle {
        id: cardMask
        anchors.fill: parent
        radius: root.radius
        visible: false
        layer.enabled: true
    }

    // ---- bannière ----
    Item {
        id: bannerBox
        width: parent.width
        height: root.bannerH

        // dégradé d'accent quand il n'y a pas d'image
        Rectangle {
            anchors.fill: parent
            visible: !Profile.hasBanner || bannerImg.status !== Image.Ready
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Theme.accent }
                GradientStop { position: 1; color: Theme.electric }
            }
        }
        Item {
            anchors.fill: parent
            clip: true
            Image {
                id: bannerImg
                source: Profile.hasBanner ? "file://" + Profile.banner : ""
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                width: parent.width
                // image à pleine largeur, décalée selon le cadrage choisi
                height: implicitHeight > 0 && implicitWidth > 0 ? width * implicitHeight / implicitWidth : parent.height
                y: -Math.max(0, height - parent.height) * Profile.bannerY
                sourceSize.width: 900
            }
        }
        // fondu vers la carte
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 40
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: Qt.alpha(Theme.s1, 0.55) }
            }
        }
    }

    // ---- avatar (chevauche la bannière) ----
    Rectangle {
        id: avatarRing
        x: 18
        y: root.bannerH - root.avatarSize / 2 - 4
        width: root.avatarSize + 8
        height: width
        radius: Identity.avatarShape === "square" ? Tokens.rMd : (Identity.avatarShape === "soft" ? Tokens.rLg : width / 2)
        color: Theme.s1

        Art {
            anchors.centerIn: parent
            width: root.avatarSize
            height: width
            source: Identity.hasAvatar ? Identity.avatar : ""
            radius: Identity.avatarShape === "square" ? Tokens.rSm : (Identity.avatarShape === "soft" ? Tokens.rMd : width / 2)
            fallbackIcon: "person"
        }
        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 6
            width: 18
            height: 18
            radius: 9
            color: Net.online ? Theme.success : Theme.textFaint
            border.width: 3
            border.color: Theme.s1
        }
    }

    // pronoms + hôte, à droite de l'avatar
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 16
        y: root.bannerH + 10
        spacing: 6
        Rectangle {
            visible: Profile.pronouns.length > 0
            height: 22
            width: pronTxt.implicitWidth + 16
            radius: 11
            color: Qt.alpha(Theme.accent, 0.14)
            border.width: 1
            border.color: Qt.alpha(Theme.accent, 0.4)
            Txt { id: pronTxt; anchors.centerIn: parent; role: "caption"; text: Profile.pronouns; color: Theme.accent }
        }
        Rectangle {
            height: 22
            width: hostTxt.implicitWidth + 16
            radius: 11
            color: Theme.s3
            border.width: 1
            border.color: Theme.border
            Txt { id: hostTxt; anchors.centerIn: parent; role: "mono"; font.pixelSize: 10; text: Identity.userLogin + "@" + Identity.hostName; color: Theme.textSub }
        }
    }

    // ---- contenu ----
    ColumnLayout {
        id: body
        x: 20
        y: root.bannerH + root.avatarSize / 2 + 14
        width: root.width - 40
        spacing: 10

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Txt {
                Layout.fillWidth: true
                role: "title"
                font.family: Theme.displayFont
                font.pixelSize: Tokens.fTitle + 5
                font.weight: Font.Bold
                text: Identity.userName
                elide: Text.ElideRight
            }
            Txt {
                Layout.fillWidth: true
                visible: Identity.userStatus.length > 0
                role: "body"
                color: Theme.textSub
                text: Identity.userStatus
                elide: Text.ElideRight
            }
        }

        Txt {
            Layout.fillWidth: true
            visible: Profile.bio.length > 0
            role: "body"
            text: Profile.bio
            wrapMode: Text.Wrap
            maximumLineCount: 5
            elide: Text.ElideRight
        }

        // localisation · site web
        Flow {
            Layout.fillWidth: true
            visible: Profile.location.length > 0 || Profile.website.length > 0
            spacing: 14
            Row {
                visible: Profile.location.length > 0
                spacing: 6
                Text { text: Profile.locationGlyph; font.family: Theme.font; font.pixelSize: 14; color: Theme.textFaint; anchors.verticalCenter: parent.verticalCenter }
                Txt { role: "caption"; text: Profile.location; color: Theme.textSub; anchors.verticalCenter: parent.verticalCenter }
            }
            Row {
                visible: Profile.website.length > 0
                spacing: 6
                Text { text: Profile.webGlyph; font.family: Theme.font; font.pixelSize: 14; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                Txt {
                    role: "caption"
                    text: Profile.websiteLabel()
                    color: Theme.accent
                    font.underline: webArea.containsMouse
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea {
                        id: webArea
                        anchors.fill: parent
                        enabled: root.interactive
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Profile.openWebsite()
                    }
                }
            }
        }

        // centres d'intérêt
        Flow {
            Layout.fillWidth: true
            visible: Profile.tags.length > 0
            spacing: 6
            Repeater {
                model: Profile.tags
                Rectangle {
                    required property string modelData
                    height: 24
                    width: tagTxt.implicitWidth + 18
                    radius: 12
                    color: Theme.s3
                    border.width: 1
                    border.color: Theme.border
                    Txt { id: tagTxt; anchors.centerIn: parent; role: "caption"; text: parent.modelData; color: Theme.text }
                }
            }
        }

        // réseaux
        Flow {
            Layout.fillWidth: true
            visible: Profile.activeLinks.length > 0
            spacing: 6
            Repeater {
                model: Profile.activeLinks
                Rectangle {
                    id: chip
                    required property var modelData
                    height: 30
                    width: chipRow.implicitWidth + 20
                    radius: Tokens.rMd
                    color: chipArea.containsMouse ? Qt.alpha(Theme.accent, 0.16) : Theme.s2
                    border.width: 1
                    border.color: chipArea.containsMouse ? Qt.alpha(Theme.accent, 0.5) : Theme.border
                    Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
                    Row {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 7
                        Text { text: chip.modelData.glyph; font.family: Theme.font; font.pixelSize: 15; color: chipArea.containsMouse ? Theme.accent : Theme.text; anchors.verticalCenter: parent.verticalCenter }
                        Txt { role: "caption"; text: Profile.link(chip.modelData.id); color: Theme.textSub; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea {
                        id: chipArea
                        anchors.fill: parent
                        enabled: root.interactive
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Profile.openNet(chip.modelData)
                    }
                    Tip { target: chip; text: chip.modelData.label + (chip.modelData.url.length ? "" : " — clic pour copier"); active: chipArea.containsMouse }
                }
            }
        }
    }
}
