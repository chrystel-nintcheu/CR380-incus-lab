# Les flux Incus

Cette section couvre les concepts fondamentaux de l'écosystème Incus : registres d'images, gestion des images, cycle de vie des conteneurs et exposition de ports.

{% tabs %}
{% tab title="Français" %}
**Objectifs d'apprentissage :**

- Comprendre les registres distants et les formats de sortie (Lab 05)
- Maîtriser le cycle de vie des images : rechercher, filtrer, télécharger, supprimer (Lab 06)
- Gérer les conteneurs : lancer, arrêter, publier, cloner, supprimer (Lab 07)
- Exposer les ports d'un conteneur sur l'hôte avec les proxy devices (Lab 08)
{% endtab %}
{% tab title="English" %}
**Learning objectives:**

- Understand remote registries and output formats (Lab 05)
- Master the image lifecycle: search, filter, download, delete (Lab 06)
- Manage containers: launch, stop, publish, clone, delete (Lab 07)
- Expose container ports on the host using proxy devices (Lab 08)
{% endtab %}
{% endtabs %}

## Images utilisées

| Image distante | Alias local | Utilisée dans |
|----------------|-------------|---------------|
| `images:ubuntu/noble/amd64` | `ubuntux64` | Labs 07+ |
| `images:alpine/3.20` | `alpinex64` | Lab 06 (supprimée ensuite) |
| `images:openwrt/23.05/amd64` | `openwrt23.05` | Lab 08 |
| `images:debian/12` | `debian12` | Lab 09+ |
