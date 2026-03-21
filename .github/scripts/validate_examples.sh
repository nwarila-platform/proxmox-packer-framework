#!/usr/bin/env bash
set -euo pipefail

repo_root="$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null 2>&1
  pwd -P
)"

packer_dir="$repo_root/packer"
tmp_dir="$(mktemp -d)"

cleanup() {
  rm -rf "$tmp_dir"
}

trap cleanup EXIT

stub_playbook="$tmp_dir/validation-playbook.yml"
stub_ansible_playbook="$tmp_dir/ansible-playbook"

# Validation should cover the example surfaces without reintroducing repo-owned
# Ansible content as part of the supported runtime contract.
cat > "$stub_playbook" <<'YAML'
---
- name: Validation-only Ansible stub
  hosts: all
  gather_facts: false
  tasks:
    - name: Emit validation marker
      ansible.builtin.debug:
        msg: validation-only stub
YAML

cat > "$stub_ansible_playbook" <<'SH'
#!/usr/bin/env sh
if [ "$1" = "--version" ]; then
  echo "ansible-playbook [core 2.18.0]"
  exit 0
fi
exit 0
SH

chmod +x "$stub_ansible_playbook"
export PATH="$tmp_dir:$PATH"

create_override_file() {
  local override_file="$1"

  cat > "$override_file" <<EOF
proxmox_hostname         = "proxmox.invalid"
proxmox_api_token_id     = "packer@pam!validation"
proxmox_api_token_secret = "validation-secret"
deploy_user_name         = "packer"
deploy_user_password     = "ChangeMe123!"
deploy_user_key          = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMockValidationKeyOnly build-validation@example"

ansible_config = {
  playbook_path     = "${stub_playbook}"
  requirements_path = null
  roles_path        = null
  config_path       = null
  extra_vars        = {}
}
EOF
}

validate_example() {
  local example_name="$1"
  local example_file="$2"
  local override_file="$tmp_dir/${example_name}.pkrvars.hcl"

  create_override_file "$override_file"

  echo "Validating ${example_name}..."
  packer validate \
    -var-file="$example_file" \
    -var-file="$override_file" \
    .
}

cd "$packer_dir"
packer init .

validate_example \
  "rocky-linux-9" \
  "$repo_root/examples/packer/rocky-linux-9/rocky-linux-9.pkrvars.hcl"
validate_example \
  "ubuntu-24-04-lts" \
  "$repo_root/examples/packer/ubuntu-24-04/ubuntu-24-04-lts.pkrvars.hcl"
validate_example \
  "windows-server-2022" \
  "$repo_root/examples/packer/windows-server-2022/windows-server-2022.pkrvars.hcl"
