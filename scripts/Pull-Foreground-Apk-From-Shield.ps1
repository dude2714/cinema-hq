param(
    [string]$Serial = '0321418026779',
    [string]$OutputApk = 'Moovies2.apk',
    [string]$ReleaseVersion = 'shield-copy',
    [string]$Notes = 'Pulled from Shield foreground app'
)

$ErrorActionPreference = 'Stop'

function Resolve-Adb {
    $adb = Get-Command adb -ErrorAction SilentlyContinue
    if ($adb) { return $adb.Source }

    $fallback = 'C:\Users\johns\AppData\Local\Microsoft\WinGet\Packages\Google.PlatformTools_Microsoft.Winget.Source_8wekyb3d8bbwe\platform-tools\adb.exe'
    if (Test-Path -LiteralPath $fallback) { return $fallback }

    throw 'adb not found'
}

function Get-AccessibleFallbackApk {
    param(
        [string]$AdbPath,
        [string]$SerialNumber
    )

    $candidateDirs = @(
        '/sdcard/Download/Downloader',
        '/sdcard/Download'
    )

    foreach ($dir in $candidateDirs) {
        $listing = & $AdbPath -s $SerialNumber shell ls -t $dir 2>$null
        if (-not $listing) {
            continue
        }

        $match = $listing |
            ForEach-Object { $_.ToString().Trim() } |
            Where-Object { $_ -match '(?i)(^cinema.*\.apk$|^cinemahd.*\.apk$)' } |
            Select-Object -First 1

        if ($match) {
            return ($dir.TrimEnd('/') + '/' + $match)
        }
    }

    return $null
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$targetApk = Join-Path $repoRoot $OutputApk
$releaseFile = Join-Path $repoRoot 'release.json'
$changelogFile = Join-Path $repoRoot 'CHANGELOG.md'
$reportFile = Join-Path $repoRoot 'pull-from-shield-report.txt'
$adb = Resolve-Adb

$top = & $adb -s $Serial shell dumpsys activity activities 2>&1
$topLine = $top | Select-String 'mResumedActivity:' | Select-Object -First 1
if (-not $topLine) {
    throw 'Could not determine foreground activity from Shield.'
}

$match = [regex]::Match($topLine.ToString(), 'u\d+\s+([A-Za-z0-9._$]+)/')
if (-not $match.Success) {
    throw 'Could not parse package name from foreground activity.'
}

$packageName = $match.Groups[1].Value
$pmPath = & $adb -s $Serial shell pm path $packageName 2>&1
$apkPathLine = $pmPath | Select-String '^package:' | Select-Object -First 1
if (-not $apkPathLine) {
    throw "Could not resolve APK path for package $packageName"
}

$deviceApkPath = ($apkPathLine.ToString() -replace '^package:', '').Trim()

$pullFailed = $false
try {
    & $adb -s $Serial pull $deviceApkPath $targetApk | Out-Host
} catch {
    $pullFailed = $true
}

if ((-not (Test-Path -LiteralPath $targetApk)) -or $pullFailed) {
    $fallbackApkPath = Get-AccessibleFallbackApk -AdbPath $adb -SerialNumber $Serial
    if ($fallbackApkPath) {
        $deviceApkPath = $fallbackApkPath
        & $adb -s $Serial pull $deviceApkPath $targetApk | Out-Host
    }
}

if (-not (Test-Path -LiteralPath $targetApk)) {
    throw "APK pull failed: $targetApk"
}

$apk = Get-Item -LiteralPath $targetApk
$sha = (Get-FileHash -LiteralPath $targetApk -Algorithm SHA256).Hash
$updatedUtc = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')

$release = [ordered]@{
    version = $ReleaseVersion
    updatedUtc = $updatedUtc
    apkFile = $OutputApk
    sizeBytes = [int64]$apk.Length
    sha256 = $sha
    notes = "$Notes ($packageName)"
}
$release | ConvertTo-Json | Set-Content -LiteralPath $releaseFile -Encoding utf8

if (-not (Test-Path -LiteralPath $changelogFile)) {
    "# Changelog`r`n" | Set-Content -LiteralPath $changelogFile -Encoding utf8
}

$entry = @(
    "## $ReleaseVersion - $updatedUtc"
    "- APK: $OutputApk"
    "- Package: $packageName"
    "- Size: $($apk.Length) bytes"
    "- SHA-256: $sha"
    "- Notes: $Notes"
)

$existing = Get-Content -LiteralPath $changelogFile -Raw
$header = "# Changelog`r`n"
if ($existing.StartsWith($header)) {
    $body = $existing.Substring($header.Length).TrimStart("`r", "`n")
    $newContent = $header + "`r`n" + ($entry -join "`r`n") + "`r`n`r`n" + $body + "`r`n"
} else {
    $newContent = "# Changelog`r`n`r`n" + ($entry -join "`r`n") + "`r`n"
}
Set-Content -LiteralPath $changelogFile -Value $newContent -Encoding utf8

@(
    'PACKAGE=' + $packageName,
    'APK_PATH=' + $deviceApkPath,
    'OUTPUT_APK=' + $targetApk,
    'SHA256=' + $sha,
    'UPDATED_UTC=' + $updatedUtc
) | Set-Content -LiteralPath $reportFile -Encoding ascii

Write-Host 'Pulled foreground APK from Shield'
Write-Host ('- Package: ' + $packageName)
Write-Host ('- Device path: ' + $deviceApkPath)
Write-Host ('- Output: ' + $targetApk)
Write-Host ('- SHA-256: ' + $sha)
