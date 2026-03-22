#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 03 — Après installation / Post-Installation
# =============================================================================
#
# FR: Configuration post-installation: ajout de l'utilisateur au groupe
#     incus-admin. Discussion sur les implications de sécurité.
#
# EN: Post-installation setup: adding the user to the incus-admin group.
#     Discussion about security implications.
#
# GitBook: ${GITBOOK_BASE_URL}/incus-lab/installation/apres-installation
# Depends on: 02-install
# =============================================================================

run_test() {
    section_header "03" "Après installation / Post-Installation" \
        "${GITBOOK_BASE_URL}/incus-lab/installation/apres-installation"

    check_dependency "02" || { section_summary; return 0; }

    learn_pause \
        "Après l'installation, il faut configurer les permissions utilisateur.
Le groupe 'incus-admin' donne un accès complet au démon Incus.

⚠️  SÉCURITÉ: N'ajoutez que des utilisateurs de confiance à ce groupe.
L'accès local via le socket Unix donne un contrôle total sur Incus." \
        "After installation, we need to configure user permissions.
The 'incus-admin' group gives full access to the Incus daemon.

⚠️  SECURITY: Only add trusted users to this group.
Local access via the Unix socket gives full control over Incus."

    # -------------------------------------------------------------------------
    # Step 1: Add current user to incus-admin group
    # FR: Ajouter l'utilisateur courant au groupe incus-admin
    # -------------------------------------------------------------------------
    # STUDENT NOTE: adduser ajoute un utilisateur à un groupe
    # adduser adds a user to a group
    local current_user="${SUDO_USER:-${USER}}"

    learn_pause \
        "Commande: sudo adduser ${current_user} incus-admin
Ceci permet à votre utilisateur de contrôler incus sans sudo." \
        "Command: sudo adduser ${current_user} incus-admin
This allows your user to control incus without sudo."

    run_cmd "Add user to incus-admin" "${TIMEOUT_DEFAULT}" \
        sudo adduser "${current_user}" incus-admin 2>/dev/null || true
    # adduser may return non-zero if user is already in group — that's OK
    pass "adduser ${current_user} incus-admin executed"

    # -------------------------------------------------------------------------
    # Step 2: Verify group membership
    # FR: Vérifier l'appartenance au groupe
    # -------------------------------------------------------------------------
    # STUDENT NOTE: getent group affiche les membres d'un groupe
    # getent group shows the members of a group
    assert_output_contains \
        "User '${current_user}' is in incus-admin group" \
        "${current_user}" \
        "L'utilisateur n'est pas dans le groupe. Essayez: sudo adduser ${current_user} incus-admin" \
        getent group incus-admin

    # -------------------------------------------------------------------------
    # Step 3: Verify incus access via group
    # FR: Vérifier l'accès à incus via le groupe
    # -------------------------------------------------------------------------
    # STUDENT NOTE: sg exécute une commande avec les permissions d'un groupe
    # sg runs a command with a group's permissions
    # NOTE: We use 'sg' instead of 'newgrp' because newgrp spawns a new shell
    # and breaks script execution.
    learn_pause \
        "Nous utilisons 'sg incus-admin -c \"commande\"' au lieu de 'newgrp'
car newgrp ouvre un nouveau shell et ne fonctionne pas dans un script." \
        "We use 'sg incus-admin -c \"command\"' instead of 'newgrp'
because newgrp opens a new shell and doesn't work in scripts."

    run_cmd "Test incus access via group" "${TIMEOUT_DEFAULT}" \
        incus_run incus info 2>/dev/null || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "incus accessible via incus-admin group / accessible via le groupe"
    else
        # Fallback: test with sudo
        run_cmd "Test incus access via sudo" "${TIMEOUT_DEFAULT}" \
            sudo incus info 2>/dev/null || true
        if (( CMD_EXIT_CODE == 0 )); then
            pass "incus accessible via sudo (group may require re-login)"
        else
            fail "Cannot access incus" \
                 "incus info should succeed" \
                 "exit code ${CMD_EXIT_CODE}" \
                 "Essayez de vous déconnecter/reconnecter (logout/login) pour rafraîchir les groupes."
        fi
    fi

    learn_pause \
        "Lisez la documentation officielle sur la sécurité Incus:
https://linuxcontainers.org/incus/docs/main/explanation/security/

Résumé: L'accès local au démon Incus via le socket Unix donne
toujours un accès complet, y compris la possibilité de monter
des systèmes de fichiers et des périphériques de l'hôte." \
        "Read the official Incus security documentation:
https://linuxcontainers.org/incus/docs/main/explanation/security/

Summary: Local access to the Incus daemon via the Unix socket
always grants full access, including the ability to attach
host file systems and devices."

    section_summary
}
