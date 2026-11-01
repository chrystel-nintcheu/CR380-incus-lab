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
        "Ce script nettoie ce qui a été créé pendant les labs:
- Arrête et supprime les conteneurs du lab (les autres sont conservés)
- Supprime les images du lab
- Supprime les volumes et pools de stockage du lab
- Supprime les fichiers temporaires

Votre système sera comme avant les labs." \
        "This script cleans up what was created during the labs:
- Stops and deletes the lab containers (others are kept)
- Deletes the lab images
- Deletes the lab volumes and storage pools
- Removes temporary files

Your system will be like before the labs."

    # -------------------------------------------------------------------------
    # Step 1: Check that Incus is available
    # FR: Vérifier qu'Incus est disponible
    # -------------------------------------------------------------------------
    # Check if incus is available before trying to manage containers
    if ! command -v incus &>/dev/null || ! getent group incus-admin &>/dev/null; then
        skip "Incus not installed or no incus-admin group — nothing to clean" \
             "incus ou groupe incus-admin absent"

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
        section_summary
        return 0
    fi

    # -------------------------------------------------------------------------
    # Step 2: Delete all known containers (and only those)
    # FR: Supprimer les conteneurs du lab, et seulement ceux-là
    # -------------------------------------------------------------------------
    local containers=("${CT_U1}" "${CT_CLONE}" "${CT_ROUTER}" "${CT_DEBIAN}" "${CT_NGINX}" "${CT_APPWEB}")

    for ct in "${containers[@]}"; do
        cleanup_container "${ct}"
    done
    pass "All known containers cleaned up / Tous les conteneurs connus nettoyés"

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

    run_cmd "Check remaining lab containers" "${TIMEOUT_DEFAULT}" \
        incus_run incus list --format csv -c n || true

    if (( CMD_EXIT_CODE != 0 )); then
        fail "Cannot list containers" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}: ${CMD_OUTPUT:0:200}" \
             "Vérifiez le démon Incus: systemctl status incus"
    else
        local leftover=""
        for ct in "${containers[@]}"; do
            if printf '%s\n' "${CMD_OUTPUT}" | grep -qFx -- "${ct}"; then
                leftover+="${ct} "
            fi
        done
        if [[ -z "${leftover}" ]]; then
            pass "No lab containers remaining / Aucun conteneur du lab restant"
        else
            fail "Some lab containers still exist" \
                 "none of: ${containers[*]}" \
                 "${leftover}" \
                 "Supprimez manuellement: incus delete --force <nom>"
        fi
    fi

    run_cmd "Check remaining lab images" "${TIMEOUT_DEFAULT}" \
        incus_run incus image alias list --format csv || true

    if (( CMD_EXIT_CODE != 0 )); then
        fail "Cannot list image aliases" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}: ${CMD_OUTPUT:0:200}" \
             "Vérifiez le démon Incus: systemctl status incus"
    else
        local leftover_img=""
        for img in "${images[@]}"; do
            if printf '%s\n' "${CMD_OUTPUT}" | cut -d, -f1 | grep -qFx -- "${img}"; then
                leftover_img+="${img} "
            fi
        done
        if [[ -z "${leftover_img}" ]]; then
            pass "No lab images remaining / Aucune image du lab restante"
        else
            fail "Some lab images still exist" \
                 "none of: ${images[*]}" \
                 "${leftover_img}" \
                 "Supprimez manuellement: incus image delete <alias>"
        fi
    fi

    learn_pause \
        "🎉 Nettoyage terminé! Votre environnement est propre et prêt
pour une prochaine session de lab." \
        "🎉 Cleanup complete! Your environment is clean and ready
for the next lab session."

    section_summary
}
