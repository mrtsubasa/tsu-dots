pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.rice
import qs.kit
import "../../components"

// Icône du dock v3 : survol = léger soulèvement (pas d'effet « loupe »),
// indicateurs d'état sous l'icône (1 point par fenêtre, 3 max ; capsule
// d'accent si l'app a le focus). Clic = focus / lancement, clic milieu =
// nouvelle fenêtre, clic droit = menu (épingler, fermer…).
Item {
    id: root

    property var app: ({})
    property int slot: -1          // index dans DockCfg.apps (-1 = non épinglée)
    property string outputName: ""
    property string edge: "bottom"

    readonly property bool sep: !!(app && (app.type === "separator" || app.sep))
    readonly property bool panelLink: String(app.exec || "").indexOf("spell:") === 0
    readonly property string panelIcon: {
        const c = String(app.exec || "");
        if (c.indexOf("launcher") >= 0) return "apps";
        if (c.indexOf("dashboard") >= 0 || c.indexOf("control") >= 0) return "tune";
        if (c.indexOf("atelier") >= 0 || c.indexOf("studio") >= 0) return "palette";
        return "widgets";
    }
    readonly property int box: DockCfg.iconSize
    readonly property var wins: sep || panelLink ? [] : DockCfg.runningWins(app)
    readonly property bool live: wins.length > 0
    readonly property bool focused: wins.some(w => w.is_focused)
    readonly property bool vertical: edge === "left" || edge === "right"
    readonly property string label: {
        if (app.name && app.name.length)
            return app.name;
        const d = DesktopEntries.heuristicLookup(app.wmclass || app.id || "");
        return d ? d.name : (app.id || "");
    }

    width: sep ? (vertical ? box : 10) : box
    height: sep ? (vertical ? 10 : box) : box

    // séparateur
    Rectangle {
        visible: root.sep
        anchors.centerIn: parent
        width: root.vertical ? root.box * 0.5 : 1
        height: root.vertical ? 1 : root.box * 0.5
        color: Theme.borderStrong
    }

    Item {
        id: icon
        visible: !root.sep
        width: root.box
        height: root.box
        property real lift: area.containsMouse ? 4 : 0
        Behavior on lift { NumberAnimation { duration: Motion.dur(Motion.fast); easing.type: Easing.OutCubic } }
        x: root.edge === "left" ? lift : (root.edge === "right" ? -lift : 0)
        y: root.edge === "bottom" ? -lift : (root.edge === "top" ? lift : 0)
        scale: area.pressed ? 0.9 : (area.containsMouse ? 1.08 : 1)
        Behavior on scale { NumberAnimation { duration: Motion.dur(Motion.fast) } }

        AppIcon {
            visible: !root.panelLink
            anchors.fill: parent
            appId: root.app.desktop || root.app.wmclass || root.app.id || ""
            iconName: root.app.icon || ""
            label: root.label
            size: root.box
        }

        Rectangle {
            visible: root.panelLink
            anchors.fill: parent
            radius: Tokens.rMd
            color: Theme.s4
            border.width: 1
            border.color: Theme.border
            Icon {
                anchors.centerIn: parent
                name: root.panelIcon
                size: root.box * 0.55
                color: Theme.accent
            }
        }
    }

    // indicateurs
    Row {
        visible: root.live && DockCfg.showDots
        spacing: 3
        anchors.horizontalCenter: root.vertical ? undefined : parent.horizontalCenter
        anchors.verticalCenter: root.vertical ? parent.verticalCenter : undefined
        anchors.top: root.edge === "bottom" ? parent.bottom : undefined
        anchors.topMargin: 4
        anchors.bottom: root.edge === "top" ? parent.top : undefined
        anchors.bottomMargin: 4
        anchors.left: root.edge === "right" ? parent.right : undefined
        anchors.leftMargin: 4
        anchors.right: root.edge === "left" ? parent.left : undefined
        anchors.rightMargin: 4

        Repeater {
            model: root.focused ? 1 : Math.min(3, root.wins.length)
            Rectangle {
                width: root.focused ? 14 : 4
                height: 4
                radius: 2
                color: root.focused ? Theme.accent : Theme.textSub
                Behavior on width { NumberAnimation { duration: Motion.dur(Motion.base) } }
            }
        }
    }

    MouseArea {
        id: area
        visible: !root.sep
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                menu.openAt(root);
            else if (mouse.button === Qt.MiddleButton)
                DockCfg.newInstance(root.app);
            else
                DockCfg.launch(root.app, root.outputName);
        }
    }

    Tip {
        target: root
        text: root.label + (root.wins.length > 1 ? "  ·  " + root.wins.length + " fenêtres" : "")
        side: root.edge === "bottom" ? "top" : (root.edge === "top" ? "bottom" : (root.edge === "left" ? "right" : "left"))
        active: area.containsMouse && !menu.visible
    }

    Menu {
        id: menu
        side: root.edge === "bottom" ? "top" : (root.edge === "top" ? "bottom" : (root.edge === "left" ? "right" : "left"))
        items: {
            const out = [];
            if (!root.panelLink)
                out.push({ label: "Nouvelle fenêtre", icon: "add", action: () => DockCfg.newInstance(root.app) });
            if (root.slot >= 0) {
                out.push({ label: "Déplacer avant", icon: root.vertical ? "arrow_upward" : "arrow_back", enabled: root.slot > 0, action: () => DockCfg.move(root.slot, -1) });
                out.push({ label: "Déplacer après", icon: root.vertical ? "arrow_downward" : "arrow_forward", enabled: root.slot < DockCfg.apps.length - 1, action: () => DockCfg.move(root.slot, 1) });
                out.push({ label: "Désépingler", icon: "keep_off", action: () => DockCfg.unpin(root.slot) });
            } else {
                out.push({ label: "Épingler au dock", icon: "keep", action: () => DockCfg.pin(root.app.wmclass || root.app.id) });
            }
            if (root.live) {
                out.push({ separator: true });
                out.push({ label: root.wins.length > 1 ? "Fermer les " + root.wins.length + " fenêtres" : "Fermer", icon: "close", danger: true, action: () => DockCfg.closeAll(root.app) });
            }
            return out;
        }
    }
}
