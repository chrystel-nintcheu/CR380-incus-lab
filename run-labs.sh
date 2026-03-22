#!/usr/bin/env bash
# =============================================================================
# CR380 - Incus Lab Test Suite — Master Runner / Lanceur principal
# =============================================================================
#
# FR: Script principal qui orchestre l'exécution de tous les tests de lab.
#     Supporte plusieurs modes d'exécution pour enseignants et étudiants.
#
# EN: Main script that orchestrates the execution of all lab tests.
#     Supports multiple execution modes for teachers and students.
#
# Usage:
#   sudo ./run-labs.sh                    # Default: validate mode (teacher)
#   sudo ./run-labs.sh --validate         # Same as default
#   sudo ./run-labs.sh --learn            # Student mode: interactive, with pauses
#   sudo ./run-labs.sh --lab 06           # Run only lab 06 (images)
#   sudo ./run-labs.sh --reset 09         # Cleanup + rerun lab 09
#   sudo ./run-labs.sh --quick            # Skip install/init if incus present
#   sudo ./run-labs.sh --check-images     # Verify remote images exist (no download)
#   sudo ./run-labs.sh --diff             # Compare last two reports
#   sudo ./run-labs.sh --verbose          # Show full command output
#   sudo ./run-labs.sh --learn --lab 06   # Combine: learn mode on lab 06 only
#
# =============================================================================

# Resolve paths
RUNNER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="${RUNNER_DIR}/tests"

# =============================================================================
# PARSE ARGUMENTS / ANALYSE DES ARGUMENTS
# =============================================================================

# Defaults
export MODE="validate"
export VERBOSE=1
RUN_LAB=""
RESET_LAB=""
QUICK_MODE=false
CHECK_IMAGES_ONLY=false
DIFF_ONLY=false

usage() {
    cat <<'USAGE'
CR380 - Incus Lab Test Suite
Usage: sudo ./run-labs.sh [OPTIONS]

Modes:
  --validate        Mode enseignant (défaut): exécution rapide, résumé à la fin
                    Teacher mode (default): fast execution, summary at end
  --learn           Mode étudiant: interactif, avec pauses et explications
                    Student mode: interactive, with pauses and explanations

Filtering:
  --lab NN          Exécuter seulement le lab NN (ex: 06)
                    Run only lab NN (e.g., 06)
  --reset NN        Nettoyer les artefacts du lab NN, puis le relancer
                    Cleanup artifacts from lab NN, then rerun it
  --quick           Sauter install/init si incus est déjà présent
                    Skip install/init if incus is already present

Utilities:
  --check-images    Vérifier que les images existent (sans télécharger)
                    Verify remote images exist (no download)
  --diff            Comparer les deux derniers rapports
                    Compare the last two reports
  --verbose         Afficher la sortie complète des commandes
                    Show full command output
  -h, --help        Afficher cette aide / Show this help

Examples:
  sudo ./run-labs.sh                      # Full validation
  sudo ./run-labs.sh --learn              # Student interactive mode
  sudo ./run-labs.sh --learn --lab 06     # Learn mode, lab 06 only
  sudo ./run-labs.sh --quick              # Skip install, validate the rest
  sudo ./run-labs.sh --check-images       # Quick image availability check
  sudo ./run-labs.sh --diff               # Compare last two results
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --validate)
            MODE="validate"; shift ;;
        --learn)
            MODE="learn"; shift ;;
        --lab)
            RUN_LAB="$2"; shift 2 ;;
        --reset)
            RESET_LAB="$2"; shift 2 ;;
        --quick)
            QUICK_MODE=true; shift ;;
        --check-images)
            CHECK_IMAGES_ONLY=true; shift ;;
        --diff)
            DIFF_ONLY=true; shift ;;
        --verbose)
            VERBOSE=2; shift ;;
        -h|--help)
            usage; exit 0 ;;
        *)
            echo "Unknown option: $1"; usage; exit 1 ;;
    esac
