# Lab 09 — Conteneur d'application

{% hint style="info" %}
**Objectif** : Créer un conteneur d'application en suivant le pattern : image de base → installer l'application → publier comme nouvelle image.
{% endhint %}

{% tabs %}
{% tab title="Français" %}
Le pattern « conteneur d'application » :

1. Partir d'une image de base (Debian 12)
2. Installer l'application (nginx + outils)
3. Configurer
4. Publier comme nouvelle image (`nginx-0.0.0`)
5. Utiliser cette image pour déployer

C'est similaire au Dockerfile de Docker.
{% endtab %}
{% tab title="English" %}
The 'application container' pattern:

1. Start from a base image (Debian 12)
2. Install the application (nginx + tools)
3. Configure
4. Publish as a new image (`nginx-0.0.0`)
5. Use that image for deployment

This is similar to Docker's Dockerfile.
{% endtab %}
{% endtabs %}

## Étape 1 : Lancer le conteneur de base

```bash
incus launch debian12 debianCT
```

## Étape 2 : Installer les paquets

{% tabs %}
{% tab title="Français" %}
Ceci installe le serveur web nginx et des outils utiles dans le conteneur.
{% endtab %}
{% tab title="English" %}
This installs the nginx web server and useful tools inside the container.
{% endtab %}
{% endtabs %}

```bash
incus exec debianCT -- apt-get update -y
incus exec debianCT -- apt-get install -y nginx ufw tree vim
```

## Étape 3 : Activer les services

```bash
incus exec debianCT -- systemctl start nginx
incus exec debianCT -- systemctl enable nginx
```

## Étape 4 : Configurer le pare-feu

{% tabs %}
{% tab title="Français" %}
Configuration du pare-feu :
- `ufw allow 'Nginx Full'` — autoriser HTTP (80) et HTTPS (443)
- `ufw allow OpenSSH` — autoriser SSH (22)
- `ufw --force enable` — activer le pare-feu
{% endtab %}
{% tab title="English" %}
Firewall configuration:
- `ufw allow 'Nginx Full'` — allow HTTP (80) and HTTPS (443)
- `ufw allow OpenSSH` — allow SSH (22)
- `ufw --force enable` — enable the firewall
{% endtab %}
{% endtabs %}

```bash
incus exec debianCT -- ufw allow 'Nginx Full'
incus exec debianCT -- ufw allow OpenSSH
incus exec debianCT -- ufw --force enable
```

{% hint style="warning" %}
Dans un conteneur non-privilégié, UFW peut ne pas fonctionner. C'est un comportement attendu — les règles réseau sont gérées au niveau de l'hôte.
{% endhint %}

## Étape 5 : Publier comme image

{% tabs %}
{% tab title="Français" %}
L'image `nginx-0.0.0` contient Debian + nginx + UFW configuré.
{% endtab %}
{% tab title="English" %}
The `nginx-0.0.0` image contains Debian + nginx + configured UFW.
{% endtab %}
{% endtabs %}

```bash
incus publish debianCT --alias nginx-0.0.0 --force
```

## Étape 6 : Déployer depuis l'image

```bash
incus delete --force debianCT
incus launch nginx-0.0.0 nginxCT
```

## Étape 7 : Exposer le port et vérifier

```bash
incus config device add nginxCT monport80vers8000 proxy \
  listen=tcp:0.0.0.0:8000 connect=tcp:127.0.0.1:80

curl -sL --max-time 15 http://localhost:8000
```

{% hint style="success" %}
**Résultat attendu** : Le serveur nginx répond sur `http://localhost:8000` avec la page par défaut de Debian/nginx.
{% endhint %}
