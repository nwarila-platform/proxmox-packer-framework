# ============================================================================================ #
# resources.tf — ISO file lifecycle management on Proxmox storage                               #
#                                                                                                 #
# Each entry in var.iso_files becomes a managed resource. Terraform downloads the ISO to the   #
# specified Proxmox node and datastore, verifies the checksum, and removes the file from       #
# Proxmox storage when the entry is deleted from configuration.                                 #
# ============================================================================================ #

resource "proxmox_virtual_environment_download_file" "iso_file" {
  for_each = local.iso_files

  node_name          = each.value["node_name"]
  datastore_id       = each.value["datastore_id"]
  content_type       = each.value["content_type"]
  url                = each.value["url"]
  checksum           = each.value["checksum"]
  checksum_algorithm = each.value["checksum_algorithm"]
  file_name          = each.value["file_name"]
  overwrite          = each.value["overwrite"]
  upload_timeout     = each.value["upload_timeout"]
  verify             = each.value["verify"]
}
