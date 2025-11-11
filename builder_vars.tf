# builder_vars.tf

variable "pm_api_url" {}
variable "pm_api_token_id" {}
variable "pm_api_token_secret" {}
variable "proxmox_node" {}

variable "template_vmid" {
  description = "The VMID to assign to the new template (must be unique)"
  type        = number
  default     = 9000
}

variable "iso_file_name" {
  description = "The full ISO file name located on Proxmox (e.g., 'local:iso/ubuntu-22.04.4-live-server-amd64.iso')"
  type        = string
}

variable "preseed_url" {
  description = "The HTTP URL where the unattended installation file (preseed.cfg) is hosted."
  type        = string
}

variable "final_template_name" {
  description = "The name for the resulting template"
  type        = string
  default     = "ubuntu-2204-template-from-iso"
}
