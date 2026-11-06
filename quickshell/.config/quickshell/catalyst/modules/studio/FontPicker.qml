pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Sélecteur de police : recherche + liste rendue dans chaque police.
// `monoOnly` limite aux polices à chasse fixe (terminaux, mono du rice).
ColumnLayout {
    id: root

    property string current: ""
    property string defaultName: ""
    property bool monoOnly: false
    property string sample: "Aa Bb 0123 — Catalyst"
    signal picked(string family)

    readonly property var source: monoOnly ? Fonts.mono : Fonts.all
    readonly property var filtered: {
        const q = search.text.trim().toLowerCase();
        const list = q.length ? source.filter(f => f.toLowerCase().indexOf(q) >= 0) : source;
        return list.slice(0, 300);
    }

    spacing: 8

    Component.onCompleted: {
        if (!Fonts.loaded)
            Fonts.refresh();
        search.focusInput();
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        SearchField {
            id: search
            Layout.fillWidth: true
            placeholder: (root.monoOnly ? "Rechercher une police mono" : "Rechercher une police") + " (" + root.source.length + ")"
        }
        Button {
            variant: "secondary"
            icon: "restart_alt"
            text: "Par défaut" + (root.defaultName.length ? " (" + root.defaultName + ")" : "")
            onClicked: root.picked("")
        }
    }

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.preferredHeight: 260
        clip: true
        model: root.filtered
        boundsBehavior: Flickable.StopAtBounds
        spacing: 2

        delegate: Rectangle {
            id: item
            required property string modelData
            readonly property bool selected: modelData === root.current
            width: list.width
            height: 40
            radius: Tokens.rMd
            color: selected ? Qt.alpha(Theme.accent, 0.14) : (hover.containsMouse ? Theme.hover : "transparent")
            border.width: selected ? 1 : 0
            border.color: Qt.alpha(Theme.accent, 0.4)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12
                Txt {
                    Layout.preferredWidth: 220
                    role: "label"
                    text: item.modelData
                    elide: Text.ElideRight
                    color: item.selected ? Theme.accent : Theme.text
                }
                Text {
                    Layout.fillWidth: true
                    text: root.sample
                    font.family: item.modelData
                    font.pixelSize: 15
                    color: Theme.textSub
                    elide: Text.ElideRight
                }
                Icon {
                    visible: item.selected
                    name: "check"
                    size: 16
                    color: Theme.accent
                }
            }

            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.picked(item.modelData)
            }
        }
    }

    Txt {
        visible: root.filtered.length === 0
        role: "caption"
        color: Theme.textFaint
        text: Fonts.loaded ? "Aucune police ne correspond." : "Chargement des polices…"
    }
}
