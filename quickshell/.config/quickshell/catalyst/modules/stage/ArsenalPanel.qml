pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit

// Arsenal — navigateur de tes outils de sécurité (façon menu Kali/Parrot).
// Gauche : recherche + catégories. Droite : liste des outils ; clic = détail
// (binaires, version, lancement terminal / aide / man / favori / copier).
FocusScope {
    id: root

    property real maxHeight: 760
    implicitWidth: 1040
    implicitHeight: Math.min(maxHeight, 720)

    Component.onCompleted: {
        Arsenal.refresh();
        field.focusInput();
    }
    Keys.onEscapePressed: PanelService.hide()

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ---------- colonne gauche : catégories ----------
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 248
            color: Qt.alpha(Theme.s0, 0.35)
            radius: Tokens.rXl

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Mark { size: 20 }
                    ColumnLayout {
                        spacing: 0
                        Txt { role: "title"; text: "Arsenal" }
                        Txt { role: "overline"; text: Arsenal.total + " outils"; color: Theme.accent }
                    }
                }

                SearchField {
                    id: field
                    Layout.fillWidth: true
                    placeholder: "Rechercher un outil…"
                    onTextChanged: Arsenal.query = text
                    input.Keys.onDownPressed: list.forceActiveFocus()
                }

                ListView {
                    id: cats
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 1
                    model: [{ id: "", label: "Tous les outils", icon: "apps", count: Arsenal.total },
                            { id: "__fav", label: "Favoris", icon: "star", count: Arsenal.favorites.length },
                            { id: "__recent", label: "Récents", icon: "history", count: Arsenal.recents.length }].concat(Arsenal.categories)

                    delegate: Item {
                        id: cat
                        required property var modelData
                        readonly property bool on: Arsenal.category === modelData.id
                                                   || (modelData.id === "__fav" && root.view === "fav")
                                                   || (modelData.id === "__recent" && root.view === "recent")
                        width: cats.width
                        height: 34
                        Rectangle {
                            anchors.fill: parent
                            radius: Tokens.rSm
                            color: cat.on ? Theme.stateActive : (hov.hovered ? Theme.stateHover : "transparent")
                        }
                        HoverHandler { id: hov }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10
                            Icon { name: cat.modelData.icon; size: 17; fill: cat.on ? 1 : 0; color: cat.on ? Theme.accent : Theme.textSub }
                            Txt { Layout.fillWidth: true; role: "label"; text: cat.modelData.label; color: cat.on ? Theme.text : Theme.textSub }
                            Txt { role: "mono"; font.pixelSize: 10; text: cat.modelData.count; color: Theme.textFaint }
                        }
                        TapHandler {
                            onTapped: {
                                if (cat.modelData.id === "__fav") { root.view = "fav"; Arsenal.category = ""; }
                                else if (cat.modelData.id === "__recent") { root.view = "recent"; Arsenal.category = ""; }
                                else { root.view = "all"; Arsenal.category = cat.modelData.id; }
                            }
                        }
                    }
                }
            }
        }

        // ---------- colonne droite : outils ----------
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            property var shown: {
                if (root.view === "fav")
                    return Arsenal.tools.filter(t => Arsenal.favorites.indexOf(t.n) >= 0);
                if (root.view === "recent") {
                    const map = {};
                    for (let i = 0; i < Arsenal.tools.length; i++) map[Arsenal.tools[i].n] = Arsenal.tools[i];
                    return Arsenal.recents.map(n => map[n]).filter(x => x);
                }
                const local = Arsenal.results;
                // outils disponibles (non installés) depuis dépôts + AUR
                if (Arsenal.includeAvailable && Arsenal.remote.length) {
                    const have = {};
                    for (let i = 0; i < Arsenal.tools.length; i++) have[Arsenal.tools[i].n] = true;
                    const avail = Arsenal.remote
                        .filter(x => !have[x.n])
                        .map(x => ({ n: x.n, d: x.desc, c: [x.repo], gui: false, r: x.repo, avail: true, ver: x.ver }));
                    return local.concat(avail);
                }
                return local;
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    Txt {
                        Layout.fillWidth: true
                        role: "hero"
                        text: root.view === "fav" ? "Favoris" : root.view === "recent" ? "Récents"
                              : (Arsenal.category.length ? (Arsenal.categories.find(c => c.id === Arsenal.category) || {}).label : "Tous les outils")
                    }
                    Txt { role: "caption"; text: parent.parent.parent.shown.length + (root.view === "all" && !Arsenal.query.length && !Arsenal.category.length ? " / " + Arsenal.resultCount + " affichés" : "") + " outils" }
                    Spinner { visible: Arsenal.searching; size: 16 }
                    Button {
                        variant: Arsenal.includeAvailable ? "primary" : "secondary"
                        height_: 30
                        icon: "cloud_download"
                        text: "Non installés"
                        onClicked: Arsenal.includeAvailable = !Arsenal.includeAvailable
                    }
                    IconButton { icon: "refresh"; size: 30; iconSize: 16; tooltip: "Reconstruire le catalogue"; onClicked: Arsenal.refresh() }
                    IconButton { icon: "close"; size: 30; iconSize: 17; tooltip: "Fermer"; onClicked: PanelService.hide() }
                }

                Txt {
                    Layout.fillWidth: true
                    visible: Arsenal.includeAvailable && Arsenal.query.length < 2
                    role: "caption"
                    color: Theme.textFaint
                    text: "Tape au moins 2 lettres pour chercher dans les dépôts et l'AUR les outils que tu n'as pas encore."
                }

                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 2
                    model: parent.parent.shown
                    boundsBehavior: Flickable.StopAtBounds
                    cacheBuffer: 400

                    delegate: Item {
                        id: toolRow
                        required property var modelData
                        required property int index
                        readonly property bool open: Arsenal.detailFor === modelData.n && expanded
                        property bool expanded: false
                        width: list.width
                        implicitHeight: col.implicitHeight

                        ColumnLayout {
                            id: col
                            width: parent.width
                            spacing: 0

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 48
                                radius: Tokens.rMd
                                color: toolRow.expanded ? Theme.stateHover : (rowHover.hovered ? Qt.alpha(Theme.text, 0.035) : "transparent")
                                HoverHandler { id: rowHover }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 8
                                    spacing: 12

                                    Rectangle {
                                        Layout.preferredWidth: 32; Layout.preferredHeight: 32
                                        radius: Tokens.rSm
                                        color: Theme.s3
                                        Icon { anchors.centerIn: parent; name: toolRow.modelData.avail ? "cloud_download" : (toolRow.modelData.gui ? "desktop_windows" : "terminal"); size: 17; color: toolRow.modelData.avail ? Theme.accent : (toolRow.modelData.gui ? Theme.accent2 : Theme.textSub) }
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        RowLayout {
                                            spacing: 6
                                            Txt { role: "body"; text: toolRow.modelData.n; font.weight: Font.DemiBold }
                                            Icon { visible: Arsenal.isFav(toolRow.modelData.n); name: "star"; size: 12; fill: 1; color: Theme.warning }
                                        }
                                        Txt { Layout.fillWidth: true; role: "caption"; text: toolRow.modelData.d || toolRow.modelData.c.join(", "); elide: Text.ElideRight }
                                    }
                                    Rectangle {
                                        visible: !rowHover.hovered && !toolRow.expanded
                                        implicitWidth: repoT.implicitWidth + 12
                                        implicitHeight: 18
                                        radius: 5
                                        readonly property color tone: {
                                            const r = toolRow.modelData.r;
                                            if (r === "blackarch") return Theme.signature;
                                            if (r === "aur") return Theme.warning;
                                            if (r === "chaotic") return Theme.accent2;
                                            if (r === "cachyos") return Theme.accent;
                                            return Theme.textSub;
                                        }
                                        color: Qt.alpha(tone, 0.14)
                                        Txt {
                                            id: repoT
                                            anchors.centerIn: parent
                                            role: "mono"; font.pixelSize: 9
                                            text: toolRow.modelData.r
                                            color: parent.tone
                                        }
                                    }
                                    Button {
                                        visible: toolRow.modelData.avail === true
                                        variant: "primary"
                                        height_: 30
                                        icon: "download"
                                        text: "Installer"
                                        onClicked: Arsenal.install(toolRow.modelData.n)
                                    }
                                    IconButton {
                                        visible: (rowHover.hovered || toolRow.expanded) && !toolRow.modelData.avail
                                        icon: Arsenal.isFav(toolRow.modelData.n) ? "star" : "star_outline"
                                        size: 30; iconSize: 17
                                        tooltip: "Favori"
                                        onClicked: Arsenal.toggleFav(toolRow.modelData.n)
                                    }
                                    IconButton {
                                        visible: (rowHover.hovered || toolRow.expanded) && !toolRow.modelData.avail
                                        icon: toolRow.expanded ? "expand_less" : "expand_more"
                                        size: 30; iconSize: 18
                                        tooltip: "Détails"
                                        onClicked: {
                                            toolRow.expanded = !toolRow.expanded;
                                            if (toolRow.expanded)
                                                Arsenal.loadDetail(toolRow.modelData.n);
                                        }
                                    }
                                }
                                TapHandler {
                                    onTapped: {
                                        if (toolRow.modelData.avail) {
                                            Arsenal.install(toolRow.modelData.n);
                                            return;
                                        }
                                        toolRow.expanded = !toolRow.expanded;
                                        if (toolRow.expanded)
                                            Arsenal.loadDetail(toolRow.modelData.n);
                                    }
                                }
                            }

                            // détail déroulant
                            Pane {
                                Layout.fillWidth: true
                                Layout.leftMargin: 44
                                Layout.rightMargin: 4
                                Layout.bottomMargin: toolRow.expanded ? 6 : 0
                                visible: toolRow.expanded
                                level: 3
                                glass: false
                                radius: Tokens.rMd
                                implicitHeight: toolRow.expanded ? detCol.implicitHeight + 20 : 0

                                ColumnLayout {
                                    id: detCol
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 10
                                    spacing: 8

                                    readonly property var det: Arsenal.detailFor === toolRow.modelData.n ? Arsenal.detail : null

                                    Txt {
                                        Layout.fillWidth: true
                                        role: "caption"
                                        wrapMode: Text.WordWrap
                                        text: (detCol.det && detCol.det.desc) ? detCol.det.desc : toolRow.modelData.d
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        Txt { role: "mono"; font.pixelSize: 10; color: Theme.textFaint; text: detCol.det && detCol.det.version ? "v" + detCol.det.version : "" }
                                        Txt { Layout.fillWidth: true; role: "mono"; font.pixelSize: 10; color: Theme.accent2; elide: Text.ElideRight; text: detCol.det && detCol.det.url ? detCol.det.url : "" }
                                    }

                                    // binaires exécutables
                                    Flow {
                                        Layout.fillWidth: true
                                        spacing: 6
                                        visible: detCol.det && detCol.det.bins && detCol.det.bins.length > 0
                                        Repeater {
                                            model: detCol.det && detCol.det.bins ? detCol.det.bins : []
                                            Rectangle {
                                                required property string modelData
                                                height: 30
                                                width: binRow.implicitWidth + 16
                                                radius: Tokens.rSm
                                                color: Theme.s2
                                                border.width: 1
                                                border.color: Theme.border
                                                RowLayout {
                                                    id: binRow
                                                    anchors.centerIn: parent
                                                    spacing: 6
                                                    Icon { name: "chevron_right"; size: 14; color: Theme.accent }
                                                    Txt { role: "mono"; font.pixelSize: 11; text: modelData }
                                                }
                                                TapHandler { onTapped: toolRow.modelData.gui ? Arsenal.launchGui(modelData) : Arsenal.runInTerminal(modelData) }
                                            }
                                        }
                                    }
                                    Txt {
                                        visible: detCol.det && (!detCol.det.bins || detCol.det.bins.length === 0)
                                        role: "caption"; color: Theme.textFaint
                                        text: "Pas d'exécutable direct (bibliothèque, données ou greffon)."
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6
                                        readonly property string bin0: detCol.det && detCol.det.bins && detCol.det.bins.length ? detCol.det.bins[0] : toolRow.modelData.n
                                        Button { variant: "primary"; height_: 28; icon: "terminal"; text: "Terminal"; visible: !toolRow.modelData.gui; onClicked: Arsenal.runInTerminal(parent.bin0) }
                                        Button { variant: "primary"; height_: 28; icon: "launch"; text: "Lancer"; visible: toolRow.modelData.gui; onClicked: Arsenal.launchGui(parent.bin0) }
                                        Button { variant: "secondary"; height_: 28; icon: "help"; text: "Aide"; onClicked: Arsenal.help(parent.bin0) }
                                        Button { variant: "ghost"; height_: 28; icon: "menu_book"; text: "man"; onClicked: Arsenal.manpage(parent.bin0) }
                                        Item { Layout.fillWidth: true }
                                        Button { variant: "ghost"; height_: 28; icon: "content_copy"; text: "Copier"; onClicked: Arsenal.copyName(parent.bin0) }
                                    }
                                }
                            }
                        }
                    }

                    EmptyState {
                        anchors.centerIn: parent
                        width: parent.width - 40
                        visible: list.count === 0
                        icon: "search_off"
                        title: root.view === "fav" ? "Aucun favori" : root.view === "recent" ? "Rien de récent" : "Aucun outil"
                        text: root.view === "fav" ? "Ajoute des outils en favori avec l'étoile."
                              : (Arsenal.query.length ? "Aucun outil pour « " + Arsenal.query + " »." : "")
                    }
                }
            }
        }
    }

    property string view: "all"   // all | fav | recent
}
