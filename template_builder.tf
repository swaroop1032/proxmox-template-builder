# --- TEMPLATE_BUILDER.TF (FINAL CORRECTED VERSION FOR BPG PROVIDER SCHEMA) ---
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox" 
      version = ">=0.50.0" 
    }
  }
}

provider "proxmox" {
  # Authentication is handled by PM_TOKEN_ID, PM_API_URL, etc., passed from Jenkins.
}

# 1. Download the latest Ubuntu 22.04 Cloud Image
resource "proxmox_virtual_environment_download_file" "download_ubuntu_image" {
  # Correct: content_type must be "import" for arbitrary file URLs
  content_type = "import" 
  datastore_id = var.storage_vm_disk
  node_name    = var.proxmox_node
  url          = var.ubuntu_image_url
  file_name    = var.image_file_name
}

# 2. Configure the VM and convert it to a template (using BPG resource)
resource "proxmox_virtual_environment_vm" "ubuntu_template" {
  name        = var.template_name_new
  description = "Automated Base Cloud-Init Template (22.04)" 
  node_name   = var.proxmox_node 
  vm_id       = var.template_vmid 

  # FIX: CPU settings must be in a dedicated block
  cpu {
    cores   = var.template_cores
    sockets = 1
  }

  # FIX: Memory settings must be in a dedicated block
  memory {
    dedicated = var.template_memory 
  }
  
  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }
  
  # FIX: Disk block is FLAT. All storage and file attributes are here.
  disk {
    interface      = "scsi0" // Required interface type
    size           = var.template_disk_size
    storage_pool   = var.storage_vm_disk // Storage pool is now a direct attribute
    importing_file = proxmox_virtual_environment_download_file.download_ubuntu_image.file_name // File import is a direct attribute
  }

  operating_system {
      type = "cloud-init"
  }
  
  # FIX: Cloud-init user and networking must be in the 'initialization' block
  initialization {
    user = var.ci_default_user
    # Add a default IP configuration to ensure network is enabled for cloud-init
    ip_config {
      ip = "dhcp" 
    }
  }

  # Template conversion is a top-level attribute
  template = true 

  depends_on = [
    proxmox_virtual_environment_download_file.download_ubuntu_image
  ]
}
