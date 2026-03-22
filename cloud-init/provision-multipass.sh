#!/usr/bin/env bash
# =============================================================================
# CR380 - Multipass VM Provisioning Script
# =============================================================================
#
# FR: Script wrapper pour lancer une VM multipass avec la bonne config cloud-init.
# EN: Wrapper script to launch a multipass VM with the right cloud-init config.
#
# Usage:
#   ./provision-multipass.sh --fresh      # Clean VM, no Incus
#   ./provision-multipass.sh --ready      # Pre-configured with Incus
#   ./provision-multipass.sh --delete     # Delete the VM
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VM_NAME="cr380-lab"
CPUS=2
MEMORY="4G"
DISK="20G"
UBUNTU_VERSION="24.04"

usage() {
    echo "Usage: $0 [--fresh|--ready|--delete]"
    echo ""
    echo "  --fresh   Launch a clean VM (no Incus installed)"
    echo "  --ready   Launch a pre-configured VM (Incus installed + initialized)"
    echo "  --delete  Delete the VM"
    echo ""
    echo "  FR: --fresh = VM propre, --ready = VM pré-configurée"
    exit 1
}

check_multipass() {
    if ! command -v multipass &>/dev/null; then
        echo "ERROR: multipass is not installed."
        echo "Install it: sudo snap install multipass"
        echo ""
        echo "FR: multipass n'est pas installé. Installez-le: sudo snap install multipass"
        exit 1
    fi
}

delete_vm() {
    echo "Deleting VM '${VM_NAME}'..."
    multipass delete "${VM_NAME}" 2>/dev/null || true
    multipass purge 2>/dev/null || true
    echo "VM '${VM_NAME}' deleted."
}

launch_vm() {
    local cloud_init_file="$1"
    local label="$2"

    if ! [[ -f "${cloud_init_file}" ]]; then
        echo "ERROR: Cloud-init file not found: ${cloud_init_file}"
        exit 1
    fi

    # Delete existing VM if present
    if multipass list 2>/dev/null | grep -q "${VM_NAME}"; then
        echo "VM '${VM_NAME}' already exists. Deleting first..."
        delete_vm
    fi

    echo "Launching ${label} VM '${VM_NAME}'..."
    echo "  OS: Ubuntu ${UBUNTU_VERSION}"
    echo "  CPUs: ${CPUS}, Memory: ${MEMORY}, Disk: ${DISK}"
    echo "  Cloud-init: ${cloud_init_file}"
    echo ""

    multipass launch "${UBUNTU_VERSION}" \
        --name "${VM_NAME}" \
        --cpus "${CPUS}" \
        --memory "${MEMORY}" \
        --disk "${DISK}" \
        --cloud-init "${cloud_init_file}"

    echo ""
    echo "VM '${VM_NAME}' launched successfully!"
    echo "Connect with: multipass shell ${VM_NAME}"
    echo ""
    echo "FR: VM '${VM_NAME}' lancée. Connectez-vous: multipass shell ${VM_NAME}"
}

# Main
[[ $# -lt 1 ]] && usage

check_multipass

case "${1}" in
    --fresh)
        launch_vm "${SCRIPT_DIR}/user-data-fresh.yaml" "FRESH (no Incus)"
        ;;
    --ready)
        launch_vm "${SCRIPT_DIR}/user-data-ready.yaml" "READY (Incus pre-installed)"
        ;;
    --delete)
        delete_vm
        ;;
    *)
        usage
        ;;
esac
