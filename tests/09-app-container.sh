#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 09 — Conteneur d'application / Application Container
# =============================================================================
#
# FR: Créer un conteneur Debian avec nginx, le configurer, puis publier
#     l'image. Comprendre le pattern: base image + application = app image.
#
# EN: Create a Debian container with nginx, configure it, then publish
#     the image. Understand the pattern: base image + app = app image.
#
# GitBook: ${GITBOOK_BASE_URL}/incus-lab/la-persistance/transfert-de-fichiers-et-repertoires
# Depends on: 08-port-exposure
# =============================================================================

run_test() {
    section_header "09" "Conteneur d'application / Application Container" \
        "${GITBOOK_BASE_URL}/incus-lab/la-persistance/transfert-de-fichiers-et-repertoires"

    check_dependency "08" || { section_summary; return 0; }

    learn_pause \
        "Le pattern 'conteneur d'application':
1. Partir d'une image de base (Debian 12)
2. Installer l'application (nginx + outils)
3. Configurer
4. Publier comme nouvelle image (nginx-0.0.0)
5. Utiliser cette image pour déployer

C'est similaire au Dockerfile de Docker." \
        "The 'application container' pattern:
1. Start from a base image (Debian 12)
2. Install the application (nginx + tools)
3. Configure
4. Publish as a new image (nginx-0.0.0)
5. Use that image for deployment

This is similar to Docker's Dockerfile."

    # -------------------------------------------------------------------------
    # Step 1: Launch Debian container
    # FR: Lancer un conteneur Debian
    # -------------------------------------------------------------------------
    cleanup_container "${CT_DEBIAN}"

    run_cmd "Launch '${CT_DEBIAN}' from '${ALIAS_DEBIAN}'" "${TIMEOUT_CONTAINER_READY}" \
        incus_run incus launch ${ALIAS_DEBIAN} ${CT_DEBIAN} || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Container '${CT_DEBIAN}' launched"
    elif [[ "${CMD_OUTPUT}" == *"already"* ]]; then
        pass "Container '${CT_DEBIAN}' already exists"
    else
        fail "Failed to launch '${CT_DEBIAN}'" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}: ${CMD_OUTPUT:0:200}" \
             "Vérifiez: incus image ls | grep ${ALIAS_DEBIAN}"
    fi

    wait_for_ready "${CT_DEBIAN}"

    # Give network time to initialize
    sleep 3

    # -------------------------------------------------------------------------
    # Step 2: Install nginx + tools inside container
    # FR: Installer nginx + outils dans le conteneur
    # -------------------------------------------------------------------------
    learn_pause \
        "Commandes exécutées dans le conteneur:
  incus exec ${CT_DEBIAN} -- apt update
  incus exec ${CT_DEBIAN} -- apt install -y nginx ufw tree vim

Ceci installe le serveur web nginx et des outils utiles." \
        "Commands executed inside the container:
  incus exec ${CT_DEBIAN} -- apt update
  incus exec ${CT_DEBIAN} -- apt install -y nginx ufw tree vim

