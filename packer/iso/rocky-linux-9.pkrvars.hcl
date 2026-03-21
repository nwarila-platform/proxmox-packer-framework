# ============================================================================================= #
# Rocky Linux 9 — ISO sources                                                                  #
#                                                                                               #
# ISO lifecycle is managed by Terraform (terraform/). This file references ISOs by their        #
# Proxmox storage path. Checksums are verified at download time by Terraform; Packer verifies   #
# again at build time.                                                                          #
# ============================================================================================= #

boot_iso = {
  iso_checksum         = "sha256:8ff2a47e2f3bfe442617fceb7ef289b7b1d2d0502089dbbd505d5368b2b3a90f"
  iso_file             = "cephFS:iso/Rocky-9.6-x86_64-dvd.iso"
  iso_urls             = null
  iso_download_pve     = null
  iso_storage_pool     = null
  cd_label             = null
  index                = 0
  iso_target_extension = null
  iso_target_path      = null
  keep_cdrom_device    = false
  type                 = "scsi"
  unmount              = true
}

additional_iso_files = []
