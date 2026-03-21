# Architecture

## Data-Driven Normalization Pattern

The framework uses a three-layer data flow:

1. **Consumer inputs** (`.pkrvars.hcl`) define environment-specific values
2. **`locals.pkr.hcl`** normalizes inputs with `coalesce()` defaults, assembles the
   template variable contract, and constructs the install ISO
3. **`source.pkr.hcl`** consumes normalized locals to configure the Proxmox ISO source

This pattern lets consumers override only what differs from the defaults while ensuring
every build produces a structurally consistent template.

## Install Template Mechanism

The framework uses a generic `install_template` variable instead of OS-specific branching.
Consumer repos provide:

- `template_path` — path to a `.pkrtpl.hcl` file (Kickstart, Autounattend, autoinstall, etc.)
- `output_file` — filename on the virtual CD (e.g. `/ks.cfg`, `/autounattend.xml`)
- `cd_label` — CD volume label (default: `OEMDRV`)
- `cd_type` — bus type for the CD device (default: `scsi`)
- `extra_cd_content` — companion files packaged onto the same virtual CD (for example Ubuntu `meta-data`)
- `extra_vars` — OS-specific variables passed through the `extra` map

The framework renders the template with the guaranteed [template variable contract](template-contract.md)
and packages it onto a virtual CD via `additional_iso_files`.

This design supports any installer type (Kickstart, Autounattend, autoinstall, preseed)
without framework changes.

## Framework-Consumer Boundary

**Framework owns:**

- Proxmox API integration and VM lifecycle
- The shared Packer variable contract (`variables.pkr.hcl`, `locals.pkr.hcl`)
- Communicator wiring (SSH ciphers, WinRM transport, timeout management)
- Communicator security defaults and override points (for example WinRM HTTPS vs bootstrap HTTP)
- Build pipeline orchestration (`builds.pkr.hcl`, `source.pkr.hcl`)
- Template variable contract definition
- Maintained installer examples for Kickstart, Windows, and Ubuntu

**Consumer repos own:**

- Configuration management (Ansible playbooks, roles, Galaxy requirements)
- OS installer templates (Kickstart, Autounattend, autoinstall)
- Environment-specific values (IPs, storage pools, VM IDs, credentials)

The default shared source for Ansible content is
[ansible-framework](https://github.com/NWarila/ansible-framework).

## ISO Lifecycle Boundary

The repository currently supports two ISO-management layers:

- `terraform/` can download and manage ISO lifecycle on Proxmox storage.
- `packer/iso/catalog.json` provides the bundled Packer-side media catalog, with `packer/iso/*.pkrvars.hcl` still available as explicit override files.

For the shipped OS families, the framework can infer a bundled media profile from `packer_image.os_name` and `packer_image.os_version`. Consumers can still override the inferred profile with `media_profile`, `boot_iso`, or `additional_iso_files`.

Today, those bundled media defaults are still committed in this repository. That is an intentional transitional state while a dedicated external media-tracking repository is being prepared. Until that external handoff exists, Terraform-backed media management and Packer-side media defaults must be kept in sync by maintainers.

## Packer Subdirectory Layout

All Packer HCL files live under `packer/` rather than the repository root. This is a
deliberate choice because the repo also contains examples, documentation, CI/CD
configuration, and editor settings that are not Packer HCL files. Packer parses all
`.pkr.hcl` files in the directory passed to `packer build`, so the subdirectory layout
is functionally equivalent to root placement.

CI workflows and README instructions reference this path consistently via
`working-directory: packer/`.

## File Responsibilities

| File | Purpose |
|------|---------|
| `packer.pkr.hcl` | Packer version constraint and plugin declarations |
| `variables.pkr.hcl` | Input variable declarations (consumer contract surface) |
| `locals.pkr.hcl` | Variable normalization, template var contract, install ISO assembly |
| `source.pkr.hcl` | Proxmox ISO source definition with dynamic hardware blocks |
| `builds.pkr.hcl` | Build definition with consumer-driven Ansible provisioner and manifest |
| `data.pkr.hcl` | Git data source for build metadata |
| `packer/iso/catalog.json` | Bundled media catalog used for inferred Rocky, Ubuntu, and Windows ISO defaults |
| `packer/iso/*.pkrvars.hcl` | Explicit media override files retained for compatibility and future handoff work |
| `terraform/*.tf` | Optional Terraform helper for managing ISO lifecycle on Proxmox storage |
