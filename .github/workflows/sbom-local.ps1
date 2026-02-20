# ========================================
# Lokale SBOM-Generierung für Frontend & Backend
# ========================================
# 
# Dieses Script generiert SBOM-Dateien lokal auf Ihrem Rechner
# ohne GitHub Actions zu benötigen.
#

param(
    [switch]$UploadToDTrack = $false,
    [string]$DTrackUrl = "http://localhost:8081",
    [string]$DTrackApiKey = ""
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SBOM Generation Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Continue"
$startLocation = Get-Location
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootPath = Split-Path -Parent (Split-Path -Parent $scriptPath)
$sbomPath = Join-Path $rootPath "sbom"

# SBOM-Verzeichnis erstellen
if (-not (Test-Path $sbomPath)) {
    New-Item -ItemType Directory -Path $sbomPath -Force | Out-Null
    Write-Host "✓ SBOM-Verzeichnis erstellt: $sbomPath" -ForegroundColor Green
}

# ========================================
# Backend SBOM (.NET)
# ========================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Backend SBOM (.NET)" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

# Prüfe .NET Installation
$dotnetVersion = dotnet --version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ .NET SDK nicht gefunden. Bitte installieren Sie .NET SDK." -ForegroundColor Red
    exit 1
}
Write-Host "✓ .NET Version: $dotnetVersion" -ForegroundColor Green

# Prüfe CycloneDX Tool
$cdxInstalled = dotnet tool list -g | Select-String "cyclonedx"
if (-not $cdxInstalled) {
    Write-Host "→ Installiere CycloneDX für .NET..." -ForegroundColor Yellow
    dotnet tool install --global CycloneDX
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ CycloneDX Installation fehlgeschlagen" -ForegroundColor Red
        exit 1
    }
}
Write-Host "✓ CycloneDX für .NET installiert" -ForegroundColor Green

# Generiere Backend SBOM
$backendProject = Join-Path $rootPath "Shop\Backend\ShopAPI.csproj"
Write-Host "→ Generiere Backend SBOM..." -ForegroundColor Yellow
Set-Location $rootPath

dotnet CycloneDX $backendProject -o $sbomPath

# Zeige erstellte Dateien
Write-Host "  → Erstellte Dateien im SBOM-Verzeichnis:" -ForegroundColor Cyan
Get-ChildItem $sbomPath | ForEach-Object { Write-Host "     - $($_.Name)" -ForegroundColor Gray }

# Umbenennen von bom.json zu backend-sbom.json
$bomFile = Join-Path $sbomPath "bom.json"
$shopApiBomFile = Join-Path $sbomPath "ShopAPI.bom.json"
$backendSbomFile = Join-Path $sbomPath "backend-sbom.json"

if (Test-Path $bomFile) {
    Move-Item -Path $bomFile -Destination $backendSbomFile -Force
    Write-Host "  → Umbenannt: bom.json -> backend-sbom.json" -ForegroundColor Cyan
} elseif (Test-Path $shopApiBomFile) {
    Move-Item -Path $shopApiBomFile -Destination $backendSbomFile -Force
    Write-Host "  → Umbenannt: ShopAPI.bom.json -> backend-sbom.json" -ForegroundColor Cyan
} else {
    # Suche nach einer beliebigen .json Datei
    $jsonFiles = Get-ChildItem -Path $sbomPath -Filter "*.json"
    if ($jsonFiles.Count -gt 0) {
        $firstJson = $jsonFiles[0]
        Move-Item -Path $firstJson.FullName -Destination $backendSbomFile -Force
        Write-Host "  → Umbenannt: $($firstJson.Name) -> backend-sbom.json" -ForegroundColor Cyan
    }
}

if ($LASTEXITCODE -eq 0 -and (Test-Path $backendSbomFile)) {
    Write-Host "✓ Backend SBOM erstellt: backend-sbom.json" -ForegroundColor Green
    $backendJson = Get-Content $backendSbomFile | ConvertFrom-Json
    $backendComponents = $backendJson.components.Count
    Write-Host "  → $backendComponents Komponenten gefunden" -ForegroundColor Cyan
} else {
    Write-Host "❌ Backend SBOM Generierung fehlgeschlagen" -ForegroundColor Red
}

# ========================================
# Frontend SBOM (React/Node.js)
# ========================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Frontend SBOM (React/Node.js)" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

# Prüfe Node.js Installation
$nodeVersion = node --version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Node.js nicht gefunden. Bitte installieren Sie Node.js." -ForegroundColor Red
    exit 1
}
Write-Host "✓ Node.js Version: $nodeVersion" -ForegroundColor Green

# Prüfe npm Installation
$npmVersion = npm --version 2>$null
Write-Host "✓ npm Version: $npmVersion" -ForegroundColor Green

# Prüfe/Installiere Dependencies
$frontendPath = Join-Path $rootPath "Shop\Frontend"
if (-not (Test-Path (Join-Path $frontendPath "node_modules"))) {
    Write-Host "→ Installiere Frontend Dependencies..." -ForegroundColor Yellow
    Set-Location $frontendPath
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ npm install fehlgeschlagen" -ForegroundColor Red
        exit 1
    }
}
Write-Host "✓ Frontend Dependencies vorhanden" -ForegroundColor Green

# Prüfe CycloneDX NPM
$cdxNpmVersion = npm list -g @cyclonedx/cyclonedx-npm --depth=0 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "→ Installiere CycloneDX für NPM..." -ForegroundColor Yellow
    npm install -g @cyclonedx/cyclonedx-npm
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ CycloneDX NPM Installation fehlgeschlagen" -ForegroundColor Red
        exit 1
    }
}
Write-Host "✓ CycloneDX für NPM installiert" -ForegroundColor Green

