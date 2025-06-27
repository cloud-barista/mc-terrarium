# Output resource group name
output "resource_group_name" {
  value = data.azurerm_resource_group.existing.name
}

# Output cluster name
output "cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

# Output Kubeconfig file content
# The azurerm provider provides kubeconfig content directly through the 'kube_config_raw' attribute, which is very convenient.
output "kube_config" {
  description = "Kubeconfig content to connect to the AKS cluster."
  sensitive   = true # Contains sensitive information, so it won't be exposed in the terminal
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
}
