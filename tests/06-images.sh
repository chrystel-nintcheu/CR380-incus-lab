#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 06 — Images
# =============================================================================
#
# FR: Chercher, filtrer, télécharger et gérer des images de conteneurs.
#     Comprendre le flux: recherche → filtre → téléchargement → alias.
#
# EN: Search, filter, download and manage container images.
#     Understand the workflow: search → filter → download → alias.
#
# GitBook: ${GITBOOK_BASE_URL}/incus-lab/les-flux-incus/image
# Depends on: 05-registries
# =============================================================================

run_test() {
    section_header "06" "Images" \
        "${GITBOOK_BASE_URL}/incus-lab/les-flux-incus/image"

    check_dependency "05" || { section_summary; return 0; }

    learn_pause \
        "Le cycle de vie d'une image:
1. Rechercher dans le registre (incus image list images:...)
2. Filtrer par distribution et architecture
3. Télécharger avec un alias local
4. Utiliser l'alias pour lancer des conteneurs

Nous allons pratiquer chaque étape." \
        "The image lifecycle:
1. Search in the registry (incus image list images:...)
2. Filter by distribution and architecture
3. Download with a local alias
4. Use the alias to launch containers

We will practice each step."

    # -------------------------------------------------------------------------
    # Step 1: Search for images (e.g., kali)
    # FR: Rechercher des images (ex: kali)
    # -------------------------------------------------------------------------
    # STUDENT NOTE: La recherche distante peut prendre quelques secondes
    # Remote search may take a few seconds
    learn_pause \
        "Commande: incus image list images:kali
Ceci recherche toutes les images contenant 'kali' dans le registre distant." \
        "Command: incus image list images:kali
This searches for all images containing 'kali' in the remote registry."

    run_cmd "Search for kali images" "${TIMEOUT_DEFAULT}" \
        incus_run incus image list images:kali || true

    if (( CMD_EXIT_CODE == 0 )) && [[ -n "${CMD_OUTPUT}" ]]; then
        pass "Image search for 'kali' returned results"
    else
        fail "Image search for 'kali' failed or returned empty" \
             "non-empty results" \
             "exit code ${CMD_EXIT_CODE}" \
             "Vérifiez votre connexion Internet. Essayez: ping linuxcontainers.org"
    fi

    # -------------------------------------------------------------------------
    # Step 2: Filter images (ubuntu/noble amd64)
    # FR: Filtrer les images (ubuntu/noble amd64)
    # -------------------------------------------------------------------------
    learn_pause \
        "Commande: incus image list images:ubuntu/noble amd64
On peut filtrer par distribution ET architecture en ajoutant des mots-clés." \
        "Command: incus image list images:ubuntu/noble amd64
You can filter by distribution AND architecture by adding keywords."

    assert_output_not_empty \
        "Filtered search for Ubuntu Noble amd64" \
        "Aucun résultat. L'image images:ubuntu/noble n'existe peut-être plus dans le registre." \
        incus_run incus image list images:ubuntu/noble amd64

    # -------------------------------------------------------------------------
    # Step 3: Download Ubuntu image with alias
    # FR: Télécharger l'image Ubuntu avec un alias
    # -------------------------------------------------------------------------
    learn_pause \
        "Commande: incus image copy ${IMAGE_UBUNTU} local: --alias ${ALIAS_UBUNTU} --auto-update
Télécharge l'image et lui attribue l'alias '${ALIAS_UBUNTU}' pour usage local.
--auto-update garde l'image à jour automatiquement." \
        "Command: incus image copy ${IMAGE_UBUNTU} local: --alias ${ALIAS_UBUNTU} --auto-update
Downloads the image and assigns alias '${ALIAS_UBUNTU}' for local use.
--auto-update keeps the image automatically up to date."

    run_cmd "Download Ubuntu image (${IMAGE_UBUNTU})" "${TIMEOUT_DOWNLOAD}" \
        incus_run incus image copy ${IMAGE_UBUNTU} local: --alias ${ALIAS_UBUNTU} --auto-update || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Ubuntu image downloaded with alias '${ALIAS_UBUNTU}'"
    elif (( CMD_EXIT_CODE == 124 )); then
        fail "Ubuntu image download timed out (${TIMEOUT_DOWNLOAD}s)" \
             "download completes" \
             "TIMEOUT" \
             "Connexion lente? Augmentez TIMEOUT_DOWNLOAD dans config.env"
    else
        fail "Ubuntu image download failed" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}: ${CMD_OUTPUT:0:200}" \
             "Vérifiez le nom de l'image dans config.env: IMAGE_UBUNTU=${IMAGE_UBUNTU}"
    fi

    # -------------------------------------------------------------------------
    # Step 4: Download Alpine image
    # FR: Télécharger l'image Alpine
    # -------------------------------------------------------------------------
    run_cmd "Download Alpine image (${IMAGE_ALPINE})" "${TIMEOUT_DOWNLOAD}" \
        incus_run incus image copy ${IMAGE_ALPINE} local: --alias ${ALIAS_ALPINE} --auto-update || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Alpine image downloaded with alias '${ALIAS_ALPINE}'"
    else
        fail "Alpine image download failed" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}: ${CMD_OUTPUT:0:200}" \
             "Vérifiez: IMAGE_ALPINE=${IMAGE_ALPINE}"
    fi

    # -------------------------------------------------------------------------
    # Step 5: Download OpenWRT image
    # FR: Télécharger l'image OpenWRT
    # -------------------------------------------------------------------------
    run_cmd "Download OpenWRT image (${IMAGE_OPENWRT})" "${TIMEOUT_DOWNLOAD}" \
        incus_run incus image copy ${IMAGE_OPENWRT} local: --alias ${ALIAS_OPENWRT} --auto-update || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "OpenWRT image downloaded with alias '${ALIAS_OPENWRT}'"
    else
        fail "OpenWRT image download failed" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}: ${CMD_OUTPUT:0:200}" \
             "Vérifiez: IMAGE_OPENWRT=${IMAGE_OPENWRT}"
    fi

    # -------------------------------------------------------------------------
    # Step 6: Download Debian image
    # FR: Télécharger l'image Debian
    # -------------------------------------------------------------------------
    run_cmd "Download Debian image (${IMAGE_DEBIAN})" "${TIMEOUT_DOWNLOAD}" \
        incus_run incus image copy ${IMAGE_DEBIAN} local: --alias ${ALIAS_DEBIAN} --auto-update || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Debian image downloaded with alias '${ALIAS_DEBIAN}'"
    else
        fail "Debian image download failed" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}: ${CMD_OUTPUT:0:200}" \
             "Vérifiez: IMAGE_DEBIAN=${IMAGE_DEBIAN}"
    fi

    # -------------------------------------------------------------------------
    # Step 7: Verify all images present locally
    # FR: Vérifier que toutes les images sont présentes localement
    # -------------------------------------------------------------------------
    learn_pause \
        "Vérifions que toutes les images sont bien téléchargées localement