# Generiere Frontend SBOM
Write-Host "→ Generiere Frontend SBOM..." -ForegroundColor Yellow
Set-Location $frontendPath

$frontendSbomPath = Join-Path $sbomPath "frontend-sbom.json"
npx @cyclonedx/cyclonedx-npm --output-file $frontendSbomPath --output-format json

Write-Host "  → Prüfe ob Datei erstellt wurde..." -ForegroundColor Cyan

if ($LASTEXITCODE -eq 0 -and (Test-Path $frontendSbomPath)) {
    Write-Host "✓ Frontend SBOM erstellt: frontend-sbom.json" -ForegroundColor Green
    $frontendJson = Get-Content $frontendSbomPath | ConvertFrom-Json
    $frontendComponents = $frontendJson.components.Count
    Write-Host "  → $frontendComponents Komponenten gefunden" -ForegroundColor Cyan
} else {
    Write-Host "❌ Frontend SBOM Generierung fehlgeschlagen" -ForegroundColor Red
    if (-not (Test-Path $frontendSbomPath)) {
        Write-Host "  → Datei wurde nicht erstellt: $frontendSbomPath" -ForegroundColor Red
    }
}

# ========================================
# Upload zu Dependency-Track (Optional)
# ========================================
if ($UploadToDTrack) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "Upload zu Dependency-Track" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    
    if ([string]::IsNullOrEmpty($DTrackApiKey)) {
        Write-Host "❌ API-Key fehlt. Verwenden Sie -DTrackApiKey Parameter." -ForegroundColor Red
    } else {
        # Backend SBOM hochladen
        $backendSbomFile = Join-Path $sbomPath "backend-sbom.json"
        if (Test-Path $backendSbomFile) {
            Write-Host "→ Lade Backend SBOM hoch..." -ForegroundColor Yellow
            
            $boundary = [System.Guid]::NewGuid().ToString()
            $headers = @{
                "X-Api-Key" = $DTrackApiKey
                "Content-Type" = "multipart/form-data; boundary=$boundary"
            }
            
            $body = @"
--$boundary
Content-Disposition: form-data; name="autoCreate"

true
--$boundary
Content-Disposition: form-data; name="projectName"

Shop-Backend
--$boundary
Content-Disposition: form-data; name="projectVersion"

1.0.0
--$boundary
Content-Disposition: form-data; name="bom"; filename="backend-sbom.json"
Content-Type: application/json

$(Get-Content $backendSbomFile -Raw)
--$boundary--
"@
            
            try {
                $response = Invoke-RestMethod -Uri "$DTrackUrl/api/v1/bom" -Method Post -Headers $headers -Body $body
                Write-Host "✓ Backend SBOM hochgeladen" -ForegroundColor Green
            } catch {
                Write-Host "❌ Backend SBOM Upload fehlgeschlagen: $_" -ForegroundColor Red
            }
        }
        
        # Frontend SBOM hochladen
        $frontendSbomFile = Join-Path $sbomPath "frontend-sbom.json"
        if (Test-Path $frontendSbomFile) {
            Write-Host "→ Lade Frontend SBOM hoch..." -ForegroundColor Yellow
            
            $boundary = [System.Guid]::NewGuid().ToString()
            $headers = @{
                "X-Api-Key" = $DTrackApiKey
                "Content-Type" = "multipart/form-data; boundary=$boundary"
            }
            
            $body = @"
--$boundary
Content-Disposition: form-data; name="autoCreate"

true
--$boundary
Content-Disposition: form-data; name="projectName"

Shop-Frontend
--$boundary
Content-Disposition: form-data; name="projectVersion"

1.0.0
--$boundary
Content-Disposition: form-data; name="bom"; filename="frontend-sbom.json"
Content-Type: application/json

$(Get-Content $frontendSbomFile -Raw)
--$boundary--
"@
            
            try {
                $response = Invoke-RestMethod -Uri "$DTrackUrl/api/v1/bom" -Method Post -Headers $headers -Body $body
                Write-Host "✓ Frontend SBOM hochgeladen" -ForegroundColor Green
            } catch {
                Write-Host "❌ Frontend SBOM Upload fehlgeschlagen: $_" -ForegroundColor Red
            }
        }
    }
}

# ========================================
# Zusammenfassung
# ========================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Zusammenfassung" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$backendSbomExists = Test-Path (Join-Path $sbomPath "backend-sbom.json")
$frontendSbomExists = Test-Path (Join-Path $sbomPath "frontend-sbom.json")

Write-Host "SBOM-Verzeichnis: $sbomPath" -ForegroundColor White
Write-Host ""
Write-Host "Generierte Dateien:" -ForegroundColor White
if ($backendSbomExists) {
    Write-Host "  ✓ backend-sbom.json" -ForegroundColor Green
} else {
    Write-Host "  ❌ backend-sbom.json" -ForegroundColor Red
}

if ($frontendSbomExists) {
    Write-Host "  ✓ frontend-sbom.json" -ForegroundColor Green
} else {
    Write-Host "  ❌ frontend-sbom.json" -ForegroundColor Red
}

Write-Host ""
if ($backendSbomExists -and $frontendSbomExists) {
    Write-Host "🎉 Alle SBOM-Dateien erfolgreich erstellt!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Einige SBOM-Dateien konnten nicht erstellt werden." -ForegroundColor Yellow
}

# Zurück zum Startverzeichnis
Set-Location $startLocation

Write-Host ""
Write-Host "Weitere Informationen: https://docs.dependencytrack.org/" -ForegroundColor Cyan
