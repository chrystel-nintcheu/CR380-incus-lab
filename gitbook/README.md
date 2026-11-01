# Accueil — CR380 Labs Incus

Bienvenue dans le guide pratique du cours **CR380** de Polytechnique Montréal. Ce guide accompagne la suite de tests automatisés qui reproduit chaque exercice de lab Incus.

{% hint style="info" %}
Ce guide est généré à partir du dépôt [CR380-incus-lab](https://github.com/chrystel-nintcheu/CR380-incus-lab). Les commandes présentées sont les mêmes que celles exécutées par la suite de tests automatisés.
{% endhint %}

## Progression des labs

| Lab | Titre | Section | Prérequis |
|-----|-------|---------|-----------|
| 00 | Vérifications préalables | Préparation de l'hôte | Aucun |
| 01 | Désinstallation | Installation et configuration | Lab 00 |
| 02 | Installation | Installation et configuration | Lab 01 |
| 03 | Après installation | Installation et configuration | Lab 02 |
| 04 | Initialisation | Installation et configuration | Lab 03 |
| 05 | Registres | Les flux Incus | Lab 04 |
| 06 | Images | Les flux Incus | Lab 05 |
| 07 | Conteneurs | Les flux Incus | Lab 06 |
| 08 | Exposer un port | Les flux Incus | Lab 07 |
| 09 | Conteneur d'application | La persistance | Lab 08 |
| 10 | Transfert de fichiers | La persistance | Lab 09 |
| 11 | Stockage | La persistance | Lab 10 |
| 12 | Volumes | La persistance | Lab 11 |
| 99 | Nettoyage final | Finalisation | Aucun |

## Prérequis système

{% tabs %}
{% tab title="Français" %}
Avant de commencer, assurez-vous que votre machine répond à ces critères :

- **OS** : Ubuntu 24.04 (amd64) dans WSL 2, sur Windows 10 (build 19041 ou plus) ou Windows 11. Suivez d'abord la [Préparation de l'hôte](preparation-hote/README.md)
- **Disque** : au moins 10 Go d'espace libre dans Ubuntu (20 Go libres sur `C:` recommandés)
- **Internet** : accès à `linuxcontainers.org`
- **Sudo** : le mot de passe de votre utilisateur Ubuntu
- **Outils** : `git`, `curl` et `wget` installés (`jq` facultatif)
{% endtab %}
{% tab title="English" %}
Before starting, make sure your machine meets these requirements:

- **OS**: Ubuntu 24.04 (amd64) in WSL 2, on Windows 10 (build 19041 or later) or Windows 11. Follow the [host preparation](preparation-hote/README.md) first
- **Disk**: at least 10 GB free space in Ubuntu (20 GB free on `C:` recommended)
- **Internet**: access to `linuxcontainers.org`
- **Sudo**: your Ubuntu user password
- **Tools**: `git`, `curl` and `wget` installed (`jq` optional)
{% endtab %}
{% endtabs %}

## Structure du cours

Le cours est divisé en trois grandes sections :

1. **Installation et configuration** (Labs 01–04) — Installer Incus, configurer les permissions, initialiser le stockage et le réseau.
2. **Les flux Incus** (Labs 05–08) — Explorer les registres d'images, télécharger des images, lancer des conteneurs, exposer des ports.
3. **La persistance** (Labs 09–12) — Créer des conteneurs d'application, transférer des fichiers, gérer le stockage et les volumes.

Un lab de nettoyage (Lab 99) remet votre environnement dans son état initial.
