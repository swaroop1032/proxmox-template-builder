# --- template_builder.tf (FINAL CORRECTED VERSION) ---
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Provider authentication uses variables passed via TF_VAR_ environment variables
provider "proxmox" {
  pm_api_url          = var.pm_api_url
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure     = true
}

# Resource to generate a unique suffix for the VM name
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
  numeric = true
}

# Define the Virtual Machine resource by cloning an existing template
resource "proxmox_vm_qemu" "vm_from_jenkins" { 
  # --- General Settings ---
  name        = "ubuntu-vm-jenkins-${random_string.suffix.result}"
  desc        = "Managed by Terraform and Jenkins"
  target_node = var.proxmox_node 
  vmid        = 0 # Proxmox will assign a free ID

  # Clones from the existing template
  clone = var.vm_template_name 
  
  # --- Resources ---
  cores   = 2
  sockets = 1
  memory  = 2048 

  # --- Disk (The change is here: boot = true) ---
  disk {
    storage = var.storage_vm_disk
    type    = "scsi"
    size    = "20G" 
    boot    = true # CHANGED: Must be a boolean (true/false), not an integer (1/0)
  }
  
  # --- Network ---
  network {
    bridge = "vmbr0" # Set to your primary Proxmox bridge
    model  = "virtio"
  }
  
  # --- Cloud-Init ---
  ciuser    = var.ci_default_user
  ipconfig0 = "ip=dhcp"
}
