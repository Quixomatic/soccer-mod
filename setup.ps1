# Soccer Mod - Setup Script
# Downloads the latest SourceMod 1.12 compiler to .sourcemod-source/

$SM_VERSION = "1.12"
$SM_DIR = ".sourcemod-source"
$SM_DROP_URL = "https://sm.alliedmods.net/smdrop/$SM_VERSION"

Write-Host "Soccer Mod Setup" -ForegroundColor Cyan
Write-Host "================" -ForegroundColor Cyan

# Check if already set up
if (Test-Path "$SM_DIR/addons/sourcemod/scripting/spcomp.exe") {
    Write-Host "SourceMod compiler already exists at $SM_DIR/" -ForegroundColor Yellow
    $confirm = Read-Host "Re-download latest version? (y/N)"
    if ($confirm -ne "y") {
        Write-Host "Setup cancelled."
        exit 0
    }
    Remove-Item -Recurse -Force $SM_DIR
}

# Get the latest filename
Write-Host "Fetching latest SourceMod $SM_VERSION build info..." -ForegroundColor Gray
try {
    $latestFile = (Invoke-WebRequest -Uri "$SM_DROP_URL/sourcemod-latest-windows" -UseBasicParsing).Content.Trim()
} catch {
    Write-Host "ERROR: Failed to fetch latest version info from $SM_DROP_URL" -ForegroundColor Red
    exit 1
}

$downloadUrl = "$SM_DROP_URL/$latestFile"
$zipPath = "sourcemod-temp.zip"

Write-Host "Downloading $latestFile..." -ForegroundColor Gray
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
} catch {
    Write-Host "ERROR: Failed to download $downloadUrl" -ForegroundColor Red
    exit 1
}

# Extract
Write-Host "Extracting to $SM_DIR/..." -ForegroundColor Gray
New-Item -ItemType Directory -Force -Path $SM_DIR | Out-Null
Expand-Archive -Path $zipPath -DestinationPath $SM_DIR -Force

# Cleanup
Remove-Item $zipPath

# Verify
if (Test-Path "$SM_DIR/addons/sourcemod/scripting/spcomp.exe") {
    Write-Host ""
    Write-Host "Setup complete!" -ForegroundColor Green
    Write-Host "  Compiler: $SM_DIR/addons/sourcemod/scripting/spcomp.exe" -ForegroundColor Gray
    Write-Host "  Includes: $SM_DIR/addons/sourcemod/scripting/include/" -ForegroundColor Gray
    Write-Host ""
    Write-Host "You can now build with: npm run build" -ForegroundColor Cyan
} else {
    Write-Host "ERROR: Setup finished but spcomp.exe not found. Check the extracted files." -ForegroundColor Red
    exit 1
}
