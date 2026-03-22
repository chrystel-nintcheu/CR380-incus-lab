#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 12 — Volumes
# =============================================================================
#
# FR: Créer un volume de stockage, l'attacher à un conteneur et y stocker
#     des données persistantes. Les volumes survivent à la suppression
#     des conteneurs.
#
# EN: Create a storage volume, attach it to a container and store persistent
#     data. Volumes survive container deletion.
#
# GitBook: ${GITBOOK_BASE_URL}/incus-lab/la-persistance/volume
# Depends on: 11-storage
# =============================================================================

run_test() {
    section_header "12" "Volumes" \
        "${GITBOOK_BASE_URL}/incus-lab/la-persistance/volume"

    check_dependency "11" || { section_summary; return 0; }

    learn_pause \
        "Un 'volume' Incus est un espace de stockage persistant qui peut être
attaché à un ou plusieurs conteneurs. Contrairement au filesystem du
conteneur, les données dans un volume survivent à la suppression du conteneur.

C'est similaire aux 'Docker volumes'." \
        "An Incus 'volume' is a persistent storage space that can be attached
to one or more containers. Unlike the container's filesystem, data in a
volume survives container deletion.

This is similar to 'Docker volumes'."

    local storage_dir="${HOME}/${ADV_STORAGE_DIR}"

    # -------------------------------------------------------------------------
    # Step 1: Create volume
    # FR: Créer un volume
    # -------------------------------------------------------------------------
    # STUDENT NOTE: Un volume est un sous-ensemble du pool de stockage.
    # Il peut être attaché/détaché des conteneurs à volonté.
    # A volume is a subset of the storage pool.
    # It can be attached/detached from containers at will.

    # Cleanup existing volume
    cleanup_volume "${ADV_STORAGE_POOL}" "${ADV_VOLUME}"

    learn_pause \
        "Commande: incus storage volume create ${ADV_STORAGE_POOL} ${ADV_VOLUME}
Ceci crée un volume nommé '${ADV_VOLUME}' dans le pool '${ADV_STORAGE_POOL}'." \
        "Command: incus storage volume create ${ADV_STORAGE_POOL} ${ADV_VOLUME}
This creates a volume named '${ADV_VOLUME}' in pool '${ADV_STORAGE_POOL}'."

    run_cmd "Create volume '${ADV_VOLUME}'" "${TIMEOUT_DEFAULT}" \
        incus_run incus storage volume create ${ADV_STORAGE_POOL} ${ADV_VOLUME} || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Volume '${ADV_VOLUME}' created in pool '${ADV_STORAGE_POOL}'"
    else
        fail "Failed to create volume '${ADV_VOLUME}'" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}: ${CMD_OUTPUT:0:200}" \
             "Le pool '${ADV_STORAGE_POOL}' existe-t-il? Vérifiez: incus storage list"
    fi

    # -------------------------------------------------------------------------
    # Step 2: Verify volume in list
    # FR: Vérifier le volume dans la liste
    # -------------------------------------------------------------------------
    assert_output_contains \
        "Volume '${ADV_VOLUME}' in pool list" \
        "${ADV_VOLUME}" \
        "Le volume devrait apparaître dans la liste." \
        incus_run incus storage volume list ${ADV_STORAGE_POOL}

    # -------------------------------------------------------------------------
    # Step 3: Attach volume to appwebCT
    # FR: Attacher le volume au conteneur appwebCT
    # -------------------------------------------------------------------------
    learn_pause \
        "Commande: incus storage volume attach ${ADV_STORAGE_POOL} ${ADV_VOLUME} ${CT_APPWEB} /var/www
Ceci monte le volume '${ADV_VOLUME}' au chemin /var/www dans le conteneur.

⚠️  IMPORTANT: Le contenu précédent de /var/www sera masqué par le volume.
Le volume est initialement vide — nous devrons y copier l'application." \
        "Command: incus storage volume attach ${ADV_STORAGE_POOL} ${ADV_VOLUME} ${CT_APPWEB} /var/www
This mounts the volume '${ADV_VOLUME}' at /var/www in the container.

