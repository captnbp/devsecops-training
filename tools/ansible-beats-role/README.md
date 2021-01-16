Beats
=====

Install Elastic beats within your ansible playbook:
* Auditbeat
* Filebeat
* Heartbeat
* Metricbeat
* Packetbeat

Install
------
```bash
ansible-galaxy install 'git+https://gitlab.com/captnbp/ansible-beats-role.git' -f
```

Requirements
------------

* A Hashicorp Vault instance with a role-id + secret-id with sufficient permissions
  * Create an ELK role for Vault (https://www.vaultproject.io/docs/secrets/databases/elasticdb.html#create-a-role-for-vault)
    ```sh
    $ curl \
      -X POST \
      -H "Content-Type: application/json" \
      -d '{"cluster": ["manage_security"]}' \
      https://elastic:$PASSWORD@localhost:9200/_security/role/vault
    ```
  * Create an ELK user for Vault (Replace default below password)
    ```sh
    $ curl \
      -X POST \
      -H "Content-Type: application/json" \
      -d '{ "password" : "myPa55word", "roles" : [ "vault" ], "full_name" : "Hashicorp Vault", "metadata" : { "plugin_name": "Vault Plugin Database Elasticsearch", "plugin_url": "https://github.com/hashicorp/vault-plugin-database-elasticsearch" } }' \
      https://elastic:$PASSWORD@localhost:9200/_security/user/vault
    ```
  * Create an ELK role for Beats
    ```sh
    $ curl \
      -X POST \
      -H "Content-Type: application/json" \
      -d '{"elasticsearch_role_definition": {"name":"beats","role_descriptors":{"beats":{"cluster":["monitor","read_ilm","cluster:admin/ingest/pipeline/get","cluster:admin/xpack/monitoring/bulk"],"indices":[{"names":[".monitoring-beats-*",".monitoring-es-*",".monitoring-kibana-*"],"privileges":["create_doc","create_index","view_index_metadata"]},{"names":["auditbeat-*"],"privileges":["create_doc","view_index_metadata"]},{"names":["filebeat-*"],"privileges":["create_doc","view_index_metadata"]},{"names":["heartbeat-*"],"privileges":["create_doc","view_index_metadata"]},{"names":["metricbeat-*"],"privileges":["create_doc","view_index_metadata"]},{"names":["packetbeat-*"],"privileges":["create_doc","view_index_metadata"]},{"names":["winlogbeat-*"],"privileges":["create_doc","view_index_metadata"]}]}}}' \
      https://elastic:$PASSWORD@localhost:9200/_security/role/beat_monitoring_agent
    ```
  * Enable the database secrets engine if it is not already enabled:
    ```sh
    $ vault secrets enable database
    Success! Enabled the database secrets engine at: database/
    ```
    By default, the secrets engine will enable at the name of the engine. To enable the secrets engine at a different path, use the -path argument.
  * Configure Vault with the proper plugin and connection information:
    ```sh
    $ vault write database/config/my-elasticsearch-database \
      plugin_name="elasticsearch-database-plugin" \
      allowed_roles="beats,superuser" \
      username=vault \
      password=myPa55word \
      url=https://localhost:9200 \
      ca_cert=/usr/share/ca-certificates/extra/elastic-stack-ca.crt.pem 
    ```
  * Configure a role that maps a name in Vault to a role definition in Elasticsearch. This is considered the most secure type of role because nobody can perform a privilege escalation by editing a role's privileges out-of-band in Elasticsearch:
    ```sh
    $ vault write database/roles/beats db_name=my-elasticsearch-database creation_statements='{"elasticsearch_roles": ["beat_monitoring_agent"]}' default_ttl="768h" max_ttl="768h"
    $ vault write database/roles/superuser db_name=my-elasticsearch-database creation_statements='{"elasticsearch_roles": ["superuser"]}' default_ttl="1h" max_ttl="24h"
    ```
  * Configure a Vault policy to allow the Ansible role to get ELK creds for the Beats agents:
    ```sh
    $ vault policy write beats -<<EOF
    # Create a user for Beats
    path "database/creds/beats" {
      capabilities = [ "read", "list" ]
    }
    # Create a superuser for Beats
    path "database/creds/superuser" {
      capabilities = [ "read", "list" ]
    }
    # List credentials
    path "database/creds/" {
      capabilities = [ "list" ]
    }
    # Revoke beats user
    path "sys/leases/revoke/database/creds/beats/+" {
      capabilities = [ "update" ]
    }
    # Revoke beats superuser
    path "sys/leases/revoke/database/creds/superuser/+" {
      capabilities = [ "update" ]
    }
    EOF
    ```
  * Create an AppRole the the Ansible playbook:
    ```sh
    $ vault write auth/approle/role/beats policies="beats"
    Success! Data written to: auth/approle/role/beats
    ```
  * Get the AppRole role-id:
    ```sh
    $ vault read auth/approle/role/beats/role-id
    Key        Value
    ---        -----
    role_id    82c9734c-060c-4346-1033-sdfgfdfqsd5az
    ```
  * Create the AppRole secret-id:
    ```sh
    $ vault write -f auth/approle/role/beats/secret-id
    Key                   Value
    ---                   -----
    secret_id             fa333c70-6yh8-ae90-5thj-93c7825e9714
    secret_id_accessor    cfad6409-2e5c-ea4c-2be3-9305647d00b7
    ```

If using Elastic Cloud
* A vault_monitoring_account_path with the following fields:
  * cloud_id
  * username
  * password

If **NOT** using Elastic Cloud
* A vault_monitoring_account_path with the following fields:
  * username
  * password
  * If not using dynamic Vault secrets, url (Ex: "https://elasticsearch.domain.tld:9200")

Role Variables
--------------

```yaml
# Beats directory layout
home_dir: "/usr/share"
config_dir: "/etc"
data_dir: "/var/lib"
log_dir: "/var/log"

# Vault secret storage
vault_monitoring_account_path: "database/creds/beats"

# If using Elastic Cloud
elk_auth_type_cloud_id: True

# Else if not using Elastic Cloud
elk_auth_type_cloud_id: False
elasticsearch_url: "https://your-elk-url.domain.tld:9200"
kibana_url: "https://your-kibana-url.domain.tld:5601"
```

Dependencies
------------

You will need to install the following module:

https://github.com/TerryHowe/ansible-modules-hashivault/

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

```yaml
- hosts: servers
  roles:
    - { role: ansible-beats-role, tags: ['beats'] }
  vars:
    # Beats directory layout
    home_dir: "/usr/share"
    config_dir: "/etc"
    data_dir: "/var/lib"
    log_dir: "/var/log"

    # Vault secret storage
    vault_monitoring_account_path: "database/creds/beats"

    # If using Elastic Cloud
    elk_auth_type_cloud_id: True

    # Else if not using Elastic Cloud
    elk_auth_type_cloud_id: False
    elasticsearch_url: "https://your-elk-url.domain.tld:9200"
    kibana_url: "https://your-kibana-url.domain.tld:5601"
```

Example Playbook for Gitlab CI integration
------------------------------------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

In your Gitlab repository, set the following variables in `Settings -> CI / CD -> Variables`

```
      VAULT_ADDR: "https://your-vault-url.domain.tld"
      VAULT_SKIP_VERIFY: False
      VAULT_AUTHTYPE: approle
      VAULT_AUTH_METHOD: approle
      VAULT_ROLE_ID: <your role-id>
      VAULT_SECRET_ID: <your secret-id>
```


```yaml
- hosts: servers
  roles:
    - { role: ansible-beats-role, tags: ['beats'] }
  vars:
    # Beats directory layout
    home_dir: "/usr/share"
    config_dir: "/etc"
    data_dir: "/var/lib"
    log_dir: "/var/log"

    # Vault secret storage
    vault_monitoring_account_path: "database/creds/beats"

    # If using Elastic Cloud
    elk_auth_type_cloud_id: True

    # Else if not using Elastic Cloud
    elk_auth_type_cloud_id: False
    elasticsearch_url: "https://your-elk-url.domain.tld:9200"
    kibana_url: "https://your-kibana-url.domain.tld:5601"
```

License
-------

BSD

Author Information
------------------

Contact me at benoit@doca-consulting.fr
