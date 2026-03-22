#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 08 — Exposer/Fermer un port / Port Exposure
# =============================================================================
#
# FR: Créer un conteneur OpenWRT et exposer son port 80 via un proxy device.
#     Comprendre la différence entre nat et proxy.
#
# EN: Create an OpenWRT container and expose its port 80 via a proxy device.
#     Understand the difference between nat and proxy.
#
# GitBook: ${GITBOOK_BASE_URL}/incus-lab/les-flux-incus/conteneur
# Depends on: 07-containers
# =============================================================================

run_test() {
    section_header "08" "Exposer/Fermer un port / Port Exposure" \
        "${GITBOOK_BASE_URL}/incus-lab/les-flux-incus/conteneur"

    check_dependency "07" || { section_summary; return 0; }

    learn_pause \
        "Incus utilise des 'proxy devices' pour exposer les ports d'un conteneur
sur l'hôte. C'est différent du port forwarding classique (iptables).

Un proxy device crée une connexion entre un port de l'hôte et un port
du conteneur, gérée par le démon Incus." \
        "Incus uses 'proxy devices' to expose container ports on the host.
This is different from classic port forwarding (iptables).

A proxy device creates a connection between a host port and a
container port, managed by the Incus daemon."

    # -------------------------------------------------------------------------
    # Step 1: Launch OpenWRT container
    # FR: Lancer un conteneur OpenWRT
    # -------------------------------------------------------------------------
    # STUDENT NOTE: OpenWRT est un système d'exploitation pour routeurs.
    # Son interface web écoute sur le port 80.
    # OpenWRT is a router operating system.
    # Its web interface listens on port 80.

    cleanup_container "${CT_ROUTER}"

    learn_pause \
        "Commande: incus launch ${ALIAS_OPENWRT} ${CT_ROUTER}
OpenWRT est un OS de routeur avec une interface web sur le port 80." \
        "Command: incus launch ${ALIAS_OPENWRT} ${CT_ROUTER}
OpenWRT is a router OS with a web interface on port 80."

    run_cmd "Launch '${CT_ROUTER}' from '${ALIAS_OPENWRT}'" "${TIMEOUT_CONTAINER_READY}" \
        incus_run incus launch ${ALIAS_OPENWRT} ${CT_ROUTER} || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Container '${CT_ROUTER}' launched"
    elif [[ "${CMD_OUTPUT}" == *"already"* ]]; then
        pass "Container '${CT_ROUTER}' already exists"
    else
        fail "Failed to launch '${CT_ROUTER}'" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}: ${CMD_OUTPUT:0:200}" \
             "Vérifiez que l'image '${ALIAS_OPENWRT}' existe: incus image ls"
    fi

    wait_for_ready "${CT_ROUTER}"

    # Give OpenWRT time to start its web server (procd can take 10+ seconds)
    sleep 10

    # -------------------------------------------------------------------------
    # Step 2: Add proxy device to expose port 80 → 8888
    # FR: Ajouter un proxy device pour exposer le port 80 → 8888
    # -------------------------------------------------------------------------
    learn_pause \
        "Commande: incus config device add ${CT_ROUTER} monport80vers${PORT_OPENWRT_LISTEN} proxy \\
  listen=tcp:0.0.0.0:${PORT_OPENWRT_LISTEN} connect=tcp:127.0.0.1:80

Ceci fait écouter l'hôte sur le port ${PORT_OPENWRT_LISTEN} et redirige
vers le port 80 du conteneur." \
        "Command: incus config device add ${CT_ROUTER} monport80vers${PORT_OPENWRT_LISTEN} proxy \\
  listen=tcp:0.0.0.0:${PORT_OPENWRT_LISTEN} connect=tcp:127.0.0.1:80

