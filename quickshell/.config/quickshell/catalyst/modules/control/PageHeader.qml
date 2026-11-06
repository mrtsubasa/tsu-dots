import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// En-tête de sous-page : retour (capsule), médaillon d'icône, sur-titre
// « // centre de contrôle », titre, contrôle optionnel à droite, filet.
ColumnLayout {
    id: root
    property string title: ""
    property string subtitle: ""
    property string icon: ""
    property color tone: Theme.accent
    default property alias trailing: trail.data
    signal back()

    spacing: 12

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            radius: 17
            color: backTap.containsMouse ? Qt.alpha(Theme.text, 0.10) : Qt.alpha(Theme.text, 0.05)
            border.width: 1
            border.color: Theme.border
            Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
            Icon { anchors.centerIn: parent; name: "arrow_back"; size: 17; color: Theme.text }
            StateLayer { id: backTap; anchors.fill: parent; radius: 17; hoverAlpha: 0; onClicked: root.back() }
            Tip { target: backTap; text: "Retour"; active: backTap.containsMouse }
        }
        Rectangle {
            visible: root.icon.length > 0
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            radius: Tokens.rMd
            color: Qt.alpha(root.tone, 0.14)
            border.width: 1
            border.color: Qt.alpha(root.tone, 0.32)
            Icon { anchors.centerIn: parent; name: root.icon; size: 18; fill: 1; color: root.tone }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Txt { role: "title"; text: root.title; Layout.fillWidth: true }
            Txt { role: "caption"; text: root.subtitle; visible: text.length > 0; Layout.fillWidth: true }
        }
        Row {
            id: trail
            spacing: 6
            Layout.alignment: Qt.AlignVCenter
        }
    }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.alpha(root.tone, 0.5) }
            GradientStop { position: 0.3; color: Theme.border }
            GradientStop { position: 1; color: "transparent" }
        }
    }
}
