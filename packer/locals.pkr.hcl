# ============================================================================================= #
# - File: .\locals.pkr.hcl                                                    | Version: v1.0.0 #
# --- [ Description ] ------------------------------------------------------------------------- #
#   The locals file is the "brains" of the playbook. It's responsible for building the final    #
# object that gets passed as directly as possible to the "proxmox-iso" source.                  #
# ============================================================================================= #

locals {

  kickstart_file = (
    var.packer_image.install_method != "kickstart" ? [] : [
      {
        cd_files             = null
        index                = 1
        iso_checksum         = null
        iso_download_pve     = null
        iso_file             = null
        iso_storage_pool     = "cephFS"
        iso_target_extension = "iso"
        iso_target_path      = "iso"
        iso_urls             = null
        keep_cdrom_device    = true
        type                 = "scsi"
        unmount              = true

        cd_label = "OEMDRV"
        cd_content = {
          "/ks.cfg" = templatefile(
            "${abspath(path.root)}/templates/ks.pkrtpl.hcl",
            {
              additional_packages  = join(" ", coalesce(var.packer_image.additional_packages, []))
              deploy_user_name     = var.deploy_user_name
              deploy_user_password = var.deploy_user_password
              deploy_user_key      = var.deploy_user_key
              os_language          = local.packer_image.os_language
              os_keyboard          = local.packer_image.os_keyboard
              os_timezone          = local.packer_image.os_timezone

              # Networking Information
              device = (
                var.network_adapters[0].mac_address != null && var.network_adapters[0].mac_address != ""
                ? var.network_adapters[0].mac_address
                : "link"
              )
              ipv4_address = var.network_adapters[0].ipv4_address
              ipv4_netmask = var.network_adapters[0].ipv4_netmask
              ipv4_gateway = var.network_adapters[0].ipv4_gateway
              dns          = var.network_adapters[0].dns

              # Drive Information
              swap       = var.vm_disk_use_swap
              partitions = var.vm_disk_partitions
              lvm        = var.vm_disk_lvm

            }
          ) #"/ks.cfg"
        }   #data_source_content
      }     #var.packer_image
    ]
  ) #kickstart_file

  packer_image = {

    # Proxmox Settings
    insecure_skip_tls_verify = coalesce(var.packer_image.insecure_skip_tls_verify, false)

    # OS Installation & Configuration
    install_method = var.packer_image.install_method

    # Template Metadata
    os_language = coalesce(var.packer_image.os_language, "en_US")
    os_keyboard = coalesce(var.packer_image.os_keyboard, "us")
    os_timezone = coalesce(var.packer_image.os_timezone, "UTC")
    os_family   = var.packer_image.os_family
    os_name     = var.packer_image.os_name
    os_version  = var.packer_image.os_version

    # General Settings
    node                 = var.packer_image.node
    pool                 = var.packer_image.pool
    tags                 = var.packer_image.tags
    template_description = var.packer_image.template_description
    template_name        = var.packer_image.template_name
    vm_id                = var.packer_image.vm_id
    vm_name              = var.packer_image.vm_name

    # QEMU Agent
    qemu_agent           = coalesce(var.packer_image.qemu_agent, true)
    qemu_additional_args = var.packer_image.qemu_additional_args != null ? var.packer_image.qemu_additional_args : null

    # Misc Settings
    disable_kvm  = coalesce(var.packer_image.disable_kvm, false)
    machine      = coalesce(var.packer_image.machine, "q35")
    os           = var.packer_image.os
    task_timeout = coalesce(var.packer_image.task_timeout, "30m")

    # VM Configuration: Boot Settings
    bios                   = coalesce(var.packer_image.bios, "ovmf")
    boot                   = coalesce(var.packer_image.boot, "order=scsi2;scsi0;net0")
    boot_command           = coalesce(var.packer_image.boot_command, [])
    boot_key_interval      = var.packer_image.boot_key_interval == null ? null : var.packer_image.boot_key_interval
    boot_keygroup_interval = var.packer_image.boot_keygroup_interval == null ? null : var.packer_image.boot_keygroup_interval
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
    vm_interface    = null

  }

  additional_iso_files = concat(
    local.kickstart_file,
    [
      for additional_iso_file in var.additional_iso_files : {
        cd_content       = additional_iso_file.cd_content == null ? null : additional_iso_file.cd_content
        cd_files         = additional_iso_file.cd_files == null ? null : additional_iso_file.cd_files
        cd_label         = additional_iso_file.cd_label == null ? null : additional_iso_file.cd_label
        index            = additional_iso_file.index == null ? null : additional_iso_file.index
        iso_checksum     = additional_iso_file.iso_checksum
        iso_download_pve = coalesce(additional_iso_file.iso_download_pve, false)
        iso_file         = additional_iso_file.iso_file == null ? null : additional_iso_file.iso_file
        iso_storage_pool = coalesce(
          additional_iso_file.iso_storage_pool,
          local.disks[0].storage_pool
        )
        iso_target_extension = coalesce(additional_iso_file.iso_target_extension, "iso")
        iso_target_path      = additional_iso_file.iso_target_path == null ? null : additional_iso_file.iso_target_path
        iso_urls             = additional_iso_file.iso_urls == null ? null : additional_iso_file.iso_urls
        keep_cdrom_device    = coalesce(additional_iso_file.keep_cdrom_device, false)
        type                 = coalesce(additional_iso_file.type, "scsi")
        unmount              = coalesce(additional_iso_file.unmount, true)
      }
    ]
  )

  boot_iso = {
    cd_label         = coalesce(var.boot_iso.cd_label, "BOOTISO")
    iso_checksum     = var.boot_iso.iso_checksum
    iso_file         = var.boot_iso.iso_file == null ? null : var.boot_iso.iso_file
    iso_urls         = var.boot_iso.iso_urls == null ? null : var.boot_iso.iso_urls
    index            = coalesce(var.boot_iso.index, 10)
    iso_download_pve = coalesce(var.boot_iso.iso_download_pve, false)
    iso_storage_pool = coalesce(
      var.boot_iso.iso_storage_pool,
      local.disks[0].storage_pool
    )
    iso_target_extension = coalesce(var.boot_iso.iso_target_extension, "iso")
    iso_target_path      = var.boot_iso.iso_target_path == null ? null : var.boot_iso.iso_target_path
    keep_cdrom_device    = coalesce(var.boot_iso.keep_cdrom_device, false)
    type                 = coalesce(var.boot_iso.type, "scsi")
    unmount              = coalesce(var.boot_iso.unmount, true)
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
      storage_pool        = coalesce(disk.storage_pool, "nvme-pool")
      type                = coalesce(disk.type, "scsi")
    }
  ]

  efi_config = var.packer_image.bios == "seabios" ? null : (
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
      ipv4_address = network_adapter.ipv4_address == null ? null : network_adapter.ipv4_address
      ipv4_netmask = network_adapter.ipv4_netmask == null ? null : network_adapter.ipv4_netmask
      ipv4_gateway = network_adapter.ipv4_gateway == null ? null : network_adapter.ipv4_gateway
      dns          = network_adapter.dns == null ? null : network_adapter.dns
      bridge       = network_adapter.bridge
      firewall     = coalesce(network_adapter.firewall, true)
      mac_address  = network_adapter.mac_address == null ? null : network_adapter.mac_address
      model        = coalesce(network_adapter.model, "virtio")
      mtu          = coalesce(network_adapter.mtu, 1492)
      packet_queues = coalesce(
        network_adapter.packet_queues,
        local.packer_image.cores
      )
      vlan_tag = coalesce(network_adapter.vlan_tag, 666)
    }
  ]

  pci_devices = [
    for pci_device in var.pci_devices : {
      host          = pci_device.host
      mapping       = pci_device.mapping
      device_id     = pci_device.device_id == null ? null : pci_device.device_id
      hide_rombar   = coalesce(pci_device.hide_rombar, false)
      legacy_igd    = coalesce(pci_device.legacy_igd, false)
      mdev          = pci_device.mdev == null ? null : pci_device.mdev
      pcie          = pci_device.pcie == null ? null : pci_device.pcie
      romfile       = pci_device.romfile == null ? null : pci_device.romfile
      sub_device_id = pci_device.sub_device_id == null ? null : pci_device.sub_device_id
      sub_vendor_id = pci_device.sub_vendor_id == null ? null : pci_device.sub_vendor_id
      vendor_id     = pci_device.vendor_id == null ? null : pci_device.vendor_id
      x_vga         = coalesce(pci_device.x_vga, false)
    }
  ]

  rng0 = var.rng0 == null ? null : {
    source    = coalesce(var.rng0.source, "/dev/urandom")
    max_bytes = coalesce(var.rng0.max_bytes, 1024)
    period    = coalesce(var.rng0.period, 1000)
  }

  tpm_config = var.packer_image.bios == "seabios" ? null : (
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
    memory = var.vga.memory == null ? null : var.vga.memory
  }

}
