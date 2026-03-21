# ============================================================================================ #
# providers.tf — Provider configuration                                                          #
# ============================================================================================ #

provider "proxmox" {
  endpoint  = "https://${var.proxmox_hostname}:8006/api2/json"
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure  = var.proxmox_skip_tls_verify
}
