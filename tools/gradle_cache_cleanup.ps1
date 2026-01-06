<#
PowerShell script to safely stop Gradle, back up and remove corrupted Gradle cache entries,
then run Flutter/Gradle clean and rebuild steps. Run from the project root.
Usage: 
  .\tools\gradle_cache_cleanup.ps1 [-Force]

If you run without -Force the script will prompt before deleting the cache folder.
#>
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Timestamp() { return (Get-Date).ToString('yyyyMMdd-HHmmss') }

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent
if (-not (Test-Path $projectRoot)) { $projectRoot = Get-Location }

Write-Host "Project root: $projectRoot"

# 1) Stop Gradle daemons (use wrapper if available)
$gradleWrapper = Join-Path $projectRoot "android\gradlew.bat"
if (Test-Path $gradleWrapper) {
    Write-Host "Stopping Gradle daemons via wrapper..."
    & $gradleWrapper --stop 2>&1 | Write-Host
} else {
    Write-Host "gradlew not found, attempting 'gradle --stop' (requires gradle on PATH)..."
    & gradle --stop 2>&1 | Write-Host
}

# 2) Backup then delete corrupted cache
$gradleCache = Join-Path $env:USERPROFILE ".gradle\caches"
$journalFile = Join-Path $gradleCache "journal-1\file-access.bin"
$backupRoot = Join-Path $env:USERPROFILE ".gradle_backups"
if (-not (Test-Path $backupRoot)) { New-Item -ItemType Directory -Path $backupRoot | Out-Null }

if (Test-Path $gradleCache) {
    $stamp = Timestamp
    $backup = Join-Path $backupRoot "caches-backup-$stamp"
    Write-Host "Backing up existing caches to: $backup"
    Move-Item -Path $gradleCache -Destination $backup -Force
    Write-Host "Backup complete."

    if (-not $Force) {
        $confirm = Read-Host "Caches were moved to backup. Proceed to recreate cache and run clean/rebuild? (Y/N)"
        if ($confirm -ne 'Y' -and $confirm -ne 'y') { Write-Host "Aborting per user request."; exit 1 }
    }
} else {
    Write-Host "No Gradle caches folder found at $gradleCache"
}

# 3) Recreate empty caches folder to avoid permission issues
if (-not (Test-Path $gradleCache)) { New-Item -ItemType Directory -Path $gradleCache | Out-Null }

# 4) Run Flutter clean / pub get / build (if flutter is available)
Write-Host "Running Flutter clean and pub get (requires flutter on PATH)..."
try {
    & flutter clean 2>&1 | Write-Host
    & flutter pub get 2>&1 | Write-Host
} catch {
    Write-Host "Flutter commands failed or Flutter not on PATH. You can run them manually later."
}

# 5) Optionally run Gradle clean/build in android folder
$androidDir = Join-Path $projectRoot "android"
if (Test-Path $androidDir) {
    Push-Location $androidDir
    Write-Host "Running Gradle clean in $androidDir"
    if (Test-Path "gradlew.bat") {
        & .\gradlew.bat clean 2>&1 | Write-Host
    } else {
        & gradle clean 2>&1 | Write-Host
    }
    Pop-Location
}

Write-Host "Cleanup script finished. If you still see Gradle cache errors, consider running 'chkdsk C: /F' as administrator, disabling antivirus, or setting a new GRADLE_USER_HOME and rebuilding."
