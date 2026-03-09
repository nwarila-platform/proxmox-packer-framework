# Contributing

Thanks for considering a contribution! This project is small, but contributions and bug reports are very welcome.

## Ways to contribute

- Report bugs or problems
- Suggest improvements or new features
- Submit pull requests with fixes or enhancements
- Improve documentation or examples

## Getting started

1. **Fork** the repository and create a branch for your changes:

   ```bash
   git checkout -b my-change
   ```

1. **Install pre-commit hooks** (requires [pre-commit](https://pre-commit.com)):

   ```bash
   pre-commit install
   pre-commit install --hook-type commit-msg
   ```

1. Make your edits.
1. Run all checks locally:

   ```bash
   pre-commit run --all-files
   ```

1. Open a **pull request** against the main branch and describe what you changed and why.

## Commit message format

This project uses [Conventional Commits](https://www.conventionalcommits.org/). Every commit message must follow the format:

```text
<type>: <description>
```

Allowed types: `feat`, `fix`, `ci`, `docs`, `refactor`, `test`, `chore`, `security`

Examples:

- `feat: add cloud-init clean step to clean role`
- `fix: use smart transfer method in ansible.cfg`
- `docs: update CONTRIBUTING with pre-commit instructions`

## Reporting bugs

Please open an issue using the **Bug Report** template and include:

- What you were trying to do
- What you expected to happen
- What actually happened
- Steps to reproduce
- Your environment (OS, Packer version, Proxmox version)

Screenshots or logs are helpful if something fails unexpectedly.

## Pull request guidelines

- Keep each PR focused on a single change when you can.
- Ensure `pre-commit run --all-files` passes before opening.
- Update documentation or examples if behavior or configuration changes.
- Be open to feedback and iterate on your PR if requested.

## Code of Conduct

This project is governed by the `CODE_OF_CONDUCT.md` file in this repository.
By participating, you agree to follow it.

## Questions

If you're not sure how best to contribute, feel free to open an issue and ask.
