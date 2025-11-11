# --- variables.tf (FINAL CORRECTED VERSION) ---
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
  description = "The name of the Proxmox node to deploy to"
  type        = string
  default     = "pve"
}

variable "storage_vm_disk" {
  description = "The storage pool where the VM disk will be stored"
  type        = string
  default     = "local-lvm" 
}

# **THIS IS THE CRUCIAL MISSING VARIABLE DECLARATION**
variable "vm_template_name" {
  description = "The name of the Proxmox template to clone"
  type        = string
}

variable "ci_default_user" {
  description = "The default cloud-init user for the VM"
  type        = string
  default     = "terraform"
}
