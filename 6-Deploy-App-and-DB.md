# Déploiement de l'application et sa DB

## Déploiement de la DB Postgresql

5. Déploiement de Postgresql via Ansible en mode Docker sur la VM avec volume data dans infrastructure
   - Création des creds dans Ansible avec stockage dans Vault
   - Déploiement du container en allant chercher les creds dans Vault
6. Déploiement de l'application avec creds from  vault, intégration à Traefik