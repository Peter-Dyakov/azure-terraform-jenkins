
resource "random_pet" "prefix" {}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${random_pet.prefix.id}-aks1"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${random_pet.prefix.id}-k8s"
  kubernetes_version  = "1.30"

  sku_tier = "Standard"

  default_node_pool {
    name            = "default"
    node_count      = 2
    vm_size         = "Standard_D2s_v3"
    os_disk_size_gb = 30
  }


  identity {
    type = "SystemAssigned"
  }

  key_vault_secrets_provider {
   # update the secrets on a regular basis
   secret_rotation_enabled = true
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

resource "azurerm_public_ip" "nginx_ingress_ip" {
  name                = "nginx-ingress-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "helm_release" "nginx_ingress" {
  depends_on = [kubernetes_namespace.ingress-nginx, azurerm_kubernetes_cluster.aks]
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"

  set {
    name  = "controller.service.loadBalancerIP"
    value = azurerm_public_ip.nginx_ingress_ip.ip_address
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-dns-label-name"
    value = "2bcloud-dns-label"
  }
}


# # Horizontal Pod Autoscaler (HPA) configuration
# resource "kubernetes_horizontal_pod_autoscaler" "hpa" {
#   depends_on = [azurerm_kubernetes_cluster.aks]
#   metadata {
#     name      = "flask-hpa"
#     namespace = "kube-system"
#   }

#   spec {
#     scale_target_ref {
#       api_version = "apps/v1"
#       kind        = "Deployment"
#       name        = "my-app"
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

# Grant AKS Cluster's Managed Identity Pull Access to ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.jenkins.id
  skip_service_principal_aad_check = true
  depends_on                       = [azurerm_kubernetes_cluster.aks] 
}


resource "azurerm_key_vault_access_policy" "aks_policy" {
  key_vault_id = azurerm_key_vault.jenkins.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id

  secret_permissions = [
    "Get",
    "List"
  ]
}



