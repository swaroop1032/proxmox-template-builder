# --- TEMPLATE_BUILDER.TF (FINAL CORRECTED VERSION) ---
terraform {
  required_providers {
    proxmox = {
      # Must use BPG provider for download functionality
      source  = "bpg/proxmox"
      version = ">=0.50.0" 
    }
  }
}

provider "proxmox" {
  # FIX: The BPG provider requires a completely empty block here 
  # and expects authentication via PM_TOKEN_ID, PM_API_URL, etc.
}

# 1. Download the latest Ubuntu 22.04 Cloud Image
resource "proxmox_virtual_environment_download_file" "download_ubuntu_image" {
  content_type = "iso" 
  datastore_id = var.storage_vm_disk
  node_name    = var.proxmox_node
  url          = var.ubuntu_image_url
  file_name    = var.image_file_name
}

# 2. Create the VM and convert it to a template
resource "proxmox_vm_qemu" "ubuntu_template" {
  name        = var.template_name_new
  desc        = "Automated Base Cloud-Init Template (22.04)"
  target_node = var.proxmox_node
  vmid        = var.template_vmid

  cores   = var.template_cores
  sockets = 1
  memory  = var.template_memory
  
  network {
    id     = 0
    model  = "virtio"
    bridge = var.network_bridge
  }
  
  disk {
    disk    = "scsi0"
    size    = var.template_disk_size
    storage = var.storage_vm_disk
    type    = "scsi"
    import_from_file {
      datastore_id = var.storage_vm_disk
      file_name    = proxmox_virtual_environment_download_file.download_ubuntu_image.file_name
    }
  }

  os_type    = "cloud-init"
  ci_user    = var.ci_default_user 
  ci_storage = var.storage_vm_disk 

  template     = true
  force_create = true 

  depends_on = [
    proxmox_virtual_environment_download_file.download_ubuntu_image
  ]
}
