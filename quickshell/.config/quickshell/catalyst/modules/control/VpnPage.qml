pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.rice
import qs.kit

// VPN : connexions NetworkManager (OpenVPN, WireGuard, plugins installés).
//  - connecter / déconnecter, identifiants demandés au besoin
//  - exporter en fichier réutilisable (Kali, Parrot, autre machine…)
//  - « réseaux du VPN uniquement » (garde Internet via la box, typique HTB/THM)
//  - réparer un VPN dont les certificats ont disparu
//  - ajouter : fichier, configuration collée, WireGuard en saisie manuelle
ColumnLayout {
    id: root
    signal back()
    spacing: Tokens.sectionGap

    property string addMode: ""          // "" | file | paste | wg
    property string confirmDel: ""
    property string renaming: ""

    Component.onCompleted: Vpn.users++
    Component.onDestruction: Vpn.users = Math.max(0, Vpn.users - 1)

    PageHeader {
        Layout.fillWidth: true
        title: "VPN"
        subtitle: Vpn.activeVpn ? "Connecté : " + Vpn.activeVpn.label + (Ifaces.vpn ? " · " + Ifaces.lhost : "") : Vpn.userVpns.length + " configuration(s)"
        onBack: root.back()
    }

    // message d'état
    Rectangle {
        Layout.fillWidth: true
        visible: Vpn.note.length > 0
        implicitHeight: noteRow.implicitHeight + 16
        radius: Tokens.rMd
        color: Qt.alpha(Vpn.noteError ? Theme.warning : Theme.success, 0.12)
        RowLayout {
            id: noteRow
            anchors.fill: parent
            anchors.margins: 8
            anchors.leftMargin: 12
            spacing: 8
            Icon { name: Vpn.noteError ? "error" : "check_circle"; size: 16; color: Vpn.noteError ? Theme.warning : Theme.success }
            Txt { Layout.fillWidth: true; role: "caption"; wrapMode: Text.WordWrap; text: Vpn.note; color: Vpn.noteError ? Theme.warning : Theme.success }
            Button {
                visible: Vpn.needSecrets.length > 0
                variant: "secondary"
                height_: 26
                icon: "password"
                text: "Saisir les identifiants"
                onClicked: Vpn.upInteractive(Vpn.needSecrets)
            }
        }
    }

    // ---------------- connexions ----------------
    Repeater {
        model: Vpn.items

        Pane {
            id: card
            required property var modelData
            readonly property var v: modelData
            readonly property bool broken: v.missing && v.missing.length > 0
            readonly property bool busy: Vpn.busyUuid === v.uuid
            Layout.fillWidth: true
            implicitHeight: cardCol.implicitHeight + 20
            level: 3
            glass: false
            radius: Tokens.rLg
            borderColor: v.active ? Qt.alpha(Theme.success, 0.5) : (broken ? Qt.alpha(Theme.warning, 0.5) : Theme.border)

            ColumnLayout {
                id: cardCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                anchors.leftMargin: 12
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Rectangle {
                        width: 34
                        height: 34
                        radius: Tokens.rMd
                        color: card.v.active ? Theme.success : Theme.s4
                        Icon {
                            anchors.centerIn: parent
                            name: card.v.external ? "hub" : (card.v.active ? "vpn_lock" : "vpn_key")
                            size: 18
                            fill: card.v.active ? 1 : 0
                            color: card.v.active ? Theme.onAccent : Theme.textSub
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        RowLayout {
                            spacing: 6
                            Txt { role: "heading"; text: card.v.label; Layout.maximumWidth: 170 }
                            Badge { label: card.v.type; tone: card.v.type === "wireguard" ? Theme.accent2 : Theme.accent; ink: Theme.onAccent }
                        }
                        Txt {
                            Layout.fillWidth: true
                            role: "caption"
                            color: card.broken ? Theme.warning : Theme.textSub
                            text: card.v.external ? "Géré par " + card.v.label + " (lecture seule)"
                                : card.broken ? card.v.missing.length + " fichier(s) de certificat introuvable(s) — à réparer"
                                : card.busy ? "Connexion…"
                                : card.v.active ? "Connecté" + (card.v.neverDefault ? " · réseaux du VPN uniquement" : " · tout le trafic")
                                : (card.v.neverDefault ? "Réseaux du VPN uniquement (Internet via la box)" : "Tout le trafic passe par le VPN") + (card.v.autoconnect ? " · auto" : "")
                        }
                    }
                    Spinner { visible: card.busy; size: 18 }
                    Toggle {
                        visible: !card.v.external
                        checked: card.v.active
                        disabled: card.busy || card.broken
                        onToggled: v => v ? Vpn.up(card.v) : Vpn.down(card.v)
                    }
                }

                // actions
                Flow {
                    Layout.fillWidth: true
                    visible: !card.v.external
                    spacing: 6
                    Button {
                        visible: card.broken
                        variant: "primary"
                        height_: 28
                        icon: "build"
                        text: "Réparer depuis un fichier…"
                        onClicked: Vpn.pickFile(p => Vpn.replace(card.v, p))
                    }
                    Button {
                        variant: "secondary"
                        height_: 28
                        icon: "ios_share"
                        text: "Exporter"
                        onClicked: Vpn.exportTo(card.v, "")
                    }
                    Button {
                        variant: card.v.neverDefault ? "primary" : "ghost"
                        height_: 28
                        icon: "alt_route"
                        text: "VPN seul"
                        onClicked: Vpn.setOpt(card.v, "neverdefault", !card.v.neverDefault)
                    }
                    Button {
                        variant: card.v.autoconnect ? "primary" : "ghost"
                        height_: 28
                        icon: "autorenew"
                        text: "Auto"
                        onClicked: Vpn.setOpt(card.v, "autoconnect", !card.v.autoconnect)
                    }
                    IconButton {
                        id: more
                        icon: "more_horiz"
                        size: 28
                        iconSize: 17
                        tooltip: "Plus d'actions"
                        onClicked: moreMenu.openAt(more)
                    }
                    Button {
                        visible: root.confirmDel === card.v.uuid
                        variant: "danger"
                        height_: 28
                        icon: "delete"
                        text: "Confirmer la suppression"
                        onClicked: {
                            root.confirmDel = "";
                            Vpn.remove(card.v);
                        }
                    }
                }
                Menu {
                    id: moreMenu
                    side: "bottom"
                    items: [
                        { label: "Exporter vers…", icon: "folder_open", action: () => Vpn.pickDir(d => Vpn.exportTo(card.v, d)) },
                        { label: "Remplacer par un fichier…", icon: "build", action: () => Vpn.pickFile(p => Vpn.replace(card.v, p)) },
                        { label: "Renommer", icon: "edit", action: () => root.renaming = card.v.uuid },
                        { separator: true },
                        { label: "Supprimer…", icon: "delete", danger: true, action: () => { root.confirmDel = card.v.uuid; delT.restart(); } }
                    ]
                }
                Field {
                    Layout.fillWidth: true
                    visible: root.renaming === card.v.uuid
                    placeholder: "Nouveau nom pour " + card.v.label + " (Entrée)"
                    onAccepted: t => {
                        if (t.trim().length)
                            Vpn.rename(card.v, t.trim());
                        root.renaming = "";
                    }
                }
            }
        }
    }
    Timer {
        id: delT
        interval: 4000
        onTriggered: root.confirmDel = ""
    }

    // ---------------- ajout ----------------
    SectionHeader { Layout.fillWidth: true; text: "Ajouter un VPN" }

    Segmented {
        Layout.fillWidth: true
        model: [{ id: "file", label: "Fichier", icon: "upload_file" }, { id: "paste", label: "Coller", icon: "content_paste" }, { id: "wg", label: "WireGuard manuel", icon: "key" }]
        current: root.addMode
        onSelected: id => root.addMode = root.addMode === id ? "" : id
    }

    // fichier
    ColumnLayout {
        Layout.fillWidth: true
        visible: root.addMode === "file"
        spacing: 8
        Field {
            id: fileName
            Layout.fillWidth: true
            placeholder: "Nom (facultatif : nom du fichier sinon)"
        }
        Button {
            variant: "primary"
            icon: "upload_file"
            text: "Choisir un .ovpn / .conf / .pcf…"
            onClicked: Vpn.pickFile(p => {
                Vpn.importFile(p, fileName.text.trim());
                fileName.text = "";
                root.addMode = "";
            })
        }
    }

    // coller
    ColumnLayout {
        Layout.fillWidth: true
        visible: root.addMode === "paste"
        spacing: 8
        Field {
            id: pasteName
            Layout.fillWidth: true
            placeholder: "Nom du VPN (ex. HTB, THM, Bureau)"
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 160
            radius: Tokens.rMd
            color: Theme.s1
            border.width: 1
            border.color: pasteEdit.activeFocus ? Qt.alpha(Theme.accent, 0.6) : Theme.border
            Flickable {
                anchors.fill: parent
                anchors.margins: 8
                contentHeight: pasteEdit.implicitHeight
                clip: true
                TextEdit {
                    id: pasteEdit
                    width: parent.width
                    wrapMode: TextEdit.WrapAnywhere
                    color: Theme.text
                    selectionColor: Theme.selection
                    font.family: Theme.monoFont
                    font.pixelSize: 11
                    textFormat: TextEdit.PlainText
                    Txt {
                        visible: pasteEdit.text.length === 0
                        role: "mono"
                        font.pixelSize: 11
                        color: Theme.textFaint
                        text: "Colle ici le contenu du .ovpn ou du .conf WireGuard…"
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Txt {
                Layout.fillWidth: true
                role: "caption"
                color: Theme.textFaint
                text: /\[Interface\]/.test(pasteEdit.text) ? "Détecté : WireGuard" : (pasteEdit.text.length ? "Détecté : OpenVPN" : "")
            }
            Button {
                variant: "primary"
                icon: "add"
                text: "Ajouter"
                disabled: pasteName.text.trim().length === 0 || pasteEdit.text.trim().length === 0
                onClicked: {
                    Vpn.paste(pasteName.text.trim(), /\[Interface\]/.test(pasteEdit.text) ? "conf" : "ovpn", pasteEdit.text);
                    pasteEdit.text = "";
                    pasteName.text = "";
                    root.addMode = "";
                }
            }
        }
    }

    // WireGuard manuel
    GridLayout {
        Layout.fillWidth: true
        visible: root.addMode === "wg"
        columns: 2
        columnSpacing: 8
        rowSpacing: 6

        property string pub: ""

        Txt { role: "label"; text: "Nom" }
        Field { id: wgName; Layout.fillWidth: true; placeholder: "ex. Labo" }
        Txt { role: "label"; text: "Adresse" }
        Field { id: wgAddr; Layout.fillWidth: true; mono: true; placeholder: "10.0.0.2/32" }
        Txt { role: "label"; text: "DNS" }
        Field { id: wgDns; Layout.fillWidth: true; mono: true; placeholder: "facultatif" }
        Txt { role: "label"; text: "Clé privée" }
        RowLayout {
            Layout.fillWidth: true
            Field { id: wgPriv; Layout.fillWidth: true; mono: true; placeholder: "colle-la ou génère une paire" }
            Button {
                variant: "secondary"
                height_: Tokens.ctrl
                icon: "key"
                text: "Générer"
                onClicked: Vpn.genkey(r => {
                    if (r && r.private) {
                        wgPriv.text = r.private;
                        parent.parent.pub = r.public;
                    }
                })
            }
        }
        Item { width: 1; height: 1; visible: parent.pub.length > 0 }
        RowLayout {
            Layout.fillWidth: true
            visible: parent.pub.length > 0
            Txt { Layout.fillWidth: true; role: "mono"; font.pixelSize: 10; text: "Clé publique à donner au serveur : " + parent.parent.pub; color: Theme.accent2 }
            IconButton { icon: "content_copy"; size: 26; iconSize: 14; tooltip: "Copier"; onClicked: Ifaces.copy(parent.parent.pub) }
        }
        Txt { role: "label"; text: "Pair : clé publique" }
        Field { id: wgPeer; Layout.fillWidth: true; mono: true; placeholder: "clé publique du serveur" }
        Txt { role: "label"; text: "Clé partagée" }
        Field { id: wgPsk; Layout.fillWidth: true; mono: true; placeholder: "facultatif (PresharedKey)" }
        Txt { role: "label"; text: "Endpoint" }
        Field { id: wgEnd; Layout.fillWidth: true; mono: true; placeholder: "vpn.exemple.com:51820" }
        Txt { role: "label"; text: "Réseaux" }
        Field { id: wgAllowed; Layout.fillWidth: true; mono: true; placeholder: "0.0.0.0/0, ::/0 (tout) ou 10.10.10.0/24" }
        Txt { role: "label"; text: "Keepalive" }
        Field { id: wgKa; Layout.fillWidth: true; mono: true; placeholder: "25 (s, facultatif)" }

        Item { width: 1; height: 1 }
        Button {
            Layout.alignment: Qt.AlignRight
            variant: "primary"
            icon: "add"
            text: "Créer le WireGuard"
            disabled: !wgName.text.trim().length || !wgPriv.text.trim().length || !wgAddr.text.trim().length || !wgPeer.text.trim().length || !wgEnd.text.trim().length
            onClicked: {
                Vpn.wgManual({ name: wgName.text.trim(), privateKey: wgPriv.text.trim(), address: wgAddr.text.trim(), dns: wgDns.text.trim(), peerPublicKey: wgPeer.text.trim(), presharedKey: wgPsk.text.trim(), endpoint: wgEnd.text.trim(), allowedIps: wgAllowed.text.trim(), keepalive: Number(wgKa.text) || 0 });
                for (const f of [wgName, wgAddr, wgDns, wgPriv, wgPeer, wgPsk, wgEnd, wgAllowed, wgKa])
                    f.text = "";
                root.addMode = "";
            }
        }
    }

    Txt {
        Layout.fillWidth: true
        role: "caption"
        color: Theme.textFaint
        wrapMode: Text.WordWrap
        text: "Types installés : " + Vpn.types.join(", ") + ". Autres VPN via leur plugin NetworkManager : networkmanager-openconnect (AnyConnect, GlobalProtect, Fortinet, Pulse), -strongswan (IPsec/IKEv2), -l2tp, -vpnc (Cisco IPsec), -sstp, -pptp. Exports dans ~/Documents/VPN, droits 600."
    }
}
