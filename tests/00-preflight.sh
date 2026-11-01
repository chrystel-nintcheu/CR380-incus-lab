#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 00 — Preflight Checks / Vérifications préalables
# =============================================================================
#
# FR: Vérifie que l'environnement est prêt avant de lancer les labs:
#     - Système d'exploitation Ubuntu 24.04+
#     - Accès sudo
#     - Connectivité Internet
#     - Espace disque suffisant (>10 Go)
#     - Architecture amd64
#     - Pas de verrou dpkg
#     - WSL 2, systemd actif, dépôt hors de /mnt/c, Docker absent, DNS
#
# EN: Verifies the environment is ready before running labs:
#     - Ubuntu 24.04+ operating system
#     - Sudo access
#     - Internet connectivity
#     - Sufficient disk space (>10 GB)
#     - amd64 architecture
#     - No dpkg lock
#     - WSL 2, systemd running, repository outside /mnt/c, no Docker, DNS
#
# GitBook: N/A (prerequisite check, not a lab exercise)
# Depends on: nothing
# =============================================================================

run_test() {
    section_header "00" "Preflight Checks / Vérifications préalables"

    learn_pause \
        "Avant de commencer les labs, nous vérifions que votre système est prêt.
Ces vérifications sont essentielles pour éviter des erreurs plus tard." \
        "Before starting the labs, we verify your system is ready.
These checks are essential to avoid errors later."

    # -------------------------------------------------------------------------
    # Check 1: Ubuntu version / Version Ubuntu
    # -------------------------------------------------------------------------
    # STUDENT NOTE: lsb_release retourne les informations de la distribution Linux
    # lsb_release returns Linux distribution information
    local os_version
    os_version=$(lsb_release -rs 2>/dev/null || echo "0")
    local os_major
    os_major=$(echo "${os_version}" | cut -d. -f1)

    if (( os_major >= 24 )); then
        pass "OS: Ubuntu ${os_version} (>= 24.04)"
    else
        fail "OS: Ubuntu ${os_version} (requires >= 24.04)" \
             ">= 24.04" \
             "${os_version}" \
             "Ce lab requiert Ubuntu 24.04 LTS ou plus récent. Installez la bonne version."
    fi

    # -------------------------------------------------------------------------
    # Check 2: Sudo access / Accès sudo
    # -------------------------------------------------------------------------
    # STUDENT NOTE: sudo -n teste l'accès sudo sans demander de mot de passe
    # sudo -n tests sudo access without prompting for password
    if sudo -n true 2>/dev/null; then
        pass "Sudo: access confirmed / accès confirmé"
    else
        fail "Sudo: cannot run sudo without password" \
             "passwordless sudo" \
             "sudo requires password or is not available" \
             "Exécutez: sudo visudo et ajoutez votre utilisateur. / Run: sudo visudo and add your user."
    fi

    # -------------------------------------------------------------------------
    # Check 3: Internet connectivity / Connectivité Internet
    # -------------------------------------------------------------------------
    # STUDENT NOTE: ping teste la connectivité réseau vers un serveur distant
    # ping tests network connectivity to a remote server
    if ping -c 1 -W 5 linuxcontainers.org &>/dev/null; then
        pass "Internet: linuxcontainers.org reachable / accessible"
    elif ping -c 1 -W 5 8.8.8.8 &>/dev/null; then
        pass "Internet: connectivity OK (DNS may have issues)"
    else
        fail "Internet: no connectivity detected" \
             "ping to linuxcontainers.org or 8.8.8.8" \
             "no response" \
             "Vérifiez votre connexion réseau. / Check your network connection."
    fi

    # -------------------------------------------------------------------------
    # Check 4: Disk space / Espace disque
    # -------------------------------------------------------------------------
    # STUDENT NOTE: df --output=avail affiche l'espace libre en kilo-octets
    # df --output=avail shows free space in kilobytes
    local avail_kb
    avail_kb=$(df --output=avail / | tail -1 | tr -d ' ')
    local avail_gb=$(( avail_kb / 1024 / 1024 ))

    if (( avail_gb >= 10 )); then
        pass "Disk: ${avail_gb} GB free (>= 10 GB required)"
    else
        fail "Disk: only ${avail_gb} GB free" \
             ">= 10 GB" \
             "${avail_gb} GB" \
             "Libérez de l'espace disque. Essayez: sudo apt clean && sudo apt autoremove"
    fi

    # -------------------------------------------------------------------------
    # Check 5: Architecture / Architecture
    # -------------------------------------------------------------------------
    # STUDENT NOTE: dpkg --print-architecture retourne l'architecture du système
    # dpkg --print-architecture returns the system architecture
    local arch
    arch=$(dpkg --print-architecture 2>/dev/null || echo "unknown")

    if [[ "${arch}" == "amd64" ]]; then
        pass "Architecture: ${arch}"
    else
        fail "Architecture: ${arch} (requires amd64)" \
             "amd64" \
             "${arch}" \
             "Les images du lab sont pour amd64. Votre système doit être x86_64."
    fi

    # -------------------------------------------------------------------------
    # Check 6: No dpkg lock / Pas de verrou dpkg
    # -------------------------------------------------------------------------
    # STUDENT NOTE: fuser vérifie si un fichier est utilisé par un processus
    # fuser checks if a file is being used by a process
    if ! fuser /var/lib/dpkg/lock-frontend &>/dev/null 2>&1; then
        pass "DPKG: no lock held / pas de verrou"
    else
        fail "DPKG: lock is held by another process" \
             "no lock on /var/lib/dpkg/lock-frontend" \
             "lock is active" \
             "Un autre processus utilise apt/dpkg. Attendez ou: sudo kill \$(sudo fuser /var/lib/dpkg/lock-frontend 2>/dev/null)"
    fi

    # -------------------------------------------------------------------------
    # Check 7: Required tools / Outils requis
    # -------------------------------------------------------------------------
    local tools_ok=true
    for tool in git curl wget; do
        if command -v "${tool}" &>/dev/null; then
            pass "Tool: ${tool} found / trouvé"
        else
            fail "Tool: ${tool} not found" \
                 "${tool} installed" \
                 "not found" \
                 "Installez avec: sudo apt install -y ${tool}"
            tools_ok=false
        fi
    done

    # -------------------------------------------------------------------------
    # Check 8: WSL 2 / Sous-système Windows pour Linux 2 (classe A)
    # -------------------------------------------------------------------------
    # STUDENT NOTE: Incus a besoin d'un vrai noyau Linux (cgroups, veth, nftables).
    # Seul WSL 2 en fournit un; WSL 1 n'en a pas. / Incus needs a real Linux kernel.
    local kernel_version
    kernel_version=$(cat /proc/version 2>/dev/null || echo "")

    if [[ "${kernel_version}" == *WSL2* ]]; then
        pass "WSL: version 2 (kernel $(uname -r))"
    elif [[ "${kernel_version,,}" == *microsoft* ]]; then
        fail "WSL: WSL 1 détecté (WSL 2 requis)" \
             "WSL 2" \
             "WSL 1" \
             "Dans PowerShell: wsl --set-version <distribution> 2  (vérifiez avec: wsl -l -v)"
    else
        fail "WSL: environnement non WSL détecté" \
             "WSL 2 (Windows 10/11)" \
             "$(uname -r)" \
             "Cette version du lab s'exécute dans une distribution Ubuntu 24.04 sous WSL 2."
    fi

    # -------------------------------------------------------------------------
    # Check 9: systemd actif / systemd running
    # -------------------------------------------------------------------------
    # STUDENT NOTE: Incus est un service systemd. Sous WSL, systemd est activé
    # par [boot] systemd=true dans /etc/wsl.conf. / Incus runs as a systemd service.
    local systemd_state
    systemd_state=$(systemctl is-system-running 2>/dev/null || true)

    if [[ "${systemd_state}" == "running" ]]; then
        pass "systemd: actif (running)"
    elif [[ "${systemd_state}" == "degraded" ]]; then
        pass "systemd: actif (degraded) — unités en échec: $(systemctl --failed --no-legend 2>/dev/null | awk '{print $2}' | paste -sd, -)"
    else
        fail "systemd: non actif (état: ${systemd_state:-inconnu})" \
             "running" \
             "${systemd_state:-inconnu}" \
             "Ajoutez [boot] systemd=true dans /etc/wsl.conf, puis dans PowerShell: wsl --shutdown, et relancez Ubuntu."
    fi

    # -------------------------------------------------------------------------
    # Check 10: Dépôt dans le système de fichiers Linux / Repository on Linux fs
    # -------------------------------------------------------------------------
    # STUDENT NOTE: Sous /mnt/c, les permissions et la vitesse d'accès diffèrent.
    # Under /mnt/c, permissions and I/O speed differ from native Linux.
    if [[ "${PROJECT_ROOT}" == /mnt/* ]]; then
        fail "Dépôt: ${PROJECT_ROOT} est sur le disque Windows" \
             "dépôt sous ~ (système de fichiers Linux)" \
             "${PROJECT_ROOT}" \
             "Clonez le dépôt dans votre dossier personnel: cd ~ && git clone <url>"
    else
        pass "Dépôt: ${PROJECT_ROOT} dans le système de fichiers Linux"
    fi

    # -------------------------------------------------------------------------
    # Check 11: Docker absent / No conflicting Docker
    # -------------------------------------------------------------------------
    # STUDENT NOTE: Docker modifie les règles du pare-feu et peut couper l'accès
    # réseau des conteneurs Incus. / Docker can break Incus container networking.
    if command -v docker &>/dev/null || systemctl is-active --quiet docker 2>/dev/null; then
        log "WARN: Docker détecté, conflit réseau possible avec Incus"
        echo -e "  ${YELLOW}⚠${NC} Docker détecté: peut priver les conteneurs Incus d'Internet (DNS, NAT)."
        echo -e "    ${YELLOW}💡 HINT: Désactivez Docker dans cette distribution pour les labs: sudo systemctl disable --now docker${NC}"
    else
        pass "Docker: absent (pas de conflit réseau)"
    fi

    # -------------------------------------------------------------------------
    # Check 12: Résolution DNS / DNS resolution
    # -------------------------------------------------------------------------
    # STUDENT NOTE: Les images sont téléchargées depuis images.linuxcontainers.org.
    # Images are downloaded from images.linuxcontainers.org.
    if getent hosts images.linuxcontainers.org &>/dev/null; then
        pass "DNS: images.linuxcontainers.org résolu"
    else
        fail "DNS: images.linuxcontainers.org non résolu" \
             "résolution DNS fonctionnelle" \
             "aucune réponse" \
             "Vérifiez /etc/resolv.conf et la connexion Windows; essayez: wsl --shutdown puis relancez Ubuntu."
    fi

    section_summary
}
