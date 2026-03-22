#!/usr/bin/env bash
# =============================================================================
# CR380 - Incus Lab Test Suite — Framework commun / Common framework
# =============================================================================
#
# FR: Ce fichier contient toutes les fonctions utilitaires partagées entre les
#     scripts de test. Il gère l'affichage coloré, les assertions, les délais
#     d'attente, le mode apprentissage, les dépendances entre tests, et la
#     génération de rapports JSON.
#
# EN: This file contains all shared utility functions used by the test scripts.
#     It handles colored output, assertions, timeouts, learn mode, test
#     dependencies, and JSON report generation.
#
# STUDENT NOTE / NOTE ÉTUDIANT:
#   Ce fichier est le "moteur" de la suite de tests. Lisez-le pour comprendre
#   comment les assertions fonctionnent. / This file is the test suite "engine".
#   Read it to understand how assertions work.
#
# =============================================================================

# Prevent double-sourcing / Empêcher le double chargement
[[ -n "${_COMMON_SH_LOADED:-}" ]] && return 0
_COMMON_SH_LOADED=1

# =============================================================================
# GLOBAL VARIABLES / VARIABLES GLOBALES
# =============================================================================

# Resolve project root regardless of where we're called from
# FR: Trouver le répertoire racine du projet
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source configuration / Charger la configuration
# shellcheck source=../config.env
source "${PROJECT_ROOT}/config.env"

# =============================================================================
# INCUS COMMAND WRAPPER / WRAPPER DE COMMANDE INCUS
# =============================================================================
# FR: Crée un script exécutable pour lancer des commandes incus.
#     Si on est root (EUID=0), exécute directement (root accède au socket).
#     Sinon, utilise 'sg incus-admin' pour l'accès au groupe.
# EN: Creates an executable wrapper to run incus commands.
#     If we are root (EUID=0), runs directly (root has socket access).
#     Otherwise, uses 'sg incus-admin' for group access.
INCUS_RUN="/tmp/.incus_run_cr380"
if (( EUID == 0 )); then
    printf '#!/bin/bash\nexec "$@"\n' > "${INCUS_RUN}"
else
    printf '#!/bin/bash\nexec sg incus-admin -c "$*"\n' > "${INCUS_RUN}"
fi
chmod +x "${INCUS_RUN}"
# Function alias for convenience (works in subshells from $())
incus_run() { "${INCUS_RUN}" "$@"; }

# Mode: validate (default) or learn
# FR: Mode d'exécution: validate (défaut, rapide) ou learn (interactif)
MODE="${MODE:-validate}"

# Verbosity: 0=quiet, 1=normal, 2=verbose
VERBOSE="${VERBOSE:-1}"

# Counters / Compteurs
TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_SKIP=0
SECTION_PASS=0
SECTION_FAIL=0
SECTION_SKIP=0
CURRENT_SECTION=""
CURRENT_SECTION_NUM=""
SECTION_START_TIME=""

# Dependency tracking / Suivi des dépendances
# FR: Tableau associatif qui enregistre le résultat de chaque test
declare -A TEST_RESULTS

# Log and report paths / Chemins des logs et rapports
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
LOG_DIR="${PROJECT_ROOT}/logs"
RESULTS_DIR="${PROJECT_ROOT}/results"
LOG_FILE="${LOG_DIR}/test-${TIMESTAMP}.log"
REPORT_FILE="${RESULTS_DIR}/report-${TIMESTAMP}.json"

# Ensure directories exist / S'assurer que les répertoires existent
mkdir -p "${LOG_DIR}" "${RESULTS_DIR}"

# Initialize report / Initialiser le rapport
echo '{"timestamp":"'"${TIMESTAMP}"'","tests":[' > "${REPORT_FILE}"
_REPORT_FIRST_ENTRY=true

# =============================================================================
# COLORS / COULEURS
# =============================================================================
# FR: Codes de couleur ANSI pour l'affichage dans le terminal
# EN: ANSI color codes for terminal display

if [[ -t 1 ]]; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    DIM='\033[2m'
    NC='\033[0m'  # No Color / Sans couleur
else
    GREEN='' RED='' YELLOW='' BLUE='' CYAN='' BOLD='' DIM='' NC=''
fi

