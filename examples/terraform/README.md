# Terraform Examples

These files are non-live examples for the Proxmox media lifecycle inputs now owned by
[`nwarila-platform/proxmox-media-infra`](https://github.com/nwarila-platform/proxmox-media-infra).

This Packer framework repo does not own Terraform state, Terraform apply workflows, or
Proxmox ISO/media lifecycle credentials. Downstream OS-template repositories do not need
to run Terraform before calling this framework's reusable Packer workflow.
