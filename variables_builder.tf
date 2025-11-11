# --- VARIABLES_BUILDER.TF (Template Variables) ---

# --- Connection Secrets (REQUIRED BY TERRAFORM PLAN) ---
# These must be set via -var in Jenkins
variable "pm_api_url" {
  description = "The URL for the Proxmox API"
  type        = string
}
variable "pm_api_token_id" {
  description = "The Proxmox API Token ID"
  type        = string
  sensitive   = true
}
variable "pm_api_token_secret" {
  description = "The Proxmox API Token Secret"
  type        = string
  sensitive   = true
}

# --- Cloud Image Configuration ---
variable "ubuntu_image_url" {
  description = "URL to the Cloud Image."
  type        = string
  default     = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
}
variable "image_file_name" {
  description = "The name to give the downloaded QCOW2 file."
  type        = string
  default     = "ubuntu-2204-cloudinit.qcow2"
}
variable "ci_default_user" {
  description = "Default user for the Cloud-Init template."
  type        = string
  default     = "ubuntu"
}

# --- Proxmox Infrastructure Defaults (Can be overridden via Jenkins) ---
variable "proxmox_node" {
  description = "The name of the Proxmox node to deploy the template to"
  type        = string
  default     = "pve"
}
variable "storage_vm_disk" {
  description = "The storage identifier for VM disks (e.g., 'local-lvm')"
  type        = string
  default     = "local-lvm"
}
variable "network_bridge" {
  description = "The Proxmox network bridge for the template (must exist)"
  type        = string
  default     = "vmbr0"
}

# --- Template Resource Settings ---
variable "template_name_new" {
  description = "The final name of the Ubuntu template (used by the VM Provisioner job)"
  type        = string
  default     = "ubuntu-2204-cloudinit-template-swa"
}
variable "template_vmid" {
  description = "The unique VMID for the template (use a high number like 9000)"
  type        = number
  default     = 9000
}
variable "template_cores" {
  description = "Number of CPU cores for the base template."
  type        = number
  default     = 1
}
variable "template_memory" {
  description = "Amount of memory in MB for the base template."
  type        = number
  default     = 1024
}
variable "template_disk_size" {
  description = "Disk size for the base template (initial OS size)."
  type        = string
  default     = "20G"
}
