pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit
import "../control"

// Dashboard déroulant « poste de commande » : en-tête horloge (fil de la
// journée), calendrier, télémétrie (jauges + tracés CPU / RAM / GPU), lecteur
// (carte média du rice) et météo. Tuiles propres au dashboard : les widgets
// du bureau restent indépendants. Mesures rapides (1 s) uniquement à l'écran.
FocusScope {
    id: root
    property real maxHeight: 900

    implicitWidth: 780
    implicitHeight: Math.min(maxHeight, col.implicitHeight + 40)

    readonly property date now: SysInfo.now

    function greet() {
        const h = now.getHours();
        if (h < 6) return "Bonne nuit";
        if (h < 12) return "Bonjour";
        if (h < 18) return "Bon après-midi";
        return "Bonsoir";
    }
    function cap(s) {
        return s.length ? s.charAt(0).toUpperCase() + s.slice(1) : s;
    }
    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        const day = (t.getUTCDay() + 6) % 7;
        t.setUTCDate(t.getUTCDate() - day + 3);
        const first = new Date(Date.UTC(t.getUTCFullYear(), 0, 4));
        return 1 + Math.round(((t - first) / 86400000 - 3 + ((first.getUTCDay() + 6) % 7)) / 7);
    }
    readonly property real dayFrac: (now.getHours() * 3600 + now.getMinutes() * 60 + now.getSeconds()) / 86400
    readonly property int dayOfYear: Math.floor((new Date(now.getFullYear(), now.getMonth(), now.getDate()) - new Date(now.getFullYear(), 0, 1)) / 86400000) + 1

    // ---- télémétrie : cadence rapide + historique tant que c'est affiché ----
    property bool _fast: false
    function _watch(on) {
        if (on === _fast)
            return;
        _fast = on;
        SysInfo.fastUsers = Math.max(0, SysInfo.fastUsers + (on ? 1 : -1));
        Gpu.users = Math.max(0, Gpu.users + (on ? 1 : -1));
    }
    onVisibleChanged: _watch(visible)
    Component.onCompleted: _watch(visible)
    Component.onDestruction: _watch(false)

    readonly property int histLen: 48
    property var cpuHist: []
    property var ramHist: []
    property var gpuHist: []
    function _push(arr, v) {
        const a = arr.concat([v]);
        return a.length > histLen ? a.slice(a.length - histLen) : a;
    }
    Connections {
        target: SysInfo
        function onCpuChanged() { root.cpuHist = root._push(root.cpuHist, SysInfo.cpu); }
        function onRamChanged() { root.ramHist = root._push(root.ramHist, SysInfo.ram); }
    }
    Connections {
        target: Gpu
        function onUtilChanged() { root.gpuHist = root._push(root.gpuHist, Gpu.util); }
    }

    // ---- briques ----
    component Tile: Pane {
        level: 1
        glass: true
        radius: Tokens.rLg
        highlight: true
        default property alias body: hold.data
        Item { id: hold; anchors.fill: parent; anchors.margins: 16 }
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        // ---- en-tête : identité + horloge + fil de la journée ----
        Tile {
            Layout.fillWidth: true
            Layout.preferredHeight: 128

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 18

                // avatar cerclé d'un anneau de la journée écoulée
                Item {
                    Layout.preferredWidth: 72
                    Layout.preferredHeight: 72
                    Ring {
                        anchors.centerIn: parent
                        size: 72
                        value: root.dayFrac
                        thickness: 3
                        tone: Theme.accent
                        alert: false
                    }
                    Art {
                        anchors.centerIn: parent
                        width: 60
                        height: 60
                        source: Identity.hasAvatar ? Identity.avatar : ""
                        radius: Identity.avatarShape === "square" ? Tokens.rMd : width / 2
                        fallbackIcon: "person"
                    }
                }

                ColumnLayout {
                    spacing: 0
                    Txt {
                        role: "overline"
                        text: "// " + root.greet() + ", " + Identity.userName
                        color: Theme.accent
                    }
                    RowLayout {
                        spacing: 6
                        Text {
                            text: Qt.formatTime(root.now, "HH:mm")
                            color: Theme.text
                            font.family: Theme.displayFont
                            font.pixelSize: 48
                            font.weight: Font.Medium
                            font.letterSpacing: -1.5
                            font.features: ({ "tnum": 1 })
                        }
                        Text {
                            Layout.alignment: Qt.AlignBottom
                            Layout.bottomMargin: 10
                            text: Qt.formatTime(root.now, "ss")
                            color: Theme.accent2
                            font.family: Theme.monoFont
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }
                    }
                    Txt {
                        role: "caption"
                        text: root.cap(Qt.locale().toString(root.now, "dddd d MMMM")) + "  ·  semaine " + root.isoWeek(root.now) + "  ·  jour " + root.dayOfYear
                        color: Theme.textSub
                    }
                }

                Item { Layout.fillWidth: true }

                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    spacing: 6
                    // météo express
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        visible: Weather.ready
                        spacing: 6
                        Text { text: Weather.glyph; color: Theme.accent2; font.family: Theme.monoFont; font.pixelSize: 18 }
                        Txt { role: "label"; text: Weather.temp + "°"; strong: true }
                        Txt { role: "caption"; text: Weather.city; color: Theme.textSub }
                    }
                    Txt { role: "mono"; text: Identity.hostName; color: Theme.text; font.weight: Font.DemiBold; Layout.alignment: Qt.AlignRight }
                    Txt { role: "caption"; text: "en ligne depuis " + (Identity.uptimeText || SysInfo.uptime); color: Theme.textSub; Layout.alignment: Qt.AlignRight }
                    Txt { role: "caption"; text: Identity.wmText + (Identity.osText ? " · " + Identity.osText : ""); color: Theme.textFaint; Layout.alignment: Qt.AlignRight }
                }
            }

            // fil de la journée : 00h → 24h, curseur à l'heure actuelle
            Item {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 12
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 2
                    radius: 1
                    color: Qt.alpha(Theme.text, 0.07)
                    Rectangle {
                        width: parent.width * root.dayFrac
                        height: parent.height
                        radius: 1
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: Qt.alpha(Theme.accent2, 0.15) }
                            GradientStop { position: 1; color: Theme.accent }
                        }
                    }
                }
                Repeater {
                    model: [6, 12, 18]
                    Rectangle {
                        required property int modelData
                        x: parent.width * modelData / 24
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 6
                        color: Qt.alpha(Theme.text, 0.18)
                    }
                }
                Rectangle {
                    x: parent.width * root.dayFrac - 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 8
                    height: 8
                    radius: 4
                    color: Theme.accent
                    border.width: 2
                    border.color: Theme.s1
                }
            }
        }

        // ---- rangée 1 : calendrier + télémétrie ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Tile {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.preferredHeight: 300

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    DashHead {
                        Layout.fillWidth: true
                        label: Qt.locale().toString(root.now, "MMMM")
                        meta: String(root.now.getFullYear())
                    }

                    GridLayout {
                        id: cal
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: 7
                        rowSpacing: 0
                        columnSpacing: 0

                        readonly property var cells: {
                            const first = new Date(root.now.getFullYear(), root.now.getMonth(), 1);
                            const lead = (first.getDay() + 6) % 7;
                            const out = [];
                            for (let i = 0; i < 42; i++)
                                out.push(new Date(root.now.getFullYear(), root.now.getMonth(), 1 - lead + i));
                            return out;
                        }

                        Repeater {
                            model: ["L", "M", "M", "J", "V", "S", "D"]
                            Txt {
                                required property string modelData
                                required property int index
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                role: "overline"
                                text: modelData
                                color: index >= 5 ? Theme.accent2 : Theme.textFaint
                            }
                        }
                        Repeater {
                            model: cal.cells
                            Item {
                                id: day
                                required property var modelData
                                readonly property bool inMonth: modelData.getMonth() === root.now.getMonth()
                                readonly property bool today: inMonth && modelData.getDate() === root.now.getDate()
                                readonly property bool weekend: modelData.getDay() === 0 || modelData.getDay() === 6
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 30
                                    height: 30
                                    radius: Tokens.rSm
                                    color: day.today ? Theme.accent : (dayHover.hovered && day.inMonth ? Theme.s3 : "transparent")
                                }
                                Txt {
                                    anchors.centerIn: parent
                                    role: "label"
                                    text: day.modelData.getDate()
                                    strong: day.today
                                    color: day.today ? Theme.onAccent
                                        : !day.inMonth ? Qt.alpha(Theme.text, 0.18)
                                        : day.weekend ? Theme.accent2 : Theme.text
                                }
                                HoverHandler { id: dayHover }
                            }
                        }
                    }
                }
            }

            Tile {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.preferredHeight: 300

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12

                    DashHead {
                        Layout.fillWidth: true
                        label: "télémétrie"
                        meta: SysInfo.hasTemp ? Math.round(SysInfo.temp) + "°C" : ""
                    }
                    DashMeter {
                        Layout.fillWidth: true
                        label: "CPU"
                        value: Math.round(SysInfo.cpu * 100) + "%"
                        frac: SysInfo.cpu
                        tone: Theme.accent
                        hist: root.cpuHist
                        capacity: root.histLen
                    }
                    DashMeter {
                        Layout.fillWidth: true
                        label: "RAM"
                        sub: SysInfo.ramText
                        value: Math.round(SysInfo.ram * 100) + "%"
                        frac: SysInfo.ram
                        tone: Theme.accent2
                        hist: root.ramHist
                        capacity: root.histLen
                    }
                    DashMeter {
                        Layout.fillWidth: true
                        visible: Gpu.available
                        label: "GPU"
                        sub: Gpu.temp > 0 ? Math.round(Gpu.temp) + "°C" : ""
                        value: Math.round(Gpu.util * 100) + "%"
                        frac: Gpu.util
                        tone: Theme.signature
                    }
                    DashMeter {
                        Layout.fillWidth: true
                        label: "Disque"
                        sub: SysInfo.diskText
                        value: Math.round(SysInfo.disk * 100) + "%"
                        frac: SysInfo.disk
                        tone: Theme.textSub
                    }
                    Item { Layout.fillHeight: true }
                }
            }
        }

        // ---- rangée 2 : lecteur + météo ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            MediaCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 2
                Layout.alignment: Qt.AlignTop
                visible: Players.has
                large: true
                level: 1
            }
            Tile {
                Layout.fillWidth: true
                Layout.preferredWidth: 2
                Layout.preferredHeight: 120
                visible: !Players.has
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Icon { Layout.alignment: Qt.AlignHCenter; name: "music_off"; size: 26; color: Theme.textFaint }
                    Txt { Layout.alignment: Qt.AlignHCenter; role: "caption"; text: "Rien en lecture"; color: Theme.textFaint }
                }
            }

            Tile {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                Layout.minimumHeight: 120

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 4
                    visible: Weather.ready

                    DashHead {
                        Layout.fillWidth: true
                        label: Weather.city || "météo"
                    }
                    Item { Layout.fillHeight: true }
                    RowLayout {
                        spacing: 10
                        Text {
                            text: Weather.glyph
                            color: Theme.accent2
                            font.family: Theme.monoFont
                            font.pixelSize: 40
                        }
                        Text {
                            text: Weather.temp + "°"
                            color: Theme.text
                            font.family: Theme.displayFont
                            font.pixelSize: 44
                            font.weight: Font.Medium
                            font.letterSpacing: -1
                        }
                    }
                    Txt {
                        Layout.fillWidth: true
                        role: "caption"
                        text: root.cap(Weather.desc) + " · ressenti " + Weather.feel + "°"
                    }
                    // amplitude du jour : min → max, position de la température actuelle
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Txt { role: "mono"; text: Weather.low + "°"; color: Theme.textSub; font.pixelSize: 10 }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 4
                            radius: 2
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: Theme.accent2 }
                                GradientStop { position: 1; color: Theme.warning }
                            }
                            Rectangle {
                                readonly property real f: Weather.high > Weather.low ? (Weather.temp - Weather.low) / (Weather.high - Weather.low) : 0.5
                                x: parent.width * Math.max(0, Math.min(1, f)) - 4
                                anchors.verticalCenter: parent.verticalCenter
                                width: 8
                                height: 8
                                radius: 4
                                color: Theme.text
                                border.width: 2
                                border.color: Theme.s1
                            }
                        }
                        Txt { role: "mono"; text: Weather.high + "°"; color: Theme.textSub; font.pixelSize: 10 }
                    }
                }
                ColumnLayout {
                    anchors.centerIn: parent
                    visible: !Weather.ready
                    Spinner { Layout.alignment: Qt.AlignHCenter }
                    Txt { role: "caption"; text: "Météo…"; color: Theme.textFaint }
                }
            }
        }
    }
}
