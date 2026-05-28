# Architecture Decision Records

This directory holds the Architecture Decision Records (ADRs) governing this
repository. Per [org ADR-0001](org/0001-use-architecture-decision-records.md),
ADRs are organized into three scopes:

- `org/` - byte-identical mirrors of org-baseline ADRs from
  [`NWarila/.github`](https://github.com/NWarila/.github). These apply to every
  repo in the org regardless of stack and are kept in sync by the org drift gate.
- `template/` - ADRs inherited from this repo's Packer type-template
  ([`NWarila/packer-framework-template`](https://github.com/NWarila/packer-framework-template)).
  These carry Packer-framework decisions every derivative framework inherits.
  This scope is currently empty (only the directory skeleton is tracked).
- `repo/` - ADRs specific to this repository only. This scope is currently empty.

`proxmox-packer-framework` is a Proxmox-specific framework derived from the
Packer framework type-template. Stack-wide decisions live at the template tier;
org-wide decisions live at the org tier and are mirrored here for auditability.

## Org ADRs

The `org/` scope is mirrored from `NWarila/.github` and enforced by the org
drift gate.

| ADR | Status | Decision |
| --- | --- | --- |
| [ADR-0001](org/0001-use-architecture-decision-records.md) | Accepted | Use ADRs to document design rationale. |
| [ADR-0002](org/0002-adopt-diataxis-documentation-framework.md) | Accepted | Use Diátaxis for non-ADR documentation. |
| [ADR-0003](org/0003-use-deny-all-gitignore-strategy.md) | Accepted | Use deny-all `.gitignore` allowlists. |
| [ADR-0004](org/0004-use-renovate-for-dependency-updates.md) | Accepted | Use Renovate for dependency updates. |

## Template ADRs

The `template/` scope mirrors Packer-framework-template ADRs as this repository
adopts them. It currently holds only the directory skeleton; the `.gitkeep`
placeholder keeps the directory tracked until a template ADR is mirrored here.

## Repo ADRs

The `repo/` scope is for decisions that apply to this repository alone. It is
currently empty; the `.gitkeep` placeholder keeps the directory skeleton
complete until this repository records a repo-specific ADR.
