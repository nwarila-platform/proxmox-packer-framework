# ============================================================================================= #
# Windows Server 2022 — ISO sources                                                             #
#                                                                                               #
# ISO lifecycle is managed by Terraform (terraform/). This file references ISOs by their        #
# Proxmox storage path. Checksums are verified at download time by Terraform; Packer verifies   #
# again at build time.                                                                          #
# ============================================================================================= #

boot_iso = {
  iso_checksum         = "sha256:3e4fa6d8507b554856fc9ca6079cc402df11a8b79344871669f0251535255325"
  iso_file             = "cephFS:iso/SERVER_EVAL_x64FRE_en-us.iso"
  iso_urls             = null
  iso_download_pve     = null
  iso_storage_pool     = null
  cd_label             = null
  index                = 0
  iso_target_extension = null
  iso_target_path      = null
  keep_cdrom_device    = false
  type                 = "sata"
  unmount              = true
}

additional_iso_files = [
  {
    iso_checksum         = "sha256:ebd48258668f7f78e026ed276c28a9d19d83e020a36b24730bfba1a93eed3a35"
    iso_file             = "cephFS:iso/virtio-win-0.1.262.iso"
    iso_urls             = null
    iso_download_pve     = null
    iso_storage_pool     = null
    cd_content           = null
    cd_files             = null
    cd_label             = null
    index                = 2
    iso_target_extension = null
    iso_target_path      = null
    keep_cdrom_device    = false
    type                 = "sata"
    unmount              = true
  }
]
