# ============================================================================================= #
# Rocky Linux 9 — UEFI, VirtIO, SSH communicator, DISA STIG Kickstart                         #
#                                                                                               #
# NOTE: vm_id 9000 is a placeholder. Proxmox VMIDs are unique cluster-wide; downstream repos   #
# must allocate IDs appropriate for their environment. Use -force to replace an existing         #
# template with the same vm_id.                                                                 #
# ============================================================================================= #

# --- Install Template -------------------------------------------------------------------- #
# Points to the Kickstart template shipped with this example. Consumer repos should provide
# their own template path. The template receives the guaranteed template variable contract
# (see docs/template-contract.md).
install_template = {
  template_path    = "../examples/packer/rocky-linux-9/ks.pkrtpl.hcl"
  output_file      = "/ks.cfg"
  cd_label         = "OEMDRV"
  cd_type          = "scsi"
  iso_storage_pool = "cephFS"
  extra_cd_content = {}
}

# --- Ansible Configuration --------------------------------------------------------------- #
# Consumer repos import their own Ansible roles/playbooks, typically from ansible-framework.
# Update these paths to point to your consumer repo's Ansible content.
ansible_config = {
  playbook_path     = "../consumer-repo/ansible/playbooks/rocky-linux-9.yml"
  requirements_path = null
  roles_path        = null
  config_path       = null
  extra_vars = {
    enable_cloudinit = "true"
  }
}

# --- Packer Image ------------------------------------------------------------------------ #
packer_image = {

  # Proxmox Settings
  # NOTE: insecure_skip_tls_verify = true is an EXCEPTION for environments with self-signed
  # certificates. Production environments should use verified TLS (set to false).
  insecure_skip_tls_verify = true

  # Connection Settings
  communicator                 = "ssh"
  ssh_timeout                  = "30m"
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
  os_name     = "rocky"
  os_version  = "9"

  # General Settings
  template_description = "Rocky Linux 9 Template built with Packer"
  template_name        = "rocky-linux-9-template"
  vm_id                = 9000
  pool                 = "tmpl-golden-pkr"
  node                 = "tcnhq-prxmx01"
  vm_name              = "rocky-linux-9-template"
  tags                 = ["rocky", "linux", "template", "packer"]

  # QEMU Agent
  qemu_agent           = true
  qemu_additional_args = ""

  # Misc Settings
  disable_kvm  = false
  machine      = "q35"
  os           = "l26"
  task_timeout = "10m"

  # VM Configuration: Boot Settings
  bios                   = "ovmf"
  boot                   = "order=scsi2;scsi0;scsi1;"
  boot_key_interval      = null
  boot_keygroup_interval = null
  boot_wait              = "10s"
  onboot                 = false
  boot_command = [
    "<up>",
    "e",
    "<down><down><end><wait>",
    " inst.text inst.ks=hd:LABEL=OEMDRV:/ks.cfg",
    "<leftCtrlOn>x<leftCtrlOff>"
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
    ipv4_address  = "10.69.128.200"
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

#region ------ [ Disks & Partitions ] --------------------------------------------------------- #

vm_disk_use_swap = true
vm_disk_partitions = [
  {
    name = "efi"
    size = 1024,
    format = {
      label  = "EFIFS",
      fstype = "fat32",
    },
    mount = {
      path    = "/boot/efi",
      options = "",
    },
    volume_group = "",
  },
  {
    name = "boot"
    size = 1024,
    format = {
      label  = "BOOTFS",
      fstype = "ext4",
    },
    mount = {
      path    = "/boot",
      options = "",
    },
    volume_group = "",
  },
  {
    name = "sysvg"
    size = -1,
    format = {
      label  = "",
      fstype = "",
    },
    mount = {
      path    = "",
      options = "",
    },
    volume_group = "sysvg",
  },
]
vm_disk_lvm = [
  {
    name : "sysvg",
    partitions : [
      {
        name = "lv_swap",
        size = 1024,
        format = {
          label  = "SWAPFS",
          fstype = "swap",
        },
        mount = {
          path    = "",
          options = "",
        },
      },
      {
        name = "lv_root",
        size = 10240,
        format = {
          label  = "ROOTFS",
          fstype = "ext4",
        },
        mount = {
          path    = "/",
          options = "",
        },
      },
      {
        name = "lv_home",
        size = 4096,
        format = {
          label  = "HOMEFS",
          fstype = "ext4",
        },
        mount = {
          path    = "/home",
          options = "nodev,nosuid",
        },
      },
      {
        name = "lv_opt",
        size = 2048,
        format = {
          label  = "OPTFS",
          fstype = "ext4",
        },
        mount = {
          path    = "/opt",
          options = "nodev",
        },
      },
      {
        name = "lv_tmp",
        size = 4096,
        format = {
          label  = "TMPFS",
          fstype = "ext4",
        },
        mount = {
          path    = "/tmp",
          options = "nodev,noexec,nosuid",
        },
      },
      {
        name = "lv_var",
        size = 2048,
        format = {
          label  = "VARFS",
          fstype = "ext4",
        },
        mount = {
          path    = "/var",
          options = "nodev",
        },
      },
      {
        name = "lv_var_tmp",
        size = 1000,
        format = {
          label  = "VARTMPFS",
          fstype = "ext4",
        },
        mount = {
          path    = "/var/tmp",
          options = "nodev,noexec,nosuid",
        },
      },
      {
        name = "lv_var_log",
        size = 4096,
        format = {
          label  = "VARLOGFS",
          fstype = "ext4",
        },
        mount = {
          path    = "/var/log",
          options = "nodev,noexec,nosuid",
        },
      },
      {
        name = "lv_var_audit",
        size = 500,
        format = {
          label  = "AUDITFS",
          fstype = "ext4",
        },
        mount = {
          path    = "/var/log/audit",
          options = "nodev,noexec,nosuid",
        },
      },
    ],
  }
]

#endregion --- [ Disks & Partitions ] --------------------------------------------------------- #
