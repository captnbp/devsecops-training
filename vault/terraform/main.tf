provider "vault" {
  # It is strongly recommended to configure this provider through the
  # environment variables described above, so that each user can have
  # separate credentials set in the environment.
  #
  # This will default to using $VAULT_ADDR
  # But can be set explicitly
  # address = "https://vault.example.net:8200"
}

resource "vault_mount" "db" {
  path = "database"
  type = "database"
}

resource "vault_jwt_auth_backend" "gitlab_oidc" {
  description  = "Authenticate Vault user using Gitlab OIDC provider"
  path = "oidc"
  type = "oidc"
  oidc_discovery_url = "https://gitlab.com"
  oidc_client_id = "552bd9ab910c33884e76c9bb7323c8dfe2bd24320eecb0fc9106835087abc6a8"
  oidc_client_secret = "054146be36dee14376f43b1f83ef5ba5d5dafbfca1a4abd8396f5e23bd7496cb"
  bound_issuer = "localhost"
  default_role = "default"
}

resource "vault_jwt_auth_backend_role" "gitlab_oidc_admin" {
  backend         = vault_jwt_auth_backend.gitlab_oidc.path
  role_name       = "admin"
  token_policies  = ["default", "admin"]
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
    groups = "hitema-devsecops-2020/group_0"
  }
}

resource "vault_policy" "admin" {
  name = "admin"

  policy = <<EOT
    # Manage auth methods broadly across Vault
    path "auth/*"
    {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }

    # Create, update, and delete auth methods
    path "sys/auth/*"
    {
      capabilities = ["create", "update", "delete", "sudo"]
    }

    # List auth methods
    path "sys/auth"
    {
      capabilities = ["read"]
    }

    # To list policies - Step 3
    path "sys/policy"
    {
      capabilities = ["read"]
    }

    # Create and manage ACL policies via CLI
    path "sys/policy/*"
    {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }

    # Create and manage ACL policies via API & UI
    path "sys/policies/acl/*"
    {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }

    # To make the Policy menu point visible for the user
    path "sys/policies/acl"
    {
      capabilities = ["list"]
    }

    # List, create, update, and delete key/value secrets
    path "secret/*"
    {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }

    # List secret engines broadly across Vault.
    path "sys/mounts"
    {
      capabilities = ["read", "list"]
    }

    # Manage and manage secret engines broadly across Vault.
    path "sys/mounts/*"
    {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }

    # Read health checks
    path "sys/health"
    {
      capabilities = ["read", "sudo"]
    }

    # To perform Step 4
    path "sys/capabilities"
    {
      capabilities = ["create", "update"]
    }

    # To perform Step 4
    path "sys/capabilities-self"
    {
      capabilities = ["create", "update"]
    }

    # Create and manage entities and groups
    path "identity/*" {
      capabilities = [ "create", "read", "update", "delete", "list" ]
    }

    # Work with pki secrets engine
    path "pki*" {
      capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
    }

    # Manage detabase secret engine
    path "database/*" {
      capabilities = [ "create", "read", "update", "delete", "list" ]
    }

    # To configure the SSH secrets engine
    path "ssh/*" {
      capabilities = [ "create", "read", "update", "delete", "list" ]
    }

  EOT
  }

