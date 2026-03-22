#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 02 — Installation
# =============================================================================
#
# FR: Installation d'Incus via le gestionnaire de paquets apt.
#     Option 1 du lab (le dépôt Ubuntu officiel).
#     Vérifie que le paquet est installé, que le service est actif.
#
# EN: Installation of Incus via the apt package manager.
#     Option 1 of the lab (the official Ubuntu repository).
#     Verifies the package is installed and the service is active.
#
# GitBook: ${GITBOOK_BASE_URL}/incus-lab/installation
# Depends on: 01-uninstall
# =============================================================================

run_test() {
    section_header "02" "Installation" \
        "${GITBOOK_BASE_URL}/incus-lab/installation"

    check_dependency "01" || { section_summary; return 0; }

    learn_pause \
        "Nous allons installer Incus depuis le dépôt officiel Ubuntu avec apt.
C'est l'option 1 du lab (la plus simple et recommandée)." \
        "We will install Incus from the official Ubuntu repository with apt.
This is Option 1 of the lab (simplest and recommended)."

    # -------------------------------------------------------------------------
    # Step 1: Update package list
    # FR: Mettre à jour la liste des paquets
    # -------------------------------------------------------------------------
    # STUDENT NOTE: Toujours faire 'apt update' avant 'apt install'
    # Always run 'apt update' before 'apt install'
    run_cmd "Update apt package list" "${TIMEOUT_APT}" \
        sudo apt-get update -y || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "apt update succeeded / apt update réussi"
    else
        fail "apt update failed" "exit code 0" "exit code ${CMD_EXIT_CODE}" \
             "Vérifiez votre connexion Internet / Check your Internet connection"
    fi

    # -------------------------------------------------------------------------
    # Step 2: Install incus
    # FR: Installer incus
    # -------------------------------------------------------------------------
    # STUDENT NOTE: Le flag -y évite les confirmations interactives
    # The -y flag avoids interactive confirmations
    learn_pause \
        "Commande: sudo apt install -y incus
Le flag -y répond automatiquement 'oui' aux confirmations." \
        "Command: sudo apt install -y incus
The -y flag automatically answers 'yes' to confirmations."

    run_cmd "Install incus package" "0" \
        sudo apt-get install -y incus
    if (( CMD_EXIT_CODE == 0 )); then
        pass "incus package installed / paquet incus installé"
    else
        # Check if incus is actually installed via dpkg despite non-zero exit.
        if dpkg -l incus 2>/dev/null | grep -q '^ii'; then
            log "apt exited non-zero but incus package IS installed (dpkg shows ii)"
            pass "incus package installed (slow but succeeded) / paquet incus installé"
            sudo systemctl start incus 2>/dev/null || true
            sleep 2
        else
            fail "incus package installation failed" \
                 "exit code 0" \
                 "exit code ${CMD_EXIT_CODE}" \
                 "Essayez: sudo apt update --fix-missing && sudo apt install -y incus"
            section_summary
            return 0
        fi
    fi

    # -------------------------------------------------------------------------
    # Step 3: Verify installation — version check
    # FR: Vérification — contrôle de version
    # -------------------------------------------------------------------------
    # STUDENT NOTE: incus --version retourne la version installée
    # incus --version returns the installed version
    assert_success \
        "incus --version returns OK" \
        "Si ceci échoue, le paquet n'a pas été installé correctement. Réinstallez." \
        incus --version

    if [[ -n "${CMD_OUTPUT}" ]]; then
        log "Incus version: ${CMD_OUTPUT}"
        if [[ "${MODE}" == "learn" ]] || (( VERBOSE >= 2 )); then
            echo -e "    ${DIM}Version: ${CMD_OUTPUT}${NC}"
        fi
    fi

    # -------------------------------------------------------------------------
    # Step 4: Verify systemd service is active
    # FR: Vérifier que le service systemd est actif
    # -------------------------------------------------------------------------
    # STUDENT NOTE: systemctl is-active vérifie si un service est en cours d'exécution
    # systemctl is-active checks if a service is running
    run_cmd "Check incus service status" "${TIMEOUT_DEFAULT}" \
        systemctl is-active incus || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "incus service is active / service incus actif"
    else
        # Service may be socket-activated; start it explicitly
        log "incus service is '${CMD_OUTPUT}' — starting it..."
        run_cmd "Start incus service" "${TIMEOUT_DEFAULT}" \
            sudo systemctl start incus || true
        sleep 2

        run_cmd "Re-check incus service" "${TIMEOUT_DEFAULT}" \
            systemctl is-active incus || true

        if (( CMD_EXIT_CODE == 0 )); then
            pass "incus service is active (after manual start)"
        else
            fail "incus service is not active" \
                 "active" \
                 "${CMD_OUTPUT}" \
                 "Le service incus n'est pas actif. Essayez: sudo systemctl start incus"
        fi
    fi

    learn_pause \
        "Incus est maintenant installé et le service est actif!
Vous pouvez vérifier manuellement avec: incus --version && systemctl is-active incus" \
        "Incus is now installed and the service is active!
You can verify manually with: incus --version && systemctl is-active incus"

    section_summary
}
