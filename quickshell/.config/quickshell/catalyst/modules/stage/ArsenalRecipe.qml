pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.rice
import qs.kit

// Formulaire d'une recette Arsenal : on remplit les champs dont l'outil a
// besoin, puis « Lancer » construit la commande (arguments discrets, pas de
// shell) et l'ouvre dans un terminal. Un aperçu montre la commande exacte.
ColumnLayout {
    id: root

    required property var recipe
    property color tone: Theme.accent
    property string toolName: ""

    property var values: ({})
    property int rev: 0

    Component.onCompleted: {
        const v = {};
        const fs = recipe.fields || [];
        for (let i = 0; i < fs.length; i++)
            if (fs[i].default !== undefined)
                v[fs[i].key] = fs[i].default;
        values = v;
    }

    function setVal(k, val) {
        values[k] = val;
        rev++;
    }

    // recalculé à chaque frappe (rev)
    readonly property var built: {
        rev;
        return Arsenal.buildRecipe(recipe, values);
    }
    function quote(a) {
        return /[^a-zA-Z0-9_.:\/@=,-]/.test(a) ? "'" + a.replace(/'/g, "'\\''") + "'" : a;
    }
    readonly property string preview: built.argv.map(quote).join(" ")

    spacing: 8

    // en-tête de la recette
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Rectangle { Layout.preferredWidth: 6; Layout.preferredHeight: 6; radius: 3; color: root.tone }
        Txt { role: "label"; text: root.recipe.label; font.weight: Font.DemiBold }
        Txt {
            Layout.fillWidth: true
            role: "caption"
            color: Theme.textFaint
            text: root.recipe.desc || ""
            elide: Text.ElideRight
        }
    }

    // champs
    Repeater {
        model: root.recipe.fields || []

        RowLayout {
            id: fr
            required property var modelData
            readonly property bool missing: root.built.missing.indexOf(modelData.key) >= 0
            Layout.fillWidth: true
            spacing: 8

            Txt {
                Layout.preferredWidth: 96
                Layout.alignment: Qt.AlignVCenter
                role: "caption"
                color: fr.missing ? Theme.warning : Theme.textSub
                text: fr.modelData.label + (fr.modelData.req ? " *" : "")
                elide: Text.ElideRight
            }

            // choix fermé
            Segmented {
                visible: fr.modelData.type === "choice"
                compact: true
                model: (fr.modelData.options || []).map(o => ({ id: o, label: o }))
                current: root.values[fr.modelData.key] || fr.modelData.default || ""
                onSelected: id => root.setVal(fr.modelData.key, id)
            }

            // texte / fichier / dossier / entier
            Field {
                id: field
                visible: fr.modelData.type !== "choice"
                Layout.fillWidth: true
                mono: true
                placeholder: fr.modelData.ph || ""
                text: fr.modelData.default || ""
                onTextChanged: root.setVal(fr.modelData.key, text)
                onAccepted: root.launch()
            }
            IconButton {
                visible: fr.modelData.type === "file" || fr.modelData.type === "dir"
                icon: "folder_open"
                variant: "tonal"
                size: Tokens.ctrl
                iconSize: 16
                tooltip: "Parcourir"
                onClicked: picker.running = true
            }
            Process {
                id: picker
                property string out: ""
                command: ["zenity", "--file-selection", "--title", fr.modelData.label]
                    .concat(fr.modelData.type === "dir" ? ["--directory"] : [])
                stdout: SplitParser { onRead: line => picker.out = line.trim() }
                onStarted: out = ""
                onExited: {
                    if (picker.out.length)
                        field.text = picker.out;
                }
            }
        }
    }

    // aperçu de la commande
    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 2
        implicitHeight: prevRow.implicitHeight + 16
        radius: Tokens.rSm
        color: Theme.s1
        border.width: 1
        border.color: Theme.border

        RowLayout {
            id: prevRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 10
            anchors.rightMargin: 8
            spacing: 8

            Text { text: "$"; color: root.tone; font.family: Theme.monoFont; font.pixelSize: 11; font.weight: Font.Bold }
            Txt {
                Layout.fillWidth: true
                role: "mono"
                font.pixelSize: 11
                color: Theme.textSub
                text: root.preview
                elide: Text.ElideRight
            }
            IconButton {
                icon: "content_copy"
                size: 26
                iconSize: 14
                tooltip: "Copier la commande"
                onClicked: Quickshell.execDetached(["bash", "-c", "printf '%s' \"$1\" | wl-copy", "_", root.preview])
            }
        }
    }

    // lancement
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Txt {
            visible: root.built.missing.length > 0
            role: "caption"
            color: Theme.warning
            text: "Champ requis manquant"
        }
        Item { Layout.fillWidth: true }
        Button {
            variant: "primary"
            height_: 30
            icon: "play_arrow"
            text: "Lancer"
            disabled: root.built.missing.length > 0
            onClicked: root.launch()
        }
    }

    function launch() {
        const b = root.built;
        if (b.missing.length > 0)
            return;
        Arsenal.runRecipe((root.toolName || b.argv[0]) + " · " + root.recipe.label, b.argv);
    }
}
