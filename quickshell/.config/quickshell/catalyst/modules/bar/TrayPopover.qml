pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs.rice
import "../../components"

Item {
    id: root
    implicitWidth: 328
    implicitHeight: menuOpen ? 460 : Math.min(420, 56 + grid.implicitHeight + 24)

    property bool menuOpen: false
    property var menuHandle: null
    property var menuStack: []
    property string menuTitle: ""
    readonly property int menuCount: {
        const c = opener.children;
        if (!c)
            return 0;
        if (c.count !== undefined)
            return c.count;
        if (c.values)
            return c.values.length;
        return 0;
    }

    function iconSrc(icon) {
        const s = icon || "";
        if (!s)
            return "";
        if (s.indexOf("?path=") >= 0) {
            const split = s.split("?path=");
            const name = split[0].substring(split[0].lastIndexOf("/") + 1);
            return "file://" + split[1] + "/" + name;
        }
        if (s.startsWith("/"))
            return "file://" + s;
        if (s.startsWith("file://") || s.startsWith("image://"))
            return s;
        return "image://icon/" + s;
    }

    function labelOf(item) {
        return (item.tooltipTitle || item.title || item.id || "app").toString();
    }

    function clean(t) {
        return String(t || "").replace(/&/g, "").replace(/_/g, "");
    }

    function openMenu(item) {
        if (item && item.hasMenu && item.menu) {
            menuHandle = item.menu;
            menuStack = [];
            menuTitle = labelOf(item);
            menuOpen = true;
            return;
        }
        if (item)
            item.secondaryActivate();
    }

    function closeMenu() {
        menuOpen = false;
        menuHandle = null;
        menuStack = [];
        menuTitle = "";
    }

    function backMenu() {
        if (!menuStack.length) {
            closeMenu();
            return;
        }
        const prev = menuStack[menuStack.length - 1];
        menuStack = menuStack.slice(0, menuStack.length - 1);
        menuHandle = prev;
    }

    function clickEntry(entry) {
        if (!entry || entry.isSeparator || entry.enabled === false)
            return;
        if (entry.hasChildren) {
            menuStack = menuStack.concat([menuHandle]);
            menuHandle = entry;
            return;
        }
        entry.triggered();
        closeMenu();
        PanelService.hidePopover();
    }

    QsMenuOpener {
        id: opener
        menu: root.menuHandle
    }

    Surface {
        anchors.fill: parent
        elev: 3
        radius: Tokens.rLg
        photo: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12
            visible: !root.menuOpen

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Tray"
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: Theme.primary
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: String(SystemTray.items.values.length)
                    font.family: Theme.font
                    font.pixelSize: 11
                    color: Theme.inkMuted
                }
            }

            Grid {
                id: grid
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                columns: 4
                columnSpacing: 6
                rowSpacing: 6

                Repeater {
                    model: SystemTray.items

                    delegate: Rectangle {
                        id: cell
                        required property var modelData
                        width: 72
                        height: 70
                        radius: 18
                        color: area.containsMouse ? Qt.alpha(Theme.primary, 0.16) : Qt.alpha(Theme.surfaceContainerLow, 0.55)
                        border.width: 1
                        border.color: area.containsMouse ? Theme.primary : Theme.hairline

                        Column {
                            anchors.centerIn: parent
                            spacing: 6
                            width: parent.width - 8
                            Image {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 24
                                height: 24
                                source: root.iconSrc(cell.modelData.icon)
                                sourceSize.width: 24
                                sourceSize.height: 24
                                asynchronous: true
                                smooth: true
                            }
                            Text {
                                width: parent.width
                                text: root.labelOf(cell.modelData)
                                font.family: Theme.font
                                font.pixelSize: 10
                                color: Theme.ink
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        MouseArea {
                            id: area
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            onClicked: event => {
                                if (event.button === Qt.RightButton) {
                                    root.openMenu(cell.modelData);
                                } else if (event.button === Qt.MiddleButton) {
                                    cell.modelData.secondaryActivate();
                                } else if (cell.modelData.onlyMenu) {
                                    root.openMenu(cell.modelData);
                                } else {
                                    cell.modelData.activate();
                                    PanelService.hidePopover();
                                }
                            }
                        }
                    }
                }
            }

            Text {
                visible: SystemTray.items.values.length === 0
                Layout.alignment: Qt.AlignHCenter
                text: "Aucune icône"
                font.family: Theme.font
                font.pixelSize: 12
                color: Theme.inkMuted
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10
            visible: root.menuOpen

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    text: "󰁍"
                    font.family: Theme.font
                    font.pixelSize: 15
                    color: backMouse.containsMouse ? Theme.primary : Theme.ink
                    MouseArea {
                        id: backMouse
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.backMenu()
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: root.menuTitle
                    font.family: Theme.uiFont
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: Theme.ink
                    elide: Text.ElideRight
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentHeight: menuCol.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: menuCol
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: opener.children
                        delegate: Item {
                            id: row
                            required property var modelData
                            width: menuCol.width
                            height: modelData.isSeparator ? 10 : 36
                            opacity: modelData.enabled === false ? 0.45 : 1

                            Rectangle {
                                visible: row.modelData.isSeparator
                                anchors.centerIn: parent
                                width: parent.width - 8
                                height: 1
                                color: Theme.hairline
                            }

                            Rectangle {
                                visible: !row.modelData.isSeparator
                                anchors.fill: parent
                                radius: 10
                                color: rowMouse.containsMouse ? Qt.alpha(Theme.primary, 0.16) : Qt.alpha(Theme.surfaceContainerLow, 0.45)
                                border.width: 1
                                border.color: rowMouse.containsMouse ? Theme.primary : Theme.hairline

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Rectangle {
                                        visible: row.modelData.buttonType !== QsMenuButtonType.None
                                        Layout.preferredWidth: 12
                                        Layout.preferredHeight: 12
                                        radius: row.modelData.buttonType === QsMenuButtonType.RadioButton ? 6 : 3
                                        color: "transparent"
                                        border.width: 1
                                        border.color: Theme.primary
                                        Rectangle {
                                            visible: row.modelData.checkState === Qt.Checked
                                            anchors.centerIn: parent
                                            width: 6
                                            height: 6
                                            radius: parent.radius - 1
                                            color: Theme.primary
                                        }
                                    }

                                    Image {
                                        visible: (row.modelData.icon || "").length > 0
                                        Layout.preferredWidth: 16
                                        Layout.preferredHeight: 16
                                        source: root.iconSrc(row.modelData.icon)
                                        sourceSize.width: 16
                                        sourceSize.height: 16
                                        asynchronous: true
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: root.clean(row.modelData.text)
                                        font.family: Theme.uiFont
                                        font.pixelSize: 12
                                        color: Theme.ink
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        visible: row.modelData.hasChildren
                                        text: "󰅂"
                                        font.family: Theme.font
                                        font.pixelSize: 14
                                        color: Theme.primary
                                    }
                                }

                                MouseArea {
                                    id: rowMouse
                                    anchors.fill: parent
                                    hoverEnabled: row.modelData.enabled !== false
                                    enabled: !row.modelData.isSeparator && row.modelData.enabled !== false
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.clickEntry(row.modelData)
                                }
                            }
                        }
                    }
                }
            }

            Text {
                visible: root.menuCount === 0
                Layout.alignment: Qt.AlignHCenter
                text: "aucune option"
                font.family: Theme.uiFont
                font.pixelSize: 11
                color: Theme.inkMuted
            }
        }
    }
}
