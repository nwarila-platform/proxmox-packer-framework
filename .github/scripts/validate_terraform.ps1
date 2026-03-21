$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$terraformDir = Join-Path $repoRoot "terraform"

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

Push-Location $terraformDir

try {
    Invoke-NativeCommand -Executable "terraform" -Arguments @("init", "-backend=false", "-input=false")
    Invoke-NativeCommand -Executable "terraform" -Arguments @("validate")
}
finally {
    Pop-Location
}
