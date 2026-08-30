param(
    [string]$SummaryPath = (Join-Path $PSScriptRoot '..\snapshot-summary.json'),
    [string]$ReadmePath = (Join-Path $PSScriptRoot '..\README.md')
)

$ErrorActionPreference = 'Stop'
$SummaryPath = [IO.Path]::GetFullPath($SummaryPath)
$ReadmePath = [IO.Path]::GetFullPath($ReadmePath)

if (-not (Test-Path -LiteralPath $SummaryPath -PathType Leaf)) {
    throw "Snapshot summary not found: $SummaryPath"
}
if (-not (Test-Path -LiteralPath $ReadmePath -PathType Leaf)) {
    throw "README not found: $ReadmePath"
}

$summary = Get-Content -Raw -Encoding UTF8 -LiteralPath $SummaryPath | ConvertFrom-Json
$release = [string]$summary.frontend_release
$endpointCount = [int]$summary.endpoint_count

if ($release -notmatch '^[0-9a-f]{7,40}$') {
    throw "Unexpected frontend release: $release"
}
if ($endpointCount -lt 1) {
    throw "Unexpected endpoint count: $endpointCount"
}

$methodCounts = @{}
foreach ($method in @($summary.methods)) {
    $name = ([string]$method.name).ToUpperInvariant()
    $count = [int]$method.count
    if ($name -notmatch '^[A-Z]+$' -or $count -lt 0) {
        throw "Invalid method summary: $name = $count"
    }
    $methodCounts[$name] = $count
}

$methodTotal = ($methodCounts.Values | Measure-Object -Sum).Sum
if ([int]$methodTotal -ne $endpointCount) {
    throw "Method total $methodTotal does not match endpoint count $endpointCount"
}

$readme = [IO.File]::ReadAllText($ReadmePath)
$newline = if ($readme.Contains("`r`n")) { "`r`n" } else { "`n" }
$methodOrder = @('GET', 'POST', 'PUT', 'PATCH', 'DELETE')
$orderedMethods = @($methodOrder | Where-Object { $methodCounts.ContainsKey($_) })
$orderedMethods += @($methodCounts.Keys | Where-Object { $_ -notin $methodOrder } | Sort-Object)

$snapshotPattern = '(?s)<!-- BEGIN GENERATED SNAPSHOT -->(.*?)<!-- END GENERATED SNAPSHOT -->'
$snapshotMatch = [regex]::Match($readme, $snapshotPattern)
if (-not $snapshotMatch.Success) {
    throw 'Generated snapshot markers are missing from README.md'
}

$existingBlock = $snapshotMatch.Groups[1].Value
$existingLines = @($existingBlock -split '\r?\n')
$snapshotLine = $existingLines | Where-Object { $_ -match '`[0-9a-f]{7,40}`' } | Select-Object -First 1
$separatorIndex = [Array]::IndexOf($existingLines, '|---|---:|')
$totalLine = $existingLines | Where-Object { $_ -match '^\| \*\*.+\*\* \| \*\*\d+\*\* \|$' } | Select-Object -First 1
if ($null -eq $snapshotLine -or $separatorIndex -lt 1 -or $null -eq $totalLine) {
    throw 'Generated snapshot template is invalid'
}

$snapshotLine = [regex]::Replace($snapshotLine, '`[0-9a-f]{7,40}`', "``$release``", 1)
$totalLine = [regex]::Replace($totalLine, '\*\*\d+\*\*', "**$endpointCount**", 1)
$block = [Collections.Generic.List[string]]::new()
$block.Add('<!-- BEGIN GENERATED SNAPSHOT -->')
$block.Add($snapshotLine)
$block.Add('')
$block.Add($existingLines[$separatorIndex - 1])
$block.Add($existingLines[$separatorIndex])
foreach ($name in $orderedMethods) {
    $block.Add("| $name | $($methodCounts[$name]) |")
}
$block.Add($totalLine)
$block.Add('<!-- END GENERATED SNAPSHOT -->')
$generatedBlock = $block -join $newline

$updated = [regex]::Replace($readme, $snapshotPattern, [Text.RegularExpressions.MatchEvaluator]{ param($match) $generatedBlock }, 1)

$referencePattern = '(?m)^(- \[[^\r\n]+\]\(API_REFERENCE\.md\) - )\d+( [^\r\n]+)$'
if (-not [regex]::IsMatch($updated, $referencePattern)) {
    throw 'Full reference count line is missing from README.md'
}
$updated = [regex]::Replace(
    $updated,
    $referencePattern,
    "`${1}$endpointCount`${2}",
    1
)

[IO.File]::WriteAllText($ReadmePath, $updated, (New-Object Text.UTF8Encoding($false)))
Write-Host "README updated: frontend $release, endpoints $endpointCount"