This makes the host listen on port ${PORT_OPENWRT_LISTEN} and redirect
to port 80 in the container."

    # Remove any existing proxy device from previous run
    incus_run incus config device remove ${CT_ROUTER} monport80vers${PORT_OPENWRT_LISTEN} 2>/dev/null || true

    run_cmd "Add proxy device" "${TIMEOUT_DEFAULT}" \
        incus_run incus config device add ${CT_ROUTER} monport80vers${PORT_OPENWRT_LISTEN} proxy listen=tcp:0.0.0.0:${PORT_OPENWRT_LISTEN} connect=tcp:127.0.0.1:80 || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Proxy device 'monport80vers${PORT_OPENWRT_LISTEN}' added"
    else
        fail "Failed to add proxy device" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}: ${CMD_OUTPUT:0:200}" \
             "Le port ${PORT_OPENWRT_LISTEN} est peut-être déjà utilisé. Vérifiez: ss -tlnp | grep ${PORT_OPENWRT_LISTEN}"
    fi

    # -------------------------------------------------------------------------
    # Step 3: Verify proxy device in config
    # FR: Vérifier le proxy device dans la configuration
    # -------------------------------------------------------------------------
    assert_output_contains \
        "Proxy device visible in container config" \
        "monport80vers${PORT_OPENWRT_LISTEN}" \
        "Le device devrait apparaître dans 'incus config show ${CT_ROUTER}'." \
        incus_run incus config show ${CT_ROUTER}

    # -------------------------------------------------------------------------
    # Step 4: Test HTTP access via proxy
    # FR: Tester l'accès HTTP via le proxy
    # -------------------------------------------------------------------------
    learn_pause \
        "Testons l'accès HTTP:
Commande: curl -sL --max-time ${TIMEOUT_CURL} http://localhost:${PORT_OPENWRT_LISTEN}

Vous devriez voir la page web d'OpenWRT (LuCI)." \
        "Let's test HTTP access:
Command: curl -sL --max-time ${TIMEOUT_CURL} http://localhost:${PORT_OPENWRT_LISTEN}

You should see the OpenWRT web page (LuCI)."

    # Give a moment for the proxy to be ready
    sleep 2

    run_cmd "HTTP test via proxy" "${TIMEOUT_CURL}" \
        curl -sL --max-time "${TIMEOUT_CURL}" "http://localhost:${PORT_OPENWRT_LISTEN}" || true

    if (( CMD_EXIT_CODE == 0 )) && [[ -n "${CMD_OUTPUT}" ]]; then
        pass "HTTP response received on port ${PORT_OPENWRT_LISTEN}"
    else
        fail "No HTTP response on port ${PORT_OPENWRT_LISTEN}" \
             "HTTP response from OpenWRT" \
             "exit code ${CMD_EXIT_CODE}" \
             "OpenWRT peut prendre quelques secondes à démarrer. Attendez et réessayez: curl http://localhost:${PORT_OPENWRT_LISTEN}"
    fi

    # -------------------------------------------------------------------------
    # Step 5: Remove proxy device
    # FR: Retirer le proxy device
    # -------------------------------------------------------------------------
    learn_pause \
        "Commande: incus config device remove ${CT_ROUTER} monport80vers${PORT_OPENWRT_LISTEN}
Ceci ferme le port sur l'hôte." \
        "Command: incus config device remove ${CT_ROUTER} monport80vers${PORT_OPENWRT_LISTEN}
This closes the port on the host."

    run_cmd "Remove proxy device" "${TIMEOUT_DEFAULT}" \
        incus_run incus config device remove ${CT_ROUTER} monport80vers${PORT_OPENWRT_LISTEN} || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Proxy device removed / Device proxy retiré"
    else
        fail "Failed to remove proxy device" \
             "exit code 0" \
             "exit code ${CMD_EXIT_CODE}" \
             "Vérifiez le nom du device: incus config show ${CT_ROUTER}"
    fi

    # -------------------------------------------------------------------------
    # Step 6: Verify device removed from config
    # FR: Vérifier que le device a été retiré de la configuration
    # -------------------------------------------------------------------------
    assert_output_not_contains \
        "Proxy device no longer in config" \
        "monport80vers${PORT_OPENWRT_LISTEN}" \
        "Le device devrait avoir été supprimé." \
        incus_run incus config show ${CT_ROUTER}

    section_summary
}
