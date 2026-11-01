# Dépannage / Troubleshooting

## Erreurs fréquentes / Common Errors

### 1. `E: Could not get lock /var/lib/dpkg/lock-frontend`

**Cause**: Un autre processus apt est en cours d'exécution.
Another apt process is running.

**Solution**:
```bash
# Attendre que le processus termine / Wait for it to finish
sudo lsof /var/lib/dpkg/lock-frontend

# Ou forcer la libération (ATTENTION: seulement si apt n'est plus actif)
# Or force release (WARNING: only if apt is not actively running)
sudo rm -f /var/lib/dpkg/lock-frontend
sudo dpkg --configure -a
```

---

### 2. `Error: not found` (container ou image)

**Cause**: Le conteneur ou l'image n'existe pas.
The container or image doesn't exist.

**Solution**:
```bash
# Vérifier les conteneurs / Check containers
incus list

# Vérifier les images / Check images
incus image list

# Vérifier les alias / Check aliases
incus image alias list
```

---

### 3. Timeout lors du téléchargement d'images / Image download timeout

**Cause**: Connexion Internet lente ou serveur d'images surchargé.
Slow internet or overloaded image server.

**Solution**:
```bash
# Vérifier la connectivité / Check connectivity
ping -c 3 images.linuxcontainers.org

# Augmenter le timeout dans config.env / Increase timeout in config.env
vim config.env
# Modifier TIMEOUT_DOWNLOAD=600

# Réessayer le lab des images / Retry the images lab
sudo ./run-labs.sh --reset 06
```

---

### 4. `Error: Permission denied` / Permission refusée

**Cause**: L'utilisateur n'est pas dans le groupe `incus-admin`.
User is not in the `incus-admin` group.

**Solution**:
```bash
# Ajouter l'utilisateur au groupe / Add user to group
sudo adduser $USER incus-admin

# IMPORTANT: la session doit être renouvelée. Sous WSL, dans PowerShell :
# IMPORTANT: the session must be renewed. Under WSL, in PowerShell:
#   wsl --terminate Ubuntu-24.04
# puis rouvrez Ubuntu / then reopen Ubuntu

# Vérifier / Verify
groups | grep incus-admin
```

Sans attendre, `sg incus-admin -c "incus list"` fonctionne dans la session courante.

---

### 5. `Error: Address already in use` (port conflict)

**Cause**: Le port est déjà utilisé par un autre processus.
The port is already in use by another process.

**Solution**:
```bash
# Trouver le processus / Find the process
sudo ss -tlnp | grep :8888

# Changer le port dans config.env ou arrêter le processus
# Change port in config.env or stop the process
```

---

### 6. Container stuck in STOPPED state

**Cause**: Le conteneur n'a pas pu démarrer (erreur de configuration).
Container failed to start (configuration error).

**Solution**:
```bash
# Voir les logs du conteneur / See container logs
incus info <container-name> --show-log

# Essayer de démarrer / Try to start
incus start <container-name>

# Si ça ne fonctionne pas: supprimer et recréer
# If it doesn't work: delete and recreate
incus delete --force <container-name>
```

---

### 7. `Error: Storage pool not found`

**Cause**: Le pool de stockage n'a pas été créé ou a été supprimé.
Storage pool was not created or was deleted.

**Solution**:
```bash
# Lister les pools / List pools
incus storage list

# Recréer si nécessaire / Recreate if needed
sudo ./run-labs.sh --reset 04
```

---

### 8. `newgrp` in scripts doesn't work

**Cause**: `newgrp` opens a new shell and breaks script execution.

**Solution**: The test suite uses `sg incus-admin -c "command"` instead.
If you're testing manually, use:
```bash
sg incus-admin -c "incus list"
# OR: log out and log back in after adduser
```

---

### 9. `incus admin init` fails with "already initialized"

**Cause**: Incus was already initialized from a previous run.

