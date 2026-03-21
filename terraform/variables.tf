# ============================================================================================ #
# variables.tf — Input variable declarations for ISO lifecycle management                      #
# ============================================================================================ #

#region ------ [ Proxmox Settings ] ---------------------------------------------------------- #

variable "proxmox_hostname" {
  type        = string
  description = "The FQDN or IP address of a Proxmox node."
  sensitive   = true
}

variable "proxmox_api_token_id" {
  type        = string
  description = "The token to login to the Proxmox node/cluster. The format is USER@REALM!TOKENID. (e.g. packer@pam!packer_pve_token)"
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  type        = string
  description = "The secret for the API token used to login to the Proxmox API."
  sensitive   = true
}

variable "proxmox_skip_tls_verify" {
  type        = bool
  default     = false
  description = "Skip TLS certificate verification when connecting to the Proxmox API. Defaults to false (secure). Set to true only in environments with self-signed certificates."
}

#endregion --- [ Proxmox Settings ] ---------------------------------------------------------- #

#region ------ [ ISO Files ] ----------------------------------------------------------------- #

variable "iso_files" {
  description = "List of ISO files to download and manage on Proxmox storage. Terraform owns the full lifecycle — removing an entry deletes the ISO from the node."
  type = list(
    object({
      name               = string
      node_name          = string
      datastore_id       = string
      content_type       = string
      url                = string
      checksum           = string
      checksum_algorithm = string
      file_name          = string
      overwrite          = bool
      upload_timeout     = number
      verify             = bool
    })
  )

  validation {
    condition     = length(var.iso_files) > 0
    error_message = "At least one ISO file must be defined."
  }
}

#endregion --- [ ISO Files ] ----------------------------------------------------------------- #
