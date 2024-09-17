
resource "random_pet" "prefix" {}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${random_pet.prefix.id}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${random_pet.prefix.id}-k8s"
  kubernetes_version  = "1.30"

  default_node_pool {
    name            = "default"
    node_count      = 2
    vm_size         = "Standard_D2_v2"
    os_disk_size_gb = 30
  }

  service_principal {
    client_id     = var.appId
    client_secret = var.password
  }

  role_based_access_control_enabled = true

  tags = {
    environment = "QA"
  }

  
  lifecycle {
    ignore_changes = [
      default_node_pool[0].upgrade_settings,
    ]
  }

}

# Add Helm provider for managing Helm charts in AKS
provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
  }
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
}

# Define the Kubernetes namespace
resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}


# Cert Manager Installation using Helm
resource "helm_release" "cert_manager" {
  depends_on = [kubernetes_namespace.cert_manager, azurerm_kubernetes_cluster.aks]
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"

  set {
    name  = "installCRDs"
    value = "true"
  }

}

# Define the Kubernetes namespace
resource "kubernetes_namespace" "ingress-nginx" {
  metadata {
    name = "ingress-nginx"
  }
} 

# Install NGINX Ingress Controller with Static IP
resource "helm_release" "nginx_ingress" {
  depends_on = [kubernetes_namespace.ingress-nginx, azurerm_kubernetes_cluster.aks]
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"

  set {
    name  = "controller.service.loadBalancerIP"
    value = "Static-IP"
  }
}

# # Horizontal Pod Autoscaler (HPA) configuration
# resource "kubernetes_horizontal_pod_autoscaler" "hpa" {
#   depends_on = [azurerm_kubernetes_cluster.aks]
#   metadata {
#     name      = "example-hpa"
#     namespace = "kube-system"
#   }

#   spec {
#     scale_target_ref {
#       api_version = "apps/v1"
#       kind        = "Deployment"
#       name        = "example-deployment"
#     }

#     min_replicas = 1
#     max_replicas = 10

#     # Define the metric and threshold for CPU usage
#     metric {
#       type = "Resource"

#       resource {
#         name  = "cpu"
#         target {
#           type               = "Utilization"
#           average_utilization = 50
#         }
#       }
#     }
#   }
# }

# Install Redis Sentinel
resource "helm_release" "redis_sentinel" {
  depends_on = [azurerm_kubernetes_cluster.aks]
  name       = "redis-sentinel"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"
  namespace  = "default"

  set {
    name  = "architecture"
    value = "replication"
  }

  set {
    name  = "sentinel.enabled"
    value = "true"
  }
}