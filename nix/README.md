# tsu-dots sur NixOS — expérimental

> ⚠️ Ce flake **s'évalue** (vérifié dans un conteneur Nix : la config home-manager d'exemple
> et un système NixOS de test produisent leurs dérivations), mais il **n'a jamais tourné sur
> une vraie machine NixOS**. Retours bienvenus.

Deux modules :

| Module | Rôle |
| --- | --- |
| `nixosModules.default` | côté système : session Hyprland (UWSM), portails, polkit, upower, keyring, i2c (ddcutil), et en option libvirt / v4l2loopback |
| `homeManagerModules.default` | côté utilisateur : paquets + liens de `~/.tsu-dots` vers `~/.config` (comme Stow) |

Les configs sont liées vers **ton clone** (`mkOutOfStoreSymlink`), pas copiées dans le store :
le Studio de Catalyst écrit dans ses propres fichiers (réglages, widgets, fonds d'écran).

## Installation

```bash
git clone https://github.com/mrtsubasa/tsu-dots.git ~/.tsu-dots
```

Dans le `flake.nix` de ton système :

```nix
{
  inputs.tsu-dots.url = "github:mrtsubasa/tsu-dots";

  outputs = { nixpkgs, home-manager, tsu-dots, ... }: {
    nixosConfigurations.ma-machine = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        tsu-dots.nixosModules.default
        { tsu-dots = { enable = true; vm = false; cam = false; }; }

        home-manager.nixosModules.home-manager
        {
          home-manager.users.moi = {
            imports = [ tsu-dots.homeManagerModules.default ];
            programs.tsu-dots = {
              enable = true;
              # path = "/home/moi/.tsu-dots";  # par défaut
              vpn = true;
            };
          };
        }
      ];
    };
  };
}
```

Options home-manager : `enable`, `path`, `vm`, `vpn`, `cam`, `security`.
Options NixOS : `tsu-dots.enable`, `tsu-dots.vm`, `tsu-dots.cam`.

## Ce qui ne marche pas (encore) sur Nix

- **Arsenal / BlackArch** : dépôt pacman, sans équivalent. `security = true` n'installe que quelques outils de base.
- **Panneau Paquets** et compteur de mises à jour : basés sur pacman/paru.
- Les scripts ont des chemins Arch par endroits (`/usr/share/...`, `/usr/lib/...`).
- Si tu gères déjà `~/.config/hypr`, `~/.zshrc`, etc. avec home-manager, désactive-les sinon les liens entrent en conflit.
