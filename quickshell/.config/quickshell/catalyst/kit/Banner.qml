import QtQuick
import QtQuick.Layouts
import qs.rice

// Bandeau d'information / avertissement : filet coloré, icône, texte.
Rectangle {
    id: root
    property string icon: "info"
    property string text: ""
    property color tone: Theme.warning
    default property alias trailing: trail.data

    implicitHeight: Math.max(38, row.implicitHeight + 18)
    radius: Tokens.rMd
    color: Qt.alpha(tone, 0.09)
    border.width: 1
    border.color: Qt.alpha(tone, 0.28)

    Rectangle {
        x: 0
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: parent.height - 16
        radius: 1
        color: root.tone
    }
    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 10
        spacing: 9
        Icon { Layout.alignment: Qt.AlignTop; Layout.topMargin: 10; name: root.icon; size: 16; fill: 1; color: root.tone }
        Txt {
            Layout.fillWidth: true
            Layout.topMargin: 9
            Layout.bottomMargin: 9
            role: "caption"
            wrapMode: Text.WordWrap
            color: Qt.lighter(root.tone, 1.08)
            text: root.text
        }
        RowLayout { id: trail; spacing: 6 }
    }
}