done

export MODE VERBOSE

# =============================================================================
# SOURCE FRAMEWORK / CHARGER LE FRAMEWORK
# =============================================================================
source "${TESTS_DIR}/_common.sh"

# =============================================================================
# DIFF MODE — just compare reports and exit
# =============================================================================
if [[ "${DIFF_ONLY}" == "true" ]]; then
    diff_reports
    exit 0
fi

# =============================================================================
# CHECK-IMAGES MODE — verify image availability and exit
# =============================================================================
if [[ "${CHECK_IMAGES_ONLY}" == "true" ]]; then
    section_header "CI" "Check Remote Images / Vérification des images" ""
    echo -e "  ${DIM}Vérification de la disponibilité des images... / Checking image availability...${NC}"

    # Source config for image names
    all_ok=true
    for img_var in IMAGE_UBUNTU IMAGE_ALPINE IMAGE_OPENWRT IMAGE_DEBIAN; do
        img_name="${!img_var}"
        echo -ne "  Checking ${img_name}... "
        if timeout 30 incus image list "${img_name}" --format csv 2>/dev/null | grep -q .; then
            echo -e "${GREEN}✓ available${NC}"
        else
            echo -e "${RED}✗ NOT FOUND${NC}"
            all_ok=false
        fi
    done

    if [[ "${all_ok}" == "true" ]]; then
        echo -e "\n  ${GREEN}${BOLD}✓ Toutes les images sont disponibles / All images available${NC}"
        exit 0
    else
        echo -e "\n  ${RED}${BOLD}✗ Certaines images sont introuvables / Some images not found${NC}"
        echo -e "  ${YELLOW}💡 HINT: Mettez à jour config.env avec les noms d'images corrects${NC}"
        echo -e "  ${YELLOW}         Update config.env with correct image names${NC}"
        exit 1
    fi
fi

# =============================================================================
# BANNER / BANNIÈRE
# =============================================================================
echo ""
echo -e "${BOLD}${BLUE}"
echo "  ╔══════════════════════════════════════════════════════════╗"
echo "  ║                                                          ║"
echo "  ║   CR380 — Introduction aux conteneurs                    ║"
echo "  ║   Suite de tests automatisés / Automated Test Suite      ║"
echo "  ║                                                          ║"
echo "  ╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  ${DIM}Mode     : ${MODE}${NC}"
echo -e "  ${DIM}Date     : $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "  ${DIM}Log      : ${LOG_FILE}${NC}"
echo -e "  ${DIM}Report   : ${REPORT_FILE}${NC}"
if [[ -n "${RUN_LAB}" ]]; then
    echo -e "  ${DIM}Lab      : ${RUN_LAB} only${NC}"
fi
if [[ "${QUICK_MODE}" == "true" ]]; then
    echo -e "  ${DIM}Quick    : skipping install/init${NC}"
fi
echo ""

log "=========================================="
log "CR380 Lab Test Suite — START"
log "Mode: ${MODE} | Quick: ${QUICK_MODE} | Lab: ${RUN_LAB:-all} | Reset: ${RESET_LAB:-none}"
log "=========================================="

# =============================================================================
# DEFINE TEST ORDER / DÉFINIR L'ORDRE DES TESTS
# =============================================================================

# FR: Liste ordonnée de tous les scripts de test
# EN: Ordered list of all test scripts
ALL_TESTS=(
    "00-preflight.sh"
    "01-uninstall.sh"
    "02-install.sh"
    "03-post-install.sh"
    "04-init.sh"
    "05-registries.sh"
    "06-images.sh"
    "07-containers.sh"
    "08-port-exposure.sh"
    "09-app-container.sh"
    "10-file-transfer.sh"
    "11-storage.sh"
    "12-volumes.sh"
    "99-teardown.sh"
)

