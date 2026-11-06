# NixOS module for tsu-dots (EXPERIMENTAL): what can only be set system-wide
{ config, lib, pkgs, ... }:

let
  cfg = config.tsu-dots;
in
{
  options.tsu-dots = {
    enable = lib.mkEnableOption "the system side of tsu-dots (Hyprland session, portals, polkit)";
    vm = lib.mkEnableOption "libvirt / QEMU for the VM panel";
    cam = lib.mkEnableOption "the v4l2loopback virtual camera";
  };

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };
    programs.zsh.enable = true;

    security.polkit.enable = true;
    services.upower.enable = true;
    services.gnome.gnome-keyring.enable = true;
    networking.networkmanager.enable = lib.mkDefault true;
    hardware.bluetooth.enable = lib.mkDefault true;
    hardware.i2c.enable = true; # ddcutil (external monitor brightness)

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    virtualisation.libvirtd.enable = cfg.vm;
    programs.virt-manager.enable = cfg.vm;

    boot.extraModulePackages = lib.optionals cfg.cam [ config.boot.kernelPackages.v4l2loopback ];
    boot.kernelModules = lib.optionals cfg.cam [ "v4l2loopback" ];
  };
}
