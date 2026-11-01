# Dépannage WSL

{% hint style="info" %}
Cette page ne liste que des problèmes **réellement rencontrés** pendant le portage du lab sous WSL 2. Pour les autres erreurs, lisez le **HINT** affiché par le test qui échoue, puis consultez `docs/TROUBLESHOOTING.md` dans le dépôt.
{% endhint %}

## `/usr/bin/env: 'bash\r': No such file or directory`

| | |
|---|---|
| **Symptôme** | Tous les scripts échouent avec `bash\r`, ou avec `$'\r': command not found` |
| **Cause** | Les fichiers ont des fins de ligne Windows (CRLF). Linux lit le `\r` comme faisant partie de la commande. Cela arrive quand le dépôt est copié ou téléchargé depuis Windows, par exemple en ZIP |
| **Correction** | Clonez le dépôt **depuis Ubuntu** (étape 8) avec `git clone`. Le fichier `.gitattributes` du dépôt force alors les fins de ligne LF |

## Lab 06 : `Failed getting image: The requested image couldn't be found`

| | |
|---|---|
| **Symptôme** | Le Lab 06 échoue au téléchargement d'Alpine ou d'OpenWrt, et les labs 07 à 12 sont ignorés |
| **Cause** | La version d'image demandée dans `config.env` n'existe plus sur `images.linuxcontainers.org` (par exemple `alpine/3.20` ou `openwrt/23.05/amd64`) |
| **Vérification** | `./run-labs.sh --check-images` indique quelles images sont introuvables |
| **Correction** | Utilisez la version actuelle du dépôt : `git pull`. Votre enseignant tient `config.env` à jour avant chaque cours |
