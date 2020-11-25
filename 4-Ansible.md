# Ansible pour customiser notre image et notre VM

Nous allons d'abord améliorer la sécurité initiale de notre image VM générée par Packer. En effet il est plus que recommandé de déployer une VM déjà sécurisée, que de déployer une VM non sécurisée et donc vulnérable, puis de la sécuriser en post déploiement alors qu'elle est potentiellement déjà piratée.

Afin de faciliter la configuration de l'image de la VM, nous allons utiliser Ansible plutôt qu'un script shell difficile à maintenir pour des opérations complexes.

Ensuite, nous utiliserons une nouvelle fois pour faire de la post-configuration de notre VM déployée.

Cours sur Ansible : https://docs.google.com/presentation/d/1y7JRD_yCUBOLE22fXfak5Zt6qeMQMYSpyK8P6YB0lio/edit#slide=id.ga201d4bac2_0_68 
## Sécurisation de base de notre image VM (image)

Nous allons appliquer l'amélioration suivante de sécurité à notre image VM :
- Installation et configuration de Fail2ban, un outil qui détecte les attaques par brute-force sur notre VM puis blackliste les IPs attaquantes dans le firewall linux `iptables`. Voici une introduction à Fail2ban : https://linuxize.com/post/install-configure-fail2ban-on-ubuntu-20-04/

0. Dans le dépôt `image`, créez une issue `Installation de Fail2ban pour protéger SSH des attaques par brut-force`, puis créez la Merge Request et sa branche associée.
1. Dans Code-Hitema, pullez le code et basculez sur la nouvelle branche.
2. En vous référant à https://www.packer.io/docs/provisioners/ansible, ajouter un 2e provisioner à votre fichier `packer/packer.json à la suite du provisionner de type shell.
3. Créer un fichier `packer/playbook.yml` et :
   - Créez le playbook qui va installer le package `fail2ban` sur l'image.
   - Ajoutez une task pour updater la liste de packages (`update_cache`) tout en installant le package `fail2ban` : https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_module.html
   - Ajoutez une task pour nettoyer le cache APT : 
     ```yaml
     - name: Remove useless packages from the cache
       apt:
         autoclean: yes

     - name: Remove dependencies that are no longer required
       apt:
         autoremove: yes
     ```
4. Pour tester en local depuis le terminal de code-hitema avant de commiter :
   - Ouvrez la page https://vault-hitema.doca.cloud/ui/ et récupérez votre `VAULT_TOKEN` :

     ![Vault Token](images/vault-3.png)
     
   - Créez la variable d'environnement dans le Terminal de Code-Hitema :
     ```bash
     export VAULT_TOKEN=<Le token précédement récupéré>
     export GROUPE_NUMBER=<groupe number>
     ```
   - Exportez les les variables d'environnement nécessaire à l'exécution de Packer :
     ```bash
     export SCW_DEFAULT_PROJECT_ID=$(vault read -field=SCW_DEFAULT_PROJECT_ID secret/groupe-${GROUPE_NUMBER}/scaleway)
     export SCW_DEFAULT_ORGANIZATION_ID=$(vault read -field=SCW_DEFAULT_ORGANIZATION_ID secret/groupe-${GROUPE_NUMBER}/scaleway)
     export SCW_ACCESS_KEY=$(vault read -field=SCW_ACCESS_KEY secret/groupe-${GROUPE_NUMBER}/scaleway)
     export SCW_SECRET_KEY=$(vault read -field=SCW_SECRET_KEY secret/groupe-${GROUPE_NUMBER}/scaleway)
     export SCW_DEFAULT_ZONE=$(vault read -field=SCW_DEFAULT_ZONE secret/groupe-${GROUPE_NUMBER}/scaleway)
     export SCW_IMAGE=$(scw instance image list name=ubuntu-hitema-1.0.2 -o json | jq -r ".[0].ID")
     export IMAGE_TAG=1.0.2
     ```
   - Puis :
     ```bash
     cd packer
     packer validate packer.json
     packer build packer.json
     ```
6. Si le test est passé, commitez votre code sur la branche et pushez
   ```bash
   git commit packer/playbook.yml packer/packer.json -m "Install fail2ban with Ansible"
   git tag -a v1.0.3
   git push
   git push --tags
   ```
