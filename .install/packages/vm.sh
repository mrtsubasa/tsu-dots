#!/bin/bash
# =============================================================================
# VM Packages - Virtual machines panel (libvirt / QEMU)
# =============================================================================
# Optional: needed by the VM panel (scripts/vmctl.py)
# =============================================================================

VM_PACKAGES=(
    "libvirt"
    "qemu-full"
    "virt-install"
    "virt-manager"
    "dnsmasq"   # NAT network for guests
    "edk2-ovmf" # UEFI firmware
    "swtpm"     # TPM (Windows 11 guests)
)

VM_AUR_PACKAGES=(
)

# Setup - enable libvirt and let the user manage VMs without root
setup_vm() {
    echo -e "\033[0;36m[>>]\033[0m Enabling libvirtd..."
    sudo systemctl enable --now libvirtd.service
    sudo usermod -aG libvirt "$USER"
    echo -e "\033[0;32m[INFO]\033[0m Added $USER to the libvirt group (log out and back in)."
}
