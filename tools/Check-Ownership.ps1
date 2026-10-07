$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$project = Get-Content -LiteralPath (Join-Path $projectRoot 'default.project.json') -Raw | ConvertFrom-Json
$expected = @{
    'ServerScriptService/WarrrServer' = 'prototype/Server.server.luau'
    'StarterPlayer/StarterPlayerScripts/WarrrClient' = 'prototype/Client.client.luau'
}
$script:mappedCount = 0
function Test-Node($node, [string]$location) {
    if ($node.PSObject.Properties.Name -contains '$path') {
        if (-not $expected.ContainsKey($location) -or $expected[$location] -cne $node.'$path') {
            throw "Unapproved forward-sync mapping: $location"
        }
        $script:mappedCount++
    } else {
        if ($node.'$ignoreUnknownInstances' -ne $true) { throw "Missing preserve-unknown flag: $location" }
    }
    foreach ($property in $node.PSObject.Properties) {
        if ($property.Name.StartsWith('$')) { continue }
        if ($property.Name -eq 'UserOwned') { throw 'UserOwned must never be forward-mapped.' }
        $childLocation = if ($location) { "$location/$($property.Name)" } else { $property.Name }
        Test-Node $property.Value $childLocation
    }
}
Test-Node $project.tree ''
if ($script:mappedCount -ne $expected.Count) { throw 'Unexpected mapped script count.' }
Write-Output 'Ownership check passed: only the two approved scripts are forward-synced.'
