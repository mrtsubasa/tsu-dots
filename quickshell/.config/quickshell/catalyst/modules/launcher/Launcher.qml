pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.rice
import "../../components"

Scope {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            visible: PanelService.active === "launcher" && PanelService.onScreen(modelData)
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.namespace: "catalyst-panel"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            anchors { top: true; bottom: true; left: true; right: true }

            property real appear: visible ? 1 : 0
            Behavior on appear { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }

            onVisibleChanged: {
                if (visible) {
                    LauncherData.reset();
                    search.focus = true;
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: PanelService.hide()
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.scrim
                opacity: win.appear
            }

            Item {
                id: card
                width: Math.min(780, parent.width - 40)
                height: Math.min(680, parent.height - 56)
                anchors.horizontalCenter: parent.horizontalCenter
                y: (parent.height - height) * 0.42 + (1 - win.appear) * 36
                opacity: win.appear
                scale: 0.96 + win.appear * 0.04
                transformOrigin: Item.Center

                MouseArea {
                    anchors.fill: parent
                    onWheel: event => {
                        if (event.angleDelta.y < 0)
                            LauncherData.nextPage();
                        else
                            LauncherData.prevPage();
                        event.accepted = true;
                    }
                }

                Surface {
                    anchors.fill: parent
                    elev: 3
                    photo: true
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 14

                    Rectangle {
                        Layout.fillWidth: true
                        height: 52
                        radius: 22
                        color: Qt.alpha(Theme.surfaceContainerLowest, 0.72)
                        border.width: 1
                        border.color: search.activeFocus ? Theme.primary : Qt.alpha(Theme.hairline, 0.8)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 8
                            spacing: 10
                            z: 1
                            Text {
                                text: "󰍉"
                                font.family: Theme.font
                                font.pixelSize: 18
                                color: Theme.primary
                            }
                            TextInput {
                                id: search
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: Theme.ink
                                font.family: Theme.uiFont
                                font.pixelSize: 16
                                verticalAlignment: Text.AlignVCenter
                                onTextChanged: LauncherData.setQuery(text)
                                Keys.onEscapePressed: PanelService.hide()
                                Keys.onReturnPressed: LauncherData.launchSelected()
                                Keys.onDownPressed: LauncherData.moveSel(0, 1)
                                Keys.onUpPressed: LauncherData.moveSel(0, -1)
                                Keys.onPressed: event => {
                                    if (text.length > 0)
                                        return;
                                    if (event.key === Qt.Key_Left) {
                                        LauncherData.moveSel(-1, 0);
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Right) {
                                        LauncherData.moveSel(1, 0);
                                        event.accepted = true;
                                    }
                                }
                            }
                            Text {
                                visible: LauncherData.resultCount > 0
                                text: LauncherData.resultCount
                                font.family: Theme.uiFont
                                font.pixelSize: 12
                                color: Theme.inkMuted
                            }
                            IconBtn { icon: "󰅖"; accent: Theme.inkMuted; onClicked: PanelService.hide() }
                        }

                        Text {
                            visible: search.text.length === 0
                            z: 0
                            anchors.left: parent.left
                            anchors.leftMargin: 46
                            anchors.verticalCenter: parent.verticalCenter
                            text: "App, jeu, outil, BlackArch…"
                            font.family: Theme.uiFont
                            font.pixelSize: 15
                            color: Theme.inkMuted
                        }
                    }

                    Flickable {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        clip: true
                        contentWidth: catRow.implicitWidth
                        boundsBehavior: Flickable.StopAtBounds
                        Row {
                            id: catRow
                            spacing: 6
                            Repeater {
                                model: LauncherData.categories
                                delegate: Rectangle {
                                    id: chip
                                    required property var modelData
                                    readonly property bool on: LauncherData.category === modelData.id || (modelData.id === "sec" && LauncherData.baMode)
                                    height: 36
                                    width: on ? chipRow.implicitWidth + 18 : 36
                                    radius: 18
                                    color: on ? Theme.primary : Qt.alpha(Theme.surfaceContainerHigh, 0.55)
                                    border.width: on ? 0 : 1
                                    border.color: Theme.hairline
                                    Row {
                                        id: chipRow
                                        anchors.centerIn: parent
                                        spacing: 6
                                        Text {
                                            text: chip.modelData.glyph
                                            font.family: Theme.font
                                            font.pixelSize: 13
                                            color: chip.on ? Theme.inkPrimary : Theme.ink
                                        }
                                        Text {
                                            visible: chip.on
                                            text: chip.modelData.label
                                            font.family: Theme.uiFont
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                            color: Theme.inkPrimary
                                        }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: LauncherData.setCategory(chip.modelData.id)
                                    }
                                }
                            }
                        }
                    }

                    Flickable {
                        visible: LauncherData.baMode
                        Layout.fillWidth: true
                        implicitHeight: visible ? 30 : 0
                        clip: true
                        contentWidth: baRow.implicitWidth
                        boundsBehavior: Flickable.StopAtBounds
                        Row {
                            id: baRow
                            spacing: 5
                            Repeater {
                                model: LauncherData.baCats
                                delegate: Rectangle {
                                    id: baChip
                                    required property var modelData
                                    readonly property bool on: LauncherData.category === modelData.id
                                    height: 28
                                    width: baLab.implicitWidth + 16
                                    radius: 14
                                    color: on ? Qt.alpha(Theme.tertiary, 0.28) : "transparent"
                                    border.width: 1
                                    border.color: on ? Theme.tertiary : Qt.alpha(Theme.tertiary, 0.22)
                                    Text {
                                        id: baLab
                                        anchors.centerIn: parent
                                        text: baChip.modelData.label
                                        font.family: Theme.uiFont
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        color: baChip.on ? Theme.tertiary : Theme.inkMuted
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: LauncherData.setCategory(baChip.modelData.id)
                                    }
                                }
                            }
                        }
                    }

                    Flickable {
                        visible: !LauncherData.searching && LauncherData.resultCount > 0
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentHeight: grid.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds
                        Grid {
                            id: grid
                            width: parent.width
                            columns: LauncherData.cols
                            Repeater {
                                model: LauncherData.pageApps
                                delegate: Item {
                                    id: cell
                                    required property var modelData
                                    required property int index
                                    width: grid.width / LauncherData.cols
                                    height: 118
                                    readonly property bool sel: index === LauncherData.selected
                                    readonly property bool live: LauncherData.isRunning(modelData)

                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        radius: 22
                                        color: sel ? Qt.alpha(Theme.primary, 0.16) : (cellHover.containsMouse ? Qt.alpha(Theme.primary, 0.08) : Qt.alpha(Theme.surfaceContainerLow, 0.28))
                                        border.width: sel || live ? 1 : 0
                                        border.color: live && !sel ? Theme.success : Theme.primary

                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 8
                                            width: parent.width - 12
                                            AppIcon {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                iconName: cell.modelData.icon || ""
                                                appId: cell.modelData.id || ""
                                                label: cell.modelData.name || ""
                                                size: 48
                                                plain: true
                                            }
                                            Text {
                                                width: parent.width
                                                text: cell.modelData.name || ""
                                                font.family: Theme.uiFont
                                                font.pixelSize: 11
                                                font.weight: Font.DemiBold
                                                color: Theme.ink
                                                elide: Text.ElideRight
                                                wrapMode: Text.Wrap
                                                maximumLineCount: 2
                                                horizontalAlignment: Text.AlignHCenter
                                            }
                                        }

                                        Rectangle {
                                            visible: cell.live
                                            width: 8
                                            height: 8
                                            radius: 4
                                            color: Theme.success
                                            anchors.top: parent.top
                                            anchors.right: parent.right
                                            anchors.margins: 10
                                        }
                                    }

                                    MouseArea {
                                        id: cellHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: LauncherData.selected = cell.index
                                        onClicked: LauncherData.launch(cell.modelData)
                                    }
                                }
                            }
                        }
                    }

                    Flickable {
                        visible: LauncherData.searching && LauncherData.resultCount > 0
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentHeight: listCol.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds
                        Column {
                            id: listCol
                            width: parent.width
                            spacing: 4
                            Repeater {
                                model: LauncherData.pageApps
                                delegate: Rectangle {
                                    id: row
                                    required property var modelData
                                    required property int index
                                    width: listCol.width
                                    height: 56
                                    radius: 14
                                    readonly property bool sel: index === LauncherData.selected
                                    readonly property bool live: LauncherData.isRunning(modelData)
                                    color: sel ? Qt.alpha(Theme.primary, 0.14) : (rowHover.containsMouse ? Qt.alpha(Theme.primary, 0.06) : "transparent")
                                    border.width: sel ? 1 : 0
                                    border.color: Theme.primary

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 14
                                        spacing: 12
                                        AppIcon {
                                            iconName: row.modelData.icon || ""
                                            appId: row.modelData.id || ""
                                            label: row.modelData.name || ""
                                            size: 36
                                            plain: true
                                        }
                                        Column {
                                            Layout.fillWidth: true
                                            spacing: 2
                                            Text {
                                                width: parent.width
                                                text: row.modelData.name || ""
                                                font.family: Theme.uiFont
                                                font.pixelSize: 14
                                                font.weight: Font.DemiBold
                                                color: Theme.ink
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                width: parent.width
                                                visible: (row.modelData.comment || row.modelData.genericName || "").length > 0
                                                text: row.modelData.comment || row.modelData.genericName || ""
                                                font.family: Theme.uiFont
                                                font.pixelSize: 11
                                                color: Theme.inkMuted
                                                elide: Text.ElideRight
                                            }
                                        }
                                        Rectangle {
                                            visible: row.live
                                            width: 8
                                            height: 8
                                            radius: 4
                                            color: Theme.success
                                        }
                                    }

                                    MouseArea {
                                        id: rowHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: LauncherData.selected = row.index
                                        onClicked: LauncherData.launch(row.modelData)
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        visible: LauncherData.resultCount === 0
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Text {
                            anchors.centerIn: parent
                            text: "Aucun résultat"
                            font.family: Theme.uiFont
                            font.pixelSize: 14
                            color: Theme.inkMuted
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        IconBtn {
                            visible: LauncherData.pageCount > 1
                            icon: "󰁍"
                            onClicked: LauncherData.prevPage()
                        }
                        Text {
                            text: LauncherData.pageCount > 1
                                  ? (LauncherData.safePage + "  /  " + LauncherData.pageCount)
                                  : ""
                            font.family: Theme.uiFont
                            font.pixelSize: 12
                            color: Theme.inkMuted
                        }
                        IconBtn {
                            visible: LauncherData.pageCount > 1
                            icon: "󰁔"
                            onClicked: LauncherData.nextPage()
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: LauncherData.resultCount === 1 ? "1 app" : (LauncherData.resultCount + " apps")
                            font.family: Theme.uiFont
                            font.pixelSize: 12
                            color: Theme.inkMuted
                        }
                    }
                }
            }
        }
    }
}
