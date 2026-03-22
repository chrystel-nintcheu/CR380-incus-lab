# Lab 08 — Exposer un port

{% hint style="info" %}
**Objectif** : Exposer les ports d'un conteneur sur l'hôte en utilisant les proxy devices, puis vérifier l'accès HTTP et fermer le port.
{% endhint %}

{% tabs %}
{% tab title="Français" %}
Incus utilise des « proxy devices » pour exposer les ports d'un conteneur sur l'hôte. C'est différent du port forwarding classique (iptables).

Un proxy device crée une connexion entre un port de l'hôte et un port du conteneur, gérée par le démon Incus.
{% endtab %}
{% tab title="English" %}
Incus uses 'proxy devices' to expose container ports on the host. This is different from classic port forwarding (iptables).

A proxy device creates a connection between a host port and a container port, managed by the Incus daemon.
{% endtab %}
{% endtabs %}

## Étape 1 : Lancer le conteneur OpenWRT

{% tabs %}
{% tab title="Français" %}
OpenWRT est un OS de routeur avec une interface web sur le port 80.
{% endtab %}
{% tab title="English" %}
OpenWRT is a router OS with a web interface on port 80.
{% endtab %}
{% endtabs %}

```bash
incus launch openwrt23.05 routerCT
```

## Étape 2 : Ajouter un proxy device

{% tabs %}
{% tab title="Français" %}
Ceci fait écouter l'hôte sur le port 8888 et redirige vers le port 80 du conteneur.
{% endtab %}
{% tab title="English" %}
This makes the host listen on port 8888 and redirect to port 80 in the container.
{% endtab %}
{% endtabs %}

```bash
incus config device add routerCT monport80vers8888 proxy \
  listen=tcp:0.0.0.0:8888 connect=tcp:127.0.0.1:80
```

## Étape 3 : Vérifier la configuration

```bash
incus config show routerCT
```

{% hint style="success" %}
**Résultat attendu** : Le device `monport80vers8888` de type `proxy` apparaît dans la configuration du conteneur.
{% endhint %}

## Étape 4 : Tester l'accès HTTP

{% tabs %}
{% tab title="Français" %}
Vous devriez voir la page web d'OpenWRT (LuCI).
{% endtab %}
{% tab title="English" %}
You should see the OpenWRT web page (LuCI).
{% endtab %}
{% endtabs %}

```bash
curl -sL --max-time 15 http://localhost:8888
```

## Étape 5 : Retirer le proxy device

{% tabs %}
{% tab title="Français" %}
Ceci ferme le port sur l'hôte.
{% endtab %}
{% tab title="English" %}
This closes the port on the host.
{% endtab %}
{% endtabs %}

```bash
incus config device remove routerCT monport80vers8888
```

{% hint style="success" %}
**Résultat attendu** : Le port 8888 n'est plus accessible. `incus config show routerCT` ne montre plus le device proxy.
{% endhint %}
