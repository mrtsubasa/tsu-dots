pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

// « Rester éveillé » : inhibe la mise en veille via le protocole Wayland
// idle-inhibit (respecté par Hyprland/hypridle). L'inhibiteur lui-même vit
// dans la barre du premier écran (il a besoin d'une surface visible).
Singleton {
    property bool on: false

    function toggle() {
        on = !on;
    }
}