⚠️  IMPORTANT: Previous /var/www content will be hidden by the volume.
The volume starts empty — we'll need to copy the application into it."

    run_cmd "Attach volume to '${CT_APPWEB}'" "${TIMEOUT_DEFAULT}" \
        incus_run incus storage volume attach ${ADV_STORAGE_POOL} ${ADV_VOLUME} ${CT_APPWEB} /var/www || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Volume '${ADV_VOLUME}' attached to '${CT_APPWEB}' at /var/www"
    else
        fail "Failed to attach volume" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}: ${CMD_OUTPUT:0:200}" \
             "Le conteneur est-il en cours d'exécution? Vérifiez: incus ls"
    fi

    # -------------------------------------------------------------------------
    # Step 4: Verify volume is used
    # FR: Vérifier que le volume est utilisé
    # -------------------------------------------------------------------------
    run_cmd "Show volume details" "${TIMEOUT_DEFAULT}" \
        incus_run incus storage volume show ${ADV_STORAGE_POOL} ${ADV_VOLUME} || true

    if echo "${CMD_OUTPUT}" | grep -q "${CT_APPWEB}"; then
        pass "Volume '${ADV_VOLUME}' is used by '${CT_APPWEB}'"
    else
        fail "Volume not showing as used by '${CT_APPWEB}'" \
             "used_by contains '${CT_APPWEB}'" \
             "${CMD_OUTPUT:0:200}" \
             "Vérifiez l'attachement: incus storage volume show ${ADV_STORAGE_POOL} ${ADV_VOLUME}"
    fi

    # -------------------------------------------------------------------------
    # Step 5: Set permissions on volume directory
    # FR: Définir les permissions sur le répertoire du volume
    # -------------------------------------------------------------------------
    learn_pause \
        "Le volume est stocké dans ${storage_dir}/custom/.
Nous devons ajuster les permissions pour que le serveur web dans le
conteneur puisse lire les fichiers.

Commande: sudo chmod -R 777 ${storage_dir}/custom

⚠️  Note: 777 est utilisé ici pour simplifier. En production,
utilisez des permissions plus restrictives." \
        "The volume is stored in ${storage_dir}/custom/.
We need to adjust permissions so the web server in the container
can read the files.

Command: sudo chmod -R 777 ${storage_dir}/custom

⚠️  Note: 777 is used here for simplicity. In production,
use more restrictive permissions."

    run_cmd "Set permissions on volume directory" "${TIMEOUT_DEFAULT}" \
        sudo chmod -R 777 "${storage_dir}/custom" || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Permissions set on ${storage_dir}/custom"
    else
        fail "Failed to set permissions" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}" \
             "Le répertoire ${storage_dir}/custom existe-t-il? ls -la ${storage_dir}/"
    fi

    # -------------------------------------------------------------------------
    # Step 6: Clone demo app into volume
    # FR: Cloner l'application de démo dans le volume
    # -------------------------------------------------------------------------
    local volume_html_dir="${storage_dir}/custom/default_${ADV_VOLUME}/html"

    learn_pause \
        "Nous clonons l'application de démo directement dans le répertoire
du volume pour que le conteneur puisse la servir.

Destination: ${volume_html_dir}" \
        "We clone the demo app directly into the volume directory
so the container can serve it.

Destination: ${volume_html_dir}"

    rm -rf "${volume_html_dir}"
    mkdir -p "$(dirname "${volume_html_dir}")"

    run_cmd "Clone demo app into volume" "${TIMEOUT_DOWNLOAD}" \
        git clone "${DEMO_APP_REPO}" "${volume_html_dir}" || true

    if (( CMD_EXIT_CODE == 0 )) && [[ -d "${volume_html_dir}" ]]; then
        pass "Demo app cloned into volume at '${volume_html_dir}'"
    else
        fail "Failed to clone demo app into volume" \
             "directory exists at ${volume_html_dir}" \
             "exit code ${CMD_EXIT_CODE}" \
             "Vérifiez: DEMO_APP_REPO=${DEMO_APP_REPO}"
    fi

    # Set permissions on cloned files
    sudo chmod -R 777 "${volume_html_dir}" 2>/dev/null || true

    learn_pause \
        "Les données du volume sont maintenant accessibles au conteneur.
Même si le conteneur '${CT_APPWEB}' est supprimé, les données
dans le volume '${ADV_VOLUME}' sont préservées.

C'est le concept clé de la persistance avec les volumes!" \
        "The volume data is now accessible to the container.
Even if the container '${CT_APPWEB}' is deleted, the data
in the volume '${ADV_VOLUME}' is preserved.

This is the key concept of persistence with volumes!"

    section_summary
}
