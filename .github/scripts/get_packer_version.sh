#!/usr/bin/env bash
set -euo pipefail

FILE="./providers.pkr.hcl"
[[ -f "$FILE" ]] || { echo "::error file=$FILE::Missing $FILE"; exit 1; }

PACKER_VERSION="$(
  awk -F'"' '
    /^[[:space:]]*required_version[[:space:]]*=/ {
      if (NF < 2 || $2 == "") {
        print "::error file=" FILENAME "::required_version is empty or not quoted" > "/dev/stderr"
        exit 3
      }
      print $2
      found=1
      exit 0
    }
    END {
      if (!found) {
        print "::error file=" FILENAME "::required_version not found" > "/dev/stderr"
        exit 2
      }
    }
  ' "$FILE"
)"

echo "PACKER_VERSION=$PACKER_VERSION" >> "$GITHUB_ENV"
echo "Using PACKER_VERSION=$PACKER_VERSION"