# =============================================================================
# LOGGING / JOURNALISATION
# =============================================================================

# FR: Écrire un message dans le fichier log et optionnellement à l'écran
# EN: Write a message to the log file and optionally to screen
log() {
    local msg="[$(date '+%H:%M:%S')] $*"
    echo "${msg}" >> "${LOG_FILE}"
}

log_and_print() {
    local msg="$*"
    log "${msg}"
    echo -e "${msg}"
}

# =============================================================================
# JSON REPORT / RAPPORT JSON
# =============================================================================

# FR: Ajouter un résultat de test au rapport JSON
# EN: Append a test result to the JSON report
write_json_result() {
    local test_name="$1"
    local status="$2"       # pass, fail, skip
    local duration="$3"     # seconds
    local error="${4:-}"    # error message if any

    # Escape special JSON characters
    error="${error//\\/\\\\}"
    error="${error//\"/\\\"}"
    error="${error//$'\n'/\\n}"

    if [[ "${_REPORT_FIRST_ENTRY}" == "true" ]]; then
        _REPORT_FIRST_ENTRY=false
    else
        echo ',' >> "${REPORT_FILE}"
    fi

    cat >> "${REPORT_FILE}" <<EOF
{"test":"${test_name}","status":"${status}","duration_s":${duration},"error":"${error}"}
EOF
}

# FR: Finaliser le rapport JSON (fermer le tableau et l'objet)
# EN: Finalize the JSON report (close the array and object)
finalize_report() {
    echo '],"summary":{"pass":'"${TOTAL_PASS}"',"fail":'"${TOTAL_FAIL}"',"skip":'"${TOTAL_SKIP}"'}}' >> "${REPORT_FILE}"

    # Cleanup old reports — keep last 10
    # FR: Nettoyer les anciens rapports — garder les 10 derniers
    local count
    count=$(find "${RESULTS_DIR}" -name 'report-*.json' | wc -l)
    if (( count > 10 )); then
        find "${RESULTS_DIR}" -name 'report-*.json' -printf '%T@ %p\n' \
            | sort -n | head -n $(( count - 10 )) | awk '{print $2}' \
            | xargs rm -f
    fi
    count=$(find "${LOG_DIR}" -name 'test-*.log' | wc -l)
    if (( count > 10 )); then
        find "${LOG_DIR}" -name 'test-*.log' -printf '%T@ %p\n' \
            | sort -n | head -n $(( count - 10 )) | awk '{print $2}' \
            | xargs rm -f
    fi
}

# =============================================================================
# SECTION MANAGEMENT / GESTION DES SECTIONS
# =============================================================================

