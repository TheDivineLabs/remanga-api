$ErrorActionPreference = 'Stop'
$root = Join-Path $env:TEMP "remanga-api-readme-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $root | Out-Null

try {
    $summaryPath = Join-Path $root 'snapshot-summary.json'
    $readmePath = Join-Path $root 'README.md'
    $summary = @{
        frontend_release = 'abc12345'
        endpoint_count = 10
        methods = @(
            @{ name = 'DELETE'; count = 1 }
            @{ name = 'GET'; count = 4 }
            @{ name = 'PATCH'; count = 1 }
            @{ name = 'POST'; count = 3 }
            @{ name = 'PUT'; count = 1 }
        )
    } | ConvertTo-Json -Depth 5
    $readme = @'
- [Reference](API_REFERENCE.md) - 2 routes;

<!-- BEGIN GENERATED SNAPSHOT -->
Snapshot for frontend `deadbee` contains:

| HTTP method | Count |
|---|---:|
| GET | 1 |
| POST | 1 |
| **Total** | **2** |
<!-- END GENERATED SNAPSHOT -->
'@
    [IO.File]::WriteAllText($summaryPath, $summary, (New-Object Text.UTF8Encoding($false)))
    [IO.File]::WriteAllText($readmePath, $readme, (New-Object Text.UTF8Encoding($false)))

    & (Join-Path $PSScriptRoot '..\Update-ReadmeSnapshot.ps1') -SummaryPath $summaryPath -ReadmePath $readmePath
    $result = [IO.File]::ReadAllText($readmePath)
    if ($result -notmatch 'frontend `abc12345`') { throw 'Frontend release was not updated' }
    if ($result -notmatch '\| PATCH \| 1 \|') { throw 'PATCH count was not added' }
    if ($result -notmatch '\| \*\*Total\*\* \| \*\*10\*\* \|') { throw 'Endpoint total was not updated' }
    if ($result -notmatch 'API_REFERENCE\.md\) - 10 routes') { throw 'Reference count was not updated' }
    Write-Host 'README update test passed'
}
finally {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
}
