# CR380 — Incus Lab

> **FR** : Suite de tests automatisés et tutoriels interactifs pour apprendre les conteneurs [Incus](https://linuxcontainers.org/incus/) dans le cadre du cours CR380 — *Introduction aux conteneurs* à Polytechnique Montréal.
>
> **EN**: Automated test suite and interactive tutorials for learning [Incus](https://linuxcontainers.org/incus/) containers as part of the CR380 — *Introduction to Containers* course at Polytechnique Montréal.

Incus est un gestionnaire de conteneurs et de machines virtuelles système.
Ce dépôt contient **13 labs progressifs** (00–12) plus un nettoyage final (99) qui couvrent l'installation, la configuration, la gestion d'images, le cycle de vie des conteneurs, le réseau, le stockage et les volumes persistants.

Incus is a system container and virtual machine manager.
This repository contains **13 progressive labs** (00–12) plus a final teardown (99) covering installation, configuration, image management, container lifecycle, networking, storage, and persistent volumes.

---

## Démarrage rapide / Quick Start

```bash
# Mode interactif étudiant — explications bilingues, pauses entre les étapes
# Interactive student mode — bilingual explanations, pauses between steps
sudo ./run-labs.sh --learn

# Mode validation enseignant — rapide, silencieux, résumé à la fin
# Teacher validation mode — fast, quiet, summary at end
sudo ./run-labs.sh --validate

# Exécuter un seul lab / Run a single lab
sudo ./run-labs.sh --learn --lab 07
```

> **Prérequis / Prerequisites** : Ubuntu 24.04 LTS (amd64), accès `sudo`, connexion Internet, 10 Go+ d'espace disque libre.
> Voir le [Guide de l'étudiant](docs/STUDENT-GUIDE.md) pour la configuration de la VM / See the [Student Guide](docs/STUDENT-GUIDE.md) for VM setup.

---

## Progression des labs / Lab Progression

Les labs sont organisés en **4 phases d'apprentissage**. Chaque lab dépend du précédent dans sa phase.

The labs are organized into **4 learning phases**. Each lab depends on the previous one within its phase.

```mermaid
graph LR
    subgraph "🔧 Phase 1 — Mise en place / Setup"
        L00["00 · Preflight"]
        L01["01 · Désinstallation<br/>Uninstall"]
        L02["02 · Installation<br/>Install"]
        L03["03 · Post-installation<br/>Post-install"]
        L04["04 · Initialisation<br/>Init"]
        L00 --> L01 --> L02 --> L03 --> L04
    end

    subgraph "📦 Phase 2 — Concepts fondamentaux / Core Concepts"
        L05["05 · Registres<br/>Registries"]
        L06["06 · Images"]
        L07["07 · Conteneurs<br/>Containers"]
        L04 --> L05 --> L06 --> L07
    end

    subgraph "🌐 Phase 3 — Réseau et applications / Networking & Apps"
        L08["08 · Exposition de ports<br/>Port Exposure"]
        L09["09 · Conteneur applicatif<br/>App Container"]
        L07 --> L08 --> L09
    end

    subgraph "💾 Phase 4 — Persistance / Persistence"
        L10["10 · Transfert de fichiers<br/>File Transfer"]
        L11["11 · Stockage<br/>Storage Pools"]
        L12["12 · Volumes"]
        L09 --> L10 --> L11 --> L12
    end

    L99["99 · Nettoyage final<br/>Final Teardown"]
    L12 -.->|cleanup| L99

    style L00 fill:#e8f5e9
    style L12 fill:#e3f2fd
    style L99 fill:#ffebee
```

---

## Résumé des labs / Lab Summary

| # | Lab | Description FR | Description EN | Commande clé / Key Command |
|---|-----|---------------|----------------|---------------------------|
| 00 | **Preflight** | Vérifier l'environnement (OS, sudo, réseau, disque) | Verify environment (OS, sudo, network, disk) | — |
| 01 | **Désinstallation** | Supprimer Incus complètement pour repartir à zéro | Remove Incus completely for a clean start | `sudo apt purge incus incus-client` |
| 02 | **Installation** | Installer Incus via le gestionnaire de paquets | Install Incus via the package manager | `sudo apt install incus` |
| 03 | **Post-installation** | Ajouter l'utilisateur au groupe `incus-admin` | Add the user to the `incus-admin` group | `sudo adduser $USER incus-admin` |
| 04 | **Initialisation** | Configurer stockage, réseau et profils via preseed | Configure storage, network and profiles via preseed | `incus admin init --preseed` |
| 05 | **Registres** | Explorer les serveurs d'images distants | Explore remote image servers | `incus remote list` |
| 06 | **Images** | Chercher, télécharger et gérer les images | Search, download and manage images | `incus image copy images:ubuntu/noble/amd64 local: --alias ubuntux64` |
| 07 | **Conteneurs** | Lancer, cloner, publier et supprimer des conteneurs | Launch, clone, publish and delete containers | `incus launch ubuntux64 u1` |
| 08 | **Ports** | Exposer un port via un proxy device | Expose a port via a proxy device | `incus config device add routerCT monport80vers8888 proxy listen=tcp:0.0.0.0:8888 connect=tcp:127.0.0.1:80` |
| 09 | **Application** | Installer nginx dans un conteneur Debian, publier l'image | Install nginx in a Debian container, publish the image | `incus exec debianCT -- apt-get install -y nginx` |
| 10 | **Fichiers** | Transférer des fichiers entre l'hôte et un conteneur | Transfer files between host and container | `incus file push index.html nginxCT/var/www/html/` |
| 11 | **Stockage** | Créer un pool de stockage dédié | Create a dedicated storage pool | `incus storage create websrv_storage dir source=/root/websrv_dir` |
| 12 | **Volumes** | Créer et attacher un volume persistant | Create and attach a persistent volume | `incus storage volume attach websrv_storage www_volume appwebCT /var/www` |
| 99 | **Nettoyage** | Tout supprimer et repartir à zéro | Delete everything and start fresh | `sudo ./run-labs.sh --reset 99` |

---

## Comprendre les résultats / Understanding Results

```
✓  Test réussi / Test passed
✗  Test échoué / Test failed — lisez le HINT / read the HINT
⊘  Test ignoré / Test skipped — dépendance non satisfaite / unmet dependency
```

Quand un test échoue, le script affiche :
- **Attendu / Expected** — le résultat attendu
- **Obtenu / Actual** — le résultat obtenu
- **💡 HINT** — une suggestion pour résoudre le problème

When a test fails, the script shows:
- **Expected** — what was expected
- **Actual** — what was obtained
- **💡 HINT** — a suggestion to fix the issue

---

## Modes d'exécution / Execution Modes

| Drapeau / Flag | Mode | Description |
|----------------|------|-------------|
| `--validate` | Enseignant / Teacher | Exécution rapide, résumé à la fin / Fast run, summary at end |
| `--learn` | Étudiant / Student | Explications bilingues, pause entre chaque étape / Bilingual explanations, pause between steps |
| `--lab NN` | Lab unique / Single lab | Exécuter uniquement le lab NN / Run only lab NN |
| `--reset NN` | Réinitialisation / Reset | Nettoyer puis réexécuter le lab NN / Clean then rerun lab NN |
| `--quick` | Rapide / Quick | Sauter install/init si Incus est déjà présent / Skip install/init if Incus present |
| `--diff` | Comparaison / Compare | Comparer les 2 derniers rapports JSON / Compare last 2 JSON reports |
| `--verbose` | Verbeux / Verbose | Afficher toutes les sorties / Show all output |
| `--check-images` | Vérification / Check | Vérifier que les images existent dans les registres / Verify images exist in registries |

---

## Structure du projet / Project Structure

```
incus-lab/
├── run-labs.sh              # Lanceur principal / Master runner
├── config.env               # Configuration centrale / Central config
├── tests/
│   ├── _common.sh           # Framework de test / Test framework
│   ├── 00-preflight.sh      # → 12-volumes.sh  (13 labs)
│   └── 99-teardown.sh       # Nettoyage final / Final cleanup
├── cloud-init/
│   ├── user-data-fresh.yaml       # VM propre / Clean VM
│   ├── user-data-ready.yaml       # VM pré-configurée / Pre-configured VM
│   └── provision-multipass.sh     # Lanceur Multipass / Multipass launcher
├── docs/                    # Documentation détaillée / Detailed docs
├── results/                 # Rapports JSON / JSON reports (auto-generated)
└── logs/                    # Journaux détaillés / Detailed logs (auto-generated)
```

---

## Documentation

| Document | Description |
|----------|-------------|
| [Guide de l'étudiant / Student Guide](docs/STUDENT-GUIDE.md) | Configuration VM, première exécution, aide / VM setup, first run, help |
| [Guide de l'enseignant / Teacher Guide](docs/TEACHER-GUIDE.md) | Validation pré-cours, configuration / Pre-class validation, configuration |
| [Dépannage / Troubleshooting](docs/TROUBLESHOOTING.md) | Erreurs fréquentes et solutions / Common errors and solutions |
| [Architecture](docs/ARCHITECTURE.md) | Fonctionnement interne du framework / Framework internals |

---

## Référence du cours / Course Reference

📖 [CR380 — Introduction aux conteneurs (GitBook)](https://polytechnique-montreal.gitbook.io/cr380/)

---

## Licence / License

Ce projet est utilisé à des fins pédagogiques dans le cadre du cours CR380 à Polytechnique Montréal.

This project is used for educational purposes as part of the CR380 course at Polytechnique Montréal.
