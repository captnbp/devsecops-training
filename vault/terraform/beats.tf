resource "vault_policy" "beats" {
  count = 54
  name = "beats-groupe-${count.index}"

  policy = <<EOT
    # Get ELK credentials for beats
    path "secret/groupe-${count.index}/elasticsearch" {
      capabilities = [ "read", "list", "create", "update", "delete" ]
    }

    # Create and manage ACL policies
    path "sys/policies/acl/beats-role-${count.index}"
    {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }

    # To list policies - Step 3
    path "sys/policies/acl"
    {
      capabilities = ["list"]
    }

    # Create and manage roles
    path "auth/approle/role/beats-role-${count.index}" {
      capabilities = [ "create", "read", "update", "delete", "list" ]
    }
    # Get role-id
    path "auth/approle/role/beats-role-${count.index}/role-id" {
      capabilities = [ "read" ]
    }
    # Get secret-id
    path "auth/approle/role/beats-role-${count.index}/secret-id" {
      capabilities = [ "update" ]
    }
  EOT
}