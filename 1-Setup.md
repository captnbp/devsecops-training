# Setup de votre environnement

## Création des groupes et ajouts dans Gitlab/Scaleway

0. Création des groupes (max 2 étudiants) de travail (1 système/réseau + 1 dev)
0. Se faire ajouter comme membre **Maintainer** de vrotre groupe Gitlab
    - Créer un compte Gitlab par élève (sauf si déjà fait). 
      
      > **Attention** : merci de mettre votre prénom et nom en tant que Full Name dans votre compte, sinon on ne vous retrouvera pas pour la notation...)

    - Venir voir un prof pour se faire ajouter au sous-groupe **groupe_< number >**
0. Création du compte cloud Scaleway
    - Demandez à votre professeur de vous ajouter à l'organisation Scaleway Hitema
    - Vous allez recevoir un mail pour créer votre compte Scaleway
      
      > **Attention** : merci de mettre votre prénom et nom dans votre profile Scaleway, sinon on ne vous retrouvera pas pour la notation...)

## Configuration de Mattermost

0. Télécharger et installer Mattermost à partir de https://mattermost.com/download/#mattermostApps (Documentation : https://docs.mattermost.com/install/desktop.html)
0. Activez votre compte via cette invitation https://mattermost-hitema.doca.cloud/signup_user_complete/?id=uu1u3jn3m7ys9kx6tfkpiinpka
1. Configurer le server Mattermost privé au démarrage en mettant l'url suivante : https://mattermost-hitema.doca.cloud

   ![Installation](images/mattermost-1.png)

2. Puis se loguer en utilisant le SSO Gitlab

   ![Login](images/mattermost-2.png)
   ![Login](images/mattermost-6.png)

3. Vous êtes logué :

   ![Town Square](images/mattermost-3.png)

4. Créer un channel par groupe nommé **groupe_< number >**

   ![Group](images/mattermost-4.png)

5. Ajouter votre binôme à votre channel Mattermost **groupe_< number >**

   ![Group](images/mattermost-5.png)

## Création des dépôts Gitlab

Cours sur Gitlab CI : https://docs.google.com/presentation/d/1Iu_xR9ab1uzolNxr6-NMCCnDNveh2QGAqeJMvMqQu5A/edit?usp=sharing

Créer 3 projets Gitlab (**`image`**, **`infrastructure`** et **`application`**) dans votre sous-groupe Gitlab **groupe_< number >**
  
> **Attention** : merci de mettre les noms de projets en minuscules

## Connexion à Visual Studio Code Hub puis configuration

Il faut maintenant configurer votre environnement de développement dans votre instance **Visual Studio Code Hub**.

Connectez-vous à l'url suivante : https://code-hitema.doca.cloud avec le navigateur Chrome ou Edge Chromium (pas le vieux Edge ni Firefox ni Safari) et créez votre *server* :

0. Connectez-vous à l'url suivante : https://code-hitema.doca.cloud

   ![Group](images/code-server-0.png)

1. Authorisez Gitlab à vous autentifier dans Code Server Hub

   ![Group](images/code-server-1.png)

2. Créez votre *Server* (votre environnement de développement personnel dans Code-Hitema)

   ![Group](images/code-server-2.png)

3. Dès que votre *Server* est créé, cliquez sur le lien pour l'ouvrir

   ![Group](images/code-server-3.png)


### Configuration de l'IDE

0. Installer les extensions suivantes (`Ctrl + Shift + X`)
    - Gitlab Workflow
    - Hashicorp Terraform
    - Docker
    - hadolint
    - ansible

Fermer et ré ouvrir le navigateur https://code-hitema.doca.cloud pour avoir les extensions 

   ![Group](images/code-server-4.png)

0. Ouvrir un terminal (`Ctrl+Shift+C`)
0. Changer le Default Shell du terminal et utiliser zsh (`/usr/bin/zsh`)

   ![Group](images/code-server-5.png)

0. Fermer le shell bash (`Ctrl+D`) puis ouvrir à nouveau le terminal avec le shell Zsh (`Ctrl+Shift+C`)

### Création des clés SSH

