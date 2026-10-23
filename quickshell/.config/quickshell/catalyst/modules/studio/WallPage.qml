pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit

// Fonds d'écran : bibliothèque locale (miniatures chargées à la volée),
// cible « tous les écrans » (avec Material You) ou un écran précis.
ColumnLayout {
    id: root
    spacing: 16

    property string target: ""     // "" = tous les écrans
    property string filter: ""

    readonly property var shown: {
        const f = filter.trim().toLowerCase();
        const all = Walls.files;
        return f.length ? all.filter(p => p.toLowerCase().indexOf(f) >= 0) : all;
    }

    Component.onCompleted: Walls.scan()

    // écrans
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Segmented {
            model: [{ id: "", label: "Tous les écrans", icon: "desktop_windows" }].concat(Quickshell.screens.map(s => ({ id: s.name, label: s.name, icon: "monitor" })))
            current: root.target
            onSelected: id => root.target = id
        }
        Item { Layout.fillWidth: true }
        SearchField {
            Layout.preferredWidth: 220
            fieldHeight: Tokens.ctrl
            placeholder: "Filtrer…"
            onTextChanged: root.filter = text
        }
        IconButton {
            icon: "shuffle"
            variant: "tonal"
            tooltip: "Fond aléatoire"
            onClicked: Walls.random()
        }
        IconButton {
            icon: "refresh"
            variant: "tonal"
            tooltip: "Rafraîchir la bibliothèque"
            onClicked: Walls.scan()
        }
    }

    // fonds actuels par écran
    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        Repeater {
            model: Quickshell.screens
            Pane {
                id: cur
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 74
                level: 3
                glass: false
                radius: Tokens.rLg
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 12
                    Art {
                        Layout.preferredWidth: 96
                        Layout.preferredHeight: 54
                        source: "file://" + Walls.wallFor(cur.modelData.name)
                        radius: Tokens.rSm
                        fallbackIcon: "wallpaper"
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Txt { role: "overline"; text: cur.modelData.name; color: Theme.accent }
                        Txt {
                            Layout.fillWidth: true
                            role: "caption"
                            elide: Text.ElideMiddle
                            text: Walls.wallFor(cur.modelData.name).split("/").pop()
                        }
                        Txt {
                            role: "caption"
                            color: Theme.textFaint
                            text: Walls.perOutput[cur.modelData.name] ? "Fond propre à cet écran" : "Fond global"
                        }
                    }
                }
            }
        }
    }

    SectionHeader {
        Layout.fillWidth: true
        text: "Bibliothèque  " + root.shown.length
        actionText: "Ouvrir le dossier"
        actionIcon: "folder_open"
        onAction: Quickshell.execDetached(["xdg-open", Walls.dir])
    }

    Spinner { visible: Walls.scanning; Layout.alignment: Qt.AlignHCenter }

    GridLayout {
        Layout.fillWidth: true
        columns: Math.max(2, Math.floor(width / 186))
        columnSpacing: 10
        rowSpacing: 10

        Repeater {
            // la grille se construit par lots de 48 pour rester fluide
            model: root.shown.slice(0, more.count)

            Item {
                id: tile
                required property string modelData
                readonly property bool isVid: Walls.isVideo(modelData)
                readonly property bool on: root.target.length ? Walls.wallFor(root.target) === modelData : Walls.current === modelData
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
                        source: Walls.thumbOf(tile.modelData)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Motion.dur(Motion.base) } }
                    }
                    Spinner {
                        visible: thumb.status !== Image.Ready && !tile.isVid
                        anchors.centerIn: parent
                        size: 16
                        color: Theme.textFaint
                    }
                    Icon {
                        visible: tile.isVid
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 6
                        name: "movie"
                        size: 28
                        color: Theme.textSub
                    }
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 26
                        visible: hov.containsMouse || tile.isVid
                        gradient: Gradient {
                            GradientStop { position: 0; color: "transparent" }
                            GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.7) }
                        }
                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 6
                            text: tile.modelData.split("/").pop()
                            elide: Text.ElideMiddle
                            color: "white"
                            font.family: Theme.uiFont
                            font.pixelSize: 10
                        }
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    radius: Tokens.rMd
                    color: "transparent"
                    border.width: tile.on ? 2 : (hov.containsMouse ? 1 : 0)
                    border.color: tile.on ? Theme.accent : Theme.borderStrong
                    Icon {
                        visible: tile.on
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 6
                        name: "check_circle"
                        fill: 1
                        size: 18
                        color: Theme.accent
                    }
                }
                StateLayer {
                    id: hov
                    anchors.fill: parent
                    radius: Tokens.rMd
                    hoverAlpha: 0.0
                    onClicked: Walls.set(tile.modelData, root.target)
                }
            }
        }
    }

    Item {
        id: more
        property int count: 48
        Layout.fillWidth: true
        implicitHeight: visible ? 40 : 0
        visible: root.shown.length > count
        Button {
            anchors.centerIn: parent
            variant: "secondary"
            text: "Afficher plus (" + (root.shown.length - more.count) + ")"
            onClicked: more.count += 48
        }
    }

    SectionHeader { Layout.fillWidth: true; text: "Sources en ligne" }
    Txt {
        Layout.fillWidth: true
        role: "caption"
        color: Theme.textFaint
        wrapMode: Text.WordWrap
        text: "Ouvre tes scripts de téléchargement existants ; rien n'est récupéré tant que tu ne lances pas une source."
    }
    Flow {
        Layout.fillWidth: true
        spacing: 8
        Repeater {
            model: [
                { label: "Wallhaven", cmd: "wallhaven_wallpaper.sh" },
                { label: "Konachan", cmd: "konachan_wallpaper.sh" },
                { label: "Yande.re", cmd: "yandere_wallpaper.sh" },
                { label: "Gelbooru", cmd: "gelbooru_wallpaper.sh" },
                { label: "Unsplash", cmd: "unsplash_wallpaper.sh" }
            ]
            Button {
                required property var modelData
                variant: "secondary"
                icon: "travel_explore"
                text: modelData.label
                onClicked: {
                    const s = Quickshell.env("HOME") + "/.config/niri/scripts/";
                    Quickshell.execDetached(["bash", s + "here.sh", "--", s + modelData.cmd]);
                    PanelService.hide();
                }
            }
        }
    }
}