**Solution**:
```bash
# Nettoyer complètement / Clean completely
sudo ./run-labs.sh --reset 01
# Puis réexécuter / Then rerun
sudo ./run-labs.sh --lab 04
```

---

### 10. Less than 10 GB free disk space

**Cause**: Le disque virtuel (VHDX) de la distribution WSL est plein, ou `C:` n'a plus de place (le VHDX grandit avec les images et conteneurs).
The WSL distribution's virtual disk is full, or `C:` is running out of space (the VHDX grows with images and containers).

**Solution**:
```bash
# Vérifier l'espace / Check space
df -h /

# Nettoyer les images inutilisées / Clean unused images
incus image list
incus image delete <unused-alias>

# Nettoyer apt / Clean apt cache
sudo apt clean
```

---

### 11. `git clone` fails (demo app repository)

**Cause**: The repository URL may have changed or is not accessible.

**Solution**:
```bash
# Vérifier l'URL / Check URL
echo $DEMO_APP_REPO

# Tester manuellement / Test manually
git ls-remote $DEMO_APP_REPO

# Mettre à jour dans config.env si nécessaire
# Update in config.env if needed
```

---

### 12. Tests show SKIPPED for everything

**Cause**: An early test (00-04) failed, causing all dependent tests to skip.

**Solution**:
```bash
# Voir quel test a échoué / See which test failed
sudo ./run-labs.sh --validate 2>&1 | grep "✗"

# Corriger le problème, puis relancer
# Fix the issue, then rerun
sudo ./run-labs.sh --validate
```

---

## Logs et rapports / Logs and Reports

```bash
# Voir le dernier log / View latest log
ls -t logs/ | head -1 | xargs -I{} cat logs/{}

# Voir le dernier rapport / View latest report
ls -t results/ | head -1 | xargs -I{} cat results/{}

# Comparer les rapports / Compare reports
sudo ./run-labs.sh --diff
```

## Contact

Si aucune solution ne fonctionne, contactez votre enseignant avec:
If no solution works, contact your teacher with:

1. Le log complet (`logs/test-*.log`)
2. La sortie de la commande qui échoue
3. La version d'Ubuntu (`lsb_release -a`) et, depuis PowerShell, `wsl --version` et `wsl -l -v`
4. L'espace disque disponible (`df -h /`) et la version de Windows (`winver`)

---

## Problèmes avancés / Advanced Issues

### 13. Interface bridge persistante après désinstallation / Bridge interface persists after uninstall

**Cause**: Les interfaces Linux bridge survivent à la désinstallation du paquet.
Linux bridge interfaces persist across package reinstalls.

**Solution**:
```bash
sudo ip link set cr380incusbr0 down 2>/dev/null || true
sudo ip link delete cr380incusbr0 2>/dev/null || true
# Puis réinitialiser / Then reinitialize
sudo ./run-labs.sh --reset 04
```

---

### 14. Commande introuvable après suppression du paquet / Command still found after package removal

**Cause**: Le shell met en cache les chemins des binaires dans une table de hachage.
The shell caches binary paths in a hash table.

**Solution**:
```bash
hash -r        # Vider le cache (Bash/Zsh) / Clear cache (Bash/Zsh)
which incus    # Devrait retourner "not found" / Should return "not found"
```

---

### 15. "Error: already running" lors du lancement d'un conteneur / Container "already running" on launch

**Cause**: Sur les images à démarrage rapide (ex: OpenWRT), `incus launch` peut démarrer automatiquement le conteneur avant la commande explicite de démarrage.
On fast-booting images (e.g., OpenWRT), `incus launch` may auto-start the container before the explicit start command.

**Solution**: Ce comportement est normal et géré par le framework de test. Si vous voyez cette erreur en mode manuel :
This is normal and handled by the test framework. If you see this error manually:
```bash
# Le conteneur est déjà en cours d'exécution / Container is already running
incus list <container-name>
```

---

## Problèmes propres à WSL / WSL-specific issues

