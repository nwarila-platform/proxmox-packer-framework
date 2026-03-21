#!/usr/bin/env bash
set -euo pipefail

repo_root="$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null 2>&1
  pwd -P
)"

terraform_dir="$repo_root/terraform"

cd "$terraform_dir"
terraform init -backend=false -input=false
terraform validate
