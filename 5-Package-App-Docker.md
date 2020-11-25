# Packaging d'une application Python dans Docker et tests

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
5. Une fois notre application, ses dépendances, son Dockerfile corrigés, commitez l'application dans votre branche, puis soumettez la Merge Request à votre professeur pour review et approbation.

## Tests de qualité et sécurité

Nous allons tester et builder l'image. Exceptionellement nous ne pourrons pas tester le build directement dans notre terminal code-hitema, Docker Engine n'étant ni installé, ni capable de tourner à l'intérieur de Kubernetes (Docker inception).

Il va donc falloir tester le build directement dans Gitlab CI.

0. Créez une issue `Check Dockerfile and requirements` dans le dépôt Gitlab `application`, puis une Merge Request
1. Toujours dans le dépôt application, et la branche précédente, créez le fichier `.gitlab-ci.yml` à la racine.
   - Settez l'image avec `image: captnbp/gitlab-ci-image:v2.9.7`
2. Préparez les stages suivants : test, build
3. Nous allons intégrer les différents checks que nous avons fait précédement dans des jobs indépendants au sein du stage `test`:
   - hadolint (image `hadolint/hadolint`)
   - dependency_scanning_safety (image `pyupio/safety`)
   - dependency_scanning façon Gitlab -> https://docs.gitlab.com/ee/user/application_security/dependency_scanning/
   - code_quality façon Gitlab -> https://docs.gitlab.com/ee/user/project/merge_requests/code_quality.html
   - sast façon Gitlab -> https://docs.gitlab.com/ee/user/application_security/sast/

   > Il faudra bien penser à inclure les 3 jobs proposés par Gitlab :
   > ```yaml
   > include:
   >   - template: Jobs/Code-Quality.gitlab-ci.yml  # https://gitlab.com/gitlab-org/gitlab-foss/blob/master/lib/gitlab/ci/templates/Jobs/Code-Quality.gitlab-ci.yml
   >   - template: Security/SAST.gitlab-ci.yml  # https://gitlab.com/gitlab-org/gitlab-foss/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml
   >   - template: Code-Quality.gitlab-ci.yml  # https://gitlab.com/gitlab-org/gitlab-foss/blob/master/lib/gitlab/ci/templates/Code-Quality.gitlab-ci.yml
   > ```
4. Dès que votre pipeline est fonctionnel et que les tests sont OK, commitez dans votre branche, puis soumettez la Merge Request à votre professeur pour review et approbation.

## Build de l'image Docker

0. Créez une issue `Build Dockerfile` dans le dépôt Gitlab `application`, puis une Merge Request
1. Nous allons builder l'image Docker avec l'outil kaniko (https://github.com/GoogleContainerTools/kaniko)
   - Voici un peu de documentation : https://docs.gitlab.com/ee/ci/docker/using_kaniko.html
   - Créez le job `build` rattaché au stage `build`
   - Ajoutez le `before_script` suivant :
     ```yaml
     before_script:
       - |
         if [[ -z "$CI_COMMIT_TAG" ]]; then
           export CI_APPLICATION_REPOSITORY=${CI_APPLICATION_REPOSITORY:-$CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG}
           export CI_APPLICATION_TAG=${CI_APPLICATION_TAG:-$CI_COMMIT_SHA}
         else
           export CI_APPLICATION_REPOSITORY=${CI_APPLICATION_REPOSITORY:-$CI_REGISTRY_IMAGE}/app
           export CI_APPLICATION_TAG=${CI_APPLICATION_TAG:-$CI_COMMIT_TAG}
         fi
     ```
   - Afin d'éviter de se faire blacklister par Docker Hub (rate limit) inscrivez-vous sur le site https://hub.docker.com/, pusi créez un Access Token ici : https://hub.docker.com/settings/security
   - Stockez votre access token Docker Hub dans Vault dans le secret nommé : `groupe-<group number>/dockerhub` en mettant les 2 keys suivantes :
     - `DOCKERHUB_USERNAME` -> votre username de votre compte Docker Hub
     - `DOCKERHUB_ACCESS_TOKEN` -> votre access token
     - `URL` = `https://index.docker.io/v1/` (cf. https://github.com/GoogleContainerTools/kaniko#pushing-to-docker-hub)
   - Dans notre job `build`, il faudra aller faire un `vault read groupe-<group number>/dockerhub` pour chaque key du secret afin de les intégrer à la création du fichier `/kaniko/.docker/config.json` (en plus des creds déjà settés dans l'exemple de la doc Gitlab)
     Voici un exemple à adapter :
     ```yaml
     docker-build:
       stage: build
       image:
         name: gcr.io/kaniko-project/executor:debug
         entrypoint: [""]
       script:
         - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > /kaniko/.docker/config.json
         - /kaniko/executor --context $CI_PROJECT_DIR/dockerfiles/browser --dockerfile Dockerfile --destination $CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG
     ```
2. Dès que votre pipeline est fonctionnel et que les tests sont OK, commitez dans votre branche, puis soumettez la Merge Request à votre professeur pour review et approbation.

## Scan de l'image Docker à la recherche de packages vulnérables

0. Créez une issue `Scan Docker image` dans le dépôt Gitlab `application`, puis une Merge Request
1. Ajoutez les variables globales suivantes à votre `.gitlab-ci.yml`:
   ```yaml
   variables:
     ROLLOUT_RESOURCE_TYPE: deployment
     SECURE_ANALYZERS_PREFIX: "registry.gitlab.com/gitlab-org/security-products/analyzers"
     CS_MAJOR_VERSION: 2
     CONTAINER_SCANNING_DISABLED: "False"
   ```
2. Créez un stage `security`
3. Ajoutez le scan d'image image façon Gitlab https://docs.gitlab.com/ee/user/application_security/container_scanning/
   ```yaml
   container_scanning_nginx:
     stage: security
     image: $SECURE_ANALYZERS_PREFIX/klar:$CS_MAJOR_VERSION
     variables:
       # By default, use the latest clair vulnerabilities database, however, allow it to be overridden here with a specific image
       # to enable container scanning to run offline, or to provide a consistent list of vulnerabilities for integration testing purposes
       CLAIR_DB_IMAGE_TAG: "latest"
       CLAIR_DB_IMAGE: "$SECURE_ANALYZERS_PREFIX/clair-vulnerabilities-db:$CLAIR_DB_IMAGE_TAG"
       # Override the GIT_STRATEGY variable in your `.gitlab-ci.yml` file and set it to `fetch` if you want to provide a `clair-whitelist.yml`
       # file. See https://docs.gitlab.com/ee/user/application_security/container_scanning/index.html#overriding-the-container-scanning-template
       # for details
       GIT_STRATEGY: none
     allow_failure: true
     services:
       - name: $CLAIR_DB_IMAGE
         alias: clair-vulnerabilities-db
     script:
       - /analyzer run
     artifacts:
       reports:
         container_scanning: gl-container-scanning-report.json
   ```
4. Dès que votre pipeline est fonctionnel et que les tests sont OK, commitez dans votre branche, puis soumettez la Merge Request à votre professeur pour review et approbation.
