pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit

// Navigateur de fonds d'écran en ligne (WallHub). Images (Wallhaven + boorus
// anime) ou fonds animés (MotionBGs, Gelbooru), recherche, grille de
// miniatures distantes, application en 1 clic (télécharge dans la
// bibliothèque puis pose sur l'écran cible ; une vidéo se pose partout).
ColumnLayout {
    id: root
    spacing: 12

    property string target: ""     // écran cible ("" = tous)

    // ---- type ----
    Segmented {
        model: [
            { id: "image", label: "Images", icon: "image" },
            { id: "live", label: "Animés", icon: "movie" }
        ]
        current: WallHub.kind
        onSelected: id => WallHub.setKind(id)
    }

    // ---- sources ----
    Flow {
        Layout.fillWidth: true
        spacing: 8
        Repeater {
            model: WallHub.shownSources
            Rectangle {
                id: chip
                required property var modelData
                readonly property bool on: WallHub.source === modelData.id
                implicitWidth: chRow.implicitWidth + 24
                implicitHeight: 34
                radius: Tokens.rLg
                color: on ? Theme.accent : Theme.s3
                border.width: on ? 0 : 1
                border.color: Theme.border
                RowLayout {
                    id: chRow
                    anchors.centerIn: parent
                    spacing: 6
                    Icon {
                        name: chip.modelData.icon
                        size: 15
                        fill: chip.on ? 1 : 0
                        color: chip.on ? Theme.onAccent : Theme.textSub
                    }
                    Txt {
                        text: chip.modelData.label
                        role: "label"
                        color: chip.on ? Theme.onAccent : Theme.text
                    }
                    Rectangle {
                        visible: chip.modelData.anime
                        implicitWidth: aTxt.implicitWidth + 10
                        implicitHeight: 16
                        radius: 8
                        color: chip.on ? Qt.rgba(0, 0, 0, 0.18) : Theme.s1
                        Text {
                            id: aTxt
                            anchors.centerIn: parent
                            text: "anime"
                            font.family: Theme.uiFont
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            color: chip.on ? Theme.onAccent : Theme.accent2
                        }
                    }
                }
                StateLayer {
                    anchors.fill: parent
                    radius: Tokens.rLg
                    onClicked: WallHub.setSource(chip.modelData.id)
                }
            }
        }
    }

    // ---- classification (filtre predef) ----
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Segmented {
            model: [
                { id: "safe", label: "SFW", icon: "shield" },
                { id: "nsfw", label: "NSFW", icon: "explicit" },
                { id: "all", label: "Tout", icon: "all_inclusive" }
            ]
            current: WallHub.rating
            onSelected: id => WallHub.setRating(id)
        }
        Item { Layout.fillWidth: true }
        Txt {
            visible: WallHub.rating !== "safe" && (WallHub.source === "safebooru" || WallHub.source === "motionbgs")
            role: "caption"
            color: Theme.warning
            text: WallHub.srcMeta.label + " reste SFW"
        }
        Txt {
            visible: WallHub.rating === "nsfw" && WallHub.source === "wallhaven"
            role: "caption"
            color: Theme.textFaint
            text: "Wallhaven : NSFW complet = clé API"
        }
    }

    // ---- recherche ----
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        SearchField {
            Layout.fillWidth: true
            fieldHeight: Tokens.ctrl
            text: WallHub.query
            placeholder: WallHub.source === "wallhaven"
                ? "Rechercher… (préfixe anime: ou photo:)"
                : WallHub.source === "motionbgs"
                ? "Rechercher… (ex. silver wolf, rain, city) — vide = nouveautés"
                : "Rechercher des tags… (ex. scenery, city, sky)"
            onTextChanged: WallHub.query = text
        }
        IconButton {
            icon: "refresh"
            variant: "tonal"
            tooltip: "Relancer"
            onClicked: WallHub.search(true)
        }
    }

    // ---- presets de tags ----
    Flow {
        Layout.fillWidth: true
        spacing: 7
        Repeater {
            model: WallHub.presets
            Rectangle {
                id: pchip
                required property var modelData
                readonly property bool on: WallHub.query === modelData.q
                implicitWidth: pTxt.implicitWidth + 22
                implicitHeight: 28
                radius: Tokens.rLg
                color: on ? Theme.accent2 : Theme.s2
                border.width: on ? 0 : 1
                border.color: Theme.border
                Txt {
                    id: pTxt
                    anchors.centerIn: parent
                    text: pchip.modelData.label
                    role: "caption"
                    color: pchip.on ? Theme.onAccent : Theme.textSub
                }
                StateLayer {
                    anchors.fill: parent
                    radius: Tokens.rLg
                    onClicked: WallHub.usePreset(pchip.modelData.q)
                }
            }
        }
    }

    // ---- état ----
    RowLayout {
        Layout.fillWidth: true
        visible: WallHub.error.length > 0
        spacing: 8
        Icon { name: "error"; size: 16; color: Theme.error }
        Txt { Layout.fillWidth: true; role: "caption"; color: Theme.error; text: WallHub.error; wrapMode: Text.WordWrap }
    }

    Spinner {
        visible: WallHub.loading && WallHub.items.length === 0
        Layout.alignment: Qt.AlignHCenter
    }

    EmptyState {
        visible: !WallHub.loading && WallHub.items.length === 0 && WallHub.error.length === 0
        Layout.fillWidth: true
        icon: "wallpaper"
        title: "Aucun résultat"
        text: "Change de source ou affine ta recherche."
    }

    // ---- grille ----
    GridLayout {
        Layout.fillWidth: true
        columns: Math.max(2, Math.floor(width / 196))
        columnSpacing: 10
        rowSpacing: 10

        Repeater {
            model: WallHub.items

            Item {
                id: tile
                required property var modelData
                readonly property bool busy: WallHub.busyId === (modelData.src + ":" + modelData.id)
                Layout.fillWidth: true
                Layout.preferredHeight: width * 9 / 16

                Rectangle {
                    anchors.fill: parent
                    radius: Tokens.rMd
                    color: Theme.s3
                    clip: true

                    Image {
                        id: thumb
                        anchors.fill: parent
                        source: tile.modelData.thumb
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        sourceSize.width: 400
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Motion.dur(Motion.base) } }
                    }
                    Spinner {
                        visible: thumb.status === Image.Loading
                        anchors.centerIn: parent
                        size: 16
                        color: Theme.textFaint
                    }
                    Icon {
                        visible: thumb.status === Image.Error
                        anchors.centerIn: parent
                        name: "broken_image"
                        size: 24
                        color: Theme.textFaint
                    }

                    // bandeau résolution (au survol)
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 24
                        visible: hov.containsMouse && !tile.busy
                        gradient: Gradient {
                            GradientStop { position: 0; color: "transparent" }
                            GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.75) }
                        }
                        Text {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            anchors.margins: 6
                            anchors.right: parent.right
                            elide: Text.ElideRight
                            text: tile.modelData.res
                            color: "white"
                            font.family: Theme.monoFont
                            font.pixelSize: 10
                        }
                    }

                    // marque « vidéo » (fond animé)
                    Icon {
                        visible: !!tile.modelData.video
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.margins: 6
                        name: "movie"
                        size: 18
                        color: "white"
                    }

                    // voile « téléchargement »
                    Rectangle {
                        anchors.fill: parent
                        visible: tile.busy
                        color: Qt.rgba(0, 0, 0, 0.55)
                        Spinner { anchors.centerIn: parent; size: 22; color: "white" }
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    radius: Tokens.rMd
                    color: "transparent"
                    border.width: hov.containsMouse ? 1 : 0
                    border.color: Theme.borderStrong
                    Icon {
                        visible: hov.containsMouse && !tile.busy
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 6
                        name: tile.modelData.video ? "play_circle" : "add_photo_alternate"
                        size: 18
                        color: "white"
                    }
                }
                StateLayer {
                    id: hov
                    anchors.fill: parent
                    radius: Tokens.rMd
                    hoverAlpha: 0.0
                    disabled: tile.busy
                    onClicked: WallHub.apply(tile.modelData, root.target)
                }
            }
        }
    }

    // ---- pagination ----
    Item {
        Layout.fillWidth: true
        implicitHeight: 40
        visible: WallHub.items.length > 0
        Button {
            anchors.centerIn: parent
            variant: "secondary"
            text: WallHub.loading ? "Chargement…" : (WallHub.more ? "Charger plus" : "Fin des résultats")
            disabled: WallHub.loading || !WallHub.more
            onClicked: WallHub.loadMore()
        }
    }
}
