# Lab 07 — Conteneurs

{% hint style="info" %}
**Objectif** : Maîtriser le cycle de vie complet d'un conteneur Incus — lancer, publier, cloner et supprimer.
{% endhint %}

{% tabs %}
{% tab title="Français" %}
Le cycle de vie d'un conteneur Incus :

1. Lancer (launch) depuis une image → conteneur RUNNING
2. Arrêter (stop) → STOPPED
3. Cloner ou publier (publish) → nouvelle image
4. Supprimer (delete) → libérer les ressources

Nous allons pratiquer chaque opération.
{% endtab %}
{% tab title="English" %}
The Incus container lifecycle:

1. Launch from an image → RUNNING container
2. Stop → STOPPED
3. Clone or publish → new image
4. Delete → free resources

We will practice each operation.
{% endtab %}
{% endtabs %}

## Étape 1 : Lancer un conteneur

{% tabs %}
{% tab title="Français" %}
Ceci crée un conteneur nommé `u1` à partir de l'image `ubuntux64` et le démarre automatiquement.
{% endtab %}
{% tab title="English" %}
This creates a container named `u1` from the `ubuntux64` image and starts it automatically.
{% endtab %}
{% endtabs %}

```bash
incus launch ubuntux64 u1
```

## Étape 2 : Lister en YAML

{% tabs %}
{% tab title="Français" %}
On peut lister les conteneurs en YAML pour voir tous les détails.
{% endtab %}
{% tab title="English" %}
You can list containers in YAML to see all details.
{% endtab %}
{% endtabs %}

```bash
incus ls --format yaml
```

## Étape 3 : Publier comme image

{% tabs %}
{% tab title="Français" %}
Ceci crée une image à partir du conteneur en cours d'exécution. Le flag `--force` permet la publication même si le conteneur tourne.
{% endtab %}
{% tab title="English" %}
This creates an image from the running container. The `--force` flag allows publishing even while the container is running.
{% endtab %}
{% endtabs %}

```bash
incus publish u1 --alias imgCustomU1x64 --force
```

## Étape 4 : Lancer un clone

{% tabs %}
{% tab title="Français" %}
Ceci lance un nouveau conteneur à partir de l'image que nous venons de publier.
{% endtab %}
{% tab title="English" %}
This launches a new container from the image we just published.
{% endtab %}
{% endtabs %}

```bash
incus launch imgCustomU1x64 cloneU1x64
```

## Étape 5 : Supprimer le clone

{% tabs %}
{% tab title="Français" %}
On arrête d'abord, puis on supprime. On pourrait aussi faire `incus delete --force cloneU1x64` (arrête et supprime en une seule commande).
{% endtab %}
{% tab title="English" %}
We stop first, then delete. You could also do `incus delete --force cloneU1x64` (stops and deletes in one command).
{% endtab %}
{% endtabs %}

```bash
incus stop cloneU1x64
incus delete cloneU1x64
```

{% hint style="success" %}
**Résultat attendu** : Le conteneur `u1` est toujours en cours d'exécution. Le clone `cloneU1x64` est supprimé. L'image `imgCustomU1x64` est disponible pour les prochains labs.
{% endhint %}
