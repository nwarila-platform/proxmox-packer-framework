$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$packerDir = Join-Path $repoRoot "packer"
$tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())

New-Item -ItemType Directory -Path $tmpDir | Out-Null

try {
    $stubPlaybook = Join-Path $tmpDir "validation-playbook.yml"
    $stubPlaybookHcl = $stubPlaybook -replace "\\", "/"
    $stubAnsiblePlaybook = Join-Path $tmpDir "ansible-playbook.cmd"

    @"
---
- name: Validation-only Ansible stub
  hosts: all
  gather_facts: false
  tasks:
    - name: Emit validation marker
      ansible.builtin.debug:
        msg: validation-only stub
"@ | Set-Content -Path $stubPlaybook -NoNewline

    @"
@echo off
if "%~1"=="--version" (
  echo ansible-playbook [core 2.18.0]
  exit /b 0
)
exit /b 0
"@ | Set-Content -Path $stubAnsiblePlaybook -NoNewline

    $env:PATH = "$tmpDir;$env:PATH"

    function Invoke-NativeCommand {
        param(
            [Parameter(Mandatory = $true)]
            [string] $Executable,
            [Parameter()]
            [string[]] $Arguments = @()
        )

        & $Executable @Arguments
        if ($LASTEXITCODE -ne 0) {
            throw "Command failed: $Executable $($Arguments -join ' ')"
        }
    }

    function New-OverrideFile {
        param(
            [Parameter(Mandatory = $true)]
            [string] $OverridePath
        )

        @"
proxmox_hostname         = "proxmox.invalid"
proxmox_api_token_id     = "packer@pam!validation"
proxmox_api_token_secret = "validation-secret"
proxmox_node             = "validation-node"
deploy_user_name         = "packer"
deploy_user_password     = "ChangeMe123!"
deploy_user_public_key          = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMockValidationKeyOnly build-validation@example"

ansible_config = {
  playbook_path     = "$stubPlaybookHcl"
  requirements_path = null
  roles_path        = null
  config_path       = null
  extra_vars        = {}
}
"@ | Set-Content -Path $OverridePath -NoNewline
    }

    function Invoke-ExampleValidation {
        param(
            [Parameter(Mandatory = $true)]
            [string] $ExampleName,
            [Parameter(Mandatory = $true)]
            [string] $ExampleFile
        )

        $overrideFile = Join-Path $tmpDir "$ExampleName.pkrvars.hcl"
        New-OverrideFile -OverridePath $overrideFile

        Write-Host "Validating $ExampleName..."
        Invoke-NativeCommand -Executable "packer" -Arguments @(
            "validate",
            "-var-file=$ExampleFile",
            "-var-file=$overrideFile",
            "."
        )
    }

    Push-Location $packerDir
    Invoke-NativeCommand -Executable "packer" -Arguments @("init", ".")
    Invoke-ExampleValidation `
        -ExampleName "rocky-linux-9" `
        -ExampleFile (Join-Path $repoRoot "examples\packer\rocky-linux-9\rocky-linux-9.pkrvars.hcl")
    Invoke-ExampleValidation `
        -ExampleName "ubuntu-24-04-lts" `
        -ExampleFile (Join-Path $repoRoot "examples\packer\ubuntu-24-04\ubuntu-24-04-lts.pkrvars.hcl")
    Invoke-ExampleValidation `
        -ExampleName "windows-server-2022" `
        -ExampleFile (Join-Path $repoRoot "examples\packer\windows-server-2022\windows-server-2022.pkrvars.hcl")
}
finally {
    Pop-Location -ErrorAction SilentlyContinue
    Remove-Item -Path $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
}
