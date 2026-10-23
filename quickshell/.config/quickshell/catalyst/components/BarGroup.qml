pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice

Item {
    id: root
    property int padding: Tokens.s1
    default property alias items: row.data
    implicitWidth: Math.max(36, row.implicitWidth + padding * 2)
    implicitHeight: Tokens.barHeight

    Rectangle {
        anchors.fill: parent
        radius: Tokens.rMd
        color: Theme.layer1
        border.width: 1
        border.color: Tokens.borderOf(0.7)
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        spacing: Tokens.s1
    }
}
