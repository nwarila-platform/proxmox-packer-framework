# Security Policy

## Supported Versions

This repository is currently in a pre-1.0 transition state while the framework boundary and
consumer-owned Ansible model settle. Until multiple tagged release lines exist, the supported
security surface is:

- the current `main` branch
- the latest tagged release, once release automation starts publishing real versions

No previous-minor support matrix is published yet because the repository does not currently
evidence multiple maintained release lines.

## Reporting a Vulnerability

**Please do NOT report security vulnerabilities through public GitHub issues.**

Instead, report them via email to **reports@nicholaswarila.com** with the
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
- Weaknesses in the framework's communicator hardening (SSH ciphers, WinRM transport)
- Secrets or credentials exposed in build artifacts or logs
- CI/CD pipeline vulnerabilities (workflow injection, secret leakage)
- Installer template configurations that bypass intended security controls

The following are **out of scope**:

- Vulnerabilities in upstream dependencies (Packer, Ansible, Proxmox) — report these
  to the respective maintainers
- Issues requiring physical access to the Proxmox host
- Denial of service against build infrastructure
- Consumer-owned Ansible role or playbook security issues

## Security Features

This project implements the following security controls:

- **Hardened SSH communicator** with restricted ciphers and key exchange algorithms
- **UEFI/Secure Boot and TPM 2.0** support with secure defaults
- **Secret scanning** via Gitleaks at every CI gate and pre-commit
- **Dependency scanning** via Trivy (filesystem) and Dependabot (GitHub Actions)
- **SHA-pinned GitHub Actions** to prevent supply chain attacks via mutable tags

### Security Notes for Shipped Examples

- **TLS verification:** Shipped examples set `insecure_skip_tls_verify = true` as an
  exception for environments with self-signed certificates. Production environments
  should set this to `false`.
- **WinRM transport:** The Windows example demonstrates a bootstrap-only HTTP Basic /
  ignore-cert path on port 5985. The framework now exposes consumer-controlled WinRM
  settings so hardened environments can use HTTPS on port 5986 with certificate
  validation and stronger authentication.
- **Installer hardening:** The Rocky Linux Kickstart example applies DISA STIG via
  OpenSCAP, CIS-aligned partitioning, and SSH hardening in `%post`.
