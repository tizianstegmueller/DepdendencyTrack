# SBOM Generation Script
# Generiert SBOM-Dateien fuer Frontend und Backend

Write-Host "========================================"  -ForegroundColor Cyan
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
    Write-Host "SBOM-Verzeichnis erstellt: $sbomPath" -ForegroundColor Green
}

# Alte Artefakte bereinigen
$staleFiles = @(
    (Join-Path $sbomPath "bom.xml"),
    (Join-Path $sbomPath "backend-sbom.xml"),
    (Join-Path $sbomPath "backend-sbom.json")
)
foreach ($file in $staleFiles) {
    if (Test-Path $file) {
        Remove-Item $file -Force
    }
}

# Backend SBOM (.NET)
Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Backend SBOM (.NET)" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

$dotnetVersion = dotnet --version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Fehler: .NET SDK nicht gefunden" -ForegroundColor Red
    exit 1
}
Write-Host ".NET Version: $dotnetVersion" -ForegroundColor Green

$cdxInstalled = dotnet tool list -g | Select-String "cyclonedx"
if (-not $cdxInstalled) {
    Write-Host "Installiere CycloneDX fuer .NET..." -ForegroundColor Yellow
    dotnet tool install --global CycloneDX
    if ($LASTEXITCODE -ne 0) {
        Write-Host "CycloneDX Installation fehlgeschlagen" -ForegroundColor Red
        exit 1
    }
}
Write-Host "CycloneDX fuer .NET installiert" -ForegroundColor Green

$backendProject = Join-Path $rootPath "Shop\Backend\ShopAPI.csproj"
Write-Host "Generiere Backend SBOM..." -ForegroundColor Yellow
Set-Location $rootPath

dotnet CycloneDX $backendProject -o $sbomPath

Write-Host "Erstellte Dateien im SBOM-Verzeichnis:" -ForegroundColor Cyan
Get-ChildItem $sbomPath | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }

$bomXmlFile = Join-Path $sbomPath "bom.xml"
$shopApiBomXmlFile = Join-Path $sbomPath "ShopAPI.bom.xml"
$backendSbomFile = Join-Path $sbomPath "backend-sbom.xml"

if (Test-Path $bomXmlFile) {
    Move-Item -Path $bomXmlFile -Destination $backendSbomFile -Force
    Write-Host "Umbenannt: bom.xml -> backend-sbom.xml" -ForegroundColor Cyan
} elseif (Test-Path $shopApiBomXmlFile) {
    Move-Item -Path $shopApiBomXmlFile -Destination $backendSbomFile -Force
    Write-Host "Umbenannt: ShopAPI.bom.xml -> backend-sbom.xml" -ForegroundColor Cyan
} else {
    Write-Host "Backend-BOM-Datei (XML) wurde nicht gefunden" -ForegroundColor Red
}

if ($LASTEXITCODE -eq 0 -and (Test-Path $backendSbomFile)) {
    Write-Host "Backend SBOM erstellt: backend-sbom.xml" -ForegroundColor Green
} else {
    Write-Host "Backend SBOM Generierung fehlgeschlagen" -ForegroundColor Red
}

# Frontend SBOM (React/Node.js)
Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Frontend SBOM (React/Node.js)" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

$nodeVersion = node --version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Fehler: Node.js nicht gefunden" -ForegroundColor Red
    exit 1
}
Write-Host "Node.js Version: $nodeVersion" -ForegroundColor Green

$npmVersion = npm --version 2>$null
Write-Host "npm Version: $npmVersion" -ForegroundColor Green

$frontendPath = Join-Path $rootPath "Shop\Frontend"
if (-not (Test-Path (Join-Path $frontendPath "node_modules"))) {
    Write-Host "Installiere Frontend Dependencies..." -ForegroundColor Yellow
    Set-Location $frontendPath
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "npm install fehlgeschlagen" -ForegroundColor Red
        exit 1
    }
}
Write-Host "Frontend Dependencies vorhanden" -ForegroundColor Green

$cdxNpmVersion = npm list -g @cyclonedx/cyclonedx-npm --depth=0 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Installiere CycloneDX fuer NPM..." -ForegroundColor Yellow
    npm install -g @cyclonedx/cyclonedx-npm
    if ($LASTEXITCODE -ne 0) {
        Write-Host "CycloneDX NPM Installation fehlgeschlagen" -ForegroundColor Red
        exit 1
    }
}
Write-Host "CycloneDX fuer NPM installiert" -ForegroundColor Green

Write-Host "Generiere Frontend SBOM..." -ForegroundColor Yellow
Set-Location $frontendPath

$frontendSbomPath = Join-Path $sbomPath "frontend-sbom.json"
npx @cyclonedx/cyclonedx-npm --output-file $frontendSbomPath --output-format json

if ($LASTEXITCODE -eq 0 -and (Test-Path $frontendSbomPath)) {
    Write-Host "Frontend SBOM erstellt: frontend-sbom.json" -ForegroundColor Green
    $frontendJson = Get-Content $frontendSbomPath | ConvertFrom-Json
    $frontendComponents = $frontendJson.components.Count
    Write-Host "$frontendComponents Komponenten gefunden" -ForegroundColor Cyan
} else {
    Write-Host "Frontend SBOM Generierung fehlgeschlagen" -ForegroundColor Red
    if (-not (Test-Path $frontendSbomPath)) {
        Write-Host "Datei wurde nicht erstellt: $frontendSbomPath" -ForegroundColor Red
    }
}

