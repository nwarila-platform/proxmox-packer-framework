#cloud-config
autoinstall:
  version: 1
  locale: ${os_language}.UTF-8
  keyboard:
    layout: ${os_keyboard}
  timezone: ${os_timezone}
  identity:
    hostname: ubuntu-24-04-template
    username: ${deploy_user_name}
    password: ${deploy_user_password}
  ssh:
    allow-pw: true
    install-server: true
    authorized-keys:
      - ${deploy_user_public_key}
  storage:
    layout:
      name: direct
  packages: []
  late-commands:
    - curtin in-target -- apt-get update
    - curtin in-target -- apt-get install -y qemu-guest-agent
    - curtin in-target -- systemctl enable qemu-guest-agent
