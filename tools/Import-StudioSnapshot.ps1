param(
    [Parameter(Mandatory = $true)][string]$InputPlace,
    [string]$RojoPath = "$env:USERPROFILE\.aftman\tool-storage\rojo-rbx\rojo\7.7.1\rojo.exe"
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
& (Join-Path $PSScriptRoot 'Check-Ownership.ps1')
$inputFile = (Resolve-Path -LiteralPath $InputPlace).Path
if ([IO.Path]::GetExtension($inputFile) -notin @('.rbxl', '.rbxlx')) { throw 'Input must be a saved Studio place.' }
if (-not (Test-Path -LiteralPath $RojoPath -PathType Leaf)) { throw 'Rojo executable missing; supply -RojoPath.' }
$snapshotId = (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 6)
$snapshot = Join-Path $projectRoot "studio-snapshots/$snapshotId"
New-Item -ItemType Directory -Path $snapshot -Force | Out-Null
Copy-Item -LiteralPath $inputFile -Destination (Join-Path $snapshot ('Studio-original' + [IO.Path]::GetExtension($inputFile)))
$tree = [ordered]@{ '$className' = 'DataModel' }
foreach ($service in @('Workspace','ServerScriptService','ServerStorage','ReplicatedStorage','ReplicatedFirst','StarterGui','StarterPack','Lighting','SoundService')) {
    $tree[$service] = [ordered]@{
        '$className' = $service
        'UserOwned' = @{ '$path' = "content/$service/UserOwned" }
    }
    New-Item -ItemType Directory -Path (Join-Path $snapshot "content/$service/UserOwned") -Force | Out-Null
}
$tree['StarterPlayer'] = [ordered]@{ '$className' = 'StarterPlayer' }
foreach ($container in @('StarterPlayerScripts', 'StarterCharacterScripts')) {
    $tree['StarterPlayer'][$container] = [ordered]@{
        '$className' = $container
        'UserOwned' = @{ '$path' = "content/StarterPlayer/$container/UserOwned" }
    }
    New-Item -ItemType Directory -Path (Join-Path $snapshot "content/StarterPlayer/$container/UserOwned") -Force | Out-Null
}
$importProject = Join-Path $snapshot 'snapshot.project.json'
@{ name = 'StudioSnapshot-DO-NOT-SERVE'; tree = $tree } | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $importProject -Encoding utf8
try {
    & $RojoPath syncback $importProject --input $inputFile --non-interactive
    if ($LASTEXITCODE -ne 0) { throw "Import failed. Check that all UserOwned folders exist in the saved place. Original is backed up in $snapshot" }
} finally {
    # Keep the import configuration as a record, not a selectable live-sync project.
    Move-Item -LiteralPath $importProject -Destination (Join-Path $snapshot 'snapshot-config.json')
}
Write-Output "New read-only-by-policy snapshot: $snapshot"
Write-Output 'Live-sync source files were not changed. Never serve this snapshot.'
