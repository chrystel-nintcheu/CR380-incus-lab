#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 07 — Conteneurs / Containers
# =============================================================================
#
# FR: Lancer, gérer, cloner et supprimer des conteneurs. Comprendre le
#     cycle de vie: image → conteneur → clone → publication → suppression.
#
# EN: Launch, manage, clone and delete containers. Understand the
#     lifecycle: image → container → clone → publish → delete.
#
# GitBook: ${GITBOOK_BASE_URL}/incus-lab/les-flux-incus/conteneur
# Depends on: 06-images
# =============================================================================

run_test() {
    section_header "07" "Conteneurs / Containers" \
        "${GITBOOK_BASE_URL}/incus-lab/les-flux-incus/conteneur"

    check_dependency "06" || { section_summary; return 0; }

    learn_pause \
        "Le cycle de vie d'un conteneur Incus:
1. Lancer (launch) depuis une image → conteneur RUNNING
2. Arrêter (stop) → STOPPED
3. Cloner ou publier (publish) → nouvelle image
4. Supprimer (delete) → libérer les ressources

Nous allons pratiquer chaque opération." \
        "The Incus container lifecycle:
1. Launch from an image → RUNNING container
2. Stop → STOPPED
3. Clone or publish → new image
4. Delete → free resources

We will practice each operation."

    # -------------------------------------------------------------------------
    # Step 1: Launch container u1 from Ubuntu image
    # FR: Lancer le conteneur u1 depuis l'image Ubuntu
    # -------------------------------------------------------------------------
    # STUDENT NOTE: 'incus launch alias nom' crée et démarre un conteneur
    # 'incus launch alias name' creates and starts a container
    learn_pause \
        "Commande: incus launch ${ALIAS_UBUNTU} ${CT_U1}
Ceci crée un conteneur nommé '${CT_U1}' à partir de l'image '${ALIAS_UBUNTU}'
et le démarre automatiquement." \
        "Command: incus launch ${ALIAS_UBUNTU} ${CT_U1}
This creates a container named '${CT_U1}' from the '${ALIAS_UBUNTU}' image
and starts it automatically."

    # Cleanup if remnant exists
    cleanup_container "${CT_U1}"

    run_cmd "Launch container '${CT_U1}' from '${ALIAS_UBUNTU}'" "${TIMEOUT_CONTAINER_READY}" \
        incus_run incus launch ${ALIAS_UBUNTU} ${CT_U1} || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Container '${CT_U1}' launched"
    elif [[ "${CMD_OUTPUT}" == *"already"* ]]; then
        pass "Container '${CT_U1}' already exists (from previous run)"
    else
        fail "Failed to launch '${CT_U1}'" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}: ${CMD_OUTPUT:0:200}" \
             "Vérifiez que l'image '${ALIAS_UBUNTU}' existe: incus image ls"
    fi

    # Wait for container to be running
    wait_for_ready "${CT_U1}"

    # -------------------------------------------------------------------------
    # Step 2: List containers
    # FR: Lister les conteneurs
    # -------------------------------------------------------------------------
    assert_resource_exists "container" "${CT_U1}" \
        "Conteneur '${CT_U1}' devrait exister. Revérifiez le lancement."

    # Check YAML output
    learn_pause \
        "On peut lister les conteneurs en YAML pour voir tous les détails:
Commande: incus ls --format yaml" \
        "You can list containers in YAML to see all details:
Command: incus ls --format yaml"

    assert_output_not_empty \
        "Container list YAML output" \
        "La liste des conteneurs ne devrait pas être vide." \
        incus_run incus ls --format yaml

    # -------------------------------------------------------------------------
    # Step 3: Publish u1 as custom image
    # FR: Publier u1 comme image personnalisée
    # -------------------------------------------------------------------------
    learn_pause \
        "Commande: incus publish ${CT_U1} --alias ${IMG_CUSTOM_U1} --force
Ceci crée une image à partir du conteneur en cours d'exécution.
--force permet la publication même si le conteneur est en cours d'exécution." \
        "Command: incus publish ${CT_U1} --alias ${IMG_CUSTOM_U1} --force
This creates an image from the running container.
--force allows publishing even while the container is running."

    # Cleanup image if remnant exists
    cleanup_image "${IMG_CUSTOM_U1}"

    # Stop the container first for a clean publish
    run_cmd "Stop '${CT_U1}' before publish" "${TIMEOUT_DEFAULT}" \
        incus_run incus stop ${CT_U1} --force || true

    run_cmd "Publish '${CT_U1}' as '${IMG_CUSTOM_U1}'" "${TIMEOUT_EXEC}" \
        incus_run incus publish ${CT_U1} --alias ${IMG_CUSTOM_U1} || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Published '${CT_U1}' as image '${IMG_CUSTOM_U1}'"
    else
        fail "Failed to publish '${CT_U1}'" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}: ${CMD_OUTPUT:0:200}" \
             "Le conteneur doit exister. Vérifiez: incus ls"
    fi

    # -------------------------------------------------------------------------
    # Step 4: Launch clone from custom image
    # FR: Lancer un clone depuis l'image personnalisée
    # -------------------------------------------------------------------------
    learn_pause \
        "Commande: incus launch ${IMG_CUSTOM_U1} ${CT_CLONE}
Ceci lance un nouveau conteneur à partir de l'image que nous venons de publier." \
        "Command: incus launch ${IMG_CUSTOM_U1} ${CT_CLONE}
This launches a new container from the image we just published."

    cleanup_container "${CT_CLONE}"

    run_cmd "Launch clone '${CT_CLONE}' from '${IMG_CUSTOM_U1}'" "${TIMEOUT_CONTAINER_READY}" \
        incus_run incus launch ${IMG_CUSTOM_U1} ${CT_CLONE} || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Clone '${CT_CLONE}' launched from '${IMG_CUSTOM_U1}'"
    else
        fail "Failed to launch clone '${CT_CLONE}'" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}: ${CMD_OUTPUT:0:200}" \
             "Vérifiez que l'image '${IMG_CUSTOM_U1}' existe: incus image ls"
    fi

    wait_for_ready "${CT_CLONE}"

    # -------------------------------------------------------------------------
    # Step 5: Stop and delete clone
    # FR: Arrêter et supprimer le clone
    # -------------------------------------------------------------------------
    learn_pause \
        "Commande: incus stop ${CT_CLONE} && incus delete ${CT_CLONE}
On arrête d'abord, puis on supprime. On pourrait aussi faire:
incus delete --force ${CT_CLONE} (arrête et supprime en une seule commande)." \
        "Command: incus stop ${CT_CLONE} && incus delete ${CT_CLONE}
We stop first, then delete. You could also do:
incus delete --force ${CT_CLONE} (stops and deletes in one command)."

    run_cmd "Stop clone '${CT_CLONE}'" "${TIMEOUT_DEFAULT}" \
        incus_run incus stop ${CT_CLONE} || true

    run_cmd "Delete clone '${CT_CLONE}'" "${TIMEOUT_DEFAULT}" \
        incus_run incus delete ${CT_CLONE} || true

    # Verify deletion
    assert_resource_not_exists "container" "${CT_CLONE}" \
        "Le conteneur '${CT_CLONE}' devrait être supprimé."

    section_summary
}
