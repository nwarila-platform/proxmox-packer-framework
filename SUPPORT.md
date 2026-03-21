# Support

## Supported use case

This repository supports the Packer framework itself, the repository automation around it, and the developer workflow needed to work on it safely and consistently. This includes the variable contract, normalization layer, build pipeline, and shipped installer examples.

Configuration management (Ansible playbooks, roles, Galaxy requirements) is owned by consumer repositories, not this framework. For Ansible-specific support, refer to [ansible-framework](https://github.com/NWarila/ansible-framework) or your consumer repo's documentation.

## Out of scope

- Troubleshooting your specific Proxmox environment.
- Debugging OS installation issues caused by custom installer template modifications.
- Recovering failed builds in downstream consumer repositories.
- Handling credentials or environment-specific secret management for consumers.
- Ansible playbook, role, or collection issues (owned by consumer repos).

## When requesting help

Include:

- the command you ran
- the operating system
- the Packer and plugin versions (`packer version`, `packer plugins installed`)
- the relevant workflow or script
- the exact error output
- the target Proxmox VE version
