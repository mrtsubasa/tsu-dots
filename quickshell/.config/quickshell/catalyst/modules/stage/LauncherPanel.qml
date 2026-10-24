pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit
import "../../components"

// Launcher : champ unique, résultats au clavier (↑↓ / Tab, Entrée, Ctrl+1…9).
// Préfixes : = calcul · > terminal · : commandes Catalyst.
FocusScope {
    id: root

    property real maxHeight: 640
    readonly property int rowH: 52
    readonly property int visibleRows: Math.min(8, Search.results.length)

    implicitWidth: 660
    implicitHeight: Math.min(maxHeight, header.height + (Search.results.length ? list.contentHeight + 16 : empty.implicitHeight) + footer.height + 1)

    Component.onCompleted: {
        Search.reset();
        field.focusInput();
    }

    function keyNav(event) {
        const ctrl = event.modifiers & Qt.ControlModifier;
        if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier)) || (ctrl && event.key === Qt.Key_J)) {
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
                field.text = "";
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
            implicitHeight: 68

            SearchField {
                id: field
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                large: true
                icon: Search.mode === "calc" ? "calculate" : (Search.mode === "shell" ? "terminal" : (Search.mode === "cmd" ? "bolt" : "search"))
                placeholder: "Rechercher une application, une commande…  ( =  >  : )"
                input.onTextChanged: Search.setQuery(field.text)
                input.Keys.onPressed: event => root.keyNav(event)

                Txt {
                    visible: Search.mode !== "app"
                    role: "overline"
                    text: Search.mode === "calc" ? "calcul" : (Search.mode === "shell" ? "terminal" : "commandes")
                    color: Theme.accent
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
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
            visible: Search.results.length > 0
            clip: true
            model: Search.results
            currentIndex: Search.selected
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: Motion.dur(Motion.fast)
            highlightFollowsCurrentItem: true
            spacing: 2
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            highlight: Rectangle {
                radius: Tokens.rMd
                color: Theme.stateActive
                border.width: 1
                border.color: Qt.alpha(Theme.accent, 0.35)
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

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 14

                    Item {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32

                        AppIcon {
                            visible: row.modelData.kind === "app"
                            anchors.centerIn: parent
                            appId: row.modelData.kind === "app" ? (row.modelData.appId || "") : ""
                            iconName: row.modelData.kind === "app" ? (row.modelData.icon || "") : ""
                            label: row.modelData.title
                            size: 30
                        }
                        Rectangle {
                            visible: row.modelData.kind !== "app"
                            anchors.fill: parent
                            radius: Tokens.rMd
                            color: row.current ? Theme.accent : Theme.s4
                            Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
                            Icon {
                                anchors.centerIn: parent
                                name: row.modelData.icon || "bolt"
                                size: 18
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
                            visible: text.length > 0
                            role: "caption"
                            text: row.modelData.subtitle || ""
                        }
                    }

                    Txt {
                        visible: row.modelData.kind === "app" && row.modelData.terminal
                        role: "overline"
                        text: "tty"
                        color: Theme.textFaint
                    }
                    Txt {
                        visible: ["cmd", "project", "ssh"].indexOf(row.modelData.kind) >= 0
                        role: "overline"
                        text: row.modelData.kind === "project" ? "projet" : (row.modelData.kind === "ssh" ? "ssh" : ShellCfg.brand)
                        color: row.current ? Theme.accent : Theme.textFaint
                    }
                    Rectangle {
                        visible: row.index < 9
                        Layout.preferredWidth: hint.implicitWidth + 10
                        Layout.preferredHeight: 20
                        radius: 5
                        color: "transparent"
                        border.width: 1
                        border.color: Theme.border
                        opacity: row.current ? 1 : 0.5
                        Txt {
                            id: hint
                            anchors.centerIn: parent
                            role: "mono"
                            font.pixelSize: 10
                            text: "^" + (row.index + 1)
                            color: Theme.textSub
                        }
                    }
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
            implicitHeight: 1
            color: Theme.divider
        }
        Item {
            id: footer
            Layout.fillWidth: true
            implicitHeight: 34

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 16
                Mark { size: 13 }
                Txt { role: "caption"; text: Search.results.length + " résultat" + (Search.results.length > 1 ? "s" : ""); color: Theme.textFaint }
                Item { Layout.fillWidth: true }
                Txt { role: "caption"; text: "↑↓ naviguer"; color: Theme.textFaint }
                Txt { role: "caption"; text: "↵ ouvrir"; color: Theme.textFaint }
                Txt { role: "caption"; text: "échap fermer"; color: Theme.textFaint }
            }
        }
    }
}
