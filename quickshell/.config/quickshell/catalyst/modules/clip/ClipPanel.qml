pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.rice
import "../../components"

Scope {
    Variants {
        model: Quickshell.screens
        SideShell {
            id: shell
            required property var modelData
            screen: modelData
            panelId: "clip"
            panelWidth: 480
            panelHeight: 640
            corner: "br"

            Connections {
                target: shell
                function onVisibleChanged() {
                    if (shell.visible)
                        clipProc.running = true;
                }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                PanelHead {
                    icon: "󰅌"
                    title: "Clipboard"
                    closable: true
                    onClosed: PanelService.hide()
                    IconBtn { icon: "󰑐"; onClicked: clipProc.running = true }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: 22
                    color: Theme.surfaceContainerLowest
                    border.width: 1
                    border.color: filter.activeFocus ? Theme.primary : Theme.hairline
                    TextInput {
                        id: filter
                        anchors.fill: parent
                        anchors.margins: 10
                        color: Theme.ink
                        font.family: Theme.font
                        font.pixelSize: 13
                        onTextChanged: clipProc.running = true
                    }
                    Text {
                        visible: filter.text.length === 0
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Filtrer l’historique…"
                        font.family: Theme.font
                        font.pixelSize: 13
                        color: Theme.inkMuted
                    }
                }

                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 6
                    model: clipProc.items
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: ListView.view.width
                        height: 52
                        radius: 22
                        color: Theme.layer2
                        border.width: 1
                        border.color: Theme.hairline
                        Text {
                            anchors.fill: parent
                            anchors.margins: 12
                            text: modelData.text
                            textFormat: Text.PlainText
                            font.family: Theme.font
                            font.pixelSize: 12
                            color: Theme.ink
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            verticalAlignment: Text.AlignVCenter
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const id = String(modelData.raw || "");
                                if (!id.length)
                                    return;
                                Quickshell.execDetached([
                                    "bash", "-lc",
                                    "cliphist decode " + JSON.stringify(id) + " | wl-copy"
                                ]);
                                PanelService.hide();
                            }
                        }
                    }
                }
            }

            Process {
                id: clipProc
                command: ["cliphist", "list"]
                property string buf: ""
                property var items: []
                stdout: SplitParser { onRead: data => clipProc.buf += data }
                onRunningChanged: if (running) buf = ""
                onExited: {
                    const q = filter.text.trim().toLowerCase();
                    const lines = buf.split("\n");
                    const out = [];
                    for (let i = 0; i < lines.length && out.length < 60; i++) {
                        const line = lines[i];
                        if (!line.length)
                            continue;
                        const tab = line.indexOf("\t");
                        const raw = tab >= 0 ? line.slice(0, tab) : line;
                        let text = tab >= 0 ? line.slice(tab + 1) : line;
                        if (text.indexOf("[[ binary data") === 0)
                            text = "Image / binaire";
                        text = text.replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F]/g, " ");
                        if (text.length > 200)
                            text = text.slice(0, 200);
                        if (q && text.toLowerCase().indexOf(q) < 0)
                            continue;
                        out.push({ raw: raw, text: text });
                    }
                    items = out;
                }
            }
        }
    }
}
