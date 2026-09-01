param(
    [string]$DonorApk = (Join-Path (Split-Path -Parent $PSScriptRoot) 'Moovies2.apk'),
    [string]$WorkRoot = (Join-Path (Split-Path -Parent $PSScriptRoot) 'apk-work'),
    [string]$DecodedDirName = 'moovies2-src',
    [string]$NewPackage = 'com.dude2714.moovies2',
    [string]$NewAppName = 'Moovies2'
)

$ErrorActionPreference = 'Stop'

function Resolve-Java {
    $java = Get-Command java -ErrorAction SilentlyContinue
    if ($java) { return $java.Source }

    $fallback = 'C:\Users\johns\scoop\apps\temurin17-jdk\current\bin\java.exe'
    if (Test-Path -LiteralPath $fallback) { return $fallback }

    throw 'java not found'
}

function Resolve-ApktoolJar {
    $fallback = 'C:\Users\johns\scoop\apps\apktool\current\apktool.jar'
    if (Test-Path -LiteralPath $fallback) { return $fallback }

    throw 'apktool jar not found'
}

function Update-TextFile {
    param(
        [string]$Path,
        [string]$OldPackageDot,
        [string]$NewPackageDot,
        [string]$OldPackageSlash,
        [string]$NewPackageSlash,
        [string]$AppName
    )

    $content = [System.IO.File]::ReadAllText($Path)
    $updated = $content.Replace($OldPackageDot, $NewPackageDot).Replace($OldPackageSlash, $NewPackageSlash)

    if ($Path.EndsWith('strings.xml', [System.StringComparison]::OrdinalIgnoreCase)) {
        $updated = [System.Text.RegularExpressions.Regex]::Replace(
            $updated,
            '<string name="app_name">.*?</string>',
            '<string name="app_name">' + $AppName + '</string>',
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )
    }

    if ($updated -ne $content) {
        [System.IO.File]::WriteAllText($Path, $updated)
    }
}

function Get-RewriteTargets {
    param(
        [string]$DecodedPath
    )

    $targets = New-Object System.Collections.Generic.List[string]

    foreach ($rootFile in 'AndroidManifest.xml', 'apktool.yml') {
        $rootPath = Join-Path $DecodedPath $rootFile
        if (Test-Path -LiteralPath $rootPath) {
            $targets.Add($rootPath)
        }
    }

    $candidateDirs = @(
        (Join-Path $DecodedPath 'res'),
        (Join-Path $DecodedPath 'smali'),
        (Join-Path $DecodedPath 'smali_classes2'),
        (Join-Path $DecodedPath 'smali_classes3'),
        (Join-Path $DecodedPath 'smali_classes4')
    )

    foreach ($dir in $candidateDirs) {
        if (-not (Test-Path -LiteralPath $dir)) {
            continue
        }

        Get-ChildItem -LiteralPath $dir -Recurse -File |
            Where-Object { $_.Extension -in '.xml', '.yml', '.smali', '.json', '.txt' } |
            ForEach-Object { $targets.Add($_.FullName) }
    }

    return $targets
}

function Move-PackageDirectory {
    param(
        [string]$DecodedPath,
        [string]$SourcePackageSlash,
        [string]$TargetPackageSlash
    )

    $movedAny = $false

    foreach ($smaliRootName in 'smali', 'smali_classes2', 'smali_classes3', 'smali_classes4') {
        $smaliRoot = Join-Path $DecodedPath $smaliRootName
        if (-not (Test-Path -LiteralPath $smaliRoot)) {
            continue
        }

        $sourcePackageDir = Join-Path $smaliRoot ($SourcePackageSlash -replace '/', '\\')
        if (-not (Test-Path -LiteralPath $sourcePackageDir)) {
            continue
        }

        $targetPackageDir = Join-Path $smaliRoot ($TargetPackageSlash -replace '/', '\\')
        $targetPackageParent = Split-Path -Parent $targetPackageDir
        New-Item -ItemType Directory -Path $targetPackageParent -Force | Out-Null
        Move-Item -LiteralPath $sourcePackageDir -Destination $targetPackageDir
        $movedAny = $true
    }

    if (-not $movedAny) {
        throw "Expected donor package directory not found under decoded smali roots for $SourcePackageSlash"
    }
}

function Write-ProgressLog {
    param(
        [string]$Path,
        [string]$Message
    )

    Add-Content -LiteralPath $Path -Value $Message
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$decodedPath = Join-Path $WorkRoot $DecodedDirName
$oldPackage = 'com.app.mlounge'
$oldPackageSlash = 'com/app/mlounge'
$newPackageSlash = $NewPackage.Replace('.', '/')
$progressLogPath = Join-Path $repoRoot 'fork-progress.txt'

Set-Content -LiteralPath $progressLogPath -Value 'START' -Encoding ascii

if (-not (Test-Path -LiteralPath $DonorApk)) {
    throw "Donor APK not found: $DonorApk"
}

New-Item -ItemType Directory -Path $WorkRoot -Force | Out-Null

if (Test-Path -LiteralPath $decodedPath) {
    Remove-Item -LiteralPath $decodedPath -Recurse -Force
}

$java = Resolve-Java
$apktoolJar = Resolve-ApktoolJar

& $java -jar $apktoolJar d -f $DonorApk -o $decodedPath | Out-Host
Write-ProgressLog -Path $progressLogPath -Message 'DECODE_COMPLETE'

$textFiles = Get-RewriteTargets -DecodedPath $decodedPath
Write-ProgressLog -Path $progressLogPath -Message ('REWRITE_TARGETS=' + $textFiles.Count)

foreach ($file in $textFiles) {
    try {
        Update-TextFile -Path $file -OldPackageDot $oldPackage -NewPackageDot $NewPackage -OldPackageSlash $oldPackageSlash -NewPackageSlash $newPackageSlash -AppName $NewAppName
    } catch {
        Write-ProgressLog -Path $progressLogPath -Message ('FAILED_FILE=' + $file)
        Write-ProgressLog -Path $progressLogPath -Message ('FAILED_REASON=' + $_.Exception.Message)
        throw
    }
}

Write-ProgressLog -Path $progressLogPath -Message 'REWRITE_COMPLETE'

Move-PackageDirectory -DecodedPath $decodedPath -SourcePackageSlash $oldPackageSlash -TargetPackageSlash $newPackageSlash
Write-ProgressLog -Path $progressLogPath -Message 'MOVE_COMPLETE'

$reportPath = Join-Path $repoRoot 'fork-report.txt'
$report = @"
DONOR_APK=$DonorApk
DECODED_DIR=$decodedPath
OLD_PACKAGE=$oldPackage
NEW_PACKAGE=$NewPackage
NEW_APP_NAME=$NewAppName
REWRITE_TARGETS=$($textFiles.Count)
"@.Trim()
[System.IO.File]::WriteAllText($reportPath, $report, [System.Text.Encoding]::ASCII)
Write-ProgressLog -Path $progressLogPath -Message 'REPORT_COMPLETE'

Write-Host 'Prepared Moovies2 fork workspace'
Write-Host ('- Donor APK: ' + $DonorApk)
Write-Host ('- Decoded dir: ' + $decodedPath)
Write-Host ('- New package: ' + $NewPackage)
Write-Host ('- New app name: ' + $NewAppName)