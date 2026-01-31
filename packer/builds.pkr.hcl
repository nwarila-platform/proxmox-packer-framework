# ============================================================================================= #
# - File: .\builds.pkr.hcl                                                    | Version: v1.0.0 #
# --- [ Description ] ------------------------------------------------------------------------- #
#                                                                                               #
# ============================================================================================= #


# Build Definition to create the VM Template
build {

  sources = ["source.proxmox-iso.packer_image"]

  provisioner "ansible" {
    user                   = "${var.deploy_user_name}"
    galaxy_file            = "${path.root}/ansible/linux-requirements.yml"
    galaxy_force_with_deps = true
    playbook_file          = "${path.root}/ansible/linux-playbook.yml"
    roles_path             = "${path.root}/ansible/roles"
    ansible_env_vars = [
      "ANSIBLE_CONFIG=${path.root}/ansible/ansible.cfg"
    ]
    extra_arguments = [
      # Declare Connection Settings
      "--extra-vars", "ansible_user=${var.deploy_user_name}",
      "--extra-vars", "ansible_become_pass=${var.deploy_user_password}",

      # Provide Variables Needed In Playbook
      "--extra-vars", "deploy_user_key='${var.deploy_user_key}'",
      "--extra-vars", "enable_cloudinit='${var.packer_image.cloud_init}'"
    ]
  }

  post-processor "manifest" {
    output = join(
      "",
      [path.root, "/manifests/", formatdate("YYYY-MM-DD_HH-mm-ss", timestamp()), ".json"]
    )
    strip_path = true
    strip_time = true
    custom_data = {
      build_username = "${var.deploy_user_name}"
      build_date     = formatdate("DD-MM-YYYY hh:mm ZZZ", "${timestamp()}")
      build_version  = "${data.git-repository.cwd.head}"
      cpu_sockets    = "${local.packer_image.sockets}"
      cpu_cores      = "${local.packer_image.cores}"
      bios           = "${local.packer_image.bios}"
      os_type        = "${local.packer_image.os}"
      mem_size       = "${local.packer_image.memory}"
      cloud_init     = "${local.packer_image.cloud_init}"
    }
  }
}
