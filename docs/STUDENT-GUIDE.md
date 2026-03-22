# Guide de l'étudiant / Student Guide

## Bienvenue / Welcome

Ce guide vous aidera à configurer votre environnement de lab et à utiliser
la suite de tests en mode interactif.

This guide will help you set up your lab environment and use the test suite
in interactive mode.

## Configuration de la VM / VM Setup

### Option 1: Multipass (recommandé / recommended)

```bash
# Installer multipass / Install multipass
sudo snap install multipass

# Lancer une VM propre / Launch a clean VM
./cloud-init/provision-multipass.sh --fresh

# Se connecter / Connect
multipass shell cr380-lab
```

### Option 2: VM Proxmox

Votre enseignant vous fournira les identifiants de connexion.
Your teacher will provide you with connection credentials.

## Première exécution / First run

```bash
cd ~/incus-lab

# Mode interactif (recommandé pour la première fois)
# Interactive mode (recommended for first time)
sudo ./run-labs.sh --learn
```

En mode `--learn`, le script:
- Explique chaque étape en français ET en anglais
- Attend que vous appuyiez sur Entrée avant de continuer
- Affiche les commandes qui seront exécutées

In `--learn` mode, the script:
- Explains each step in French AND English
- Waits for you to press Enter before continuing
- Shows the commands that will be executed

## Exécuter un seul lab / Run a single lab

```bash
# Exécuter uniquement le lab sur les images
# Run only the images lab
sudo ./run-labs.sh --learn --lab 06
```

## Recommencer un lab / Redo a lab

Si vous voulez recommencer un lab à zéro:
If you want to redo a lab from scratch:

```bash
# Nettoyer et réexécuter le lab 09
# Clean and rerun lab 09
sudo ./run-labs.sh --reset 09
```

## Comprendre les résultats / Understanding results

```
✓  = Test réussi / Test passed
✗  = Test échoué / Test failed (lisez le HINT!)
⊘  = Test ignoré / Test skipped (dépendance non satisfaite)
```

Quand un test échoue, regardez:
When a test fails, look at:
- **Attendu / Expected**: ce qui était attendu
- **Obtenu / Actual**: ce qui a été obtenu
- **💡 HINT**: conseil pour résoudre le problème

## Liste des labs / Lab list

| # | Titre / Title | Description |
|---|--------------|-------------|
| 00 | Preflight | Vérifications préalables / Pre-flight checks |
| 01 | Désinstallation / Uninstall | Supprimer Incus complètement |
| 02 | Installation / Install | Installer Incus via apt |
| 03 | Après installation / Post-install | Configurer les groupes utilisateur |
| 04 | Initialisation / Init | Configurer stockage, réseau, profils |
| 05 | Registres / Registries | Explorer les serveurs d'images |
| 06 | Images | Chercher, télécharger, gérer les images |
| 07 | Conteneurs / Containers | Lancer, cloner, publier, supprimer |
| 08 | Ports | Exposer des ports avec proxy devices |
| 09 | Application | Créer un conteneur nginx sur Debian |
| 10 | Fichiers / Files | Transférer des fichiers host ↔ conteneur |
| 11 | Stockage / Storage | Créer et utiliser un pool de stockage |
| 12 | Volumes | Créer et attacher un volume persistant |
| 99 | Nettoyage / Teardown | Tout supprimer et repartir à zéro |

## Besoin d'aide? / Need help?

- Consultez le [Troubleshooting Guide](TROUBLESHOOTING.md)
- Lisez la [documentation Incus officielle](https://linuxcontainers.org/incus/docs/main/)
- Demandez à votre enseignant / Ask your teacher
