pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// En-tête des panneaux hérités : glyphe (Nerd Font) en pastille, titre,
// actions, fermeture — même langage que les en-têtes du kit v3.
RowLayout {
    id: root
    property string icon: ""
    property string title: ""
    property bool closable: false
    default property alias extras: extra.data
    signal closed

    Layout.fillWidth: true
    spacing: 10

    Rectangle {
        visible: root.icon.length > 0
        Layout.preferredWidth: 36
        Layout.preferredHeight: 36
        radius: Tokens.rMd
        color: Qt.alpha(Theme.accent, 0.14)
        border.width: 1
        border.color: Qt.alpha(Theme.accent, 0.32)
        Text {
            anchors.centerIn: parent
            text: root.icon
            font.family: Theme.font
            font.pixelSize: 17
            color: Theme.accent
        }
    }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        Txt { role: "overline"; text: "// " + ShellCfg.brand; color: Theme.accent }
        Txt { role: "title"; text: root.title; Layout.fillWidth: true }
    }

    Row {
        id: extra
        spacing: 6
        Layout.alignment: Qt.AlignVCenter
    }

    Rectangle {
        visible: root.closable
        Layout.preferredWidth: 32
        Layout.preferredHeight: 32
        radius: 16
        color: closeTap.containsMouse ? Qt.alpha(Theme.error, 0.16) : Qt.alpha(Theme.text, 0.05)
        border.width: 1
        border.color: closeTap.containsMouse ? Qt.alpha(Theme.error, 0.4) : Theme.border
        Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
        Icon { anchors.centerIn: parent; name: "close"; size: 16; color: closeTap.containsMouse ? Theme.error : Theme.textSub }
        StateLayer { id: closeTap; anchors.fill: parent; radius: 16; hoverAlpha: 0; onClicked: root.closed() }
        Tip { target: closeTap; text: "Fermer (Échap)"; active: closeTap.containsMouse }
    }
}
