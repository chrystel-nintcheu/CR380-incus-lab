# Guide de l'enseignant / Teacher Guide

## Avant chaque cours / Before Each Class

### 1. Mettre à jour la configuration / Update configuration

Vérifiez que les images sont toujours disponibles dans les registres:

```bash
sudo ./run-labs.sh --check-images
```

Si une image a changé de version, mettez à jour `config.env`:

```bash
vim config.env
# Modifier IMAGE_UBUNTU, IMAGE_ALPINE, etc.
```

### 2. Valider tous les labs / Validate all labs

Exécutez la suite complète sur une VM propre:

```bash
sudo ./run-labs.sh --validate
```

Résultat attendu: tous les tests passent (🎉 ALL TESTS PASSED).

Si des tests échouent:
- Consultez le log: `logs/test-YYYYMMDD-HHMMSS.log`
- Consultez le rapport: `results/report-YYYYMMDD-HHMMSS.json`
- Comparez avec le run précédent: `sudo ./run-labs.sh --diff`

### 3. Comparer les résultats / Compare results

```bash
sudo ./run-labs.sh --diff
```

Ceci compare le dernier rapport avec le précédent pour détecter les régressions.

## Provisionnement des VMs étudiantes / Student VM Provisioning

### Option A: Multipass (sur l'ordinateur de l'étudiant)

```bash
# VM propre (labs à partir de zéro)
./cloud-init/provision-multipass.sh --fresh

# VM pré-configurée (labs avancés)
./cloud-init/provision-multipass.sh --ready
```

### Option B: Proxmox (VMs centralisées)

1. Créez un template Ubuntu 24.04 dans Proxmox
2. Configurez cloud-init avec le contenu de `cloud-init/user-data-fresh.yaml`
3. Clonez le template pour chaque étudiant

### Personnalisation

- **SSH keys**: Ajoutez les clés SSH des étudiants dans les fichiers cloud-init
- **Git repo URL**: Remplacez `CHANGE-ME` dans les fichiers cloud-init par l'URL réelle du dépôt
- **Password**: Changez le mot de passe par défaut `cr380lab` dans les fichiers cloud-init

## Correction rapide d'un lab / Quick lab fix

Pour réexécuter un seul lab après une correction:

```bash
sudo ./run-labs.sh --reset 09  # Nettoie et réexécute uniquement le lab 09
```

## Structure des rapports JSON / JSON report structure

```json
{
  "timestamp": "20250101-143000",
  "tests": [
    {"test": "00-Preflight", "status": "pass", "duration_s": 5, "error": ""},
    {"test": "01-Uninstall", "status": "pass", "duration_s": 15, "error": ""}
  ],
  "summary": {"pass": 42, "fail": 0, "skip": 0}
}
```

## Calendrier recommandé / Recommended schedule

| Semaine | Labs | Commande de validation |
|---------|------|----------------------|
| 1 | 00-04 (Install + Init) | `for i in 00 01 02 03 04; do sudo ./run-labs.sh --lab $i; done` |
| 2 | 05-07 (Images + Conteneurs) | `for i in 05 06 07; do sudo ./run-labs.sh --quick --lab $i; done` |
| 3 | 08-10 (Ports + Apps + Fichiers) | `for i in 08 09 10; do sudo ./run-labs.sh --quick --lab $i; done` |
| 4 | 11-12 (Stockage + Volumes) | `for i in 11 12; do sudo ./run-labs.sh --quick --lab $i; done` |