# Quick mode: skip install-related tests if incus is already present
# FR: Mode rapide : sauter les tests d'installation si incus est déjà installé
if [[ "${QUICK_MODE}" == "true" ]] && command -v incus &>/dev/null; then
    echo -e "  ${DIM}Incus already installed — skipping labs 00-04${NC}"
    log "QUICK MODE: incus found, skipping 00-04"
    # Mark 00-04 as passed so dependencies are satisfied
    TEST_RESULTS["00"]="pass"
    TEST_RESULTS["01"]="pass"
    TEST_RESULTS["02"]="pass"
    TEST_RESULTS["03"]="pass"
    TEST_RESULTS["04"]="pass"
    ALL_TESTS=(
        "05-registries.sh"
        "06-images.sh"
        "07-containers.sh"
        "08-port-exposure.sh"
        "09-app-container.sh"
        "10-file-transfer.sh"
        "11-storage.sh"
        "12-volumes.sh"
        "99-teardown.sh"
    )
fi

# =============================================================================
# SINGLE LAB MODE / MODE LAB UNIQUE
# =============================================================================
if [[ -n "${RUN_LAB}" ]]; then
    target_file=""
    for test_file in "${ALL_TESTS[@]}"; do
        if [[ "${test_file}" == "${RUN_LAB}-"* ]]; then
            target_file="${test_file}"
            break
        fi
    done
    if [[ -z "${target_file}" ]]; then
        echo -e "${RED}  Lab '${RUN_LAB}' not found. Available labs:${NC}"
        printf '    %s\n' "${ALL_TESTS[@]}"
        exit 1
    fi
    # Mark all previous tests as passed (assume they ran before)
    for test_file in "${ALL_TESTS[@]}"; do
        local_num="${test_file%%-*}"
        if [[ "${local_num}" < "${RUN_LAB}" ]]; then
            TEST_RESULTS["${local_num}"]="pass"
        fi
    done
    ALL_TESTS=("${target_file}")
    echo -e "  ${DIM}Running single lab: ${target_file}${NC}"
fi

# =============================================================================
# RESET MODE / MODE RÉINITIALISATION
# =============================================================================
if [[ -n "${RESET_LAB}" ]]; then
    target_file=""
    for test_file in "${ALL_TESTS[@]}"; do
        if [[ "${test_file}" == "${RESET_LAB}-"* ]]; then
            target_file="${test_file}"
            break
        fi
    done
    if [[ -z "${target_file}" ]]; then
        echo -e "${RED}  Lab '${RESET_LAB}' not found.${NC}"
        exit 1
    fi
    echo -e "  ${DIM}Reset mode: cleaning up lab ${RESET_LAB} artifacts first...${NC}"
    # Mark all previous tests as passed
    for test_file in "${ALL_TESTS[@]}"; do
        local_num="${test_file%%-*}"
        if [[ "${local_num}" < "${RESET_LAB}" ]]; then
            TEST_RESULTS["${local_num}"]="pass"
        fi
    done
    ALL_TESTS=("${target_file}")
fi

# =============================================================================
# EXECUTE TESTS / EXÉCUTER LES TESTS
# =============================================================================
for test_file in "${ALL_TESTS[@]}"; do
    test_path="${TESTS_DIR}/${test_file}"

    if [[ ! -f "${test_path}" ]]; then
        echo -e "  ${YELLOW}⊘ Test file not found: ${test_file} — skipping${NC}"
        continue
    fi

    # Source and run the test script
    # FR: Charger et exécuter le script de test
    # Each test script defines a run_test() function that we call
    source "${test_path}"
    run_test
done

# =============================================================================
# FINALIZE / FINALISER
# =============================================================================
finalize_report
print_final_summary

# Exit with non-zero if any test failed
# FR: Quitter avec un code non-zéro si au moins un test a échoué
if (( TOTAL_FAIL > 0 )); then
    exit 1
fi
exit 0
