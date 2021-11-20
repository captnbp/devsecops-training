variable "email" {}
variable "grafana_admin_password" {}

terraform {
  required_providers {
    scaleway = {
      source = "scaleway/scaleway"
      version = "2.1.0"
    }
  }
}

provider "scaleway" {
}

resource "scaleway_k8s_cluster_beta" "kapsule" {
  name = "kapsule"
  version = "1.19"
  cni = "cilium"
  ingress = "nginx"
  tags = ["profs", "tooling"]
  auto_upgrade {
      enable = true
      maintenance_window_start_hour = 1
      maintenance_window_day = "sunday"
  }
}

resource "scaleway_k8s_pool_beta" "permanent" {
  cluster_id = scaleway_k8s_cluster_beta.kapsule.id
  name = "permanent"
  node_type = "DEV1-M"
  size = 1
  autoscaling = false
  autohealing = true
  container_runtime = "docker"
  tags = ["profs", "tooling", "permanent"]
}

provider "helm" {
  kubernetes {
    #host     = scaleway_k8s_cluster_beta.kapsule.apiserver_url
    #cluster_ca_certificate = scaleway_k8s_cluster_beta.kapsule.kubeconfig.0.cluster_ca_certificate
    #token = scaleway_k8s_cluster_beta.kapsule.kubeconfig.0.config_file
    config_path = "/home/coder/.kube/kapsule.yaml"
  }
}

resource "helm_release" "cert-manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.0.4"
  create_namespace = true
  namespace = "cert-manager"

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "prometheus.servicemonitor.enabled"
    value = "false"
  }
}

provider "kubernetes-alpha" {
    #host     = scaleway_k8s_cluster_beta.kapsule.apiserver_url
    #cluster_ca_certificate = scaleway_k8s_cluster_beta.kapsule.kubeconfig.0.cluster_ca_certificate
    #token = scaleway_k8s_cluster_beta.kapsule.kubeconfig.0.config_file
    config_path = "/home/coder/.kube/kapsule.yaml"
}

resource "kubernetes_manifest" "letsencrypt" {
  provider = kubernetes-alpha

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind = "ClusterIssuer"
    metadata = {
        name = "letsencrypt-prod"
    }
    spec = {
        acme = {
            email = var.email
            privateKeySecretRef = {
                name = "letsencrypt-prod"
            }
            server = "https://acme-v02.api.letsencrypt.org/directory"
            solvers = [
                {
                    http01 = {
                        ingress = {
                            class = "nginx"
                        }
                    }
                }
            ]
        }
    }
  }
}

resource "helm_release" "prometheus" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "12.2.0"
  create_namespace = true
  namespace = "kube-prometheus-stack"


  values = [
    file("prometheus.yml")
  ]

  set {
      name = "grafana.adminPassword"
      value = "Ael0JeeghahChohNg6wohwoo9uiripek"
  }
}

resource "helm_release" "code-hitema" {
  name       = "code-hitema"
  repository = "https://charts.doca.cloud"
  chart      = "code-server-hub"
  version    = "1.4.3"
  create_namespace = true
  namespace = "code-hitema"


  values = [
    file("codehub.yml")
  ]
}