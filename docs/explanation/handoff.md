# Engineering Handoff

Date: 2026-05-27

## Current State

- Branch: `chore/ship-boot-iso-required-guard` (cut from `main`)
- Base: `main` at
  `9f8f31266bdde4e6a1e6a38b3536fdfd6427dc79`
  (`refactor(packer): hand ISO lifecycle to terraform-proxmox-iso-manager-framework (#23)`)
- Remote: `origin git@github.com:nwarila-platform/proxmox-packer-framework.git`
- Open PRs (prior to this session): `#24 chore(main): release 0.1.0`
  (release-please). Closed PR `#22` was not touched.
- Recent GitHub Actions runs on `main` for Main Validation, Release Please,
  and Security Scanning are successful at the PR #23 merge timestamp.

## What This Session Did

Two prior sessions had built up a coherent dirty tree but never shipped it.
This session's audit confirmed:

- the dirty work is factually justified by the PR #23 handoff,
- the reusable workflow contract is unchanged,
- all available local checks pass,

and then bundled the entire dirty tree into one focused commit on a feature
branch and opened a PR for review.

No PRs were merged, branches deleted, or history rewritten.

## Audit Performed

- Local git status, branch, remotes, recent commits, dirty diff, and HEAD.
- Open PRs and recent CI runs via GitHub CLI.
- Reusable workflow and contract:
  - `.github/workflows/reusable-packer-framework-build.yaml`
  - `contract/reusable-packer-framework-build.yaml`
  - `tools/check_reusable_workflow_contract.py`
- Packer HCL wiring for `boot_iso` and `additional_iso_files`:
  - `packer/variables.pkr.hcl`
  - `packer/locals.pkr.hcl`
  - `packer/source.pkr.hcl`
- Example Packer var files for Rocky Linux 9, Ubuntu 24.04, and Windows Server
  2022. All supply `boot_iso`; Windows also supplies `additional_iso_files`.
- Docs and example surfaces for stale media lifecycle claims:
  - `README.md`
  - `docs/architecture.md`
  - `docs/template-contract.md`
  - `examples/terraform/*`
  - `.github/scripts/*`
- `actionlint` across all workflows.
- Stale-reference search across the repo for
  `proxmox-media-infra`, `media[_-]infra`, `REQUIREMENTS.md`,
  `packer/iso/`, and bare `iso_files`.

## Selected Problem

The single highest-impact remaining production-readiness gap was that the
prior sessions' coherent boot_iso contract-tightening work was uncommitted.
Until it ships, downstream runner repos can still validate with
`boot_iso = null` and only fail at build time, the Terraform example still
sends new runner repos in the wrong direction, and the README project tree
still references files that were deleted in PR #23.

This selection is small, fact-backed, downstream-facing, and compatible with
the reusable workflow contract. It does not change the workflow surface,
does not invent repo-owned Terraform automation, and does not reopen the
closed release-please PR.

## What Changed in This PR

Pre-existing dirty changes preserved from prior sessions, bundled here:

- `packer/variables.pkr.hcl` adds a required `boot_iso` validation guard so
  `boot_iso = null` fails fast at `packer validate` with a message pointing
  the caller at `terraform-proxmox-iso-manager-framework`.
- `.github/scripts/validate_examples.sh` adds an
  `assert_boot_iso_required` step that runs `packer validate` with
  `boot_iso = null` and confirms validation fails with the expected
  framework message.
- `.github/scripts/validate_examples.ps1` adds the Windows twin and
  resets `$global:LASTEXITCODE` after the intentional negative validation
  so the script's own exit code reflects assertion success rather than the
  intended `packer validate` failure.
- `examples/terraform/README.md` now points only at
  `terraform-proxmox-iso-manager-framework` and states that runner repos
  still need a Terraform step to render `boot_iso` / `additional_iso_files`.
- `examples/terraform/terraform.tfvars.example` no longer shows the old bulk
  `iso_files` catalog shape. It now shows runner-root-friendly `iso_pins`
  values shaped around one ISO-manager module call per ISO plus Packer
  device metadata needed to render the handoff file.
- `examples/terraform/.env.example` no longer advertises stale Proxmox auth
  `TF_VAR_*` names as this framework's Terraform contract.
- `.gitignore` allows `docs/handoff.md` through the deny-all ignore strategy.
- `README.md` removes stale `docs/REQUIREMENTS.md` and `packer/iso/`
  entries from the Project Structure tree.

## Verification

- `git status --short --branch` -> expected dirty files prior to commit.
- `gh pr list -R nwarila-platform/proxmox-packer-framework --state open` ->
  open release-please PR `#24` only at audit time.
- `gh run list -R nwarila-platform/proxmox-packer-framework --branch main --limit 10`
  -> latest `main` Main Validation, Release Please, and Security Scanning
  runs successful.
- `python tools/check_reusable_workflow_contract.py` -> OK.
- `C:\tmp\packer-1.15.0\packer.exe fmt -check -recursive packer\` -> OK.
- `C:\tmp\actionlint-1.7.12\actionlint.exe -no-color` across all workflows
  -> only pre-existing SC2181 style notes in `main-validation.yml` and
  `pr-validation.yaml`; both files are unchanged on `main` and CI is green.
- `bash -n .github/scripts/validate_examples.sh` -> OK.
- Stale-reference search across `**/*.{md,yaml,yml,hcl,sh,ps1,py,json}` for
  `proxmox-media-infra`, `media[_-]infra`, `REQUIREMENTS\.md`,
  `packer/iso/`, and bare `iso_files\b` -> source matches limited to this
  PR's diff and the handoff docs.
- `git diff --check` -> OK prior to commit.

## Checks Not Run

- Full Linux `validate_examples.sh` was not run on this Windows host.
  `bash -n` checked syntax. CI runs the bash path on Linux.
- The Windows `validate_examples.ps1` twin was not re-run in this session;
  the prior session ran it end-to-end after introducing the
  `$global:LASTEXITCODE` reset.
- No real Proxmox build was attempted.

## Known Remaining Gaps

- The first real downstream runner repo still needs to exercise the complete
  chain: ISO-manager Terraform outputs -> rendered Packer `boot_iso` /
  `additional_iso_files` pkrvars -> this framework's reusable workflow
  `var_file` input.
- `docs/template-contract.md` still has no explicit contract-version field
  or compatible-framework-release range. Tracking only — not load-bearing
  until the contract is consumed externally with version pinning.
- `opa_version` remains accepted but unused for upstream contract
  compatibility, as documented in the workflow input description.
- `packer/locals.pkr.hcl` and `packer/source.pkr.hcl` still defensively
  handle null `boot_iso` even though validation now rejects it. This is
  harmless and deliberately left alone to avoid theater.
- Pre-existing actionlint SC2181 style warnings on `main-validation.yml`
  and `pr-validation.yaml` (`if [ $? -ne 0 ]`). CI passes; not blocking.
- Open release-please PR `#24` still needs a human merge decision and is
  out of scope here.

## Recommended Next Smallest Task

After the PR opened by this session is reviewed and merged, wire one
downstream runner repository (Rocky Linux is the most likely candidate)
end-to-end through `terraform-proxmox-iso-manager-framework` -> rendered
Packer `boot_iso` pkrvars -> this framework's reusable workflow `var_file`
input. That proves the ISO-manager handoff with a real consumer and unlocks
all subsequent OS runner repos.
