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

## Étape 3 : Vérifier l'installation

{% tabs %}
{% tab title="Français" %}
Incus est maintenant installé et le service est actif ! Vous pouvez vérifier manuellement avec les commandes suivantes.
{% endtab %}
{% tab title="English" %}
Incus is now installed and the service is active! You can verify manually with the following commands.
{% endtab %}
{% endtabs %}

```bash
incus --version
systemctl is-active incus
```

{% hint style="success" %}
**Résultat attendu** : `incus --version` affiche un numéro de version et `systemctl is-active incus` retourne `active`.
{% endhint %}

{% hint style="warning" %}
Si le service n'est pas actif, démarrez-le manuellement :

```bash
sudo systemctl start incus
```
{% endhint %}
