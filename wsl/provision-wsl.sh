#!/usr/bin/env bash
# =============================================================================
# CR380 - Provisionnement de la distribution WSL de référence
# Remplace le provisionnement Multipass/cloud-init retiré (classe A).
#
# S'exécute en root, DANS la distribution jetable cr380-*, appelé par
# wsl/run-wsl-tests.ps1 -Prepare. Ne s'exécute jamais ailleurs.
# =============================================================================
set -euo pipefail

LAB_USER="${1:-student}"

if [[ "${WSL_DISTRO_NAME:-}" != cr380-* ]]; then
    echo "ERREUR: distribution '${WSL_DISTRO_NAME:-inconnue}' n'est pas cr380-* : arrêt." >&2
    exit 1
fi
if (( EUID != 0 )); then
    echo "ERREUR: ce script doit s'exécuter en root." >&2
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# Paquets de base du lab
apt-get update -y
apt-get install -y git curl wget tree vim jq members ca-certificates gnupg \
    software-properties-common apt-transport-https bash-completion

# Utilisateur du lab, sudo sans mot de passe (exigé par tests/00-preflight.sh)
if ! id "${LAB_USER}" &>/dev/null; then
    useradd --create-home --shell /bin/bash --groups sudo "${LAB_USER}"
fi
echo "${LAB_USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/90-${LAB_USER}"
chmod 0440 "/etc/sudoers.d/90-${LAB_USER}"

# systemd obligatoire pour Incus; utilisateur par défaut
cat > /etc/wsl.conf <<EOF
[boot]
systemd=true

[user]
default=${LAB_USER}
EOF

echo "Provisionnement terminé: utilisateur=${LAB_USER}, systemd=true"
