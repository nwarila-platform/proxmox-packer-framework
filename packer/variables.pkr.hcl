# ============================================================================================= #
# - File: .\variables.pkr.hcl                                                 | Version: v1.0.0 #
# --- [ Description ] ------------------------------------------------------------------------- #
#                                                                                               #
# ============================================================================================= #

#region ------ [ Proxmox Settings ] ----------------------------------------------------------- #

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
  description = "true/false to skip Proxmox TLS certificate checks."
  type        = bool
  default     = false
}

#endregion --- [ Proxmox Settings ] ----------------------------------------------------------- #

#region ------ [ Packer Settings ] ------------------------------------------------------------ #

variable "deploy_user_name" {
  type        = string
  description = "The username to log in to the guest operating system. (e.g. 'ubuntu')"
  sensitive   = true
}

variable "deploy_user_password" {
  type        = string
  description = "The password to log in to the guest operating system."
  sensitive   = true
}

variable "deploy_user_key" {
  type        = string
  description = "The SSH public key to log in to the guest operating system."
  sensitive   = true
}

#endregion --- [ Packer Settings ] ------------------------------------------------------------ #

#region ------ [ Packer Image ] --------------------------------------------------------------- #

variable "packer_image" {
  description = ""
  type = object({

    # Proxmox Settings
    insecure_skip_tls_verify = bool

    # OS Installation & Configuration
    install_method      = string
    additional_packages = list(string)

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

}

variable "additional_iso_files" {
  description = "Additional ISO files to be attached to the VM."
  type = list(
    object({
      /* Required Variables */
      iso_checksum = string
      /* Either iso_url or iso_urls Required */
      iso_file = string
      iso_urls = list(string)
      /* Optional Variables */
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
  description = "The boot ISO configuration for the VM."
  type = object({
    /* Required Variables */
    iso_checksum = string
    /* Either iso_url or iso_urls Required */
    iso_file = string
    iso_urls = list(string)
    /* Optional Variables */
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
}

variable "efi_config" {
  description = ""
  type = object({
    efi_format        = string
    efi_storage_pool  = string
    efi_type          = string
    pre_enrolled_keys = bool
  })
}

variable "network_adapters" {
  description = "List of network adapters to attach to the VM."
  type = list(
    object({
      /* Optional Variables */
      # Network Configuration
      ipv4_address = string
      ipv4_netmask = number
      ipv4_gateway = string
      dns          = list(string)
      # Hardware Configuration
      bridge        = string
      firewall      = bool
      mac_address   = string
      model         = string
      mtu           = number
      packet_queues = number
      vlan_tag      = number
    })
  )
}

variable "pci_devices" {
  description = "List of PCI devices to passthrough to the VM."
  type = list(
    object({
      /* Note: Either 'host' or 'mapping' Required */
      host    = string
      mapping = string
      /* Optional Variables */
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
    /* Optional Variables */
    source    = string
    max_bytes = number
    period    = number
  })
}

variable "tpm_config" {
  description = "The TPM configuration for the VM."
  type = object({
    /* Optional Variables */
    tpm_storage_pool = string
    tpm_version      = string
  })
}

variable "vga" {
  description = "The VGA configuration for the VM."
  type = object({
    /* Optional Variables */
    type   = string
    memory = number
  })
}

#endregion --- [ Packer Image ] --------------------------------------------------------------- #

#region ------ [ Virtual Machine (VM) Settings ] ---------------------------------------------- #

variable "vm_disk_use_swap" {
  type        = bool
  description = "Whether to use a swap partition."
}

variable "vm_disk_partitions" {
  type = list(object({
    name = string
    size = number
    format = object({
      label  = string
      fstype = string
    })
    mount = object({
      path    = string
      options = string
    })
    volume_group = string
  }))
  description = "The disk partitions for the virtual disk."
}

variable "vm_disk_lvm" {
  type = list(object({
    name = string
    partitions = list(object({
      name = string
      size = number
      format = object({
        label  = string
        fstype = string
      })
      mount = object({
        path    = string
        options = string
      })
    }))
  }))
  description = "The LVM configuration for the virtual disk."
  default     = []
}

#endregion --- [ Virtual Machine (VM) Settings - Storage ] ---------------------------------- #
