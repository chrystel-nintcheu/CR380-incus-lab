# Lab 01 — Désinstallation

{% hint style="info" %}
**Objectif** : Désinstaller complètement Incus pour repartir sur une base propre.
{% endhint %}

{% tabs %}
{% tab title="Français" %}
Nous allons d'abord désinstaller Incus complètement pour repartir sur une base propre. C'est une bonne pratique avant toute installation.
{% endtab %}
{% tab title="English" %}
We will first completely uninstall Incus to start from a clean slate. This is good practice before any installation.
{% endtab %}
{% endtabs %}

## Étape 1 : Arrêter le service

{% tabs %}
{% tab title="Français" %}
Incus est installé. Nous devons d'abord arrêter le service.
{% endtab %}
{% tab title="English" %}
Incus is installed. We must first stop the service.
{% endtab %}
{% endtabs %}

```bash
sudo systemctl stop incus incus.socket incus-user incus-user.socket incus-lxcfs incus-startup 2>/dev/null
```

Supprimons aussi les conteneurs et les images existants pour éviter les problèmes lors de la purge :

```bash
incus stop --all --force
incus list --format csv -c n          # puis : incus delete --force <nom> pour chaque conteneur
incus image list --format csv -c l    # puis : incus image delete <alias> pour chaque image
```

## Étape 2 : Purger les paquets

{% tabs %}
{% tab title="Français" %}
Maintenant nous purgeons les paquets incus avec apt.
{% endtab %}
{% tab title="English" %}
Now we purge incus packages with apt.
{% endtab %}
{% endtabs %}

```bash
sudo apt-get remove --purge -y incus
sudo apt-get autoremove -y
sudo apt-get clean
```

## Étape 3 : Supprimer les fichiers résiduels

{% tabs %}
{% tab title="Français" %}
Suppression des fichiers résiduels dans /var/lib/incus, du pont réseau `cr380incusbr0` s'il existe encore et, le cas échéant, du dépôt tiers Zabbly.
{% endtab %}
{% tab title="English" %}
Removing leftover files in /var/lib/incus, the `cr380incusbr0` network bridge if it still exists and, if present, the third-party Zabbly repository.
{% endtab %}
{% endtabs %}

```bash
sudo rm -rf /var/lib/incus*
sudo ip link set cr380incusbr0 down 2>/dev/null
sudo ip link delete cr380incusbr0 2>/dev/null
sudo rm -f /etc/apt/sources.list.d/zabbly-incus-stable.sources /etc/apt/keyrings/zabbly.asc
```

## Étape 4 : Supprimer les groupes système

{% tabs %}
{% tab title="Français" %}
Suppression des groupes système créés par Incus.
{% endtab %}
{% tab title="English" %}
Removing system groups created by Incus.
{% endtab %}
{% endtabs %}

```bash
sudo groupdel incus-admin 2>/dev/null
sudo groupdel incus 2>/dev/null
```

{% hint style="warning" %}
**Attention** : Le paquet Ubuntu ne recrée pas automatiquement le groupe `incus-admin` lors d'une réinstallation. Vous devrez le recréer manuellement au Lab 02 — Étape 3 avant de pouvoir démarrer le service Incus.
{% endhint %}

## Étape 5 : Vérification

{% tabs %}
{% tab title="Français" %}
Vérifions que tout a bien été supprimé.
{% endtab %}
{% tab title="English" %}
Let's verify everything has been removed.
{% endtab %}
{% endtabs %}

```bash
which incus          # Ne devrait rien retourner
ls /var/lib/incus    # Devrait échouer
getent group incus-admin  # Devrait être vide
```

{% hint style="success" %}
**Résultat attendu** : Le binaire `incus` n'est plus trouvé, aucun fichier résiduel, aucun groupe incus.
{% endhint %}
