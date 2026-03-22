#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 11 — Stockage / Storage
# =============================================================================
#
# FR: Créer un pool de stockage de type répertoire et assigner un conteneur
#     à ce pool. Comprendre la relation entre pools et conteneurs.
#
# EN: Create a directory-type storage pool and assign a container to it.
#     Understand the relationship between pools and containers.
#
# GitBook: ${GITBOOK_BASE_URL}/incus-lab/la-persistance/stockage-pool-de-stockage
# Depends on: 10-file-transfer
# =============================================================================

run_test() {
    section_header "11" "Stockage / Storage" \
        "${GITBOOK_BASE_URL}/incus-lab/la-persistance/stockage-pool-de-stockage"

    check_dependency "10" || { section_summary; return 0; }

    learn_pause \
        "Les 'pools de stockage' dans Incus définissent où les données des
conteneurs sont physiquement stockées. Types supportés:
- dir: simple répertoire sur le système de fichiers
- zfs: ZFS pool (snapshots, compression)
- btrfs: Btrfs subvolume
- lvm: Logical Volume Manager

Nous créons un pool de type 'dir' pointant vers un répertoire local." \
        "Storage pools in Incus define where container data is physically stored.
Supported types:
- dir: simple directory on the filesystem
- zfs: ZFS pool (snapshots, compression)
- btrfs: Btrfs subvolume
- lvm: Logical Volume Manager

We create a 'dir' type pool pointing to a local directory."

    # -------------------------------------------------------------------------
    # Step 1: Create local directory for storage
    # FR: Créer un répertoire local pour le stockage
    # -------------------------------------------------------------------------
    local storage_dir="${HOME}/${ADV_STORAGE_DIR}"

    learn_pause \
        "Commande: mkdir -p ${storage_dir}
Créons d'abord le répertoire qui servira de base au pool de stockage." \
        "Command: mkdir -p ${storage_dir}
First, let's create the directory that will serve as the storage pool's base."

    mkdir -p "${storage_dir}"
    if [[ -d "${storage_dir}" ]]; then
        pass "Directory '${storage_dir}' created"
    else
        fail "Failed to create directory '${storage_dir}'" "" "" ""
    fi

    # -------------------------------------------------------------------------
    # Step 2: Create storage pool
    # FR: Créer le pool de stockage
    # -------------------------------------------------------------------------
    # STUDENT NOTE: 'incus storage create' crée un nouveau pool.
    # Le paramètre source= pointe vers le répertoire physique.
    # 'incus storage create' creates a new pool.
    # The source= parameter points to the physical directory.

    # Cleanup if exists
    cleanup_storage "${ADV_STORAGE_POOL}"

    learn_pause \
        "Commande: incus storage create ${ADV_STORAGE_POOL} dir source=${storage_dir}
Ceci crée un pool de stockage nommé '${ADV_STORAGE_POOL}' de type 'dir'
qui utilise le répertoire '${storage_dir}'." \
        "Command: incus storage create ${ADV_STORAGE_POOL} dir source=${storage_dir}
This creates a storage pool named '${ADV_STORAGE_POOL}' of type 'dir'
using the directory '${storage_dir}'."

    run_cmd "Create storage pool '${ADV_STORAGE_POOL}'" "${TIMEOUT_DEFAULT}" \
        incus_run incus storage create ${ADV_STORAGE_POOL} dir source=${storage_dir} || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Storage pool '${ADV_STORAGE_POOL}' created"
    else
        fail "Failed to create storage pool '${ADV_STORAGE_POOL}'" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}: ${CMD_OUTPUT:0:200}" \
             "Le pool existe peut-être déjà. Vérifiez: incus storage list"
    fi

    # Verify pool exists
    assert_resource_exists "storage" "${ADV_STORAGE_POOL}" \
        "Le pool '${ADV_STORAGE_POOL}' devrait apparaître dans 'incus storage list'."

    # -------------------------------------------------------------------------
    # Step 3: Stop all containers, then launch appwebCT from demo-app image
    # FR: Arrêter tous les conteneurs, puis lancer appwebCT depuis demo-app
    # -------------------------------------------------------------------------
    learn_pause \
        "Nous arrêtons tous les conteneurs et lançons un nouveau conteneur
