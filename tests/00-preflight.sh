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
#
# EN: Verifies the environment is ready before running labs:
#     - Ubuntu 24.04+ operating system
#     - Sudo access
#     - Internet connectivity
#     - Sufficient disk space (>10 GB)
#     - amd64 architecture
#     - No dpkg lock
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

    section_summary
}
