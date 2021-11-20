# Packaging d'une application Python dans Docker et tests

Nous allons sécuriser, packager, updater l'application démo suivante écrite en Python : https://github.com/Azure-Samples/flask-postgresql-app.git

0. Créez une issue `Nouvelle demo app` dans le dépôt Gitlab `application`, puis une Merge Request
1. Dans votre terminal code-hitema, git clonez le dépôt `application` dans `$HOME/code`
2. Clonez l'application https://github.com/Azure-Samples/flask-postgresql-app.git dans votre répertoire `$HOME/code`
3. Une fois que c'est fait, copier tout les fichiers du dépôt flask-postgresql-app dans le répertoire de votre dépôt `application`
   ```bash
   cd $HOME/code
   git clone https://github.com/Azure-Samples/flask-postgresql-app.git
   git clone git@gitlab.com:h3-hitema-devsecops-2021/groupe_${GROUP_NUMBER}/application.git
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
1. Créez le fichier `.gitlab-ci.yml` à la racine.
   - Settez l'image avec `image: captnbp/gitlab-ci-image:1.6.0`
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
   >   - template: Security/Dependency-Scanning.gitlab-ci.yml  # https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/Dependency-Scanning.gitlab-ci.yml
   > ```
4. Dès que votre pipeline est fonctionnel et que les tests sont OK, commitez dans votre branche, puis soumettez la Merge Request à votre professeur pour review et approbation.

## Build de l'image Docker

0. Créez une issue `Build Dockerfile` dans le dépôt Gitlab `application`, puis une Merge Request
1. Afin d'éviter de se faire blacklister par Docker Hub (rate limit) :
   - Inscrivez-vous sur le site https://hub.docker.com/, puis créez un Access Token ici : https://hub.docker.com/settings/security
   - Stockez votre access token Docker Hub dans Vault dans le secret nommé : `groupe-<group_number>/dockerhub` en mettant les 2 keys suivantes :
     - `DOCKERHUB_USERNAME` -> votre username de votre compte Docker Hub
     - `DOCKERHUB_ACCESS_TOKEN` -> votre access token
     - `URL` = `https://index.docker.io/v1/` (cf. https://github.com/GoogleContainerTools/kaniko#pushing-to-docker-hub)
   - Dans `.gitlab-ci.yml`, créez un stage `prepare` et un job `vault` associé à ce stage
   - Dans notre job `vault`, il faudra aller faire un `vault read groupe-<group_number>/dockerhub` pour chaque key du secret afin de les intégrer à la création du fichier `/kaniko/.docker/config.json` (en plus des creds déjà settés dans l'exemple de la doc Gitlab)
     - Créer un job qui récupère le compte Docker Hub depuis Vault, construit le fichier `docker.json`, et le met en cache.
       ```yaml
       vault:
         stage: prepare
         image: captnbp/gitlab-ci-image:1.6.0
         variables:
           VAULT_ADDR: https://vault-hitema.doca.cloud:443
         script:
           - export VAULT_TOKEN="$(vault write -field=token auth/jwt/login role=application-groupe-${GROUP_NUMBER} token_ttl=30 jwt=$CI_JOB_JWT)"
           - mkdir -p .docker
           - echo "\"`vault kv get -field=URL secret/groupe-${GROUP_NUMBER}/dockerhub`\":{\"username\":\"`vault kv get -field=DOCKERHUB_USERNAME secret/groupe-${GROUP_NUMBER}/dockerhub`\",\"password\":\"`vault kv get -field=DOCKERHUB_ACCESS_TOKEN secret/groupe-${GROUP_NUMBER}/dockerhub`\"}" > ${CI_PROJECT_DIR}/.docker/config.json
           - vault token revoke -self
         cache:
           key: dockerconfig
           paths:
             - ".docker/config.json"
       ```
2. Nous allons builder l'image Docker avec l'outil kaniko (https://github.com/GoogleContainerTools/kaniko)
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
     Voici un exemple à adapter :
     ```yaml
     docker-build:
       stage: build
       image:
         name: gcr.io/kaniko-project/executor:debug
         entrypoint: [""]
       cache:
         key: dockerconfig
         paths:
           - ".docker/config.json"
       script:
         - export DOCKER_CONFIG=/kaniko/.docker
         - export DOCKER_CREDS=$(cat .docker/config.json)
         - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"},${DOCKER_CREDS}}}" > /kaniko/.docker/config.json
         - /kaniko/executor --context $CI_PROJECT_DIR --dockerfile $CI_PROJECT_DIR/Dockerfile --destination $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
     ```
     - Modifiez le contenu de `requirements.txt` avec:
       ```
       alembic==0.9.1
       appdirs==1.4.3
       click==6.7
       Flask==1.0
       Flask-Migrate==2.0.3
       Flask-Script==2.0.5
       Flask-SQLAlchemy==2.2
       itsdangerous==0.24
       Mako==1.0.6
       MarkupSafe==1.1.1
       packaging==16.8
       psycopg2==2.8.4
       pyparsing==2.2.0
       python-editor==1.0.3
       six==1.10.0
       SQLAlchemy==1.3.20
       Werkzeug==0.15.5
       ```
     - Ajouter le fichier `run.sh` à la racine du dépôt :
       ```sh
       #!/bin/bash
       /usr/local/bin/flask db upgrade
       /usr/local/bin/flask run -h 0.0.0.0 -p 5000
       ```
3. Dès que votre pipeline est fonctionnel et que les tests sont OK, commitez dans votre branche, puis soumettez la Merge Request à votre professeur pour review et approbation.

## Scan de l'image Docker à la recherche de packages vulnérables

0. Créez une issue `Scan Docker image` dans le dépôt Gitlab `application`, puis une Merge Request
1. Ajoutez les variables globales suivantes à votre `.gitlab-ci.yml`:
   ```yaml
   variables:
     CS_ANALYZER_IMAGE: registry.gitlab.com/security-products/container-scanning:4
   ```
2. Créez un stage `security`
3. Ajoutez le scan d'image image façon Gitlab https://docs.gitlab.com/ee/user/application_security/container_scanning/
   ```yaml
   container_scanning:
     image: "$CS_ANALYZER_IMAGE"
     stage: security
     variables:
       # To provide a `vulnerability-allowlist.yml` file, override the GIT_STRATEGY variable in your
       # `.gitlab-ci.yml` file and set it to `fetch`.
       # For details, see the following links:
       # https://docs.gitlab.com/ee/user/application_security/container_scanning/index.html#overriding-the-container-scanning-template
       # https://docs.gitlab.com/ee/user/application_security/container_scanning/#vulnerability-allowlisting
       GIT_STRATEGY: none
       DOCKER_IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
     allow_failure: true
     artifacts:
       reports:
         container_scanning: gl-container-scanning-report.json
       paths: [gl-container-scanning-report.json]
     dependencies: []
     script:
       - gtcs scan
     rules:
       - if: $CONTAINER_SCANNING_DISABLED
         when: never
       - if: $CI_COMMIT_BRANCH &&
             $GITLAB_FEATURES =~ /\bcontainer_scanning\b/
   ```
4. Dès que votre pipeline est fonctionnel et que les tests sont OK, commitez dans votre branche, puis soumettez la Merge Request à votre professeur pour review et approbation.
