# Lab 12 — Volumes

{% hint style="info" %}
**Objectif** : Créer un volume persistant, l'attacher à un conteneur et y déployer une application.
{% endhint %}

{% tabs %}
{% tab title="Français" %}
Un « volume » Incus est un espace de stockage persistant qui peut être attaché à un ou plusieurs conteneurs. Contrairement au filesystem du conteneur, les données dans un volume survivent à la suppression du conteneur.

C'est similaire aux « Docker volumes ».
{% endtab %}
{% tab title="English" %}
An Incus 'volume' is a persistent storage space that can be attached to one or more containers. Unlike the container's filesystem, data in a volume survives container deletion.

This is similar to 'Docker volumes'.
{% endtab %}
{% endtabs %}

## Étape 1 : Créer un volume

{% tabs %}
{% tab title="Français" %}
Ceci crée un volume nommé `www_volume` dans le pool `websrv_storage`.
{% endtab %}
{% tab title="English" %}
This creates a volume named `www_volume` in pool `websrv_storage`.
{% endtab %}
{% endtabs %}

```bash
incus storage volume create websrv_storage www_volume
incus storage volume list websrv_storage
```

{% hint style="success" %}
**Résultat attendu** : Le volume `www_volume` apparaît dans la liste des volumes du pool `websrv_storage`.
{% endhint %}

## Étape 2 : Attacher le volume au conteneur

{% tabs %}
{% tab title="Français" %}
Ceci monte le volume `www_volume` au chemin `/var/www` dans le conteneur.
{% endtab %}
{% tab title="English" %}
This mounts the volume `www_volume` at `/var/www` in the container.
{% endtab %}
{% endtabs %}

```bash
incus storage volume attach websrv_storage www_volume appwebCT /var/www
```

{% hint style="warning" %}
**Important** : Le contenu précédent de `/var/www` sera masqué par le volume. Le volume est initialement vide — nous devrons y copier l'application.
{% endhint %}

## Étape 3 : Vérifier l'association

```bash
incus storage volume show websrv_storage www_volume
```

{% hint style="success" %}
**Résultat attendu** : Le champ `used_by` montre que le volume est utilisé par `appwebCT`.
{% endhint %}

## Étape 4 : Ajuster les permissions

{% tabs %}
{% tab title="Français" %}
Le volume est stocké dans `~/websrv_dir/custom/`. Nous devons ajuster les permissions pour que le serveur web dans le conteneur puisse lire les fichiers.
{% endtab %}
{% tab title="English" %}
The volume is stored in `~/websrv_dir/custom/`. We need to adjust permissions so the web server in the container can read the files.
{% endtab %}
{% endtabs %}

```bash
sudo chmod -R 777 ~/websrv_dir/custom
```

{% hint style="warning" %}
`777` est utilisé ici pour simplifier. En production, utilisez des permissions plus restrictives.
{% endhint %}

## Étape 5 : Déployer l'application dans le volume

{% tabs %}
{% tab title="Français" %}
Nous clonons l'application de démo directement dans le répertoire du volume pour que le conteneur puisse la servir.
{% endtab %}
{% tab title="English" %}
We clone the demo app directly into the volume directory so the container can serve it.
{% endtab %}
{% endtabs %}

```bash
git clone https://github.com/nintcheu/dog-breed-recognition.git \
  ~/websrv_dir/custom/default_www_volume/html
```

## Concept clé

{% tabs %}
{% tab title="Français" %}
Les données du volume sont maintenant accessibles au conteneur. Même si le conteneur `appwebCT` est supprimé, les données dans le volume `www_volume` sont préservées.

**C'est le concept clé de la persistance avec les volumes !**
{% endtab %}
{% tab title="English" %}
The volume data is now accessible to the container. Even if the container `appwebCT` is deleted, the data in the volume `www_volume` is preserved.

**This is the key concept of persistence with volumes!**
{% endtab %}
{% endtabs %}
