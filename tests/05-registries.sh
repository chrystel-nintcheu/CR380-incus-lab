#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 05 — Registres / Registries
# =============================================================================
#
# FR: Explorer les registres distants (remotes) d'Incus. Comprendre d'où
#     viennent les images de conteneurs.
#
# EN: Explore Incus remote registries. Understand where container images
#     come from.
#
# GitBook: ${GITBOOK_BASE_URL}/incus-lab/les-flux-incus/registre
# Depends on: 04-init
# =============================================================================

run_test() {
    section_header "05" "Registres / Registries" \
        "${GITBOOK_BASE_URL}/incus-lab/les-flux-incus/registre"

    check_dependency "04" || { section_summary; return 0; }

    learn_pause \
        "Les registres sont des serveurs distants qui hébergent des images
de conteneurs prêtes à l'emploi. C'est similaire à Docker Hub, mais pour
des images système complètes (Ubuntu, Alpine, Debian, etc.).

Le registre principal est 'images' (images.linuxcontainers.org)." \
        "Registries are remote servers hosting ready-to-use container images.
It's similar to Docker Hub, but for complete system images
(Ubuntu, Alpine, Debian, etc.).

The main registry is 'images' (images.linuxcontainers.org)."

    # -------------------------------------------------------------------------
    # Step 1: List remotes
    # FR: Lister les registres distants configurés
    # -------------------------------------------------------------------------
    # STUDENT NOTE: 'incus remote list' montre les serveurs d'images configurés
    # 'incus remote list' shows configured image servers
    assert_output_contains \
        "Remote 'images' is configured / est configuré" \
        "images" \
        "Le registre 'images' devrait être configuré par défaut après l'initialisation." \
        incus_run incus remote list

    # -------------------------------------------------------------------------
    # Step 2: Check YAML format output
    # FR: Vérifier la sortie en format YAML
    # -------------------------------------------------------------------------
    learn_pause \
        "Incus supporte plusieurs formats de sortie: table (défaut), yaml, json, csv.
C'est utile pour l'automatisation et l'analyse." \
        "Incus supports multiple output formats: table (default), yaml, json, csv.
This is useful for automation and analysis."

    run_cmd "Remote list in YAML format" "${TIMEOUT_DEFAULT}" \
        incus_run incus remote list --format yaml || true

    if (( CMD_EXIT_CODE == 0 )) && [[ -n "${CMD_OUTPUT}" ]]; then
        pass "incus remote list --format yaml produces output"
    else
        fail "incus remote list --format yaml failed" \
             "valid YAML output" \
             "exit code ${CMD_EXIT_CODE}" \
             "Essayez: incus remote list --format yaml"
    fi

    # -------------------------------------------------------------------------
    # Step 3: Check key remotes
    # FR: Vérifier les registres principaux
    # -------------------------------------------------------------------------
    assert_output_contains \
        "Remote 'local' is configured" \
        "local" \
        "Le registre 'local' est le serveur Incus local." \
        incus_run incus remote list

    section_summary
}
