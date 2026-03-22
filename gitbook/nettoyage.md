# Lab 99 — Nettoyage final

{% hint style="info" %}
**Objectif** : Nettoyer complètement l'environnement de lab pour retrouver un état propre.
{% endhint %}

{% tabs %}
{% tab title="Français" %}
Ce script nettoie TOUT ce qui a été créé pendant les labs :

- Arrête et supprime tous les conteneurs
- Supprime toutes les images personnalisées
- Supprime les volumes et pools de stockage
- Supprime les fichiers temporaires

Votre système sera comme avant les labs.
{% endtab %}
{% tab title="English" %}
This script cleans up EVERYTHING created during the labs:

- Stops and deletes all containers
- Deletes all custom images
- Deletes volumes and storage pools
- Removes temporary files

Your system will be like before the labs.
{% endtab %}
{% endtabs %}

## Étape 1 : Arrêter et supprimer tous les conteneurs

```bash
incus stop --all --force
```

Supprimer chaque conteneur :

```bash
incus delete --force u1
incus delete --force routerCT
incus delete --force nginxCT
incus delete --force appwebCT
```

## Étape 2 : Supprimer les images personnalisées

```bash
incus image delete imgCustomU1x64
incus image delete nginx-0.0.0
incus image delete demo-app-0.0.0
```

## Étape 3 : Supprimer les volumes

```bash
incus storage volume delete websrv_storage www_volume
```

## Étape 4 : Supprimer les pools de stockage

```bash
incus storage delete websrv_storage
```

## Étape 5 : Nettoyer les fichiers temporaires

```bash
rm -rf ~/websrv_dir
rm -rf ml-app html.bkp index.html
rm -f index.nginx-debian.html
```

## Étape 6 : Vérifier

```bash
incus ls                    # Devrait être vide
incus image ls              # Devrait ne montrer que les images de base
incus storage list          # Devrait montrer uniquement cr380storagepool
incus storage volume list websrv_storage  # Devrait échouer (pool supprimé)
```

{% hint style="success" %}
**Résultat attendu** : Aucun conteneur, aucune image personnalisée, aucun volume. Seul le pool `cr380storagepool` et les images de base (si non supprimées) restent.
{% endhint %}