avec 'incus image ls'." \
        "Let's verify that all images have been downloaded locally
with 'incus image ls'."

    run_cmd "List local images" "${TIMEOUT_DEFAULT}" \
        incus_run incus image ls || true

    for alias in "${ALIAS_UBUNTU}" "${ALIAS_ALPINE}" "${ALIAS_OPENWRT}" "${ALIAS_DEBIAN}"; do
        if echo "${CMD_OUTPUT}" | grep -q "${alias}"; then
            pass "Local image '${alias}' found / trouvée"
        else
            fail "Local image '${alias}' not found / non trouvée" \
                 "alias '${alias}' in local images" \
                 "not found" \
                 "Retélécharger avec: incus image copy <remote>:... local: --alias ${alias}"
        fi
    done

    # -------------------------------------------------------------------------
    # Step 8: Delete Alpine image (lab exercise)
    # FR: Supprimer l'image Alpine (exercice du lab)
    # -------------------------------------------------------------------------
    learn_pause \
        "Maintenant, supprimons l'image Alpine pour pratiquer la gestion:
Commande: incus image delete ${ALIAS_ALPINE}" \
        "Now, let's delete the Alpine image to practice management:
Command: incus image delete ${ALIAS_ALPINE}"

    run_cmd "Delete Alpine image" "${TIMEOUT_DEFAULT}" \
        incus_run incus image delete ${ALIAS_ALPINE} || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Alpine image '${ALIAS_ALPINE}' deleted / supprimée"
    else
        fail "Alpine image deletion failed" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}" \
             "Image peut-être déjà supprimée ou en cours d'utilisation."
    fi

    # Verify deletion
    assert_output_not_contains \
        "Alpine image no longer in local list" \
        "${ALIAS_ALPINE}" \
        "L'image est encore présente. Vérifiez qu'aucun conteneur ne l'utilise." \
        incus_run incus image ls

    section_summary
}
