pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit

// Carte de widget. Style par widget (props.style) : glass | solid | bare.
// En mode édition : contour, barre d'outils, déplacement avec magnétisme
// (grille 16 px + bords/centres des autres widgets de l'écran, guides
// affichés par WidgetLayer), poignée de redimensionnement, premier plan.
Item {
    id: card

    property string wid: ""
    property bool editMode: false
    property bool mine: true
    property Item bounds: null
    property Item host: null           // WidgetLayer (guides)
    default property alias body: bodyBox.data

    readonly property var entry: WidgetStore.get(wid)
    readonly property var typeDef: WidgetStore.defOf(entry.type)
    readonly property string style: entry.props && entry.props.style ? entry.props.style : "glass"
    readonly property real minW: 200
    readonly property real minH: 120
    readonly property real padX: 8
    readonly property real padTop: Tokens.belowBar + 4
    readonly property real padBottom: 16
    readonly property int snapDist: 10

    x: entry.x
    y: entry.y
    z: entry.z || 0
    width: entry.w
    height: entry.h
    visible: entry.visible && mine || (editMode && mine)
    opacity: editMode && !entry.visible ? 0.4 : 1

    Pane {
        id: surface
        anchors.fill: parent
        visible: card.style !== "bare" || card.editMode
        level: card.style === "solid" ? 2 : 1
        glass: card.style !== "solid"
        fillAlpha: card.style === "bare" ? 0.25 : (card.style === "solid" ? 0.97 : Math.min(0.82, Theme.glassAlpha))
        radius: Tokens.rXl
        shadow: card.style !== "bare"
        glow: false
        borderColor: card.editMode ? Qt.alpha(Theme.accent, dragArea.drag.active ? 0.9 : 0.55) : Theme.border
    }

    Item {
        id: bodyBox
        anchors.fill: parent
        anchors.margins: card.style === "bare" ? 6 : 18
        anchors.topMargin: card.editMode ? 44 : (card.style === "bare" ? 6 : 18)
        clip: true
    }

    // ---------------- édition ----------------
    MouseArea {
        id: dragArea
        anchors.fill: parent
        enabled: card.editMode
        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        drag.target: card
        drag.threshold: 3
        drag.minimumX: card.padX
        drag.minimumY: card.padTop
        drag.maximumX: (card.bounds ? card.bounds.width : 1920) - card.width - card.padX
        drag.maximumY: (card.bounds ? card.bounds.height : 1080) - card.height - card.padBottom

        onPressed: WidgetStore.bringToFront(card.wid)
        onPositionChanged: if (drag.active) card.computeSnap(false)
        onReleased: {
            const p = card.computeSnap(true);
            WidgetStore.setPos(card.wid, p.x, p.y);
            card.x = Qt.binding(() => card.entry.x);
            card.y = Qt.binding(() => card.entry.y);
            if (card.host)
                card.host.guides = [];
        }
    }

    // calcul du magnétisme ; `apply` = positionne la carte
    function computeSnap(apply) {
        const others = host ? host.rectsExcept(wid) : [];
        const guides = [];
        let nx = x, ny = y;
        let bestX = snapDist + 1, bestY = snapDist + 1;
        const xs = [[x, 0], [x + width / 2, width / 2], [x + width, width]];
        const ys = [[y, 0], [y + height / 2, height / 2], [y + height, height]];
        for (let i = 0; i < others.length; i++) {
            const o = others[i];
            const ox = [o.x, o.x + o.w / 2, o.x + o.w];
            const oy = [o.y, o.y + o.h / 2, o.y + o.h];
            for (let a = 0; a < 3; a++)
                for (let b = 0; b < 3; b++) {
                    const dx = Math.abs(xs[a][0] - ox[b]);
                    if (dx < bestX) { bestX = dx; nx = ox[b] - xs[a][1]; guides[0] = { v: true, at: ox[b] }; }
                    const dy = Math.abs(ys[a][0] - oy[b]);
                    if (dy < bestY) { bestY = dy; ny = oy[b] - ys[a][1]; guides[1] = { v: false, at: oy[b] }; }
                }
        }
        // grille 16 px quand aucun bord n'est proche
        if (bestX > snapDist) { nx = Math.round(x / 16) * 16; guides[0] = null; }
        if (bestY > snapDist) { ny = Math.round(y / 16) * 16; guides[1] = null; }
        const host = bounds ? bounds : parent;
        nx = Math.max(padX, Math.min(nx, host.width - width - padX));
        ny = Math.max(padTop, Math.min(ny, host.height - height - padBottom));
        if (host)
            host.guides = guides.filter(g => !!g);
        if (apply) {
            x = nx;
            y = ny;
        }
        return { x: nx, y: ny };
    }

    // barre d'outils
    Rectangle {
        visible: card.editMode
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 6
        height: 34
        radius: Tokens.rMd
        color: Qt.alpha(Theme.s4, 0.92)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 4
            spacing: 2
            Icon { name: card.typeDef.icon || "widgets"; size: 16; color: Theme.accent }
            Txt { role: "label"; text: card.typeDef.label; Layout.leftMargin: 6; Layout.fillWidth: true }
            IconButton {
                icon: card.style === "glass" ? "blur_on" : (card.style === "solid" ? "rectangle" : "crop_free")
                size: 26
                iconSize: 15
                tooltip: "Style : " + (card.style === "glass" ? "verre" : (card.style === "solid" ? "plein" : "nu")) + " (clic pour changer)"
                onClicked: WidgetStore.setProps(card.wid, { style: card.style === "glass" ? "solid" : (card.style === "solid" ? "bare" : "glass") })
            }
            IconButton {
                visible: Quickshell.screens.length > 1
                icon: "screen_share"
                size: 26
                iconSize: 15
                tooltip: "Envoyer sur l'autre écran"
                onClicked: {
                    const cur = card.entry.screen || (Quickshell.screens.length ? Quickshell.screens[0].name : "");
                    const other = Quickshell.screens.find(s => s.name !== cur);
                    if (other)
                        WidgetStore.moveToScreen(card.wid, other.name);
                }
            }
            IconButton {
                icon: card.entry.visible ? "visibility" : "visibility_off"
                size: 26
                iconSize: 15
                tooltip: card.entry.visible ? "Masquer" : "Afficher"
                onClicked: WidgetStore.toggleVisible(card.wid)
            }
            IconButton {
                icon: "content_copy"
                size: 26
                iconSize: 15
                tooltip: "Dupliquer"
                onClicked: WidgetStore.duplicate(card.wid)
            }
            IconButton {
                icon: "delete"
                variant: "danger"
                size: 26
                iconSize: 15
                tooltip: "Supprimer"
                onClicked: WidgetStore.remove(card.wid)
            }
        }
    }

    // poignée de redimensionnement
    MouseArea {
        id: resizeArea
        visible: card.editMode
        width: 22
        height: 22
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        cursorShape: Qt.SizeFDiagCursor
        z: 4
        property real sx: 0
        property real sy: 0
        property real sw: 0
        property real sh: 0

        onPressed: mouse => {
            const p = mapToItem(card.bounds, mouse.x, mouse.y);
            sx = p.x; sy = p.y; sw = card.width; sh = card.height;
            WidgetStore.bringToFront(card.wid);
        }
        onPositionChanged: mouse => {
            if (!pressed)
                return;
            const host = card.bounds ? card.bounds : card.parent;
            const p = mapToItem(host, mouse.x, mouse.y);
            const snap = v => Math.round(v / 8) * 8;
            card.width = Math.max(card.minW, Math.min(host.width - card.x - card.padX, snap(sw + p.x - sx)));
            card.height = Math.max(card.minH, Math.min(host.height - card.y - card.padBottom, snap(sh + p.y - sy)));
        }
        onReleased: {
            WidgetStore.setSize(card.wid, card.width, card.height);
            card.width = Qt.binding(() => card.entry.w);
            card.height = Qt.binding(() => card.entry.h);
        }

        Icon {
            anchors.centerIn: parent
            name: "open_in_full"
            size: 14
            rotation: 90
            color: Theme.accent
        }
    }
}
