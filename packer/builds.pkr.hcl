# ============================================================================================= #
# builds.pkr.hcl - Build definition with consumer-provided Ansible provisioner                  #
# ============================================================================================= #

build {

  sources = ["source.proxmox-iso.packer_image"]

  # Ansible Provisioner (SSH communicator - Linux)
  # Consumer builds are expected to provide a real playbook path and an
  # ansible-playbook executable on PATH. The repository validation helpers
  # inject a temporary stub so framework syntax checks can run without bundling
  # consumer Ansible content.
  provisioner "ansible" {
    only                   = (local.packer_image.communicator == "ssh" && var.ansible_config.playbook_path != null) ? ["proxmox-iso.packer_image"] : []
    user                   = var.deploy_user_name
    galaxy_file            = var.ansible_config.requirements_path
    galaxy_force_with_deps = var.ansible_config.requirements_path != null ? true : null
    playbook_file          = var.ansible_config.playbook_path
    roles_path             = var.ansible_config.roles_path
    ansible_env_vars = var.ansible_config.config_path != null ? [
      "ANSIBLE_CONFIG=${var.ansible_config.config_path}"
    ] : []
    extra_arguments = concat(
      [
        "--extra-vars", "ansible_user=${var.deploy_user_name}",
        "--extra-vars", "ansible_become_pass=${var.deploy_user_password}",
        "--extra-vars", "ansible_ssh_pass=${var.deploy_user_password}"
      ],
      flatten([for k, v in var.ansible_config.extra_vars : ["--extra-vars", "${k}=${v}"]])
    )
  }

  # Ansible Provisioner (WinRM communicator - Windows)
  # Consumer builds are expected to provide a real playbook path and an
  # ansible-playbook executable on PATH. The repository validation helpers
  # inject a temporary stub so framework syntax checks can run without bundling
  # consumer Ansible content.
  provisioner "ansible" {
    only                   = (local.packer_image.communicator == "winrm" && var.ansible_config.playbook_path != null) ? ["proxmox-iso.packer_image"] : []
    user                   = var.deploy_user_name
    use_proxy              = false
    galaxy_file            = var.ansible_config.requirements_path
    galaxy_force_with_deps = var.ansible_config.requirements_path != null ? true : null
    playbook_file          = var.ansible_config.playbook_path
    roles_path             = var.ansible_config.roles_path
    ansible_env_vars = var.ansible_config.config_path != null ? [
      "ANSIBLE_CONFIG=${var.ansible_config.config_path}"
    ] : []
    extra_arguments = concat(
      [
        "--extra-vars", "ansible_user=${var.deploy_user_name}",
        "--extra-vars", "ansible_password=${var.deploy_user_password}",
        "--extra-vars", "ansible_connection=winrm",
        "--extra-vars", "ansible_port=${local.packer_image.winrm_port}",
        "--extra-vars", "ansible_winrm_scheme=${local.packer_image.winrm_use_ssl ? "https" : "http"}",
        "--extra-vars", "ansible_winrm_transport=${local.packer_image.winrm_transport}",
        "--extra-vars", "ansible_winrm_server_cert_validation=${local.packer_image.winrm_server_cert_validation}"
      ],
      flatten([for k, v in var.ansible_config.extra_vars : ["--extra-vars", "${k}=${v}"]])
    )
  }

  post-processor "manifest" {
    output = join("", [
      path.root, "/manifests/",
      formatdate("YYYY-MM-DD_HH-mm-ss", timestamp()), ".json"
    ])
    strip_path = true
    strip_time = true
    custom_data = {
      build_username = var.deploy_user_name
      build_date     = timestamp()
      build_version  = data.git-repository.cwd.head
      cpu_sockets    = local.packer_image.sockets
      cpu_cores      = local.packer_image.cores
      bios           = local.packer_image.bios
      os_type        = local.packer_image.os
      mem_size       = local.packer_image.memory
      cloud_init     = local.packer_image.cloud_init
    }
  }
}
