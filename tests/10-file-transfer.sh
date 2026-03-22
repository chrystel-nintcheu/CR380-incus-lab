#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 10 — Transfert de fichiers / File Transfer
# =============================================================================
#
# FR: Transférer des fichiers et répertoires entre l'hôte et les conteneurs.
#     Publier le résultat comme image d'application.
#
# EN: Transfer files and directories between host and containers.
#     Publish the result as an application image.
#
# GitBook: ${GITBOOK_BASE_URL}/incus-lab/la-persistance/transfert-de-fichiers-et-repertoires
# Depends on: 09-app-container
# =============================================================================

run_test() {
    section_header "10" "Transfert de fichiers / File Transfer" \
        "${GITBOOK_BASE_URL}/incus-lab/la-persistance/transfert-de-fichiers-et-repertoires"

    check_dependency "09" || { section_summary; return 0; }

    learn_pause \
        "Incus permet de transférer des fichiers entre l'hôte et les conteneurs:
- incus file pull <conteneur>/<chemin> <destination>  — copier depuis le conteneur
- incus file push <source> <conteneur>/<chemin>       — copier vers le conteneur
- Ajouter -r pour les répertoires (récursif)

C'est similaire à 'docker cp'." \
        "Incus allows file transfers between host and containers:
- incus file pull <container>/<path> <destination>  — copy from container
- incus file push <source> <container>/<path>       — copy to container
- Add -r for directories (recursive)

This is similar to 'docker cp'."

    # -------------------------------------------------------------------------
    # Step 1: Pull default nginx index page
    # FR: Récupérer la page index par défaut de nginx
    # -------------------------------------------------------------------------
    # STUDENT NOTE: Le fichier index par défaut de nginx sur Debian est
    # /var/www/html/index.nginx-debian.html
    # The default nginx index file on Debian is
    # /var/www/html/index.nginx-debian.html
    local work_dir="${PROJECT_ROOT}"

    learn_pause \
        "Commande: incus file pull ${CT_NGINX}/var/www/html/index.nginx-debian.html .
Ceci télécharge la page HTML par défaut de nginx depuis le conteneur." \
        "Command: incus file pull ${CT_NGINX}/var/www/html/index.nginx-debian.html .
This downloads the default nginx HTML page from the container."

    run_cmd "Pull default index page" "${TIMEOUT_DEFAULT}" \
        incus_run incus file pull ${CT_NGINX}/var/www/html/index.nginx-debian.html ${work_dir}/ || true

    if (( CMD_EXIT_CODE == 0 )) && [[ -f "${work_dir}/index.nginx-debian.html" ]]; then
        pass "Pulled index.nginx-debian.html from '${CT_NGINX}'"
    else
        fail "Failed to pull index file" \
             "file exists at ${work_dir}/index.nginx-debian.html" \
             "exit code ${CMD_EXIT_CODE}" \
             "Vérifiez que nginx est installé dans le conteneur: incus exec ${CT_NGINX} -- ls /var/www/html/"
    fi

    # -------------------------------------------------------------------------
    # Step 2: Create custom index.html
    # FR: Créer un fichier index.html personnalisé
    # -------------------------------------------------------------------------
    learn_pause \
        "Créons une page HTML personnalisée avec le message 'Bonsoir classe CR380'
et envoyons-la dans le conteneur." \
        "Let's create a custom HTML page with the message 'Bonsoir classe CR380'
and push it to the container."

    cat > "${work_dir}/index.html" <<'HTMLEOF'
<!DOCTYPE html>
<html>
<head><title>CR380</title></head>
<body><h1>Bonsoir classe CR380</h1></body>
</html>
HTMLEOF

    if [[ -f "${work_dir}/index.html" ]]; then
        pass "Custom index.html created"
    else
        fail "Failed to create custom index.html" "" "" ""
    fi

    # -------------------------------------------------------------------------
    # Step 3: Rename original inside container
    # FR: Renommer l'original dans le conteneur
    # -------------------------------------------------------------------------
    run_cmd "Rename original index in container" "${TIMEOUT_DEFAULT}" \
        incus_run incus exec ${CT_NGINX} -- mv /var/www/html/index.nginx-debian.html /var/www/html/index.nginx-debian.html.orig || true

    # -------------------------------------------------------------------------
    # Step 4: Push custom index.html
    # FR: Envoyer le fichier index.html personnalisé
    # -------------------------------------------------------------------------
    run_cmd "Push custom index.html" "${TIMEOUT_DEFAULT}" \
        incus_run incus file push ${work_dir}/index.html ${CT_NGINX}/var/www/html/ || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Pushed index.html to '${CT_NGINX}'"
    else
        fail "Failed to push index.html" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}" \
             "Vérifiez: le conteneur est-il en cours d'exécution? incus ls"
    fi

    # Verify the custom page is served
    sleep 1
    run_cmd "Verify custom page content" "${TIMEOUT_CURL}" \
        curl -sL --max-time "${TIMEOUT_CURL}" "http://localhost:${PORT_NGINX_LISTEN}" || true

    if echo "${CMD_OUTPUT}" | grep -q "CR380"; then
        pass "Custom page is being served (contains 'CR380')"
    else
        fail "Custom page not served" \
             "page containing 'CR380'" \
             "${CMD_OUTPUT:0:200}" \
             "Vérifiez: incus exec ${CT_NGINX} -- cat /var/www/html/index.html"
    fi

    # -------------------------------------------------------------------------
    # Step 5: Pull directory recursively
    # FR: Télécharger un répertoire entier récursivement
    # -------------------------------------------------------------------------
    learn_pause \
        "Commande: incus file pull -r ${CT_NGINX}/var/www/html ${work_dir}/
