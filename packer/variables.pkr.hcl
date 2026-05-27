# ============================================================================================ #
# variables.pkr.hcl — Input variable declarations for the Proxmox Packer Framework             #
# ============================================================================================ #

#region ------ [ Proxmox Settings ] ---------------------------------------------------------- #

variable "proxmox_hostname" {
  type        = string
  description = "The FQDN or IP address of a Proxmox node. Only one node should be specified in a cluster."
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
  description = "Optional top-level override for packer_image.insecure_skip_tls_verify. Useful when CI injects this value through PKR_VAR_proxmox_skip_tls_verify."
}

variable "proxmox_node" {
  type        = string
  description = "Optional top-level override for packer_image.node. Useful when CI injects this value through PKR_VAR_proxmox_node."
}

#endregion --- [ Proxmox Settings ] ---------------------------------------------------------- #

#region ------ [ Deploy User ] --------------------------------------------------------------- #

variable "deploy_user_name" {
  type        = string
  description = "The username for the deploy account in the guest operating system."
  sensitive   = true
}

variable "deploy_user_password" {
  type        = string
  description = "Plaintext deploy-user password. Used at build time only: as the WinRM password for Windows guests, and as the Ansible become_pass for Linux guests. Never baked into the resulting Linux image; the SHA-512 hash from deploy_user_password_hash is what lands in /etc/shadow. Provided by secure-packer-bootstrapper for Linux/SSH builds."
  sensitive   = true
}

variable "deploy_user_password_hash" {
  type        = string
  default     = null
  description = "SHA-512 crypt hash of deploy_user_password. Required for Linux/SSH builds (consumed by the install template, e.g. Kickstart user --iscrypted); ignored for Windows/WinRM builds. Generated at runtime by secure-packer-bootstrapper. Must begin with '$6$'."
  sensitive   = true

  validation {
    condition     = var.deploy_user_password_hash == null || can(regex("^\\$6\\$", var.deploy_user_password_hash))
    error_message = "The deploy_user_password_hash value must be a SHA-512 crypt hash beginning with '$6$', or null when not used. Use secure-packer-bootstrapper to generate it."
  }
}

variable "deploy_user_key" {
  type        = string
  default     = null
  description = "SSH public key for the deploy user. Required for Linux/SSH builds (the matching private key is loaded into ssh-agent on the runner); ignored for Windows/WinRM builds. Generated at runtime by secure-packer-bootstrapper."
  sensitive   = true
}

#endregion --- [ Deploy User ] --------------------------------------------------------------- #

#region ------ [ Install Template ] ---------------------------------------------------------- #

variable "install_template" {
  description = "Consumer-provided install template configuration. The framework renders this template with the guaranteed template variable contract and packages it onto a virtual CD for the OS installer."
  type = object({
    template_path    = string
    output_file      = string
    cd_label         = string
    cd_type          = string
    iso_storage_pool = string
    extra_cd_content = map(string)
  })
}

#endregion --- [ Install Template ] ---------------------------------------------------------- #

#region ------ [ Ansible Configuration ] ----------------------------------------------------- #

variable "ansible_config" {
  description = "Consumer-provided Ansible provisioner configuration. The framework handles connection wiring (SSH/WinRM) automatically based on communicator type; consumer owns playbook content and roles."
  type = object({
    playbook_path     = string
    requirements_path = string
    roles_path        = string
    config_path       = string
    extra_vars        = map(string)
  })
}

#endregion --- [ Ansible Configuration ] ----------------------------------------------------- #

#region ------ [ Packer Image ] -------------------------------------------------------------- #

variable "packer_image" {
  description = "The primary configuration object for the Proxmox VM template. Defines OS metadata, hardware specs, boot settings, cloud-init options, and Proxmox placement (node, pool, VM ID)."
  type = object({

    # Proxmox Settings
    insecure_skip_tls_verify = bool

    # Connection Settings
    communicator                 = string
    ssh_timeout                  = string
    winrm_timeout                = string
    winrm_port                   = number
    winrm_use_ssl                = bool
    winrm_insecure               = bool
    winrm_use_ntlm               = bool
    winrm_transport              = string
    winrm_server_cert_validation = string

    # Template Metadata
    os_language = string
    os_keyboard = string
    os_timezone = string
    os_family   = string
    os_name     = string
    os_version  = string

    # General Settings
    template_description = string
    template_name        = string
    vm_id                = number
    pool                 = string
    node                 = string
    vm_name              = string
    tags                 = list(string)

    # QEMU Agent
    qemu_agent           = bool
    qemu_additional_args = string

    # Misc Settings
    disable_kvm  = bool
    machine      = string
    os           = string
    task_timeout = string

    # VM Configuration: Boot Settings
    bios                   = string
    boot                   = string
    boot_key_interval      = string
    boot_keygroup_interval = string
    boot_wait              = string
    onboot                 = bool
    boot_command           = list(string)

    # VM Configuration: Cloud-Init
    cloud_init              = bool
    cloud_init_disk_type    = string
    cloud_init_storage_pool = string

    # Hardware: CPU
    cores    = number
    cpu_type = string
    sockets  = number

    # Hardware: Memory
    ballooning_minimum = number
    memory             = number
    numa               = bool

    # Hardware: Misc
    scsi_controller = string
    serials         = list(string)
    vm_interface    = string

  })

  validation {
    condition     = var.packer_image.communicator == null || contains(["ssh", "winrm"], var.packer_image.communicator)
    error_message = "The packer_image.communicator value must be \"ssh\" or \"winrm\"."
  }

  validation {
    condition     = var.packer_image.bios == null || contains(["ovmf", "seabios"], var.packer_image.bios)
    error_message = "The packer_image.bios value must be \"ovmf\" or \"seabios\"."
  }

}

