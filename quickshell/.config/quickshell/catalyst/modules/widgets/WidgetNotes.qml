import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Notes : texte libre persisté dans le widget (enregistrement 600 ms après
// la dernière frappe). Un clic donne le focus clavier à la couche.
Item {
    id: root
    property string wid: ""
    readonly property string saved: (WidgetStore.get(wid).props || {}).text || ""

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Txt { role: "overline"; text: "// notes"; color: Theme.accent; Layout.fillWidth: true }
            Txt { role: "caption"; text: edit.length + " car."; color: Theme.textFaint }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: edit.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            TextEdit {
                id: edit
                width: parent.width
                text: root.saved
                wrapMode: TextEdit.Wrap
                color: Theme.text
                selectionColor: Theme.selection
                font.family: Theme.uiFont
                font.pixelSize: 14
                textFormat: TextEdit.PlainText
                onTextChanged: if (text !== root.saved) saveT.restart()

                Txt {
                    visible: edit.text.length === 0 && !edit.activeFocus
                    role: "body"
                    text: "Écris quelque chose…"
                    color: Theme.textFaint
                }
            }
        }
    }

    Timer {
        id: saveT
        interval: 600
        onTriggered: WidgetStore.setProps(root.wid, { text: edit.text })
    }
}
