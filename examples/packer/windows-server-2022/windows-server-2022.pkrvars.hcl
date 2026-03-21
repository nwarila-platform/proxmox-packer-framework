# ============================================================================================= #
# Windows Server 2022 Datacenter — UEFI, VirtIO, WinRM communicator                            #
#                                                                                               #
# NOTE: vm_id 9001 is a placeholder. Proxmox VMIDs are unique cluster-wide; downstream repos   #
# must allocate IDs appropriate for their environment. Use -force to replace an existing        #
# template with the same vm_id.                                                                 #
#                                                                                               #
# SECURITY NOTE: This example demonstrates a bootstrap-only WinRM profile for isolated build    #
# networks. Consumers should prefer HTTPS on port 5986 with certificate validation and NTLM     #
# or stronger authentication where the environment supports it.                                 #
# ============================================================================================= #

# --- Install Template ------------------------------------------------------------------------ #
install_template = {
  template_path    = "../examples/packer/windows-server-2022/autounattend.pkrtpl.hcl"
  output_file      = "/autounattend.xml"
  cd_label         = "OEMDRV"
  cd_type          = "sata"
  iso_storage_pool = "cephFS"
  extra_cd_content = {}
}

# --- Ansible Configuration ------------------------------------------------------------------- #
# Consumer repos import their own Ansible roles/playbooks, typically from ansible-framework.
ansible_config = {
  playbook_path     = "../consumer-repo/ansible/playbooks/windows-server-2022.yml"
  requirements_path = null
  roles_path        = null
  config_path       = null
  extra_vars        = {}
}

# --- Packer Image ---------------------------------------------------------------------------- #
packer_image = {

  # Proxmox Settings
  # NOTE: insecure_skip_tls_verify = true is an EXCEPTION for environments with self-signed
  # certificates. Production environments should use verified TLS (set to false).
  insecure_skip_tls_verify = true

  # Connection Settings
  communicator                 = "winrm"
  ssh_timeout                  = null
  winrm_timeout                = "60m"
  winrm_port                   = 5985
  winrm_use_ssl                = false
  winrm_insecure               = true
  winrm_use_ntlm               = false
  winrm_transport              = "basic"
  winrm_server_cert_validation = "ignore"

  # Template Metadata
  os_language = "en-US"
  os_keyboard = "0409:00000409"
  os_timezone = "UTC"
  os_family   = "windows"
  os_name     = "windows-server"
  os_version  = "2022"

  # General Settings
  template_description = "Windows Server 2022 Template built with Packer"
  template_name        = "windows-server-2022-template"
  vm_id                = 9001
  pool                 = "tmpl-golden-pkr"
  node                 = "tcnhq-prxmx01"
  vm_name              = "windows-server-2022-template"
  tags                 = ["windows", "server", "template", "packer"]

  # QEMU Agent
  qemu_agent           = true
  qemu_additional_args = ""

  # Misc Settings
  disable_kvm  = false
  machine      = "q35"
  os           = "win11"
  task_timeout = "30m"

  # VM Configuration: Boot Settings
  bios                   = "ovmf"
  boot                   = "order=scsi0;sata0;net0;"
  boot_key_interval      = null
  boot_keygroup_interval = null
  boot_wait              = "5s"
  onboot                 = false
  boot_command = [
    "<spacebar><spacebar>"
  ]

  # VM Configuration: Cloud-Init (disabled for Windows)
  cloud_init              = false
  cloud_init_disk_type    = null
  cloud_init_storage_pool = null

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
  pre_enrolled_keys = true
}

network_adapters = [
  {
    ipv4_address  = "10.69.128.201"
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
