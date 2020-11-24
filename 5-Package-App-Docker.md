# Packaging d'une application Python dans Docker

Nous allons sécuriser, packager, updater l'application démo suivante écrite en Python : https://github.com/Azure-Samples/flask-postgresql-app.git

0. Créez une issue `Nouvelle demo app` dans le déôt Gitlab `application`, puis une Merge Request
1. Dans votre terminal code-hitema, git clonez le dépôt `application` dans `$HOME/code`
2. Clonez l'application https://github.com/Azure-Samples/flask-postgresql-app.git dans votre répertoire `$HOME/code`
3. Une fois que c'est fait, copier tout les fichiers du dépôt flask-postgresql-app dans le répertoire de votre dépôt `application`
   ```bash
   cd $HOME/code
   cp -a flask-postgresql-app/* flask-postgresql-app/.gitignore application/
   ```

Cette application demo est assez ancienne et utilise une version de python ancienne et des dépendances très certainement vulnérables. Nous allons corriger tout cela avant de builder notre image Docker qui nous permettra de déployer notre application sur notre VM Scaleway.

0. Commencez par upgrader l'image `FROM` du `Dockerfile` en utilisant une image officielle du Docker Hub
1. Tester ensuite l'état des dépendances de cette application. Les dépendances sont dans le ficher `requirements.txt`. Je vous conseille d'utiliser l'utilitaire https://github.com/pyupio/safety dans votre terminal pour un premier test.
2. Assurez-vous que le conteneur ne s'exécutera pas avec le user root un fois déployé et exécuté. Corrigez si besoin.
3. Essayez de comprendre comment cette application va lire la configuration Postgresql pour se connecter à la BDD Postgresql.
4. Testez votre Dockerfile avec l'outil https://github.com/hadolint/hadolint

Une fois notre application, ses dépendances, son Dockerfile corrigés, nous allons builder l'image. Exceptionellement nous ne pourrons pas tester le build directement dans notre terminal code-hitema, Docker Engine n'étant ni installé, ni capable de tourner à l'intérieur de Kubernetes (Docker inception).

Il va donc falloir tester le build directement dans Gitlab CI.

0. Toujours dans le dépôt application, et la branche précédente, créez le fichier `.gitlab-ci.yml` à la racine.
   - Settez l'image avec `image: captnbp/gitlab-ci-image:v2.9.7`
1. Préparez les stages suivants : test, build
2. Nous allons intégrer les différents checks que nous avons fait précédement dans des jobs indépendants au sein du stage `test`:
   - hadolint
   - dependencies_scan
3. Ensuite nous allons builder l'image Docker avec l'outil kaniko (https://github.com/GoogleContainerTools/kaniko)
   - Voici un peu de documentation : https://docs.gitlab.com/ee/ci/docker/using_kaniko.html
   - Créez le job `build` rattaché au stage `build`
   - Afin d'éviter de se faire blacklister par Docker Hub (rate limit) inscrivez-vous sur le site https://hub.docker.com/, pusi créez un Access Token ici : https://hub.docker.com/settings/security
   - Stockez votre access token Docker Hub dans Vault dans le secret nommé : `groupe-<group number>/dockerhub` en mettant les 2 keys suivantes :
     - `DOCKERHUB_USERNAME` -> votre username de votre compte Docker Hub
     - `DOCKERHUB_ACCESS_TOKEN` -> votre access token
     - `URL` = `https://index.docker.io/v1/` (cf. https://github.com/GoogleContainerTools/kaniko#pushing-to-docker-hub)
   - Dans notre job `build`, il faudra aller faire un `vault read groupe-<group number>/dockerhub` pour chaque key du secret afin de les intégrer à la création du fichier `/kaniko/.docker/config.json` (en plus des creds déjà settés dans l'exemple de la doc Gitlab)
4. Scan image façon Gitlab
5. Déploiement de Postgresql via Ansible en mode Docker sur la VM avec volume data dans infrastructure
   - Création des creds dans Ansible avec stockage dans Vault
   - Déploiement du container en allant chercher les creds dans Vault
6. Déploiement de l'application avec creds from  vault, intégration à Traefik