# --- TEMPLATE_BUILDER.TF (THE FINAL, DEFINITIVE CORRECTED VERSION FOR BPG SCHEMA) ---
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox" 
      version = ">=0.50.0" 
    }
  }
}

provider "proxmox" {}

# 1. Download the latest Ubuntu 22.04 Cloud Image
resource "proxmox_virtual_environment_download_file" "download_ubuntu_image" {
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

  cpu {
    cores   = var.template_cores
    sockets = 1
  }

  memory {
    dedicated = var.template_memory 
  }
  
  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }
  
  # FIX: Restructure to single disk block with interface type nested, 
  # moving storage_pool and importing_file inside the disk type block.
  disk { 
    scsi { # Disk interface type block (e.g., scsi, sata, virtio)
      interface = "scsi0" # This specifies the full interface
      size = var.template_disk_size
      storage_pool = var.storage_vm_disk
      importing_file = proxmox_virtual_environment_download_file.download_ubuntu_image.file_name
    }
  }

  operating_system {
      type = "cloud-init"
  }
  
  # Initialization block (This nested BPG structure has not shown errors)
  initialization {
    user_account {
      username = var.ci_default_user
    }
    
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  template = true 

  depends_on = [
    proxmox_virtual_environment_download_file.download_ubuntu_image
  ]
}
