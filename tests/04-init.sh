#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 04 — Initialisation / Initialization
# =============================================================================
#
# FR: Initialiser Incus avec un fichier preseed YAML qui correspond aux
#     réponses données lors de l'initialisation interactive dans le lab.
#
# EN: Initialize Incus with a preseed YAML file that matches the answers
#     given during interactive initialization in the lab.
#
# GitBook: ${GITBOOK_BASE_URL}/incus-lab/initialisation
# Depends on: 03-post-install
# =============================================================================

run_test() {
    section_header "04" "Initialisation / Initialization" \
        "${GITBOOK_BASE_URL}/incus-lab/initialisation"

    check_dependency "03" || { section_summary; return 0; }

    learn_pause \
        "L'initialisation configure le stockage, le réseau, et d'autres
paramètres globaux d'Incus. Nous utilisons un fichier 'preseed' YAML
qui reproduit exactement les réponses de l'initialisation interactive." \
        "Initialization configures storage, networking, and other global
Incus settings. We use a preseed YAML file that exactly reproduces
the answers from the interactive initialization."

    # -------------------------------------------------------------------------
    # Step 1: Generate preseed YAML
    # FR: Générer le fichier preseed YAML
    # -------------------------------------------------------------------------
    # STUDENT NOTE: Le preseed YAML contient toutes les réponses que vous
    # donneriez dans 'incus admin init'. C'est utile pour l'automatisation.
    # The preseed YAML contains all the answers you would give in
    # 'incus admin init'. It's useful for automation.

    local preseed_yaml
    preseed_yaml=$(cat <<PRESEEDEOF
config: {}
networks:
- config:
    ipv4.address: ${BRIDGE_IPV4}
    ipv4.nat: "true"
    ipv6.address: ${BRIDGE_IPV6}
  description: ""
  name: ${BRIDGE_NAME}
  type: bridge
  project: default
storage_pools:
- config: {}
  description: ""
  name: ${STORAGE_POOL_NAME}
  driver: ${STORAGE_POOL_DRIVER}
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      network: ${BRIDGE_NAME}
      type: nic
    root:
      path: /
      pool: ${STORAGE_POOL_NAME}
      type: disk
  name: default
projects: []
cluster: null
PRESEEDEOF
)

    learn_pause \
        "Voici le contenu du preseed YAML:

$(echo "${preseed_yaml}" | head -25)

Il définit:
- Un pool de stockage '${STORAGE_POOL_NAME}' de type '${STORAGE_POOL_DRIVER}'
- Un pont réseau '${BRIDGE_NAME}' avec IPv4 auto et IPv6 désactivé
- Un profil 'default' qui utilise ce pool et ce réseau" \
        "Here is the preseed YAML content:

$(echo "${preseed_yaml}" | head -25)

It defines:
- A storage pool '${STORAGE_POOL_NAME}' of type '${STORAGE_POOL_DRIVER}'
- A network bridge '${BRIDGE_NAME}' with IPv4 auto and IPv6 disabled
- A 'default' profile using that pool and network"

    # -------------------------------------------------------------------------
    # Step 2: Apply preseed
    # FR: Appliquer le preseed via incus admin init --preseed
    # -------------------------------------------------------------------------
    # Clean up any leftover bridge interface from previous install
    # (Linux bridge interfaces persist across package reinstalls, which
    # causes preseed to fail with "Network not found" when trying to update)
    if ip link show "${BRIDGE_NAME}" &>/dev/null; then
        log "Removing leftover bridge interface '${BRIDGE_NAME}'..."
        sudo ip link set "${BRIDGE_NAME}" down 2>/dev/null || true
        sudo ip link delete "${BRIDGE_NAME}" 2>/dev/null || true
    fi
    # Also remove leftover storage pool directory if any
    if incus_run incus storage show ${STORAGE_POOL_NAME} &>/dev/null; then
        log "Removing leftover storage pool '${STORAGE_POOL_NAME}'..."
        incus_run incus storage delete ${STORAGE_POOL_NAME} 2>/dev/null || true
    fi

    log "Applying preseed YAML..."
    if (( EUID == 0 )); then
        run_cmd "Apply preseed YAML" "${TIMEOUT_DEFAULT}" \
            bash -c "echo '${preseed_yaml}' | incus admin init --preseed" || true
    else
        run_cmd "Apply preseed YAML" "${TIMEOUT_DEFAULT}" \
            bash -c "echo '${preseed_yaml}' | sg incus-admin -c 'incus admin init --preseed'" || true
    fi

    if (( CMD_EXIT_CODE == 0 )); then
        pass "incus admin init --preseed succeeded / a réussi"
    else
        fail "incus admin init --preseed failed / a échoué" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}: ${CMD_OUTPUT}" \
             "Si déjà initialisé, exécutez d'abord le lab 01 pour nettoyer. / If already initialized, run lab 01 first to clean up."
    fi

    # -------------------------------------------------------------------------
    # Step 3: Verify incus info
    # FR: Vérifier que incus info fonctionne
    # -------------------------------------------------------------------------
    run_cmd "Check incus info" "${TIMEOUT_DEFAULT}" \
        incus_run incus info || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "incus info succeeds after init / réussit après init"
    else
        fail "incus info failed after init" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}" \
             "Vérifiez que le service incus est actif: systemctl status incus"
    fi

    # -------------------------------------------------------------------------
    # Step 4: Verify storage pool
    # FR: Vérifier que le pool de stockage existe
    # -------------------------------------------------------------------------
    assert_output_contains \
        "Storage pool '${STORAGE_POOL_NAME}' exists / existe" \
        "${STORAGE_POOL_NAME}" \
        "Le pool de stockage n'a pas été créé. Revérifiez le preseed YAML." \
        incus_run incus storage list

    # -------------------------------------------------------------------------
    # Step 5: Verify network bridge
    # FR: Vérifier que le pont réseau existe
    # -------------------------------------------------------------------------
    assert_output_contains \
        "Network bridge '${BRIDGE_NAME}' exists / existe" \
        "${BRIDGE_NAME}" \
        "Le pont réseau n'a pas été créé. Vérifiez le preseed YAML." \
        incus_run incus network list

    # -------------------------------------------------------------------------
    # Step 6: Verify default profile
    # FR: Vérifier que le profil default est configuré
    # -------------------------------------------------------------------------
    run_cmd "Check default profile" "${TIMEOUT_DEFAULT}" \
        incus_run incus profile show default || true

    if echo "${CMD_OUTPUT}" | grep -q "${STORAGE_POOL_NAME}"; then
        pass "Default profile uses pool '${STORAGE_POOL_NAME}'"
    else
        fail "Default profile does not reference '${STORAGE_POOL_NAME}'" \
             "pool: ${STORAGE_POOL_NAME}" \
             "${CMD_OUTPUT:0:200}" \
             "Revérifiez le preseed. Le profil default doit utiliser le pool ${STORAGE_POOL_NAME}."
    fi

    if echo "${CMD_OUTPUT}" | grep -q "${BRIDGE_NAME}"; then
        pass "Default profile uses network '${BRIDGE_NAME}'"
    else
        fail "Default profile does not reference '${BRIDGE_NAME}'" \
             "network: ${BRIDGE_NAME}" \
             "${CMD_OUTPUT:0:200}" \
             "Revérifiez le preseed. Le profil default doit utiliser le réseau ${BRIDGE_NAME}."
    fi

    section_summary
}
