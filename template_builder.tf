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
  # FIX: content_type must be "import" for arbitrary file URLs
  content_type = "import" 
  datastore_id = var.storage_vm_disk
  node_name    = var.proxmox_node
  url          = var.ubuntu_image_url
  file_name    = var.image_file_name
}

# 2. Configure the VM and convert it to a template (using BPG resource)
resource "proxmox_virtual_environment_vm" "ubuntu_template" {
  name        = var.template_name_new
  # FIX: BPG uses "description" instead of "desc"
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
  
  # FIX: Disk block structure for BPG
  disk {
    # FIX: "interface" is required in the disk block (e.g., scsi0, ide0)
    interface = "scsi0" 
    size      = var.template_disk_size
    
    # FIX: Storage and file import are configured in a nested block
    storage {
      storage_pool = var.storage_vm_disk
      importing_file = proxmox_virtual_environment_download_file.download_ubuntu_image.file_name
    }
  }

  # OS must be set to cloud-init
  operating_system {
      type = "cloud-init"
  }
  
  # FIX: Cloud-init user is a top-level attribute
  cloud_init_user = var.ci_default_user

  # Template conversion is a top-level attribute (no post_create_action block)
  template = true 

  depends_on = [
    proxmox_virtual_environment_download_file.download_ubuntu_image
  ]
}
