# home-manager module for tsu-dots (EXPERIMENTAL, not tested on real NixOS hardware)
#
# The rice writes to its own files (Studio settings, widgets, wallpapers…), so the
# configs are linked to a mutable clone of the repo, not copied into the Nix store.
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.tsu-dots;
  link = path: config.lib.file.mkOutOfStoreSymlink "${cfg.path}/${path}";

  python = pkgs.python3.withPackages (ps:
    [ ps.pygobject3 ps.dbus-python ps.pillow ]
    ++ lib.optionals cfg.cam [ ps.numpy ps.opencv4 ps.onnxruntime ]);
in
{
  options.programs.tsu-dots = {
    enable = lib.mkEnableOption "tsu-dots (Tsubasa Catalyst)";

    path = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.tsu-dots";
      description = "Where the tsu-dots repo is cloned (configs are symlinked from there).";
    };

    vm = lib.mkEnableOption "VM panel tools (enable virtualisation in the NixOS module too)";
    vpn = lib.mkEnableOption "VPN panel tools (WireGuard, OpenVPN, ProtonVPN)";
    cam = lib.mkEnableOption "virtual camera tools (enable v4l2loopback in the NixOS module too)";
    security = lib.mkEnableOption "a few base security tools for the Ops panel (no BlackArch on Nix)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # core
      hypridle hyprlock hyprpicker hyprsunset hyprpolkitagent
      kdePackages.polkit-kde-agent-1 nwg-displays xdg-utils xdg-user-dirs
      qt6.qtwayland

      # catalyst shell + tools its panels call
      quickshell qt6.qt5compat qt6.qtsvg qt6.qtimageformats
      awww mpv mpvpaper matugen imagemagick ffmpeg ffmpegthumbnailer
      rofi alacritty zenity
      wl-clipboard cliphist grim slurp satty wf-recorder
      playerctl brightnessctl ddcutil cava libnotify lm_sensors
      wtype socat jq bc fzf libsecret
      translate-shell tesseract yt-dlp
      python

      # terminal / editor
      kitty ghostty tmux fastfetch neovim ripgrep fd stow

      # fonts / icons / theming
      nerd-fonts.jetbrains-mono nerd-fonts.symbols-only inter material-symbols
      noto-fonts noto-fonts-cjk-sans noto-fonts-color-emoji
      papirus-icon-theme bibata-cursors
      nwg-look adw-gtk3 libsForQt5.qt5ct qt6Packages.qt6ct
    ]
    ++ lib.optionals cfg.vm [ virt-manager qemu ]
    ++ lib.optionals cfg.vpn [ wireguard-tools openvpn networkmanager-openvpn proton-vpn ]
    ++ lib.optionals cfg.cam [ v4l-utils ]
    ++ lib.optionals cfg.security [ nmap wireshark tcpdump netcat-openbsd proxychains-ng ];

    fonts.fontconfig.enable = true;

    # Same layout as `stow` would create
    xdg.configFile = {
      "hypr".source = link "hyprland/.config/hypr";
      "uwsm".source = link "hyprland/.config/uwsm";
      "quickshell".source = link "quickshell/.config/quickshell";
      "niri/scripts".source = link "niri/.config/niri/scripts";
      "kitty".source = link "kitty/.config/kitty";
      "alacritty".source = link "alacritty/.config/alacritty";
      "ghostty".source = link "ghostty/.config/ghostty";
      "nvim".source = link "nvim/.config/nvim";
      "fastfetch".source = link "fastfetch/.config/fastfetch";
      "gtk-3.0".source = link "theming/.config/gtk-3.0";
      "gtk-4.0".source = link "theming/.config/gtk-4.0";
      "qt5ct".source = link "theming/.config/qt5ct";
      "qt6ct".source = link "theming/.config/qt6ct";
      "kdeglobals".source = link "kde/.config/kdeglobals";
    };

    home.file = {
      ".zshrc".source = link "zsh/.zshrc";
      ".p10k.zsh".source = link "zsh/.p10k.zsh";
      ".tmux.conf".source = link "tmux/.tmux.conf";
      ".local/bin/tsu".source = link "local/.local/bin/tsu";
      ".local/scripts".source = link "local/.local/scripts";
    };
  };
}
