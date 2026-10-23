pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.rice
import qs.kit

// Profils : instantanés complets (thème, barre, dock, widgets, densité,
// identité). Chaque chargement sauvegarde d'abord l'état courant (« Annuler »).
ColumnLayout {
    id: root
    spacing: 16

    property string renaming: ""

    Component.onCompleted: Profiles.refresh()

    Group {
        Layout.fillWidth: true

        SettingRow {
            Layout.fillWidth: true
            icon: "bookmark_add"
            title: "Enregistrer la configuration actuelle"
            subtitle: "Thème, barre, dock, widgets et réglages d'interface"
            Field {
                id: nameField
                width: 200
                placeholder: "Nom du profil"
                onAccepted: t => saveBtn.clicked(null)
            }
            Button {
                id: saveBtn
                variant: "primary"
                icon: "save"
                text: "Enregistrer"
                disabled: nameField.text.trim().length === 0 || Profiles.busy
                onClicked: {
                    Profiles.save(nameField.text.trim());
                    nameField.text = "";
                }
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "undo"
            title: "Annuler le dernier chargement"
            subtitle: Profiles.canUndo ? "Revient à l'état d'avant le dernier profil ou réinitialisation" : "Aucun état précédent"
            Button {
                variant: "secondary"
                icon: "undo"
                text: "Annuler"
                disabled: !Profiles.canUndo || Profiles.busy
                onClicked: Profiles.undo()
            }
        }
        SettingRow {
            Layout.fillWidth: true
            icon: "restart_alt"
            title: "Réglages par défaut"
            subtitle: "Catalyst Dark, barre capsule, ordre par défaut. Les widgets et le dock sont conservés."
            Button {
                id: resetBtn
                property bool armed: false
                variant: armed ? "danger" : "secondary"
                icon: "restart_alt"
                text: armed ? "Confirmer" : "Réinitialiser"
                disabled: Profiles.busy
                onClicked: {
                    if (!armed) {
                        armed = true;
                        disarm.restart();
                        return;
                    }
                    armed = false;
                    Profiles.defaults();
                }
                Timer {
                    id: disarm
                    interval: 4000
                    onTriggered: resetBtn.armed = false
                }
            }
        }
    }

    Txt {
        Layout.fillWidth: true
        visible: Profiles.note.length > 0
        role: "caption"
        text: Profiles.note
        color: Theme.accent2
        wrapMode: Text.WordWrap
    }

    SectionHeader { Layout.fillWidth: true; text: "Mes profils  " + Profiles.user.length }

    EmptyState {
        Layout.fillWidth: true
        visible: Profiles.user.length === 0
        icon: "bookmarks"
        title: "Aucun profil"
        text: "Enregistre ta configuration pour pouvoir y revenir à tout moment."
    }

    Group {
        Layout.fillWidth: true
        visible: Profiles.user.length > 0
        Repeater {
            model: Profiles.user
            SettingRow {
                id: prof
                required property var modelData
                Layout.fillWidth: true
                icon: "bookmark"
                title: modelData.name
                subtitle: "Enregistré le " + Qt.formatDateTime(new Date(modelData.created * 1000), "dd/MM/yyyy à HH:mm")

                Field {
                    id: rn
                    visible: root.renaming === prof.modelData.id
                    width: 170
                    placeholder: prof.modelData.name
                    onAccepted: t => {
                        if (t.trim().length)
                            Profiles.rename(prof.modelData.id, t.trim());
                        root.renaming = "";
                    }
                }
                Button {
                    variant: "primary"
                    text: "Appliquer"
                    disabled: Profiles.busy
                    onClicked: Profiles.load(prof.modelData.id)
                }
                IconButton { icon: "edit"; size: 30; iconSize: 17; tooltip: "Renommer"; onClicked: { root.renaming = root.renaming === prof.modelData.id ? "" : prof.modelData.id; rn.forceActiveFocus(); } }
                IconButton { icon: "content_copy"; size: 30; iconSize: 17; tooltip: "Dupliquer"; onClicked: Profiles.duplicate(prof.modelData.id) }
                IconButton { icon: "delete"; size: 30; iconSize: 17; variant: "danger"; tooltip: "Supprimer"; onClicked: Profiles.remove(prof.modelData.id) }
            }
        }
    }
}
