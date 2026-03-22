# Lab 10 — Transfert de fichiers

{% hint style="info" %}
**Objectif** : Transférer des fichiers et répertoires entre l'hôte et les conteneurs avec `incus file pull` et `incus file push`.
{% endhint %}

{% tabs %}
{% tab title="Français" %}
Incus permet de transférer des fichiers entre l'hôte et les conteneurs :

- `incus file pull <conteneur>/<chemin> <destination>` — copier depuis le conteneur
- `incus file push <source> <conteneur>/<chemin>` — copier vers le conteneur
- Ajouter `-r` pour les répertoires (récursif)

C'est similaire à `docker cp`.
{% endtab %}
{% tab title="English" %}
Incus allows file transfers between host and containers:

- `incus file pull <container>/<path> <destination>` — copy from container
- `incus file push <source> <container>/<path>` — copy to container
- Add `-r` for directories (recursive)

This is similar to `docker cp`.
{% endtab %}
{% endtabs %}

## Étape 1 : Récupérer un fichier depuis le conteneur

{% tabs %}
{% tab title="Français" %}
Ceci télécharge la page HTML par défaut de nginx depuis le conteneur.
{% endtab %}
{% tab title="English" %}
This downloads the default nginx HTML page from the container.
{% endtab %}
{% endtabs %}

```bash
incus file pull nginxCT/var/www/html/index.nginx-debian.html .
```

## Étape 2 : Créer et envoyer une page personnalisée

{% tabs %}
{% tab title="Français" %}
Créons une page HTML personnalisée avec le message « Bonsoir classe CR380 » et envoyons-la dans le conteneur.
{% endtab %}
{% tab title="English" %}
Let's create a custom HTML page with the message 'Bonsoir classe CR380' and push it to the container.
{% endtab %}
{% endtabs %}

```bash
# Renommer l'original dans le conteneur
incus exec nginxCT -- mv /var/www/html/index.nginx-debian.html \
  /var/www/html/index.nginx-debian.html.orig

# Créer une page personnalisée
echo "<h1>Bonsoir classe CR380</h1>" > index.html

# Envoyer dans le conteneur
incus file push index.html nginxCT/var/www/html/
```

## Étape 3 : Récupérer un répertoire complet

{% tabs %}
{% tab title="Français" %}
Ceci télécharge le répertoire complet récursivement. Nous le renommerons ensuite en `html.bkp` comme sauvegarde.
{% endtab %}
{% tab title="English" %}
This downloads the entire directory recursively. We'll rename it to `html.bkp` as a backup.
{% endtab %}
{% endtabs %}

```bash
incus file pull -r nginxCT/var/www/html .
mv html html.bkp
```

## Étape 4 : Cloner et envoyer l'application de démo

{% tabs %}
{% tab title="Français" %}
Maintenant nous clonons le dépôt de l'application de démonstration et nous l'envoyons dans le conteneur pour remplacer le site web par défaut.
{% endtab %}
{% tab title="English" %}
Now we clone the demo application repository and push it to the container to replace the default website.
{% endtab %}
{% endtabs %}

```bash
git clone https://github.com/nintcheu/dog-breed-recognition.git ml-app
incus file push -r ml-app nginxCT/var/www/
```

## Étape 5 : Remplacer le site web

{% tabs %}
{% tab title="Français" %}
Nous renommons le répertoire dans le conteneur pour que nginx serve l'application de démo.
{% endtab %}
{% tab title="English" %}
We rename the directory inside the container so nginx serves the demo application.
{% endtab %}
{% endtabs %}

```bash
incus exec nginxCT -- mv /var/www/html /var/www/html.orig
incus exec nginxCT -- mv /var/www/ml-app /var/www/html
```

## Étape 6 : Publier comme image d'application

{% tabs %}
{% tab title="Français" %}
L'image `demo-app-0.0.0` contient nginx + l'application de démo.
{% endtab %}
{% tab title="English" %}
The `demo-app-0.0.0` image contains nginx + the demo application.
{% endtab %}
{% endtabs %}

```bash
incus publish nginxCT --alias demo-app-0.0.0 --force
```

{% hint style="success" %}
**Résultat attendu** : L'image `demo-app-0.0.0` est visible dans `incus image ls`. Elle sera utilisée dans les labs suivants.
{% endhint %}
