param(
    [string]$Serial = '0321418026779',
    [string]$PackageName = 'com.app.mlounge',
    [string]$OutputApk = 'Moovies2.apk',
    [string]$ReleaseVersion = 'shield-copy',
    [string]$Notes = 'Pulled from Shield source package',
    [switch]$AllowFallbackDownloadCopy
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

$pmPath = & $adb -s $Serial shell pm path $packageName 2>&1
$apkPathLine = $pmPath | Select-String '^package:' | Select-Object -First 1
if (-not $apkPathLine) {
    throw "Could not resolve APK path for package $PackageName"
}

$deviceApkPath = ($apkPathLine.ToString() -replace '^package:', '').Trim()

$pullFailed = $false
try {
    & $adb -s $Serial pull $deviceApkPath $targetApk | Out-Host
} catch {
    $pullFailed = $true
}

if ($AllowFallbackDownloadCopy -and ((-not (Test-Path -LiteralPath $targetApk)) -or $pullFailed)) {
    $fallbackApkPath = Get-AccessibleFallbackApk -AdbPath $adb -SerialNumber $Serial
    if ($fallbackApkPath) {
        $deviceApkPath = $fallbackApkPath
        & $adb -s $Serial pull $deviceApkPath $targetApk | Out-Host
    }
}

if (-not (Test-Path -LiteralPath $targetApk)) {
    throw "APK pull failed from source package $PackageName. Re-run with -AllowFallbackDownloadCopy only if you intentionally want the newest downloaded Cinema APK instead of the installed source package."
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
    notes = "$Notes ($PackageName)"
}
$release | ConvertTo-Json | Set-Content -LiteralPath $releaseFile -Encoding utf8

if (-not (Test-Path -LiteralPath $changelogFile)) {
    "# Changelog`r`n" | Set-Content -LiteralPath $changelogFile -Encoding utf8
}

$entry = @(
    "## $ReleaseVersion - $updatedUtc"
    "- APK: $OutputApk"
    "- Package: $PackageName"
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

$reportContent = @"
PACKAGE=$PackageName
APK_PATH=$deviceApkPath
OUTPUT_APK=$targetApk
SHA256=$sha
UPDATED_UTC=$updatedUtc
"@.Trim()
[System.IO.File]::WriteAllText($reportFile, $reportContent, [System.Text.Encoding]::ASCII)

Write-Host 'Pulled source package APK from Shield'
Write-Host ('- Package: ' + $PackageName)
Write-Host ('- Device path: ' + $deviceApkPath)
Write-Host ('- Output: ' + $targetApk)
Write-Host ('- SHA-256: ' + $sha)
