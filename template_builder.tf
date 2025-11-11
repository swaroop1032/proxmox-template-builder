# --- template_builder.tf ---

# Terraform Block (Define Provider Version)
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      # Use a robust version, 3.x is recommended for new features
      version = "~> 3.0" 
    }
  }
}

# Provider Configuration (Reads from your existing setup)
provider "proxmox" {
  pm_api_url          = var.pm_api_url
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure     = true 
  pm_timeout          = 120
}

# -----------------------------------------------------
# VM Resource for ISO-based Installation and Template Creation
# -----------------------------------------------------
resource "proxmox_vm_qemu" "iso_template_builder" {
  name        = "temp-iso-installer-${var.template_vmid}"
  description = "Temporary VM to build the Linux template from ISO via preseed."
  target_node = var.proxmox_node 
  vmid        = var.template_vmid

  # --- Hardware Resources ---
  memory  = 2048 
  cores   = 2
  sockets = 1

  # --- Disk Configuration ---
  disk {
    type    = "scsi"
    storage = "local-lvm" # Your desired storage for the main disk
    size    = "30G" 
    slot    = 0
    # The disk will be the primary boot target after installation
  }

  # --- Network Configuration ---
  network {
    model  = "virtio"
    bridge = "vmbr0" # Your primary Proxmox bridge
  }

  # --- ISO/CD-ROM Drive ---
  cdrom {
    # Mount the ISO for installation
    storage = split(":", var.iso_file_name)[0]
    file    = split(":", var.iso_file_name)[1]
    id      = 2 # Standard Proxmox CD-ROM ID
  }

  # --- Unattended Installation Logic (CRITICAL) ---
  # Boot order: CD-ROM (ide2) first, then the disk (scsi0)
  boot = "order=ide2;scsi0" 
  boot_delay = 5 # Give it a few seconds to start the console

  # This argument is passed to the Linux kernel to start the unattended install
  # The 'initrd' and 'preseed' flags tell the installer how to find the answer file.
  args = "-boot d net.ifnames=0 biosdevname=0 auto=true url=${var.preseed_url} ---" 

  # Set a high timeout because a full OS installation is a long process
  timeouts {
    create = "20m" # 20 minutes is a reasonable minimum for unattended installs
    update = "20m"
    delete = "5m"
  }

  # --- Post-Creation Provisioner: Convert to Template ---
  provisioner "local-exec" {
    # This runs ONLY after the proxmox_vm_qemu resource has been created 
    # and the timeout has expired (meaning the install *should* be done).
    # We rename the VM to the final template name and convert it.
    
    command = <<-EOT
      echo "Installation is assumed complete after timeout. Converting to Template..."
      
      # 1. Set the final template name
      pvesh set /nodes/${var.proxmox_node}/qemu/${proxmox_vm_qemu.iso_template_builder.vmid} --name ${var.final_template_name}
      
      # 2. Convert to template
      pvesh create /nodes/${var.proxmox_node}/qemu/${proxmox_vm_qemu.iso_template_builder.vmid}/template

      echo "Template ${var.final_template_name} (${proxmox_vm_qemu.iso_template_builder.vmid}) created successfully."
    EOT
    
    # Run this provisioner only on creation of the VM
    when = create
    
    # We need the pvesh command (Proxmox shell tool) to be available 
    # where you run terraform, or you need to run it via ssh to the PVE node.
  }
}