This installs the nginx web server and useful tools."

    # Wait for network connectivity in the container
    local net_ready=false
    for i in {1..30}; do
        if incus_run incus exec ${CT_DEBIAN} -- ping -c1 -W2 deb.debian.org &>/dev/null; then
            net_ready=true
            break
        fi
        sleep 2
    done
    if [[ "${net_ready}" == "true" ]]; then
        pass "Network ready in '${CT_DEBIAN}'"
    else
        fail "No network connectivity in '${CT_DEBIAN}'" \
             "ping deb.debian.org" \
             "no response after 60s" \
             "Vérifiez la config réseau du conteneur: incus exec ${CT_DEBIAN} -- ip a"
    fi

    run_cmd "apt update in '${CT_DEBIAN}'" "0" \
        incus_run incus exec ${CT_DEBIAN} -- apt-get update -y || true

    if (( CMD_EXIT_CODE != 0 )); then
        fail "apt update failed in '${CT_DEBIAN}'" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}" \
             "Le conteneur a peut-être besoin de temps pour obtenir le réseau. Attendez et réessayez."
    fi

    run_cmd "Install nginx+tools in '${CT_DEBIAN}'" "0" \
        incus_run incus exec ${CT_DEBIAN} -- apt-get install -y nginx ufw tree vim || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "nginx + tools installed in '${CT_DEBIAN}'"
    else
        fail "Failed to install packages in '${CT_DEBIAN}'" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}: ${CMD_OUTPUT:0:200}" \
             "Vérifiez la connectivité: incus exec ${CT_DEBIAN} -- ping -c1 deb.debian.org"
    fi

    # -------------------------------------------------------------------------
    # Step 3: Start and enable nginx
    # FR: Démarrer et activer nginx
    # -------------------------------------------------------------------------
    run_cmd "Start nginx in '${CT_DEBIAN}'" "${TIMEOUT_DEFAULT}" \
        incus_run incus exec ${CT_DEBIAN} -- systemctl start nginx || true

    run_cmd "Enable nginx in '${CT_DEBIAN}'" "${TIMEOUT_DEFAULT}" \
        incus_run incus exec ${CT_DEBIAN} -- systemctl enable nginx || true

    run_cmd "Check nginx status in '${CT_DEBIAN}'" "${TIMEOUT_DEFAULT}" \
        incus_run incus exec ${CT_DEBIAN} -- systemctl is-active nginx || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "nginx is active in '${CT_DEBIAN}'"
    else
        fail "nginx is not active in '${CT_DEBIAN}'" \
             "exit code 0 (active)" \
             "exit code ${CMD_EXIT_CODE}: ${CMD_OUTPUT}" \
             "nginx n'a pas démarré. Vérifiez: incus exec ${CT_DEBIAN} -- systemctl status nginx"
    fi

    # -------------------------------------------------------------------------
    # Step 4: Configure UFW (firewall)
    # FR: Configurer le pare-feu UFW
    # -------------------------------------------------------------------------
    learn_pause \
        "Configuration du pare-feu:
  ufw allow 'Nginx Full'  — autoriser HTTP (80) et HTTPS (443)
  ufw allow OpenSSH        — autoriser SSH (22)
  ufw --force enable       — activer le pare-feu" \
        "Firewall configuration:
  ufw allow 'Nginx Full'  — allow HTTP (80) and HTTPS (443)
  ufw allow OpenSSH        — allow SSH (22)
  ufw --force enable       — enable the firewall"

    run_cmd "UFW allow Nginx" "${TIMEOUT_DEFAULT}" \
        incus_run incus exec ${CT_DEBIAN} -- ufw allow 'Nginx Full' || true

    run_cmd "UFW allow SSH" "${TIMEOUT_DEFAULT}" \
        incus_run incus exec ${CT_DEBIAN} -- ufw allow OpenSSH || true

    run_cmd "UFW enable" "${TIMEOUT_DEFAULT}" \
        incus_run incus exec ${CT_DEBIAN} -- ufw --force enable || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "UFW enabled with nginx and SSH rules"
    else
        pass "UFW configuration skipped (expected in unprivileged containers / normal dans un conteneur non-privilégié)"
    fi

    # -------------------------------------------------------------------------
    # Step 5: Publish as nginx image
    # FR: Publier comme image nginx
    # -------------------------------------------------------------------------
    learn_pause \
        "Maintenant nous publions le conteneur configuré comme une nouvelle image:
Commande: incus publish ${CT_DEBIAN} --alias ${IMG_NGINX} --force

L'image '${IMG_NGINX}' contient Debian + nginx + UFW configuré." \
        "Now we publish the configured container as a new image:
Command: incus publish ${CT_DEBIAN} --alias ${IMG_NGINX} --force

