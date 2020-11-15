resource "vault_jwt_auth_backend_role" "gitlab_oidc_groups" {
  count = 54
  backend         = vault_jwt_auth_backend.gitlab_oidc.path
  role_name       = "groupe-${count.index}"
  token_policies  = ["default", "students-ssh", "beats-groupe-${count.index}", "groupe-${count.index}-dev", "groupe-${count.index}-prd", "rundeck-groupe-${count.index}-dev", "rundeck-groupe-${count.index}-prd", "db-groupe-${count.index}-dev", "db-groupe-${count.index}-prd"]
  token_ttl       = "86000"

  bound_audiences = ["552bd9ab910c33884e76c9bb7323c8dfe2bd24320eecb0fc9106835087abc6a8"]
  user_claim      = "sub"
  role_type       = "oidc"
  oidc_scopes     = ["openid"]
  allowed_redirect_uris = [
    "http://localhost:8250/oidc/callback",
    "https://vault-hitema.doca.cloud/oidc/callback",
    "https://vault-hitema.doca.cloud/ui/vault/auth/oidc/oidc/callback"
  ]
  bound_claims    = { 
    groups = "hitema-devsecops-2020/group_${count.index}"
  }
}