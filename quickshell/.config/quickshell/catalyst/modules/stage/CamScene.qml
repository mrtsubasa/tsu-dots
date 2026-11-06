pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Éditeur de scène caméra : aperçu en direct, calques déplaçables, choix des
// sources (webcam, écrans, images) et filtre/réglages par calque. Toute
// modification est appliquée à chaud par cam_scene.py.
ColumnLayout {
    id: root
    spacing: 12

    readonly property var sel: Cam.layer(Cam.selected)

    function snap(v) {
        for (const s of [0, 0.5, 1])
            if (Math.abs(v - s) < 0.012)
                return s;
        return v;
    }

    // ---- diffusion ----
    Button {
        Layout.fillWidth: true
        variant: Cam.sceneOn ? "secondary" : "primary"
        icon: Cam.sceneOn ? "stop_circle" : "play_arrow"
        text: Cam.sceneOn ? "Arrêter la scène" : "Diffuser cette scène"
        onClicked: Cam.sceneOn ? Cam.stop() : Cam.start("scene")
    }

    // ---- aperçu + calques ----
    Rectangle {
        id: canvas
        Layout.fillWidth: true
        Layout.preferredHeight: width * 9 / 16
        radius: Tokens.rMd
        color: Theme.s1
        border.width: 1
        border.color: Theme.border
        clip: true

        // double tampon : on ne bascule que sur une image entièrement chargée
        property bool showA: true
        property int frame: 0
        Timer {
            interval: 250
            repeat: true
            running: Cam.sceneOn && canvas.visible
            onTriggered: {
                canvas.frame++;
                const url = "file://" + Cam.previewPath + "?" + canvas.frame;
                if (canvas.showA) imgB.source = url; else imgA.source = url;
            }
        }
        Image {
            id: imgA
            anchors.fill: parent
            cache: false
            asynchronous: true
            visible: Cam.sceneOn && canvas.showA
            onStatusChanged: if (status === Image.Ready) canvas.showA = true
        }
        Image {
            id: imgB
            anchors.fill: parent
            cache: false
            asynchronous: true
            visible: Cam.sceneOn && !canvas.showA
            onStatusChanged: if (status === Image.Ready) canvas.showA = false
        }

        Repeater {
            model: Cam.layerIds
            Item {
                id: box
                required property string modelData
                readonly property var l: Cam.layer(modelData)
                readonly property bool isSel: Cam.selected === modelData
                visible: l !== null && l.visible !== false
                x: l ? l.x * canvas.width : 0
                y: l ? l.y * canvas.height : 0
                width: l ? l.w * canvas.width : 0
                height: l ? l.h * canvas.height : 0
                z: Cam.layerIds.indexOf(modelData) + (isSel ? 100 : 0)

                Rectangle {
                    anchors.fill: parent
                    radius: box.l ? box.l.radius * Math.min(width, height) : 0
                    color: Cam.sceneOn ? "transparent" : Qt.alpha(Theme.accent, box.isSel ? 0.22 : 0.1)
                    border.width: box.isSel ? 2 : 1
                    border.color: box.isSel ? Theme.accent : Qt.alpha(Theme.text, Cam.sceneOn ? 0.25 : 0.4)
                }
                Column {
                    visible: !Cam.sceneOn
                    anchors.centerIn: parent
                    spacing: 2
                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: box.l ? Cam.sourceIcon(box.l.source) : ""
                        size: 18
                        color: Theme.text
                    }
                    Txt {
                        width: Math.min(implicitWidth, box.width - 8)
                        role: "caption"
                        elide: Text.ElideMiddle
                        text: box.l ? Cam.sourceLabel(box.l.source) : ""
                    }
                }
                // déplacement (avec aimantation bords/centre)
                MouseArea {
                    anchors.fill: parent
                    preventStealing: true
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    property real grabX: 0
                    property real grabY: 0
                    onPressed: mouse => {
                        Cam.selected = box.modelData;
                        grabX = mouse.x / canvas.width;
                        grabY = mouse.y / canvas.height;
                    }
                    onPositionChanged: mouse => {
                        if (!pressed) return;
                        const p = mapToItem(canvas, mouse.x, mouse.y);
                        let nx = p.x / canvas.width - grabX;
                        let ny = p.y / canvas.height - grabY;
                        const sx = root.snap(nx + box.l.w) - box.l.w;
                        const sy = root.snap(ny + box.l.h) - box.l.h;
                        nx = root.snap(nx) !== nx ? root.snap(nx) : sx;
                        ny = root.snap(ny) !== ny ? root.snap(ny) : sy;
                        Cam.updateLayer(box.modelData, { x: nx, y: ny });
                    }
                }
                // redimensionnement (coin bas-droit)
                Rectangle {
                    visible: box.isSel
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    width: 14
                    height: 14
                    radius: 3
                    color: Theme.accent
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        preventStealing: true
                        cursorShape: Qt.SizeFDiagCursor
                        onPositionChanged: mouse => {
                            if (!pressed) return;
                            const p = mapToItem(canvas, mouse.x, mouse.y);
                            Cam.updateLayer(box.modelData, {
                                w: Math.max(0.08, root.snap(p.x / canvas.width) - box.l.x),
                                h: Math.max(0.08, root.snap(p.y / canvas.height) - box.l.y)
                            });
                        }
                    }
                }
            }
        }

        Txt {
            visible: !Cam.layerIds.length
            anchors.centerIn: parent
            role: "caption"
            color: Theme.textFaint
            text: "Ajoute une source ci-dessous"
        }
    }

    // ---- dispositions rapides ----
    Txt { text: "Disposition"; role: "overline"; color: Theme.textFaint }
    Segmented {
        Layout.fillWidth: true
        compact: true
        model: [
            { id: "solo", label: "Seul" },
            { id: "pip", label: "Incrustation" },
            { id: "split", label: "Côte à côte" },
            { id: "grid", label: "Grille" }
        ]
        current: ""
        onSelected: id => Cam.arrange(id)
    }

    // ---- ajouter une source ----
    Txt { text: "Ajouter une source"; role: "overline"; color: Theme.textFaint }
    Flow {
        Layout.fillWidth: true
        spacing: 6
        Button { variant: "secondary"; icon: "videocam"; text: "Webcam"; onClicked: Cam.addLayer("cam") }
        Repeater {
            model: Cam.screens
            Button {
                required property string modelData
                variant: "secondary"
                icon: "desktop_windows"
                text: modelData
                onClicked: Cam.addLayer("screen:" + modelData)
            }
        }
        Button { variant: "secondary"; icon: "image"; text: "Image…"; onClicked: Cam.pickLayerImage("+") }
    }

    // ---- calques (le plus haut en premier) ----
    Txt { text: "Calques"; role: "overline"; color: Theme.textFaint; visible: Cam.layerIds.length > 0 }
    Repeater {
        model: Cam.layerIds.slice().reverse()
        Rectangle {
            id: row
            required property string modelData
            readonly property var l: Cam.layer(modelData)
            readonly property bool isSel: Cam.selected === modelData
            Layout.fillWidth: true
            implicitHeight: 40
            radius: Tokens.rMd
            color: isSel ? Qt.alpha(Theme.accent, 0.16) : Theme.s3
            border.width: 1
            border.color: isSel ? Theme.accent : Theme.border
            StateLayer {
                anchors.fill: parent
                radius: Tokens.rMd
                onClicked: Cam.selected = row.modelData
            }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 4
                spacing: 6
                Icon { name: row.l ? Cam.sourceIcon(row.l.source) : ""; size: 16; color: Theme.textSub }
                Txt {
                    Layout.fillWidth: true
                    role: "label"
                    elide: Text.ElideMiddle
                    text: row.l ? Cam.sourceLabel(row.l.source) : ""
                }
                IconButton {
                    size: 28
                    icon: row.l && row.l.visible !== false ? "visibility" : "visibility_off"
                    tooltip: "Afficher / masquer"
                    onClicked: Cam.updateLayer(row.modelData, { visible: row.l.visible === false })
                }
                IconButton { size: 28; icon: "arrow_upward"; tooltip: "Monter"; onClicked: Cam.moveLayer(row.modelData, 1) }
                IconButton { size: 28; icon: "arrow_downward"; tooltip: "Descendre"; onClicked: Cam.moveLayer(row.modelData, -1) }
                IconButton { size: 28; icon: "close"; variant: "danger"; tooltip: "Retirer"; onClicked: Cam.removeLayer(row.modelData) }
            }
        }
    }

    // ---- calque sélectionné ----
    ColumnLayout {
        visible: root.sel !== null
        Layout.fillWidth: true
        spacing: 8

        component Chip: Rectangle {
            id: chip
            property string label: ""
            property string iconName: ""
            property bool on: false
            signal clicked()
            implicitWidth: chipRow.implicitWidth + 20
            implicitHeight: 30
            radius: Tokens.rMd
            color: on ? Theme.accent : Theme.s3
            border.width: on ? 0 : 1
            border.color: Theme.border
            Row {
                id: chipRow
                anchors.centerIn: parent
                spacing: 5
                Icon {
                    visible: chip.iconName.length > 0
                    anchors.verticalCenter: parent.verticalCenter
                    name: chip.iconName
                    size: 14
                    color: chip.on ? Theme.onAccent : Theme.textSub
                }
                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    role: "caption"
                    color: chip.on ? Theme.onAccent : Theme.text
                    text: chip.label
                }
            }
            StateLayer {
                anchors.fill: parent
                radius: Tokens.rMd
                onClicked: chip.clicked()
            }
        }

        Divider { Layout.fillWidth: true }

        Txt { text: "Source du calque"; role: "overline"; color: Theme.textFaint }
        Flow {
            Layout.fillWidth: true
            spacing: 6
            Chip {
                label: "Webcam"
                iconName: "videocam"
                on: !!root.sel && root.sel.source === "cam"
                onClicked: Cam.updateLayer(Cam.selected, { source: "cam" })
            }
            Repeater {
                model: Cam.screens
                Chip {
                    required property string modelData
                    label: modelData
                    iconName: "desktop_windows"
                    on: !!root.sel && root.sel.source === "screen:" + modelData
                    onClicked: Cam.updateLayer(Cam.selected, { source: "screen:" + modelData })
                }
            }
            Chip {
                label: "Image…"
                iconName: "image"
                on: !!root.sel && root.sel.source.indexOf("image:") === 0
                onClicked: Cam.pickLayerImage(Cam.selected)
            }
        }

        Txt { text: "Filtre"; role: "overline"; color: Theme.textFaint }
        Flow {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: Cam.sceneFilters
                Chip {
                    required property var modelData
                    label: modelData.label
                    on: !!root.sel && (root.sel.filter || "none") === modelData.id
                    onClicked: Cam.updateLayer(Cam.selected, { filter: modelData.id })
                }
            }
        }

        Txt { text: "Réglages"; role: "overline"; color: Theme.textFaint }
        Slider {
            Layout.fillWidth: true
            icon: "brightness_6"
            maximum: 2
            value: root.sel ? (root.sel.brightness || 0) + 1 : 1
            valueText: "Luminosité " + Math.round((shown - 1) * 100)
            onMoved: v => Cam.updateLayer(Cam.selected, { brightness: v - 1 })
        }
        Slider {
            Layout.fillWidth: true
            icon: "contrast"
            maximum: 2
            value: root.sel && root.sel.contrast !== undefined ? root.sel.contrast : 1
            valueText: "Contraste " + Math.round(shown * 100) + "%"
            onMoved: v => Cam.updateLayer(Cam.selected, { contrast: v })
        }
        Slider {
            Layout.fillWidth: true
            icon: "palette"
            maximum: 2
            value: root.sel && root.sel.saturation !== undefined ? root.sel.saturation : 1
            valueText: "Saturation " + Math.round(shown * 100) + "%"
            onMoved: v => Cam.updateLayer(Cam.selected, { saturation: v })
        }
        Slider {
            Layout.fillWidth: true
            icon: "opacity"
            value: root.sel && root.sel.opacity !== undefined ? root.sel.opacity : 1
            valueText: "Opacité " + Math.round(shown * 100) + "%"
            onMoved: v => Cam.updateLayer(Cam.selected, { opacity: v })
        }
        Slider {
            Layout.fillWidth: true
            icon: "rounded_corner"
            maximum: 0.5
            step: 0.02
            value: root.sel ? (root.sel.radius || 0) : 0
            valueText: "Arrondi " + Math.round(shown * 200) + "%"
            onMoved: v => Cam.updateLayer(Cam.selected, { radius: v })
        }

        RowLayout {
            Layout.fillWidth: true
            Txt { Layout.fillWidth: true; role: "label"; text: "Miroir" }
            Toggle {
                checked: !!root.sel && !!root.sel.mirror
                onToggled: v => Cam.updateLayer(Cam.selected, { mirror: v })
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Txt { Layout.fillWidth: true; role: "label"; text: "Image entière (bandes si besoin)" }
            Toggle {
                checked: !!root.sel && root.sel.fit === "contain"
                onToggled: v => Cam.updateLayer(Cam.selected, { fit: v ? "contain" : "cover" })
            }
        }
        RowLayout {
            Layout.fillWidth: true
            visible: !!root.sel && root.sel.source === "cam"
            Txt { Layout.fillWidth: true; role: "label"; text: "Détourer (retire le fond, GPU)" }
            Toggle {
                checked: !!root.sel && !!root.sel.cutout
                onToggled: v => Cam.updateLayer(Cam.selected, { cutout: v })
            }
        }
    }
}
