# Proxmox Packer Framework

A production-grade, data-driven [Packer](https://www.packer.io/) framework for building hardened Proxmox VE virtual machine templates. It combines automated OS installation via Kickstart, configuration management through Ansible, and DISA STIG compliance via OpenSCAP — delivering golden images that are secure, reproducible, and ready for infrastructure-as-code consumption by Terraform or OpenTofu.

---

## Architecture

```text
┌─────────────────────────────────────────────────────────────────────────┐
│  .pkrvars.hcl (variables)                                               │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌──────────────────┐  │
│  │  Proxmox   │  │  Hardware  │  │   Network   │  │  Disk / LVM      │  │
│  │  API creds │  │  CPU, RAM  │  │  IP, VLAN   │  │  Partitions      │  │
│  └─────┬──────┘  └─────┬──────┘  └──────┬──────┘  └────────┬─────────┘  │
│        └───────────────┴────────────────┴──────────────────┘            │
│                                    │                                    │
│                          locals.pkr.hcl                                 │
│                      (normalize + defaults)                             │
│                                    │                                    │
│                         source.pkr.hcl                                  │
│                       (proxmox-iso source)                              │
│                                    │                                    │
└────────────────────────────────────┼────────────────────────────────────┘
                                     │
                    ┌────────────────┴────────────────┐
                    │        builds.pkr.hcl            │
                    │                                  │
                    │  1. Kickstart (ks.pkrtpl.hcl)    │
                    │     ├─ Partitioning (LVM)        │
                    │     ├─ DISA STIG (OpenSCAP)      │
                    │     ├─ SSH hardening              │
                    │     └─ Deploy user creation       │
                    │                                  │
                    │  2. Ansible Provisioning          │
                    │     ├─ base   (update + packages)│
                    │     ├─ users  (fact injection)    │
                    │     ├─ configure (cloud-init,    │
                    │     │    SSH, hostname, SELinux)  │
                    │     └─ clean  (logs, keys,       │
                    │          machine-id, cloud-init)  │
                    │                                  │
                    │  3. Manifest (build metadata)     │
                    └────────────────┬─────────────────┘
                                     │
                                     ▼
                          Proxmox VM Template
                       (ready for Terraform clone)
```

## Features

- **Data-driven configuration** — All VM parameters (CPU, memory, disks, network, partitions) are defined in `.pkrvars.hcl` files. The `locals.pkr.hcl` normalization layer applies sensible defaults via `coalesce()`, so consumers only override what they need.
- **DISA STIG compliance** — The Kickstart template applies the STIG security profile during OS installation using the OpenSCAP add-on (`xccdf_org.ssgproject.content_profile_stig`).
- **CIS-aligned disk partitioning** — Separate LVM volumes for `/`, `/home`, `/tmp`, `/var`, `/var/tmp`, `/var/log`, and `/var/log/audit` with restrictive mount options (`noexec`, `nosuid`, `nodev`).
- **SSH hardening** — Root login disabled, public key authentication enforced, X11 forwarding disabled, SFTP subsystem explicitly configured, and `MaxAuthTries` / `LoginGraceTime` locked down — applied in both Kickstart `%post` and Ansible for defense in depth.
- **Cloud-init lifecycle** — Installs cloud-init, configures the Proxmox datasource, enables all cloud-init services, loads the `isofs` kernel module for CDROM-based config drive detection, and performs a full clean (`cloud-init clean --logs --seed`) before template sealing.
- **Template-ready cleanup** — The `clean` role removes SSH host keys, machine-id, audit/system logs, tmp directories, NetworkManager connections, udev rules, and shell history to ensure each clone gets a unique identity on first boot.
- **Build metadata** — Every build produces a JSON manifest with git commit hash, build timestamp, hardware configuration, and the deploy username for full traceability.
- **Automated build timestamps** — `template_description` is automatically stamped with the build time via Packer's `timestamp()` function, enabling downstream Terraform to detect template changes via `replace_triggered_by`.

## Supported Operating Systems

| OS | Version | Install Method | Example |
|----|---------|---------------|---------|
| Rocky Linux | 9.x | Kickstart | [rocky-linux-9.pkrvars.hcl](examples/rocky-linux-9.pkrvars.hcl) |

The framework's variable structure supports any RHEL-family OS (and has package maps for Debian, SUSE, and Ubuntu in `base/vars/main.yml`). Adding a new OS requires only a new `.pkrvars.hcl` file and, if needed, an install template.

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| [Packer](https://www.packer.io/) | 1.15.0 | Image builder |
| [Ansible](https://docs.ansible.com/) | 2.15+ | Configuration management |
| [Proxmox VE](https://www.proxmox.com/) | 8.x | Hypervisor target |
| [pre-commit](https://pre-commit.com/) | 4.0+ | Local hook runner (optional) |

### Proxmox API Token

Create a dedicated API token with the minimum permissions needed for Packer to create VMs and templates:

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
cd proxmox-packer-framework/packer
packer init .
```

### 2. Configure variables

Copy the example files and fill in your environment-specific values:

```bash
cp examples/rocky-linux-9.pkrvars.hcl packer/my-rocky.pkrvars.hcl
cp examples/secrets.pkrvars.hcl       packer/my-secrets.pkrvars.hcl
```

Edit `my-secrets.pkrvars.hcl` with your Proxmox API credentials and deploy user settings. Edit `my-rocky.pkrvars.hcl` to match your network, storage, and hardware requirements.

### 3. Validate and build

```bash
# Validate configuration
packer validate \
  -var-file="my-rocky.pkrvars.hcl" \
  -var-file="my-secrets.pkrvars.hcl" .

# Build the template (-force replaces an existing template with the same vm_id)
packer build -force \
  -var-file="my-rocky.pkrvars.hcl" \
  -var-file="my-secrets.pkrvars.hcl" .
```

### 4. Install pre-commit hooks (contributors)

```bash
pre-commit install
pre-commit install --hook-type commit-msg
```

## Project Structure

```text
proxmox-packer-framework/
├── .config/                        # Linter configurations
│   ├── .ansible-lint.yml
│   ├── .markdownlint.json
│   └── .yamllint.yaml
├── .github/
│   ├── ISSUE_TEMPLATE/             # Structured bug/feature forms
│   ├── config/gitleaks.toml        # Secret detection rules
│   ├── scripts/get_packer_version.sh
│   └── workflows/
│       ├── dev-promotion-gate.yml  # Packer fmt + validate on DEV push
│       ├── feature-push-gate.yml   # Gitleaks on feature branches
│       ├── pr-validation.yaml      # Packer fmt + validate on PRs to main
│       ├── release-please.yaml     # Automated changelog + GitHub Releases
│       └── security.yaml           # Weekly Trivy + Gitleaks scan
├── .vscode/                        # Editor settings + tasks
├── examples/
│   ├── rocky-linux-9.pkrvars.hcl   # Full Rocky Linux 9 example
│   └── secrets.pkrvars.hcl         # Credential placeholder
├── packer/
│   ├── ansible/
│   │   ├── ansible.cfg             # SSH, pipelining, transfer config
│   │   ├── linux-playbook.yml      # Main playbook (base → users → configure → clean)
│   │   ├── linux-requirements.yml  # Galaxy collections (ansible.posix, community.general)
│   │   └── roles/
│   │       ├── base/               # OS updates, package installation, cloud-init install
│   │       ├── users/              # Fact injection for deploy user
│   │       ├── configure/          # SSH, hostname, SELinux, cloud-init datasource
│   │       └── clean/              # Template sealing (logs, keys, machine-id, cloud-init)
│   ├── data/                       # Kickstart sub-templates (network, storage)
│   ├── templates/
│   │   └── ks.pkrtpl.hcl           # Data-driven Kickstart template
│   ├── builds.pkr.hcl              # Build definition (Ansible provisioner + manifest)
│   ├── data.pkr.hcl                # Git data source for build metadata
│   ├── locals.pkr.hcl              # Variable normalization layer
│   ├── providers.pkr.hcl           # Packer + plugin version pins
│   ├── source.pkr.hcl              # proxmox-iso source definition
│   └── variables.pkr.hcl           # Input variable declarations
├── .editorconfig                   # Cross-editor formatting
├── .gitattributes                  # Line endings, Linguist, export-ignore
├── .pre-commit.config.yaml         # Hooks: hygiene, secrets, packer, ansible, yaml, markdown
├── .release-please-manifest.json   # Current version tracker
├── release-please-config.json      # Changelog sections + release config
├── CHANGELOG.md
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── LICENSE                         # MIT
├── SECURITY.md
└── SUPPORT.md
```

## CI/CD Pipeline

| Workflow | Trigger | What it does |
|----------|---------|-------------|
| **Feature Push Gate** | Push to any branch except DEV/TEST/PROD | Gitleaks secret scan |
| **DEV Promotion Gate** | Push to `DEV` (packer/** changes) | Gitleaks + Packer fmt check + Packer validate |
| **PR Validation** | PR to `main` (packer/** or examples/** changes) | Gitleaks + Packer fmt check + Packer validate |
| **Security Scanning** | Push/PR to `main`, weekly schedule | Trivy filesystem scan (SARIF) + Gitleaks |
| **Release Please** | Push to `main` | Automated changelog generation + GitHub Releases |

## Downstream Integration

This framework produces Proxmox VM templates designed to be consumed by Terraform or OpenTofu. The build timestamp in `template_description` enables automatic VM replacement when a new template is built:

```hcl
# In your Terraform configuration:
resource "terraform_data" "template_version" {
  input = data.proxmox_virtual_environment_vm.template.description
}

resource "proxmox_virtual_environment_vm" "vm" {
  # ...
  lifecycle {
    replace_triggered_by = [terraform_data.template_version]
  }
}
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines. This project uses [Conventional Commits](https://www.conventionalcommits.org/) and enforces them via pre-commit hooks.

## License

This project is licensed under the [MIT License](LICENSE).
