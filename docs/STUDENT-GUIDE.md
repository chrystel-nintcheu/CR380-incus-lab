# Guide de l'étudiant / Student Guide

## Bienvenue / Welcome

Ce guide vous aidera à configurer votre environnement de lab et à utiliser
la suite de tests en mode interactif.

This guide will help you set up your lab environment and use the test suite
in interactive mode.

## Préparation de l'hôte / Host preparation

Avant le Lab 00, préparez votre ordinateur Windows 10 ou 11 : installation de WSL 2,
d'Ubuntu 24.04, vérification de systemd, puis clonage du dépôt dans `~`.
La procédure pas à pas est dans `gitbook/preparation-hote/README.md`.

Before Lab 00, prepare your Windows 10 or 11 computer: install WSL 2 and
Ubuntu 24.04, check systemd, then clone the repository into `~`.
The step-by-step procedure is in `gitbook/preparation-hote/README.md`.

Résumé / Summary:

```powershell
# PowerShell en administrateur / PowerShell as administrator
wsl --install Ubuntu-24.04
wsl -l -v          # VERSION doit être 2 / VERSION must be 2
wsl --update
```

```bash
# Dans Ubuntu / Inside Ubuntu
cd ~
git clone -b wsl-version https://github.com/chrystel-nintcheu/CR380-incus-lab.git
cd CR380-incus-lab
sudo ./run-labs.sh --lab 00
```

Ne placez jamais le dépôt sous `/mnt/c`. / Never put the repository under `/mnt/c`.

## Première exécution / First run

```bash
cd ~/CR380-incus-lab

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