5. Demandez une revue de code à votre professeur en l'assignant à votre MR dans Gitlab, puis une fois la Merge Request approuvée, mergez la branche puis taguez la branche master en `1.0.3`

## Post-configuration de la VM (infrastructure)

Pour notre post-configuration nous allons :
- Configurer le volume disque que nous avons attaché à la VM avec Terraform
- Créer un `docker network` nommé `web` de type bridge
- Déployer Traefik afin d'exposer notre future application sur internet, et de la sécuriser automatiquement avec des certificats TLS Let's Encrypt.
- Le protéger avec Fail2ban afin de banir/blaclister les IPs des attaquants potentiels

### Configuration du volume

Quand on commande une VM dans le cloud, elle se déploie avec un seul volume disque : celui du système -> `/`. Il fait en générale 20Go.

Ce volume est considéré comme éphémère, c'est-à-dire que :
- Si on supprime la VM il est supprimé avec.
- Si la VM change d'hyperviseur, la VM va redémarrer avec l'image configurée au déploiement

**Dans les 2 cas on va perdre nos données.**

La solution, c'est d'attacher 1 ou n volumes disque à notre VM et stocker les données dedans. Les volumes son répliqués, et survivent aux 2 événements cités ci-dessus.

Dans notre déploiement Terraform du TP précédent nous avons créé et attaché un volume bloc de 30Go à notre VM.

Lorsque que nous avons déployé, la VM a été créée avec ce volume. Cependant, il apparaît comme un disque vierge, pas de partition, pas de filesystem.

Nous allons donc faire les actions suivantes en post configuration avec Ansible :
- Création de la partition numéro 1 sur le disque `/dev/sda`
  > Pour trouver le disque associé au volume vous pouvez taper les commandes suivantes sur la VM en SSH:
    ```bash
    root@cli:~# lsblk
    NAME    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
    loop0     7:0    0 71.3M  1 loop /snap/lxd/16044
    loop1     7:1    0 29.8M  1 loop /snap/snapd/8140
    loop2     7:2    0   55M  1 loop /snap/core18/1754
    sda       8:0    0   28G  0 disk 
    vda     254:0    0 18.6G  0 disk 
    ├─vda1  254:1    0 18.5G  0 part /
    ├─vda14 254:14   0    4M  0 part 
    └─vda15 254:15   0  106M  0 part /boot/efi
    ```

    ```bash
    root@cli:~# ll /dev/disk/*
    /dev/disk/by-id:
    total 0
    drwxr-xr-x 2 root root  60 Nov 21 11:43 ./
    drwxr-xr-x 7 root root 140 Nov 21 11:43 ../
    lrwxrwxrwx 1 root root   9 Nov 21 11:43 scsi-0SCW_b_ssd_volume-95d1ae59-aaa9-4703-b413-5484f76e534b -> ../../sda

    /dev/disk/by-label:
    total 0
    drwxr-xr-x 2 root root  80 Nov 21 11:43 ./
    drwxr-xr-x 7 root root 140 Nov 21 11:43 ../
    lrwxrwxrwx 1 root root  11 Nov 21 11:43 UEFI -> ../../vda15
    lrwxrwxrwx 1 root root  10 Nov 21 11:43 cloudimg-rootfs -> ../../vda1

    /dev/disk/by-partuuid:
    total 0
    drwxr-xr-x 2 root root 100 Nov 21 11:43 ./
    drwxr-xr-x 7 root root 140 Nov 21 11:43 ../
    lrwxrwxrwx 1 root root  11 Nov 21 11:43 38191e9d-fa25-4e29-8f7b-2bfd0032571c -> ../../vda15
    lrwxrwxrwx 1 root root  11 Nov 21 11:43 f97f22b9-8ccc-4c14-bdc3-b451bf8c929d -> ../../vda14
    lrwxrwxrwx 1 root root  10 Nov 21 11:43 fc220e13-bb33-43c7-a49a-90d85d9edc7f -> ../../vda1

    /dev/disk/by-path:
    total 0
    drwxr-xr-x 2 root root 220 Nov 21 11:43 ./
    drwxr-xr-x 7 root root 140 Nov 21 11:43 ../
    lrwxrwxrwx 1 root root   9 Nov 21 11:43 pci-0000:00:03.0-scsi-0:0:0:0 -> ../../sda
    lrwxrwxrwx 1 root root   9 Nov 21 11:43 pci-0000:00:04.0 -> ../../vda
    lrwxrwxrwx 1 root root  10 Nov 21 11:43 pci-0000:00:04.0-part1 -> ../../vda1
    lrwxrwxrwx 1 root root  11 Nov 21 11:43 pci-0000:00:04.0-part14 -> ../../vda14
    lrwxrwxrwx 1 root root  11 Nov 21 11:43 pci-0000:00:04.0-part15 -> ../../vda15
    lrwxrwxrwx 1 root root   9 Nov 21 11:43 virtio-pci-0000:00:04.0 -> ../../vda
    lrwxrwxrwx 1 root root  10 Nov 21 11:43 virtio-pci-0000:00:04.0-part1 -> ../../vda1
    lrwxrwxrwx 1 root root  11 Nov 21 11:43 virtio-pci-0000:00:04.0-part14 -> ../../vda14
    lrwxrwxrwx 1 root root  11 Nov 21 11:43 virtio-pci-0000:00:04.0-part15 -> ../../vda15

    /dev/disk/by-uuid:
    total 0
    drwxr-xr-x 2 root root  80 Nov 21 11:43 ./
    drwxr-xr-x 7 root root 140 Nov 21 11:43 ../
    lrwxrwxrwx 1 root root  10 Nov 21 11:43 019c1001-f165-4e07-901f-de02b70c2bac -> ../../vda1
    lrwxrwxrwx 1 root root  11 Nov 21 11:43 DEA7-AD37 -> ../../vda15
    ```
    Notez que la ligne `lrwxrwxrwx 1 root root   9 Nov 21 11:43 scsi-0SCW_b_ssd_volume-95d1ae59-aaa9-4703-b413-5484f76e534b -> ../../sda` contient l'id `95d1ae59-aaa9-4703-b413-5484f76e534b` de notre volume que vous pouvez apercevoir dans l'output de Terraform, mais aussi dans l'UI Scaleway. On voit que notre volume est bien `/dev/sda`

