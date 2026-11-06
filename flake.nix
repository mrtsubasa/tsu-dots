{
  description = "tsu-dots — Tsubasa Catalyst (Hyprland + Quickshell) — EXPERIMENTAL Nix support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # System side: Hyprland session, portals, polkit, optional libvirt / v4l2loopback
      nixosModules.default = import ./nix/nixos.nix;

      # User side: packages + links from ~/.tsu-dots into ~/.config
      homeManagerModules.default = import ./nix/home.nix;

      # Example standalone home-manager config, also used to check that everything evaluates:
      #   nix build .#homeConfigurations.example.activationPackage --dry-run
      homeConfigurations.example = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          self.homeManagerModules.default
          {
            home.username = "example";
            home.homeDirectory = "/home/example";
            home.stateVersion = "25.05";
            programs.tsu-dots = {
              enable = true;
              vm = true;
              vpn = true;
              cam = true;
              security = true;
            };
          }
        ];
      };
    };
}
