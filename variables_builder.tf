# --- VARIABLES_BUILDER.TF (Variables for the Template Build) ---
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
variable "proxmox_node" {
  description = "The name of the Proxmox node to deploy the template to"
  type        = string
  default     = "pve"
}
variable "storage_vm_disk" {
  description = "The Proxmox storage identifier for VM disks and Cloud Images (e.g., 'local-lvm')"
  type        = string
  default     = "local-lvm" 
}
variable "template_name_new" {
  description = "The final name of the Ubuntu template"
  type        = string
  default     = "ubuntu-2204-cloudinit-template-swa"
}
variable "network_bridge" {
  description = "The Proxmox network bridge for the VM"
  type        = string
  default     = "vmbr0"
}
