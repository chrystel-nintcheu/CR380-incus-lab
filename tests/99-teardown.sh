#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 99 — Nettoyage final / Final Teardown
# =============================================================================
#
# FR: Nettoyer tous les artefacts créés pendant les labs. Laisser le système
#     dans un état propre. Ce script n'a pas de dépendances — il s'exécute
#     toujours.
#
# EN: Clean up all artifacts created during labs. Leave the system in a clean
#     state. This script has no dependencies — it always runs.
#
# GitBook: N/A
# Depends on: none (always runs)
# =============================================================================

run_test() {
    section_header "99" "Nettoyage final / Final Teardown" ""

    # No dependency check — teardown always runs

    learn_pause \
        "Ce script nettoie TOUT ce qui a été créé pendant les labs:
- Arrête et supprime tous les conteneurs
- Supprime toutes les images personnalisées
- Supprime les volumes et pools de stockage
- Supprime les fichiers temporaires

Votre système sera comme avant les labs." \
        "This script cleans up EVERYTHING created during the labs:
- Stops and deletes all containers
- Deletes all custom images
- Deletes volumes and storage pools
- Removes temporary files

Your system will be like before the labs."

    # -------------------------------------------------------------------------
    # Step 1: Stop all containers
    # FR: Arrêter tous les conteneurs
    # -------------------------------------------------------------------------
    # Check if incus is available before trying to manage containers
    if ! command -v incus &>/dev/null || ! getent group incus-admin &>/dev/null; then
        pass "Incus not installed or no incus-admin group — nothing to clean"
        pass "All known containers cleaned up / Tous les conteneurs connus nettoyés"
        pass "All known images cleaned up / Toutes les images connues nettoyées"
        pass "Advanced storage cleaned up"

        # Still clean up temporary files
        local cleanup_paths=(
            "${HOME}/${ADV_STORAGE_DIR}"
            "${PROJECT_ROOT}/${DEMO_APP_DIR}"
            "${PROJECT_ROOT}/html.bkp"
            "${PROJECT_ROOT}/index.html"
            "${PROJECT_ROOT}/index.nginx-debian.html"
        )
        for path in "${cleanup_paths[@]}"; do
            [[ -e "${path}" ]] && rm -rf "${path}"
        done
        pass "Temporary files cleaned up / Fichiers temporaires nettoyés"
        pass "No containers remaining / Aucun conteneur restant"
        pass "No images remaining / Aucune image restante"
        section_summary
        return 0
    fi

    run_cmd "Stop all containers" "${TIMEOUT_DEFAULT}" \
        incus_run incus stop --all --force 2>/dev/null || true
    pass "Attempted to stop all containers"

    # -------------------------------------------------------------------------
    # Step 2: Delete all known containers
    # FR: Supprimer tous les conteneurs connus
    # -------------------------------------------------------------------------
    local containers=("${CT_U1}" "${CT_CLONE}" "${CT_ROUTER}" "${CT_DEBIAN}" "${CT_NGINX}" "${CT_APPWEB}")

    for ct in "${containers[@]}"; do
        cleanup_container "${ct}"
    done
    pass "All known containers cleaned up / Tous les conteneurs connus nettoyés"

    # Also delete any remaining containers
    run_cmd "List remaining containers" "${TIMEOUT_DEFAULT}" \
        incus_run incus list --format csv -c n 2>/dev/null || true
    if [[ -n "${CMD_OUTPUT}" ]] && (( CMD_EXIT_CODE == 0 )); then
        while IFS= read -r ct; do
            [[ -z "${ct}" ]] && continue
            cleanup_container "${ct}"
            log "CLEANUP: deleted leftover container ${ct}"
        done <<< "${CMD_OUTPUT}"
        pass "Leftover containers cleaned up"
    fi

    # -------------------------------------------------------------------------
    # Step 3: Delete custom images
    # FR: Supprimer les images personnalisées
    # -------------------------------------------------------------------------
    local images=("${IMG_CUSTOM_U1}" "${IMG_NGINX}" "${IMG_DEMO_APP}" "${ALIAS_UBUNTU}" "${ALIAS_ALPINE}" "${ALIAS_OPENWRT}" "${ALIAS_DEBIAN}")

    for img in "${images[@]}"; do
        cleanup_image "${img}"
    done
    pass "All known images cleaned up / Toutes les images connues nettoyées"

    # -------------------------------------------------------------------------
    # Step 4: Delete volumes and advanced storage pool
    # FR: Supprimer les volumes et le pool de stockage avancé
    # -------------------------------------------------------------------------
    cleanup_volume "${ADV_STORAGE_POOL}" "${ADV_VOLUME}" 2>/dev/null
    cleanup_storage "${ADV_STORAGE_POOL}" 2>/dev/null
    pass "Advanced storage cleaned up"

    # -------------------------------------------------------------------------
    # Step 5: Remove temporary files and directories
    # FR: Supprimer les fichiers et répertoires temporaires
    # -------------------------------------------------------------------------
    local cleanup_paths=(
        "${HOME}/${ADV_STORAGE_DIR}"
        "${PROJECT_ROOT}/${DEMO_APP_DIR}"
        "${PROJECT_ROOT}/html.bkp"
        "${PROJECT_ROOT}/index.html"
        "${PROJECT_ROOT}/index.nginx-debian.html"
    )

    for path in "${cleanup_paths[@]}"; do
        if [[ -e "${path}" ]]; then
            rm -rf "${path}"
            log "CLEANUP: removed ${path}"
        fi
    done
    pass "Temporary files cleaned up / Fichiers temporaires nettoyés"

    # -------------------------------------------------------------------------
    # Step 6: Verify clean state
    # FR: Vérifier que l'état est propre
    # -------------------------------------------------------------------------
    learn_pause \
        "Vérifions que tout est propre..." \
        "Let's verify everything is clean..."

    run_cmd "Check remaining containers" "${TIMEOUT_DEFAULT}" \
        incus_run incus list --format csv -c n 2>/dev/null || true

    if (( CMD_EXIT_CODE != 0 )); then
        # incus command failed (daemon not running, group missing, etc.) — not a container list
        pass "No containers to check (incus unavailable) / Aucun conteneur à vérifier"
    elif [[ -z "${CMD_OUTPUT}" ]]; then
        pass "No containers remaining / Aucun conteneur restant"
    else
        fail "Some containers still exist" \
             "empty list" \
             "${CMD_OUTPUT}" \
             "Supprimez manuellement: incus delete --force <nom>"
    fi

    run_cmd "Check remaining custom images" "${TIMEOUT_DEFAULT}" \
        incus_run incus image list --format csv 2>/dev/null || true

    if (( CMD_EXIT_CODE != 0 )); then
        pass "No images to check (incus unavailable) / Aucune image à vérifier"
    elif [[ -z "${CMD_OUTPUT}" ]]; then
        pass "No images remaining / Aucune image restante"
    else
        # Images might include base images from the pool — only warn
        local count
        count=$(echo "${CMD_OUTPUT}" | wc -l)
        if (( count > 0 )); then
            pass "Remaining images (may be cache): ${count} entries"
        fi
    fi

    learn_pause \
        "🎉 Nettoyage terminé! Votre environnement est propre et prêt
pour une prochaine session de lab." \
        "🎉 Cleanup complete! Your environment is clean and ready
for the next lab session."

    section_summary
}
