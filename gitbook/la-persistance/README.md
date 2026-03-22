# La persistance

Cette section couvre les concepts avancés de persistance des données dans Incus : conteneurs d'application, transferts de fichiers, pools de stockage et volumes.

{% tabs %}
{% tab title="Français" %}
**Objectifs d'apprentissage :**

- Créer un conteneur d'application selon le pattern « image de base + app = image d'app » (Lab 09)
- Transférer des fichiers entre l'hôte et les conteneurs (Lab 10)
- Créer et gérer des pools de stockage (Lab 11)
- Créer et attacher des volumes persistants (Lab 12)
{% endtab %}
{% tab title="English" %}
**Learning objectives:**

- Create an application container following the "base image + app = app image" pattern (Lab 09)
- Transfer files between host and containers (Lab 10)
- Create and manage storage pools (Lab 11)
- Create and attach persistent volumes (Lab 12)
{% endtab %}
{% endtabs %}

## Ports utilisés

| Lab | Port hôte | Port conteneur | Service | Conteneur |
|-----|-----------|----------------|---------|-----------|
| 09 | 8000 | 80 | nginx | nginxCT |
| 11–12 | 8001 | 80 | nginx (demo-app) | appwebCT |
