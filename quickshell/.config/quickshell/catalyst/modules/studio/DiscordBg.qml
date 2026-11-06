pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.rice
import qs.kit

// Fond de la conversation Discord (thème Vesktop « Tsubasa Catalyst »).
// Tout passe par scripts/discord-bg.py, qui intègre l'image au thème ;
// Vesktop le recharge à chaud. L'aperçu montre l'image telle que traitée.
Group {
    id: root

    readonly property string script: Quickshell.env("HOME") + "/.config/quickshell/catalyst/scripts/discord-bg.py"
    property var st: ({ source: "", dim: 0.78, blur: 2, applied: false, mark1: "TSUBASA", mark2: "CATALYST", rail: "left", shape: "soft", image: "", error: "" })
    property bool busy: false
    property int rev: 0     // force le rechargement de l'aperçu (même chemin)

    function run(args) {
        ctl.buf = "";
        ctl.command = ["python3", root.script].concat(args);
        busy = true;
        ctl.running = true;
    }
    // Le Studio reste au premier plan et serait détruit à la fermeture avec
    // tout processus enfant : on le ferme et le script, détaché, ouvre le
    // sélecteur puis rouvre le Studio sur cette page.
    function pick() {
        Quickshell.execDetached(["python3", root.script, "pick"]);
        PanelService.hide();
    }

    Component.onCompleted: run(["status"])

    Process {
        id: ctl
        property string buf: ""
        stdout: SplitParser { onRead: d => ctl.buf += d }
        onExited: {
            root.busy = false;
            try {
                root.st = JSON.parse(ctl.buf);
                root.rev++;
            } catch (e) {
                root.st = Object.assign({}, root.st, { error: "Réponse illisible du script" });
            }
        }
    }
    // les curseurs émettent en continu : on n'écrit le thème qu'à la fin du geste
    Timer {
        id: dimApply
        interval: 350
        onTriggered: root.run(["dim", root.st.dim.toFixed(2)])
    }
    Timer {
        id: blurApply
        interval: 450
        onTriggered: root.run(["blur", String(root.st.blur)])
    }

    SettingRow {
        Layout.fillWidth: true
        icon: "forum"
        title: "Discord"
        subtitle: root.st.error.length ? root.st.error
            : root.st.applied ? root.st.source.split("/").pop()
            : "Image derrière la conversation (Vesktop, mise à jour en direct)"

        Art {
            width: 96
            height: 54
            radius: Tokens.rSm
            source: root.st.applied ? "file://" + root.st.image + "?" + root.rev : ""
            fallbackIcon: "image"
        }
        Button {
            icon: "folder_open"
            text: "Choisir…"
            variant: "primary"
            busy: root.busy
            disabled: root.busy
            onClicked: root.pick()
        }
        IconButton {
            icon: "wallpaper"
            variant: "tonal"
            tooltip: "Utiliser le fond du bureau"
            visible: Walls.current.length > 0 && !Walls.isVideo(Walls.current)
            onClicked: root.run(["set", Walls.current])
        }
        IconButton {
            icon: "close"
            variant: "tonal"
            tooltip: "Retirer le fond"
            visible: root.st.applied
            onClicked: root.run(["clear"])
        }
    }

    SettingRow {
        Layout.fillWidth: true
        icon: "dock_to_bottom"
        title: "Serveurs"
        subtitle: "Position de la barre des serveurs (en haut / dock : Maj + molette pour défiler)"

        Segmented {
            compact: true
            model: [
                { id: "left", label: "Gauche", icon: "dock_to_right" },
                { id: "right", label: "Droite", icon: "dock_to_left" },
                { id: "top", label: "Haut", icon: "toolbar" },
                { id: "dock", label: "Dock", icon: "dock_to_bottom" }
            ]
            current: root.st.rail ?? "left"
            onSelected: id => {
                root.st = Object.assign({}, root.st, { rail: id });
                root.run(["rail", id]);
            }
        }
    }

    SettingRow {
        Layout.fillWidth: true
        icon: "rounded_corner"
        title: "Icônes des serveurs"
        subtitle: "Forme des icônes, dossiers et boutons de la barre"

        Segmented {
            compact: true
            model: [
                { id: "round", label: "Rond", icon: "circle" },
                { id: "soft", label: "Doux", icon: "rounded_corner" },
                { id: "square", label: "Carré", icon: "crop_square" }
            ]
            current: root.st.shape ?? "soft"
            onSelected: id => {
                root.st = Object.assign({}, root.st, { shape: id });
                root.run(["shape", id]);
            }
        }
    }

    // signature de la barre du haut : appliquée sur Entrée ou au bouton
    SettingRow {
        Layout.fillWidth: true
        icon: "title"
        title: "Signature"
        subtitle: "Texte de la barre du haut — vide les deux champs pour revenir au défaut"

        Field {
            id: mark1
            width: 130
            placeholder: "TSUBASA"
            text: root.st.mark1 ?? ""
            onAccepted: root.run(["mark", mark1.text, mark2.text])
        }
        Field {
            id: mark2
            width: 130
            placeholder: "CATALYST"
            text: root.st.mark2 ?? ""
            onAccepted: root.run(["mark", mark1.text, mark2.text])
        }
        IconButton {
            icon: "check"
            variant: "tonal"
            tooltip: "Appliquer"
            disabled: root.busy
            onClicked: root.run(["mark", mark1.text, mark2.text])
        }
    }

    SettingRow {
        Layout.fillWidth: true
        visible: root.st.applied
        icon: "contrast"
        title: "Voile"
        subtitle: "Assombrit l'image pour garder le texte lisible"
        Slider {
            width: 220
            implicitHeight: 30
            icon: "dark_mode"
            maximum: 0.95
            value: root.st.dim
            onMoved: v => {
                root.st = Object.assign({}, root.st, { dim: v });
                dimApply.restart();
            }
        }
    }

    SettingRow {
        Layout.fillWidth: true
        visible: root.st.applied
        icon: "blur_on"
        title: "Flou"
        subtitle: "Appliqué à l'image une fois pour toutes (aucun coût dans Discord)"
        Slider {
            width: 220
            implicitHeight: 30
            icon: "blur_on"
            value: root.st.blur / 12
            step: 1 / 12
            valueText: root.st.blur + " px"
            onMoved: v => {
                root.st = Object.assign({}, root.st, { blur: Math.round(v * 12) });
                blurApply.restart();
            }
        }
    }
}
