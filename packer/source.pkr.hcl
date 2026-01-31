# ============================================================================================= #
# - File: .\sources.pkr.hcl                                                   | Version: v1.0.0 #
# --- [ Description ] ------------------------------------------------------------------------- #
#                                                                                               #
# ============================================================================================= #

source "proxmox-iso" "packer_image" {

  # Proxmox Configuration
  proxmox_url = "https://${var.proxmox_hostname}:8006/api2/json"
  username    = "${var.proxmox_api_token_id}"
  token       = "${var.proxmox_api_token_secret}"

  # SSH Configuration
  ssh_ciphers                 = ["aes128-gcm@openssh.com", "aes128-ctr", "aes192-ctr", "aes256-ctr"]
  ssh_host                    = "${var.network_adapters[0].ipv4_address}"
  ssh_key_exchange_algorithms = ["ecdh-sha2-nistp256", "ecdh-sha2-nistp384", "ecdh-sha2-nistp521"]
  ssh_password                = "${var.deploy_user_password}"
  ssh_port                    = "22"
  ssh_timeout                 = "30m"
  ssh_username                = "${var.deploy_user_name}"

  # Proxmox Settings
  insecure_skip_tls_verify = local.packer_image.insecure_skip_tls_verify

  # General Settings
  node = local.packer_image.node
  pool = local.packer_image.pool
  # tags                      = local.packer_image.tags
  template_description = local.packer_image.template_description
  template_name        = local.packer_image.template_name
  vm_id                = local.packer_image.vm_id
  vm_name              = local.packer_image.vm_name

  # QEMU Agent
  qemu_agent           = local.packer_image.qemu_agent
  qemu_additional_args = local.packer_image.qemu_additional_args

  # Misc Settings
  disable_kvm  = local.packer_image.disable_kvm
  machine      = local.packer_image.machine
  os           = local.packer_image.os
  task_timeout = local.packer_image.task_timeout

  # VM Configuration: Boot Settings
  bios                   = local.packer_image.bios
  boot                   = local.packer_image.boot
  boot_command           = local.packer_image.boot_command
  boot_key_interval      = local.packer_image.boot_key_interval
  boot_keygroup_interval = local.packer_image.boot_keygroup_interval
  boot_wait              = local.packer_image.boot_wait
  onboot                 = local.packer_image.onboot

  # VM Configuration: Cloud-Init
  cloud_init              = local.packer_image.cloud_init
  cloud_init_disk_type    = local.packer_image.cloud_init_disk_type
  cloud_init_storage_pool = local.packer_image.cloud_init_storage_pool

  # Hardware: CPU
  cores    = local.packer_image.cores
  cpu_type = local.packer_image.cpu_type
  sockets  = local.packer_image.sockets

  # Hardware: Memory
  ballooning_minimum = local.packer_image.ballooning_minimum
  memory             = local.packer_image.memory
  numa               = local.packer_image.numa

  # Hardware: Misc
  scsi_controller = local.packer_image.scsi_controller
  serials         = local.packer_image.serials
  vm_interface    = local.packer_image.vm_interface


  dynamic "additional_iso_files" {
    for_each = coalesce(local.additional_iso_files, [])
    iterator = additional_iso_file

    content {
      cd_content           = additional_iso_file.value["cd_content"]
      cd_files             = additional_iso_file.value["cd_files"]
      cd_label             = additional_iso_file.value["cd_label"]
      index                = additional_iso_file.value["index"]
      iso_checksum         = additional_iso_file.value["iso_checksum"]
      iso_download_pve     = additional_iso_file.value["iso_download_pve"]
      iso_file             = additional_iso_file.value["iso_file"]
      iso_storage_pool     = additional_iso_file.value["iso_storage_pool"]
      iso_target_extension = additional_iso_file.value["iso_target_extension"]
      iso_target_path      = additional_iso_file.value["iso_target_path"]
      iso_urls             = additional_iso_file.value["iso_urls"]
      keep_cdrom_device    = additional_iso_file.value["keep_cdrom_device"]
      type                 = additional_iso_file.value["type"]
      unmount              = additional_iso_file.value["unmount"]
    }
  }


  dynamic "boot_iso" {
    for_each = local.boot_iso == null ? [] : [1]

    content {
      cd_label             = local.boot_iso["cd_label"]
      iso_checksum         = local.boot_iso["iso_checksum"]
      iso_file             = local.boot_iso["iso_file"]
      iso_urls             = local.boot_iso["iso_urls"]
      index                = local.boot_iso["index"]
      iso_download_pve     = local.boot_iso["iso_download_pve"]
      iso_storage_pool     = local.boot_iso["iso_storage_pool"]
      iso_target_extension = local.boot_iso["iso_target_extension"]
      iso_target_path      = local.boot_iso["iso_target_path"]
      keep_cdrom_device    = local.boot_iso["keep_cdrom_device"]
      type                 = local.boot_iso["type"]
      unmount              = local.boot_iso["unmount"]
    }
  }


  dynamic "disks" {
    for_each = local.disks
    iterator = disk

    content {
      asyncio             = disk.value["asyncio"]
      cache_mode          = disk.value["cache_mode"]
      discard             = disk.value["discard"]
      disk_size           = disk.value["size"]
      exclude_from_backup = disk.value["exclude_from_backup"]
      format              = disk.value["format"]
      io_thread           = disk.value["io_thread"]
      ssd                 = disk.value["ssd"]
      storage_pool        = disk.value["storage_pool"]
      type                = disk.value["type"]
    }
  }


  dynamic "efi_config" {
    for_each = local.packer_image.bios == "ovmf" ? [1] : []

    content {
      efi_format        = local.efi_config["efi_format"]
      efi_storage_pool  = local.efi_config["efi_storage_pool"]
      efi_type          = local.efi_config["efi_type"]
      pre_enrolled_keys = local.efi_config["pre_enrolled_keys"]
    }
  }


  dynamic "network_adapters" {
    for_each = local.network_adapters
    iterator = network_adapter

    content {
      bridge        = network_adapter.value["bridge"]
      firewall      = network_adapter.value["firewall"]
      mac_address   = network_adapter.value["mac_address"]
      model         = network_adapter.value["model"]
      mtu           = network_adapter.value["mtu"]
      packet_queues = network_adapter.value["packet_queues"]
      vlan_tag      = network_adapter.value["vlan_tag"]
    }
  }


  dynamic "pci_devices" {
    for_each = local.pci_devices == null ? null : local.pci_devices
    iterator = pci_device

    content {
      device_id     = pci_device.value["device_id"]
      hide_rombar   = pci_device.value["hide_rombar"]
      host          = pci_device.value["host"]
      legacy_igd    = pci_device.value["legacy_igd"]
      mapping       = pci_device.value["mapping"]
      mdev          = pci_device.value["mdev"]
      pcie          = pci_device.value["pcie"]
      romfile       = pci_device.value["romfile"]
      sub_device_id = pci_device.value["sub_device_id"]
      sub_vendor_id = pci_device.value["sub_vendor_id"]
      vendor_id     = pci_device.value["vendor_id"]
      x_vga         = pci_device.value["x_vga"]
    }
  }


  dynamic "rng0" {
    for_each = local.rng0 == null ? [] : [1]
    iterator = rng0

    content {
      source    = local.rng0["source"]
      max_bytes = local.rng0["max_bytes"]
      period    = local.rng0["period"]
    }
  }


  dynamic "tpm_config" {
    for_each = local.tpm_config == null ? [] : [1]

    content {
      tpm_storage_pool = local.tpm_config["tpm_storage_pool"]
      tpm_version      = local.tpm_config["tpm_version"]
    }
  }


  dynamic "vga" {
    for_each = local.vga == null ? [] : [1]

    content {
      type   = local.vga["type"]
      memory = local.vga["memory"]
    }
  }

}
