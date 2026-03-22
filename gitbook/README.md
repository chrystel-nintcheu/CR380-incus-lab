# Accueil — CR380 Labs Incus

Bienvenue dans le guide pratique du cours **CR380** de Polytechnique Montréal. Ce guide accompagne la suite de tests automatisés qui reproduit chaque exercice de lab Incus.

{% hint style="info" %}
Ce guide est généré à partir du dépôt [CR380-incus-lab](https://github.com/chrystel-nintcheu/CR380-incus-lab). Les commandes présentées sont les mêmes que celles exécutées par la suite de tests automatisés.
{% endhint %}

## Progression des labs

| Lab | Titre | Section | Prérequis |
|-----|-------|---------|-----------|
| 00 | Vérifications préalables | — | Aucun |
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

- **OS** : Ubuntu 24.04 ou supérieur (amd64)
- **Disque** : au moins 10 Go d'espace libre
- **Internet** : accès à `linuxcontainers.org`
- **Sudo** : accès sans mot de passe (ou mot de passe en cache)
- **Outils** : `git`, `curl`, `jq` installés
{% endtab %}
{% tab title="English" %}
Before starting, make sure your machine meets these requirements:

- **OS**: Ubuntu 24.04 or later (amd64)
- **Disk**: at least 10 GB free space
- **Internet**: access to `linuxcontainers.org`
- **Sudo**: passwordless or cached password
- **Tools**: `git`, `curl`, `jq` installed
{% endtab %}
{% endtabs %}

## Structure du cours

Le cours est divisé en trois grandes sections :

1. **Installation et configuration** (Labs 01–04) — Installer Incus, configurer les permissions, initialiser le stockage et le réseau.
2. **Les flux Incus** (Labs 05–08) — Explorer les registres d'images, télécharger des images, lancer des conteneurs, exposer des ports.
3. **La persistance** (Labs 09–12) — Créer des conteneurs d'application, transférer des fichiers, gérer le stockage et les volumes.

Un lab de nettoyage (Lab 99) remet votre environnement dans son état initial.
