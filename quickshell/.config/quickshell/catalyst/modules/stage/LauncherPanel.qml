pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit
import "../../components"

// Launcher : champ unique, résultats au clavier (↑↓ / Tab, Entrée, Ctrl+1…9).
// Préfixes : = calcul · > terminal · : commandes Catalyst.
// Cinq styles (Studio → Profil & interface) : liste, compact, grille, plein écran, console.
FocusScope {
    id: root

    property real maxHeight: 640
    property real maxWidth: 1400
    readonly property string style: ["list", "compact", "grid", "full", "console"].indexOf(ShellCfg.launcherStyle) >= 0 ? ShellCfg.launcherStyle : "list"
    readonly property bool gridMode: style === "grid" || style === "full"
    readonly property bool compact: style === "compact"
    readonly property bool consoleMode: style === "console"
    readonly property int rowH: consoleMode ? 30 : (compact ? 40 : 52)
    readonly property string queryText: consoleMode ? consoleInput.text : field.text
    readonly property int visibleRows: Math.min(8, Search.results.length)
    readonly property int cols: style === "full" ? Math.max(4, Math.floor((width - 16) / 150)) : 6
    readonly property real resultsH: Search.results.length ? (gridMode ? grid.contentHeight : list.contentHeight) + 16 : empty.implicitHeight

    implicitWidth: style === "full" ? Math.min(maxWidth, 1180) : (style === "grid" ? 780 : (compact ? 560 : (consoleMode ? 640 : 660)))
    implicitHeight: style === "full" ? maxHeight : Math.min(maxHeight, header.height + resultsH + (compact ? 0 : footer.height + 1))

    Component.onCompleted: {
        Search.reset();
        focusQuery();
    }

    function focusQuery() {
        if (consoleMode)
            consoleInput.forceActiveFocus();
        else
            field.focusInput();
    }

    function clearQuery() {
        field.text = "";
        consoleInput.text = "";
    }

    // grille : haut / bas sautent d'une ligne, sans boucler
    function gridStep(d) {
        const n = Search.results.length;
        if (!n)
            return;
        Search.selected = Math.max(0, Math.min(n - 1, Search.selected + d));
    }

    function keyNav(event) {
        const ctrl = event.modifiers & Qt.ControlModifier;
        if (gridMode && (event.key === Qt.Key_Down || event.key === Qt.Key_Up || event.key === Qt.Key_Left || event.key === Qt.Key_Right)) {
            gridStep(event.key === Qt.Key_Down ? cols : (event.key === Qt.Key_Up ? -cols : (event.key === Qt.Key_Right ? 1 : -1)));
            event.accepted = true;
        } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier)) || (ctrl && event.key === Qt.Key_J)) {
            Search.move(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (ctrl && event.key === Qt.Key_K)) {
            Search.move(-1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            Search.activate();
            event.accepted = true;
        } else if (ctrl && event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
            Search.activate(event.key - Qt.Key_1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            if (Search.query.length) {
                root.clearQuery();
                event.accepted = true;
            } else {
                PanelService.hide();
                event.accepted = true;
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ---- champ ----
        Item {
            id: header
            Layout.fillWidth: true
            implicitHeight: root.consoleMode ? 64 : (root.compact ? 56 : 68)

            // ---- style console : barre de titre + invite ----
            Item {
                anchors.fill: parent
                visible: root.consoleMode

                Row {
                    x: 14
                    y: 9
                    spacing: 6
                    Repeater {
                        model: [Theme.error, Theme.warning, Theme.success]
                        Rectangle {
                            required property color modelData
                            width: 8
                            height: 8
                            radius: 4
                            color: Qt.alpha(modelData, 0.8)
                        }
                    }
                }
                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 6
                    role: "mono"
                    font.pixelSize: 10
                    text: ShellCfg.brand + " — launch"
                    color: Theme.textFaint
                }

                Row {
                    x: 16
                    y: 30
                    height: 24
                    spacing: 0
                    Txt { anchors.verticalCenter: parent.verticalCenter; role: "mono"; font.pixelSize: 15; font.weight: Font.DemiBold; text: Identity.userName.split(" ")[0].toLowerCase() + "@" + ShellCfg.brand; color: Theme.accent }
                    Txt { anchors.verticalCenter: parent.verticalCenter; role: "mono"; font.pixelSize: 15; text: " ~ "; color: Theme.textSub }
                    Txt {
                        anchors.verticalCenter: parent.verticalCenter
                        role: "mono"
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        text: Search.mode === "calc" ? "= " : (Search.mode === "shell" ? "$ " : (Search.mode === "cmd" ? ": " : "❯ "))
                        color: Theme.accent2
                    }
                    TextInput {
                        id: consoleInput
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.width - x - 40
                        color: Theme.text
                        selectionColor: Theme.selection
                        selectedTextColor: Theme.text
                        font.family: Theme.monoFont
                        font.pixelSize: 15
                        cursorVisible: false
                        cursorDelegate: Item {}
                        clip: true
                        onTextChanged: if (root.consoleMode) Search.setQuery(text)
                        Keys.onPressed: event => root.keyNav(event)

                        // curseur bloc clignotant
                        Rectangle {
                            x: consoleInput.cursorRectangle.x + 1
                            anchors.verticalCenter: parent.verticalCenter
                            width: 9
                            height: 17
                            color: Theme.accent
                            visible: consoleInput.activeFocus
                            SequentialAnimation on opacity {
                                running: consoleInput.activeFocus && !Motion.reduced
                                loops: Animation.Infinite
                                NumberAnimation { to: 0; duration: 0 }
                                PauseAnimation { duration: 530 }
                                NumberAnimation { to: 1; duration: 0 }
                                PauseAnimation { duration: 530 }
                            }
                        }
                        Txt {
                            anchors.verticalCenter: parent.verticalCenter
                            x: 14
                            visible: consoleInput.text.length === 0
                            role: "mono"
                            font.pixelSize: 15
                            text: "lancer…  = calc  > sh  : cmd"
                            color: Theme.textFaint
                        }
                    }
                }
            }

            SearchField {
                id: field
                visible: !root.consoleMode
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                large: !root.compact
                icon: Search.mode === "calc" ? "calculate" : (Search.mode === "shell" ? "terminal" : (Search.mode === "cmd" ? "bolt" : "search"))
                placeholder: "Rechercher une application, une commande…  ( =  >  : )"
                input.onTextChanged: if (!root.consoleMode) Search.setQuery(field.text)
                input.Keys.onPressed: event => root.keyNav(event)

                Rectangle {
                    visible: Search.mode !== "app"
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                    height: 22
                    width: modeTxt.implicitWidth + 16
                    radius: 11
                    color: Qt.alpha(Theme.accent, 0.14)
                    border.width: 1
                    border.color: Qt.alpha(Theme.accent, 0.4)
                    Txt {
                        id: modeTxt
                        anchors.centerIn: parent
                        role: "overline"
                        text: Search.mode === "calc" ? "calcul" : (Search.mode === "shell" ? "terminal" : "commandes")
                        color: Theme.accent
                    }
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Theme.divider
            }
        }

        // ---- résultats ----
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            visible: !root.gridMode && Search.results.length > 0
            clip: true
            model: root.gridMode ? [] : Search.results
            currentIndex: Search.selected
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: Motion.dur(Motion.fast)
            highlightFollowsCurrentItem: true
            spacing: 2
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            highlight: Rectangle {
                radius: root.consoleMode ? 3 : Tokens.rLg
                color: Qt.alpha(Theme.accent, root.consoleMode ? 0.16 : 0.10)
                border.width: 1
                border.color: Qt.alpha(Theme.accent, 0.32)
                Rectangle {
                    x: 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: 3
                    height: parent.height * 0.5
                    radius: 1.5
                    color: Theme.accent
                }
            }

            delegate: Item {
                id: row
                required property var modelData
                required property int index
                readonly property bool current: index === Search.selected
                width: list.width
                height: root.rowH

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: Search.selected = row.index
                    onClicked: Search.activate(row.index)
                }

                // ---- ligne façon terminal (style console) ----
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10
                    visible: root.consoleMode
                    Txt { role: "mono"; font.pixelSize: 12; text: "[" + String(row.index + 1).padStart(2, "0") + "]"; color: row.current ? Theme.accent : Theme.textFaint }
                    Txt { role: "mono"; font.pixelSize: 13; text: row.current ? "▸" : " "; color: Theme.accent }
                    Txt {
                        Layout.fillWidth: true
                        role: "mono"
                        font.pixelSize: 13
                        font.weight: row.current ? Font.DemiBold : Font.Normal
                        text: row.modelData.title + (row.current && row.modelData.subtitle ? "  — " + row.modelData.subtitle : "")
                        color: row.current ? Theme.text : Theme.textSub
                        elide: Text.ElideRight
                    }
                    Txt {
                        role: "mono"
                        font.pixelSize: 11
                        text: row.modelData.kind === "app" ? (row.modelData.terminal ? "tty" : "app") : (row.modelData.kind === "cmd" ? "cmd" : (row.modelData.kind || ""))
                        color: row.current ? Theme.accent : Theme.textFaint
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: root.compact ? 12 : 14
                    visible: !root.consoleMode

                    Item {
                        Layout.preferredWidth: root.compact ? 24 : 32
                        Layout.preferredHeight: root.compact ? 24 : 32

                        AppIcon {
                            visible: row.modelData.kind === "app"
                            anchors.centerIn: parent
                            appId: row.modelData.kind === "app" ? (row.modelData.appId || "") : ""
                            iconName: row.modelData.kind === "app" ? (row.modelData.icon || "") : ""
                            label: row.modelData.title
                            size: root.compact ? 22 : 30
                        }
                        Rectangle {
                            visible: row.modelData.kind !== "app"
                            anchors.fill: parent
                            radius: Tokens.rMd
                            color: row.current ? Theme.accent : Qt.alpha(Theme.text, 0.06)
                            border.width: row.current ? 0 : 1
                            border.color: Theme.border
                            Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
                            Icon {
                                anchors.centerIn: parent
                                name: row.modelData.icon || "bolt"
                                size: root.compact ? 14 : 18
                                fill: row.current ? 1 : 0
                                color: row.current ? Theme.onAccent : Theme.text
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Txt {
                            Layout.fillWidth: true
                            role: row.modelData.kind === "calc" ? "hero" : "body"
                            text: row.modelData.title
                            font.weight: row.current ? Font.DemiBold : Font.Medium
                            font.pixelSize: row.modelData.kind === "calc" ? 20 : Tokens.fBody + 1
                        }
                        Txt {
                            Layout.fillWidth: true
                            visible: !root.compact && text.length > 0
                            role: "caption"
                            text: row.modelData.subtitle || ""
                        }
                    }

                    Rectangle {
                        readonly property string tag: row.modelData.kind === "app" ? (row.modelData.terminal ? "tty" : "") : (row.modelData.kind === "project" ? "projet" : (row.modelData.kind === "ssh" ? "ssh" : (row.modelData.kind === "cmd" ? ShellCfg.brand : "")))
                        visible: tag.length > 0
                        Layout.preferredHeight: 20
                        Layout.preferredWidth: tagTxt.implicitWidth + 14
                        radius: 10
                        color: row.current ? Qt.alpha(Theme.accent, 0.14) : Qt.alpha(Theme.text, 0.04)
                        border.width: 1
                        border.color: row.current ? Qt.alpha(Theme.accent, 0.4) : Theme.border
                        Txt { id: tagTxt; anchors.centerIn: parent; role: "overline"; font.pixelSize: 9; text: parent.tag; color: row.current ? Theme.accent : Theme.textFaint }
                    }
                    Kbd {
                        visible: row.current || row.index < 9
                        text: row.current ? "↵" : "^" + (row.index + 1)
                        lit: row.current
                        opacity: row.current ? 1 : 0.55
                    }
                }
            }
        }

        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            visible: root.gridMode && Search.results.length > 0
            clip: true
            model: root.gridMode ? Search.results : []
            currentIndex: Search.selected
            cellWidth: Math.floor(width / root.cols)
            cellHeight: root.style === "full" ? 132 : 116
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: Motion.dur(Motion.fast)
            highlightFollowsCurrentItem: true
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)

            highlight: Item {
                width: grid.cellWidth
                height: grid.cellHeight
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 3
                    radius: Tokens.rLg
                    color: Qt.alpha(Theme.accent, 0.10)
                    border.width: 1
                    border.color: Qt.alpha(Theme.accent, 0.32)
                }
            }

            delegate: Item {
                id: tile
                required property var modelData
                required property int index
                readonly property bool current: index === Search.selected
                readonly property int iconSize: root.style === "full" ? 52 : 44
                width: grid.cellWidth
                height: grid.cellHeight

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: Search.selected = tile.index
                    onClicked: Search.activate(tile.index)
                }

                Item {
                    id: tileIcon
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 16
                    width: tile.iconSize
                    height: tile.iconSize
                    scale: tile.current ? 1.08 : 1
                    Behavior on scale { NumberAnimation { duration: Motion.dur(Motion.fast); easing.type: Easing.OutCubic } }

                    AppIcon {
                        visible: tile.modelData.kind === "app"
                        anchors.centerIn: parent
                        appId: tile.modelData.kind === "app" ? (tile.modelData.appId || "") : ""
                        iconName: tile.modelData.kind === "app" ? (tile.modelData.icon || "") : ""
                        label: tile.modelData.title
                        size: tile.iconSize
                    }
                    Rectangle {
                        visible: tile.modelData.kind !== "app"
                        anchors.fill: parent
                        radius: Tokens.rLg
                        color: tile.current ? Theme.accent : Qt.alpha(Theme.text, 0.06)
                        border.width: tile.current ? 0 : 1
                        border.color: Theme.border
                        Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
                        Icon {
                            anchors.centerIn: parent
                            name: tile.modelData.icon || "bolt"
                            size: Math.round(tile.iconSize * 0.45)
                            fill: tile.current ? 1 : 0
                            color: tile.current ? Theme.onAccent : Theme.text
                        }
                    }
                }

                Txt {
                    anchors.top: tileIcon.bottom
                    anchors.topMargin: 10
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    role: "body"
                    text: tile.modelData.title
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    font.pixelSize: Tokens.fBody - 1
                    font.weight: tile.current ? Font.DemiBold : Font.Medium
                    color: tile.current ? Theme.text : Theme.textSub
                }

                Kbd {
                    visible: tile.current || tile.index < 9
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 8
                    text: tile.current ? "↵" : "^" + (tile.index + 1)
                    lit: tile.current
                    opacity: tile.current ? 1 : 0.45
                }
            }
        }

        EmptyState {
            id: empty
            Layout.fillWidth: true
            visible: Search.results.length === 0
            icon: "search_off"
            title: Search.query.length ? "Aucun résultat pour « " + Search.query + " »" : ""
            text: "Astuce : = pour calculer, > pour une commande, : pour les commandes " + ShellCfg.brand + "."
        }

        // ---- pied ----
        Rectangle {
            Layout.fillWidth: true
            visible: !root.compact
            implicitHeight: 1
            color: Theme.divider
        }
        Item {
            id: footer
            Layout.fillWidth: true
            visible: !root.compact
            implicitHeight: 34

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 16
                Mark { size: 13; visible: !root.consoleMode }
                Txt { role: "mono"; font.pixelSize: 10; text: (root.consoleMode ? "-- " : "") + Search.results.length + " résultat" + (Search.results.length > 1 ? "s" : "") + (root.consoleMode ? " --" : ""); color: Theme.textFaint }
                Item { Layout.fillWidth: true }
                Txt { visible: root.consoleMode; role: "mono"; font.pixelSize: 10; text: "[↑↓] nav  [↵] run  [^1-9] go  [esc] quit"; color: Theme.textFaint }
                KeyHints {
                    visible: !root.consoleMode
                    hints: [{ keys: ["="], text: "calcul" }, { keys: [">"], text: "terminal" }, { keys: [":"], text: "commandes" }, { keys: ["↑", "↓"], text: "naviguer" }, { keys: ["Échap"], text: "fermer" }]
                }
            }
        }
    }
}
