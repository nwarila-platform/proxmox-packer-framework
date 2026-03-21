# Proxmox Packer Framework

A data-driven [Packer](https://www.packer.io/) framework for building hardened Proxmox VE VM templates. The framework owns the Proxmox builder contract, normalization layer, and CI validation flow. Consumer repositories bring their own installer templates, Ansible content, and environment-specific values.

## Purpose

This repository is an organizational framework, not a turnkey image factory. Its job is to give downstream repositories a stable, reusable Proxmox/Packer contract so teams inherit:

- secure infrastructure defaults
- a shared input schema
- consistent validation and CI behavior
- a clean separation between framework logic and consumer content

The framework does not decide which packages, hardening profile, or application stack a guest OS should contain. Those decisions stay with the consumer repository.

## Ownership Model

| Layer | Owner | Default Source |
|-------|-------|----------------|
| Packer orchestration and variable contract | This framework | This repository |
| ISO lifecycle on Proxmox storage | This framework's `terraform/` helper or a future external media repo | `examples/terraform/` |
| OS installer templates | Consumer repo | Shipped installer examples in `examples/packer/` |
| Ansible roles, playbooks, Galaxy requirements | Consumer repo | [ansible-framework](https://github.com/NWarila/ansible-framework) |

This repository ships installer examples only. It does not ship Ansible roles, playbooks, inventories, or `ansible.cfg`; consumers import those from [ansible-framework](https://github.com/NWarila/ansible-framework) or an equivalent repository.

Today, the committed `packer/iso/*.pkrvars.hcl` files remain the bootstrap media source of truth. For the shipped Rocky, Ubuntu, and Windows families, the framework can infer those bundled media defaults automatically from `packer_image.os_name` and `packer_image.os_version`. The `terraform/` helper can manage the same ISO lifecycle on Proxmox, but this repository does not yet auto-generate the Packer-side media contract from Terraform outputs. That handoff is intentionally deferred while a dedicated media-tracking repository is being prepared.

## Architecture

At a high level:

1. Consumer `.pkrvars.hcl` files provide environment-specific inputs.
2. `packer/locals.pkr.hcl` normalizes those inputs and assembles the install-template contract.
3. `packer/source.pkr.hcl` maps the normalized values into the Proxmox ISO builder.
4. `packer/builds.pkr.hcl` runs the consumer-provided installer template, then the consumer-provided Ansible playbook.

See [docs/architecture.md](docs/architecture.md) for design decisions and [docs/template-contract.md](docs/template-contract.md) for the template variable contract.

## Supported Operating Systems

| OS | Version | Install Method | Example | Status |
|----|---------|----------------|---------|--------|
| Rocky Linux | 9.x | Kickstart | [examples/packer/rocky-linux-9/](examples/packer/rocky-linux-9/) | Validated example |
| Ubuntu Server | 24.04 LTS | Autoinstall | [examples/packer/ubuntu-24-04/](examples/packer/ubuntu-24-04/) | Validated bootstrap example |
| Windows Server | 2022 | Autounattend | [examples/packer/windows-server-2022/](examples/packer/windows-server-2022/) | Validated bootstrap example |

The generic `install_template` contract supports any guest OS that can boot from a rendered template file on a virtual CD.

Bootstrap examples are validated in CI, but consumers are still expected to:

- replace shipped media values if their environment uses different ISO locations or checksums
- point `ansible_config.*` paths at consumer-owned Ansible content
- decide whether example TLS and WinRM settings are acceptable bootstrap exceptions for their environment

Supported bundled media defaults are inferred for:

- `rocky` + `9`
- `ubuntu` + `24.04`
- `windows-server` + `2022`

Consumers can still override those defaults explicitly with `media_profile`, `boot_iso`, or `additional_iso_files`.

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| [Terraform](https://developer.hashicorp.com/terraform) | 1.14.7 | Optional ISO lifecycle helper |
| [Packer](https://www.packer.io/) | 1.15.0 | Image builder |
| [Ansible](https://docs.ansible.com/) | Consumer-defined | Consumer-owned provisioning content |
| [Proxmox VE](https://www.proxmox.com/) | 8.x | Hypervisor target |
| [pre-commit](https://pre-commit.com/) | 4.0+ | Local hook runner |

## Proxmox API Token

Create a dedicated API token with the minimum permissions needed for Packer and, if used, the Terraform ISO helper. The example below uses `--privsep=0`, which disables token privilege separation. If your environment supports token-scoped ACLs, prefer a privilege-separated token with only the required permissions.

```bash
pveum role add PackerBuilder -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit ISO.Download Pool.Audit Pool.Allocate SDN.Use Sys.Modify"
pveum user add packer@pve
pveum aclmod / -user packer@pve -role PackerBuilder
pveum user token add packer@pve packer-token --privsep=0
```

## Quick Start

### 1. Clone and initialize

```bash
git clone https://github.com/NWarila/proxmox-packer-framework.git
cd proxmox-packer-framework

cd terraform
terraform init

cd ../packer
packer init .
```

### 2. Copy example inputs

```bash
# Packer example inputs
cp ../examples/packer/.env.example ./../.env.packer.example
cp ../examples/packer/rocky-linux-9/rocky-linux-9.pkrvars.hcl ./my-rocky.pkrvars.hcl

# Optional Terraform ISO helper inputs
cp ../examples/terraform/.env.example ../terraform/.env.terraform.example
cp ../examples/terraform/terraform.tfvars.example ../terraform/terraform.tfvars
```

The `.env.example` files are templates for values you should export into your shell or CI environment. They are not auto-loaded by Terraform or Packer.

### 3. Configure your environment

- export `PKR_VAR_*` values for Proxmox access and deploy-user credentials from the copied Packer env example
- export `TF_VAR_*` values if you are using the Terraform ISO helper
- edit `my-rocky.pkrvars.hcl` for network, storage, hardware, and installer settings
- point `install_template.template_path` and `ansible_config.*` paths at consumer-owned content

For the shipped Rocky, Ubuntu, and Windows families, you do not need a separate ISO var file just to validate or build. The framework will resolve the bundled media defaults automatically unless you override them.

The framework also accepts `PKR_VAR_proxmox_skip_tls_verify` and `PKR_VAR_proxmox_node` as top-level CI-friendly overrides for the matching nested `packer_image` fields.

If you want Terraform to manage ISO lifecycle today:

```bash
cd ../terraform
terraform plan
terraform apply
```

That helper uploads and tracks ISO media in Proxmox, but the checked-in bundled media catalog is still the active Packer-side default until the future external media repository is in place.

### 4. Validate and build

```bash
# Terraform helper validation
cd ../terraform
terraform fmt -check -recursive .
terraform validate

# Packer validation and build
cd ../packer
packer validate \
  -var-file="my-rocky.pkrvars.hcl" \
  .

packer build -force \
  -var-file="my-rocky.pkrvars.hcl" \
  .
```

`vm_id` values are unique cluster-wide in Proxmox. The shipped example IDs are placeholders only.

### 5. Install pre-commit hooks

```bash
pre-commit install
pre-commit install --hook-type commit-msg
```

## Project Structure

```text
proxmox-packer-framework/
|-- .config/
|-- .github/
|   |-- config/gitleaks.toml
|   |-- scripts/
|   |   |-- get_packer_version.sh
|   |   |-- validate_examples.sh
|   |   |-- validate_examples.ps1
|   |   |-- validate_terraform.sh
|   |   `-- validate_terraform.ps1
|   `-- workflows/
|-- .vscode/
|-- docs/
|   |-- architecture.md
|   |-- template-contract.md
|   `-- REQUIREMENTS.md
|-- examples/
|   |-- packer/
|   |   |-- .env.example
|   |   |-- rocky-linux-9/
|   |   |-- ubuntu-24-04/
|   |   `-- windows-server-2022/
|   `-- terraform/
|       |-- .env.example
|       `-- terraform.tfvars.example
|-- packer/
|   |-- iso/
|   |-- builds.pkr.hcl
|   |-- data.pkr.hcl
|   |-- locals.pkr.hcl
|   |-- packer.pkr.hcl
|   |-- source.pkr.hcl
|   `-- variables.pkr.hcl
|-- terraform/
|   |-- .terraform.lock.hcl
|   |-- data.tf
|   |-- locals.tf
|   |-- outputs.tf
|   |-- providers.tf
|   |-- resources.tf
|   |-- variables.tf
|   `-- versions.tf
|-- .editorconfig
|-- .gitattributes
|-- .pre-commit.config.yaml
|-- .release-please-manifest.json
|-- release-please-config.json
|-- CHANGELOG.md
|-- CODE_OF_CONDUCT.md
|-- CONTRIBUTING.md
|-- LICENSE
|-- SECURITY.md
`-- SUPPORT.md
```

## CI/CD Pipeline

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| Feature Push Gate | Push to any branch except `DEV`, `TEST`, `PROD` | Gitleaks secret scan |
| DEV Promotion Gate | Push to `DEV` for `packer/**`, `terraform/**`, `examples/**`, `.github/scripts/**` | Gitleaks, Terraform fmt/validate, Packer fmt/validate |
| PR Validation | PR to `main` for `packer/**`, `terraform/**`, `examples/**`, `.github/scripts/**` | Gitleaks, Terraform fmt/validate, Packer fmt/validate |
| Security Scanning | Push/PR to `main`, weekly schedule | Trivy filesystem scan plus Gitleaks |
| Release Please | Push to `main` | Automated changelog generation and GitHub releases |

## Downstream Integration

This framework produces Proxmox VM templates designed to be consumed by Terraform or OpenTofu. A downstream repo can check out its own consumer content next to this framework, place its `.auto.pkrvars.hcl` file in the framework `packer/` working directory, and run `packer validate .` / `packer build .` directly as long as it supplies:

- `install_template` pointing at consumer-owned installer templates
- `ansible_config` pointing at consumer-owned Ansible content, with `ansible-playbook` available on PATH in the runtime environment
- `packer_image.os_name` and `packer_image.os_version` matching a bundled media family, or explicit media overrides

The build timestamp in `template_description` can be used to trigger downstream VM replacement when a new template is published.

```hcl
resource "terraform_data" "template_version" {
  input = data.proxmox_virtual_environment_vm.template.description
}

resource "proxmox_virtual_environment_vm" "vm" {
  lifecycle {
    replace_triggered_by = [terraform_data.template_version]
  }
}
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines. This project uses [Conventional Commits](https://www.conventionalcommits.org/) and enforces them with pre-commit hooks.

## License

This project is licensed under the [MIT License](LICENSE).
