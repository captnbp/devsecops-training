
resource "vault_jwt_auth_backend" "gitlab_jwt" {
  description  = "Use Gitlab JWT provider for Gitlab CI"
  path = "jwt"
  jwks_url = "https://gitlab.com/-/jwks"
  bound_issuer = "gitlab.com"
}

resource "vault_jwt_auth_backend_role" "packer" {
  count = 54
  backend         = vault_jwt_auth_backend.gitlab_jwt.path
  role_name       = "packer-groupe-${count.index}"
  token_policies  = ["default", "groupe-${count.index}-gitlab", "beats-role-${count.index}"]
  token_explicit_max_ttl = 600

  bound_claims = {
    project_path = "hitema-devsecops-2020/group_${count.index}/image"
  }

  user_claim      = "user_email"
  role_type       = "jwt"
}

resource "vault_jwt_auth_backend_role" "dev" {
  count = 54
  backend         = vault_jwt_auth_backend.gitlab_jwt.path
  role_name       = "dev-groupe-${count.index}"
  token_policies  = ["default", "gitlab-ssh", "groupe-${count.index}-gitlab", "db-groupe-${count.index}-dev", "rundeck-groupe-${count.index}-dev", "beats-role-${count.index}"]
  token_explicit_max_ttl = 600

  bound_claims = {
    namespace_path = "hitema-devsecops-2020/group_${count.index}"
    ref_type = "branch"
    ref_protected = false
  }

  user_claim      = "user_email"
  role_type       = "jwt"
}

resource "vault_jwt_auth_backend_role" "prd" {
  count = 54
  backend         = vault_jwt_auth_backend.gitlab_jwt.path
  role_name       = "prd-groupe-${count.index}"
  token_policies  = ["default", "gitlab-ssh", "groupe-${count.index}-gitlab", "db-groupe-${count.index}-prd", "rundeck-groupe-${count.index}-prd", "beats-role-${count.index}"]
  token_explicit_max_ttl = 600

  bound_claims = {
    namespace_path = "hitema-devsecops-2020/group_${count.index}"
    ref = "master"
    ref_type = "branch"
    ref_protected = true
  }
  
  user_claim      = "user_email"
  role_type       = "jwt"
}

resource "vault_jwt_auth_backend_role" "infrastructure" {
  count = 54
  backend         = vault_jwt_auth_backend.gitlab_jwt.path
  role_name       = "infrastructure-groupe-${count.index}"
  token_policies  = ["default", "gitlab-ssh", "groupe-${count.index}-gitlab", "db-groupe-${count.index}-dev", "rundeck-groupe-${count.index}-dev", "db-groupe-${count.index}-prd", "rundeck-groupe-${count.index}-prd", "beats-role-${count.index}"]
  token_explicit_max_ttl = 600

  bound_claims = {
    project_path = "hitema-devsecops-2020/group_${count.index}/infrastructure"
  }

  user_claim      = "user_email"
  role_type       = "jwt"
}

resource "vault_jwt_auth_backend_role" "application" {
  count = 54
  backend         = vault_jwt_auth_backend.gitlab_jwt.path
  role_name       = "application-groupe-${count.index}"
  token_policies  = ["default", "gitlab-ssh", "groupe-${count.index}-gitlab", "db-groupe-${count.index}-dev", "rundeck-groupe-${count.index}-dev", "db-groupe-${count.index}-prd", "rundeck-groupe-${count.index}-prd", "beats-role-${count.index}"]
  token_explicit_max_ttl = 600

  bound_claims = {
    project_path = "hitema-devsecops-2020/group_${count.index}/application"
  }

  user_claim      = "user_email"
  role_type       = "jwt"
}

resource "vault_policy" "gitlab" {
  count = 54
  name = "groupe-${count.index}-gitlab"

  policy = <<EOT
    # List groups
    path "secret/+" {
      capabilities = [ "list" ]
    }
    # Manage secrets
    path "secret/groupe-${count.index}/scaleway" {
      capabilities = [ "read", "list" ]
    }
    path "secret/groupe-${count.index}/dockerhub" {
      capabilities = [ "read", "list" ]
    }
    path "secret/groupe-${count.index}/postgresql-admin-password" {
      capabilities = [ "create", "update", "delete", "read", "list" ]
    }
    path "secret/groupe-${count.index}/postgresql-application-password" {
      capabilities = [ "create", "update", "delete", "read", "list" ]
    }
  EOT
}
