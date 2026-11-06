#!/bin/bash
# =============================================================================
# Camera Packages - Virtual camera, filters and scene compositor
# =============================================================================
# Optional: needed by the camera panel (scripts/cam-filter.sh, cam_*.py)
# =============================================================================

CAM_PACKAGES=(
    "v4l2loopback-dkms"   # virtual camera device
    "v4l2loopback-utils"
    "v4l-utils"
    "python-numpy"
    "python-opencv"
    "python-onnxruntime-cpu" # background removal / anime filter models
)

CAM_AUR_PACKAGES=(
)

# Setup - kernel headers for the v4l2loopback DKMS module
setup_cam() {
    local kpkg
    kpkg="$(pacman -Qoq "/usr/lib/modules/$(uname -r)/vmlinuz" 2>/dev/null || true)"
    if [[ -n "$kpkg" ]]; then
        echo -e "\033[0;36m[>>]\033[0m Installing ${kpkg}-headers for v4l2loopback..."
        sudo pacman -S --needed --noconfirm "${kpkg}-headers" ||
            echo -e "\033[1;33m[WARN]\033[0m Install the headers of your kernel manually."
    else
        echo -e "\033[1;33m[WARN]\033[0m Running kernel not found: install its -headers package for v4l2loopback."
    fi
}
