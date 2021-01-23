
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
    path "secret/groupe-${count.index}/scaleway_s3_backup" {
      capabilities = [ "read", "list" ]
    }
    path "secret/groupe-${count.index}/passphrase_s3_backup" {
      capabilities = [ "read", "list" ]
    }
    path "secret/groupe-${count.index}/dockerhub" {
      capabilities = [ "read", "list" ]
    }
    path "secret/groupe-${count.index}/elasticsearch" {
      capabilities = [ "read", "list" ]
    }
    path "secret/groupe-${count.index}/postgresql-admin-password" {
      capabilities = [ "create", "update", "delete", "read", "list" ]
    }
    path "secret/groupe-${count.index}/postgresql-application-password" {
      capabilities = [ "create", "update", "delete", "read", "list" ]
    }

    # Create and manage ACL policies
    path "sys/policies/acl/application-groupe-${count.index}-prd" {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }
    
    path "sys/policies/acl/rundeck-groupe-${count.index}-prd" {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }

    # To list policies - Step 3
    path "sys/policies/acl" {
      capabilities = ["list"]
    }

    # Create and manage ACL policies
    path "sys/policy/application-groupe-${count.index}-prd" {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }
    path "sys/policy/rundeck-groupe-${count.index}-prd" {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }

    # Configure the database secret engine and create roles
    path "database/config/" {
      capabilities = [ "read", "list" ]
    }
    path "database/config/postgresql-groupe-${count.index}-prd" {
      capabilities = [ "create", "read", "update", "delete", "list" ]
    }
    path "database/roles/" {
      capabilities = [ "read", "list" ]
    }
    path "database/roles/monitoring-groupe-${count.index}-prd" {
      capabilities = [ "create", "read", "update", "delete", "list" ]
    }
    path "database/roles/backup-groupe-${count.index}-prd" {
      capabilities = [ "create", "read", "update", "delete", "list" ]
    }
    path "database/roles/restore-groupe-${count.index}-prd" {
      capabilities = [ "create", "read", "update", "delete", "list" ]
    }
    path "database/roles/application-groupe-${count.index}-prd" {
      capabilities = [ "create", "read", "update", "delete", "list" ]
    }
    path "database/creds/monitoring-groupe-${count.index}-prd" {
      capabilities = [ "read", "list" ]
    }
    path "database/creds/backup-groupe-${count.index}-prd" {
      capabilities = [ "read", "list" ]
    }
    path "database/creds/restore-groupe-${count.index}-prd" {
      capabilities = [ "read", "list" ]
    }
    path "database/creds/application-groupe-${count.index}-prd" {
      capabilities = [ "read", "list" ]
    }

    # Create and manage roles
    path "auth/approle/role/application-groupe-${count.index}-prd" {
      capabilities = [ "create", "read", "update", "delete", "list" ]
    }
    # Get role-id
    path "auth/approle/role/application-groupe-${count.index}-prd/role-id" {
      capabilities = [ "read" ]
    }
    # Get secret-id
    path "auth/approle/role/application-groupe-${count.index}-prd/secret-id" {
      capabilities = [ "update" ]
    }

    # Create and manage roles for rundeck
    path "auth/approle/role/rundeck-groupe-${count.index}-prd" {
      capabilities = [ "create", "read", "update", "delete", "list" ]
    }
    # Get role-id
    path "auth/approle/role/rundeck-groupe-${count.index}-prd/role-id" {
      capabilities = [ "read" ]
    }
    # Get secret-id
    path "auth/approle/role/rundeck-groupe-${count.index}-prd/secret-id" {
      capabilities = [ "update" ]
    }
  EOT
}
