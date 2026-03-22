# Lab 04 — Initialisation

{% hint style="info" %}
**Objectif** : Configurer le stockage, le réseau et les profils d'Incus avec un fichier preseed YAML.
{% endhint %}

{% tabs %}
{% tab title="Français" %}
L'initialisation configure le stockage, le réseau, et d'autres paramètres globaux d'Incus. Nous utilisons un fichier « preseed » YAML qui reproduit exactement les réponses de l'initialisation interactive.
{% endtab %}
{% tab title="English" %}
Initialization configures storage, networking, and other global Incus settings. We use a preseed YAML file that exactly reproduces the answers from the interactive initialization.
{% endtab %}
{% endtabs %}

## Étape 1 : Comprendre le preseed YAML

{% tabs %}
{% tab title="Français" %}
Le preseed YAML contient toutes les réponses que vous donneriez dans `incus admin init`. Il définit :

- Un pool de stockage `cr380storagepool` de type `dir`
- Un pont réseau `cr380incusbr0` avec IPv4 auto et IPv6 désactivé
- Un profil `default` qui utilise ce pool et ce réseau
{% endtab %}
{% tab title="English" %}
The preseed YAML contains all the answers you would give in `incus admin init`. It defines:

- A storage pool `cr380storagepool` of type `dir`
- A network bridge `cr380incusbr0` with IPv4 auto and IPv6 disabled
- A `default` profile using that pool and network
{% endtab %}
{% endtabs %}

{% code title="preseed.yaml" lineNumbers="true" %}
```yaml
config: {}
networks:
- config:
    ipv4.address: auto
    ipv4.nat: "true"
    ipv6.address: none
  description: ""
  name: cr380incusbr0
  type: bridge
  project: default
storage_pools:
- config: {}
  description: ""
  name: cr380storagepool
  driver: dir
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      network: cr380incusbr0
      type: nic
    root:
      path: /
      pool: cr380storagepool
      type: disk
  name: default
projects: []
cluster: null
```
{% endcode %}

## Étape 2 : Appliquer le preseed

```bash
cat <<'EOF' | incus admin init --preseed
config: {}
networks:
- config:
    ipv4.address: auto
    ipv4.nat: "true"
    ipv6.address: none
  description: ""
  name: cr380incusbr0
  type: bridge
  project: default
storage_pools:
- config: {}
  description: ""
  name: cr380storagepool
  driver: dir
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      network: cr380incusbr0
      type: nic
    root:
      path: /
      pool: cr380storagepool
      type: disk
  name: default
projects: []
cluster: null
EOF
```

## Étape 3 : Vérifier la configuration

```bash
incus info
incus storage list
incus network list
incus profile show default
```

{% hint style="success" %}
**Résultat attendu** :

- `incus storage list` montre le pool `cr380storagepool`
- `incus network list` montre le pont `cr380incusbr0`
- `incus profile show default` montre le pool et le réseau dans les devices
{% endhint %}
