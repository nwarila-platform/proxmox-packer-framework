# ============================================================================================ #
# locals.pkr.hcl — Variable normalization and template rendering                               #
#                                                                                              #
# This file is the "brains" of the framework. It normalizes consumer inputs with sensible      #
# defaults, assembles the template variable contract, and constructs the install ISO from the  #
# consumer-provided install template.                                                          #
# ============================================================================================ #

locals {

  #region ------ [ Packer Image Normalization ] ---------------------------------------------- #

  packer_image = {

    # Proxmox Settings
    insecure_skip_tls_verify = coalesce(
      var.proxmox_skip_tls_verify,
      var.packer_image.insecure_skip_tls_verify,
      false
    )

    # Connection Settings
    communicator  = coalesce(var.packer_image.communicator, "ssh")
    ssh_timeout   = coalesce(var.packer_image.ssh_timeout, "30m")
    winrm_timeout = coalesce(var.packer_image.winrm_timeout, "60m")
    winrm_use_ssl = coalesce(var.packer_image.winrm_use_ssl, true)
    winrm_port = coalesce(
      var.packer_image.winrm_port,
      coalesce(var.packer_image.winrm_use_ssl, true) ? 5986 : 5985
    )
    winrm_insecure = coalesce(
      var.packer_image.winrm_insecure,
      coalesce(var.packer_image.winrm_use_ssl, true) ? false : true
    )
    winrm_use_ntlm = coalesce(var.packer_image.winrm_use_ntlm, true)
    winrm_transport = coalesce(
      var.packer_image.winrm_transport,
      coalesce(var.packer_image.winrm_use_ntlm, true) ? "ntlm" : "basic"
    )
    winrm_server_cert_validation = coalesce(
      var.packer_image.winrm_server_cert_validation,
      coalesce(var.packer_image.winrm_use_ssl, true) ? "validate" : "ignore"
    )

    # Template Metadata
    os_language = coalesce(var.packer_image.os_language, "en_US")
    os_keyboard = coalesce(var.packer_image.os_keyboard, "us")
    os_timezone = coalesce(var.packer_image.os_timezone, "UTC")
    os_family   = var.packer_image.os_family
    os_name     = var.packer_image.os_name
    os_version  = var.packer_image.os_version

    # General Settings
    node                 = coalesce(var.proxmox_node, var.packer_image.node)
    pool                 = var.packer_image.pool
    tags                 = coalesce(var.packer_image.tags, [])
    template_description = "${var.packer_image.template_description} | Built: ${timestamp()}"
    template_name        = var.packer_image.template_name
    vm_id                = var.packer_image.vm_id
    vm_name              = var.packer_image.vm_name

    # QEMU Agent
    qemu_agent           = coalesce(var.packer_image.qemu_agent, true)
    qemu_additional_args = var.packer_image.qemu_additional_args

    # Misc Settings
    disable_kvm  = coalesce(var.packer_image.disable_kvm, false)
    machine      = coalesce(var.packer_image.machine, "q35")
    os           = var.packer_image.os
    task_timeout = coalesce(var.packer_image.task_timeout, "30m")

    # VM Configuration: Boot Settings
    bios                   = coalesce(var.packer_image.bios, "ovmf")
    boot                   = coalesce(var.packer_image.boot, "order=scsi2;scsi0;net0")
    boot_command           = coalesce(var.packer_image.boot_command, [])
    boot_key_interval      = var.packer_image.boot_key_interval
    boot_keygroup_interval = var.packer_image.boot_keygroup_interval
    boot_wait              = coalesce(var.packer_image.boot_wait, "10s")
    onboot                 = coalesce(var.packer_image.onboot, false)

    # VM Configuration: Cloud-Init
    cloud_init           = coalesce(var.packer_image.cloud_init, true)
    cloud_init_disk_type = coalesce(var.packer_image.cloud_init_disk_type, "scsi")
    cloud_init_storage_pool = coalesce(
      var.packer_image.cloud_init_storage_pool,
      local.disks[0].storage_pool
    )

    # Hardware: CPU
    cores    = coalesce(var.packer_image.cores, 1)
    cpu_type = coalesce(var.packer_image.cpu_type, "host")
    sockets  = coalesce(var.packer_image.sockets, 1)

    # Hardware: Memory
    ballooning_minimum = coalesce(var.packer_image.ballooning_minimum, 0)
    memory             = coalesce(var.packer_image.memory, 2048)
    numa               = coalesce(var.packer_image.numa, false)

    # Hardware: Misc
    scsi_controller = coalesce(var.packer_image.scsi_controller, "virtio-scsi-single")
    serials         = coalesce(var.packer_image.serials, [])
    vm_interface    = var.packer_image.vm_interface

  }

  #endregion --- [ Packer Image Normalization ] ---------------------------------------------- #

  #region ------ [ Bundled Media Profiles ] -------------------------------------------------- #

  framework_media_catalog = jsondecode(file("${path.root}/iso/catalog.json"))

  framework_media_profile_aliases = {
    "rocky-9"             = "rocky-linux-9"
    "ubuntu-24.04"        = "ubuntu-24-04-lts"
    "windows-server-2022" = "windows-server-2022"
  }

  inferred_media_profile = try(
    local.framework_media_profile_aliases["${local.packer_image.os_name}-${local.packer_image.os_version}"],
    null
  )

  selected_media_profile_key = var.media_profile != null ? var.media_profile : local.inferred_media_profile

  selected_media_profile = local.selected_media_profile_key == null ? null : try(
    local.framework_media_catalog[local.selected_media_profile_key],
    null
  )

  effective_boot_iso = (
    var.boot_iso != null
    ? var.boot_iso
    : (local.selected_media_profile == null ? null : try(local.selected_media_profile.boot_iso, null))
  )

  effective_additional_iso_files = concat(
    local.selected_media_profile == null ? [] : try(local.selected_media_profile.additional_iso_files, []),
    var.additional_iso_files
  )

  #endregion --- [ Bundled Media Profiles ] ---------------------------------------------------- #

  #region ------ [ Template Variable Contract ] ------------------------------------------------ #

  template_vars = {

    # Credentials
    deploy_user_name     = var.deploy_user_name
    deploy_user_password = var.deploy_user_password
    deploy_user_public_key      = var.deploy_user_public_key

    # Locale
    os_language = local.packer_image.os_language
    os_keyboard = local.packer_image.os_keyboard
    os_timezone = local.packer_image.os_timezone

    # OS Metadata
    os_family  = local.packer_image.os_family
    os_name    = local.packer_image.os_name
    os_version = local.packer_image.os_version

    # Network (first adapter, pre-resolved)
    network_device = (
      var.network_adapters[0].mac_address != null && var.network_adapters[0].mac_address != ""
      ? var.network_adapters[0].mac_address
      : "link"
    )
    network_ipv4_address = var.network_adapters[0].ipv4_address
    network_ipv4_netmask = var.network_adapters[0].ipv4_netmask
    network_ipv4_gateway = var.network_adapters[0].ipv4_gateway
    network_dns          = var.network_adapters[0].dns

    # Build Context
    build_bios         = local.packer_image.bios
    build_communicator = local.packer_image.communicator

    # Hardware Summary
    hw_cores     = local.packer_image.cores
    hw_memory    = local.packer_image.memory
    hw_disk_size = local.disks[0].size

  }

  #endregion --- [ Template Variable Contract ] ---------------------------------------------- #

  #region ------ [ Install ISO ] ------------------------------------------------------------- #

  install_iso = [
    {
      cd_files             = null
      index                = 1
      iso_checksum         = null
      iso_download_pve     = null
      iso_file             = null
      iso_storage_pool     = coalesce(var.install_template.iso_storage_pool, local.disks[0].storage_pool)
      iso_target_extension = "iso"
      iso_target_path      = "iso"
      iso_urls             = null
      keep_cdrom_device    = true
      type                 = var.install_template.cd_type
      unmount              = true

      cd_label = var.install_template.cd_label
      cd_content = merge(
        var.install_template.extra_cd_content,
        {
          (var.install_template.output_file) = templatefile(
            var.install_template.template_path,
            local.template_vars
          )
        }
      )
    }
  ]

  #endregion --- [ Install ISO ] ------------------------------------------------------------- #

  #region ------ [ Hardware Normalization ] -------------------------------------------------- #

  additional_iso_files = concat(
    local.install_iso,
    [
      for additional_iso_file in local.effective_additional_iso_files : {
        cd_content       = additional_iso_file.cd_content
        cd_files         = additional_iso_file.cd_files
        cd_label         = additional_iso_file.cd_label
        index            = additional_iso_file.index
        iso_checksum     = additional_iso_file.iso_checksum
        iso_download_pve = coalesce(additional_iso_file.iso_download_pve, false)
        iso_file         = additional_iso_file.iso_file
        iso_storage_pool = coalesce(
          additional_iso_file.iso_storage_pool,
          local.disks[0].storage_pool
        )
        iso_target_extension = coalesce(additional_iso_file.iso_target_extension, "iso")
        iso_target_path      = additional_iso_file.iso_target_path
        iso_urls             = additional_iso_file.iso_urls
        keep_cdrom_device    = coalesce(additional_iso_file.keep_cdrom_device, false)
        type                 = coalesce(additional_iso_file.type, "scsi")
        unmount              = coalesce(additional_iso_file.unmount, true)
      }
    ]
  )

  boot_iso = local.effective_boot_iso == null ? null : {
    cd_label         = coalesce(local.effective_boot_iso.cd_label, "BOOTISO")
    iso_checksum     = local.effective_boot_iso.iso_checksum
    iso_file         = local.effective_boot_iso.iso_file
    iso_urls         = local.effective_boot_iso.iso_urls
    index            = coalesce(local.effective_boot_iso.index, 10)
    iso_download_pve = coalesce(local.effective_boot_iso.iso_download_pve, false)
    iso_storage_pool = coalesce(
      local.effective_boot_iso.iso_storage_pool,
      local.disks[0].storage_pool
    )
    iso_target_extension = coalesce(local.effective_boot_iso.iso_target_extension, "iso")
    iso_target_path      = local.effective_boot_iso.iso_target_path
    keep_cdrom_device    = coalesce(local.effective_boot_iso.keep_cdrom_device, false)
    type                 = coalesce(local.effective_boot_iso.type, "scsi")
    unmount              = coalesce(local.effective_boot_iso.unmount, true)
  }

  disks = [
    for disk in var.disks : {
      asyncio             = coalesce(disk.asyncio, "io_uring")
      cache_mode          = coalesce(disk.cache_mode, "none")
      discard             = coalesce(disk.discard, false)
      exclude_from_backup = coalesce(disk.exclude_from_backup, false)
      format              = coalesce(disk.format, "raw")
      io_thread           = coalesce(disk.io_thread, false)
      size                = disk.size
      ssd                 = coalesce(disk.ssd, true)
      storage_pool        = disk.storage_pool
      type                = coalesce(disk.type, "scsi")
    }
  ]

  efi_config = local.packer_image.bios == "seabios" ? null : (
    var.efi_config == null ? null : {
      efi_format = coalesce(var.efi_config.efi_format, "raw")
      efi_storage_pool = coalesce(
        var.efi_config.efi_storage_pool,
        local.disks[0].storage_pool
      )
      efi_type          = coalesce(var.efi_config.efi_type, "4m")
      pre_enrolled_keys = coalesce(var.efi_config.pre_enrolled_keys, true)
    }
  )

  network_adapters = [
    for network_adapter in var.network_adapters : {
      ipv4_address  = network_adapter.ipv4_address
      ipv4_netmask  = network_adapter.ipv4_netmask
      ipv4_gateway  = network_adapter.ipv4_gateway
      dns           = network_adapter.dns
      bridge        = network_adapter.bridge
      firewall      = coalesce(network_adapter.firewall, true)
      mac_address   = network_adapter.mac_address
      model         = coalesce(network_adapter.model, "virtio")
      mtu           = coalesce(network_adapter.mtu, 0)
      packet_queues = coalesce(network_adapter.packet_queues, 0)
      vlan_tag      = network_adapter.vlan_tag
    }
  ]

  pci_devices = [
    for pci_device in var.pci_devices : {
      host          = pci_device.host
      mapping       = pci_device.mapping
      device_id     = pci_device.device_id
      hide_rombar   = coalesce(pci_device.hide_rombar, false)
      legacy_igd    = coalesce(pci_device.legacy_igd, false)
      mdev          = pci_device.mdev
      pcie          = pci_device.pcie
      romfile       = pci_device.romfile
      sub_device_id = pci_device.sub_device_id
      sub_vendor_id = pci_device.sub_vendor_id
      vendor_id     = pci_device.vendor_id
      x_vga         = coalesce(pci_device.x_vga, false)
    }
  ]

  rng0 = var.rng0 == null ? null : {
    source    = coalesce(var.rng0.source, "/dev/urandom")
    max_bytes = coalesce(var.rng0.max_bytes, 1024)
    period    = coalesce(var.rng0.period, 1000)
  }

  tpm_config = local.packer_image.bios == "seabios" ? null : (
    var.tpm_config == null ? null : {
      tpm_storage_pool = coalesce(
        var.tpm_config.tpm_storage_pool,
        local.disks[0].storage_pool
      )
      tpm_version = coalesce(var.tpm_config.tpm_version, "v2.0")
    }
  )

  vga = var.vga == null ? null : {
    type   = coalesce(var.vga.type, "virtio")
    memory = var.vga.memory
  }

  #endregion --- [ Hardware Normalization ] ---------------------------------------------------- #

}
