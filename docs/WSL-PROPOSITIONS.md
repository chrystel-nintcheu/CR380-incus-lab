# Propositions d'enrichissement

Idées hors périmètre strict de la migration (classe D). Elles ont été **autorisées par l'enseignant** et implémentées, sauf mention contraire.

| # | Proposition | État | Fichiers |
|---|---|---|---|
| 1 | Comparaison exacte dans `assert_resource_exists` / `assert_resource_not_exists` (et `cleanup_image`, `cleanup_storage`) : nom exact en première colonne CSV, plus de sous-chaîne | fait | `tests/_common.sh` |
| 2 | `wait_for_ready` et `--check-images` passent par `incus_run` (groupe `incus-admin`) | fait | `tests/_common.sh`, `run-labs.sh` |
| 3 | Wrapper `incus_run` : `mktemp` au lieu du chemin fixe, arguments protégés par `printf '%q '`, suppression à la sortie | fait | `tests/_common.sh`, `docs/ARCHITECTURE.md` |
| 4 | Dépôt des labs 10 et 12 épinglé sur un commit (`DEMO_APP_REF`), tutoriel aligné | fait | `config.env`, `tests/10-file-transfer.sh`, `tests/12-volumes.sh`, `gitbook/la-persistance/{transfert-fichiers,volume}.md` |
| 5 | `./run-labs.sh --check-images` avant chaque cours | déjà disponible, aucune modification | — |

## Bugs confirmés par lecture du code et corrigés (classe B)

| # | Hypothèse de la mission | Cause racine | Correction |
|---|---|---|---|
| 4 | `--reset NN` ne nettoie rien | `run-labs.sh` affichait « cleaning up » sans appeler de nettoyage | fonction `reset_lab_artifacts` (conteneurs, images, volume, pool, fichiers du lab NN) |
| 5 | `99-teardown.sh` supprime tout | `incus stop --all` et suppression de **tous** les conteneurs restants, y compris ceux de l'étudiant ; branches qui passaient sans rien tester | seuls les conteneurs et images du lab sont supprimés ; vérification finale ciblée ; la branche « Incus absent » devient un `skip` |
| — | `--diff` compare un rapport vide | `_common.sh` créait un rapport vide au chargement (aussi pour `--diff` et `--check-images`), qui devenait le « courant » et pouvait écraser un vrai rapport créé dans la même seconde | pas de rapport pour ces deux modes ; seuls les rapports finalisés (avec `summary`) sont comparés |

## Hypothèses infirmées

| # | Hypothèse | Constat |
|---|---|---|
| 6 | Lab 11 `/root/websrv_dir` contre nettoyage `${HOME}` | Tous les scripts utilisent `${HOME}/${ADV_STORAGE_DIR}` : cohérent. Seul `README.md` cite `/root/websrv_dir` (valeur de `${HOME}` sous `sudo`). |

## Non traité

- Hypothèse 10 : prérequis alignés dans la préparation de l'hôte.
- Section `VM_*` de `config.env` (Multipass) : non retirée, décision de l'enseignant requise.
