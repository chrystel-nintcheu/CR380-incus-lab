# Préparation de l'hôte (Windows et WSL 2)

{% hint style="info" %}
**Objectif** : Préparer votre ordinateur Windows 10 ou 11 pour qu'il exécute une distribution Ubuntu 24.04 sous WSL 2. Les labs 00 à 12 se déroulent ensuite **dans Ubuntu**, avec exactement les mêmes commandes que dans le reste de ce guide.
{% endhint %}

## Où taper les commandes

Cette page utilise deux terminaux. Vérifiez toujours lequel est ouvert avant de copier une commande.

| Terminal | Comment l'ouvrir | Invite typique |
|----------|------------------|----------------|
| **PowerShell** (Windows) | Menu Démarrer, taper `PowerShell` | `PS C:\Users\vous>` |
| **PowerShell en administrateur** | Clic droit sur PowerShell, « Exécuter en tant qu'administrateur » | `PS C:\Windows\system32>` |
| **Ubuntu** (Linux) | Menu Démarrer, taper `Ubuntu 24.04` | `vous@NOM-PC:~$` |

{% hint style="warning" %}
Les commandes qui commencent par `wsl` se tapent dans **PowerShell**. Les commandes `sudo`, `apt`, `git` et `./run-labs.sh` se tapent dans **Ubuntu**.
{% endhint %}

## Étape 1 : Vérifier votre ordinateur

