import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// En-tête de sous-page : retour · titre · contrôle optionnel à droite.
RowLayout {
    id: root
    property string title: ""
    property string subtitle: ""
    default property alias trailing: trail.data
    signal back()

    spacing: 8

    IconButton {
        icon: "arrow_back"
        size: 32
        iconSize: 18
        tooltip: "Retour"
        onClicked: root.back()
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