0. Créer un jeu de clé ssh avec `ssh-keygen -t ed25519 -C "${JUPYTERHUB_USER}" -N ""` dans le Terminal Code-Hitema
1. Chaque étudiant doit ajouter sa clé publique ssh `cat $HOME/.ssh/id_ed25519.pub` dans la liste de clé du compte Scaleway (https://console.scaleway.com/project/)
2. Chaque étudiant doit ajouter sa clé publique ssh `cat $HOME/.ssh/id_ed25519.pub` dans son compte Gitlab: https://gitlab.com/profile/keys
    
    > **Attention** : copier coller correctement les clés publiques générées (Pas de retour à la ligne vide, inclure `ssh-ed25519` et `Prénom` dans la sélection de la clé publique)

### Création du Gitlab Personnal Token

0. Se rendre dans les settings de votre profile Gitlab : https://gitlab.com/-/profile/personal_access_tokens
1. Créer votre personal access token avec les paramètres suivants :
    - Name : `VScode`
    - Expiration : `2021-12-31`
    - Scopes : tout cocher

    ![Group](images/gitlab-0.png)
2. Récupérer le token
3. Configurer l'extension Gitlab Workflow (Ctrl+Shift+P)

    3.1. Rechercher "GitLab: Set GitLab Personal Access Token" ensuite taper sur la touche 'Entrée'.

    3.2. Coller votre token et taper ensuite sur la touche 'Entrée'.

   ![Group](images/code-server-6.png)

## Création des dépôts Gitlab

### Images Packer

0. Créer un projet (dépôt) nommé **`image`** dans votre sous-groupe `h3-hitema-devsecops-2021/groupe_<group_number>`
0. Créer une issue dans le dépôt **`image`** nommée `Création de la structure de base du dépôt`
0. Depuis cette issue, créer une merge request (bouton en bas). Cela va aussi créer une branche de travail à utiliser ci-dessous
0. Création de la structure de répertoire du projet **`image`**
    ```sh
    ./packer/
    ./packer/packer.json
    ./doc/
    README.md
    .gitlab-ci.yml
    .gitignore
    LICENSE
    ```
    ```sh
    # Dans votre Terminal code-hitema
    mkdir -p $HOME/code
    cd $HOME/code
    git clone git@gitlab.com:h3-hitema-devsecops-2021/groupe_<group_number>/image.git

    cd image
    git checkout <branche créée dans la merge request de l issue>

    mkdir packer doc
    touch README.md LICENSE .gitignore .gitlab-ci.yml  packer/packer.json

    git add packer doc README.md LICENSE .gitignore .gitlab-ci.yml  packer/packer.json
    git commit -a -m ":tada: Initial commit for folder structure"
    git push
    ```
### Gestion de l'infrastructure via Terraform

0. Créer un projet (dépôt) nommé **`infrastructure`** dans votre sous-groupe `h3-hitema-devsecops-2021/groupe_<group_number>`
0. Créer une issue dans le dépôt **`infrastructure`** nommée `Création de la structure de base du dépôt`
0. Depuis cette issue, créer une merge request (bouton en bas). Cela va aussi créer une branche de travail à utiliser ci-dessous
0. Création de la structure de répertoire du projet **`infrastructure`**
    ```sh
    ./terraform/
    ./terraform/main.tf
    ./postconf_vm/
    ./doc/
    README.md
    .gitlab-ci.yml
    .gitignore
    LICENSE
    ```
    ```sh
    # Dans votre Terminal code-hitema
    cd $HOME/code
    git clone git@gitlab.com:h3-hitema-devsecops-2021/groupe_<group_number>/infrastructure.git

    cd infrastructure
    git checkout <branche créée dans la merge request de l issue>

    mkdir terraform doc postconf_vm
    touch README.md LICENSE .gitignore .gitlab-ci.yml terraform/main.tf

    git add  terraform terraform doc postconf_vm README.md LICENSE .gitignore .gitlab-ci.yml terraform/main.tf
    git commit -a -m ":tada: Initial commit for folder structure"
    git push
    ```

### Application hello-world

0. Créer un projet (dépôt) nommé **`application`** dans votre sous-groupe `h3-hitema-devsecops-2021/groupe_<group_number>`

## Création d'un jeu d'API keys Scaleway dans votre projet Scaleway

0. Se rendre sur la page https://console.scaleway.com/
1. Sélectionner dans la liste des projects votre groupe

   ![Group](images/scaleway-0.png)
2. Clicker sur `Generate new API Key`
3. **Dans le champ `API Key purpose`, mettre `groupe_<group_number>`**
4. Pour le mainteneur des dépôts -> ajouter les credentials de l'API Scaleway dans les variables (cocher `Masked`, décocher `Protected`) du dépôts Gitlab `image` : `Settings -> CI / CD -> Variables`:
    - **SCW_DEFAULT_PROJECT_ID** : Votre Project ID Scaleway (https://console.scaleway.com/project/settings)
    - **SCW_DEFAULT_ORGANIZATION_ID** : Votre Project ID Scaleway (https://console.scaleway.com/project/settings)
    - **SCW_ACCESS_KEY** : Votre Access key Scaleway
    - **SCW_SECRET_KEY** : Votre Secret key Scaleway
    - **SCW_DEFAULT_ZONE** : fr-par-1

## Configuration des variables d'environnement de Gitlab CI dans nos 3 dépôts

0. Création d'un jeu de clé publique ssh pour Gitlab (1 jeu par groupe)
    ```sh
    TEMP_DIR=`mktemp -d`
    ssh-keygen -t ed25519 -f ${TEMP_DIR}/id_ed25519 -C gitlab -N ""
      Generating public/private ed25519 key pair.
      Enter passphrase (empty for no passphrase): 
      Enter same passphrase again: 
      Your identification has been saved in gitlab/id_ed25519.
      Your public key has been saved in /tmp/tmp.TU8zUhNwem/id_ed25519.pub.
      The key fingerprint is:
      SHA256:ppy6HdBQifHSpL+iyoGnxDdV2LZFvucLVrk6w1ph8xk gitlab
      The keys randomart image is:
      +--[ED25519 256]--+
      |    .oo. .       |
      |    .*+ o        |
      |    +.o+ o       |
      |     =o o . .    |
      |    ..o.S= E     |
      |o   .o =. B +    |
      |.+.o. * .+ =     |
      |ooo..+ .o+o .    |
      |oo. o.....o.     |
      +----[SHA256]-----+

    # SSH_PRIV_KEY
    cat ${TEMP_DIR}/id_ed25519
      -----BEGIN OPENSSH PRIVATE KEY-----
      b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
      QyNTUxOQAAACDWlIqL/xVwlFc736N2rYFnKPhgnppJDM184bcnMdwFGgAAAJhevlgOXr5Y
      DgAAAAtzc2gtZWQyNTUxOQAAACDWlIqL/xVwlFc736N2rYFnKPhgnppJDM184bcnMdwFGg
      AAAECooyRCYytqdN9wIFsprhqAzRLUpinwZmmX97aHFTXO8NaUiov/FXCUVzvfo3atgWco
      +GCemkkMzXzhtycx3AUaAAAADmJlbm9pdEBkZXNrdG9wAQIDBAUGBw==
      -----END OPENSSH PRIVATE KEY-----

    # SSH_PUB_KEY
    cat ${TEMP_DIR}/id_ed25519.pub 
      ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINaUiov/FXCUVzvfo3atgWco+GCemkkMzXzhtycx3AUa gitlab
    
    rm -R ${TEMP_DIR}
    ```
1. Pour le mainteneur des dépôts -> ajouter les clés ssh générées précédemment dans les variables (décocher `Masked`, décocher `Protected`) des 2 dépôts Gitlab `infrastructure` et `application` (mais pas `image`): `Settings -> CI / CD -> Variables`:
    - **SSH_PRIV_KEY**
    - **SSH_PUB_KEY**
    
    > **Attention** : copier coller correctement les clés générées (Pas de retour à la ligne vide, inclure les `-----BEGIN OPENSSH PRIVATE KEY-----`  et `-----END OPENSSH PRIVATE KEY-----` dans la sélection avant de copier, inclure `ssh-ed25519` et `gitlab` dans la sélection de la clé publique)

2. Pour le mainteneur des dépôts -> ajouter les credentials de l'API Scaleway dans les variables (décocher `Masked`, décocher `Protected`) du dépôts Gitlab `infrastructure` : `Settings -> CI / CD -> Variables`:
    - **ANSIBLE_HOST_KEY_CHECKING** : False
    - **SCW_DEFAULT_ORGANIZATION_ID** : Votre Project ID Scaleway (https://console.scaleway.com/project/settings)
    - **SCW_DEFAULT_ZONE** : fr-par-1

3. Pour le mainteneur des dépôts -> ajouter les credentials de l'API Scaleway dans les variables (décocher `Masked`, décocher `Protected`) du dépôts Gitlab `application` : `Settings -> CI / CD -> Variables`:
    - **ANSIBLE_HOST_KEY_CHECKING** : False
    - **SCW_DEFAULT_ORGANIZATION_ID** : Votre Project ID Scaleway (https://console.scaleway.com/project/settings)
    - **SCW_DEFAULT_ZONE** : fr-par-1

### Devoirs du soir
Lire
*  https://learn.hashicorp.com/packer
*  https://learn.hashicorp.com/terraform
