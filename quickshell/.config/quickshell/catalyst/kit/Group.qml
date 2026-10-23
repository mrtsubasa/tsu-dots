import QtQuick
import QtQuick.Layouts
import qs.rice

// Groupe de réglages : carte qui empile des SettingRow.
Pane {
    id: root
    default property alias rows: col.data
    level: 3
    glass: false
    radius: Tokens.rLg
    implicitHeight: col.implicitHeight + 8
    implicitWidth: 480

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 4
        spacing: 0
    }
}
