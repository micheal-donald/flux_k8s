terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  backend "local" {
    path = "terraform.tfstate"
  }
}

# Define the Azure Provider
provider "azurerm" {
  features {}

  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
  subscription_id = var.azure_subscription_id
}

# Create a Resource Group for the AKS cluster and its networking resources
resource "azurerm_resource_group" "aks_rg" {
  name     = "aks-free-tier-rg"
  location = "Australia East"  # Choose an Azure region close to your location for minimal latency
}

# Define a Virtual Network to host the Kubernetes cluster
resource "azurerm_virtual_network" "aks_vnet" {
  name                = "aks-vnet"
  address_space       = ["10.0.0.0/16"]  # Define the IP address space for the VNet
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
}

# Define a Subnet within the Virtual Network for the AKS cluster nodes
resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.aks_rg.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.0.0.0/24"]  # Subnet address range for AKS nodes
}

# Create the Azure Kubernetes Service (AKS) Cluster
resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "aks-free-tier-cluster"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  dns_prefix          = "aks-free-tier-dns"  # DNS prefix for AKS API server

  default_node_pool {
    name       = "default"
    node_count = 1  # Set to 1 node to stay within the free tier; AKS free control plane requires only node costs
    vm_size    = "Standard_A2_v2"  # Use the Standard_A2_v2 VM, which is part of Azure's free tier
    vnet_subnet_id = azurerm_subnet.aks_subnet.id  # Attach the node pool to the previously created subnet
  }

  # Enable managed identity for the cluster (SystemAssigned) - this is required for managing cluster resources
  identity {
    type = "SystemAssigned"
  }

    # Define network profile to resolve CIDR conflict
  network_profile {
    network_plugin     = "azure"
    service_cidr       = "10.1.0.0/16"  # Use a CIDR range that does not overlap with your subnet
    dns_service_ip     = "10.1.0.10"    # An IP address within the service CIDR
}
  
  # Optional - Enables the Kubernetes dashboard (can be disabled if not needed to save resources)
  #addon_profile {
  #  kube_dashboard {
  #    enabled = true  # Note that enabling the dashboard adds slight resource overhead
  #  }
  #}

  tags = {
    environment = "free-tier"  # Tagging for resource identification and cost management
  }
}
