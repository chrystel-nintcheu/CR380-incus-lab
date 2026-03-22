# CR380 Incus Lab — Automated Test Suite

> **FR**: Suite de tests automatisés pour valider les labs Incus du cours CR380.
> **EN**: Automated test suite to validate CR380 Incus lab exercises.

## Quick Start / Démarrage rapide

```bash
# Teacher: validate all labs before class
sudo ./run-labs.sh --validate

# Student: interactive learning mode
sudo ./run-labs.sh --learn

# Run a single lab
sudo ./run-labs.sh --lab 06

# Reset and rerun a specific lab
sudo ./run-labs.sh --reset 09
```

## Requirements / Prérequis

- Ubuntu 24.04 LTS (amd64)
- `sudo` access
- Internet connection
- 10 GB+ free disk space

## Project Structure / Structure du projet

```
incus-lab/
├── run-labs.sh              # Master runner (all modes and flags)
├── config.env               # Central configuration (images, timeouts, names)
├── tests/
│   ├── _common.sh           # Test framework (assertions, logging, reports)
│   ├── 00-preflight.sh      # Pre-flight checks (OS, sudo, internet, disk)
│   ├── 01-uninstall.sh      # Complete Incus removal
│   ├── 02-install.sh        # Incus installation via apt
│   ├── 03-post-install.sh   # Post-install: user groups + permissions
│   ├── 04-init.sh           # Incus initialization (preseed YAML)
│   ├── 05-registries.sh     # Remote registries
│   ├── 06-images.sh         # Image search, download, alias, delete
│   ├── 07-containers.sh     # Container lifecycle (launch, clone, publish)
│   ├── 08-port-exposure.sh  # Proxy devices (port forwarding)
│   ├── 09-app-container.sh  # Application container (nginx on Debian)
│   ├── 10-file-transfer.sh  # File push/pull between host and containers
│   ├── 11-storage.sh        # Storage pools
│   ├── 12-volumes.sh        # Persistent volumes
│   └── 99-teardown.sh       # Full cleanup
├── cloud-init/
│   ├── user-data-fresh.yaml       # Clean VM (no Incus)
│   ├── user-data-ready.yaml       # Pre-configured VM (Incus ready)
│   └── provision-multipass.sh     # Multipass launcher
├── docs/                    # Documentation
├── results/                 # JSON test reports (auto-generated)
└── logs/                    # Detailed logs (auto-generated)
```

## Modes / Modes d'exécution

| Flag | Description FR | Description EN |
|------|---------------|----------------|
| `--validate` | Mode enseignant (défaut): rapide, silencieux, résumé à la fin | Teacher mode (default): fast, quiet, summary at end |
| `--learn` | Mode étudiant: pauses, explications bilingues | Student mode: pauses, bilingual explanations |
| `--lab NN` | Exécuter un seul lab | Run a single lab |
| `--reset NN` | Nettoyer + réexécuter un lab | Clean + rerun a lab |
| `--quick` | Sauter install/init si Incus déjà présent | Skip install/init if Incus present |
| `--check-images` | Vérifier que les images existent dans les registres | Verify images exist in registries |
| `--diff` | Comparer les 2 derniers rapports | Compare last 2 reports |
| `--verbose` | Afficher toutes les sorties | Show all output |

## Configuration

Edit [config.env](config.env) to update image names, aliases, timeouts, and other settings before each semester or when image versions change.

## Reports / Rapports

JSON reports are saved in `results/` after each run. Use `--diff` to compare:

```bash
sudo ./run-labs.sh --diff
```

## See Also / Voir aussi

- [TEACHER-GUIDE.md](TEACHER-GUIDE.md) — Pre-class validation workflow
- [STUDENT-GUIDE.md](STUDENT-GUIDE.md) — Student onboarding
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) — Common errors + solutions
- [ARCHITECTURE.md](ARCHITECTURE.md) — Framework internals
