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

# IMPORTANT: Déconnectez-vous et reconnectez-vous pour rafraîchir les groupes
# IMPORTANT: Log out and log back in to refresh groups
exit
# reconnectez-vous / reconnect

# Vérifier / Verify
groups | grep incus-admin
```

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

### 10. VM has less than 10GB free disk space

**Cause**: The VM disk is too small or is full.

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
3. La version d'Ubuntu (`lsb_release -a`)
4. L'espace disque disponible (`df -h /`)