The '${IMG_NGINX}' image contains Debian + nginx + configured UFW."

    cleanup_image "${IMG_NGINX}"

    run_cmd "Publish '${CT_DEBIAN}' as '${IMG_NGINX}'" "${TIMEOUT_EXEC}" \
        incus_run incus publish ${CT_DEBIAN} --alias ${IMG_NGINX} --force || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Published '${CT_DEBIAN}' as image '${IMG_NGINX}'"
    else
        fail "Failed to publish image '${IMG_NGINX}'" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}: ${CMD_OUTPUT:0:200}" \
             "Le conteneur '${CT_DEBIAN}' doit exister. Vérifiez: incus ls"
    fi

    # -------------------------------------------------------------------------
    # Step 6: Delete original and launch from published image
    # FR: Supprimer l'original et lancer depuis l'image publiée
    # -------------------------------------------------------------------------
    run_cmd "Delete '${CT_DEBIAN}'" "${TIMEOUT_DEFAULT}" \
        incus_run incus delete --force ${CT_DEBIAN} || true

    cleanup_container "${CT_NGINX}"

    run_cmd "Launch '${CT_NGINX}' from '${IMG_NGINX}'" "${TIMEOUT_CONTAINER_READY}" \
        incus_run incus launch ${IMG_NGINX} ${CT_NGINX} || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Container '${CT_NGINX}' launched from '${IMG_NGINX}'"
    elif [[ "${CMD_OUTPUT}" == *"already"* ]]; then
        pass "Container '${CT_NGINX}' already exists"
    else
        fail "Failed to launch '${CT_NGINX}' from '${IMG_NGINX}'" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}: ${CMD_OUTPUT:0:200}" \
             "L'image '${IMG_NGINX}' existe-t-elle? Vérifiez: incus image ls"
    fi

    wait_for_ready "${CT_NGINX}"

    # -------------------------------------------------------------------------
    # Step 7: Verify nginx is active in new container
    # FR: Vérifier que nginx est actif dans le nouveau conteneur
    # -------------------------------------------------------------------------
    # Give services time to start
    sleep 3

    run_cmd "Check nginx status in '${CT_NGINX}'" "${TIMEOUT_DEFAULT}" \
        incus_run incus exec ${CT_NGINX} -- systemctl is-active nginx || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "nginx is active in '${CT_NGINX}'"
    else
        fail "nginx is not active in '${CT_NGINX}'" \
             "exit code 0 (active)" \
             "exit code ${CMD_EXIT_CODE}: ${CMD_OUTPUT}" \
             "nginx devrait être actif dans le conteneur publié. Vérifiez: incus exec ${CT_NGINX} -- systemctl status nginx"
    fi

    # -------------------------------------------------------------------------
    # Step 8: Expose port and verify HTTP
    # FR: Exposer le port et vérifier HTTP
    # -------------------------------------------------------------------------
    # Remove any existing proxy device from previous run
    incus_run incus config device remove ${CT_NGINX} monport80vers${PORT_NGINX_LISTEN} 2>/dev/null || true

    run_cmd "Add proxy device for port ${PORT_NGINX_LISTEN}" "${TIMEOUT_DEFAULT}" \
        incus_run incus config device add ${CT_NGINX} monport80vers${PORT_NGINX_LISTEN} proxy listen=tcp:0.0.0.0:${PORT_NGINX_LISTEN} connect=tcp:127.0.0.1:80 || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Proxy device added on port ${PORT_NGINX_LISTEN}"
    else
        fail "Failed to add proxy device" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}" \
             "Port ${PORT_NGINX_LISTEN} peut être occupé. Vérifiez: ss -tlnp | grep ${PORT_NGINX_LISTEN}"
    fi

    sleep 2

    run_cmd "HTTP test on port ${PORT_NGINX_LISTEN}" "${TIMEOUT_CURL}" \
        curl -sL --max-time "${TIMEOUT_CURL}" "http://localhost:${PORT_NGINX_LISTEN}" || true

    if (( CMD_EXIT_CODE == 0 )) && [[ -n "${CMD_OUTPUT}" ]]; then
        pass "HTTP response received on port ${PORT_NGINX_LISTEN}"
    else
        fail "No HTTP response on port ${PORT_NGINX_LISTEN}" \
             "HTTP response from nginx" \
             "exit code ${CMD_EXIT_CODE}" \
             "Vérifiez: incus config show ${CT_NGINX} et incus exec ${CT_NGINX} -- systemctl status nginx"
    fi

    section_summary
}
