pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit

// ProtonVPN — navigateur de serveurs dans le panneau (façon Arsenal).
// Gauche : recherche + catégories d'activité. Droite : serveurs classés avec
// charge live et reco de l'optimal ; clic = connexion WireGuard en 1 clic.
FocusScope {
    id: root

    property real maxHeight: 760
    implicitWidth: 940
    implicitHeight: Math.min(maxHeight, 720)

    Component.onCompleted: {
        Proton.users++;
        field.focusInput();
    }
    Component.onDestruction: Proton.users = Math.max(0, Proton.users - 1)
    Keys.onEscapePressed: PanelService.hide()

    // couleur selon la charge serveur
    function loadColor(l) {
        return l < 50 ? Theme.success : (l < 80 ? Theme.warning : Theme.error);
    }

    // ---- délégué de ligne serveur (réutilisé par toutes les listes) ----
    Component {
        id: serverRow
        Rectangle {
            id: row
            required property var modelData
            readonly property var s: modelData
            readonly property bool isActive: Proton.connected && Proton.activeId === s.id
            readonly property bool isBusy: Proton.busyId === s.id
            width: ListView.view ? ListView.view.width : 0
            implicitHeight: 54
            radius: Tokens.rMd
            color: rowHover.hovered ? Theme.s2 : "transparent"

            HoverHandler { id: rowHover }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10

                // code pays
                Rectangle {
                    width: 34; height: 24; radius: 5
                    color: Theme.s4
                    Txt { anchors.centerIn: parent; role: "mono"; font.pixelSize: 11; text: row.s.cc; color: Theme.textSub }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    RowLayout {
                        spacing: 5
                        Txt { role: "label"; text: row.s.name }
                        Badge { visible: row.s.p2p; label: "P2P"; tone: Theme.accent2; ink: Theme.onAccent }
                        Badge { visible: row.s.tor; label: "Tor"; tone: Theme.signature; ink: Theme.onAccent }
                        Badge { visible: row.s.sc; label: "Core"; tone: Theme.accent; ink: Theme.onAccent }
                    }
                    Txt { role: "caption"; color: Theme.textFaint; text: (row.s.city && row.s.city.length ? row.s.city + " · " : "") + "entrée " + row.s.entry }
                }
                // jauge de charge
                ColumnLayout {
                    Layout.preferredWidth: 84
                    spacing: 2
                    RowLayout {
                        Layout.fillWidth: true
                        Txt { Layout.fillWidth: true; role: "caption"; text: "charge"; color: Theme.textFaint }
                        Txt { role: "caption"; text: row.s.load + "%"; color: root.loadColor(row.s.load) }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 4; radius: 2; color: Theme.s4
                        Rectangle {
                            width: parent.width * Math.min(1, row.s.load / 100)
                            height: parent.height; radius: 2
                            color: root.loadColor(row.s.load)
                        }
                    }
                }
                // action
                Spinner { visible: row.isBusy; size: 18 }
                Button {
                    visible: !row.isBusy
                    variant: row.isActive ? "danger" : "primary"
                    height_: 28
                    icon: row.isActive ? "link_off" : "vpn_key"
                    text: row.isActive ? "Couper" : "Connecter"
                    onClicked: row.isActive ? Proton.disconnect() : Proton.connect(row.s)
                }
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ---------- colonne gauche ----------
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 250
            color: Qt.alpha(Theme.s0, 0.35)
            radius: Tokens.rXl

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Icon { name: "security"; size: 22; color: Theme.accent }
                    ColumnLayout {
                        spacing: 0
                        Txt { role: "title"; text: "ProtonVPN" }
                        Txt { role: "overline"; text: Proton.ready ? Proton.total + " serveurs · tier " + Proton.tier : "chargement…"; color: Theme.accent }
                    }
                }

                SearchField {
                    id: field
                    Layout.fillWidth: true
                    placeholder: "Pays, ville, serveur…"
                    onTextChanged: Proton.query = text
                }

                ListView {
                    id: cats
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 1
                    model: Proton.categories.concat([{ id: "pays", label: "Tous les pays", icon: "public", count: Proton.countries.length }])

                    delegate: Rectangle {
                        id: cat
                        required property var modelData
                        readonly property bool on: Proton.category === cat.modelData.id && Proton.query.length < 2
                        width: cats.width
                        implicitHeight: 40
                        radius: Tokens.rMd
                        color: on ? Qt.alpha(Theme.accent, 0.16) : (catHover.containsMouse ? Theme.s2 : "transparent")

                        MouseArea {
                            id: catHover
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                field.text = "";
                                Proton.query = "";
                                Proton.closeCountry();
                                Proton.category = cat.modelData.id;
                            }
                        }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10
                            Icon { name: cat.modelData.icon; size: 17; color: cat.on ? Theme.accent : Theme.textSub }
                            Txt { Layout.fillWidth: true; role: "label"; text: cat.modelData.label; color: cat.on ? Theme.text : Theme.textSub }
                            Txt { role: "caption"; text: cat.modelData.count; color: Theme.textFaint }
                        }
                    }
                }

                // état connexion
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: connCol.implicitHeight + 16
                    radius: Tokens.rMd
                    color: Proton.connected ? Qt.alpha(Theme.success, 0.14) : Theme.s2
                    ColumnLayout {
                        id: connCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 4
                        Txt {
                            Layout.fillWidth: true
                            role: "caption"
                            wrapMode: Text.WordWrap
                            color: Proton.connected ? Theme.success : Theme.textSub
                            text: Proton.connected ? "Connecté · " + (Proton.activeName || "ProtonVPN") : "Non connecté"
                        }
                        Button {
                            visible: Proton.connected
                            variant: "danger"
                            height_: 26
                            icon: "link_off"
                            text: "Déconnecter"
                            onClicked: Proton.disconnect()
                        }
                    }
                }
            }
        }

        // ---------- colonne droite ----------
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 14
            spacing: 8

            // en-tête contextuel
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                IconButton {
                    visible: Proton.countryCode.length > 0
                    icon: "arrow_back"
                    size: 28
                    onClicked: Proton.closeCountry()
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Txt {
                        role: "heading"
                        text: Proton.query.length >= 2 ? "Recherche : « " + Proton.query + " »"
                            : Proton.countryCode.length ? "Serveurs — " + Proton.countryCode
                            : Proton.category === "pays" ? "Tous les pays"
                            : (Proton.current ? Proton.current.label : "")
                    }
                    Txt {
                        role: "caption"
                        color: Theme.textFaint
                        visible: Proton.category !== "pays" && !Proton.countryCode.length && Proton.query.length < 2 && Proton.current
                        text: Proton.current ? Proton.current.desc : ""
                    }
                }
                IconButton { icon: "refresh"; size: 28; tooltip: "Rafraîchir"; onClicked: Proton.refresh() }
                IconButton { icon: "close"; size: 28; onClicked: PanelService.hide() }
            }

            // message
            Rectangle {
                Layout.fillWidth: true
                visible: Proton.note.length > 0
                implicitHeight: 34
                radius: Tokens.rSm
                color: Qt.alpha(Proton.noteError ? Theme.warning : Theme.success, 0.12)
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    spacing: 8
                    Icon { name: Proton.noteError ? "error" : "info"; size: 15; color: Proton.noteError ? Theme.warning : Theme.success }
                    Txt { Layout.fillWidth: true; role: "caption"; text: Proton.note; color: Proton.noteError ? Theme.warning : Theme.success }
                }
            }

            // reco en vedette (vue catégorie simple)
            Pane {
                id: recoPane
                Layout.fillWidth: true
                readonly property var r: (Proton.current && Proton.current.reco) ? Proton.current.reco : null
                visible: Proton.query.length < 2 && !Proton.countryCode.length && Proton.category !== "pays" && recoPane.r !== null
                level: 3
                glass: false
                radius: Tokens.rLg
                implicitHeight: 64
                borderColor: Qt.alpha(Theme.accent, 0.45)
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10
                    Icon { name: "recommend"; size: 22; color: Theme.accent }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        RowLayout {
                            spacing: 6
                            Txt { role: "label"; text: recoPane.r ? recoPane.r.name : "" }
                            Txt { role: "caption"; color: Theme.textFaint; text: recoPane.r ? (recoPane.r.city || recoPane.r.cc) : "" }
                        }
                        Txt { role: "caption"; color: Theme.accent; text: "Recommandé — le moins chargé" }
                    }
                    Txt {
                        role: "label"
                        text: (recoPane.r ? recoPane.r.load : 0) + "%"
                        color: root.loadColor(recoPane.r ? recoPane.r.load : 0)
                    }
                    Button {
                        variant: "primary"
                        height_: 30
                        icon: "vpn_key"
                        text: "Connecter"
                        disabled: recoPane.r === null
                        onClicked: if (recoPane.r) Proton.connect(recoPane.r)
                    }
                }
            }

            // ---- listes ----
            // serveurs d'une catégorie / recherche / pays
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                visible: Proton.query.length >= 2 || Proton.countryCode.length > 0 || Proton.category !== "pays"
                model: Proton.query.length >= 2 ? Proton.findResults
                    : Proton.countryCode.length ? Proton.countryServers
                    : (Proton.current ? Proton.current.servers : [])
                delegate: serverRow

                EmptyState {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    icon: Proton.query.length >= 2 ? "search_off" : "dns"
                    title: Proton.query.length >= 2 ? "Aucun serveur" : "Rien ici"
                }
            }

            // liste des pays
            ListView {
                id: countryList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 1
                boundsBehavior: Flickable.StopAtBounds
                visible: Proton.category === "pays" && !Proton.countryCode.length && Proton.query.length < 2
                model: Proton.countries

                delegate: Rectangle {
                    id: cRow
                    required property var modelData
                    readonly property var c: modelData
                    width: countryList.width
                    implicitHeight: 46
                    radius: Tokens.rMd
                    color: cHover.containsMouse ? Theme.s2 : "transparent"
                    MouseArea { id: cHover; anchors.fill: parent; hoverEnabled: true; onClicked: Proton.openCountry(cRow.c.cc) }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10
                        Rectangle {
                            width: 34; height: 24; radius: 5; color: Theme.s4
                            Txt { anchors.centerIn: parent; role: "mono"; font.pixelSize: 11; text: cRow.c.cc; color: Theme.textSub }
                        }
                        Txt { Layout.fillWidth: true; role: "label"; text: cRow.c.name }
                        Txt { role: "caption"; color: Theme.textFaint; text: cRow.c.count + " serveurs" }
                        Txt { role: "caption"; text: "min " + cRow.c.best.load + "%"; color: root.loadColor(cRow.c.best.load) }
                        Icon { name: "chevron_right"; size: 18; color: Theme.textFaint }
                    }
                }
            }
        }
    }
}