# FR: Afficher l'en-tête d'une section de test et démarrer le chronomètre
# EN: Display the header of a test section and start the timer
#
# Usage: section_header "06" "Images" "${GITBOOK_BASE_URL}/incus-lab/les-flux-incus/image"
section_header() {
    local num="$1"
    local title="$2"
    local gitbook_url="${3:-}"

    CURRENT_SECTION_NUM="${num}"
    CURRENT_SECTION="${title}"
    SECTION_PASS=0
    SECTION_FAIL=0
    SECTION_SKIP=0
    SECTION_START_TIME=$(date +%s)

    log "===== START: [${num}] ${title} ====="
    echo ""
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${BLUE}  LAB ${num} — ${title}${NC}"
    if [[ -n "${gitbook_url}" ]]; then
        echo -e "${DIM}  📖 ${gitbook_url}${NC}"
    fi
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# FR: Afficher le résumé d'une section et enregistrer le résultat
# EN: Display the section summary and record the result
section_summary() {
    local end_time
    end_time=$(date +%s)
    local duration=$(( end_time - SECTION_START_TIME ))
    local status="pass"
    local error=""

    if (( SECTION_FAIL > 0 )); then
        status="fail"
        error="${SECTION_FAIL} assertion(s) failed"
        TEST_RESULTS["${CURRENT_SECTION_NUM}"]="fail"
    elif (( SECTION_SKIP > 0 && SECTION_PASS == 0 )); then
        status="skip"
        TEST_RESULTS["${CURRENT_SECTION_NUM}"]="skip"
    else
        TEST_RESULTS["${CURRENT_SECTION_NUM}"]="pass"
    fi

    echo ""
    echo -e "${DIM}  ──────────────────────────────────────────────────────────${NC}"
    if [[ "${status}" == "pass" ]]; then
        echo -e "  ${GREEN}${BOLD}✓ LAB ${CURRENT_SECTION_NUM} PASSED${NC} ${DIM}(${SECTION_PASS} checks, ${duration}s)${NC}"
    elif [[ "${status}" == "skip" ]]; then
        echo -e "  ${YELLOW}${BOLD}⊘ LAB ${CURRENT_SECTION_NUM} SKIPPED${NC} ${DIM}(${duration}s)${NC}"
    else
        echo -e "  ${RED}${BOLD}✗ LAB ${CURRENT_SECTION_NUM} FAILED${NC} ${DIM}(${SECTION_PASS} passed, ${SECTION_FAIL} failed, ${duration}s)${NC}"
    fi

    write_json_result "${CURRENT_SECTION_NUM}-${CURRENT_SECTION}" "${status}" "${duration}" "${error}"
    log "===== END: [${CURRENT_SECTION_NUM}] ${CURRENT_SECTION} => ${status} (${duration}s) ====="
}

# =============================================================================
# ASSERTIONS / VÉRIFICATIONS
# =============================================================================

# FR: Marquer un test comme réussi / EN: Mark a test as passed
pass() {
    local msg="$1"
    (( TOTAL_PASS++ )) || true
    (( SECTION_PASS++ )) || true
    log "PASS: ${msg}"
    echo -e "  ${GREEN}✓${NC} ${msg}"
}

# FR: Marquer un test comme échoué avec détails et indice
# EN: Mark a test as failed with details and hint
#
# Usage: fail "description" "expected_value" "actual_value" "hint for student"
fail() {
    local msg="$1"
    local expected="${2:-}"
    local actual="${3:-}"
    local hint="${4:-}"

    (( TOTAL_FAIL++ )) || true
    (( SECTION_FAIL++ )) || true

    log "FAIL: ${msg} | expected=[${expected}] actual=[${actual}] hint=[${hint}]"
    echo -e "  ${RED}✗${NC} ${msg}"
    if [[ -n "${expected}" ]]; then
        echo -e "    ${DIM}Attendu / Expected : ${NC}${expected}"
    fi
    if [[ -n "${actual}" ]]; then
        echo -e "    ${DIM}Obtenu  / Actual   : ${NC}${actual}"
    fi
    if [[ -n "${hint}" ]]; then
        echo -e "    ${YELLOW}💡 HINT: ${hint}${NC}"
    fi
}

# FR: Marquer un test comme ignoré / EN: Mark a test as skipped
skip() {
    local msg="$1"
    local reason="${2:-}"

    (( TOTAL_SKIP++ )) || true
    (( SECTION_SKIP++ )) || true
    log "SKIP: ${msg} | reason=[${reason}]"
    echo -e "  ${YELLOW}⊘${NC} ${msg}"
    if [[ -n "${reason}" ]]; then
        echo -e "    ${DIM}Raison / Reason: ${reason}${NC}"
    fi
}

# -----------------------------------------------------------------------------
# run_cmd — Execute a command with timeout, logging, and spinner
# FR: Exécuter une commande avec délai d'attente, journalisation et indicateur
#
# Usage: run_cmd "description" timeout_seconds command [args...]
# Returns: exit code of the command
# Sets: CMD_OUTPUT (captured stdout+stderr), CMD_EXIT_CODE
# -----------------------------------------------------------------------------
run_cmd() {
    local description="$1"
    local cmd_timeout="$2"
    shift 2
    local cmd=("$@")

    log "RUN (timeout=${cmd_timeout}s): ${cmd[*]}"

    if [[ "${MODE}" == "learn" ]] || (( VERBOSE >= 2 )); then
        echo -e "  ${DIM}▸ ${cmd[*]}${NC}"
    fi

    CMD_OUTPUT=""
    CMD_EXIT_CODE=0

    # Resolve incus_run function to the executable wrapper for timeout compatibility
    if [[ "${cmd[0]}" == "incus_run" ]]; then
        cmd[0]="${INCUS_RUN}"
    fi

    # Run with timeout and capture output
    # FR: Exécuter avec délai d'attente et capturer la sortie
    if (( cmd_timeout > 0 )); then
        CMD_OUTPUT=$(timeout "${cmd_timeout}" "${cmd[@]}" 2>&1) || CMD_EXIT_CODE=$?
    else
        CMD_OUTPUT=$("${cmd[@]}" 2>&1) || CMD_EXIT_CODE=$?
    fi

    # Check for timeout (exit code 124)
    # FR: Vérifier si la commande a expiré (code 124)
    if (( CMD_EXIT_CODE == 124 )); then
        log "TIMEOUT after ${cmd_timeout}s: ${cmd[*]}"
        CMD_OUTPUT="TIMEOUT after ${cmd_timeout} seconds"
    fi

    # Log output (truncated if too long)
    if (( ${#CMD_OUTPUT} > 2000 )); then
        log "OUTPUT (truncated): ${CMD_OUTPUT:0:2000}..."
    else
        log "OUTPUT: ${CMD_OUTPUT}"
    fi
    log "EXIT_CODE: ${CMD_EXIT_CODE}"

    return ${CMD_EXIT_CODE}
}

# -----------------------------------------------------------------------------
# assert_exit_code — Run command and check its exit code
# FR: Exécuter une commande et vérifier son code de retour
#
# Usage: assert_exit_code "description" expected_code hint command [args...]
# -----------------------------------------------------------------------------
assert_exit_code() {
    local description="$1"
    local expected_code="$2"
    local hint="$3"
    shift 3

    run_cmd "${description}" "${TIMEOUT_DEFAULT}" "$@" || true

    if (( CMD_EXIT_CODE == expected_code )); then
        pass "${description}"
    else
        fail "${description}" "exit code ${expected_code}" "exit code ${CMD_EXIT_CODE}" "${hint}"
    fi
}

# -----------------------------------------------------------------------------
# assert_success — Run command and check it exits 0
# FR: Exécuter une commande et vérifier qu'elle réussit (code 0)
#
# Usage: assert_success "description" hint command [args...]
# -----------------------------------------------------------------------------
assert_success() {
    local description="$1"
    local hint="$2"
    shift 2

    run_cmd "${description}" "${TIMEOUT_DEFAULT}" "$@" || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "${description}"
    else
        fail "${description}" "exit code 0 (success)" "exit code ${CMD_EXIT_CODE}" "${hint}"
    fi
}

# -----------------------------------------------------------------------------
# assert_failure — Run command and check it exits non-zero
# FR: Exécuter une commande et vérifier qu'elle échoue (code ≠ 0)
#
# Usage: assert_failure "description" hint command [args...]
# -----------------------------------------------------------------------------
assert_failure() {
    local description="$1"
    local hint="$2"
    shift 2

    run_cmd "${description}" "${TIMEOUT_DEFAULT}" "$@" || true

    if (( CMD_EXIT_CODE != 0 )); then
        pass "${description}"
    else
        fail "${description}" "non-zero exit code (failure)" "exit code 0 (success)" "${hint}"
    fi
}

# -----------------------------------------------------------------------------
# assert_output_contains — Run command and check output contains substring
# FR: Exécuter une commande et vérifier que la sortie contient une sous-chaîne
#
# Usage: assert_output_contains "description" "substring" hint command [args...]
# -----------------------------------------------------------------------------
assert_output_contains() {
    local description="$1"
    local substring="$2"
    local hint="$3"
    shift 3

    run_cmd "${description}" "${TIMEOUT_DEFAULT}" "$@" || true

    if echo "${CMD_OUTPUT}" | grep -qi "${substring}"; then
        pass "${description}"
    else
        local actual_short="${CMD_OUTPUT}"
        if (( ${#actual_short} > 200 )); then
            actual_short="${actual_short:0:200}..."
        fi
        fail "${description}" "output containing '${substring}'" "${actual_short}" "${hint}"
    fi
}

# -----------------------------------------------------------------------------
# assert_output_not_contains — Run command and check output does NOT contain substring
# FR: Exécuter et vérifier que la sortie ne contient PAS une sous-chaîne
#
# Usage: assert_output_not_contains "description" "substring" hint command [args...]
# -----------------------------------------------------------------------------
assert_output_not_contains() {
    local description="$1"
    local substring="$2"
    local hint="$3"
    shift 3

    run_cmd "${description}" "${TIMEOUT_DEFAULT}" "$@" || true

    if echo "${CMD_OUTPUT}" | grep -qi "${substring}"; then
        local actual_short="${CMD_OUTPUT}"
        if (( ${#actual_short} > 200 )); then
            actual_short="${actual_short:0:200}..."
        fi
        fail "${description}" "output NOT containing '${substring}'" "${actual_short}" "${hint}"
    else
        pass "${description}"
    fi
}

# -----------------------------------------------------------------------------
# assert_output_not_empty — Run command and check output is not empty
# FR: Exécuter une commande et vérifier que la sortie n'est pas vide
#
# Usage: assert_output_not_empty "description" hint command [args...]
# -----------------------------------------------------------------------------
assert_output_not_empty() {
    local description="$1"
    local hint="$2"
    shift 2

    run_cmd "${description}" "${TIMEOUT_DEFAULT}" "$@" || true

    if [[ -n "${CMD_OUTPUT}" ]]; then
        pass "${description}"
    else
        fail "${description}" "non-empty output" "(empty)" "${hint}"
    fi
}

# =============================================================================
# INCUS-SPECIFIC ASSERTIONS / ASSERTIONS SPÉCIFIQUES À INCUS
# =============================================================================

# FR: Vérifier qu'une ressource incus existe (conteneur, image, pool, etc.)
# EN: Check that an incus resource exists (container, image, pool, etc.)
#
# Usage: assert_resource_exists "container" "u1" "hint"
assert_resource_exists() {
    local resource_type="$1"    # container, image, storage, network
    local name="$2"
    local hint="${3:-}"

    local cmd
    case "${resource_type}" in
        container) cmd="incus list" ;;
        image)     cmd="incus image list" ;;
        storage)   cmd="incus storage list" ;;
        network)   cmd="incus network list" ;;
        volume)    cmd="incus storage volume list ${4:-default}" ;;
        *)         fail "Unknown resource type: ${resource_type}" "" "" ""; return 1 ;;
    esac

    assert_output_contains \
        "${resource_type} '${name}' exists / existe" \
        "${name}" \
        "${hint}" \
        bash -c "${cmd}"
}

# FR: Vérifier qu'une ressource incus n'existe PAS
# EN: Check that an incus resource does NOT exist
assert_resource_not_exists() {
    local resource_type="$1"
    local name="$2"
    local hint="${3:-}"

    local cmd
    case "${resource_type}" in
        container) cmd="incus list" ;;
        image)     cmd="incus image list" ;;
        storage)   cmd="incus storage list" ;;
        network)   cmd="incus network list" ;;
        volume)    cmd="incus storage volume list ${4:-default}" ;;
        *)         fail "Unknown resource type: ${resource_type}" "" "" ""; return 1 ;;
    esac

    assert_output_not_contains \
        "${resource_type} '${name}' does not exist / n'existe pas" \
        "${name}" \
        "${hint}" \
        bash -c "${cmd}"
}

