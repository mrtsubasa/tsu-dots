pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.rice
import qs.kit

// Carte de profil : bannière (image ou motif généré aux couleurs du thème),
// avatar en anneau lumineux, nom + pronoms, statut en citation, bio, méta,
// bande de stats du rice, centres d'intérêt et réseaux.
// Aperçu dans le Studio, panneau au clic sur l'avatar du centre de contrôle.
Rectangle {
    id: root

    property bool interactive: true
    readonly property int bannerH: 150
    readonly property int avatarSize: 88
    readonly property string wm: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") ? "Hyprland" : Identity.wmText
    readonly property string themeLabel: Themes.active.length ? (Themes.byId(Themes.active) ? Themes.byId(Themes.active).label : Themes.active) : (Theme.mode === "auto" ? "Material You" : "Palette " + Palettes.current)

    implicitWidth: 420
    implicitHeight: body.y + body.implicitHeight + 20
    radius: Tokens.rXl
    color: Theme.s1
    border.width: 1
    border.color: Qt.alpha(Theme.accent, 0.22)

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

    // léger reflet d'accent qui prolonge la bannière, sans couture
    Rectangle {
        y: root.bannerH
        width: root.width
        height: 180
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.alpha(Theme.accent, 0.07) }
            GradientStop { position: 1; color: "transparent" }
        }
    }

    // ================= bannière =================
    Item {
        id: bannerBox
        width: parent.width
        height: root.bannerH
        clip: true

        // ---- motif généré (sans image) ----
        Item {
            anchors.fill: parent
            visible: !Profile.hasBanner || bannerImg.status !== Image.Ready

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Theme.mix(Theme.background, Theme.accent, 0.85) }
                    GradientStop { position: 0.55; color: Theme.mix(Theme.background, Theme.signature, 0.55) }
                    GradientStop { position: 1.0; color: Theme.mix(Theme.background, Theme.electric, 0.75) }
                }
            }
            // assombrit vers le bas pour la lisibilité
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: Qt.alpha(Theme.background, 0.55) }
                }
            }
            // grille de points
            Grid {
                anchors.fill: parent
                anchors.margins: 6
                columns: Math.floor(width / 14)
                rowSpacing: 10
                columnSpacing: 10
                opacity: 0.22
                Repeater {
                    model: Math.floor((root.width - 12) / 14) * Math.floor((root.bannerH - 12) / 14)
                    Rectangle { width: 2; height: 2; radius: 1; color: "white" }
                }
            }
            // diagonales
            Repeater {
                model: 7
                Rectangle {
                    required property int index
                    x: root.width * 0.42 + index * 34
                    y: -40
                    width: 2 + (index % 3)
                    height: root.bannerH * 1.6
                    rotation: 28
                    color: "white"
                    opacity: 0.05 + (index % 2) * 0.04
                }
            }
            // marque en filigrane
            Text {
                anchors.right: parent.right
                anchors.rightMargin: -6
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -14
                text: ShellCfg.brand.toUpperCase()
                font.family: Theme.displayFont
                font.pixelSize: 64
                font.weight: Font.Black
                font.letterSpacing: -2
                color: "white"
                opacity: 0.12
            }
        }

        // ---- image choisie ----
        Image {
            id: bannerImg
            source: Profile.hasBanner ? "file://" + Profile.banner : ""
            visible: status === Image.Ready
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            width: parent.width
            // pleine largeur, décalée selon le cadrage choisi
            height: implicitHeight > 0 && implicitWidth > 0 ? width * implicitHeight / implicitWidth : parent.height
            y: -Math.max(0, height - parent.height) * Profile.bannerY
            sourceSize.width: 900
        }

        // lignes de balayage
        Column {
            anchors.fill: parent
            spacing: 3
            opacity: 0.07
            Repeater {
                model: Math.ceil(root.bannerH / 4)
                Rectangle { width: bannerBox.width; height: 1; color: "black" }
            }
        }

        // fondu vers la carte
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 56
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                // même teinte que le haut du reflet en dessous : pas de ligne de séparation
                GradientStop { position: 1; color: Theme.mix(Theme.s1, Theme.accent, 0.07) }
            }
        }

        // étiquette verre
        Rectangle {
            x: 14
            y: 14
            height: 22
            width: tagRow.implicitWidth + 16
            radius: 11
            color: Qt.alpha(Theme.background, 0.45)
            border.width: 1
            border.color: Qt.alpha("white", 0.18)
            Row {
                id: tagRow
                anchors.centerIn: parent
                spacing: 6
                Rectangle { width: 6; height: 6; radius: 3; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                Txt { role: "overline"; text: "// profil"; color: "white"; anchors.verticalCenter: parent.verticalCenter }
            }
        }

        // en ligne
        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 14
            y: 14
            height: 22
            width: onRow.implicitWidth + 16
            radius: 11
            color: Qt.alpha(Theme.background, 0.45)
            border.width: 1
            border.color: Qt.alpha("white", 0.18)
            Row {
                id: onRow
                anchors.centerIn: parent
                spacing: 6
                Rectangle {
                    width: 7; height: 7; radius: 3.5
                    color: Net.online ? Theme.success : Theme.textFaint
                    anchors.verticalCenter: parent.verticalCenter
                    SequentialAnimation on opacity {
                        running: Net.online && !Motion.reduced
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.35; duration: 900; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1; duration: 900; easing.type: Easing.InOutSine }
                    }
                }
                Txt { role: "caption"; text: Net.online ? "en ligne" : "hors ligne"; color: "white"; anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }

    // ================= avatar =================
    Item {
        id: avatarBox
        x: 22
        y: root.bannerH - root.avatarSize / 2 - 10
        width: root.avatarSize + 10
        height: width
        // lueur
        Item {
            anchors.fill: parent
            anchors.margins: -6
            layer.enabled: true
            layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 32 }
            ShapeFill { anchors.fill: parent; anchors.margins: 6; color: Qt.alpha(Theme.accent, 0.35) }
        }
        // anneau en dégradé
        ShapeFill {
            anchors.fill: parent
            gradient: [Theme.accent, Theme.electric]
        }
        ShapeFill {
            anchors.fill: parent
            anchors.margins: 3
            color: Theme.s1
        }
        Avatar {
            anchors.centerIn: parent
            width: root.avatarSize
            height: width
        }
    }

    // ================= contenu =================
    ColumnLayout {
        id: body
        x: 22
        y: root.bannerH + root.avatarSize / 2 + 4
        width: root.width - 44
        spacing: 12

        // nom + pronoms, puis @login · hôte
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Txt {
                    Layout.maximumWidth: body.width - (pronChip.visible ? pronChip.width + 8 : 0)
                    role: "hero"
                    font.pixelSize: Tokens.fTitle + 7
                    font.weight: Font.Bold
                    text: Identity.userName
                    elide: Text.ElideRight
                }
                Rectangle {
                    id: pronChip
                    visible: Profile.pronouns.length > 0
                    Layout.alignment: Qt.AlignVCenter
                    height: 20
                    width: pronTxt.implicitWidth + 14
                    radius: 10
                    color: Qt.alpha(Theme.accent, 0.16)
                    border.width: 1
                    border.color: Qt.alpha(Theme.accent, 0.45)
                    Txt { id: pronTxt; anchors.centerIn: parent; role: "caption"; text: Profile.pronouns; color: Theme.accent }
                }
                Item { Layout.fillWidth: true }
            }
            Txt {
                Layout.fillWidth: true
                role: "mono"
                font.pixelSize: 11
                text: "@" + Identity.userLogin + "  ·  " + Identity.hostName
                color: Theme.textFaint
                elide: Text.ElideRight
            }
        }

        // statut en citation
        RowLayout {
            Layout.fillWidth: true
            visible: Identity.userStatus.length > 0
            spacing: 10
            Rectangle {
                Layout.preferredWidth: 3
                Layout.fillHeight: true
                radius: 1.5
                gradient: Gradient {
                    GradientStop { position: 0; color: Theme.accent }
                    GradientStop { position: 1; color: Theme.electric }
                }
            }
            Txt {
                Layout.fillWidth: true
                role: "body"
                font.italic: true
                text: Identity.userStatus
                color: Theme.text
                wrapMode: Text.Wrap
            }
        }

        Txt {
            Layout.fillWidth: true
            visible: Profile.bio.length > 0
            role: "body"
            text: Profile.bio
            color: Theme.textSub
            wrapMode: Text.Wrap
            maximumLineCount: 5
            elide: Text.ElideRight
            lineHeight: 1.15
        }

        // localisation · site
        Flow {
            Layout.fillWidth: true
            visible: Profile.location.length > 0 || Profile.website.length > 0
            spacing: 16
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

        // bande de stats du rice
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 54
            radius: Tokens.rLg
            color: Theme.s2
            border.width: 1
            border.color: Theme.border
            RowLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 0
                Repeater {
                    model: [
                        { k: "uptime", v: SysInfo.uptime.length ? SysInfo.uptime : "—" },
                        { k: "thème", v: root.themeLabel },
                        { k: "wm", v: root.wm }
                    ]
                    Item {
                        id: stat
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Rectangle {
                            visible: stat.index > 0
                            width: 1
                            height: parent.height * 0.55
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.divider
                        }
                        Column {
                            anchors.centerIn: parent
                            width: parent.width - 12
                            spacing: 2
                            Txt { width: parent.width; horizontalAlignment: Text.AlignHCenter; role: "overline"; text: stat.modelData.k; color: Theme.textFaint }
                            Txt { width: parent.width; horizontalAlignment: Text.AlignHCenter; role: "label"; text: stat.modelData.v; elide: Text.ElideRight; color: Theme.text }
                        }
                    }
                }
            }
        }

        // centres d'intérêt
        ColumnLayout {
            Layout.fillWidth: true
            visible: Profile.tags.length > 0
            spacing: 6
            Txt { role: "overline"; text: "// intérêts"; color: Theme.accent }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: Profile.tags
                    Rectangle {
                        required property string modelData
                        height: 26
                        width: tagTxt.implicitWidth + 22
                        radius: 13
                        color: Qt.alpha(Theme.accent, 0.10)
                        border.width: 1
                        border.color: Qt.alpha(Theme.accent, 0.28)
                        Txt { id: tagTxt; anchors.centerIn: parent; role: "label"; text: "# " + parent.modelData; color: Theme.text }
                    }
                }
            }
        }

        // réseaux : boutons-icônes
        ColumnLayout {
            Layout.fillWidth: true
            visible: Profile.activeLinks.length > 0
            spacing: 6
            Txt { role: "overline"; text: "// liens"; color: Theme.accent }
            Flow {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: Profile.activeLinks
                    Rectangle {
                        id: chip
                        required property var modelData
                        width: 40
                        height: 40
                        radius: Tokens.rMd
                        color: chipArea.containsMouse ? Qt.alpha(Theme.accent, 0.18) : Theme.s2
                        border.width: 1
                        border.color: chipArea.containsMouse ? Qt.alpha(Theme.accent, 0.6) : Theme.border
                        scale: chipArea.pressed ? 0.94 : (chipArea.containsMouse ? 1.06 : 1)
                        Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
                        Behavior on scale { NumberAnimation { duration: Motion.dur(Motion.fast); easing.type: Easing.OutCubic } }
                        Text {
                            anchors.centerIn: parent
                            text: chip.modelData.glyph
                            font.family: Theme.font
                            font.pixelSize: 18
                            color: chipArea.containsMouse ? Theme.accent : Theme.text
                        }
                        MouseArea {
                            id: chipArea
                            anchors.fill: parent
                            enabled: root.interactive
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Profile.openNet(chip.modelData)
                        }
                        Tip {
                            target: chip
                            text: chip.modelData.label + " · " + Profile.link(chip.modelData.id) + (chip.modelData.url.length ? "" : " (clic pour copier)")
                            active: chipArea.containsMouse
                        }
                    }
                }
            }
        }
    }
}
