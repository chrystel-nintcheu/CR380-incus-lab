# Portage WSL 2 — inventaire et décisions

Branche de travail : `wsl-version` (la mission parle de `wsl` : écart à valider, voir « Décisions demandées »).
Classes : **A** adaptation WSL, **B** correction de bug, **C** clarification pédagogique.

## Versions testées

| Élément | Valeur |
|---|---|
| Windows | Windows 11 24H2, build 26100.8037 (le registre affiche « Windows 10 Enterprise » : c'est un défaut connu, le numéro de build ≥ 22000 indique Windows 11) |
| WSL | 2.7.14.0, noyau `6.18.33.2-microsoft-standard-WSL2` |
| Distribution | Ubuntu 24.04.5 LTS (`Ubuntu-24.04`, copie jetable `cr380-test`) |
| Incus | 6.0.0 (paquet `incus` d'Ubuntu, via apt) |
| Réseau WSL | NAT (par défaut), aucun `.wslconfig` |

## Matrice Windows

| Windows | Statut |
|---|---|
| Windows 11 | testé (build 26100) |
| Windows 10 | **non testé** |

## Inventaire (phase 0)

| Fichier | Verdict | Effet sous WSL |
|---|---|---|
| `run-labs.sh` | **B** | `--reset` nettoie réellement, `--check-images` via `incus_run` ; `--quick` interdit en validation officielle |
| `tests/_common.sh` | **B** | assertions exactes, wrapper `mktemp`/`%q`, `wait_for_ready` via `incus_run`, `--diff` corrigé |
| `tests/99-teardown.sh`, `tests/10-file-transfer.sh`, `tests/12-volumes.sh` | **B** | teardown limité aux ressources du lab ; dépôt de démonstration épinglé |
| `tests/00-preflight.sh` | **A** | ajout des contrôles WSL 2, systemd, `/mnt/c`, Docker, DNS |
| `tests/01-12` | inchangés hors 10 et 12 | aucun échec constaté |
| `config.env` | **B** | images Alpine 3.20 et OpenWrt 23.05 retirées du registre ; section `VM_*` (Multipass) retirée (sans usage sous WSL) |
| `cloud-init/*` | **retiré** | inutilisé sous WSL ; remplacé par `wsl/provision-wsl.sh` |
| `README.md`, `docs/*`, `gitbook/*` | **C** (fait) | Multipass/cloud-init remplacés par la préparation de l'hôte WSL ; diagrammes d'architecture, banc d'essai et schéma d'exécution ajoutés ; `docs/TROUBLESHOOTING.md` (section WSL) et `docs/ARCHITECTURE.md` relus et alignés sur le code ; Labs 01 et 99 du tutoriel alignés sur les scripts |
| `gitbook/preparation-hote/` | **C** (nouveau) | chapitre « Préparation de l'hôte » (9 étapes, PowerShell et Ubuntu) et « Dépannage WSL » (uniquement les 2 échecs rencontrés) |
| `.gitattributes` | **A** (nouveau) | force LF pour `.sh`, `.env`, `.yaml`, `.md` |
| `wsl/run-wsl-tests.ps1`, `wsl/provision-wsl.sh` | **A** (nouveaux) | banc d'essai déterministe |

## Mesure de base (lab actuel, scripts d'origine, distribution neuve)

| Essai | Résultat |
|---|---|
| 1 | Échec de tous les scripts : `/usr/bin/env: 'bash\r'`. Cause : copie de travail Windows en CRLF. Corrigé par `.gitattributes` (A) et conversion dans le banc d'essai. |
| 2 | Labs 00 à 05 réussis. Lab 06 : 5 échecs (`alpine/3.20`, `openwrt/23.05/amd64` introuvables). Labs 07 à 12 ignorés par dépendance, 99 réussi. 44 réussis, 5 échoués. |

## Corrections

| # | Classe | Symptôme | Cause racine | Fichiers |
|---|---|---|---|---|
| 1 | B | Lab 06 : `The requested image couldn't be found` | Les images `alpine/3.20` et `openwrt/23.05/amd64` n'existent plus sur `images.linuxcontainers.org` (vérifié : il reste `alpine/3.21` à `3.24` et `openwrt/25.12`, `openwrt/snapshot`) | `config.env`, `gitbook/reference.md`, `gitbook/les-flux-incus/{README,image,port-exposure}.md` |
| 2 | A | `bash\r` : fins de ligne CRLF | Extraction Windows sans `.gitattributes` | `.gitattributes`, `wsl/run-wsl-tests.ps1` |
| 3 | A | Aucun contrôle WSL | Le preflight ne vérifiait pas WSL 2, systemd, `/mnt/c`, Docker, DNS | `tests/00-preflight.sh` |

Choix des versions (à valider par l'enseignant) : Alpine **3.22** et OpenWrt **25.12** (seule version stable disponible). L'alias `openwrt23.05` devient `openwrt25.12`.

## Validation (phase 5, partielle)

| Critère | Résultat |
|---|---|
| Deux `sudo ./run-labs.sh --validate` sur deux distributions neuves issues du même tarball (scripts avec les propositions et corrections B) | 104 réussis, 0 échoué, 0 ignoré, deux fois |
| Comparaison des deux rapports JSON (test par test) | aucune différence |
| Chemin sans `sudo` (`sg incus-admin` avec arguments protégés) : `--check-images`, labs 05 à 07, `--reset 07` | réussi |
| `--learn` sans terminal (`< /dev/null`, lab 05) | ne bloque pas, code de sortie 0 |
| `--diff` (après correction) | compare les deux derniers rapports finalisés ; plus de rapport vide |
| `bash -n` sur tous les `.sh` | OK |
| `shellcheck` 0.9.0 | aucune erreur ; 8 avertissements préexistants (SC2034, SC2155, SC1090, SC2115 dans `10-file-transfer.sh`) non traités |
| Fins de ligne LF (`.sh`, `.env`, `.yaml`) dans la distribution | OK (après conversion par le banc d'essai) |
| YAML (`.gitbook.yaml`) | valide |
| Liens de `gitbook/SUMMARY.md` | non vérifié par outil (les deux nouvelles pages existent) |

Commandes : `.\wsl\run-wsl-tests.ps1 -Prepare` (une fois), puis `.\wsl\run-wsl-tests.ps1` (code de sortie non nul au moindre échec ou test ignoré).

## Réseau

Un `proxy device` Incus (`listen=tcp:0.0.0.0:8001`) est joignable depuis la distribution **et** depuis Windows (`curl.exe http://localhost:8001` renvoie le contenu du conteneur) en mode réseau NAT par défaut. Non testé : mode `mirrored`.

## Hypothèses de la mission : état

| # | État |
|---|---|
| 1 | Appliquée (proposition 1, `tests/_common.sh`) : comparaison exacte |
| 2, 3 | Appliquées (propositions 2 et 3) |
| 4 | Confirmée, corrigée (`reset_lab_artifacts`) |
| 5 | Confirmée, corrigée (teardown limité aux ressources du lab) |
| 6 | Infirmée (tout utilise `${HOME}`) |
| 7 | confirmée et constatée : corrigée (correction 1) |
| 8 | Appliquée (dépôt épinglé, `DEMO_APP_REF`) |
| 9 | règle appliquée : `--quick` non utilisé |
| 10 | prérequis alignés (préparation de l'hôte) |

Détail : `docs/WSL-PROPOSITIONS.md`. Bug supplémentaire trouvé en testant : `--diff` comparait un rapport vide (classe B).

## Différences avec la version Multipass

| Sujet | Multipass | WSL 2 |
|---|---|---|
| Machine | VM créée par cloud-init | distribution Ubuntu 24.04 importée depuis un tarball |
| Utilisateur | `student` (cloud-init) | `student` (`/etc/wsl.conf`, `[user] default`) |
| systemd | actif d'office | `[boot] systemd=true` dans `/etc/wsl.conf` |
| Paquets de base | `packages:` cloud-init | `wsl/provision-wsl.sh` |
| Dépôt | `/home/student/incus-lab` | `~/CR380-incus-lab`, jamais sous `/mnt/c` |
| Accès aux ports | IP de la VM | `localhost` Windows (NAT) |

## Décisions demandées à l'enseignant

1. Le dépôt est sur la branche `wsl-version` ; la mission parle de `wsl`. Confirmer la branche.
2. Valider Alpine 3.22 et OpenWrt 25.12 (le contenu du cours cite OpenWrt 23.05).

## Limites connues

- `git` est absent du shell de travail : aucun commit n'a pu être créé, l'état de l'arbre n'a pas pu être vérifié (non vérifié).
- Phase 4 : le chapitre `gitbook/preparation-hote/` est écrit. Vérifié par exécution : `wsl --install … --name … --no-launch` (Ubuntu 24.04 fournit déjà `systemd=true`, `git`, `curl`, `wget`, pas `jq`), `wsl -l -v`, `systemctl is-system-running`, refus du dépôt sous `/mnt/c` par le Lab 00 (14 contrôles). Non vérifié : premier lancement interactif (création d'utilisateur), `wsl --install Ubuntu-24.04` sans `--name`, `wsl --update`, `wsl --set-version`, détection du BIOS. Seuil de 20 Go sur `C:` : recommandation non mesurée.
- Les diagrammes Mermaid (`README.md`, `docs/ARCHITECTURE.md`, `docs/TEACHER-GUIDE.md`) ne sont pas rendus par GitBook ; le tutoriel `gitbook/` utilise un schéma texte. Rendu Mermaid vérifié seulement par relecture (non vérifié dans GitHub).
- Lab lancé par `sudo ./run-labs.sh` (campagnes complètes) ; le chemin sans `sudo` n'a été exécuté que sur `--check-images`, `--lab 05` à `07` et `--reset 07`.