# FR: Attendre qu'un conteneur soit dans l'état RUNNING
# EN: Wait until a container reaches the RUNNING state
#
# Usage: wait_for_ready "container_name" [timeout_seconds]
wait_for_ready() {
    local ct_name="$1"
    local wfr_timeout="${2:-${TIMEOUT_CONTAINER_READY}}"
    local elapsed=0
    local interval=2

    log "Waiting for container '${ct_name}' to be RUNNING (timeout=${wfr_timeout}s)"
    if [[ "${MODE}" == "learn" ]]; then
        echo -e "  ${DIM}⏳ Attente du conteneur '${ct_name}'... / Waiting for '${ct_name}'...${NC}"
    fi

    while (( elapsed < wfr_timeout )); do
        local status
        status=$(incus list "${ct_name}" --format csv -c s 2>/dev/null || echo "")
        if [[ "${status}" == "RUNNING" ]]; then
            pass "Container '${ct_name}' is RUNNING / est en cours d'exécution"
            return 0
        fi
        sleep "${interval}"
        (( elapsed += interval )) || true
    done

    fail "Container '${ct_name}' did not reach RUNNING state" \
         "RUNNING" \
         "$(incus list "${ct_name}" --format csv -c s 2>/dev/null || echo 'not found')" \
         "Check: incus list ${ct_name}. Le conteneur peut avoir échoué au démarrage."
    return 1
}

