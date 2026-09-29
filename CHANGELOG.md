# Changelog

## [0.1.2](https://github.com/nwarila-platform/proxmox-packer-framework/compare/v0.1.1...v0.1.2) (2026-06-02)


### Documentation

* fix packer framework doc accuracy ([#37](https://github.com/nwarila-platform/proxmox-packer-framework/issues/37)) ([3a1afa3](https://github.com/nwarila-platform/proxmox-packer-framework/commit/3a1afa3e05358b53736abd921aa5ecbdbf621e8b))

## [0.1.1](https://github.com/nwarila-platform/proxmox-packer-framework/compare/v0.1.0...v0.1.1) (2026-05-29)


### Documentation

* sync README workflow table with post-gitleaks-cleanup reality ([#35](https://github.com/nwarila-platform/proxmox-packer-framework/issues/35)) ([c960fbd](https://github.com/nwarila-platform/proxmox-packer-framework/commit/c960fbdb06e94f516b1dc1fba37b52efba02ed45))

## [0.1.0](https://github.com/nwarila-platform/proxmox-packer-framework/compare/v0.0.1...v0.1.0) (2026-05-28)


### Features

* **ci:** expose reusable Packer framework workflow ([11adc3c](https://github.com/nwarila-platform/proxmox-packer-framework/commit/11adc3c940b62c56f9dba56039b2fa27c23e270b))
* **release:** migrate to org reusable-release-please + release evidence ([#31](https://github.com/nwarila-platform/proxmox-packer-framework/issues/31)) ([e1a9960](https://github.com/nwarila-platform/proxmox-packer-framework/commit/e1a99606bf61dd128510eafbb50c9ce824ee7f6b))
* **release:** ppf-appropriate release evidence (SBOM + provenance) ([#32](https://github.com/nwarila-platform/proxmox-packer-framework/issues/32)) ([77543cb](https://github.com/nwarila-platform/proxmox-packer-framework/commit/77543cbbcbf43218d488aee98ddf7cf1bd873222))


### Bug Fixes

* **ci:** correct pre-commit config name and gate all PRs ([#27](https://github.com/nwarila-platform/proxmox-packer-framework/issues/27)) ([4a79a54](https://github.com/nwarila-platform/proxmox-packer-framework/commit/4a79a54b634028639a5e935617fbfca28ac33a79))


### Refactoring

* **packer:** hand ISO lifecycle to terraform-proxmox-iso-manager-framework ([#23](https://github.com/nwarila-platform/proxmox-packer-framework/issues/23)) ([9f8f312](https://github.com/nwarila-platform/proxmox-packer-framework/commit/9f8f31266bdde4e6a1e6a38b3536fdfd6427dc79))


### CI/CD

* **align:** drift-gate type-template baseline + tidy docs (Diataxis) ([#30](https://github.com/nwarila-platform/proxmox-packer-framework/issues/30)) ([bc69aab](https://github.com/nwarila-platform/proxmox-packer-framework/commit/bc69aab6d015888b83a3b40bd7f6194ffa08549b))
* **deps:** migrate from Dependabot to Renovate (ADR-0004) ([#29](https://github.com/nwarila-platform/proxmox-packer-framework/issues/29)) ([92e9106](https://github.com/nwarila-platform/proxmox-packer-framework/commit/92e91062b79edaf7be4a6f6cb8dfd872ab73cb87))
* fix shellcheck SC2181 in packer-fmt step ([#26](https://github.com/nwarila-platform/proxmox-packer-framework/issues/26)) ([b3029c6](https://github.com/nwarila-platform/proxmox-packer-framework/commit/b3029c6d94558cf3bac58fe8c7508792f7877ecc))
* **security:** call org reusables + add repo-hygiene caller ([#28](https://github.com/nwarila-platform/proxmox-packer-framework/issues/28)) ([fc7ae0a](https://github.com/nwarila-platform/proxmox-packer-framework/commit/fc7ae0a6ab221823840f5363becc889b6e72d60c))

## 0.0.1 (2026-05-04)


### Features

* add comprehensive security policy and reporting guidelines ([f8f1b40](https://github.com/nwarila-platform/proxmox-packer-framework/commit/f8f1b406043852c8ef8d23cd5a55207a55238da0))


### Bug Fixes

* capitalize validation error messages to satisfy Packer requirements ([0629cf6](https://github.com/nwarila-platform/proxmox-packer-framework/commit/0629cf60b138c3a51caf7f02607ab6922d50cdff))
* **ci:** align single-branch validation workflow and example checks ([b90308e](https://github.com/nwarila-platform/proxmox-packer-framework/commit/b90308e2ea156df1cf4443070fea5f5adbdb7bfe))
* **ci:** enforce main validation and restore packer fmt cleanliness ([51482a0](https://github.com/nwarila-platform/proxmox-packer-framework/commit/51482a055cca4261c5bcc3c23fe7c6d8691a4a4b))
* **packer:** align ssh path with secure-packer-bootstrapper credential contract ([51f38b0](https://github.com/nwarila-platform/proxmox-packer-framework/commit/51f38b0f46876583153dcbd95675544ca40eeff5))
* **packer:** restore valid connection field types ([417a8ec](https://github.com/nwarila-platform/proxmox-packer-framework/commit/417a8eced66e18e5e6f4e0bdce804a28c3333126))
* switch ansible provisioners to except-based logic and make connection fields optional ([1419928](https://github.com/nwarila-platform/proxmox-packer-framework/commit/1419928a388d90af8bfba3ad8a23859d43a1c75f))
* update terraform lock file to match bpg/proxmox 0.98.1 ([002b6cc](https://github.com/nwarila-platform/proxmox-packer-framework/commit/002b6cc498e0e918bb47284369254987c8472759))
