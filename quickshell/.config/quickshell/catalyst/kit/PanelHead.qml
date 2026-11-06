import QtQuick
import QtQuick.Layouts
import qs.rice

// En-tête de panneau : médaillon d'icône teinté, sur-titre « // … », titre,
// contenu libre à droite (boutons, puces).
RowLayout {
    id: root
    property string icon: ""
    property string overline: ""
    property string title: ""
    property string subtitle: ""
    property color tone: Theme.accent
    default property alias trailing: trail.data

    spacing: 11

    Rectangle {
        visible: root.icon.length > 0
        Layout.preferredWidth: 36
        Layout.preferredHeight: 36
        radius: Tokens.rMd
        color: Qt.alpha(root.tone, 0.14)
        border.width: 1
        border.color: Qt.alpha(root.tone, 0.32)
        Icon { anchors.centerIn: parent; name: root.icon; size: 19; fill: 1; color: root.tone }
    }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        Txt { visible: root.overline.length > 0; role: "overline"; text: "// " + root.overline; color: root.tone }
        Txt { Layout.fillWidth: true; role: "title"; text: root.title }
        Txt { Layout.fillWidth: true; visible: root.subtitle.length > 0; role: "caption"; text: root.subtitle }
    }
    RowLayout {
        id: trail
        spacing: 6
    }
}
