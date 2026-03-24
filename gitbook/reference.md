# Référence rapide

## Configuration du cours

Toutes les valeurs utilisées dans les labs sont centralisées dans le fichier `config.env` du dépôt.

### Images distantes

| Image | Identifiant distant | Alias local |
|-------|-------------------|-------------|
| Ubuntu 24.04 (Noble) | `images:ubuntu/noble/amd64` | `ubuntux64` |
| Alpine 3.20 | `images:alpine/3.20` | `alpinex64` |
| OpenWRT 23.05 | `images:openwrt/23.05/amd64` | `openwrt23.05` |
| Debian 12 | `images:debian/12` | `debian12` |

### Conteneurs

| Conteneur | Créé dans | Image source |
|-----------|-----------|-------------|
| `u1` | Lab 07 | `ubuntux64` |
| `cloneU1x64` | Lab 07 | `imgCustomU1x64` (supprimé dans le même lab) |
| `routerCT` | Lab 08 | `openwrt23.05` |
| `debianCT` | Lab 09 | `debian12` (supprimé après publication) |
| `nginxCT` | Lab 09 | `nginx-0.0.0` |
| `appwebCT` | Lab 11 | `demo-app-0.0.0` |

### Images publiées

| Alias | Créée dans | Base |
|-------|-----------|------|
| `imgCustomU1x64` | Lab 07 | Conteneur `u1` |
| `nginx-0.0.0` | Lab 09 | Conteneur `debianCT` (Debian + nginx + UFW) |
| `demo-app-0.0.0` | Lab 10 | Conteneur `nginxCT` (nginx + app démo) |

### Réseau et stockage

| Ressource | Nom | Type | Créée dans |
|-----------|-----|------|-----------|
| Pool initial | `cr380storagepool` | `dir` | Lab 04 (preseed) |
| Pont réseau | `cr380incusbr0` | `bridge` (IPv4 auto) | Lab 04 (preseed) |
| Pool avancé | `websrv_storage` | `dir` → `~/websrv_dir` | Lab 11 |
| Volume | `www_volume` | custom | Lab 12 |

### Ports exposés

| Port hôte | Port conteneur | Conteneur | Service | Lab |
|-----------|----------------|-----------|---------|-----|
| 8888 | 80 | `routerCT` | OpenWRT LuCI | Lab 08 |
| 8000 | 80 | `nginxCT` | nginx | Lab 09 |
| 8001 | 80 | `appwebCT` | nginx (demo-app) | Lab 11 |

---

## Dépannage

### 1. `fatal: The group 'incus-admin' does not exist`

{% hint style="danger" %}
Le groupe `incus-admin` a été supprimé (Lab 01) et n'a pas été recréé lors de la réinstallation. Le paquet Ubuntu ne recrée pas ce groupe automatiquement.
{% endhint %}

```bash
# Créer le groupe manuellement
sudo addgroup --system incus-admin

# Redémarrer le service (il échoue sans ce groupe)
sudo systemctl reset-failed incus
sudo systemctl restart incus
```

Voir Lab 02 — Étape 3 pour plus de détails.

### 2. `Permission denied` lors de l'accès à Incus

{% hint style="warning" %}
Votre utilisateur n'est pas dans le groupe `incus-admin`, ou le groupe n'est pas encore actif.
{% endhint %}

```bash
# Vérifier le groupe
getent group incus-admin

# Ajouter l'utilisateur
sudo adduser $USER incus-admin

# Activer sans déconnexion
sg incus-admin -c "incus info"
```

### 3. Téléchargement d'image expiré (timeout)

{% hint style="warning" %}
Votre connexion Internet est lente ou le serveur d'images est temporairement indisponible.
{% endhint %}

```bash
# Tester la connectivité
ping -c3 images.linuxcontainers.org

# Réessayer le téléchargement
incus image copy images:ubuntu/noble/amd64 local: --alias ubuntux64 --auto-update
```

### 4. Port déjà utilisé (`address already in use`)

{% hint style="warning" %}
Un autre conteneur ou processus utilise déjà le port.
{% endhint %}

```bash
# Trouver le processus
sudo ss -tlnp | grep :8888

# Retirer le proxy device existant
incus config device remove routerCT monport80vers8888
```

### 5. Conteneur ne démarre pas (déjà existant)

{% hint style="warning" %}
Un conteneur avec le même nom existe déjà d'un lab précédent.
{% endhint %}

```bash
# Vérifier
incus list

# Supprimer et relancer
incus delete --force u1
incus launch ubuntux64 u1
```

### 6. Bridge réseau persiste après désinstallation

{% hint style="warning" %}
L'interface réseau `cr380incusbr0` peut persister même après la purge d'Incus.
{% endhint %}

```bash
# Vérifier
ip link show cr380incusbr0

# Supprimer manuellement
sudo ip link set cr380incusbr0 down
sudo ip link delete cr380incusbr0
```

### 7. `hash incus` cache après suppression

{% hint style="warning" %}
Bash met en cache l'emplacement des commandes. Après la désinstallation d'incus, `which incus` peut encore le trouver.
{% endhint %}

```bash
hash -r   # Vider le cache
which incus   # Devrait maintenant échouer
```

### 8. Suite de tests : « already running »

{% hint style="info" %}
Si `run-labs.sh` signale qu'une instance est déjà en cours, arrêtez tous les processus liés, puis relancez.
{% endhint %}

```bash
sudo ./run-labs.sh --lab 99   # Nettoyage complet
sudo ./run-labs.sh --validate # Relancer la validation
```
