pragma ComponentBehavior: Bound
import QtQuick
import qs.rice

// Workspaces V2 : cellules 22×18, gap 2, chiffres mono 11px.
// Îlots : actif = couleur du texte (pas de pastille pleine).
// Identités continues : actif = fill accent.
Item {
    id: root
    property string outputName: ""
    readonly property var spaces: Niri.workspacesOn(root.outputName)
    readonly property int cell: 22
    readonly property int cellH: 18
    readonly property int gap: 2
    readonly property bool fillActive: !Tokens.barIslands

    implicitWidth: (root.spaces.length + 1) * (root.cell + root.gap)
    implicitHeight: Tokens.barHeight

    Repeater {
        model: root.spaces.length

        delegate: Item {
            id: ws
            required property int index
            readonly property var modelData: root.spaces[index] || {}
            readonly property bool active: !!(modelData.is_active || modelData.is_focused)
            readonly property bool urgent: !!modelData.is_urgent
            readonly property int idx: modelData.idx || 0
            readonly property int wsId: modelData.id || 0
            readonly property bool occupied: {
                const wins = Niri.windows;
                for (let i = 0; i < wins.length; i++) {
                    if (wins[i].workspace_id === ws.wsId)
                        return true;
                }
                return ws.active;
            }

            x: ws.index * (root.cell + root.gap)
            y: (root.height - root.cellH) / 2
            width: root.cell
            height: root.cellH

            Rectangle {
                visible: ws.occupied && !ws.active
                anchors.fill: parent
                radius: Tokens.rSm
                color: Qt.alpha(Theme.primaryContainer, 0.32)
            }

            Rectangle {
                visible: ws.active && root.fillActive
                anchors.fill: parent
                radius: Tokens.rSm
                color: ws.urgent ? Theme.error : Theme.primary
            }

            Text {
                anchors.centerIn: parent
                text: String(ws.idx)
                font.family: Theme.font
                font.pixelSize: Tokens.tBarSmall
                font.weight: ws.active ? Font.Bold : Font.Medium
                color: ws.urgent ? Theme.error : (ws.active ? (root.fillActive ? Theme.inkPrimary : Theme.ink) : (ws.occupied ? Theme.inkMuted : Qt.alpha(Theme.inkMuted, 0.55)))
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Niri.focusWorkspace(root.outputName, ws.idx)
                onPressed: event => {
                    if (event.button === Qt.RightButton)
                        PanelService.toggle("dashboard", root.outputName);
                }
            }
        }
    }

    Item {
        x: root.spaces.length * (root.cell + root.gap)
        y: (root.height - root.cellH) / 2
        width: root.cell
        height: root.cellH
        Text {
            anchors.centerIn: parent
            text: "+"
            font.family: Theme.font
            font.pixelSize: Tokens.tBarSmall
            color: addArea.containsMouse ? Theme.primary : Qt.alpha(Theme.inkMuted, 0.7)
        }
        MouseArea {
            id: addArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Niri.addWorkspace()
        }
    }
}
