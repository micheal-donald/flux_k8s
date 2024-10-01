# Output the kubeconfig to interact with the AKS cluster (Sensitive)
output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks_cluster.kube_config_raw
  sensitive = true  # Marked sensitive to prevent accidental exposure of credentials
}