variable "additional_iso_files" {
  description = "Additional ISO files to be attached to the VM (e.g. VirtIO drivers)."
  default     = []
  type = list(
    object({
      iso_checksum         = string
      iso_file             = string
      iso_urls             = list(string)
      cd_content           = map(string)
      cd_files             = list(string)
      cd_label             = string
      index                = number
      iso_download_pve     = bool
      iso_storage_pool     = string
      iso_target_extension = string
      iso_target_path      = string
      keep_cdrom_device    = bool
      type                 = string
      unmount              = bool
    })
  )
}

variable "boot_iso" {
  description = "The boot ISO configuration for the VM. ISO lifecycle is owned externally (see docs/architecture.md). Consumers must supply this value — typically rendered from the Terraform-managed ISO module output into an auto-loaded pkrvars file."
  default     = null
  type = object({
    iso_checksum         = string
    iso_file             = string
    iso_urls             = list(string)
    cd_label             = string
    index                = number
    iso_download_pve     = bool
    iso_storage_pool     = string
    iso_target_extension = string
    iso_target_path      = string
    keep_cdrom_device    = bool
    type                 = string
    unmount              = bool
  })

  validation {
    condition     = var.boot_iso != null
    error_message = "The boot_iso value must be supplied explicitly by the caller. Render it from terraform-proxmox-iso-manager-framework outputs into a pkrvars file and pass that file through the reusable workflow var_file input."
  }
}

variable "disks" {
  description = "List of disks to attach to the VM."
  type = list(
    object({
      asyncio             = string
      cache_mode          = string
      discard             = bool
      exclude_from_backup = bool
      format              = string
      io_thread           = bool
      size                = string
      ssd                 = bool
      storage_pool        = string
      type                = string
    })
  )

  validation {
    condition     = length(var.disks) > 0
    error_message = "At least one disk must be defined."
  }
}

variable "efi_config" {
  description = "UEFI firmware configuration for the VM. Controls EFI disk format, storage pool, EFI type (2m/4m), and whether Microsoft Secure Boot keys are pre-enrolled."
  type = object({
    efi_format        = string
    efi_storage_pool  = string
    efi_type          = string
    pre_enrolled_keys = bool
  })
}

variable "network_adapters" {
  description = "List of network adapters to attach to the VM. At least one adapter is required; the first adapter is used for communicator host and install-time networking."
  type = list(
    object({
      ipv4_address  = string
      ipv4_netmask  = number
      ipv4_gateway  = string
      dns           = list(string)
      bridge        = string
      firewall      = bool
      mac_address   = string
      model         = string
      mtu           = number
      packet_queues = number
      vlan_tag      = number
    })
  )

  validation {
    condition     = length(var.network_adapters) > 0
    error_message = "At least one network adapter must be defined. The first adapter is used for communicator host and install-time networking."
  }
}

variable "pci_devices" {
  description = "List of PCI devices to passthrough to the VM."
  type = list(
    object({
      host          = string
      mapping       = string
      device_id     = string
      hide_rombar   = bool
      legacy_igd    = bool
      mdev          = string
      pcie          = bool
      romfile       = string
      sub_device_id = string
      sub_vendor_id = string
      vendor_id     = string
      x_vga         = bool
    })
  )
}

variable "rng0" {
  description = "The RNG device configuration for the VM."
  type = object({
    source    = string
    max_bytes = number
    period    = number
  })
}

variable "tpm_config" {
  description = "The TPM configuration for the VM."
  type = object({
    tpm_storage_pool = string
    tpm_version      = string
  })
}

variable "vga" {
  description = "The VGA configuration for the VM."
  type = object({
    type   = string
    memory = number
  })
}

#endregion --- [ Packer Image ] -------------------------------------------------------------- #
