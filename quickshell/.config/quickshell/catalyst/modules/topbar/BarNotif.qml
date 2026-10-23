import QtQuick
import qs.rice
import qs.kit

// Cloche : point signature s'il y a des notifications, icône barrée en
// Ne pas déranger. Clic = centre de contrôle (section notifications) ;
// clic droit = bascule NPD.
BarItem {
    id: root

    property var barWin: null
    readonly property int count: Notifs.count

    tooltip: Notifs.dnd ? "Ne pas déranger" : (count > 0 ? count + " notification" + (count > 1 ? "s" : "") : "Aucune notification")
    padX: 7
    active: PanelService.active === "control" && PanelService.focusSection === "notifs" && PanelService.outputName === (barWin ? barWin.outputName : "")

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            Notifs.toggleDnd();
        else
            PanelService.openAt("control", root.barWin, root, "notifs");
    }

    Item {
        width: 18
        height: 18
        anchors.verticalCenter: parent.verticalCenter

        Icon {
            anchors.centerIn: parent
            name: Notifs.dnd ? "notifications_off" : (root.count > 0 ? "notifications_unread" : "notifications")
            size: 17
            fill: root.count > 0 ? 1 : 0
            color: Notifs.dnd ? Theme.textFaint : Theme.text
        }
    }

    Text {
        visible: root.count > 0 && !Notifs.dnd
        anchors.verticalCenter: parent.verticalCenter
        text: root.count > 99 ? "99+" : String(root.count)
        font.family: Theme.monoFont
        font.pixelSize: 11
        font.weight: Font.Bold
        color: Theme.signature
    }
}
