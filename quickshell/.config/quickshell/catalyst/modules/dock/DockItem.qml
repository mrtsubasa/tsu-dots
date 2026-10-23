pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.rice
import "../../components"

Item {
    id: root
    property var app: ({})
    property int slot: 0
    property real mousePos: -9999
    property bool dockHot: false
    property Item track: null
    property string outputName: ""

    readonly property bool sep: !!(app && (app.type === "separator" || app.sep))
    readonly property bool spell: String(app.exec || "").indexOf("spell:") === 0
    readonly property string spellGlyph: {
        const c = String(app.exec || "");
        if (c.indexOf("launcher") >= 0)
            return "󰀻";
        if (c.indexOf("dashboard") >= 0 || c.indexOf("atelier") >= 0)
            return "󰒓";
        return "󰘔";
    }
    readonly property int box: DockCfg.iconSize
    readonly property var wins: root.sep ? [] : DockCfg.runningWins(app)
    readonly property bool live: wins.length > 0
    readonly property bool focused: {
        for (let i = 0; i < wins.length; i++) {
            if (wins[i].is_focused)
                return true;
        }
        return false;
    }
    readonly property real dist: {
        if (!dockHot || root.sep || !track)
            return 9999;
        const p = mapToItem(track, width / 2, height / 2);
        const along = DockCfg.vertical ? p.y : p.x;
        return Math.abs(mousePos - along);
    }
    readonly property real mag: {
        if (root.sep || DockCfg.zoom <= 1.02)
            return 1;
        const k = Math.max(0, 1 - dist / Math.max(24, DockCfg.magRange));
        return 1 + (DockCfg.zoom - 1) * Math.pow(k, 1.15);
    }

    width: DockCfg.vertical ? box : (root.sep ? 12 : box)
    height: DockCfg.vertical ? (root.sep ? 12 : box) : box

    Rectangle {
        visible: root.sep
        anchors.centerIn: parent
        width: DockCfg.vertical ? Math.max(12, box * 0.55) : 2
        height: DockCfg.vertical ? 2 : Math.max(12, box * 0.55)
        radius: 1
        color: Qt.alpha(Theme.primary, 0.45)
    }

    Item {
        visible: !root.sep
        anchors.centerIn: parent
        width: box
        height: box
        scale: root.mag
        transformOrigin: DockCfg.east ? Item.Right : (DockCfg.west ? Item.Left : (DockCfg.north ? Item.Top : Item.Bottom))
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        AppIcon {
            visible: !root.spell
            anchors.centerIn: parent
            size: box
            plain: true
            iconName: root.app.icon || ""
            appId: root.app.wmclass || root.app.id || ""
            label: root.app.name || root.app.id || ""
        }
        Text {
            visible: root.spell
            anchors.centerIn: parent
            text: root.spellGlyph
            font.family: Theme.font
            font.pixelSize: Math.round(box * 0.72)
            color: Theme.primary
        }

        Rectangle {
            visible: DockCfg.showDots && root.live
            width: root.focused ? 9 : 5
            height: 5
            radius: 3
            color: root.focused ? Theme.primary : Qt.alpha(Theme.ink, 0.55)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: -5
        }
    }

    Rectangle {
        visible: !root.sep && DockCfg.showLabels !== "never" && area.containsMouse
        anchors.verticalCenter: DockCfg.vertical ? parent.verticalCenter : undefined
        anchors.horizontalCenter: DockCfg.vertical ? undefined : parent.horizontalCenter
        anchors.right: DockCfg.east ? parent.left : undefined
        anchors.left: DockCfg.west ? parent.right : undefined
        anchors.bottom: DockCfg.south ? parent.top : undefined
        anchors.top: DockCfg.north ? parent.bottom : undefined
        anchors.margins: 10
        height: lab.implicitHeight + 10
        width: lab.implicitWidth + 16
        radius: 8
        color: Qt.alpha(Theme.surfaceContainerHigh, 0.94)
        border.width: 1
        border.color: Theme.hairline
        z: 20
        Text {
            id: lab
            anchors.centerIn: parent
            text: root.app.name || root.app.id || ""
            font.family: Theme.uiFont
            font.pixelSize: 11
            color: Theme.ink
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: root.sep ? Qt.ArrowCursor : Qt.PointingHandCursor
        onPositionChanged: event => {
            if (!root.track)
                return;
            const p = mapToItem(root.track, event.x, event.y);
            root.track.feed(p.x, p.y);
        }
        onEntered: {
            if (root.track)
                root.track.enter();
        }
        onClicked: event => {
            if (root.sep)
                return;
            if (event.button === Qt.RightButton)
                DockCfg.unpin(root.slot);
            else
                DockCfg.launch(root.app, root.outputName);
        }
    }
}
