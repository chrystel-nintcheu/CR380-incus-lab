# Lab 11 — Stockage

{% hint style="info" %}
**Objectif** : Créer un pool de stockage de type `dir`, lancer un conteneur dessus et vérifier l'association.
{% endhint %}

{% tabs %}
{% tab title="Français" %}
Les « pools de stockage » dans Incus définissent où les données des conteneurs sont physiquement stockées. Types supportés :

- **dir** : simple répertoire sur le système de fichiers
- **zfs** : ZFS pool (snapshots, compression)
- **btrfs** : Btrfs subvolume
- **lvm** : Logical Volume Manager

Nous créons un pool de type `dir` pointant vers un répertoire local.
{% endtab %}
{% tab title="English" %}
Storage pools in Incus define where container data is physically stored. Supported types:

- **dir**: simple directory on the filesystem
- **zfs**: ZFS pool (snapshots, compression)
- **btrfs**: Btrfs subvolume
- **lvm**: Logical Volume Manager

We create a `dir` type pool pointing to a local directory.
{% endtab %}
{% endtabs %}

## Étape 1 : Créer le répertoire

{% tabs %}
{% tab title="Français" %}
Créons d'abord le répertoire qui servira de base au pool de stockage.
{% endtab %}
{% tab title="English" %}
First, let's create the directory that will serve as the storage pool's base.
{% endtab %}
{% endtabs %}

```bash
mkdir -p ~/websrv_dir
```

## Étape 2 : Créer le pool de stockage

{% tabs %}
{% tab title="Français" %}
Ceci crée un pool de stockage nommé `websrv_storage` de type `dir` qui utilise le répertoire `~/websrv_dir`.
{% endtab %}
{% tab title="English" %}
This creates a storage pool named `websrv_storage` of type `dir` using the directory `~/websrv_dir`.
{% endtab %}
{% endtabs %}

```bash
incus storage create websrv_storage dir source=$HOME/websrv_dir
```

```bash
incus storage list
```

{% hint style="success" %}
**Résultat attendu** : Le pool `websrv_storage` apparaît dans `incus storage list`.
{% endhint %}

## Étape 3 : Arrêter les conteneurs et lancer sur le nouveau pool

{% tabs %}
{% tab title="Français" %}
Nous arrêtons tous les conteneurs et lançons un nouveau conteneur `appwebCT` depuis l'image `demo-app-0.0.0` en utilisant notre nouveau pool de stockage.
{% endtab %}
{% tab title="English" %}
We stop all containers and launch a new container `appwebCT` from the `demo-app-0.0.0` image using our new storage pool.
{% endtab %}
{% endtabs %}

```bash
incus stop --all
incus launch demo-app-0.0.0 appwebCT -s websrv_storage
```

## Étape 4 : Exposer le port et vérifier

```bash
incus config device add appwebCT monport80vers8001 proxy \
  listen=tcp:0.0.0.0:8001 connect=tcp:127.0.0.1:80
```

```bash
incus config show appwebCT
incus storage show websrv_storage
```

{% hint style="success" %}
**Résultat attendu** :

- `incus config show appwebCT` montre le device proxy et le root pool `websrv_storage`
- `incus storage show websrv_storage` montre `appwebCT` dans la section `used_by`
{% endhint %}
