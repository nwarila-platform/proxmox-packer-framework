# ============================================================================================ #
# outputs.tf — ISO file paths for Packer consumption                                            #
#                                                                                                 #
# Outputs the Proxmox storage paths (e.g. "cephFS:iso/Rocky-9.6-x86_64-dvd.iso") that Packer   #
# references via iso_file in boot_iso and additional_iso_files variable files.                  #
# ============================================================================================ #

output "iso_file_paths" {
  description = "Map of ISO logical names to their Proxmox storage paths (datastore:content_type/filename)."
  value = {
    for key, iso_file in proxmox_virtual_environment_download_file.iso_file : key => "${iso_file.datastore_id}:${iso_file.content_type}/${iso_file.file_name}"
  }
}
