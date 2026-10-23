pragma ComponentBehavior: Bound
import QtQuick
import qs.rice
import qs.kit
import "../../components"

// Fenêtre active de l'écran : icône d'app + titre (classe en sous-texte au
// survol). Masqué quand le workspace est vide.
BarItem {
    id: root

    property string outputName: ""
    property int maxWidth: 360

    // fenêtre du workspace actif de CET écran uniquement (vide → rien)
    readonly property var win: {
        const spaces = Niri.workspacesOn(outputName);
        let ws = null;
        for (let i = 0; i < spaces.length; i++)
            if (spaces[i].is_active || spaces[i].is_focused)
                ws = spaces[i];
        if (!ws)
            return null;
        const wins = Niri.windows;
        let first = null;
        for (let i = 0; i < wins.length; i++) {
            if (wins[i].workspace_id !== ws.id)
                continue;
            if (wins[i].is_focused || wins[i].id === ws.active_window_id)
                return wins[i];
            if (!first)
                first = wins[i];
        }
        return first;
    }
    readonly property string appId: win ? String(win.app_id || "") : ""
    readonly property string title: {
        if (!win)
            return "";
        const t = String(win.title || "").trim();
        return t.length ? t : appId;
    }

    visible: title.length > 0
    tooltip: appId.length && title !== appId ? appId : ""
    padX: 8
    spacing: 8

    onClicked: mouse => {
        if (mouse.button === Qt.MiddleButton && root.win)
            Niri.closeWindow(root.win.id);
        else
            PanelService.toggle("overview", root.outputName);
    }

    AppIcon {
        appId: root.appId
        size: 16
        plain: true
        anchors.verticalCenter: parent.verticalCenter
    }

    Txt {
        role: "label"
        text: root.title
        color: Theme.textSub
        width: Math.min(implicitWidth, root.maxWidth)
        anchors.verticalCenter: parent.verticalCenter
    }
}