# Zusammenfassung
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Zusammenfassung" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$backendSbomExists = Test-Path (Join-Path $sbomPath "backend-sbom.xml")
$frontendSbomExists = Test-Path (Join-Path $sbomPath "frontend-sbom.json")

Write-Host "SBOM-Verzeichnis: $sbomPath" -ForegroundColor White
Write-Host ""
Write-Host "Generierte Dateien:" -ForegroundColor White
if ($backendSbomExists) {
    Write-Host "  OK: backend-sbom.xml" -ForegroundColor Green
} else {
    Write-Host "  FEHLER: backend-sbom.xml" -ForegroundColor Red
}

if ($frontendSbomExists) {
    Write-Host "  OK: frontend-sbom.json" -ForegroundColor Green
} else {
    Write-Host "  FEHLER: frontend-sbom.json" -ForegroundColor Red
}

Write-Host ""
if ($backendSbomExists -and $frontendSbomExists) {
    Write-Host "Alle SBOM-Dateien erfolgreich erstellt!" -ForegroundColor Green
} else {
    Write-Host "Einige SBOM-Dateien konnten nicht erstellt werden." -ForegroundColor Yellow
}

# Upload zu Dependency-Track
Write-Host "" 
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Dependency-Track Upload" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$dependencyTrackUrl = if ($env:DTRACK_URL) { $env:DTRACK_URL.TrimEnd('/') } else { "http://localhost:8081" }
$dependencyTrackApiKey = "odt_gtZWN1RP_djZkrWdl0ukPlRZi1rrGjH1gKNnKmCLE"
$projectVersion = if ($env:DTRACK_PROJECT_VERSION) { $env:DTRACK_PROJECT_VERSION } else { "1.0.0" }
$backendProjectName = if ($env:DTRACK_BACKEND_PROJECT_NAME) { $env:DTRACK_BACKEND_PROJECT_NAME } else { "Shop-Backend" }
$frontendProjectName = if ($env:DTRACK_FRONTEND_PROJECT_NAME) { $env:DTRACK_FRONTEND_PROJECT_NAME } else { "Shop-Frontend" }

function Upload-SbomToDependencyTrack {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$ProjectVersion,
        [Parameter(Mandatory = $true)][string]$DependencyTrackUrl,
        [Parameter(Mandatory = $true)][string]$ApiKey
    )

    if (-not (Test-Path $FilePath)) {
        Write-Host "SBOM-Datei nicht gefunden: $FilePath" -ForegroundColor Red
        return $false
    }

    try {
        $bomBytes = [System.IO.File]::ReadAllBytes($FilePath)
        $bomBase64 = [System.Convert]::ToBase64String($bomBytes)

        $payload = @{
            autoCreate = $true
            projectName = $ProjectName
            projectVersion = $ProjectVersion
            bom = $bomBase64
        } | ConvertTo-Json -Depth 5

        $headers = @{
            "X-Api-Key" = $ApiKey
        }

        $response = Invoke-RestMethod -Method Put -Uri "$DependencyTrackUrl/api/v1/bom" -Headers $headers -ContentType "application/json" -Body $payload

        if ($response.token) {
            Write-Host "Upload erfolgreich fuer '$ProjectName' (Token: $($response.token))" -ForegroundColor Green
        } else {
            Write-Host "Upload erfolgreich fuer '$ProjectName'" -ForegroundColor Green
        }
        return $true
    }
    catch {
        Write-Host "Upload fehlgeschlagen fuer '$ProjectName': $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

if ([string]::IsNullOrWhiteSpace($dependencyTrackApiKey)) {
    Write-Host "Kein API Key gefunden. Setzen Sie DTRACK_API_KEY, um Uploads zu aktivieren." -ForegroundColor Yellow
    Write-Host "Dependency-Track URL: $dependencyTrackUrl" -ForegroundColor Gray
} else {
    Write-Host "Dependency-Track URL: $dependencyTrackUrl" -ForegroundColor White
    Write-Host "Lade SBOM-Dateien hoch..." -ForegroundColor Yellow

    $uploadBackendOk = $false
    $uploadFrontendOk = $false

    if ($backendSbomExists) {
        $uploadBackendOk = Upload-SbomToDependencyTrack -FilePath (Join-Path $sbomPath "backend-sbom.xml") -ProjectName $backendProjectName -ProjectVersion $projectVersion -DependencyTrackUrl $dependencyTrackUrl -ApiKey $dependencyTrackApiKey
    } else {
        Write-Host "Backend SBOM fehlt, Upload uebersprungen." -ForegroundColor Yellow
    }

    if ($frontendSbomExists) {
        $uploadFrontendOk = Upload-SbomToDependencyTrack -FilePath (Join-Path $sbomPath "frontend-sbom.json") -ProjectName $frontendProjectName -ProjectVersion $projectVersion -DependencyTrackUrl $dependencyTrackUrl -ApiKey $dependencyTrackApiKey
    } else {
        Write-Host "Frontend SBOM fehlt, Upload uebersprungen." -ForegroundColor Yellow
    }

    if (($backendSbomExists -and -not $uploadBackendOk) -or ($frontendSbomExists -and -not $uploadFrontendOk)) {
        Write-Host "Mindestens ein Upload ist fehlgeschlagen." -ForegroundColor Yellow
    } elseif ($backendSbomExists -or $frontendSbomExists) {
        Write-Host "Alle verfuegbaren SBOM-Dateien wurden hochgeladen." -ForegroundColor Green
    }
}

Set-Location $startLocation

Write-Host ""
Write-Host "Weitere Informationen: https://docs.dependencytrack.org/" -ForegroundColor Cyan
