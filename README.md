# Proxmox Packer Framework

[![CI](https://github.com/nwarila-platform/proxmox-packer-framework/actions/workflows/main-validation.yml/badge.svg)](https://github.com/nwarila-platform/proxmox-packer-framework/actions/workflows/main-validation.yml)
[![Security](https://github.com/nwarila-platform/proxmox-packer-framework/actions/workflows/security.yaml/badge.svg)](https://github.com/nwarila-platform/proxmox-packer-framework/actions/workflows/security.yaml)
[![Release](https://img.shields.io/github/v/release/nwarila-platform/proxmox-packer-framework)](https://github.com/nwarila-platform/proxmox-packer-framework/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

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
| ISO download and SHA verification on Proxmox storage | [terraform-proxmox-iso-manager-framework](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework) | Runner repo's Terraform |
| OS installer templates | Consumer repo | Shipped installer examples in `examples/packer/` |
| Ansible roles, playbooks, Galaxy requirements | Consumer repo | [ansible-framework](https://github.com/nwarila-platform/ansible-framework) |

This repository ships installer examples only. It does not ship Ansible roles, playbooks, inventories, or `ansible.cfg`; consumers import those from [ansible-framework](https://github.com/nwarila-platform/ansible-framework) or an equivalent repository.

ISO lifecycle is owned externally. Runner repos invoke `terraform-proxmox-iso-manager-framework` to download and SHA-verify the boot ISO onto Proxmox storage, then emit a `boot_iso` pkrvars file consumed by this framework's reusable workflow via its `var_file` input. See [docs/explanation/architecture.md](docs/explanation/architecture.md#iso-lifecycle-boundary).

## Architecture

At a high level:

1. Consumer `.pkrvars.hcl` files provide environment-specific inputs.
2. `packer/locals.pkr.hcl` normalizes those inputs and assembles the install-template contract.
3. `packer/source.pkr.hcl` maps the normalized values into the Proxmox ISO builder.
4. `packer/builds.pkr.hcl` runs the consumer-provided installer template, then the consumer-provided Ansible playbook.

See [docs/explanation/architecture.md](docs/explanation/architecture.md) for design decisions and [docs/reference/template-contract.md](docs/reference/template-contract.md) for the template variable contract.

## Supported Operating Systems

| OS | Version | Install Method | Example | Status |
|----|---------|----------------|---------|--------|
| Rocky Linux | 9.x | Kickstart | [examples/packer/rocky-linux-9/](examples/packer/rocky-linux-9/) | Validated example |
| Ubuntu Server | 24.04 LTS | Autoinstall | [examples/packer/ubuntu-24-04/](examples/packer/ubuntu-24-04/) | Validated bootstrap example |
| Windows Server | 2022 | Autounattend | [examples/packer/windows-server-2022/](examples/packer/windows-server-2022/) | Validated bootstrap example |

The generic `install_template` contract supports any guest OS that can boot from a rendered template file on a virtual CD.

Bootstrap examples are validated in CI, but consumers are still expected to:

- supply `boot_iso` (and any `additional_iso_files`) from their runner-repo Terraform that calls `terraform-proxmox-iso-manager-framework`
- point `ansible_config.*` paths at consumer-owned Ansible content
- decide whether example TLS and WinRM settings are acceptable bootstrap exceptions for their environment

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| [Packer](https://www.packer.io/) | 1.15.0 | Image builder |
| [Ansible](https://docs.ansible.com/) | Consumer-defined | Consumer-owned provisioning content |
| [Proxmox VE](https://www.proxmox.com/) | 8.x | Hypervisor target |
| [pre-commit](https://pre-commit.com/) | 4.0+ | Local hook runner |

## Proxmox API Token

Create a dedicated API token with the minimum permissions needed for Packer. The example below uses `--privsep=0`, which disables token privilege separation. If your environment supports token-scoped ACLs, prefer a privilege-separated token with only the required permissions.

```bash
pveum role add PackerBuilder -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit ISO.Download Pool.Audit Pool.Allocate SDN.Use Sys.Modify"
pveum user add packer@pve
pveum aclmod / -user packer@pve -role PackerBuilder
pveum user token add packer@pve packer-token --privsep=0
```

## Quick Start

### 1. Clone and initialize

```bash
git clone https://github.com/nwarila-platform/proxmox-packer-framework.git
cd proxmox-packer-framework

cd packer
packer init .
```

### 2. Copy example inputs

```bash
# Packer example inputs
cp ../examples/packer/.env.example ./../.env.packer.example
cp ../examples/packer/rocky-linux-9/rocky-linux-9.pkrvars.hcl ./my-rocky.pkrvars.hcl
```

The `.env.example` files are templates for values you should export into your shell or CI environment. They are not auto-loaded by Packer.

### 3. Configure your environment

- export `PKR_VAR_*` values for Proxmox access and deploy-user credentials from the copied Packer env example
- edit `my-rocky.pkrvars.hcl` for network, storage, hardware, and installer settings
- point `install_template.template_path` and `ansible_config.*` paths at consumer-owned content

The framework requires `boot_iso` (and any `additional_iso_files`) to be supplied by the caller — there are no bundled media defaults. In production, runner repos render those blocks from [`terraform-proxmox-iso-manager-framework`](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework) outputs into an auto-loaded pkrvars file. For local validate runs, the example pkrvars files under `examples/packer/` pin known-good Proxmox storage paths and SHA-256 checksums directly.

The framework also accepts `PKR_VAR_proxmox_skip_tls_verify` and `PKR_VAR_proxmox_node` as top-level CI-friendly overrides for the matching nested `packer_image` fields.

### 4. Validate and build

```bash
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
|   |-- scripts/
|   |   |-- get_packer_version.sh
|   |   |-- validate_examples.sh
|   |   `-- validate_examples.ps1
|   `-- workflows/
|-- .vscode/
|-- docs/
|   |-- explanation/
|   |   `-- architecture.md
|   `-- reference/
|       `-- template-contract.md
|-- examples/
|   |-- packer/
|   |   |-- .env.example
|   |   |-- rocky-linux-9/
|   |   |-- ubuntu-24-04/
|   |   `-- windows-server-2022/
|   `-- terraform/
|       |-- .env.example
|       |-- README.md
|       `-- terraform.tfvars.example
|-- packer/
|   |-- builds.pkr.hcl
|   |-- data.pkr.hcl
|   |-- locals.pkr.hcl
|   |-- packer.pkr.hcl
|   |-- source.pkr.hcl
|   `-- variables.pkr.hcl
|-- .editorconfig
|-- .gitattributes
|-- .pre-commit-config.yaml
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
| Main Validation | Push to `main` touching `packer/**`, `examples/**`, `contract/**`, `tools/**`, `.github/scripts/**`, `.github/workflows/**`, `.pre-commit-config.yaml` (plus release-please outputs) | Reusable workflow contract check, Packer init/fmt/validate |
| PR Validation | Every PR to `main` (and merge queue) | Reusable workflow contract check, Packer init/fmt/validate |
| Security | Push/PR to `main`, merge queue, weekly schedule | Calls the org `reusable-iac-security` (Trivy IaC plus Gitleaks secret scan), `reusable-codeql`, and `reusable-scorecard` (OpenSSF Scorecard) reusables |
| Drift Gate | Every PR to `main` | Verifies this repo against the org baseline and the `packer-framework-template` baseline manifests |
| Repo Hygiene | PR to `main`, merge queue, weekly schedule | Calls the org `reusable-repo-hygiene` policy (SHA-pinned actions, exact pins, `pull_request_target` safety) |
| Release | Push to `main` (opt-in via `RELEASE_PLEASE_ON_PUSH`) or a published release | Runs release-please for changelog/releases and publishes release evidence/attestations |

Secret scanning and IaC scanning run once, in the Security workflow, through the org-owned
`reusable-iac-security` reusable; the validation workflows no longer run Gitleaks inline. Two
additional workflows are callable rather than event-triggered: `reusable-packer-framework-build.yaml`
(the downstream build/validate entrypoint described below) and `reusable-release-evidence.yaml`
(invoked by the Release workflow).

## Downstream Integration

Downstream OS-template repositories should call this framework through its reusable workflow when
they want CI to validate or build against a SHA-pinned framework revision. The workflow accepts the
same runner protocol input names as `NWarila/packer-framework-template`:

```yaml
jobs:
  validate-template-inputs:
    uses: nwarila-platform/proxmox-packer-framework/.github/workflows/reusable-packer-framework-build.yaml@0123456789abcdef0123456789abcdef01234567
    with:
      framework_ref: 0123456789abcdef0123456789abcdef01234567
      input_repo: NWarila/<os-template-repo>
      input_ref: fedcba9876543210fedcba9876543210fedcba98
      overlay_paths: |
        packer/repos/public/=>packer/repos/public/
      var_file: |
        packer/repos/public/rocky-linux-9.pkrvars.hcl
      build: false
      upload_artifacts: false
```

For privileged Proxmox builds, set `build: true` and pass Proxmox credentials as
reusable-workflow secrets. The workflow downloads the pinned `secure-packer-bootstrapper` release,
verifies its SHA-256 checksum, generates the short-lived deploy-user password/hash/key material in
the build step, loads the generated key into `ssh-agent`, and then runs `packer build`.

```yaml
jobs:
  build-template:
    uses: nwarila-platform/proxmox-packer-framework/.github/workflows/reusable-packer-framework-build.yaml@0123456789abcdef0123456789abcdef01234567
    with:
      framework_ref: 0123456789abcdef0123456789abcdef01234567
      input_repo: NWarila/<os-template-repo>
      input_ref: fedcba9876543210fedcba9876543210fedcba98
      overlay_paths: |
        packer/repos/public/=>packer/repos/public/
      var_file: |
        packer/repos/public/rocky-linux-9.pkrvars.hcl
      build: true
      upload_artifacts: true
    secrets:
      proxmox_hostname: ${{ secrets.PROXMOX_HOSTNAME }}
      proxmox_api_token_id: ${{ secrets.PROXMOX_PACKER_FRAMEWORK_TOKEN_ID }}
      proxmox_api_token_secret: ${{ secrets.PROXMOX_PACKER_FRAMEWORK_SECRET }}
      proxmox_node: ${{ secrets.PROXMOX_NODE }}
      deploy_user_name: ${{ secrets.DEPLOY_USER_NAME }}
```

This framework produces Proxmox VM templates designed to be consumed by Terraform or OpenTofu. A downstream repo can check out its own consumer content next to this framework, place its `.auto.pkrvars.hcl` file in the framework `packer/` working directory, and run `packer validate .` / `packer build .` directly as long as it supplies:

- `install_template` pointing at consumer-owned installer templates
- `ansible_config` pointing at consumer-owned Ansible content, with `ansible-playbook` available on PATH in the runtime environment
- `boot_iso` (and any `additional_iso_files`) rendered from a runner-repo Terraform call to `terraform-proxmox-iso-manager-framework`

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