Ceci télécharge le répertoire complet récursivement.
Nous le renommerons ensuite en 'html.bkp' comme sauvegarde." \
        "Command: incus file pull -r ${CT_NGINX}/var/www/html ${work_dir}/
This downloads the entire directory recursively.
We'll rename it to 'html.bkp' as a backup."

    rm -rf "${work_dir}/html" "${work_dir}/html.bkp"

    run_cmd "Pull html directory recursively" "${TIMEOUT_DEFAULT}" \
        incus_run incus file pull -r ${CT_NGINX}/var/www/html ${work_dir}/ || true

    if [[ -d "${work_dir}/html" ]]; then
        mv "${work_dir}/html" "${work_dir}/html.bkp"
        pass "Pulled and renamed html → html.bkp"
    else
        fail "Failed to pull html directory" \
             "directory html exists" \
             "directory not found" \
             "Essayez manuellement: incus file pull -r ${CT_NGINX}/var/www/html ."
    fi

    # -------------------------------------------------------------------------
    # Step 6: Clone demo app and push to container
    # FR: Cloner l'application de démo et envoyer dans le conteneur
    # -------------------------------------------------------------------------
    learn_pause \
        "Maintenant nous clonons le dépôt de l'application de démonstration
et nous l'envoyons dans le conteneur pour remplacer le site web par défaut.

Commande: git clone ${DEMO_APP_REPO} ${DEMO_APP_DIR}
          incus file push -r ${DEMO_APP_DIR} ${CT_NGINX}/var/www/" \
        "Now we clone the demo application repository and push it
to the container to replace the default website.

