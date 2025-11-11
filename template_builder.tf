# --- TEMPLATE_BUILDER.TF (Creates the Cloud-Init Template) ---
terraform {
  required_providers {
    proxmox = {
      # The BPG provider is often preferred for file management (downloading images)
      source  = "bpg/proxmox"
      version = ">=0.50.0" 
    }
  }
}

provider "proxmox" {
  pm_api_url         = var.pm_api_url
  pm_api_token_id    = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure    = true # WARNING: Use false with a valid SSL certificate
}

# 1. Download the latest Ubuntu 22.04 Cloud Image
resource "proxmox_virtual_environment_download_file" "download_ubuntu_image" {
  # This downloads the pre-installed OS image file directly to Proxmox storage.
  content_type = "iso" 
  datastore_id = var.storage_vm_disk
  node_name    = var.proxmox_node
  url          = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  file_name    = "ubuntu-2204-cloudinit.qcow2" 
}

# 2. Create the VM and convert it to a template
resource "proxmox_vm_qemu" "ubuntu_template" {
  name        = var.template_name_new
  desc        = "Automated Base Cloud-Init Template (22.04)"
  target_node = var.proxmox_node
  vmid        = 9000 # Use a high VMID for templates

  cores   = 1
  sockets = 1
  memory  = 1024
  
  network {
    id     = 0
    model  = "virtio"
    bridge = var.network_bridge
  }
  
  # Configure disk to import the downloaded image
  disk {
    disk    = "scsi0"
    size    = "20G"
    storage = var.storage_vm_disk
    type    = "scsi"
    import_from_file {
      datastore_id = var.storage_vm_disk
      file_name    = proxmox_virtual_environment_download_file.download_ubuntu_image.file_name
    }
  }

  # Enable Cloud-Init settings on the template
  os_type    = "cloud-init"
  ci_user    = "ubuntu" 
  ci_storage = var.storage_vm_disk 

  # The magic: immediately convert to a template after provisioning!
  template     = true
  force_create = true 

  depends_on = [
    proxmox_virtual_environment_download_file.download_ubuntu_image
  ]
}