# =============================================================================
# CLEANUP HELPERS / FONCTIONS DE NETTOYAGE
# =============================================================================

# FR: Supprimer un conteneur de manière sûre (ignorer si absent)
# EN: Safely delete a container (ignore if not present)
cleanup_container() {
    local name="$1"
    command -v incus &>/dev/null || return 0
    if incus list --format csv -c n 2>/dev/null | grep -qx "${name}"; then
        incus stop --force "${name}" 2>/dev/null || true
        incus delete --force "${name}" 2>/dev/null || true
        log "CLEANUP: deleted container ${name}"
    fi
}

# FR: Supprimer une image par alias de manière sûre
# EN: Safely delete an image by alias
cleanup_image() {
    local alias="$1"
    command -v incus &>/dev/null || return 0
    if incus image list --format csv 2>/dev/null | grep -q "${alias}"; then
        incus image delete "${alias}" 2>/dev/null || true
        log "CLEANUP: deleted image ${alias}"
    fi
}

# FR: Supprimer un pool de stockage de manière sûre
# EN: Safely delete a storage pool
cleanup_storage() {
    local pool="$1"
    command -v incus &>/dev/null || return 0
    if incus storage list --format csv 2>/dev/null | grep -q "${pool}"; then
        # First delete all volumes in the pool
        local volumes
        volumes=$(incus storage volume list "${pool}" --format csv 2>/dev/null | grep '^custom,' | cut -d',' -f2 || true)
        for vol in ${volumes}; do
            incus storage volume delete "${pool}" "${vol}" 2>/dev/null || true
            log "CLEANUP: deleted volume ${vol} from pool ${pool}"
        done
        incus storage delete "${pool}" 2>/dev/null || true
        log "CLEANUP: deleted storage pool ${pool}"
    fi
}

