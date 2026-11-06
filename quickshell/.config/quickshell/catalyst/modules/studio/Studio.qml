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
        { id: "profiles", label: "Profils", icon: "bookmarks", desc: "Sauvegarder et restaurer" },
        { id: "sekaipop", label: "SekaiPop", icon: "tune", desc: "Petite barre, OSD, service" }
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
        } else if ((event.modifiers & Qt.ControlModifier) && event.key >= Qt.Key_1 && event.key <= Qt.Key_8) {
            root.page = root.pages[event.key - Qt.Key_1].id;
            event.accepted = true;
        }
    }

    readonly property var current: pages.find(p => p.id === page) || pages[0]
    readonly property int currentIndex: pages.indexOf(current)
    readonly property var groups: [
        { label: "Apparence", ids: ["themes", "wall"] },
        { label: "Espace de travail", ids: ["bar", "dock", "desk"] },
        { label: "Système", ids: ["panels", "profiles", "sekaipop"] }
    ]
    readonly property string themeLabel: Themes.active.length ? (Themes.byId(Themes.active) ? Themes.byId(Themes.active).label : Themes.active) : (Theme.mode === "auto" ? "Material You" : "Palette " + Palettes.current)

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ---------------- navigation ----------------
        Item {
            Layout.fillHeight: true
            Layout.preferredWidth: 236

            Rectangle {
                anchors.fill: parent
                radius: Tokens.rXl
                color: Qt.alpha(Theme.s0, 0.42)
                // coins droits côté contenu
                Rectangle {
                    anchors.right: parent.right
                    width: parent.radius
                    height: parent.height
                    color: parent.color
                }
            }
            // séparation : filet vertical qui s'éteint aux extrémités
            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: parent.height * 0.86
                gradient: Gradient {
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 0.5; color: Theme.borderStrong }
                    GradientStop { position: 1; color: "transparent" }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                anchors.topMargin: 18
                spacing: 2

                // marque
                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 18
                    spacing: 11
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: Tokens.rMd
                        color: Qt.alpha(Theme.accent, 0.12)
                        border.width: 1
                        border.color: Qt.alpha(Theme.accent, 0.28)
                        Mark { anchors.centerIn: parent; size: 20; lit: 1 }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Txt { role: "title"; text: "Studio" }
                        Txt { role: "overline"; text: ShellCfg.brand; color: Theme.accent }
                    }
                }

                Repeater {
                    model: root.groups
                    ColumnLayout {
                        id: grp
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.topMargin: index > 0 ? 12 : 0
                        spacing: 2

                        Txt {
                            Layout.leftMargin: 8
                            Layout.bottomMargin: 4
                            role: "overline"
                            text: grp.modelData.label
                            color: Theme.textFaint
                        }
                        Repeater {
                            model: grp.modelData.ids
                            StudioNavItem {
                                required property string modelData
                                readonly property var pg: root.pages.find(p => p.id === modelData)
                                Layout.fillWidth: true
                                icon: pg.icon
                                label: pg.label
                                shortcut: "^" + (root.pages.indexOf(pg) + 1)
                                on: root.page === modelData
                                onClicked: root.page = modelData
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // thème actif : bandeau de couleurs, clic = page Thèmes
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 70

                    Rectangle {
                        anchors.fill: parent
                        radius: Tokens.rLg
                        color: Theme.s2
                        border.width: 1
                        border.color: themeTap.containsMouse ? Qt.alpha(Theme.accent, 0.35) : Theme.border
                        clip: true
                        Behavior on border.color { ColorAnimation { duration: Motion.dur(Motion.fast) } }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            height: 2
                            radius: 1
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: Theme.accent }
                                GradientStop { position: 0.55; color: Theme.accent2 }
                                GradientStop { position: 1; color: Theme.signature }
                            }
                        }
                    }
                    StateLayer {
                        id: themeTap
                        anchors.fill: parent
                        radius: Tokens.rLg
                        hoverAlpha: 0.03
                        onClicked: root.page = "themes"
                    }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 10
                        anchors.topMargin: 3
                        spacing: 10
                        Row {
                            spacing: -6
                            Repeater {
                                model: [Theme.accent, Theme.accent2, Theme.signature]
                                Rectangle {
                                    required property color modelData
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: modelData
                                    border.width: 2
                                    border.color: Theme.s2
                                }
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Txt { role: "overline"; text: "Thème actif"; color: Theme.textFaint; font.pixelSize: 9 }
                            Txt { role: "label"; strong: true; Layout.fillWidth: true; text: root.themeLabel }
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
                anchors.leftMargin: 26
                anchors.rightMargin: 18
                anchors.topMargin: 20
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    RowLayout {
                        spacing: 6
                        Txt { role: "overline"; text: "Studio"; color: Theme.textFaint }
                        Txt { role: "overline"; text: "/"; color: Theme.accent }
                        Txt { role: "overline"; text: root.groups.find(g => g.ids.indexOf(root.page) >= 0).label; color: Theme.textFaint }
                        Txt { role: "overline"; text: "/"; color: Theme.accent }
                        Txt { role: "overline"; text: String(root.currentIndex + 1).padStart(2, "0"); color: Theme.accent }
                    }
                    Txt {
                        role: "hero"
                        text: root.current.label
                    }
                    Txt {
                        role: "caption"
                        text: root.current.desc
                    }
                }
                Rectangle {
                    Layout.alignment: Qt.AlignTop
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    radius: 17
                    color: closeTap.containsMouse ? Qt.alpha(Theme.error, 0.16) : Qt.alpha(Theme.text, 0.05)
                    border.width: 1
                    border.color: closeTap.containsMouse ? Qt.alpha(Theme.error, 0.4) : Theme.border
                    Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
                    Icon {
                        anchors.centerIn: parent
                        name: "close"
                        size: 17
                        color: closeTap.containsMouse ? Theme.error : Theme.textSub
                    }
                    StateLayer {
                        id: closeTap
                        anchors.fill: parent
                        radius: 17
                        hoverAlpha: 0
                        onClicked: PanelService.hide()
                    }
                    Tip { target: closeTap; text: "Fermer (Échap)"; active: closeTap.containsMouse }
                }
            }

            // filet d'accent sous l'en-tête
            Rectangle {
                id: rule
                anchors.top: head.bottom
                anchors.topMargin: 14
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 26
                anchors.rightMargin: 18
                height: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Qt.alpha(Theme.accent, 0.55) }
                    GradientStop { position: 0.25; color: Theme.border }
                    GradientStop { position: 1; color: "transparent" }
                }
            }

            Flickable {
                id: flick
                anchors.top: rule.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 26
                anchors.rightMargin: 14
                anchors.bottomMargin: 6
                contentHeight: loader.implicitHeight + 40
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Loader {
                    id: loader
                    y: 18
                    width: flick.width - 12
                    source: {
                        switch (root.page) {
                        case "themes": return "ThemesPage.qml";
                        case "wall": return "WallPage.qml";
                        case "bar": return "BarPage.qml";
                        case "dock": return "DockPage.qml";
                        case "desk": return "DeskPage.qml";
                        case "panels": return "PanelsPage.qml";
                        case "profiles": return "ProfilesPage.qml";
                        case "sekaipop": return "SekaiPopPage.qml";
                        }
                        return "";
                    }
                    onLoaded: flick.contentY = 0
                    opacity: status === Loader.Ready ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Motion.dur(Motion.base) } }
                }
            }

            // barre de défilement fine
            Rectangle {
                visible: flick.contentHeight > flick.height
                anchors.right: parent.right
                anchors.rightMargin: 6
                y: flick.y + 8 + (flick.height - 16 - height) * (flick.contentY / Math.max(1, flick.contentHeight - flick.height))
                width: 3
                height: Math.max(36, (flick.height - 16) * flick.height / flick.contentHeight)
                radius: 1.5
                color: Qt.alpha(Theme.text, flick.moving ? 0.28 : 0.12)
                Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
            }
        }
    }

    // ---------------- éditeur de cadrage (overlay) ----------------
    Loader {
        anchors.fill: parent
        z: 1000
        active: Walls.framing
        sourceComponent: WallFramer {}
    }
}
