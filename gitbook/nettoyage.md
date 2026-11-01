# Lab 99 — Nettoyage final

{% hint style="info" %}
**Objectif** : Nettoyer complètement l'environnement de lab pour retrouver un état propre.
{% endhint %}

{% tabs %}
{% tab title="Français" %}
Ce script nettoie ce qui a été créé pendant les labs :

- Arrête et supprime les conteneurs du lab (`u1`, `cloneU1x64`, `routerCT`, `debianCT`, `nginxCT`, `appwebCT` ; les autres conteneurs sont conservés)
- Supprime les images du lab (publiées et alias téléchargés)
- Supprime les volumes et pools de stockage du lab
- Supprime les fichiers temporaires

Le pool `cr380storagepool` et le pont `cr380incusbr0` créés au Lab 04 restent en place.
{% endtab %}
{% tab title="English" %}
This script cleans up what was created during the labs:

- Stops and deletes the lab containers (`u1`, `cloneU1x64`, `routerCT`, `debianCT`, `nginxCT`, `appwebCT`; other containers are kept)
- Deletes the lab images (published images and downloaded aliases)
- Deletes the lab volumes and storage pools
- Removes temporary files

The `cr380storagepool` pool and the `cr380incusbr0` bridge created in Lab 04 stay in place.
{% endtab %}
{% endtabs %}

## Étape 1 : Arrêter et supprimer les conteneurs du lab

L'option `--force` arrête le conteneur avant de le supprimer. Supprimer chaque conteneur du lab qui existe encore (`incus ls` pour vérifier) :

```bash
incus delete --force u1
incus delete --force cloneU1x64
incus delete --force routerCT
incus delete --force debianCT
incus delete --force nginxCT
incus delete --force appwebCT
```

## Étape 2 : Supprimer les images du lab

```bash
incus image delete imgCustomU1x64
incus image delete nginx-0.0.0
incus image delete demo-app-0.0.0
incus image delete ubuntux64
incus image delete alpinex64
incus image delete openwrt25.12
incus image delete debian12
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
incus ls                    # Aucun conteneur du lab
incus image ls              # Aucune image du lab
incus storage list          # Devrait montrer uniquement cr380storagepool
incus storage volume list websrv_storage  # Devrait échouer (pool supprimé)
```

{% hint style="success" %}
**Résultat attendu** : Aucun conteneur du lab, aucune image du lab, aucun volume. Seul le pool `cr380storagepool` reste (avec le pont `cr380incusbr0`).
{% endhint %}
