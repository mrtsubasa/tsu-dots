pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Presse-papiers : recherche, ↑↓ + Entrée pour copier, Suppr pour retirer
// une entrée, pause de l'enregistrement, effacement complet (confirmé).
FocusScope {
    id: root

    property real maxHeight: 640
    property int sel: 0
    property bool armWipe: false
    readonly property var shown: {
        const q = field.text.trim().toLowerCase();
        return q.length ? Clip.entries.filter(e => e.text.toLowerCase().indexOf(q) >= 0) : Clip.entries;
    }

    implicitWidth: 560
    implicitHeight: Math.min(maxHeight, 600)

    Component.onCompleted: {
        Clip.refresh();
        field.focusInput();
    }

    function activate(i) {
        const e = shown[i];
        if (!e)
            return;
        Clip.copy(e);
        PanelService.hide();
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Txt { role: "overline"; text: "// " + ShellCfg.brand; color: Theme.accent }
                Txt { role: "title"; text: "Presse-papiers" }
            }
            Button {
                variant: Clip.paused ? "primary" : "secondary"
                icon: Clip.paused ? "play_arrow" : "pause"
                text: Clip.paused ? "Reprendre" : "Pause"
                height_: 30
                onClicked: Clip.setPaused(!Clip.paused)
            }
            Button {
                variant: root.armWipe ? "danger" : "ghost"
                icon: "delete_sweep"
                text: root.armWipe ? "Confirmer" : "Tout effacer"
                height_: 30
                disabled: Clip.count === 0
                onClicked: {
                    if (!root.armWipe) {
                        root.armWipe = true;
                        disarm.restart();
                        return;
                    }
                    root.armWipe = false;
                    Clip.wipe();
                }
                Timer {
                    id: disarm
                    interval: 4000
                    onTriggered: root.armWipe = false
                }
            }
            IconButton { icon: "close"; size: 30; iconSize: 17; tooltip: "Fermer"; onClicked: PanelService.hide() }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: Clip.paused
            implicitHeight: 34
            radius: Tokens.rMd
            color: Qt.alpha(Theme.warning, 0.12)
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                spacing: 8
                Icon { name: "pause_circle"; size: 16; color: Theme.warning }
                Txt { role: "caption"; text: "Enregistrement en pause : rien de ce que tu copies n'est conservé."; color: Theme.warning }
            }
        }

        SearchField {
            id: field
            Layout.fillWidth: true
            placeholder: "Rechercher dans " + Clip.count + " entrées…"
            onTextChanged: root.sel = 0
            input.Keys.onPressed: event => {
                if (event.key === Qt.Key_Down) {
                    root.sel = Math.min(root.shown.length - 1, root.sel + 1);
                } else if (event.key === Qt.Key_Up) {
                    root.sel = Math.max(0, root.sel - 1);
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.activate(root.sel);
                } else if (event.key === Qt.Key_Delete) {
                    Clip.remove(root.shown[root.sel]);
                } else if (event.key === Qt.Key_Escape) {
                    PanelService.hide();
                } else {
                    return;
                }
                event.accepted = true;
            }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: root.shown
            currentIndex: root.sel
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
            boundsBehavior: Flickable.StopAtBounds

            delegate: ListItem {
                id: row
                required property var modelData
                required property int index
                width: list.width
                rowHeight: 44
                icon: modelData.image ? "image" : (/^https?:\/\//.test(modelData.text) ? "link" : "notes")
                title: modelData.text.replace(/\s+/g, " ").slice(0, 160)
                current: index === root.sel
                onClicked: root.activate(index)
                onHoveredChanged: if (hovered) root.sel = index
                IconButton {
                    icon: "delete"
                    size: 26
                    iconSize: 15
                    tooltip: "Retirer (Suppr)"
                    opacity: row.current ? 1 : 0.4
                    onClicked: Clip.remove(row.modelData)
                }
            }
        }

        EmptyState {
            Layout.fillWidth: true
            visible: root.shown.length === 0 && !Clip.loading
            icon: "content_paste_off"
            title: Clip.count === 0 ? "Historique vide" : "Aucun résultat"
        }

        Txt {
            Layout.fillWidth: true
            role: "caption"
            color: Theme.textFaint
            text: "↑↓ choisir · Entrée copier · Suppr retirer · les mots de passe des gestionnaires (KeePassXC, Bitwarden…) ne sont jamais enregistrés"
            wrapMode: Text.WordWrap
        }
    }
}