- Formatage de la partition en `ext4`
- Créer le répertoire `/data` sur la VM avec le mode `0755`, le owner `root`, le groupe `root`
- Monter la partition créée sur le filesystem de la VM dans `/data` avec l'option `noatime`, et configurer son montage persistant dans `/etc/fstab`

Afin d'implementer les spécifications ci-dessus, nous allons créer un role Ansible dans le répertoire `postconf_vm/roles` de notre dépôt `infrastructure` :

0. Dans le dépôt `infrastructure`, créez une issue `Post-config - Volume`, puis créez la Merge Request et sa branche associée.
1. Dans Code-Hitema, pullez le code et basculez sur la nouvelle branche.
2. Créez la structure de répertoires suivante :
   ```bash
   mkdir postconf_vm/roles
   mkdir postconf_vm/roles/partitions
   mkdir postconf_vm/roles/partitions/tasks
   touch postconf_vm/roles/partitions/tasks/main.yml
   ```
3. Ouvrez et éditez le fichier `postconf_vm/roles/partitions/tasks/main.yml` dans code-hitema.
4. A laide des modules Ansible suivants : 
   - [community.general.parted](https://docs.ansible.com/ansible/latest/collections/community/general/parted_module.html)
   - [community.general.filesystem](https://docs.ansible.com/ansible/latest/collections/community/general/filesystem_module.html)
   - [file](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/file_module.html)
   - [ansible.posix.mount](https://docs.ansible.com/ansible/latest/collections/ansible/posix/mount_module.html)
   
   écrivez les tasks suivantes dans `postconf_vm/roles/partitions/tasks/main.yml` :
   - Create the data partition
   - Format data partition
   - Create data folder
   - Mount data partition
5. Crééz le fichier d'[inventaire Ansible dynamique](https://docs.ansible.com/ansible/latest/scenario_guides/guide_scaleway.html#dynamic-inventory-script) suivant `postconf_vm/scaleway-ansible-inventory.yml`:
   ```yaml
   plugin: scaleway
   regions:
     - par1
   ```

   Ce fichier va permettre à Ansible de lister toutes les VMs qui matchent les critères dans le fichier (ici région fr-par) et présenter des groupes de VMs par tag à Ansible
6. Créez maintenant votre Playbook Ansible `postconf_vm/playbook.yml` qui va permettre d'exécuter le role `partitions` sur la VM remontée par l'inventaire dynamique Ansible :
   - Afin d'être sûr de déployer sur la bonne VM, le playbook devra s'exécuter sur le groupe de `hosts: production`
   - Le remote user devra être `root`
   - Le role à exécuter est `partitions`
7. Nous allons maintenant tester notre playbook en CLI depuis le terminal code-hitema:
   - Ouvrez la page https://vault-hitema.doca.cloud/ui/ et récupérez votre `VAULT_TOKEN` :

     ![Vault Token](images/vault-3.png)
     
   - Créez la variable d'environnement dans le Terminal de Code-Hitema :
     ```bash
     export VAULT_TOKEN=<Le token précédement récupéré>
     export GROUPE_NUMBER=<groupe number>
     ```
   - Exportez les les variables d'environnement nécessaire à l'exécution de Packer :
     ```bash
     export SCW_DEFAULT_PROJECT_ID=$(vault read -field=SCW_DEFAULT_PROJECT_ID secret/groupe-${GROUPE_NUMBER}/scaleway)
     export SCW_DEFAULT_ORGANIZATION_ID=$(vault read -field=SCW_DEFAULT_ORGANIZATION_ID secret/groupe-${GROUPE_NUMBER}/scaleway)
     export SCW_ACCESS_KEY=$(vault read -field=SCW_ACCESS_KEY secret/groupe-${GROUPE_NUMBER}/scaleway)
     export SCW_SECRET_KEY=$(vault read -field=SCW_SECRET_KEY secret/groupe-${GROUPE_NUMBER}/scaleway)
     export SCW_DEFAULT_ZONE=$(vault read -field=SCW_DEFAULT_ZONE secret/groupe-${GROUPE_NUMBER}/scaleway)
     export SCW_TOKEN=$(vault read -field=SCW_SECRET_KEY secret/groupe-${GROUPE_NUMBER}/scaleway)
     export SCW_IMAGE=$(scw instance image list name=ubuntu-hitema-1.0.3 -o json | jq -r ".[0].ID")
     ```
   - Puis :
     ```bash
     cd postconf_vm/
     vault write -field=signed_key ssh/sign/students public_key=@$HOME/.ssh/id_ed25519.pub > $HOME/.ssh/id_ed25519-cert.pub
     ansible-inventory --list -i scaleway-ansible-inventory.yml
     ansible-lint .
     ansible-playbook -i scaleway-ansible-inventory.yml -l production playbook.yml
     ```
     > Pour installer ansible-lint : 
     > ```bash
     > pip3 install ansible-lint
     > ```
     > Et pour l'utiliser :
     > ```bash
     > /home/coder/.local/bin/ansible-lint .
     > ```
8. Si le test manuel est passé, commitez votre code sur la branche et pushez
   ```bash
   git commit .gitlab-ci.yml postconf_vm/playbook.yml postconf_vm/scaleway-ansible-inventory.yml postconf_vm/roles/partitions/tasks/main.yml -m "Setup volume in VM"
   git push
   ```
9. On va maintenant intégrer le déploiement du playbook Ansible à Gilab CI après que l'infratructure sera déployée via Terraform.
   - Ajoutez un stage `postconf_vm` à votre fichier `.gitlab-ci.yml`
   - Ajouez le job suivant à la fin du fichier :
     ```yaml
     ansible_lint:
       stage: validate
       script:
         - cd ${CI_PROJECT_DIR}/postconf_vm
         - ansible-lint .
     
     postconf:
       stage: postconf
       environment:
         name: production
       script:
         # Install ssh-agent if not already installed
         - 'which ssh-agent || ( apt-get update -y && apt-get install openssh-client -y )'
         - eval "$(ssh-agent -s)"

         # Add the SSH key stored in SSH_PRIV_KEY variable to the agent store
         - echo "$SSH_PRIV_KEY" | tr -d '\r' | ssh-add - > /dev/null

         # Create the SSH directory and give it the right permissions
         - mkdir -p ~/.ssh
         - chmod 700 ~/.ssh

         # Make Vault sign our public key and store the SSH certificate in .ssh/
         - vault write -field=signed_key ssh/sign/gitlab public_key=${SSH_PUB_KEY} > ${HOME}/.ssh/id_ed25519.pub
         
         # Deploy
         - cd postconf_vm
         - ansible-playbook -i scaleway-ansible-inventory.yml -l production playbook.yml --syntax-check
         - ansible-playbook -i scaleway-ansible-inventory.yml -l production playbook.yml
       only:
         - master
     ```
     - Changez le tag de l'image dans `before_script` pour avoir `1.0.3` au lieu de `1.0.1`
10. Demandez une revue de code à votre professeur en l'assignant à votre MR dans Gitlab, puis une fois la Merge Request approuvée, mergez la branche et constatez le déploiement de votre playbook.

#### Amélioration de la sécurité des clés SSH de Gitlab CI

Laisser des secrets statiques dans Gitlab n'est pas ce qui est de mieux en terme de sécurité. Nous préférons avoir des secrets temporaires, jetables et dynamiques. D'où la proposition suivant pour les clés SSH utilisées par Gitlab.

1.  Nous allons maintenant faire une amélioration de sécurité pour la gestion du jeu de clé SSH de Gitlab, celui que nous avons mis dans les variables CI/CD des projets `infrastructure` et `application` :
    - Supprimez ces variables des 2 projets
    - Faites une issue `Suppression des clés SSH statiques Gitlab`, puis une Merge Request, et enfin pullez le code dans code-hitema, et checkoutez sur la branche nouvellement créée.
    - Adaptez le job de `postconf` dans `.gitlab-ci.yml` pour ne plus utiliser les clés statiques depuis les variables CI/CD, en créant un nouveau jeu de clé SSH temporaire de type `ed25519`
    - C'est ce nouveau jeu de clés temporaire qui sera signé par la commande `vault write -field=signed_key ssh/sign/gitlab public_key=${SSH_PUB_KEY} > ${HOME}/.ssh/id_ed25519.pub`
2.  Commitez, pushez, et si tout se passe bien, montrez le résultat à votre professeur pour qu'il merge votre Merge Request.


### Traefik
Nous voulons déployer Traefik afin d'exposer notre future application sur internet, et de la sécuriser automatiquement avec des certificats TLS Let's Encrypt.

Pour cela :
- Créez un `docker network` nommé `web` de type `bridge`
- Déployez Traefik dans un container Docker 
- Protégez le avec Fail2ban afin de banir/blaclister les IPs des attaquants potentiels

Afin d'implementer les spécifications ci-dessus, nous allons créer un role Ansible dans le répertoire `postconf_vm/roles` de notre dépôt `infrastructure` :

0. Dans le dépôt `infrastructure`, créez une issue `Post-config - Déploiement de Traefik`, puis créez la Merge Request et sa branche associée.
1. Dans Code-Hitema, pullez le code et basculez sur la nouvelle branche.
2. Créez la structure de répertoires suivante :
   ```bash
   mkdir postconf_vm/roles/traefik
   mkdir postconf_vm/roles/traefik/tasks
   touch postconf_vm/roles/traefik/tasks/main.yml
   ```
3. Ouvrez et éditez le fichier `postconf_vm/roles/traefik/tasks/main.yml` dans code-hitema.
4. A laide des modules Ansible suivants : 
   - [community.general.docker_network](https://docs.ansible.com/ansible/latest/collections/community/general/docker_network_module.html)
   - [community.general.docker_container](https://docs.ansible.com/ansible/latest/collections/community/general/docker_container_module.html)
   
   écrivez les tasks suivantes dans `postconf_vm/roles/traefik/tasks/main.yml` :
   - Create the web docker network
   - Deploy Traefik
     ```yaml
     - name: Deploy Traefik
       community.general.docker_container:
         name: traefik
         state: started
         image: traefik:v2.3
         command:
           - "--providers.docker.endpoint=unix:///var/run/docker.sock"
           - "--providers.docker.exposedbydefault=false"
           - "--api.insecure=true"
           - "--providers.docker=true"
           - "--providers.docker.network=traefik-public"
           - "--entrypoints.web.address=:80"
           - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
           - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
           - "--entrypoints.web.http.redirections.entrypoint.permanent=true"
           - "--entrypoints.websecure.address=:443"
           - "--certificatesresolvers.letsencryptresolver.acme.httpchallenge=true"
           - "--certificatesresolvers.letsencryptresolver.acme.httpchallenge.entrypoint=web"
           - "--certificatesresolvers.letsencryptresolver.acme.email={{ lookup('env','GITLAB_USER_EMAIL') }}"
           - "--certificatesresolvers.letsencryptresolver.acme.storage=/letsencrypt/acme.json"
           - "--accesslog=true"
           - "--accesslog.filepath=/var/log/access.log"
         restart_policy: always
         published_ports:
           - "80:80"
           - "443:443"
         networks:
           - name: web
         volumes:
           - /var/run/docker.sock:/var/run/docker.sock
           - /var/log/:/var/log/traefik
           # To persist certificates
           - traefik-certificates:/letsencrypt
         labels:
           - "co.elastic.logs/module=traefik"
     ```
   - Enable Fail2ban jail for Traefik
     - Créer le fichier `/etc/fail2ban/jail.d/traefik.conf` avec le contenu suivant :
       ```
       [traefik-auth]
       enabled = true
       port = http,https
       ```
   - Restart fail2ban
5. Ajoutez le role `traefik` à votre `postconf_vm/playbook.yml`
6. Nous allons maintenant tester notre playbook en CLI depuis le terminal code-hitema:
   - Ouvrez la page https://vault-hitema.doca.cloud/ui/ et récupérez votre `VAULT_TOKEN` :

     ![Vault Token](images/vault-3.png)
     
   - Créez la variable d'environnement dans le Terminal de Code-Hitema :
     ```bash
     export VAULT_TOKEN=<Le token précédement récupéré>
     export GROUPE_NUMBER=<groupe number>
     ```
   - Exportez les les variables d'environnement nécessaire à l'exécution d'Ansible :
     ```bash
     export SCW_DEFAULT_PROJECT_ID=$(vault read -field=SCW_DEFAULT_PROJECT_ID secret/groupe-${GROUPE_NUMBER}/scaleway)
     export SCW_DEFAULT_ORGANIZATION_ID=$(vault read -field=SCW_DEFAULT_ORGANIZATION_ID secret/groupe-${GROUPE_NUMBER}/scaleway)
     export SCW_ACCESS_KEY=$(vault read -field=SCW_ACCESS_KEY secret/groupe-${GROUPE_NUMBER}/scaleway)
     export SCW_SECRET_KEY=$(vault read -field=SCW_SECRET_KEY secret/groupe-${GROUPE_NUMBER}/scaleway)
     export SCW_DEFAULT_ZONE=$(vault read -field=SCW_DEFAULT_ZONE secret/groupe-${GROUPE_NUMBER}/scaleway)
     export SCW_TOKEN=$(vault read -field=SCW_SECRET_KEY secret/groupe-${GROUPE_NUMBER}/scaleway)
     ```
   - Puis :
     ```bash
     cd postconf_vm/
     vault write -field=signed_key ssh/sign/students public_key=@$HOME/.ssh/id_ed25519.pub > $HOME/.ssh/id_ed25519-cert.pub
     ansible-lint .
     ansible-inventory --list -i scaleway-ansible-inventory.yml
     ansible-playbook -i scaleway-ansible-inventory.yml -l production playbook.yml --syntax-check
     ansible-playbook -i scaleway-ansible-inventory.yml -l production playbook.yml
     ```
7. Si le test manuel est passé, commitez votre code sur la branche et pushez
   ```bash
   git commit .gitlab-ci.yml postconf_vm/playbook.yml postconf_vm/roles/traefik/tasks/main.yml -m "Setup Traefik"
   git push
   ```
8. Demandez une revue de code à votre professeur en l'assignant à votre MR dans Gitlab, puis une fois la Merge Request approuvée, mergez la branche et constatez le déploiement de votre playbook.