# FR: Supprimer un volume de manière sûre
# EN: Safely delete a volume
cleanup_volume() {
    local pool="$1"
    local vol="$2"
    command -v incus &>/dev/null || return 0
    incus storage volume delete "${pool}" "${vol}" 2>/dev/null || true
    log "CLEANUP: deleted volume ${vol} from pool ${pool}"
}

# =============================================================================
# DEPENDENCY MANAGEMENT / GESTION DES DÉPENDANCES
# =============================================================================

# FR: Vérifier si les dépendances d'un test ont réussi
# EN: Check if a test's dependencies have passed
#
# Usage: check_dependency "05" || return 0
# Returns 0 if all dependencies passed, 1 if any failed/skipped
check_dependency() {
    local dep_num="$1"
    local dep_result="${TEST_RESULTS[${dep_num}]:-}"

    if [[ "${dep_result}" == "fail" ]] || [[ "${dep_result}" == "skip" ]]; then
        echo -e "  ${YELLOW}⊘ SKIPPED — Lab ${dep_num} did not pass (${dep_result})${NC}"
        echo -e "  ${DIM}  Dépendance non satisfaite. Exécuter d'abord le lab ${dep_num}.${NC}"
        echo -e "  ${DIM}  Dependency not met. Run lab ${dep_num} first.${NC}"
        SECTION_SKIP=1
        TEST_RESULTS["${CURRENT_SECTION_NUM}"]="skip"
        return 1
    fi
    return 0
}

# =============================================================================
# LEARN MODE / MODE APPRENTISSAGE
# =============================================================================

