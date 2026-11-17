# SignalScope Milestone 1: verify one real GDELT GKG 2.1 archive.
# Requirements: Windows PowerShell 5.1+ or PowerShell 7+, internet.
# Writes a downloaded ZIP to ./data; does not install anything.

$ErrorActionPreference = 'Stop'
$feedUrl = 'https://data.gdeltproject.org/gdeltv2/lastupdate.txt'

Write-Host '1. Reading GDELT live update list...'
$feed = (Invoke-WebRequest -Uri $feedUrl -TimeoutSec 30).Content
$line = @($feed -split '\r?\n' | Where-Object { $_ -match '\.gkg\.csv\.zip' }) | Select-Object -First 1
if (-not $line) { throw 'No GKG ZIP found in lastupdate.txt' }

$match = [regex]::Match($line, 'https?://\S+\.gkg\.csv\.zip')
if (-not $match.Success) { throw "Cannot extract GKG ZIP URL from: $line" }
$url = $match.Value -replace '^http://', 'https://'
Write-Host "GKG URL: $url"

$dataDir = Join-Path $PSScriptRoot 'data'
[System.IO.Directory]::CreateDirectory($dataDir) | Out-Null
$zipPath = Join-Path $dataDir ([System.IO.Path]::GetFileName($url))

Write-Host '2. Downloading one GKG archive...'
Invoke-WebRequest -Uri $url -OutFile $zipPath -TimeoutSec 120
Write-Host ("ZIP size: {0:N2} MB" -f ((Get-Item $zipPath).Length / 1MB))

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($zipPath)

$total = 0
$invalid = 0
$withOrganizations = 0
$nvidiaRows = 0
$exampleOrganizations = @()
$nvidiaSources = New-Object System.Collections.Generic.List[string]
try {
    $entry = $archive.Entries | Where-Object { $_.Name -match '\.csv$' } | Select-Object -First 1
    if (-not $entry) { throw 'ZIP has no CSV entry' }

    Write-Host "3. Scanning $($entry.Name) (no full extraction required)..."
    $reader = [System.IO.StreamReader]::new($entry.Open(), [System.Text.Encoding]::UTF8)
    try {
        while ($null -ne ($record = $reader.ReadLine())) {
            $fields = $record.Split([char]9) # GKG 2.1 is tab-delimited
            if ($fields.Length -lt 27) { $invalid++; continue }
            $total++

            $orgField = $fields[13] # 0-based index: V1ORGANIZATIONS
            if (-not [string]::IsNullOrWhiteSpace($orgField)) {
                $withOrganizations++
                if ($exampleOrganizations.Count -eq 0) {
                    $exampleOrganizations = @($orgField -split ';' | Where-Object { $_ } | Select-Object -First 8)
                }
            }

            if ($orgField -match '(?i)\bnvidia\b') {
                $nvidiaRows++
                if ($nvidiaSources.Count -lt 3) {
                    $nvidiaSources.Add($fields[4]) # V2DOCUMENTIDENTIFIER URL
                }
            }
        }
    }
    finally { $reader.Dispose() }
}
finally { $archive.Dispose() }

Write-Host ''
Write-Host '=== SignalScope GDELT smoke test ==='
Write-Host "Valid records:          $total"
Write-Host "Invalid/short records:  $invalid"
Write-Host "Records with companies: $withOrganizations"
Write-Host "NVIDIA mention records: $nvidiaRows"
Write-Host ('Example organizations: ' + ($exampleOrganizations -join ', '))
if ($nvidiaSources.Count -gt 0) {
    Write-Host 'Up to three NVIDIA source links:'
    foreach ($source in $nvidiaSources) { Write-Host "  $source" }
}
if ($total -gt 0 -and $withOrganizations -gt 0) {
    Write-Host 'PASS: real GKG data can be downloaded and parsed.'
    if ($nvidiaRows -eq 0) { Write-Host 'NOTE: no NVIDIA record in this 15-minute batch; test more batches in Milestone 2.' }
}
else {
    throw 'FAIL: no usable GKG rows or no organization names found.'
}
