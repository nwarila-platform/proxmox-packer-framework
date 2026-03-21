# ============================================================================================ #
# versions.tf — Terraform and provider version constraints                                      #
# ============================================================================================ #

terraform {

  # Specify the required Terraform version
  required_version = "1.14.7"

  # Specify the required providers
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.98.1"
    }
  }

}
