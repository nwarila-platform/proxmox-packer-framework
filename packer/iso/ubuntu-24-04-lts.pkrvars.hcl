# ============================================================================================= #
# Ubuntu Server 24.04 LTS — ISO sources                                                        #
#                                                                                               #
# ISO lifecycle is managed by Terraform (terraform/). This file references ISOs by their        #
# Proxmox storage path. Checksums are verified at download time by Terraform; Packer verifies   #
# again at build time.                                                                          #
# ============================================================================================= #

boot_iso = {
  iso_checksum         = "sha256:d6fea1f11b4d23b481a48f34985f150d7d20ee0a7246b30f2e3bbfe6541ea4f0"
  iso_file             = "cephFS:iso/ubuntu-24.04.2-live-server-amd64.iso"
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
