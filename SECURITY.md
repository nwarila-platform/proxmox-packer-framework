# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest release | Yes |
| Previous minor | Security fixes only |
| Older | No |

## Reporting a Vulnerability

**Please do NOT report security vulnerabilities through public GitHub issues.**

Instead, report them via email to **reports@TrinityTechnicalServices.com** with the
following information:

- Description of the vulnerability
- Steps to reproduce (or proof-of-concept)
- Affected versions
- Any potential mitigations you've identified

### What to expect

| Milestone | Target |
|-----------|--------|
| Acknowledgement | Within 48 hours |
| Initial assessment | Within 7 days |
| Fix or mitigation | Within 30 days (severity-dependent) |

You will receive updates at each milestone. If the vulnerability is accepted, you will
be credited in the release notes unless you prefer to remain anonymous.

## Coordinated Disclosure

We follow a coordinated disclosure model:

1. Reporter submits the vulnerability privately.
2. We acknowledge receipt and begin investigation.
3. We develop and test a fix.
4. We release the fix and publish an advisory.
5. Reporter is free to publish details after the fix is released.

We ask that you give us reasonable time to address the issue before any public
disclosure. We will work with you to agree on a timeline.

## Scope

The following are **in scope** for security reports:

- Packer templates that produce insecure VM configurations
- Ansible roles that weaken OS hardening (SSH, SELinux, firewall)
- Secrets or credentials exposed in build artifacts or logs
- CI/CD pipeline vulnerabilities (workflow injection, secret leakage)
- Kickstart configurations that bypass intended security controls

The following are **out of scope**:

- Vulnerabilities in upstream dependencies (Packer, Ansible, Proxmox) — report these
  to the respective maintainers
- Issues requiring physical access to the Proxmox host
- Denial of service against build infrastructure

## Security Features

This project implements the following security controls:

- **DISA STIG compliance** via OpenSCAP during OS installation
- **CIS-aligned partitioning** with restrictive mount options
- **SSH hardening** applied in both Kickstart and Ansible (defense in depth)
- **Secret scanning** via Gitleaks at every CI gate and pre-commit
- **Dependency scanning** via Trivy (filesystem) and Dependabot (GitHub Actions)
- **Template sealing** removes SSH keys, machine-id, logs, and cloud-init state
