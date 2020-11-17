# Création de 2 infrastructures automatiquement via Terraform

Nous souhaitons construire automatiquement notre datacenter/infrastructure qui va héberger notre application.

Pour cela vous allez déployer votre infratructure avec l'outil Terraform dans votre projet dédié Scaleway.

Notre application a besoin d'une VM Ubuntu utilisant l'image VM que nous avons buildée avec Packer, une base de données Postgresql, des règles de Firewall strictes, un volume de 30Go pour stocker les données de l'application.

Voici le détail :
- Une variable `environnement` passée en argument lors de l'exécution de Terraform.
- Une variable `image` passée en argument lors de l'exécution de Terraform.
- Une ip publique pour notre VM et lui assigner
- Une VM :
  - Type de VM : `DEV1-S`
  - Nom : variable `environnement`
  - Image OS : variable `image`
  - Activer IPv6 sur la VM
  - Tags : hitema,group-<group number>,variable `environnement`
- Créer un groupe de sécurité (attaché à la VM) qui va contenir les règles suivantes :
  - Nom : variable `environnement`
  - Inbound : policy par défaut -> drop
    - Port 22 (SSH) depuis `0.0.0.0/0`
    - Port 80 (HTTP) depuis `0.0.0.0/0`
    - Port 443 (HTTPS) depuis `0.0.0.0/0`
  - Outbound : policy par défaut -> accept
- Un volume de données :
  - Nom : variable `environnement`
  - Taille : 30Go
  - Type : `b_ssd`

## Documentation

- Gitlab: https://docs.gitlab.com/ee/ci/introduction/
- Terraform: https://www.terraform.io/docs/providers/scaleway/index.html
- Terraform states in Gitlab CI HTTP backend : https://docs.gitlab.com/ee/user/infrastructure/terraform_state.html#get-started-using-gitlab-ci

## Terraform

0. Cours sur Terraform
1. Créez une nouvelle issue nommée `Création d'une infrastructure Scaleway avec Terraform` puis créez sa Merge Request. Ensuite pullez le code, et changez de branche pour utiliser la nouvelle branche
2. A partir des spécifications ci-dessus, créez le fichier `terraform/main.tf` et ajoutez l'ensemble des resources nécessaires pour créer notre infrastructure. 
   
   Voici le début qui déclare les 2 variables à passer en argument de la commande terraform et l'import du plugin de provide Terraform à la bonne version :
   ```hcl
   variable image {}
   variable environnement {}
 
   terraform {
     required_providers {
       scaleway = {
         source = "scaleway/scaleway"
         version = "1.17.0"
       }
     }
   }
   ```
3. Pour tester en local depuis le terminal de code-hitema avant de commiter :
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
     export IMAGE_TAG=1.0.1
     ```
   - Puis :
     ```bash
     cd terraform
     terraform init
     terraform validate -var image="ubuntu-hitema-1.0.1" -var environnement="cli"
     terraform plan -var image="ubuntu-hitema-1.0.1" -var environnement="cli"
     terraform apply -var image="ubuntu-hitema-1.0.1" -var environnement="cli"
     ```
4. Une fois votre infrastructure déployée avec succès, récupérez l'adresse IP de votre VM dans l'interface Scaleway (https://console.scaleway.com/instance/servers)
   ```bash
   vault write -field=signed_key ssh/sign/students public_key=@$HOME/.ssh/id_ed25519.pub > $HOME/.ssh/id_ed25519-cert.pub
   ssh -i $HOME/.ssh/id_ed25519-cert.pub -i $HOME/.ssh/id_ed25519 root@<Addresse IP de votre VM>
   ```
5. Faites une petite démo à votre professeur si ça a marché !
6. Maintenant que votre déploiement Terraform est fonctionnel en test, nous allons le **destroy** pour passer à l'industrialisation :
   ```bash
   terraform destroy -var image="ubuntu-hitema-1.0.1" -var environnement="cli"
   ```
7. Enfin commitez dans votre branche votre fichier `terraform/main.tf`

## Intégration à Gitlab CI pour gérer automatiquement l'infrastructure

   Voici le début qui déclare les 2 variables à passer en argument de la commande terraform et l'import du plugin de provide Terraform à la bonne version :
   ```hcl
   variable image {}
   variable environnement {}
 
   terraform {
     backend "http" {}
     required_providers {
       scaleway = {
         source = "scaleway/scaleway"
         version = "1.17.0"
       }
     }
   }
   ```