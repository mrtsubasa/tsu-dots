pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit

// Arsenal — navigateur de tes outils de sécurité (façon menu Kali/Parrot).
// Gauche : marque, recherche, collections et catégories. Droite : portée
// (installés / dépôts & AUR), liste des outils ; clic = détail (binaires,
// version, lancement terminal / aide / man / favori / copier). En portée
// « Dépôts & AUR », la recherche interroge pacman + paru et propose
// l'installation (toujours dans un terminal, jamais en silence).
FocusScope {
    id: root

    property real maxHeight: 760
    implicitWidth: 1060
    implicitHeight: Math.min(maxHeight, 720)

    property string view: "all"   // all | fav | recent | remote

    Component.onCompleted: {
        Arsenal.refresh();
        field.focusInput();
    }
    Keys.onEscapePressed: PanelService.hide()

    // id de catégorie → libellé (pastilles des lignes)
    readonly property var catLabel: {
        const m = {};
        for (let i = 0; i < Arsenal.categories.length; i++)
            m[Arsenal.categories[i].id] = Arsenal.categories[i].label;
        return m;
    }
    // teinte stable par nom (monogramme des lignes)
    readonly property var tones: [Theme.accent, Theme.accent2, Theme.signature, Theme.warning, Theme.success]
    function toneOf(name) {
        let h = 0;
        for (let i = 0; i < name.length; i++)
            h = (h * 31 + name.charCodeAt(i)) >>> 0;
        return tones[h % tones.length];
    }
    function setView(v, cat) {
        view = v;
        Arsenal.category = cat || "";
        Arsenal.includeAvailable = v === "remote";
        list.positionViewAtBeginning();
    }

    readonly property var shown: {
        if (view === "remote") {
            const have = {};
            for (let i = 0; i < Arsenal.tools.length; i++) have[Arsenal.tools[i].n] = true;
            const seen = {};
            return Arsenal.remote.filter(x => !have[x.n] && !seen[x.n] && (seen[x.n] = true))
                .map(x => ({ n: x.n, d: x.desc, c: [], gui: false, r: x.repo, avail: true, ver: x.ver }));
        }
        if (view === "fav")
            return Arsenal.tools.filter(t => Arsenal.favorites.indexOf(t.n) >= 0);
        if (view === "recent") {
            const map = {};
            for (let i = 0; i < Arsenal.tools.length; i++) map[Arsenal.tools[i].n] = Arsenal.tools[i];
            return Arsenal.recents.map(n => map[n]).filter(x => x);
        }
        return Arsenal.results;
    }
    readonly property string heading: view === "fav" ? "Favoris" : view === "recent" ? "Récents"
        : view === "remote" ? "Dépôts & AUR"
        : (Arsenal.category.length ? (root.catLabel[Arsenal.category] || Arsenal.category) : "Tous les outils")

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ---------- colonne gauche ----------
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 252
            color: Qt.alpha(Theme.s0, 0.45)
            radius: Tokens.rXl

            // arête droite
            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.topMargin: 18
                anchors.bottomMargin: 18
                width: 1
                color: Theme.border
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // marque
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 2
                    spacing: 10
                    Mark { size: 22 }
                    ColumnLayout {
                        spacing: -1
                        Text {
                            text: "ARSENAL"
                            color: Theme.text
                            font.family: Theme.displayFont
                            font.pixelSize: 17
                            font.weight: Font.Bold
                            font.letterSpacing: 2.4
                        }
                        Txt {
                            role: "overline"
                            text: Arsenal.ready ? Arsenal.total + " outils installés" : "chargement…"
                            color: Theme.accent
                        }
                    }
                }

                SearchField {
                    id: field
                    Layout.fillWidth: true
                    placeholder: root.view === "remote" ? "Chercher dans les dépôts…" : "Rechercher un outil…"
                    onTextChanged: Arsenal.query = text
                    input.Keys.onDownPressed: list.forceActiveFocus()
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentHeight: navCol.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: navCol
                        width: parent.width
                        spacing: 1

                        Txt { role: "overline"; text: "// collections"; color: Theme.textFaint; Layout.leftMargin: 6; Layout.bottomMargin: 2 }
                        ArsenalNavItem {
                            icon: "apps"; label: "Tous les outils"; count: String(Arsenal.total)
                            on: root.view === "all" && !Arsenal.category.length
                            onPicked: root.setView("all", "")
                        }
                        ArsenalNavItem {
                            icon: "star"; label: "Favoris"; count: String(Arsenal.favorites.length)
                            on: root.view === "fav"
                            onPicked: root.setView("fav", "")
                        }
                        ArsenalNavItem {
                            icon: "history"; label: "Récents"; count: String(Arsenal.recents.length)
                            on: root.view === "recent"
                            onPicked: root.setView("recent", "")
                        }
                        ArsenalNavItem {
                            icon: "cloud_download"; label: "Dépôts & AUR"; count: "+"
                            on: root.view === "remote"
                            onPicked: root.setView("remote", "")
                        }

                        Txt { role: "overline"; text: "// catégories"; color: Theme.textFaint; Layout.leftMargin: 6; Layout.topMargin: 10; Layout.bottomMargin: 2 }
                        Repeater {
                            model: Arsenal.categories
                            ArsenalNavItem {
                                required property var modelData
                                icon: modelData.icon
                                label: modelData.label
                                count: String(modelData.count)
                                on: root.view === "all" && Arsenal.category === modelData.id
                                onPicked: root.setView("all", modelData.id)
                            }
                        }
                    }
                }
            }
        }

        // ---------- colonne droite ----------
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 20
            spacing: 12

            // en-tête : titre, compteur, portée, actions
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Txt { role: "hero"; text: root.heading }
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: cntT.implicitWidth + 14
                    implicitHeight: 20
                    radius: 10
                    color: Qt.alpha(Theme.accent, 0.12)
                    Txt {
                        id: cntT
                        anchors.centerIn: parent
                        role: "mono"
                        font.pixelSize: 10
                        color: Theme.accent
                        text: root.shown.length + (root.view === "all" && !Arsenal.query.length && !Arsenal.category.length
                              ? " / " + Arsenal.resultCount : "")
                    }
                }
                Spinner { visible: Arsenal.searching; size: 16 }
                Item { Layout.fillWidth: true }
                Segmented {
                    compact: true
                    model: [
                        { id: "local", label: "Installés", icon: "inventory_2" },
                        { id: "remote", label: "Dépôts & AUR", icon: "cloud_download" }
                    ]
                    current: root.view === "remote" ? "remote" : "local"
                    onSelected: id => root.setView(id === "remote" ? "remote" : "all", "")
                }
                IconButton { icon: "refresh"; size: 30; iconSize: 16; tooltip: "Reconstruire le catalogue"; onClicked: Arsenal.refresh() }
                IconButton { icon: "close"; size: 30; iconSize: 17; tooltip: "Fermer"; onClicked: PanelService.hide() }
            }

            // bandeau explicatif de la portée dépôts
            Rectangle {
                Layout.fillWidth: true
                visible: root.view === "remote"
                implicitHeight: remoteRow.implicitHeight + 16
                radius: Tokens.rMd
                color: Qt.alpha(Theme.accent2, 0.08)
                border.width: 1
                border.color: Qt.alpha(Theme.accent2, 0.18)
                RowLayout {
                    id: remoteRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 12
                    spacing: 10
                    Icon { name: "info"; size: 16; color: Theme.accent2 }
                    Txt {
                        Layout.fillWidth: true
                        role: "caption"
                        wrapMode: Text.WordWrap
                        color: Theme.textSub
                        text: "Outils que tu n'as pas encore, cherchés dans les dépôts pacman (BlackArch, extra…) et l'AUR. "
                              + "« Installer » ouvre un terminal avec paru : rien ne s'installe sans ta confirmation."
                    }
                }
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 2
                model: root.shown
                boundsBehavior: Flickable.StopAtBounds
                cacheBuffer: 400

                delegate: Item {
                    id: toolRow
                    required property var modelData
                    required property int index
                    property bool expanded: false
                    readonly property bool avail: modelData.avail === true
                    readonly property color tone: root.toneOf(modelData.n)
                    width: list.width
                    implicitHeight: col.implicitHeight

                    ColumnLayout {
                        id: col
                        width: parent.width
                        spacing: 0

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 52
                            radius: Tokens.rMd
                            color: toolRow.expanded ? Qt.alpha(Theme.text, 0.05) : (rowHover.hovered ? Qt.alpha(Theme.text, 0.035) : "transparent")
                            Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
                            HoverHandler { id: rowHover }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 8
                                spacing: 12

                                // monogramme teinté (ou nuage pour un outil à installer)
                                Rectangle {
                                    Layout.preferredWidth: 34
                                    Layout.preferredHeight: 34
                                    radius: Tokens.rSm
                                    color: Qt.alpha(toolRow.tone, 0.12)
                                    border.width: 1
                                    border.color: Qt.alpha(toolRow.tone, rowHover.hovered || toolRow.expanded ? 0.4 : 0.16)
                                    Text {
                                        anchors.centerIn: parent
                                        visible: !toolRow.avail
                                        text: toolRow.modelData.n.replace(/[^a-z0-9]/gi, "").slice(0, 2).toUpperCase()
                                        color: toolRow.tone
                                        font.family: Theme.monoFont
                                        font.pixelSize: 12
                                        font.weight: Font.Bold
                                    }
                                    Icon {
                                        anchors.centerIn: parent
                                        visible: toolRow.avail
                                        name: "cloud_download"
                                        size: 17
                                        color: toolRow.tone
                                    }
                                    // marqueur « graphique »
                                    Rectangle {
                                        visible: toolRow.modelData.gui
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        anchors.margins: -3
                                        width: 14
                                        height: 14
                                        radius: 7
                                        color: Theme.s2
                                        Icon { anchors.centerIn: parent; name: "desktop_windows"; size: 9; color: Theme.accent2 }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    RowLayout {
                                        spacing: 6
                                        Text {
                                            text: toolRow.modelData.n
                                            color: Theme.text
                                            font.family: Theme.monoFont
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                        }
                                        Icon { visible: Arsenal.isFav(toolRow.modelData.n); name: "star"; size: 12; fill: 1; color: Theme.warning }
                                        Txt { visible: toolRow.avail && !!toolRow.modelData.ver; role: "mono"; font.pixelSize: 10; color: Theme.textFaint; text: toolRow.modelData.ver || "" }
                                    }
                                    Txt {
                                        Layout.fillWidth: true
                                        role: "caption"
                                        text: toolRow.modelData.d || toolRow.modelData.c.join(", ")
                                        elide: Text.ElideRight
                                    }
                                }

                                // pastilles : catégories (2 max) puis dépôt
                                Row {
                                    visible: !rowHover.hovered && !toolRow.expanded
                                    spacing: 4
                                    Repeater {
                                        model: toolRow.modelData.c.slice(0, 2)
                                        Rectangle {
                                            required property string modelData
                                            visible: !!root.catLabel[modelData]
                                            implicitWidth: catT.implicitWidth + 12
                                            implicitHeight: 18
                                            radius: 5
                                            color: Theme.s3
                                            Txt { id: catT; anchors.centerIn: parent; role: "caption"; font.pixelSize: 10; text: root.catLabel[parent.modelData] || ""; color: Theme.textSub }
                                        }
                                    }
                                    Rectangle {
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
                                        Txt { id: repoT; anchors.centerIn: parent; role: "mono"; font.pixelSize: 9; text: toolRow.modelData.r; color: parent.tone }
                                    }
                                }

                                // actions au survol
                                Button {
                                    visible: toolRow.avail
                                    variant: "primary"
                                    height_: 30
                                    icon: "download"
                                    text: "Installer"
                                    onClicked: Arsenal.install(toolRow.modelData.n)
                                }
                                IconButton {
                                    visible: (rowHover.hovered || toolRow.expanded) && !toolRow.avail
                                    icon: toolRow.modelData.gui ? "launch" : "terminal"
                                    variant: "tonal"
                                    size: 30; iconSize: 16
                                    tooltip: toolRow.modelData.gui ? "Lancer" : "Ouvrir dans un terminal"
                                    onClicked: toolRow.modelData.gui ? Arsenal.launchGui(toolRow.modelData.bin || toolRow.modelData.n)
                                                                     : Arsenal.runInTerminal(toolRow.modelData.bin || toolRow.modelData.n)
                                }
                                IconButton {
                                    visible: (rowHover.hovered || toolRow.expanded) && !toolRow.avail
                                    icon: "star"
                                    active: Arsenal.isFav(toolRow.modelData.n)
                                    size: 30; iconSize: 16
                                    tooltip: Arsenal.isFav(toolRow.modelData.n) ? "Retirer des favoris" : "Ajouter aux favoris"
                                    onClicked: Arsenal.toggleFav(toolRow.modelData.n)
                                }
                                Icon {
                                    visible: !toolRow.avail
                                    name: "expand_more"
                                    size: 18
                                    color: Theme.textFaint
                                    rotation: toolRow.expanded ? 180 : 0
                                    Behavior on rotation { NumberAnimation { duration: Motion.dur(Motion.base) } }
                                }
                            }
                            TapHandler {
                                onTapped: {
                                    if (toolRow.avail)
                                        return;
                                    toolRow.expanded = !toolRow.expanded;
                                    if (toolRow.expanded)
                                        Arsenal.loadDetail(toolRow.modelData.n);
                                }
                            }
                        }

                        // détail déroulant
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 56
                            Layout.rightMargin: 4
                            Layout.bottomMargin: toolRow.expanded ? 8 : 0
                            visible: toolRow.expanded
                            radius: Tokens.rMd
                            color: Theme.s2
                            border.width: 1
                            border.color: Theme.border
                            implicitHeight: toolRow.expanded ? detCol.implicitHeight + 24 : 0

                            // fil de teinte à gauche
                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.margins: 10
                                width: 2
                                radius: 1
                                color: Qt.alpha(toolRow.tone, 0.6)
                            }

                            ColumnLayout {
                                id: detCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.leftMargin: 22
                                anchors.rightMargin: 12
                                anchors.topMargin: 12
                                spacing: 10

                                readonly property var det: Arsenal.detailFor === toolRow.modelData.n ? Arsenal.detail : null

                                Txt {
                                    Layout.fillWidth: true
                                    role: "body"
                                    wrapMode: Text.WordWrap
                                    color: Theme.textSub
                                    text: (detCol.det && detCol.det.desc) ? detCol.det.desc : toolRow.modelData.d
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10
                                    visible: !!detCol.det
                                    Txt { role: "mono"; font.pixelSize: 10; color: Theme.textFaint; text: detCol.det && detCol.det.version ? "v" + detCol.det.version : "" }
                                    Txt { Layout.fillWidth: true; role: "mono"; font.pixelSize: 10; color: Theme.accent2; elide: Text.ElideRight; text: detCol.det && detCol.det.url ? detCol.det.url : "" }
                                }
                                Spinner { visible: !detCol.det; size: 14 }

                                // binaires exécutables
                                Txt {
                                    visible: detCol.det && detCol.det.bins && detCol.det.bins.length > 0
                                    role: "overline"; color: Theme.textFaint; text: "// exécutables"
                                }
                                Flow {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    visible: detCol.det && detCol.det.bins && detCol.det.bins.length > 0
                                    Repeater {
                                        model: detCol.det && detCol.det.bins ? detCol.det.bins : []
                                        Rectangle {
                                            id: binChip
                                            required property string modelData
                                            height: 28
                                            width: binRow.implicitWidth + 16
                                            radius: Tokens.rSm
                                            color: binHover.hovered ? Qt.alpha(toolRow.tone, 0.14) : Theme.s1
                                            border.width: 1
                                            border.color: binHover.hovered ? Qt.alpha(toolRow.tone, 0.4) : Theme.border
                                            HoverHandler { id: binHover; cursorShape: Qt.PointingHandCursor }
                                            RowLayout {
                                                id: binRow
                                                anchors.centerIn: parent
                                                spacing: 6
                                                Text { text: "$"; color: toolRow.tone; font.family: Theme.monoFont; font.pixelSize: 11; font.weight: Font.Bold }
                                                Txt { role: "mono"; font.pixelSize: 11; text: binChip.modelData }
                                            }
                                            TapHandler { onTapped: toolRow.modelData.gui ? Arsenal.launchGui(binChip.modelData) : Arsenal.runInTerminal(binChip.modelData) }
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
                                Item { implicitHeight: 2 }
                            }
                        }
                    }
                }

                EmptyState {
                    anchors.centerIn: parent
                    width: parent.width - 40
                    visible: list.count === 0 && !Arsenal.searching
                    icon: root.view === "remote" ? "travel_explore" : "search_off"
                    title: root.view === "fav" ? "Aucun favori"
                         : root.view === "recent" ? "Rien de récent"
                         : root.view === "remote" ? (Arsenal.query.trim().length < 2 ? "Tape le nom d'un outil" : "Rien à installer")
                         : "Aucun outil"
                    text: root.view === "fav" ? "Ajoute des outils en favori avec l'étoile."
                        : root.view === "remote"
                          ? (Arsenal.query.trim().length < 2
                             ? "Au moins 2 lettres dans la recherche à gauche : l'Arsenal cherche alors dans les dépôts et l'AUR ce que tu n'as pas encore."
                             : "Tout ce qui correspond à « " + Arsenal.query + " » est déjà installé (ou n'existe pas).")
                        : (Arsenal.query.length ? "Aucun outil pour « " + Arsenal.query + " »." : "")
                }
            }
        }
    }
}
