pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.rice
import qs.kit

// Zone de notification (StatusNotifier) en tiroir : replié par défaut, le
// chevron déplie les icônes en ligne. Clic = activer, clic milieu = action
// secondaire, clic droit = menu de l'application (panneau Catalyst).
Item {
    id: root

    property var barWin: null
    property bool expanded: false
    readonly property var items: SystemTray.items.values
    readonly property int count: items.length

    property bool want: BarCfg.on("tray") && count > 0
    implicitHeight: Tokens.barItem
    implicitWidth: chevron.width + drawer.width

    Item {
        id: drawer
        anchors.right: chevron.left
        height: parent.height
        width: root.expanded ? icons.implicitWidth + 4 : 0
        clip: true
        Behavior on width { NumberAnimation { duration: Motion.dur(Motion.base); easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.curveStd } }

        Row {
            id: icons
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            opacity: root.expanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.dur(Motion.fast) } }

            Repeater {
                // icônes construites seulement tiroir ouvert : certaines applis
                // changent d'icône en boucle (D-Bus), inutile de suivre replié
                model: root.expanded ? root.items : []

                BarItem {
                    id: ti
                    required property var modelData
                    padX: 5
                    tooltip: modelData.tooltipTitle || modelData.title || modelData.id || ""
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton)
                            PanelService.togglePopover("tray", root.barWin, root);
                        else if (mouse.button === Qt.MiddleButton)
                            ti.modelData.secondaryActivate();
                        else if (ti.modelData.onlyMenu)
                            PanelService.togglePopover("tray", root.barWin, root);
                        else
                            ti.modelData.activate();
                    }
                    onWheel: w => ti.modelData.scroll(w.angleDelta.y, false)

                    IconImage {
                        anchors.verticalCenter: parent.verticalCenter
                        source: ti.modelData.icon
                        implicitSize: 16
                    }
                }
            }
        }
    }

    BarItem {
        id: chevron
        anchors.right: parent.right
        padX: 6
        tooltip: root.expanded ? "Replier" : root.count + " application" + (root.count > 1 ? "s" : "") + " en arrière-plan"
        active: root.expanded
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                PanelService.togglePopover("tray", root.barWin, root);
            else
                root.expanded = !root.expanded;
        }

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: "chevron_left"
            size: 18
            color: Theme.textSub
            rotation: root.expanded ? 180 : 0
            Behavior on rotation { NumberAnimation { duration: Motion.dur(Motion.base) } }
        }
    }
}
