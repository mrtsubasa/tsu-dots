#!/bin/bash
# =============================================================================
#
#   ▀█▀ █▀ █ █ ▄▄ █▀▄ █▀█ ▀█▀ █▀
#    █  ▄█ █▄█    █▄▀ █▄█  █  ▄█
#
#   Installation Script (Arch family: Arch, CachyOS, EndeavourOS, BlackArch...)
#   https://github.com/mrtsubasa/tsu-dots
#
# =============================================================================

set -e

# =============================================================================
# Configuration
# =============================================================================
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_DIR="$DOTFILES_DIR/.install/packages"
SETUP_DIR="$DOTFILES_DIR/.install/setup"

# Every category, in menu order
ALL_CATEGORIES=(core catalyst terminal editor apps utils fonts theming vm vpn cam security nvidia)
RECOMMENDED_CATEGORIES=(core catalyst terminal editor apps utils fonts theming)
DRY_RUN=0
FAILED_PACKAGES=()

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# =============================================================================
# Logging functions
# =============================================================================
log_header() {
    echo ""
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}  $1${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${CYAN}[>>]${NC} $1"; }

# =============================================================================
# Initial checks
# =============================================================================
detect_distro() {
    DISTRO_ID="unknown"
    DISTRO_NAME="unknown"
    DISTRO_LIKE=""
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        DISTRO_ID="$(. /etc/os-release && echo "${ID:-unknown}")"
        DISTRO_NAME="$(. /etc/os-release && echo "${PRETTY_NAME:-${ID:-unknown}}")"
        DISTRO_LIKE="$(. /etc/os-release && echo "${ID_LIKE:-}")"
    fi

    if [[ "$DISTRO_ID" == "nixos" ]]; then
        log_error "NixOS detected: this script does not apply."
        log_info "Use the flake instead (home-manager module, experimental): see nix/README.md"
        exit 1
    fi

    if ! command -v pacman &>/dev/null || [[ ! -f /etc/arch-release && " $DISTRO_ID $DISTRO_LIKE " != *" arch "* ]]; then
        log_error "Unsupported distribution: $DISTRO_NAME"
        log_info "tsu-dots needs an Arch-based system (Arch, CachyOS, EndeavourOS, Manjaro, Garuda, BlackArch...)."
        log_info "Dependency list for other distributions: .install/README.md"
        exit 1
    fi

    log_info "Distribution: $DISTRO_NAME"
    local repos
    repos=" $(pacman-conf --repo-list 2>/dev/null | tr '\n' ' ') "
    [[ "$repos" == *" cachyos"* ]] && log_info "CachyOS repos detected: optimized builds will be used"
    [[ "$repos" == *" blackarch "* ]] && log_info "BlackArch repo detected: the security category needs no extra repo"
    [[ "$repos" == *" chaotic-aur "* ]] && log_info "Chaotic-AUR detected: AUR packages come prebuilt when available"
    if [[ "$DISTRO_ID" == "manjaro" ]]; then
        log_warn "Manjaro lags behind Arch: Hyprland >= 0.57 (Lua config) may not be in its repos yet."
    fi
    return 0
}

# Kept for the --stow-only / --setup-only paths
check_arch() { detect_distro; }

check_internet() {
    log_step "Checking internet connection..."
    if ! curl -fsS --max-time 10 -o /dev/null https://archlinux.org; then
        log_error "No internet connection!"
        exit 1
    fi
    log_info "Connection OK"
}

check_aur_helper() {
    if command -v yay &>/dev/null; then
        AUR_HELPER="yay"
    elif command -v paru &>/dev/null; then
        AUR_HELPER="paru"
    else
        log_warn "No AUR helper found (yay/paru)"
        log_info "Installing yay..."
        install_yay
        AUR_HELPER="yay"
    fi
    log_info "AUR helper: $AUR_HELPER"
}

install_yay() {
    sudo pacman -S --needed --noconfirm git base-devel
    local TEMP_DIR=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$TEMP_DIR/yay"
    cd "$TEMP_DIR/yay"
    makepkg -si --noconfirm
    cd "$DOTFILES_DIR"
    rm -rf "$TEMP_DIR"
}

# =============================================================================
# Package installation
# =============================================================================
install_packages() {
    local CATEGORY=$1
    local PACKAGES_FILE="$PACKAGES_DIR/${CATEGORY}.sh"

    if [[ ! -f "$PACKAGES_FILE" ]]; then
        log_error "Package file not found: $PACKAGES_FILE"
        return 1
    fi

    # Load package arrays
    source "$PACKAGES_FILE"

    local ARRAY_NAME="${CATEGORY^^}_PACKAGES"
    local AUR_ARRAY_NAME="${CATEGORY^^}_AUR_PACKAGES"
    local -n PACKAGES_REF="$ARRAY_NAME"
    local -n AUR_PACKAGES_REF="$AUR_ARRAY_NAME"

    # Sort by where each package really lives on this system: anything a repo
    # provides (official, CachyOS, Chaotic-AUR, BlackArch) goes through pacman,
    # the rest through the AUR helper.
    local repo=() aur=() p
    for p in "${PACKAGES_REF[@]}" "${AUR_PACKAGES_REF[@]}"; do
        [[ -z "$p" ]] && continue
        if pacman -Si "$p" &>/dev/null || pacman -Sg "$p" &>/dev/null; then
            repo+=("$p")
        else
            aur+=("$p")
        fi
    done

    if [[ $DRY_RUN -eq 1 ]]; then
        echo "  repos: ${repo[*]:-(none)}"
        echo "  AUR:   ${aur[*]:-(none)}"
        return 0
    fi

    if [[ ${#repo[@]} -gt 0 ]]; then
        log_step "Installing repo packages ($CATEGORY)..."
        if ! sudo pacman -S --needed --noconfirm "${repo[@]}"; then
            log_warn "Batch failed, retrying one by one..."
            for p in "${repo[@]}"; do
                sudo pacman -S --needed --noconfirm "$p" || FAILED_PACKAGES+=("$p")
            done
        fi
    fi

    if [[ ${#aur[@]} -gt 0 ]]; then
        log_step "Installing AUR packages ($CATEGORY)..."
        if ! $AUR_HELPER -S --needed --noconfirm "${aur[@]}"; then
            log_warn "Batch failed, retrying one by one..."
            for p in "${aur[@]}"; do
                $AUR_HELPER -S --needed --noconfirm "$p" || FAILED_PACKAGES+=("$p")
            done
        fi
    fi
    return 0
}

# =============================================================================
# Category selection menu
# =============================================================================
show_menu() {
    echo ""
    echo -e "${CYAN}Select categories to install:${NC}"
    echo ""
    echo "   1) core       - Hyprland, UWSM, portals, idle/lock (ESSENTIAL)"
    echo "   2) catalyst   - Quickshell shell + its tools: awww, matugen, rofi... (ESSENTIAL)"
    echo "   3) terminal   - Alacritty, Ghostty, Kitty, Zsh, Tmux, Fastfetch"
    echo "   4) editor     - Neovim + development tools"
    echo "   5) apps       - Dolphin, Zen Browser, Spotify, mpv"
    echo "   6) utils      - Network, Bluetooth, audio, EasyEffects, btop"
    echo "   7) fonts      - JetBrainsMono Nerd, Inter, Material Symbols, Papirus"
    echo "   8) theming    - GTK/Qt theming (qt5ct, qt6ct, adw-gtk3)"
    echo "   9) vm         - libvirt / QEMU for the VM panel"
    echo "  10) vpn        - WireGuard, OpenVPN, ProtonVPN for the VPN panel"
    echo "  11) cam        - virtual camera, filters, scene compositor"
    echo "  12) security   - BlackArch repo + base tools for Arsenal/Ops (asks first)"
    echo "  13) nvidia     - NVIDIA environment (only with an NVIDIA GPU)"
    echo ""
    echo "   a) RECOMMENDED - 1 to 8"
    echo "   f) FULL        - 1 to 11"
    echo "   q) QUIT"
    echo ""
}

get_selection() {
    local SELECTED=()

    while true; do
        show_menu
        echo -ne "${BLUE}Select numbers or letters separated by spaces: ${NC}"
        read -r input

        case "$input" in
        q | Q)
            log_info "Installation cancelled."
            exit 0
            ;;
        a | A)
            SELECTED=("${RECOMMENDED_CATEGORIES[@]}")
            break
            ;;
        f | F)
            SELECTED=("${RECOMMENDED_CATEGORIES[@]}" vm vpn cam)
            break
            ;;
        *)
            for num in $input; do
                if [[ "$num" =~ ^[0-9]+$ && $num -ge 1 && $num -le ${#ALL_CATEGORIES[@]} ]]; then
                    SELECTED+=("${ALL_CATEGORIES[$((num - 1))]}")
                else
                    log_warn "Invalid option: $num"
                fi
            done

            if [[ ${#SELECTED[@]} -gt 0 ]]; then
                break
            fi
            ;;
        esac
    done

    # Remove duplicates, keep menu order (core and catalyst first)
    CATEGORIES=()
    local c
    for c in "${ALL_CATEGORIES[@]}"; do
        [[ " ${SELECTED[*]} " == *" $c "* ]] && CATEGORIES+=("$c")
    done
    return 0
}

# =============================================================================
# Setup functions
# =============================================================================
run_stow() {
    log_header "Creating Symlinks (Stow)"
    source "$SETUP_DIR/stow.sh"
    run_stow_main
}

run_hyprland_setup() {
    log_header "Configuring Hyprland"
    source "$SETUP_DIR/hyprland.sh"
    run_hyprland_main
}

setup_zsh() {
    log_header "Configuring Zsh"

    # Change default shell to zsh
    if [[ "$SHELL" != *"zsh"* ]]; then
        log_step "Changing default shell to Zsh..."
        chsh -s $(which zsh)
        log_info "Shell changed to Zsh. Log out/in to apply."
    else
        log_info "Zsh is already the default shell."
    fi

    # Install Oh-My-Zsh
    local ZSH_DIR="$HOME/.oh-my-zsh"
    if [[ ! -d "$ZSH_DIR" ]]; then
        log_step "Installing Oh-My-Zsh..."
        git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$ZSH_DIR"
        log_info "Oh-My-Zsh installed."
    else
        log_info "Oh-My-Zsh is already installed."
    fi

    # Install plugins and themes
    local ZSH_CUSTOM_DIR="$ZSH_DIR/custom"
    local ZSH_DEPS=(
        "https://github.com/zsh-users/zsh-autosuggestions|plugins/zsh-autosuggestions"
        "https://github.com/zsh-users/zsh-syntax-highlighting|plugins/zsh-syntax-highlighting"
        "https://github.com/jeffreytse/zsh-vi-mode|plugins/zsh-vi-mode"
        "https://github.com/romkatv/powerlevel10k|themes/powerlevel10k"
    )

    for item in "${ZSH_DEPS[@]}"; do
        local URL="${item%%|*}"
        local DEST="${item##*|}"
        local NAME=$(basename "$DEST")

        if [[ ! -d "$ZSH_CUSTOM_DIR/$DEST" ]]; then
            log_step "Installing $NAME..."
            git clone --depth=1 "$URL" "$ZSH_CUSTOM_DIR/$DEST"
            log_info "$NAME installed."
        else
            log_info "$NAME is already installed."
        fi
    done
}

setup_tmux() {
    log_header "Configuring Tmux"

    # Install TPM (Tmux Plugin Manager)
    local TPM_DIR="$HOME/.tmux/plugins/tpm"
    if [[ ! -d "$TPM_DIR" ]]; then
        log_step "Installing TPM (Tmux Plugin Manager)..."
        git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
        log_info "TPM installed. Use prefix + I inside tmux to install plugins."
    else
        log_info "TPM is already installed."
    fi
}

setup_services() {
    log_header "Enabling Services"

    # Bluetooth
    if systemctl list-unit-files | grep -q "bluetooth.service"; then
        log_step "Enabling Bluetooth..."
        sudo systemctl enable --now bluetooth.service
    fi

    # NetworkManager
    if systemctl list-unit-files | grep -q "NetworkManager.service"; then
        log_step "Enabling NetworkManager..."
        sudo systemctl enable --now NetworkManager.service
    fi
}

setup_mimetypes() {
    log_header "Configuring Default Applications (MIME)"

    if command -v dolphin &>/dev/null; then
        log_step "Setting Dolphin as default file manager..."

        # Set Dolphin to open directories
        xdg-mime default org.kde.dolphin.desktop inode/directory

        # Update KDE services database
        if command -v kbuildsycoca6 &>/dev/null; then
            log_step "Updating KDE services cache..."
            kbuildsycoca6 >/dev/null 2>&1
        fi
    else
        log_warn "Dolphin not found. Skipping MIME types configuration."
    fi
}

setup_wallpaper() {
    log_header "Configuring Initial Wallpaper"

    local CURRENT_FILE="$HOME/.local/wallpapers/.current"
    local WALLPAPER
    if [[ -f "$CURRENT_FILE" ]]; then
        WALLPAPER="$(cat "$CURRENT_FILE")"
    fi
    # Fallback to default if .current doesn't exist or points to a missing file
    if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
        WALLPAPER="$HOME/.local/wallpapers/water.png"
    fi

    # Check if awww is installed
    if ! command -v awww &>/dev/null; then
        log_warn "awww is not installed. Skipping wallpaper configuration."
        return 0
    fi

    # Check if the wallpaper exists
    if [[ ! -f "$WALLPAPER" ]]; then
        log_warn "Wallpaper not found: $WALLPAPER"
        return 0
    fi

    # Check if running in a Wayland session
    if [[ -z "$WAYLAND_DISPLAY" ]]; then
        log_warn "Not in a Wayland session."
        log_info "The wallpaper will be applied automatically when Hyprland starts."
        return 0
    fi

    log_step "Starting awww daemon..."
    # Start daemon if not running
    if ! pgrep -f "awww-daemon" &>/dev/null; then
        awww-daemon >/dev/null 2>&1 &
    fi
    sleep 3

    # Check if daemon started
    if ! pgrep -f "awww-daemon" &>/dev/null; then
        log_warn "Could not start awww daemon."
        return 0
    fi

    log_step "Applying wallpaper"
    if awww img "$WALLPAPER" --transition-type grow --transition-duration 2 2>/dev/null; then
        log_info "Wallpaper configured successfully!"
    else
        log_warn "Failed to apply wallpaper."
    fi
}

setup_migrations() {
    log_header "Initializing Tsu CLI"

    local MIGRATIONS_DIR="$DOTFILES_DIR/.data/tsu-cli/migrations"
    local DONE_FILE="$HOME/.local/share/tsu/migrations-done"

    mkdir -p "$(dirname "$DONE_FILE")"
    touch "$DONE_FILE"

    # Mark all current migrations as done (fresh installs don't need them)
    local count=0
    for migration in "$MIGRATIONS_DIR"/*.sh; do
        [[ -f "$migration" ]] || continue
        local name
        name="$(basename "$migration")"
        if ! grep -qxF "$name" "$DONE_FILE" 2>/dev/null; then
            echo "$name" >> "$DONE_FILE"
            ((count++)) || true
        fi
    done

    log_info "Marked $count migrations as done (fresh install)"
}

setup_state_aur_helper() {
    local STATE_FILE="$HOME/.config/quickshell/state.json"

    if [[ ! -f "$STATE_FILE" ]]; then
        log_warn "state.json not found. Skipping AUR helper configuration."
        return 0
    fi

    if ! command -v jq &>/dev/null; then
        log_warn "jq not found. Skipping AUR helper configuration."
        return 0
    fi

    log_step "Setting AUR helper in state.json..."
    local TEMP_FILE
    TEMP_FILE=$(mktemp)
    jq --arg helper "$AUR_HELPER" '.system.aurHelper = $helper' "$STATE_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$STATE_FILE"
    log_info "AUR helper set to: $AUR_HELPER"
}

# =============================================================================
# Full installation
# =============================================================================
full_install() {
    log_header "Starting Full Installation"

    # Check internet and AUR helper now (after selection)
    check_internet

    log_step "Syncing and upgrading the system (pacman -Syu)..."
    sudo pacman -Syu --noconfirm

    check_aur_helper

    # Install stow first
    log_step "Installing GNU Stow..."
    sudo pacman -S --needed --noconfirm stow git

    # BlackArch repo before its packages
    if [[ " ${CATEGORIES[*]} " == *" security "* ]]; then
        source "$PACKAGES_DIR/security.sh"
        setup_security_repo || true
        sudo pacman -Sy --noconfirm
    fi

    # Install selected packages
    for category in "${CATEGORIES[@]}"; do
        log_header "Installing: ${category^^}"
        install_packages "$category"
    done

    # Run setup scripts
    run_stow
    run_hyprland_setup
    setup_state_aur_helper
    setup_mimetypes

    # Additional setup based on installed categories
    if [[ " ${CATEGORIES[*]} " == *" terminal "* ]]; then
        setup_zsh
        setup_tmux
    fi

    if [[ " ${CATEGORIES[*]} " == *" utils "* ]]; then
        setup_services
    fi

    if [[ " ${CATEGORIES[*]} " == *" catalyst "* ]]; then
        setup_wallpaper
    fi

    if [[ " ${CATEGORIES[*]} " == *" theming "* ]]; then
        setup_theming
    fi

    if [[ " ${CATEGORIES[*]} " == *" vm "* ]]; then
        setup_vm
    fi

    if [[ " ${CATEGORIES[*]} " == *" cam "* ]]; then
        setup_cam
    fi

    # Mark all existing migrations as done (fresh install)
    setup_migrations

    verify_install
}

# =============================================================================
# Post-install check
# =============================================================================
verify_install() {
    log_header "Checking the installation"

    local missing=() cmd font mod
    for cmd in Hyprland hyprctl quickshell awww matugen rofi alacritty cliphist grim slurp jq python3 stow; do
        command -v "$cmd" &>/dev/null || missing+=("command: $cmd")
    done
    for mod in gi dbus PIL; do
        python3 -c "import $mod" &>/dev/null || missing+=("python module: $mod")
    done
    if command -v fc-list &>/dev/null; then
        for font in "JetBrainsMono Nerd Font" "Inter" "Material Symbols Rounded"; do
            fc-list : family | grep -qi "$font" || missing+=("font: $font")
        done
    fi

    if [[ ${#missing[@]} -eq 0 ]]; then
        log_info "Everything Catalyst needs is installed."
    else
        log_warn "Missing (Catalyst will be partly broken until they are installed):"
        printf '  - %s\n' "${missing[@]}"
    fi
    return 0
}

# =============================================================================
# Reboot prompt
# =============================================================================
ask_reboot() {
    echo ""
    echo -ne "${YELLOW}Do you want to reboot the system now to apply all changes? [Y/n]: ${NC}"
    read -r do_reboot

    if [[ $do_reboot =~ ^[Yy]$ ]] || [[ -z "$do_reboot" ]]; then
        log_info "Rebooting..."
        sleep 2
        sudo reboot
    else
        log_info "Remember to reboot the system to apply all changes."
    fi
}

# =============================================================================
# Final summary
# =============================================================================
show_summary() {
    log_header "Installation Complete!"

    echo -e "${GREEN}Installed categories:${NC}"
    for cat in "${CATEGORIES[@]}"; do
        echo "  - $cat"
    done

    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Log out and select 'Hyprland (uwsm)' in your display manager"
    echo "  2. Or start manually with: uwsm start hyprland-uwsm.desktop"
    echo ""
    echo "  3. Set your monitors in ~/.config/hypr/monitors.lua"
    echo "  4. Customize everything from the Studio (right-click the ◆ in the bar)"
    echo ""

    if [[ " ${CATEGORIES[*]} " =~ " terminal " ]]; then
        echo "  5. In tmux, use prefix + I to install plugins"
    fi

    if [[ " ${CATEGORIES[*]} " =~ " nvidia " ]]; then
        echo ""
        echo -e "${YELLOW}NVIDIA:${NC}"
        echo "  - Review ~/.config/hypr/local/extra_environment.lua"
        echo "  - For hybrid GPUs, uncomment the AQ_DRM_DEVICES line"
    fi

    if [[ ${#FAILED_PACKAGES[@]} -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}Packages that failed to install:${NC} ${FAILED_PACKAGES[*]}"
    fi

    echo ""
    log_info "Enjoy your new setup!"
    echo ""
}

# =============================================================================
# Show banner
# =============================================================================
show_banner() {
    echo ""
    echo -e "${CYAN}"
    cat <<'EOF'
    ╔═══════════════════════════════════════════════════════════════╗
    ║                                                               ║
    ║   ▀█▀ █▀ █ █ ▄▄ █▀▄ █▀█ ▀█▀ █▀                                ║
    ║    █  ▄█ █▄█    █▄▀ █▄█  █  ▄█                                ║
    ║                                                               ║
    ║   https://github.com/mrtsubasa/tsu-dots                       ║
    ║   Installation Script                                         ║
    ║                                                               ║
    ╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# =============================================================================
# Main
# =============================================================================
main() {
    show_banner

    # Check the distribution (Arch family only, NixOS -> flake)
    detect_distro

    # FIRST: Category selection (before any installation)
    get_selection

    echo ""
    log_info "Selected categories: ${CATEGORIES[*]}"
    echo ""
    echo -ne "${YELLOW}Continue with the installation? [Y/n]: ${NC}"
    read -r confirm

    if [[ $confirm =~ ^[Nn]$ ]]; then
        log_info "Installation cancelled."
        exit 0
    fi

    # Run installation (checks and AUR helper here)
    full_install

    # Show summary
    show_summary

    # Prompt for reboot
    ask_reboot
}

# =============================================================================
# Command line arguments
# =============================================================================
normalize_category() {
    case "$1" in
    quickshell) echo "catalyst" ;; # old name
    *) echo "$1" ;;
    esac
}

dry_run() {
    detect_distro
    log_header "Dry run: nothing will be installed"
    [[ ${#CATEGORIES[@]} -eq 0 ]] && CATEGORIES=("${ALL_CATEGORIES[@]}")
    local category
    for category in "${CATEGORIES[@]}"; do
        echo -e "${CYAN}${category}${NC}"
        install_packages "$category"
    done
}

ACTION="main"
CATEGORIES=()
while [[ $# -gt 0 ]]; do
    case "$1" in
    --help | -h)
        echo "Usage: ./install.sh [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h           Show this help"
        echo "  --dry-run            Show what would be installed (repos vs AUR), install nothing"
        echo "  --check              Only check that Catalyst's dependencies are present"
        echo "  --stow-only          Only run stow (symlinks)"
        echo "  --setup-only         Only run the Hyprland local setup"
        echo "  --packages CAT[,CAT] Install only these categories"
        echo ""
        echo "Categories: ${ALL_CATEGORIES[*]}"
        echo "Supported: Arch and derivatives (CachyOS, EndeavourOS, Manjaro, Garuda, BlackArch...)."
        echo "NixOS: see nix/README.md"
        exit 0
        ;;
    --dry-run) DRY_RUN=1 ;;
    --check) ACTION="check" ;;
    --stow-only) ACTION="stow" ;;
    --setup-only) ACTION="setup" ;;
    --packages)
        ACTION="packages"
        if [[ -z "${2:-}" ]]; then
            log_error "Please specify a category!"
            exit 1
        fi
        IFS=',' read -ra _cats <<<"$2"
        for _c in "${_cats[@]}"; do
            _c="$(normalize_category "$_c")"
            if [[ " ${ALL_CATEGORIES[*]} " != *" $_c "* ]]; then
                log_error "Unknown category: $_c (available: ${ALL_CATEGORIES[*]})"
                exit 1
            fi
            CATEGORIES+=("$_c")
        done
        shift
        ;;
    *)
        log_error "Unknown option: $1 (see --help)"
        exit 1
        ;;
    esac
    shift
done

if [[ $DRY_RUN -eq 1 ]]; then
    dry_run
    exit 0
fi

case "$ACTION" in
check)
    verify_install
    ;;
stow)
    check_arch
    sudo pacman -S --needed --noconfirm stow
    source "$SETUP_DIR/stow.sh"
    run_stow_main
    ;;
setup)
    # no pacman involved: works on any distribution
    source "$SETUP_DIR/hyprland.sh"
    run_hyprland_main
    ;;
packages)
    check_arch
    check_internet
    check_aur_helper
    for category in "${CATEGORIES[@]}"; do
        log_header "Installing: ${category^^}"
        install_packages "$category"
    done
    if [[ ${#FAILED_PACKAGES[@]} -gt 0 ]]; then
        log_warn "Failed: ${FAILED_PACKAGES[*]}"
    fi
    ;;
*)
    main
    ;;
esac
