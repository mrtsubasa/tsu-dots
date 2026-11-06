import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Ligne de navigation de l'Arsenal (collection ou catégorie) : icône,
// libellé, compteur ; l'élément actif porte le tranchant d'accent à gauche.
Item {
    id: nav
    property string icon: ""
    property string label: ""
    property string count: ""
    property bool on: false
    signal picked
    implicitHeight: 32
    Layout.fillWidth: true

    Rectangle {
        anchors.fill: parent
        radius: Tokens.rSm
        color: nav.on ? Qt.alpha(Theme.accent, 0.12) : (navHover.hovered ? Theme.stateHover : "transparent")
        Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
    }
    // tranchant de l'élément actif
    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: nav.on ? 16 : 0
        radius: 1
        color: Theme.accent
        Behavior on height { NumberAnimation { duration: Motion.dur(Motion.base); easing.type: Easing.OutBack } }
    }
    HoverHandler { id: navHover }
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 10
        spacing: 10
        Icon { name: nav.icon; size: 16; fill: nav.on ? 1 : 0; color: nav.on ? Theme.accent : Theme.textSub }
        Txt { Layout.fillWidth: true; role: "label"; text: nav.label; color: nav.on ? Theme.text : Theme.textSub }
        Txt { role: "mono"; font.pixelSize: 10; text: nav.count; color: nav.on ? Theme.accent : Theme.textFaint }
    }
    TapHandler { onTapped: nav.picked() }
}
