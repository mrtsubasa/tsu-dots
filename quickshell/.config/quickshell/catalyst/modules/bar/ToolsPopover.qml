pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import "../../components"

Item {
    id: root
    property string page: "hub"
    implicitWidth: 328
    implicitHeight: page === "scripts" ? 420 : Math.min(380, 56 + grid.implicitHeight + 24)

    readonly property var catalog: [
        { key: "ai", icon: "󱙺", label: "IA" },
        { key: "vm", icon: "󰆧", label: "VM" },
        { key: "scripts", icon: "󰯁", label: "Scripts" },
        { key: "chat", icon: "󰍩", label: "Chat" },
        { key: "bots", icon: "󰊠", label: "Bots" },
        { key: "ops", icon: "󰗚", label: "Ops" },
        { key: "wall", icon: "󰸉", label: "Murs" },
        { key: "clip", icon: "󰅌", label: "Clip" },
        { key: "binds", icon: "󰌌", label: "Binds" },
        { key: "pkgs", icon: "󰏖", label: "Shop" }
    ]

    readonly property var tools: {
        const mods = BarCfg.modules;
        const all = root.catalog;
        const out = [];
        for (let i = 0; i < all.length; i++) {
            if (mods[all[i].key] !== false)
                out.push(all[i]);
        }
        return out;
    }

    onPageChanged: if (page === "scripts") {
        ScriptsData.refresh("");
        search.forceActiveFocus();
    }

    Surface {
        anchors.fill: parent
        elev: 3
        radius: Tokens.rLg
        photo: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text {
                    visible: root.page === "scripts"
                    text: "󰁍"
                    font.family: Theme.font
                    font.pixelSize: 14
                    color: Theme.primary
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.page = "hub"
                    }
                }
                Text {
                    text: root.page === "scripts" ? "Scripts" : "Outils"
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: Theme.primary
                }
                Item { Layout.fillWidth: true }
                Text {
                    visible: root.page === "scripts"
                    text: String(ScriptsData.scripts.length)
                    font.family: Theme.font
                    font.pixelSize: 11
                    color: Theme.inkMuted
                }
                Text {
                    visible: root.page === "scripts"
                    text: "󰝖"
                    font.family: Theme.font
                    font.pixelSize: 14
                    color: Theme.inkMuted
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ScriptsData.openFolder()
                    }
                }
            }

            Grid {
                id: grid
                visible: root.page === "hub"
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                columns: 3
                columnSpacing: 6
                rowSpacing: 6

                Repeater {
                    model: root.tools
                    delegate: Rectangle {
                        required property var modelData
                        width: 96
                        height: 72
                        radius: 18
                        color: area.containsMouse ? Qt.alpha(Theme.primary, 0.16) : Qt.alpha(Theme.surfaceContainerLow, 0.55)
                        border.width: 1
                        border.color: area.containsMouse ? Theme.primary : Theme.hairline
                        Column {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.icon
                                font.family: Theme.font
                                font.pixelSize: 20
                                color: Theme.primary
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                font.family: Theme.font
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: Theme.ink
                            }
                        }
                        MouseArea {
                            id: area
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.key === "scripts") {
                                    root.page = "scripts";
                                    return;
                                }
                                PanelService.hidePopover();
                                PanelService.toggle(modelData.key, PanelService.popoverGeom ? PanelService.popoverGeom.output : "");
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: root.page === "scripts"
                Layout.fillWidth: true
                height: 36
                radius: 10
                color: Theme.surfaceContainerLowest
                border.width: 1
                border.color: search.activeFocus ? Theme.primary : Theme.hairline
                TextInput {
                    id: search
                    anchors.fill: parent
                    anchors.margins: 10
                    color: Theme.ink
                    font.family: Theme.font
                    font.pixelSize: 13
                    verticalAlignment: Text.AlignVCenter
                    onTextChanged: ScriptsData.refresh(text)
                }
                Text {
                    visible: search.text.length === 0 && !search.activeFocus
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Rechercher…"
                    font.family: Theme.font
                    font.pixelSize: 13
                    color: Theme.inkMuted
                }
            }

            Flickable {
                visible: root.page === "scripts"
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentHeight: scriptsCol.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: scriptsCol
                    width: parent.width
                    spacing: 5
                    Repeater {
                        model: ScriptsData.scripts
                        delegate: Rectangle {
                            id: srow
                            required property var modelData
                            width: scriptsCol.width
                            height: 46
                            radius: 10
                            color: rowArea.containsMouse ? Qt.alpha(Theme.primary, 0.14) : Qt.alpha(Theme.surfaceContainerLow, 0.55)
                            border.width: 1
                            border.color: Theme.hairline
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 8
                                spacing: 8
                                Text {
                                    text: "󰆍"
                                    font.family: Theme.font
                                    font.pixelSize: 16
                                    color: Theme.primary
                                }
                                Column {
                                    Layout.fillWidth: true
                                    Text {
                                        width: parent.width
                                        text: srow.modelData.name
                                        font.family: Theme.font
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        color: Theme.ink
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        width: parent.width
                                        text: srow.modelData.dir
                                        font.family: Theme.font
                                        font.pixelSize: 10
                                        color: Theme.inkMuted
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                            MouseArea {
                                id: rowArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: event => {
                                    if (event.button === Qt.RightButton)
                                        ScriptsData.term(srow.modelData.path);
                                    else
                                        ScriptsData.run(srow.modelData.path);
                                    PanelService.hidePopover();
                                }
                            }
                        }
                    }
                }
            }

            Text {
                visible: root.page === "hub" && root.tools.length === 0
                Layout.alignment: Qt.AlignHCenter
                text: "Aucun outil"
                font.family: Theme.font
                font.pixelSize: 12
                color: Theme.inkMuted
            }

            Text {
                visible: root.page === "scripts" && ScriptsData.scripts.length === 0
                Layout.alignment: Qt.AlignHCenter
                text: "Aucun script"
                font.family: Theme.font
                font.pixelSize: 12
                color: Theme.inkMuted
            }
        }
    }
}
