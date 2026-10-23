pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice

Item {
    id: root
    property var hostWin: null
    property bool overlay: false
    property int tab: 0
    property int monthOffset: 0

    readonly property var tabs: [
        { icon: "󰋜", lab: "Accueil" },
        { icon: "󰝚", lab: "Média" },
        { icon: "󰓅", lab: "Perf" },
        { icon: "󰡉", lab: "Bureaux" }
    ]
    readonly property var monthCells: {
        root.monthOffset;
        return root.cells();
    }
    readonly property date viewMonth: {
        root.monthOffset;
        const n = new Date();
        return new Date(n.getFullYear(), n.getMonth() + root.monthOffset, 1);
    }
    readonly property real mediaProgress: {
        const len = Players.length;
        if (len <= 0)
            return 0;
        return Math.max(0, Math.min(1, Players.position / len));
    }

    function go(name) {
        if (overlay)
            PanelService.show(name, hostWin);
        else {
            PanelService.hidePopover();
            PanelService.show(name, hostWin);
        }
    }

    function close() {
        if (overlay)
            PanelService.hide();
        else
            PanelService.hidePopover();
    }

    function fmt(sec) {
        if (!isFinite(sec) || sec < 0)
            sec = 0;
        const m = Math.floor(sec / 60);
        const s = Math.floor(sec % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    function cells() {
        const d = viewMonth;
        const start = (d.getDay() + 6) % 7;
        const days = new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate();
        const out = [];
        for (let i = 0; i < start; i++)
            out.push(0);
        for (let i = 1; i <= days; i++)
            out.push(i);
        while (out.length < 42)
            out.push(0);
        return out;
    }

    function monthNum() {
        const n = viewMonth.getMonth() + 1;
        return (n < 10 ? "0" : "") + n;
    }

    function weekdayNow() {
        return ["dimanche", "lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi"][new Date().getDay()];
    }

    function winsOn(wsId) {
        const all = Niri.windows;
        const out = [];
        for (let i = 0; i < all.length; i++) {
            if (all[i].workspace_id === wsId)
                out.push(all[i]);
        }
        return out;
    }

    function winLine(wsId) {
        const wins = winsOn(wsId);
        if (!wins.length)
            return "vide";
        let s = "";
        for (let i = 0; i < Math.min(wins.length, 6); i++) {
            if (i)
                s += "\n";
            s += (wins[i].app_id || "app") + "  ·  " + (wins[i].title || "");
        }
        return s;
    }

    component VFader: Item {
        id: vf
        property real value: 0
        property bool dimmed: false
        property string icon: ""
        signal moved(real v)
        implicitWidth: 36
        Layout.fillHeight: true

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 10
            height: parent.height - 36
            y: 4
            radius: 5
            color: Qt.alpha(Theme.ink, 0.14)
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.height * Math.max(0, Math.min(1, vf.dimmed ? 0 : vf.value))
                radius: 5
                color: Theme.primary
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: Math.max(0, Math.min(parent.height - 14, (1 - (vf.dimmed ? 0 : vf.value)) * parent.height - 7))
                width: 14
                height: 14
                radius: 7
                color: Theme.ink
                border.width: 2
                border.color: Theme.primary
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            text: vf.icon
            font.family: Theme.font
            font.pixelSize: 14
            color: vf.dimmed ? Theme.error : Theme.ink
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: event => vf.moved(Math.max(0, Math.min(1, 1 - event.y / height)))
            onPositionChanged: event => {
                if (pressed)
                    vf.moved(Math.max(0, Math.min(1, 1 - event.y / height)));
            }
            onWheel: event => {
                vf.moved(Math.max(0, Math.min(1, vf.value + (event.angleDelta.y > 0 ? 0.05 : -0.05))));
                event.accepted = true;
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: 4
                delegate: Rectangle {
                    id: tabBtn
                    required property int index
                    readonly property string tIcon: index === 0 ? "󰋜" : (index === 1 ? "󰝚" : (index === 2 ? "󰓅" : "󰡉"))
                    readonly property string tLab: index === 0 ? "Accueil" : (index === 1 ? "Média" : (index === 2 ? "Perf" : "Bureaux"))
                    readonly property bool on: root.tab === index
                    Layout.preferredHeight: 36
                    implicitWidth: tabRow.implicitWidth + 22
                    radius: 18
                    color: on ? Qt.alpha(Theme.primary, 0.22) : (tabHov.containsMouse ? Theme.hover : "transparent")
                    Row {
                        id: tabRow
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: tabBtn.tIcon
                            font.family: Theme.font
                            font.pixelSize: 14
                            color: tabBtn.on ? Theme.primary : Theme.inkMuted
                        }
                        Text {
                            text: tabBtn.tLab
                            font.family: Theme.uiFont
                            font.pixelSize: 12
                            font.weight: tabBtn.on ? Font.DemiBold : Font.Medium
                            color: tabBtn.on ? Theme.ink : Theme.inkMuted
                        }
                    }
                    MouseArea {
                        id: tabHov
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.tab = tabBtn.index
                    }
                }
            }
            Item { Layout.fillWidth: true }
            Text {
                text: SysInfo.clock
                font.family: Theme.uiFont
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: Theme.inkMuted
            }
            IconBtn {
                visible: root.overlay
                icon: "󰅖"
                onClicked: root.close()
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.tab

            ColumnLayout {
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 148
                    spacing: 12

                    SoftCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Row {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 14
                            Item {
                                width: 72
                                height: 72
                                anchors.verticalCenter: parent.verticalCenter
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 72
                                    height: 72
                                    radius: 36
                                    color: Qt.alpha(Theme.primary, 0.16)
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: Weather.ready ? Weather.glyph : "󰖕"
                                    font.family: Theme.font
                                    font.pixelSize: 34
                                    color: Theme.primary
                                }
                            }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                Text {
                                    text: Weather.ready ? (Weather.temp + "°C") : "—"
                                    font.family: Theme.uiFont
                                    font.pixelSize: 28
                                    font.weight: Font.Black
                                    color: Theme.ink
                                }
                                Text {
                                    text: Weather.ready ? Weather.desc : "météo…"
                                    font.family: Theme.uiFont
                                    font.pixelSize: 13
                                    color: Theme.inkMuted
                                    font.capitalization: Font.Capitalize
                                }
                                Text {
                                    text: Weather.city
                                    font.family: Theme.uiFont
                                    font.pixelSize: 11
                                    color: Theme.inkMuted
                                }
                            }
                        }
                    }

                    SoftCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        MouseArea {
                            anchors.fill: parent
                            z: 0
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.close();
                                PanelService.showPopover("profile", root.hostWin, null);
                            }
                        }
                        RowLayout {
                            z: 1
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 12
                            Rectangle {
                                Layout.preferredWidth: 72
                                Layout.preferredHeight: 72
                                radius: Identity.avatarShape === "square" ? 8 : (Identity.avatarShape === "soft" ? 16 : 36)
                                clip: true
                                color: Theme.primary
                                border.width: 2
                                border.color: Qt.alpha(Theme.tertiary, 0.8)
                                Image {
                                    visible: Identity.hasAvatar
                                    anchors.fill: parent
                                    source: Identity.avatar ? "file://" + Identity.avatar : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                }
                                Text {
                                    visible: !Identity.hasAvatar
                                    anchors.centerIn: parent
                                    text: Identity.userInitial
                                    font.pixelSize: 24
                                    font.weight: Font.Black
                                    color: Theme.inkPrimary
                                }
                            }
                            Column {
                                Layout.fillWidth: true
                                spacing: 4
                                Text {
                                    text: Identity.userName
                                    font.family: Theme.uiFont
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                    color: Theme.ink
                                }
                                Text {
                                    visible: Identity.userStatus.length > 0
                                    text: Identity.userStatus
                                    font.family: Theme.uiFont
                                    font.pixelSize: 11
                                    color: Theme.primary
                                }
                                Row {
                                    spacing: 8
                                    Text { text: "󰣇"; font.family: Theme.font; font.pixelSize: 13; color: Theme.primary }
                                    Text {
                                        text: Identity.osText.length ? Identity.osText : "Linux"
                                        font.family: Theme.uiFont
                                        font.pixelSize: 13
                                        color: Theme.ink
                                    }
                                }
                                Row {
                                    spacing: 8
                                    Text { text: "󰖯"; font.family: Theme.font; font.pixelSize: 13; color: Theme.primary }
                                    Text {
                                        text: Identity.wmText
                                        font.family: Theme.uiFont
                                        font.pixelSize: 13
                                        color: Theme.ink
                                    }
                                }
                                Row {
                                    spacing: 8
                                    Text { text: "󰅐"; font.family: Theme.font; font.pixelSize: 13; color: Theme.primary }
                                    Text {
                                        text: "up " + (SysInfo.uptime || Identity.uptimeText || "—")
                                        font.family: Theme.uiFont
                                        font.pixelSize: 13
                                        color: Theme.inkMuted
                                    }
                                }
                            }
                        }
                    }

                    SoftCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 12
                            Item {
                                Layout.preferredWidth: 96
                                Layout.preferredHeight: 96
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 96
                                    height: 96
                                    radius: 48
                                    color: Qt.alpha(Theme.primary, 0.18)
                                    border.width: Players.playing ? 2 : 0
                                    border.color: Theme.primary
                                }
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 88
                                    height: 88
                                    radius: 44
                                    clip: true
                                    color: Theme.layer3
                                    Image {
                                        visible: Players.artUrl.length > 0
                                        anchors.fill: parent
                                        source: Players.artUrl
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                    }
                                    Text {
                                        visible: Players.artUrl.length === 0
                                        anchors.centerIn: parent
                                        text: "󰎆"
                                        font.family: Theme.font
                                        font.pixelSize: 28
                                        color: Theme.tertiary
                                    }
                                }
                            }
                            Column {
                                Layout.fillWidth: true
                                spacing: 4
                                Text {
                                    text: Players.has ? Players.title : "Rien en lecture"
                                    font.family: Theme.uiFont
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                    color: Theme.ink
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                Text {
                                    text: Players.artist
                                    font.family: Theme.uiFont
                                    font.pixelSize: 12
                                    color: Theme.inkMuted
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                Text {
                                    visible: Players.album.length > 0
                                    text: Players.album
                                    font.family: Theme.uiFont
                                    font.pixelSize: 11
                                    color: Theme.inkMuted
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                Row {
                                    spacing: 16
                                    Text {
                                        text: "󰒮"
                                        font.family: Theme.font
                                        font.pixelSize: 18
                                        color: Theme.primary
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Players.prev() }
                                    }
                                    Text {
                                        text: Players.glyph
                                        font.family: Theme.font
                                        font.pixelSize: 22
                                        color: Theme.primary
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Players.playPause() }
                                    }
                                    Text {
                                        text: "󰒭"
                                        font.family: Theme.font
                                        font.pixelSize: 18
                                        color: Theme.primary
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Players.next() }
                                    }
                                }
                            }
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 10
                            text: "󰄛"
                            font.family: Theme.font
                            font.pixelSize: 28
                            color: Qt.alpha(Theme.tertiary, 0.45)
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    SoftCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 16
                            Column {
                                Layout.preferredWidth: 72
                                spacing: 2
                                Text {
                                    text: String(new Date().getDate())
                                    font.family: Theme.uiFont
                                    font.pixelSize: 36
                                    font.weight: Font.Black
                                    color: Theme.ink
                                }
                                Text {
                                    text: root.monthNum()
                                    font.family: Theme.uiFont
                                    font.pixelSize: 18
                                    font.weight: Font.DemiBold
                                    color: Theme.inkMuted
                                }
                                Text {
                                    text: root.weekdayNow()
                                    font.family: Theme.uiFont
                                    font.pixelSize: 12
                                    color: Theme.inkMuted
                                    font.capitalization: Font.Capitalize
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 6
                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 7
                                    Repeater {
                                        model: ["L", "M", "M", "J", "V", "S", "D"]
                                        delegate: Text {
                                            required property string modelData
                                            Layout.fillWidth: true
                                            horizontalAlignment: Text.AlignHCenter
                                            text: modelData
                                            font.family: Theme.uiFont
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                            color: Theme.inkMuted
                                        }
                                    }
                                }
                                GridLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    columns: 7
                                    rowSpacing: 2
                                    columnSpacing: 2
                                    Repeater {
                                        model: 42
                                        delegate: Item {
                                            id: cell
                                            required property int index
                                            readonly property int modelData: root.monthCells[index] || 0
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            readonly property bool isToday: modelData > 0 && root.monthOffset === 0 && modelData === new Date().getDate()
                                            Rectangle {
                                                width: 28
                                                height: 28
                                                radius: 14
                                                anchors.centerIn: parent
                                                color: cell.isToday ? Theme.primary : (cellHov.containsMouse && cell.modelData > 0 ? Qt.alpha(Theme.primary, 0.16) : "transparent")
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: cell.modelData > 0 ? String(cell.modelData) : ""
                                                    font.family: Theme.uiFont
                                                    font.pixelSize: 12
                                                    font.weight: cell.isToday ? Font.DemiBold : Font.Normal
                                                    color: cell.isToday ? Theme.inkPrimary : Theme.ink
                                                }
                                            }
                                            MouseArea {
                                                id: cellHov
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                enabled: cell.modelData > 0
                                                cursorShape: cell.modelData > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        WheelHandler {
                            onWheel: event => {
                                const d = event.angleDelta.y > 0 ? -1 : 1;
                                const next = root.monthOffset + d;
                                if (next >= -12 && next <= 12)
                                    root.monthOffset = next;
                                event.accepted = true;
                            }
                        }
                    }

                    SoftCard {
                        Layout.preferredWidth: 92
                        Layout.fillHeight: true
                        Row {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 10
                            VFader {
                                width: 28
                                height: parent.height
                                value: Audio.volume
                                dimmed: Audio.muted
                                icon: Audio.muted ? "󰝟" : Audio.glyph
                                onMoved: v => Audio.setVolume(v)
                            }
                            VFader {
                                width: 28
                                height: parent.height
                                value: Bright.value
                                icon: Bright.glyph
                                onMoved: v => Bright.set(v)
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    spacing: 8
                    Repeater {
                        model: 5
                        delegate: Rectangle {
                            id: pill
                            required property int index
                            readonly property string act: index === 0 ? "wifi" : (index === 1 ? "night" : (index === 2 ? "bt" : (index === 3 ? "dnd" : "mic")))
                            readonly property bool on: {
                                if (index === 0)
                                    return Net.wifiOn;
                                if (index === 1)
                                    return Night.on;
                                if (index === 2)
                                    return Net.btOn;
                                if (index === 3)
                                    return Notifs.dnd;
                                return !Audio.micMuted;
                            }
                            readonly property string icon: {
                                if (index === 0)
                                    return Net.glyph;
                                if (index === 1)
                                    return Night.on ? "󰖔" : "󰖙";
                                if (index === 2)
                                    return Net.btGlyph;
                                if (index === 3)
                                    return Notifs.dnd ? "󰂛" : "󰂚";
                                return Audio.micMuted ? "󰍭" : "󰍬";
                            }
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 36
                            radius: 18
                            color: on ? Theme.primary : Qt.alpha(Theme.surfaceContainerHigh, 0.55)
                            border.width: 1
                            border.color: on ? Theme.primary : Qt.alpha(Theme.primary, 0.16)
                            Text {
                                anchors.centerIn: parent
                                text: pill.icon
                                font.family: Theme.font
                                font.pixelSize: 15
                                color: pill.on ? Theme.inkPrimary : Theme.ink
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const a = pill.act;
                                    if (a === "wifi")
                                        Net.toggleWifi();
                                    else if (a === "night")
                                        Night.toggle();
                                    else if (a === "bt")
                                        Net.toggleBt();
                                    else if (a === "dnd")
                                        Notifs.toggleDnd();
                                    else
                                        Audio.toggleMic();
                                }
                            }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Repeater {
                        model: 4
                        delegate: IconBtn {
                            required property int index
                            readonly property string name: index === 0 ? "launcher" : (index === 1 ? "omarchy" : (index === 2 ? "chat" : "wall"))
                            icon: index === 0 ? "󰀻" : (index === 1 ? "󰣇" : (index === 2 ? "󰍩" : "󰸉"))
                            onClicked: {
                                if (name === "wall") {
                                    Identity.dash("wallmenu");
                                    root.close();
                                } else {
                                    root.go(name);
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Repeater {
                        model: [
                            { id: "lock", label: "Lock", icon: "󰌾", danger: false },
                            { id: "dpms", label: "DPMS", icon: "󰒲", danger: false },
                            { id: "poweroff", label: "Halt", icon: "󰐥", danger: true },
                            { id: "reboot", label: "Reboot", icon: "󰜉", danger: false },
                            { id: "logout", label: "Exit", icon: "󰅼", danger: false }
                        ]
                        delegate: Rectangle {
                            id: sessBtn
                            required property var modelData
                            readonly property bool hov: sessHover.containsMouse
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30
                            radius: 15
                            color: {
                                if (sessBtn.modelData.danger && sessBtn.hov)
                                    return Theme.error;
                                if (sessBtn.hov)
                                    return Qt.alpha(Theme.primary, 0.18);
                                return Qt.alpha(Theme.surfaceContainerHigh, 0.55);
                            }
                            border.width: 1
                            border.color: sessBtn.modelData.danger && sessBtn.hov ? Theme.error : Qt.alpha(Theme.primary, 0.16)
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    text: sessBtn.modelData.icon
                                    font.family: Theme.font
                                    font.pixelSize: 13
                                    color: {
                                        if (sessBtn.modelData.danger && sessBtn.hov)
                                            return Theme.inkPrimary;
                                        if (sessBtn.modelData.danger)
                                            return Theme.inkMuted;
                                        return Theme.primary;
                                    }
                                }
                                Text {
                                    text: sessBtn.modelData.label
                                    font.family: Theme.uiFont
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.6
                                    color: {
                                        if (sessBtn.modelData.danger && sessBtn.hov)
                                            return Theme.inkPrimary;
                                        if (sessBtn.modelData.danger)
                                            return Theme.inkMuted;
                                        return Theme.ink;
                                    }
                                }
                            }
                            MouseArea {
                                id: sessHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Identity.dash(sessBtn.modelData.id);
                                    root.close();
                                }
                            }
                        }
                    }
                }
            }

            Item {
            ColumnLayout {
                anchors.fill: parent
                spacing: 16
                Item { Layout.fillHeight: true }
                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 220
                        Layout.preferredHeight: 220
                        Rectangle {
                            anchors.centerIn: parent
                            width: 220
                            height: 220
                            radius: 110
                            color: Qt.alpha(Theme.primary, 0.14)
                            border.width: Players.playing ? 3 : 1
                            border.color: Qt.alpha(Theme.primary, Players.playing ? 0.85 : 0.25)
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: 200
                            height: 200
                            radius: 100
                            clip: true
                            color: Theme.layer3
                            Image {
                                visible: Players.artUrl.length > 0
                                anchors.fill: parent
                                source: Players.artUrl
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                            Text {
                                visible: Players.artUrl.length === 0
                                anchors.centerIn: parent
                                text: "󰎆"
                                font.family: Theme.font
                                font.pixelSize: 54
                                color: Theme.tertiary
                            }
                        }
                    }
                    Column {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 4
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Players.has ? Players.title : "Rien en lecture"
                            font.family: Theme.uiFont
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                            color: Theme.ink
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Players.artist
                            font.family: Theme.uiFont
                            font.pixelSize: 13
                            color: Theme.inkMuted
                        }
                        Text {
                            visible: Players.album.length > 0
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Players.album
                            font.family: Theme.uiFont
                            font.pixelSize: 12
                            color: Theme.inkMuted
                        }
                    }
                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 28
                        Text {
                            text: "󰒮"
                            font.family: Theme.font
                            font.pixelSize: 26
                            color: Theme.primary
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Players.prev() }
                        }
                        Text {
                            text: Players.glyph
                            font.family: Theme.font
                            font.pixelSize: 34
                            color: Theme.primary
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Players.playPause() }
                        }
                        Text {
                            text: "󰒭"
                            font.family: Theme.font
                            font.pixelSize: 26
                            color: Theme.primary
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Players.next() }
                        }
                    }
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 18
                        Layout.leftMargin: 48
                        Layout.rightMargin: 48
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 4
                            radius: 2
                            color: Qt.alpha(Theme.ink, 0.16)
                            Rectangle {
                                width: parent.width * root.mediaProgress
                                height: parent.height
                                radius: 2
                                color: Theme.primary
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: Players.canSeek
                            cursorShape: Qt.PointingHandCursor
                            onClicked: event => {
                                if (Players.length > 0)
                                    Players.seekTo((event.x / width) * Players.length);
                            }
                        }
                    }
                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 12
                        Text {
                            text: root.fmt(Players.position)
                            font.family: Theme.uiFont
                            font.pixelSize: 11
                            color: Theme.inkMuted
                        }
                        Text {
                            text: root.fmt(Players.length)
                            font.family: Theme.uiFont
                            font.pixelSize: 11
                            color: Theme.inkMuted
                        }
                    }
                    Item { Layout.fillHeight: true }
            }
            }

            ColumnLayout {
            spacing: 14
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 168
                    spacing: 12
                    CircMeter { label: "CPU"; glyph: "󰻠"; value: SysInfo.cpu; text: Math.round(SysInfo.cpu * 100) + "%" }
                    CircMeter { label: "RAM"; glyph: "󰍛"; value: SysInfo.ram; text: SysInfo.ramText || (Math.round(SysInfo.ram * 100) + "%") }
                    CircMeter { label: "DISK"; glyph: "󰋊"; value: SysInfo.disk; text: SysInfo.diskText || (Math.round(SysInfo.disk * 100) + "%") }
                    CircMeter { label: "GPU"; glyph: "󰢮"; value: BarBits.gpuVal; text: BarBits.gpu || "—" }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    StatMeter { label: "CPU"; glyph: "󰻠"; value: SysInfo.cpu; valueText: Math.round(SysInfo.cpu * 100) + "%" }
                    StatMeter { label: "RAM"; glyph: "󰍛"; value: SysInfo.ram; valueText: SysInfo.ramText || (Math.round(SysInfo.ram * 100) + "%") }
                    StatMeter { label: "Temp"; glyph: "󰔏"; value: BarBits.tempVal; valueText: BarBits.temp || "—" }
                    StatMeter { label: "Disk"; glyph: "󰋊"; value: SysInfo.disk; valueText: SysInfo.diskText || (Math.round(SysInfo.disk * 100) + "%") }
                }
                Item { Layout.fillHeight: true }
            }

            Flickable {
            clip: true
            contentHeight: wsCol.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
                ColumnLayout {
                    id: wsCol
                    width: parent.width
                    spacing: 10
                    Repeater {
                        model: root.tab === 3 ? Niri.visWs.length : 0
                        delegate: Rectangle {
                            id: wsCard
                            required property int index
                            readonly property var modelData: Niri.visWs[index] || {}
                            readonly property bool active: !!(modelData.is_active || modelData.is_focused)
                            Layout.fillWidth: true
                            implicitHeight: Math.max(72, 52 + winTxt.implicitHeight)
                            radius: 22
                            color: active ? Qt.alpha(Theme.primary, 0.18) : Qt.alpha(Theme.surfaceContainerLow, 0.55)
                            border.width: 1
                            border.color: active ? Qt.alpha(Theme.primary, 0.45) : Qt.alpha(Theme.primary, 0.12)
                            Column {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 6
                                Row {
                                    spacing: 10
                                    Rectangle {
                                        width: 28
                                        height: 28
                                        radius: 10
                                        color: wsCard.active ? Theme.primary : Qt.alpha(Theme.primary, 0.18)
                                        Text {
                                            anchors.centerIn: parent
                                            text: String(wsCard.modelData.idx || "")
                                            font.family: Theme.uiFont
                                            font.pixelSize: 12
                                            font.weight: Font.Bold
                                            color: wsCard.active ? Theme.inkPrimary : Theme.ink
                                        }
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: wsCard.modelData.name || ("Bureau " + (wsCard.modelData.idx || ""))
                                        font.family: Theme.uiFont
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                        color: Theme.ink
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: wsCard.modelData.output
                                        text: wsCard.modelData.output || ""
                                        font.family: Theme.uiFont
                                        font.pixelSize: 11
                                        color: Theme.inkMuted
                                    }
                                }
                                Text {
                                    id: winTxt
                                    width: parent.width
                                    text: root.winLine(wsCard.modelData.id)
                                    font.family: Theme.uiFont
                                    font.pixelSize: 11
                                    color: Theme.inkMuted
                                    wrapMode: Text.Wrap
                                    elide: Text.ElideRight
                                    maximumLineCount: 6
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Niri.focusWorkspace(wsCard.modelData.output || Niri.focusedOutput, wsCard.modelData.idx);
                                    root.close();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        Identity.reload();
        SysInfo.refresh();
        Weather.refresh();
        Night.refresh();
        Bright.refresh();
    }
}
