# Lab 06 — Images

{% hint style="info" %}
**Objectif** : Maîtriser le cycle de vie complet des images Incus — rechercher, filtrer, télécharger avec alias, lister et supprimer.
{% endhint %}

{% tabs %}
{% tab title="Français" %}
Le cycle de vie d'une image :

1. Rechercher dans le registre (`incus image list images:...`)
2. Filtrer par distribution et architecture
3. Télécharger avec un alias local
4. Utiliser l'alias pour lancer des conteneurs

Nous allons pratiquer chaque étape.
{% endtab %}
{% tab title="English" %}
The image lifecycle:

1. Search in the registry (`incus image list images:...`)
2. Filter by distribution and architecture
3. Download with a local alias
4. Use the alias to launch containers

We will practice each step.
{% endtab %}
{% endtabs %}

## Étape 1 : Rechercher une image

{% tabs %}
{% tab title="Français" %}
Ceci recherche toutes les images contenant « kali » dans le registre distant.
{% endtab %}
{% tab title="English" %}
This searches for all images containing 'kali' in the remote registry.
{% endtab %}
{% endtabs %}

```bash
incus image list images:kali
```

## Étape 2 : Filtrer par distribution et architecture

{% tabs %}
{% tab title="Français" %}
On peut filtrer par distribution ET architecture en ajoutant des mots-clés.
{% endtab %}
{% tab title="English" %}
You can filter by distribution AND architecture by adding keywords.
{% endtab %}
{% endtabs %}

```bash
incus image list images:ubuntu/noble amd64
```

## Étape 3 : Télécharger les images avec alias

{% tabs %}
{% tab title="Français" %}
Télécharge l'image et lui attribue un alias pour usage local. Le flag `--auto-update` garde l'image à jour automatiquement.
{% endtab %}
{% tab title="English" %}
Downloads the image and assigns an alias for local use. The `--auto-update` flag keeps the image automatically up to date.
{% endtab %}
{% endtabs %}

```bash
incus image copy images:ubuntu/noble/amd64 local: --alias ubuntux64 --auto-update
incus image copy images:alpine/3.20 local: --alias alpinex64 --auto-update
incus image copy images:openwrt/23.05/amd64 local: --alias openwrt23.05 --auto-update
incus image copy images:debian/12 local: --alias debian12 --auto-update
```

{% hint style="warning" %}
Le téléchargement peut prendre plusieurs minutes selon votre connexion Internet. Si le téléchargement expire, vérifiez votre connexion avec `ping linuxcontainers.org`.
{% endhint %}

## Étape 4 : Vérifier les images locales

{% tabs %}
{% tab title="Français" %}
Vérifions que toutes les images sont bien téléchargées localement.
{% endtab %}
{% tab title="English" %}
Let's verify that all images have been downloaded locally.
{% endtab %}
{% endtabs %}

```bash
incus image ls
```

{% hint style="success" %}
**Résultat attendu** : Les quatre alias apparaissent dans la liste : `ubuntux64`, `alpinex64`, `openwrt23.05`, `debian12`.
{% endhint %}

## Étape 5 : Supprimer une image

{% tabs %}
{% tab title="Français" %}
Supprimons l'image Alpine pour pratiquer la gestion des images.
{% endtab %}
{% tab title="English" %}
Let's delete the Alpine image to practice image management.
{% endtab %}
{% endtabs %}

```bash
incus image delete alpinex64
incus image ls
```

{% hint style="success" %}
**Résultat attendu** : L'alias `alpinex64` n'apparaît plus dans la liste. Il reste trois images : `ubuntux64`, `openwrt23.05`, `debian12`.
{% endhint %}
