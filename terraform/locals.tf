# ============================================================================================= #
# locals.tf — Variable normalization for ISO file management                                    #
#                                                                                                 #
# Mirrors the Packer framework pattern: consumer inputs are normalized with sensible defaults   #
# via coalesce(), then consumed by resources.                                                   #
# ============================================================================================= #

locals {

  #region ------ [ ISO File Normalization ] ---------------------------------------------------- #

  iso_files = {
    for iso_file in var.iso_files : iso_file.name => {
      name               = iso_file.name
      node_name          = iso_file.node_name
      datastore_id       = coalesce(iso_file.datastore_id, "local")
      content_type       = coalesce(iso_file.content_type, "iso")
      url                = iso_file.url
      checksum           = iso_file.checksum
      checksum_algorithm = coalesce(iso_file.checksum_algorithm, "sha256")
      file_name          = iso_file.file_name
      overwrite          = coalesce(iso_file.overwrite, false)
      upload_timeout     = coalesce(iso_file.upload_timeout, 600)
      verify             = coalesce(iso_file.verify, true)
    }
  }

  #endregion --- [ ISO File Normalization ] ---------------------------------------------------- #

}
