# Installation et configuration

Cette section couvre les quatre premières étapes essentielles pour configurer Incus sur votre machine.

{% tabs %}
{% tab title="Français" %}
**Objectifs d'apprentissage :**

- Désinstaller proprement Incus (Lab 01)
- Installer Incus depuis le dépôt Ubuntu (Lab 02)
- Configurer les permissions utilisateur et le groupe `incus-admin` (Lab 03)
- Initialiser le stockage, le réseau et les profils avec un preseed YAML (Lab 04)
{% endtab %}
{% tab title="English" %}
**Learning objectives:**

- Cleanly uninstall Incus (Lab 01)
- Install Incus from the Ubuntu repository (Lab 02)
- Configure user permissions and the `incus-admin` group (Lab 03)
- Initialize storage, networking and profiles with a preseed YAML (Lab 04)
{% endtab %}
{% endtabs %}

## Ressources créées

À la fin de cette section, votre système disposera de :

| Ressource | Nom | Type |
|-----------|-----|------|
| Pool de stockage | `cr380storagepool` | `dir` |
| Pont réseau | `cr380incusbr0` | `bridge` (IPv4 auto) |
| Profil | `default` | Utilise le pool et le réseau |