| Élément | Exigence | Comment vérifier |
|---------|----------|------------------|
| Windows | Windows 10 version 2004 (build 19041) ou plus récente, ou Windows 11 | Touche Windows + R, taper `winver` |
| Virtualisation | Activée dans le BIOS/UEFI | Gestionnaire des tâches, onglet **Performances**, **Processeur** : « Virtualisation : Activée » |
| Droits | Compte administrateur pour la première installation | Une fenêtre « Contrôle de compte d'utilisateur » apparaît à l'installation |
| Disque | Au moins 20 Go libres sur `C:` (recommandation de l'enseignant) | Explorateur de fichiers, **Ce PC** |
| Internet | Accès à `linuxcontainers.org` | Navigateur |

{% hint style="warning" %}
Si la virtualisation est « Désactivée », activez-la dans le BIOS/UEFI de votre ordinateur avant de continuer. La procédure dépend du fabricant : consultez sa documentation ou demandez à votre enseignant.
{% endhint %}

{% hint style="info" %}
**Docker Desktop** : si Docker est installé sur le même poste, il peut priver les conteneurs Incus d'Internet. Le Lab 00 vous avertira si Docker est actif dans Ubuntu.
{% endhint %}

## Étape 2 : Installer WSL et Ubuntu 24.04

Dans **PowerShell en administrateur** :

```powershell
wsl --install Ubuntu-24.04
```

{% hint style="success" %}
**Résultat attendu** : WSL télécharge et installe « Ubuntu 24.04 LTS ». Si Windows vous demande de **redémarrer**, redémarrez, puis ouvrez **Ubuntu 24.04** depuis le menu Démarrer.
{% endhint %}

{% hint style="info" %}
- Si cette commande affiche seulement l'aide de `wsl`, WSL est déjà installé : lancez `wsl --list --online` pour voir les noms valides, puis `wsl --install -d Ubuntu-24.04`.
- Si l'installation reste bloquée à 0 %, lancez `wsl --install --web-download -d Ubuntu-24.04`.
{% endhint %}

## Étape 3 : Créer votre utilisateur Linux

Au premier lancement, la fenêtre Ubuntu vous demande :

1. un **nom d'utilisateur** (en minuscules, sans espaces) ;
2. un **mot de passe** (rien ne s'affiche pendant la saisie, c'est normal).

Ce mot de passe sert à chaque commande `sudo`. Notez-le.

## Étape 4 : Vérifier que Ubuntu utilise WSL 2

Dans **PowerShell** :

```powershell
wsl -l -v
```

{% hint style="success" %}
**Résultat attendu** : une ligne `Ubuntu-24.04` avec la colonne `VERSION` à **2**. Si le nom affiché est différent (par exemple `Ubuntu`), utilisez ce nom dans toutes les commandes `wsl` de cette page.
{% endhint %}

Si la colonne `VERSION` indique `1`, convertissez la distribution (Incus ne fonctionne pas sous WSL 1) :

```powershell
wsl --set-version Ubuntu-24.04 2
```

## Étape 5 : Mettre WSL à jour

Dans **PowerShell** :

```powershell
wsl --update
wsl --version
```

{% hint style="success" %}
**Résultat attendu** : `wsl --version` affiche la version de WSL et celle du noyau. Si `wsl --version` n'est pas reconnue, vous avez une ancienne version de WSL : `wsl --update` est alors indispensable, car systemd (exigé par Incus) n'y est pas pris en charge.
{% endhint %}

## Étape 6 : Vérifier Ubuntu et systemd

Dans **Ubuntu** :

```bash
lsb_release -ds
systemctl is-system-running
```

{% hint style="success" %}
**Résultat attendu** : `Ubuntu 24.04.x LTS`, puis `running`.
{% endhint %}

{% hint style="info" %}
**Pourquoi systemd ?** Incus est un service géré par systemd. Avec une installation récente de WSL, Ubuntu 24.04 l'active déjà.
{% endhint %}

Si la deuxième commande répond autre chose que `running` ou `degraded`, activez systemd :

```bash
sudo nano /etc/wsl.conf
```

Le fichier doit contenir :

```ini
[boot]
systemd=true
```

Enregistrez (Ctrl+O, Entrée), quittez (Ctrl+X), puis dans **PowerShell** :

```powershell
wsl --shutdown
```

Rouvrez **Ubuntu 24.04** et relancez `systemctl is-system-running`.

## Étape 7 : Vérifier les outils

Dans **Ubuntu** :

```bash
sudo apt update
sudo apt install -y git curl wget jq
```

{% hint style="info" %}
`git`, `curl` et `wget` sont exigés par le Lab 00. `jq` est facultatif : il sert à `./run-labs.sh --diff`.
{% endhint %}

## Étape 8 : Récupérer le dépôt dans le système de fichiers Linux

Dans **Ubuntu** :

```bash
cd ~
git clone -b wsl-version https://github.com/chrystel-nintcheu/CR380-incus-lab.git
cd CR380-incus-lab
pwd
```

{% hint style="success" %}
**Résultat attendu** : `pwd` affiche `/home/<votre-utilisateur>/CR380-incus-lab`.
{% endhint %}

{% hint style="danger" %}
Ne placez **jamais** le dépôt sous `/mnt/c/...` (votre disque Windows) : les permissions et les fins de ligne y diffèrent, et les scripts échouent. Le Lab 00 refuse de continuer dans ce cas.
{% endhint %}

## Étape 9 : Vérifier votre hôte avec le Lab 00

Dans **Ubuntu**, depuis `~/CR380-incus-lab` :

```bash
sudo ./run-labs.sh --lab 00
```

{% hint style="success" %}
**Résultat attendu** : `LAB 00 PASSED (14 checks)`. Chaque contrôle qui échoue affiche un **HINT** qui indique la correction. Vous pouvez ensuite suivre les labs 01 à 99.
{% endhint %}

Contrôles propres à WSL :

| Contrôle | Ce qu'il vérifie |
|----------|------------------|
| WSL | La distribution tourne sous WSL 2 |
| systemd | `systemctl is-system-running` répond `running` (ou `degraded`) |
| Dépôt | Le dépôt n'est pas sous `/mnt` |
| Docker | Avertissement si Docker est présent |
| DNS | `images.linuxcontainers.org` se résout |

## Différences à connaître sous WSL

| Sujet | Ce qu'il faut savoir |
|-------|----------------------|
| Fermer Ubuntu | Fermer la fenêtre n'arrête pas forcément la distribution. Pour la redémarrer : `wsl --terminate Ubuntu-24.04` (PowerShell) |
| Tout arrêter | `wsl --shutdown` arrête toutes les distributions WSL |
| Groupe `incus-admin` | Après `sudo adduser $USER incus-admin` (Lab 03), le groupe n'est actif qu'après une **nouvelle session** : `wsl --terminate Ubuntu-24.04`, puis rouvrez Ubuntu |
| Ports exposés (Labs 08, 09, 11) | Un port exposé par un `proxy device` (par exemple 8000) est accessible depuis Windows avec `http://localhost:8000` (mode réseau NAT par défaut de WSL) |
| Espace disque | Le disque virtuel d'Ubuntu grandit avec vos images et conteneurs, sur `C:` |

## Repartir de zéro

{% hint style="danger" %}
`wsl --unregister` **supprime définitivement** la distribution et tous ses fichiers (dépôt, conteneurs, images). N'utilisez cette commande que si votre enseignant vous le demande.
{% endhint %}

Dans **PowerShell** :

```powershell
wsl --unregister Ubuntu-24.04
wsl --install Ubuntu-24.04
```

Reprenez ensuite à l'étape 3.

## Si quelque chose ne va pas

Consultez le [Dépannage WSL](depannage-wsl.md).
