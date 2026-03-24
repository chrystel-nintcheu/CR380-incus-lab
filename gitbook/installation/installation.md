# Lab 02 — Installation

{% hint style="info" %}
**Objectif** : Installer Incus depuis le dépôt officiel Ubuntu avec apt (Option 1 — la plus simple).
{% endhint %}

{% tabs %}
{% tab title="Français" %}
Nous allons installer Incus depuis le dépôt officiel Ubuntu avec apt. C'est l'option 1 du lab (la plus simple et recommandée).
{% endtab %}
{% tab title="English" %}
We will install Incus from the official Ubuntu repository with apt. This is Option 1 of the lab (simplest and recommended).
{% endtab %}
{% endtabs %}

## Étape 1 : Mettre à jour la liste des paquets

```bash
sudo apt-get update -y
```

## Étape 2 : Installer Incus

{% tabs %}
{% tab title="Français" %}
Le flag `-y` répond automatiquement « oui » aux confirmations.
{% endtab %}
{% tab title="English" %}
The `-y` flag automatically answers 'yes' to confirmations.
{% endtab %}
{% endtabs %}

```bash
sudo apt-get install -y incus
```

## Étape 3 : Créer le groupe incus-admin

{% hint style="danger" %}
**Important** : Le paquet Ubuntu ne recrée pas le groupe `incus-admin` si celui-ci a été supprimé (par exemple après une désinstallation complète au Lab 01). Sans ce groupe, le service Incus ne peut pas démarrer.
{% endhint %}

{% tabs %}
{% tab title="Français" %}
Vérifiez si le groupe existe. S'il est absent, créez-le manuellement avant de démarrer le service.
{% endtab %}
{% tab title="English" %}
Check if the group exists. If it is missing, create it manually before starting the service.
{% endtab %}
{% endtabs %}

```bash
getent group incus-admin || sudo addgroup --system incus-admin
```

{% hint style="success" %}
**Résultat attendu** : La commande affiche la ligne du groupe, ou le crée silencieusement.
{% endhint %}

## Étape 4 : Vérifier l'installation

{% tabs %}
{% tab title="Français" %}
Incus est maintenant installé. Vérifiez la version et l'état du service.
{% endtab %}
{% tab title="English" %}
Incus is now installed. Check the version and service status.
{% endtab %}
{% endtabs %}

```bash
incus --version
sudo systemctl reset-failed incus 2>/dev/null; sudo systemctl start incus
systemctl is-active incus
```

{% hint style="success" %}
**Résultat attendu** : `incus --version` affiche un numéro de version et `systemctl is-active incus` retourne `active`.
{% endhint %}

{% hint style="warning" %}
Si le service reste inactif après `systemctl start incus`, vérifiez les logs :

```bash
sudo journalctl -u incus -n 20 --no-pager
```

L'erreur `chown: invalid group: 'root:incus-admin'` signifie que le groupe est manquant — retournez à l'étape 3.
{% endhint %}
