import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.rice
import qs.kit

// Image personnalisée (artwork, personnage…). Choix via le sélecteur de
// fichiers (zenity / kdialog) ; le chemin est persisté dans le widget.
Item {
    id: root
    property string wid: ""
    readonly property string src: (WidgetStore.get(wid).props || {}).src || ""

    function pick() {
        picker.running = true;
    }

    Art {
        anchors.fill: parent
        visible: root.src.length > 0
        source: root.src.length ? "file://" + root.src : ""
        radius: Tokens.rLg
        fallbackIcon: "broken_image"
    }

    EmptyState {
        anchors.centerIn: parent
        visible: root.src.length === 0
        icon: "add_photo_alternate"
        title: "Aucune image"
        actionText: "Choisir…"
        onAction: root.pick()
    }

    MouseArea {
        anchors.fill: parent
        visible: root.src.length > 0
        acceptedButtons: Qt.RightButton
        onClicked: root.pick()
    }

    Process {
        id: picker
        command: ["sh", "-c", "if command -v kdialog >/dev/null; then kdialog --getopenfilename \"$HOME/Images\" 'image/png image/jpeg image/webp image/gif'; else zenity --file-selection --file-filter='Images | *.png *.jpg *.jpeg *.webp *.gif'; fi"]
        stdout: SplitParser {
            onRead: data => {
                const p = data.trim();
                if (p.length)
                    WidgetStore.setProps(root.wid, { src: p });
            }
        }
    }
}
