#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 01 — Désinstallation / Uninstallation
# =============================================================================
#
# FR: Désinstallation complète d'Incus pour repartir sur une base propre.
#     Couvre: arrêt du service, purge des paquets, suppression des fichiers
#     résiduels, suppression du dépôt Zabbly (si présent), suppression des
#     groupes incus.
#
# EN: Complete uninstallation of Incus for a clean start.
#     Covers: stopping the service, purging packages, removing leftover files,
#     removing Zabbly repository (if present), removing incus groups.
#
# GitBook: ${GITBOOK_BASE_URL}/incus-lab/desinstallation
# Depends on: 00-preflight
# =============================================================================

run_test() {
    section_header "01" "Désinstallation / Uninstallation" \
        "${GITBOOK_BASE_URL}/incus-lab/desinstallation"

    # Check dependency / Vérifier la dépendance
    check_dependency "00" || { section_summary; return 0; }

    learn_pause \
        "Nous allons d'abord désinstaller Incus complètement pour repartir
sur une base propre. C'est une bonne pratique avant toute installation." \
        "We will first completely uninstall Incus to start from a clean slate.
This is good practice before any installation."

    # -------------------------------------------------------------------------
    # Step 1: Stop incus service if running
    # FR: Arrêter le service incus s'il est en cours d'exécution
    # -------------------------------------------------------------------------
    # STUDENT NOTE: systemctl stop arrête un service système
    # systemctl stop stops a system service
    if command -v incus &>/dev/null; then
        learn_pause \
            "Incus est installé. Nous devons d'abord arrêter le service." \
            "Incus is installed. We must first stop the service."

        # Stop all incus-related services
        for svc in incus incus.socket incus-user incus-user.socket incus-lxcfs incus-startup; do
            sudo systemctl stop "${svc}" 2>/dev/null || true
        done
        pass "Service incus stopped (or was not running)"

        # Delete all containers and images first to avoid purge issues
        incus stop --all --force 2>/dev/null || true
        for ct in $(incus list --format csv -c n 2>/dev/null); do
            incus delete --force "${ct}" 2>/dev/null || true
        done
        for img in $(incus image list --format csv -c l 2>/dev/null | tr -d ' '); do
            [[ -n "${img}" ]] && incus image delete "${img}" 2>/dev/null || true
        done

        # -------------------------------------------------------------------------
        # Step 2: Purge incus packages
        # FR: Purger les paquets incus
        # -------------------------------------------------------------------------
        # STUDENT NOTE: apt remove --purge supprime le paquet ET ses fichiers de config
        # apt remove --purge removes the package AND its config files
        learn_pause \
            "Maintenant nous purgeons les paquets incus avec apt." \
            "Now we purge incus packages with apt."

        run_cmd "Purge incus packages" "0" \
            sudo DEBIAN_FRONTEND=noninteractive apt-get remove --purge -y incus 2>/dev/null || true

        # If apt failed, try dpkg --purge as a fallback.
        if dpkg -l incus 2>/dev/null | grep -q '^ii'; then
            log "apt did not fully remove incus, trying dpkg --purge as fallback"
            sudo dpkg --purge --force-remove-reinstreq incus 2>/dev/null || true
        fi

        run_cmd "Clean apt cache" "${TIMEOUT_DEFAULT}" \
            sudo apt-get clean || true
        run_cmd "Autoremove unused packages" "0" \
            sudo DEBIAN_FRONTEND=noninteractive apt-get autoremove -y || true

        pass "Packages purged / Paquets purgés"

        # -------------------------------------------------------------------------
        # Step 3: Remove leftover files
        # FR: Supprimer les fichiers résiduels
        # -------------------------------------------------------------------------
        # STUDENT NOTE: /var/lib/incus contient toutes les données d'Incus
        # /var/lib/incus contains all Incus data
        learn_pause \
            "Suppression des fichiers résiduels dans /var/lib/incus." \
            "Removing leftover files in /var/lib/incus."

        # Unmount any incus tmpfs mounts first (shmounts, guestapi)
        grep -o '/var/lib/incus[^ ]*' /proc/mounts 2>/dev/null | sort -r | while read -r mp; do
            sudo umount -l "${mp}" 2>/dev/null || true
        done

        if [[ -d /var/lib/incus ]] || ls /var/lib/incus* &>/dev/null 2>&1; then
            sudo rm -rf /var/lib/incus*
            pass "Leftover files removed / Fichiers résiduels supprimés"
        else
            pass "No leftover files found / Aucun fichier résiduel"
        fi

        # -------------------------------------------------------------------------
        # Step 3b: Remove leftover network bridge
        # FR: Supprimer le pont réseau résiduel
        # -------------------------------------------------------------------------
        if ip link show "${BRIDGE_NAME}" &>/dev/null; then
            sudo ip link set "${BRIDGE_NAME}" down 2>/dev/null || true
            sudo ip link delete "${BRIDGE_NAME}" 2>/dev/null || true
            log "Removed leftover bridge interface '${BRIDGE_NAME}'"
        fi

        # -------------------------------------------------------------------------
        # Step 4: Remove Zabbly repository (if present)
        # FR: Supprimer le dépôt Zabbly (si présent)
        # -------------------------------------------------------------------------
        # STUDENT NOTE: Zabbly est un mainteneur tiers qui publie des paquets incus
        # Zabbly is a third-party maintainer that publishes incus packages
        if [[ -f /etc/apt/sources.list.d/zabbly-incus-stable.sources ]]; then
            sudo rm -f /etc/apt/sources.list.d/zabbly-incus-stable.sources
            pass "Zabbly source removed / Source Zabbly supprimée"
        else
            pass "No Zabbly source found / Aucune source Zabbly"
        fi
        if [[ -f /etc/apt/keyrings/zabbly.asc ]]; then
            sudo rm -f /etc/apt/keyrings/zabbly.asc
            pass "Zabbly key removed / Clé Zabbly supprimée"
        else
            pass "No Zabbly key found / Aucune clé Zabbly"
        fi

        # -------------------------------------------------------------------------
        # Step 5: Remove incus groups
        # FR: Supprimer les groupes incus
        # -------------------------------------------------------------------------
        # STUDENT NOTE: Les groupes sont définis dans /etc/group
        # Groups are defined in /etc/group
        learn_pause \
            "Suppression des groupes système créés par Incus." \
            "Removing system groups created by Incus."

        local groups
        groups=$(cut -d: -f1 /etc/group | grep incus || true)
        if [[ -n "${groups}" ]]; then
            while IFS= read -r grp; do
                sudo groupdel "${grp}" 2>/dev/null || true
                log "Deleted group: ${grp}"
            done <<< "${groups}"
            pass "Incus groups removed / Groupes incus supprimés"
            learn_pause \
                "⚠️  Note: Le paquet Ubuntu ne recrée PAS ces groupes lors d'une\nréinstallation. Le Lab 02 s'en chargera automatiquement." \
                "⚠️  Note: The Ubuntu package does NOT recreate these groups on\nreinstall. Lab 02 will handle this automatically."
        else
            pass "No incus groups found / Aucun groupe incus"
        fi

        # Update package list
        run_cmd "Update package list" "${TIMEOUT_APT}" \
            sudo apt-get update --fix-missing || true

    else
        pass "Incus was not installed — nothing to uninstall / Incus n'était pas installé"
    fi

    # -------------------------------------------------------------------------
    # Verification: Assert clean state
    # FR: Vérification : S'assurer que le système est propre
    # -------------------------------------------------------------------------
    learn_pause \
        "Vérifions que tout a bien été supprimé." \
        "Let's verify everything has been removed."

    # Assert incus binary is gone
    hash -r  # Clear shell's command hash table after package removal
    if ! command -v incus &>/dev/null; then
        pass "incus binary not found (clean) / binaire incus absent (propre)"
    else
        fail "incus binary still present" \
             "incus not found" \
             "$(which incus)" \
             "Essayez: sudo apt remove --purge incus && hash -r"
    fi

    # Assert no incus groups remain
    local remaining_groups
    remaining_groups=$(cut -d: -f1 /etc/group | grep incus || true)
    if [[ -z "${remaining_groups}" ]]; then
        pass "No incus groups remain / Aucun groupe incus restant"
    else
        fail "Incus groups still exist" \
             "no incus groups" \
             "${remaining_groups}" \
             "Supprimez manuellement: sudo groupdel <nom_du_groupe>"
    fi

    # Assert /var/lib/incus is gone
    if [[ ! -d /var/lib/incus ]]; then
        pass "/var/lib/incus removed / supprimé"
    else
        fail "/var/lib/incus still exists" \
             "directory removed" \
             "directory present" \
             "sudo rm -rf /var/lib/incus"
    fi

    section_summary
}
