# Terraform Examples

These files are inert reference inputs for runner repositories that call
[`nwarila-platform/terraform-proxmox-iso-manager-framework`](https://github.com/nwarila-platform/terraform-proxmox-iso-manager-framework)
before invoking this Packer framework. This repo does not own Terraform state,
Terraform apply workflows, or Proxmox ISO/media lifecycle credentials.

Runner OS-template repositories that call this framework's reusable Packer
workflow do still need their own Terraform step to render a `boot_iso` (and any
`additional_iso_files`) pkrvars file. The framework's `boot_iso` variable is
required; see [`docs/explanation/architecture.md`](../../docs/explanation/architecture.md#iso-lifecycle-boundary).
The rendered pkrvars file is consumed through the reusable workflow's `var_file`
input.

`terraform.tfvars.example` is not consumed by this repo and is not a complete
Terraform root module. It shows one runner-root-friendly `iso_pins` shape that
can drive one `module "iso"` call per ISO and then render the Packer-shaped
handoff file. Use the ISO-manager repo's own examples as the runnable module
source of truth.
