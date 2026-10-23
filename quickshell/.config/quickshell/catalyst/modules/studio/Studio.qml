pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Studio — éditeur de personnalisation. Chaque réglage écrit directement la
// configuration persistante (thèmes, bar.json, dock.json, widgets.json,
// tokens/shell.json) ; l'aperçu est le bureau lui-même, mis à jour en direct.
FocusScope {
    id: root

    property string page: "themes"
    property real maxHeight: 760

    implicitWidth: 1000
    implicitHeight: Math.min(maxHeight, 700)

    readonly property var pages: [
        { id: "themes", label: "Thèmes", icon: "palette", desc: "Couleurs, effets, thèmes personnalisés" },
        { id: "wall", label: "Fond d'écran", icon: "wallpaper", desc: "Image par écran, sources" },
        { id: "bar", label: "Barre", icon: "toolbar", desc: "Style, éléments, ordre" },
        { id: "dock", label: "Dock", icon: "dock_to_bottom", desc: "Position, taille, applications" },
        { id: "desk", label: "Bureau", icon: "dashboard_customize", desc: "Widgets et disposition" },
        { id: "panels", label: "Profil & interface", icon: "manage_accounts", desc: "Avatar, nom, densité, animations, OSD" },
        { id: "profiles", label: "Profils", icon: "bookmarks", desc: "Sauvegarder et restaurer" }
    ]

    Component.onCompleted: {
        if (PanelService.studioPage.length) {
            page = PanelService.studioPage;
            PanelService.studioPage = "";
        }
        forceActiveFocus();
    }

    Connections {
        target: PanelService
        function onStudioPageChanged() {
            if (PanelService.studioPage.length) {
                root.page = PanelService.studioPage;
                PanelService.studioPage = "";
            }
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            PanelService.hide();
            event.accepted = true;
        } else if ((event.modifiers & Qt.ControlModifier) && event.key >= Qt.Key_1 && event.key <= Qt.Key_7) {
            root.page = root.pages[event.key - Qt.Key_1].id;
            event.accepted = true;
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ---------------- navigation ----------------
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 232
            color: Qt.alpha(Theme.s0, 0.35)
            radius: Tokens.rXl

            // coins droits côté contenu
            Rectangle {
                anchors.right: parent.right
                width: parent.radius
                height: parent.height
                color: parent.color
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 14
                    Layout.leftMargin: 4
                    spacing: 10
                    Mark { size: 22 }
                    ColumnLayout {
                        spacing: 0
                        Txt { role: "title"; text: "Studio" }
                        Txt { role: "overline"; text: ShellCfg.brand; color: Theme.accent }
                    }
                }

                Repeater {
                    model: root.pages
                    Item {
                        id: nav
                        required property var modelData
                        required property int index
                        readonly property bool on: root.page === modelData.id
                        Layout.fillWidth: true
                        implicitHeight: 44

                        Rectangle {
                            anchors.fill: parent
                            radius: Tokens.rMd
                            color: nav.on ? Theme.stateActive : "transparent"
                            Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
                        }
                        Rectangle {
                            visible: nav.on
                            x: 0
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3
                            height: 18
                            radius: 1.5
                            color: Theme.accent
                        }
                        StateLayer {
                            anchors.fill: parent
                            radius: Tokens.rMd
                            onClicked: root.page = nav.modelData.id
                        }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 10
                            spacing: 12
                            Icon {
                                name: nav.modelData.icon
                                size: Tokens.iconMd
                                fill: nav.on ? 1 : 0
                                color: nav.on ? Theme.accent : Theme.textSub
                            }
                            Txt {
                                Layout.fillWidth: true
                                role: "body"
                                text: nav.modelData.label
                                font.weight: nav.on ? Font.DemiBold : Font.Medium
                                color: nav.on ? Theme.text : Theme.textSub
                            }
                            Txt {
                                role: "mono"
                                font.pixelSize: 10
                                text: "^" + (nav.index + 1)
                                color: Theme.textFaint
                                visible: nav.on
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // état du thème actif
                Pane {
                    Layout.fillWidth: true
                    implicitHeight: 64
                    level: 3
                    glass: false
                    radius: Tokens.rLg
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10
                        Row {
                            spacing: -6
                            Repeater {
                                model: [Theme.accent, Theme.accent2, Theme.signature]
                                Rectangle {
                                    required property color modelData
                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: modelData
                                    border.width: 2
                                    border.color: Theme.s3
                                }
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Txt { role: "label"; Layout.fillWidth: true; text: Themes.active.length ? (Themes.byId(Themes.active) ? Themes.byId(Themes.active).label : Themes.active) : (Theme.mode === "auto" ? "Material You" : "Palette " + Palettes.current) }
                            Txt { role: "caption"; Layout.fillWidth: true; text: "Identité " + Chrome.displayName }
                        }
                    }
                }
            }
        }

        // ---------------- contenu ----------------
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                id: head
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 22
                anchors.bottomMargin: 0
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Txt {
                        role: "hero"
                        text: root.pages.find(p => p.id === root.page).label
                    }
                    Txt {
                        role: "caption"
                        text: root.pages.find(p => p.id === root.page).desc
                    }
                }
                IconButton {
                    icon: "close"
                    tooltip: "Fermer (Échap)"
                    onClicked: PanelService.hide()
                }
            }

            Flickable {
                id: flick
                anchors.top: head.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.topMargin: 18
                anchors.leftMargin: 22
                anchors.rightMargin: 14
                anchors.bottomMargin: 6
                contentHeight: loader.implicitHeight + 24
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Loader {
                    id: loader
                    width: flick.width - 8
                    source: {
                        switch (root.page) {
                        case "themes": return "ThemesPage.qml";
                        case "wall": return "WallPage.qml";
                        case "bar": return "BarPage.qml";
                        case "dock": return "DockPage.qml";
                        case "desk": return "DeskPage.qml";
                        case "panels": return "PanelsPage.qml";
                        case "profiles": return "ProfilesPage.qml";
                        }
                        return "";
                    }
                    onLoaded: flick.contentY = 0
                    opacity: status === Loader.Ready ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Motion.dur(Motion.base) } }
                }
            }
        }
    }
}
