# ============================================================================================= #
# Ubuntu Server 24.04 LTS — UEFI, VirtIO, SSH communicator, cloud-init autoinstall             #
#                                                                                               #
# NOTE: vm_id 9002 is a placeholder. Proxmox VMIDs are unique cluster-wide; downstream repos   #
# must allocate IDs appropriate for their environment. Use -force to replace an existing        #
# template with the same vm_id.                                                                 #
# ============================================================================================= #

# --- Install Template ------------------------------------------------------------------------ #
install_template = {
  template_path    = "../examples/packer/ubuntu-24-04/user-data.pkrtpl.hcl"
  output_file      = "/user-data"
  cd_label         = "cidata"
  cd_type          = "scsi"
  iso_storage_pool = "cephFS"
  extra_cd_content = {
    "/meta-data" = <<-EOT
      instance-id: ubuntu-24-04-template
      local-hostname: ubuntu-24-04-template
    EOT
  }
}

# --- Ansible Configuration ------------------------------------------------------------------- #
# Consumer repos import their own Ansible roles/playbooks, typically from ansible-framework.
ansible_config = {
  playbook_path     = "../consumer-repo/ansible/playbooks/ubuntu-24-04.yml"
  requirements_path = null
  roles_path        = null
  config_path       = null
  extra_vars = {
    enable_cloudinit = "true"
  }
}

# --- Packer Image ---------------------------------------------------------------------------- #
packer_image = {

  # Proxmox Settings
  # NOTE: insecure_skip_tls_verify = true is an EXCEPTION for environments with self-signed
  # certificates. Production environments should use verified TLS (set to false).
  insecure_skip_tls_verify = true

  # Connection Settings
  communicator                 = "ssh"
  ssh_timeout                  = "45m"
  winrm_timeout                = null
  winrm_port                   = null
  winrm_use_ssl                = null
  winrm_insecure               = null
  winrm_use_ntlm               = null
  winrm_transport              = null
  winrm_server_cert_validation = null

  # Template Metadata
  os_language = "en_US"
  os_keyboard = "us"
  os_timezone = "UTC"
  os_family   = "linux"
  os_name     = "ubuntu"
  os_version  = "24.04"

  # General Settings
  template_description = "Ubuntu Server 24.04 LTS Template built with Packer"
  template_name        = "ubuntu-24-04-template"
  vm_id                = 9002
  pool                 = "tmpl-golden-pkr"
  node                 = "tcnhq-prxmx01"
  vm_name              = "ubuntu-24-04-template"
  tags                 = ["ubuntu", "linux", "template", "packer"]

  # QEMU Agent
  qemu_agent           = true
  qemu_additional_args = ""

  # Misc Settings
  disable_kvm  = false
  machine      = "q35"
  os           = "l26"
  task_timeout = "20m"

  # VM Configuration: Boot Settings
  bios                   = "ovmf"
  boot                   = "order=scsi2;scsi0;scsi1;"
  boot_key_interval      = null
  boot_keygroup_interval = null
  boot_wait              = "5s"
  onboot                 = false
  boot_command = [
    "c",
    "linux /casper/vmlinuz autoinstall ds=nocloud\\;s=/cidata/ ---",
    "<enter>",
    "initrd /casper/initrd",
    "<enter>",
    "boot",
    "<enter>"
  ]

  # VM Configuration: Cloud-Init
  cloud_init              = true
  cloud_init_disk_type    = "scsi"
  cloud_init_storage_pool = "nvme-pool"

  # Hardware: CPU
  cores    = 2
  cpu_type = "host"
  sockets  = 1

  # Hardware: Memory
  ballooning_minimum = 0
  memory             = 4096
  numa               = false

  # Hardware: Misc
  scsi_controller = "virtio-scsi-single"
  serials         = []
  vm_interface    = null

}

disks = [
  {
    asyncio             = "io_uring"
    cache_mode          = "none"
    discard             = false
    exclude_from_backup = false
    format              = "raw"
    io_thread           = false
    size                = "100G"
    ssd                 = true
    storage_pool        = "nvme-pool"
    type                = "scsi"
  }
]

efi_config = {
  efi_format        = "raw"
  efi_storage_pool  = "nvme-pool"
  efi_type          = "4m"
  pre_enrolled_keys = false
}

network_adapters = [
  {
    ipv4_address  = "10.69.128.202"
    ipv4_netmask  = 24
    ipv4_gateway  = "10.69.128.1"
    dns           = ["10.69.128.1"]
    bridge        = "vmbr0"
    firewall      = false
    mac_address   = null
    model         = "virtio"
    mtu           = 1492
    packet_queues = 1
    vlan_tag      = 228
  }
]

pci_devices = []

rng0 = {
  source    = "/dev/urandom"
  max_bytes = 1024
  period    = 1000
}

tpm_config = {
  tpm_storage_pool = "nvme-pool"
  tpm_version      = "v2.0"
}

vga = {
  type   = "virtio"
  memory = null
}

# Autoinstall example keeps storage simple and lets Ubuntu use the full disk.
vm_disk_use_swap   = true
vm_disk_partitions = []
vm_disk_lvm        = []