# FR: En mode apprentissage, afficher une explication et attendre que
#     l'étudiant appuie sur Entrée pour continuer.
# EN: In learn mode, display an explanation and wait for the student
#     to press Enter to continue.
#
# Usage: learn_pause "Explication en français" "Explanation in English"
learn_pause() {
    local msg_fr="$1"
    local msg_en="${2:-}"

    if [[ "${MODE}" != "learn" ]]; then
        return 0
    fi

    echo ""
    echo -e "${CYAN}  ╭─────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}  │${NC} ${BOLD}📘 NOTE${NC}"
    echo -e "${CYAN}  │${NC}"
    # Print FR message, wrapped
    while IFS= read -r line; do
        echo -e "${CYAN}  │${NC}  ${line}"
    done <<< "${msg_fr}"
    if [[ -n "${msg_en}" ]]; then
        echo -e "${CYAN}  │${NC}"
        while IFS= read -r line; do
            echo -e "${CYAN}  │${NC}  ${DIM}${line}${NC}"
        done <<< "${msg_en}"
    fi
    echo -e "${CYAN}  │${NC}"
    echo -e "${CYAN}  ╰─────────────────────────────────────────────────────────╯${NC}"
    echo ""
    read -rp "  ⏎ Appuyez sur Entrée pour continuer / Press Enter to continue... "
    echo ""
}

# =============================================================================
# FINAL SUMMARY / RÉSUMÉ FINAL
# =============================================================================

# FR: Afficher le résumé final de tous les tests
# EN: Display the final summary of all tests
print_final_summary() {
    local total=$(( TOTAL_PASS + TOTAL_FAIL + TOTAL_SKIP ))

    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  RÉSUMÉ FINAL / FINAL SUMMARY${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${GREEN}✓ Réussis  / Passed  : ${TOTAL_PASS}${NC}"
    echo -e "  ${RED}✗ Échoués  / Failed  : ${TOTAL_FAIL}${NC}"
    echo -e "  ${YELLOW}⊘ Ignorés  / Skipped : ${TOTAL_SKIP}${NC}"
    echo -e "  ${DIM}  Total              : ${total}${NC}"
    echo ""
    echo -e "  ${DIM}📄 Log    : ${LOG_FILE}${NC}"
    echo -e "  ${DIM}📊 Report : ${REPORT_FILE}${NC}"
    echo ""

    if (( TOTAL_FAIL == 0 )); then
        echo -e "  ${GREEN}${BOLD}🎉 ALL TESTS PASSED / TOUS LES TESTS ONT RÉUSSI${NC}"
    else
        echo -e "  ${RED}${BOLD}⚠  ${TOTAL_FAIL} TEST(S) FAILED / ${TOTAL_FAIL} TEST(S) ÉCHOUÉ(S)${NC}"
        echo -e "  ${DIM}  Consultez le log pour plus de détails / Check the log for details${NC}"
    fi
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# =============================================================================
# REPORT DIFF / COMPARAISON DE RAPPORTS
# =============================================================================

# FR: Comparer le dernier rapport avec le précédent
# EN: Compare the latest report with the previous one
diff_reports() {
    local reports
    reports=$(find "${RESULTS_DIR}" -name 'report-*.json' | sort | tail -2)
    local count
    count=$(echo "${reports}" | wc -l)

    if (( count < 2 )); then
        echo -e "${YELLOW}  Pas assez de rapports pour comparer (besoin de 2 minimum)${NC}"
        echo -e "${YELLOW}  Not enough reports to compare (need at least 2)${NC}"
        return 0
    fi

    local prev
    prev=$(echo "${reports}" | head -1)
    local curr
    curr=$(echo "${reports}" | tail -1)

    echo -e "${BOLD}  Comparaison / Comparison:${NC}"
    echo -e "  ${DIM}Précédent / Previous: ${prev}${NC}"
    echo -e "  ${DIM}Courant   / Current : ${curr}${NC}"
    echo ""

    # Simple diff using jq if available, otherwise raw diff
    if command -v jq &>/dev/null; then
        local prev_summary curr_summary
        prev_summary=$(jq -r '.summary | "pass=\(.pass) fail=\(.fail) skip=\(.skip)"' "${prev}")
        curr_summary=$(jq -r '.summary | "pass=\(.pass) fail=\(.fail) skip=\(.skip)"' "${curr}")
        echo -e "  Précédent / Previous : ${prev_summary}"
        echo -e "  Courant   / Current  : ${curr_summary}"
        if [[ "${prev_summary}" == "${curr_summary}" ]]; then
            echo -e "  ${GREEN}✓ Pas de changement / No changes${NC}"
        else
            echo -e "  ${YELLOW}⚠  Résultats différents / Results differ${NC}"
        fi
    else
        diff --color=auto <(cat "${prev}") <(cat "${curr}") || true
    fi
}