'${CT_APPWEB}' depuis l'image '${IMG_DEMO_APP}' en utilisant notre
nouveau pool de stockage (-s ${ADV_STORAGE_POOL}).

Commande: incus stop --all
          incus launch ${IMG_DEMO_APP} ${CT_APPWEB} -s ${ADV_STORAGE_POOL}" \
        "We stop all containers and launch a new container
'${CT_APPWEB}' from the '${IMG_DEMO_APP}' image using our
new storage pool (-s ${ADV_STORAGE_POOL}).

Command: incus stop --all
         incus launch ${IMG_DEMO_APP} ${CT_APPWEB} -s ${ADV_STORAGE_POOL}"

    run_cmd "Stop all containers" "${TIMEOUT_DEFAULT}" \
        incus_run incus stop --all || true

    cleanup_container "${CT_APPWEB}"

    run_cmd "Launch '${CT_APPWEB}' from '${IMG_DEMO_APP}' on pool '${ADV_STORAGE_POOL}'" "${TIMEOUT_CONTAINER_READY}" \
        incus_run incus launch ${IMG_DEMO_APP} ${CT_APPWEB} -s ${ADV_STORAGE_POOL} || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Container '${CT_APPWEB}' launched on pool '${ADV_STORAGE_POOL}'"
    elif [[ "${CMD_OUTPUT}" == *"already"* ]]; then
        pass "Container '${CT_APPWEB}' already exists"
    else
        fail "Failed to launch '${CT_APPWEB}'" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}: ${CMD_OUTPUT:0:200}" \
             "L'image '${IMG_DEMO_APP}' existe-t-elle? Vérifiez: incus image ls"
    fi

    wait_for_ready "${CT_APPWEB}"

    # -------------------------------------------------------------------------
    # Step 4: Expose port for appwebCT
    # FR: Exposer le port pour appwebCT
    # -------------------------------------------------------------------------
    # Remove any existing proxy device from previous run
    incus_run incus config device remove ${CT_APPWEB} monport80vers${PORT_APPWEB_LISTEN} 2>/dev/null || true

    run_cmd "Add proxy device for port ${PORT_APPWEB_LISTEN}" "${TIMEOUT_DEFAULT}" \
        incus_run incus config device add ${CT_APPWEB} monport80vers${PORT_APPWEB_LISTEN} proxy listen=tcp:0.0.0.0:${PORT_APPWEB_LISTEN} connect=tcp:127.0.0.1:80 || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Proxy device added on port ${PORT_APPWEB_LISTEN} for '${CT_APPWEB}'"
    else
        fail "Failed to add proxy device" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}" \
             "Port ${PORT_APPWEB_LISTEN} peut être occupé."
    fi

    # -------------------------------------------------------------------------
    # Step 5: Verify container config shows proxy + correct root pool
    # FR: Vérifier que la config du conteneur montre le proxy et le bon pool
    # -------------------------------------------------------------------------
    run_cmd "Show container config" "${TIMEOUT_DEFAULT}" \
        incus_run incus config show ${CT_APPWEB} || true

    if echo "${CMD_OUTPUT}" | grep -q "monport80vers${PORT_APPWEB_LISTEN}"; then
        pass "Proxy device visible in '${CT_APPWEB}' config"
    else
        fail "Proxy device not in '${CT_APPWEB}' config" \
             "device monport80vers${PORT_APPWEB_LISTEN}" \
             "not found" \
             "Vérifiez: incus config show ${CT_APPWEB}"
    fi

    # -------------------------------------------------------------------------
    # Step 6: Verify storage pool shows container
    # FR: Vérifier que le pool de stockage montre le conteneur
    # -------------------------------------------------------------------------
    assert_output_contains \
        "Storage pool '${ADV_STORAGE_POOL}' used by '${CT_APPWEB}'" \
        "${CT_APPWEB}" \
        "Le pool devrait être utilisé par '${CT_APPWEB}'. Vérifiez: incus storage show ${ADV_STORAGE_POOL}" \
        incus_run incus storage show ${ADV_STORAGE_POOL}

    section_summary
}
