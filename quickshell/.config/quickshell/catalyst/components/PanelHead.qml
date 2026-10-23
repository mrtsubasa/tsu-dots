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
        Layout.preferredWidth: 32
        Layout.preferredHeight: 32
        radius: Tokens.rMd
        color: Theme.stateActive
        Text {
            anchors.centerIn: parent
            text: root.icon
            font.family: Theme.font
            font.pixelSize: 16
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

    IconButton {
        visible: root.closable
        icon: "close"
        tooltip: "Fermer"
        onClicked: root.closed()
    }
}
