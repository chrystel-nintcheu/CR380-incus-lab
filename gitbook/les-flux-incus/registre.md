# Lab 05 — Registres

{% hint style="info" %}
**Objectif** : Explorer les registres distants d'images Incus et les formats de sortie.
{% endhint %}

{% tabs %}
{% tab title="Français" %}
Les registres sont des serveurs distants qui hébergent des images de conteneurs prêtes à l'emploi. C'est similaire à Docker Hub, mais pour des images système complètes (Ubuntu, Alpine, Debian, etc.).

Le registre principal est `images` (images.linuxcontainers.org).
{% endtab %}
{% tab title="English" %}
Registries are remote servers hosting ready-to-use container images. It's similar to Docker Hub, but for complete system images (Ubuntu, Alpine, Debian, etc.).

The main registry is `images` (images.linuxcontainers.org).
{% endtab %}
{% endtabs %}

## Étape 1 : Lister les registres

```bash
incus remote list
```

{% hint style="success" %}
**Résultat attendu** : Le registre `images` apparaît dans la liste avec l'adresse `https://images.linuxcontainers.org`.
{% endhint %}

## Étape 2 : Formats de sortie

{% tabs %}
{% tab title="Français" %}
Incus supporte plusieurs formats de sortie : table (défaut), yaml, json, csv. C'est utile pour l'automatisation et l'analyse.
{% endtab %}
{% tab title="English" %}
Incus supports multiple output formats: table (default), yaml, json, csv. This is useful for automation and analysis.
{% endtab %}
{% endtabs %}

```bash
incus remote list --format yaml
```

{% hint style="info" %}
Le format `yaml` est particulièrement utile pour inspecter la configuration complète d'une ressource. Le format `json` est pratique pour le traitement avec `jq`.
{% endhint %}
