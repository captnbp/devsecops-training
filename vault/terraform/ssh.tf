resource "vault_mount" "ssh" {
    type = "ssh"
    path = "ssh"
}

resource "vault_ssh_secret_backend_ca" "ssh" {
    backend = vault_mount.ssh.path
    generate_signing_key = true
}

resource "vault_ssh_secret_backend_role" "students" {
    name = "students"
    backend = vault_mount.ssh.path
    allow_user_certificates = true
    allowed_users = "ubuntu"
    allowed_extensions = "permit-pty,permit-port-forwarding"
    default_extensions = {
        permit-pty = ""
    }
    key_type = "ca"
    default_user = "ubuntu"
    ttl = "36000"
    max_ttl = "36000"
}

resource "vault_ssh_secret_backend_role" "gitlab" {
    name = "gitlab"
    backend = vault_mount.ssh.path
    allow_user_certificates = true
    allowed_users = "ubuntu,root"
    allowed_extensions = "permit-pty"
    default_extensions = {
        permit-pty = ""
    }
    key_type = "ca"
    default_user = "ubuntu"
    ttl = "300"
    max_ttl = "600"
}

resource "vault_policy" "students-ssh" {
  name = "students-ssh"
  policy = <<EOT
    # List secret engines broadly across Vault.
    path "ssh/*"
    {
      capabilities = ["read", "list"]
    }
    path "ssh/sign/students" {
      capabilities = ["create", "update"]
    }
  EOT
}

resource "vault_policy" "gitlab-ssh" {
  name = "gitlab-ssh"
  policy = <<EOT
    path "ssh/sign/gitlab" {
      capabilities = ["create", "update"]
    }
  EOT
}