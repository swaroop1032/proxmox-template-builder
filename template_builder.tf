# --- template_builder.tf (Updated for telmate/proxmox) ---
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

# The provider configures the connection using the variables
# which we will pass via environment variables in Jenkins.
provider "proxmox" {
  pm_api_url          = var.pm_api_url
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure     = true 
}

# We use a random suffix to ensure a unique VM name on every Jenkins run
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
  numeric = true
}

# Define the Virtual Machine resource by cloning an existing template
# IMPORTANT: This assumes a template named "ubuntu-2204-cloudinit-template" already exists in Proxmox.
resource "proxmox_vm_qemu" "vm_from_jenkins" { 
  # --- General Settings ---
  name        = "ubuntu-vm-jenkins-${random_string.suffix.result}"
  desc        = "Managed by Terraform and Jenkins"
  target_node = var.proxmox_node

  # Clones from the existing template defined in your variables file
  clone = var.vm_template_name 
  
  # --- Resources ---
  cores   = 2
  sockets = 1
  memory  = 2048 

  # --- Disk (Standard HCL block) ---
  disk {
    storage = var.storage_vm_disk
    type    = "scsi"
    # Setting size to 0 uses the size of the cloned template disk
    # To resize it, you can set a specific size: size = "50G"
  }

  # --- Network ---
  network {
    model  = "virtio"
    bridge = "vmbr0" # Set to your primary Proxmox bridge if different
  }

  # --- Cloud-Init (Simple flat attributes for telmate provider) ---
  ciuser    = var.ci_default_user
  ipconfig0 = "ip=dhcp" # Set to static if needed, e.g., "ip=192.168.1.10/24,gw=192.168.1.1"
}
