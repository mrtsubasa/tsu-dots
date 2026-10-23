pragma ComponentBehavior: Bound
import QtQuick
import qs.rice
import "../../components"

Item {
    id: root
    implicitWidth: 820
    implicitHeight: 540

    Surface {
        anchors.fill: parent
        elev: 3
        radius: Tokens.rLg
        photo: true
        border.color: Qt.alpha(Theme.primary, 0.22)

        HubBoard {
            anchors.fill: parent
            anchors.margins: 16
            overlay: false
        }
    }
}
