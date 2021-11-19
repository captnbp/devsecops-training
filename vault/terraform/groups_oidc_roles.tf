resource "vault_jwt_auth_backend_role" "gitlab_oidc_groups" {
  count = 22
  backend         = vault_jwt_auth_backend.gitlab_oidc.path
  role_name       = "groupe-${count.index}"
  token_policies  = ["default", "students-ssh", "beats-groupe-${count.index}", "groupe-${count.index}-dev", "groupe-${count.index}-prd", "rundeck-groupe-${count.index}-dev", "rundeck-groupe-${count.index}-prd", "db-groupe-${count.index}-dev", "db-groupe-${count.index}-prd"]
  token_ttl       = "86000"

  bound_audiences = ["5d239a55568c051cb1da88208d6492da97f4dc708cce007d2b1317ba9bd98608"]
  user_claim      = "sub"
  role_type       = "oidc"
  oidc_scopes     = ["openid"]
  allowed_redirect_uris = [
    "http://localhost:8250/oidc/callback",
    "https://vault-hitema.doca.cloud/oidc/callback",
    "https://vault-hitema.doca.cloud/ui/vault/auth/oidc/oidc/callback"
  ]
  bound_claims    = { 
    groups = "h3-hitema-devsecops-2021/groupe_${count.index}"
  }
}