Les contrôles du Lab 00 (`sudo ./run-labs.sh --lab 00`) détectent la plupart de ces cas et affichent un **HINT**. Voir aussi [Dépannage WSL](../gitbook/preparation-hote/depannage-wsl.md).
Lab 00 (`sudo ./run-labs.sh --lab 00`) detects most of these cases and prints a **HINT**.

### 16. `WSL: WSL 1 détecté` ou `environnement non WSL détecté`

**Cause**: La distribution tourne sous WSL 1 (pas de vrai noyau Linux) ou le lab est lancé hors de WSL.
The distribution runs on WSL 1 (no real Linux kernel) or the lab is run outside WSL.

**Solution** (PowerShell):
```powershell
wsl -l -v                              # VERSION doit être 2 / must be 2
wsl --set-version Ubuntu-24.04 2
```

---

### 17. `systemd: non actif`

**Cause**: systemd n'est pas activé dans la distribution. Incus est un service systemd.
systemd is not enabled. Incus is a systemd service.

**Solution**:
```bash
# /etc/wsl.conf doit contenir / must contain:
#   [boot]
#   systemd=true
sudo nano /etc/wsl.conf
```
Puis, dans PowerShell : `wsl --shutdown`, et rouvrez Ubuntu. / Then in PowerShell: `wsl --shutdown`, and reopen Ubuntu.

---

### 18. `Dépôt: ... est sur le disque Windows`

**Cause**: Le dépôt est sous `/mnt/c/...`. Permissions, fins de ligne et vitesse d'accès y diffèrent.
The repository is under `/mnt/c/...`.

**Solution**:
```bash
cd ~
git clone -b wsl-version https://github.com/chrystel-nintcheu/CR380-incus-lab.git
cd CR380-incus-lab
```

---

### 19. `/usr/bin/env: 'bash\r': No such file or directory`

**Cause**: Fins de ligne Windows (CRLF), par exemple après un téléchargement ZIP. Le dépôt cloné depuis Ubuntu les force en LF (`.gitattributes`).
Windows line endings (CRLF), e.g. after a ZIP download. A clone made from Ubuntu forces LF.

**Solution**: Reclonez le dépôt depuis Ubuntu (voir #18). / Clone the repository again from Ubuntu (see #18).

---

### 20. Les conteneurs n'ont ni Internet ni DNS / Containers have no Internet or DNS

**Cause**: Docker (ou un pare-feu) actif dans la même distribution modifie les règles réseau; le Lab 00 affiche un avertissement « Docker détecté ». Le DNS de WSL peut aussi être à relancer.
Docker (or a firewall) active in the same distribution changes network rules; Lab 00 prints a "Docker détecté" warning. WSL DNS may also need a restart.

**Solution**:
```bash
sudo systemctl disable --now docker      # si Docker est présent / if Docker is present
getent hosts images.linuxcontainers.org  # doit répondre / must answer
```
Si le DNS ne répond pas : `wsl --shutdown` (PowerShell), puis rouvrez Ubuntu. / If DNS does not answer: `wsl --shutdown` (PowerShell), then reopen Ubuntu.

---

### 21. Un port exposé n'est pas joignable depuis Windows / Exposed port not reachable from Windows

**Cause**: Le `proxy device` n'existe pas, ou le mode réseau de WSL n'est pas le mode NAT par défaut (le mode `mirrored` n'a pas été testé).
The proxy device is missing, or WSL networking is not the default NAT mode (`mirrored` mode was not tested).

**Solution**:
```bash
incus config show nginxCT | grep -A4 monport80vers8000   # le device existe-t-il ? / does the device exist?
curl -s http://localhost:8000 | head -3                   # depuis Ubuntu / from Ubuntu
```
Depuis PowerShell : `curl.exe http://localhost:8000`. Ports du lab : 8888 (`routerCT`), 8000 (`nginxCT`), 8001 (`appwebCT`).
