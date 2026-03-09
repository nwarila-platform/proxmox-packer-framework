# Support

## Supported use case

This repository supports the Packer framework itself, the Ansible provisioning roles, the repository automation around it, and the developer workflow needed to work on it safely and consistently.

## Out of scope

- Troubleshooting your specific Proxmox environment.
- Debugging OS installation issues caused by custom kickstart modifications.
- Recovering failed builds in downstream consumer repositories.
- Handling credentials or environment-specific secret management for consumers.

## When requesting help

Include:

- the command you ran
- the operating system
- the Packer and plugin versions (`packer version`, `packer plugins installed`)
- the relevant workflow or script
- the exact error output
- the target Proxmox VE version
