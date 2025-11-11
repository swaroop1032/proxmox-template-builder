# --- TEMPLATE_BUILDER.TF (FINAL CORRECTED VERSION FOR BPG PROVIDER) ---
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox" 
      version = ">=0.50.0" 
    }
  }
}

provider "proxmox" {
  # Authentication is handled by PM_TOKEN_ID, PM_API_URL, etc., passed from Jenkins environment variables.
}

# 1. Download the latest Ubuntu 22.04 Cloud Image
resource "proxmox_virtual_environment_download_file" "download_ubuntu_image" {
  # FIX: Content type should be 'qemu' for QCOW2 images, not 'iso'
  content_type = "qemu" 
  datastore_id = var.storage_vm_disk
  node_name    = var.proxmox_node
  url          = var.ubuntu_image_url
  file_name    = var.image_file_name
}

# 2. FIX: Use the BPG provider's correct resource type: proxmox_virtual_environment_vm
resource "proxmox_virtual_environment_vm" "ubuntu_template" {
  name        = var.template_name_new
  desc        = "Automated Base Cloud-Init Template (22.04)"
  node_name   = var.proxmox_node // BPG uses 'node_name'
  vm_id       = var.template_vmid // BPG uses 'vm_id'

  cores   = var.template_cores
  sockets = 1
  memory  = var.template_memory
  
  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }
  
  disk {
    device        = "scsi0"
    storage_pool  = var.storage_vm_disk
    size          = var.template_disk_size
    
    # FIX: BPG uses 'importing_file' instead of the nested 'import_from_file'
    importing_file = proxmox_virtual_environment_download_file.download_ubuntu_image.file_name
  }

  # FIX: BPG Cloud-Init block structure
  cloud_init {
    user = var.ci_default_user
    data_store_id = var.storage_vm_disk 
  }
  
  operating_system {
      type = "cloud-init"
  }

  # FIX: BPG converts to template via post_create_action
  post_create_action {
      template = true
  }

  depends_on = [
    proxmox_virtual_environment_download_file.download_ubuntu_image
  ]
}