Command: git clone ${DEMO_APP_REPO} ${DEMO_APP_DIR}
         incus file push -r ${DEMO_APP_DIR} ${CT_NGINX}/var/www/"

    rm -rf "${work_dir}/${DEMO_APP_DIR}"

    run_cmd "Clone demo app repository" "${TIMEOUT_DOWNLOAD}" \
        git clone "${DEMO_APP_REPO}" "${work_dir}/${DEMO_APP_DIR}" || true

    if (( CMD_EXIT_CODE == 0 )) && [[ -d "${work_dir}/${DEMO_APP_DIR}" ]]; then
        pass "Demo app cloned to '${DEMO_APP_DIR}'"
    else
        fail "Failed to clone demo app" \
             "directory ${DEMO_APP_DIR} exists" \
             "exit code ${CMD_EXIT_CODE}" \
             "Vérifiez l'URL du dépôt dans config.env: DEMO_APP_REPO=${DEMO_APP_REPO}"
    fi

    run_cmd "Push demo app to container" "${TIMEOUT_EXEC}" \
        incus_run incus file push -r ${work_dir}/${DEMO_APP_DIR} ${CT_NGINX}/var/www/ || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Pushed '${DEMO_APP_DIR}' to '${CT_NGINX}:/var/www/'"
    else
        fail "Failed to push demo app directory" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}: ${CMD_OUTPUT:0:200}" \
             "Le répertoire ${DEMO_APP_DIR} existe-t-il? ls -la ${DEMO_APP_DIR}/"
    fi

    # -------------------------------------------------------------------------
    # Step 7: Rename inside container: ml-app → html
    # FR: Renommer dans le conteneur: ml-app → html
    # -------------------------------------------------------------------------
    learn_pause \
        "Nous renommons le répertoire dans le conteneur pour que nginx
serve l'application de démo:
  mv /var/www/html → /var/www/html.orig
  mv /var/www/${DEMO_APP_DIR} → /var/www/html" \
        "We rename the directory inside the container so nginx
serves the demo application:
  mv /var/www/html → /var/www/html.orig
  mv /var/www/${DEMO_APP_DIR} → /var/www/html"

    run_cmd "Rename original html in container" "${TIMEOUT_DEFAULT}" \
        incus_run incus exec ${CT_NGINX} -- mv /var/www/html /var/www/html.orig || true

    run_cmd "Rename demo app to html" "${TIMEOUT_DEFAULT}" \
        incus_run incus exec ${CT_NGINX} -- mv /var/www/${DEMO_APP_DIR} /var/www/html || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Demo app now serves as /var/www/html"
    else
        fail "Failed to rename demo app directory" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}" \
             "Vérifiez: incus exec ${CT_NGINX} -- ls /var/www/"
    fi

    # -------------------------------------------------------------------------
    # Step 8: Publish as demo-app image
    # FR: Publier comme image demo-app
    # -------------------------------------------------------------------------
    learn_pause \
        "Publions ce conteneur comme une nouvelle image d'application:
Commande: incus publish ${CT_NGINX} --alias ${IMG_DEMO_APP} --force

L'image '${IMG_DEMO_APP}' contient nginx + l'application de démo." \
        "Let's publish this container as a new application image:
Command: incus publish ${CT_NGINX} --alias ${IMG_DEMO_APP} --force

The '${IMG_DEMO_APP}' image contains nginx + the demo application."

    cleanup_image "${IMG_DEMO_APP}"

    run_cmd "Publish as '${IMG_DEMO_APP}'" "${TIMEOUT_EXEC}" \
        incus_run incus publish ${CT_NGINX} --alias ${IMG_DEMO_APP} --force || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Published '${CT_NGINX}' as image '${IMG_DEMO_APP}'"
    else
        fail "Failed to publish image '${IMG_DEMO_APP}'" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}: ${CMD_OUTPUT:0:200}" \
             "Le conteneur '${CT_NGINX}' existe-t-il? Vérifiez: incus ls"
    fi

    # Verify published image exists
    assert_resource_exists "image" "${IMG_DEMO_APP}" \
        "L'image '${IMG_DEMO_APP}' devrait être dans la liste des images locales."

    # Cleanup temp files
    rm -f "${work_dir}/index.html" "${work_dir}/index.nginx-debian.html"

    section_summary
}
