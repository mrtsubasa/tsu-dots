pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.rice
import qs.kit

// Workspaces de l'écran : la cellule active s'élargit en capsule d'accent
// (indicateur qui glisse) ; occupé = chiffre plein, vide = chiffre estompé,
// urgent = point rouge. Molette = workspace suivant/précédent.
// Un workspace spécial ouvert sur cet écran apparaît en pastille à droite.
Item {
    id: root

    property string outputName: ""
    readonly property var spaces: Niri.workspacesOn(outputName)
    readonly property int cell: Math.max(20, Tokens.barItem - 4)
    readonly property int wide: cell + 12
    readonly property int gap: 2

    readonly property var occupiedIds: {
        const ids = {};
        const wins = Niri.windows;
        for (let i = 0; i < wins.length; i++)
            ids[wins[i].workspace_id] = true;
        return ids;
    }

    readonly property int activeIndex: {
        for (let i = 0; i < spaces.length; i++)
            if (spaces[i].is_active || spaces[i].is_focused)
                return i;
        return -1;
    }

    // workspace spécial (scratchpad) visible sur cet écran
    readonly property var hyprMon: {
        const ms = Hyprland.monitors.values;
        for (let i = 0; i < ms.length; i++)
            if (ms[i].name === outputName)
                return ms[i];
        return null;
    }
    readonly property string special: {
        const o = hyprMon ? hyprMon.lastIpcObject : null;
        const n = o && o.specialWorkspace ? String(o.specialWorkspace.name || "") : "";
        return n.replace(/^special:?/, "");
    }
    readonly property bool hasSpecial: hyprMon !== null && hyprMon.lastIpcObject && hyprMon.lastIpcObject.specialWorkspace && hyprMon.lastIpcObject.specialWorkspace.id !== 0

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activespecial" || event.name === "activespecialv2")
                Hyprland.refreshMonitors();
        }
    }

    implicitHeight: Tokens.barItem
    implicitWidth: row.implicitWidth + (specialChip.visible ? specialChip.width + 6 : 0)

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0)
                Niri.workspaceUp();
            else
                Niri.workspaceDown();
        }
    }

    // indicateur actif (glisse sous les chiffres)
    Rectangle {
        id: ind
        visible: root.activeIndex >= 0
        readonly property Item target: root.activeIndex >= 0 && rep.count > root.activeIndex ? rep.itemAt(root.activeIndex) : null
        x: target ? row.x + target.x : 0
        width: target ? target.width : root.wide
        height: root.cell
        anchors.verticalCenter: parent.verticalCenter
        radius: height / 2
        color: Theme.accent
        Behavior on x { NumberAnimation { duration: Motion.dur(Motion.slow); easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.curveStd } }
        Behavior on width { NumberAnimation { duration: Motion.dur(Motion.slow); easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.curveStd } }

        // halo discret (thèmes néon)
        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            radius: height / 2
            color: "transparent"
            border.width: 2
            border.color: Qt.alpha(Theme.accent, 0.35 * Theme.glow)
            visible: Theme.glow > 0.3
        }
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.gap

        Repeater {
            id: rep
            model: root.spaces

            Item {
                id: ws
                required property var modelData
                required property int index
                readonly property bool active: index === root.activeIndex
                readonly property bool occupied: !!root.occupiedIds[modelData.id]
                readonly property bool urgent: !!modelData.is_urgent

                width: active ? root.wide : root.cell
                height: root.cell
                Behavior on width { NumberAnimation { duration: Motion.dur(Motion.slow); easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.curveStd } }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Theme.text
                    opacity: area.containsMouse && !ws.active ? 0.07 : 0
                    Behavior on opacity { NumberAnimation { duration: Motion.dur(Motion.fast) } }
                }

                Text {
                    anchors.centerIn: parent
                    text: String(ws.modelData.idx || ws.index + 1)
                    font.family: Theme.monoFont
                    font.pixelSize: 11
                    font.weight: ws.active ? Font.Bold : Font.DemiBold
                    color: ws.active ? Theme.onAccent : (ws.occupied ? Theme.text : Theme.textFaint)
                    Behavior on color { ColorAnimation { duration: Motion.dur(Motion.fast) } }
                }

                Rectangle {
                    visible: ws.urgent && !ws.active
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Theme.error
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 2
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton)
                            PanelService.toggle("overview", root.outputName);
                        else
                            Niri.focusWorkspace(root.outputName, ws.modelData.idx);
                    }
                }
            }
        }
    }

    // scratchpad / workspace spécial
    Rectangle {
        id: specialChip
        visible: root.hasSpecial
        anchors.left: row.right
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        height: root.cell
        width: specialRow.implicitWidth + 14
        radius: height / 2
        color: Qt.alpha(Theme.signature, 0.16)
        border.width: 1
        border.color: Qt.alpha(Theme.signature, 0.45)

        Row {
            id: specialRow
            anchors.centerIn: parent
            spacing: 4
            Icon {
                name: "auto_awesome"
                size: 13
                fill: 1
                color: Theme.signature
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                visible: root.special.length > 0 && root.special !== "magic"
                text: root.special
                font.family: Theme.monoFont
                font.pixelSize: 10
                color: Theme.signature
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Hyprland.dispatch("togglespecialworkspace " + root.special)
        }
    }
}
