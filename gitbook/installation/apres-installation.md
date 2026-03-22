# Lab 03 — Après installation

{% hint style="info" %}
**Objectif** : Configurer les permissions utilisateur pour contrôler Incus sans sudo.
{% endhint %}

{% tabs %}
{% tab title="Français" %}
Après l'installation, il faut configurer les permissions utilisateur. Le groupe `incus-admin` donne un accès complet au démon Incus.
{% endtab %}
{% tab title="English" %}
After installation, we need to configure user permissions. The `incus-admin` group gives full access to the Incus daemon.
{% endtab %}
{% endtabs %}

{% hint style="danger" %}
**SÉCURITÉ** : N'ajoutez que des utilisateurs de confiance au groupe `incus-admin`. L'accès local via le socket Unix donne un contrôle total sur Incus, y compris la possibilité de monter des systèmes de fichiers et des périphériques de l'hôte.

Lisez la documentation officielle : [Sécurité Incus](https://linuxcontainers.org/incus/docs/main/explanation/security/)
{% endhint %}

## Étape 1 : Ajouter l'utilisateur au groupe

{% tabs %}
{% tab title="Français" %}
Ceci permet à votre utilisateur de contrôler incus sans sudo.
{% endtab %}
{% tab title="English" %}
This allows your user to control incus without sudo.
{% endtab %}
{% endtabs %}

```bash
sudo adduser $USER incus-admin
```

## Étape 2 : Vérifier l'appartenance au groupe

```bash
getent group incus-admin
```

{% hint style="success" %}
**Résultat attendu** : Votre nom d'utilisateur apparaît dans la sortie de `getent group incus-admin`.
{% endhint %}

## Étape 3 : Tester l'accès

{% tabs %}
{% tab title="Français" %}
Nous utilisons `sg incus-admin -c "commande"` au lieu de `newgrp` car `newgrp` ouvre un nouveau shell et ne fonctionne pas dans un script.
{% endtab %}
{% tab title="English" %}
We use `sg incus-admin -c "command"` instead of `newgrp` because `newgrp` opens a new shell and doesn't work in scripts.
{% endtab %}
{% endtabs %}

```bash
sg incus-admin -c "incus info"
```

{% hint style="warning" %}
Si vous obtenez une erreur de permission, essayez de vous déconnecter et reconnecter, ou utilisez `sudo incus info` temporairement.
{% endhint %}
