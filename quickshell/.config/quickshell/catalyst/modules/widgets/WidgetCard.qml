pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import "../../components"

Surface {
    id: card

    property string wid: ""
    property bool editMode: false
    // false si le widget est affecté à un autre écran
    property bool mine: true
    // conteneur plein écran (repère stable pour le redimensionnement)
    property Item bounds: null

    default property alias body: bodyBox.data

    readonly property var entry: WidgetStore.get(wid)
    readonly property var typeDef: WidgetStore.defOf(entry.type)
    readonly property real minW: 240
    readonly property real minH: 140
    // réserves : barre en haut, dock en bas, bordées latérales
    readonly property real padX: 8
    readonly property real padTop: 68
    readonly property real padBottom: 76

    elev: 3
    radiusScale: Tokens.rLg

    x: entry.x
    y: entry.y
    width: entry.w
    height: entry.h
    visible: entry.visible && mine

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.width: card.editMode ? 2 : 0
        border.color: Qt.alpha(Theme.primary, 0.75)
        enabled: false
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: card.editMode ? 12 : 16
        spacing: 8

        RowLayout {
            visible: card.editMode
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: card.typeDef.glyph
                font.family: Theme.font
                font.pixelSize: 15
                color: Theme.primary
            }
            Text {
                text: card.typeDef.label
                font.family: Theme.uiFont
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: Theme.ink
            }
            Item {
                Layout.fillWidth: true
            }
            Text {
                text: entry.visible ? "󰈈" : "󰈉"
                font.family: Theme.font
                font.pixelSize: 14
                color: entry.visible ? Theme.inkMuted : Theme.disabledInk
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    onClicked: WidgetStore.toggleVisible(card.wid)
                }
            }
            Text {
                text: "󰆴"
                font.family: Theme.font
                font.pixelSize: 14
                color: Theme.inkMuted
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    onClicked: WidgetStore.duplicate(card.wid)
                }
            }
            Text {
                text: "󰜗"
                font.family: Theme.font
                font.pixelSize: 15
                color: Qt.alpha(Theme.error, 0.9)
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    onClicked: WidgetStore.remove(card.wid)
                }
            }
        }

        Item {
            id: bodyBox
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 0
            Layout.minimumWidth: 0
            clip: true
        }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        enabled: card.editMode
        cursorShape: Qt.SizeAllCursor
        drag.target: card
        drag.axis: Drag.XandYAxis
        drag.threshold: 3

        onReleased: {
            const host = card.bounds ? card.bounds : card.parent;
            const snap = v => Math.max(card.padX, Math.round(v / 16) * 16);
            const nx = Math.max(card.padX, Math.min(snap(card.x), host.width - card.width - card.padX));
            const ny = Math.max(card.padTop, Math.min(snap(card.y), host.height - card.height - card.padBottom));
            card.x = nx;
            card.y = ny;
            WidgetStore.setPos(card.wid, nx, ny);
            card.x = Qt.binding(() => card.entry.x);
            card.y = Qt.binding(() => card.entry.y);
        }
    }

    MouseArea {
        id: resizeArea
        width: 26
        height: 26
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        enabled: card.editMode
        cursorShape: Qt.SizeFDiagCursor
        z: 4

        function applyTo(px, py) {
            const host = card.bounds ? card.bounds : card.parent;
            const maxW = Math.max(card.minW, host.width - card.x - card.padX);
            const maxH = Math.max(card.minH, host.height - card.y - card.padBottom);
            const w = Math.max(card.minW, Math.min(maxW, px - card.x));
            const h = Math.max(card.minH, Math.min(maxH, py - card.y));
            card.width = w;
            card.height = h;
        }

        onPressed: mouse => {
            mouse.accepted = true;
        }

        onPositionChanged: mouse => {
            if (!pressed)
                return;
            const host = card.bounds ? card.bounds : card.parent;
            const p = resizeArea.mapToItem(host, mouse.x, mouse.y);
            resizeArea.applyTo(p.x, p.y);
        }

        onReleased: {
            WidgetStore.setSize(card.wid, card.width, card.height);
            card.width = Qt.binding(() => card.entry.w);
            card.height = Qt.binding(() => card.entry.h);
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 5
            radius: 4
            color: Qt.alpha(Theme.primary, 0.35)
            enabled: false
        }
    }
}
