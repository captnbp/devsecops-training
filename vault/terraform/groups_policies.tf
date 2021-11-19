resource "vault_policy" "dev-group" {
  count = 22
  name = "groupe-${count.index}-dev"

  policy = <<EOT
    # List groups
    path "secret/+" {
      capabilities = [ "list" ]
    }
    # Manage secrets
    path "secret/groupe-${count.index}/*" {
      capabilities = [ "read", "list", "create", "update", "delete" ]
    }

    # Configure the database secret engine and create roles
    path "database/config/" {
      capabilities = [ "read", "list" ]
    }
    path "database/config/postgresql-groupe-${count.index}-dev" {
      capabilities = [ "create", "read", "update", "delete", "list" ]
    }
    path "database/roles/" {
      capabilities = [ "read", "list" ]
    }
    path "database/roles/monitoring-groupe-${count.index}-dev" {
      capabilities = [ "create", "read", "update", "delete", "list" ]
    }
    path "database/roles/backup-groupe-${count.index}-dev" {
      capabilities = [ "create", "read", "update", "delete", "list" ]
    }
    path "database/roles/application-groupe-${count.index}-dev" {
      capabilities = [ "create", "read", "update", "delete", "list" ]
    }

    # Create and manage ACL policies
    path "sys/policies/acl/application-groupe-${count.index}-dev" {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }
    path "sys/policies/acl/rundeck-groupe-${count.index}-dev" {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }

    # To list policies - Step 3
    path "sys/policies/acl" {
      capabilities = ["list"]
    }

    # Create and manage roles
    path "auth/approle/role/application-groupe-${count.index}-dev" {
      capabilities = [ "create", "read", "update", "delete", "list" ]
    }
    # Get role-id
    path "auth/approle/role/application-groupe-${count.index}-dev/role-id" {
      capabilities = [ "read" ]
    }
    # Get secret-id
    path "auth/approle/role/application-groupe-${count.index}-dev/secret-id" {
      capabilities = [ "update" ]
    }

    # Create and manage roles for rundeck
    path "auth/approle/role/rundeck-groupe-${count.index}-dev" {
      capabilities = [ "create", "read", "update", "delete", "list" ]
    }
    # Get role-id
    path "auth/approle/role/rundeck-groupe-${count.index}-dev/role-id" {
      capabilities = [ "read" ]
    }
    # Get secret-id
    path "auth/approle/role/rundeck-groupe-${count.index}-dev/secret-id" {
      capabilities = [ "update" ]
    }
  EOT
}

resource "vault_policy" "prd-group" {
  count = 22
  name = "groupe-${count.index}-prd"

  policy = <<EOT
    # List groups
    path "secret/+" {
      capabilities = [ "list" ]
    }
    # Manage secrets
    path "secret/groupe-${count.index}/*" {
      capabilities = [ "read", "list", "create", "update", "delete" ]
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

    # Create and manage ACL policies
    path "sys/policy/application-groupe-${count.index}-prd" {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }
    path "sys/policy/rundeck-groupe-${count.index}-prd" {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
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
