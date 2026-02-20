# 📋 SBOM Pipeline Dokumentation

Dieses Projekt enthält automatisierte Pipelines zur Generierung von SBOM (Software Bill of Materials) Dateien für Frontend und Backend.

## 🎯 Was ist ein SBOM?

Ein Software Bill of Materials (SBOM) ist eine strukturierte Liste aller Komponenten, Bibliotheken und Abhängigkeiten in Ihrer Software. Es ist essenziell für:
- **Sicherheitsanalysen** – Identifizierung bekannter Schwachstellen
- **Lizenz-Compliance** – Überprüfung von Softwarelizenzen
- **Supply Chain Security** – Transparenz über Software-Abhängigkeiten
- **Regulatory Requirements** – Erfüllung von Standards wie NTIA oder Executive Order 14028

## 📦 Unterstützte Formate

Die Pipeline generiert SBOMs im **CycloneDX Format** (JSON), welches:
- Von Dependency-Track nativ unterstützt wird
- Industry-Standard für SBOM ist
- OWASP-Projekt ist

## 🚀 Verwendung

### Option 1: GitHub Actions (Automatisch)

Die Pipeline läuft automatisch bei:
- **Push** auf `main`, `master` oder `develop` Branch
- **Pull Requests** zu diesen Branches
- **Täglich um 2:00 Uhr UTC** (Scheduled)
- **Manuell** über GitHub Actions UI

#### Setup:

1. Pushen Sie Ihren Code zu GitHub
2. Die Workflow-Datei ist bereits unter [.github/workflows/generate-sbom.yml](.github/workflows/generate-sbom.yml)
3. SBOMs werden automatisch als Artifacts gespeichert

#### Artifacts downloaden:

1. Gehen Sie zu **Actions** → **Generate SBOM** Workflow
2. Wählen Sie einen Run aus
3. Unter **Artifacts** finden Sie:
   - `backend-sbom` - Backend SBOM
   - `frontend-sbom` - Frontend SBOM
   - `all-sboms` - Beide zusammen

### Option 2: Lokal mit PowerShell Script

Für lokale Entwicklung oder wenn Sie kein GitHub verwenden:

```powershell
# Navigieren Sie zum Projektverzeichnis
cd c:\Users\tse\source\repos\DepdendencyTrack

# Script ausführbar machen (einmalig)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# SBOM generieren
.\.github\workflows\sbom-local.ps1
```

#### Mit Upload zu Dependency-Track:

```powershell
# API-Key aus Dependency-Track holen (siehe unten)
$apiKey = "dein-api-key-hier"

# SBOM generieren und hochladen
.\.github\workflows\sbom-local.ps1 -UploadToDTrack -DTrackApiKey $apiKey
```

#### Weitere Optionen:

```powershell
# Custom Dependency-Track URL
.\.github\workflows\sbom-local.ps1 `
    -UploadToDTrack `
    -DTrackUrl "http://your-server:8081" `
    -DTrackApiKey $apiKey
```

### Option 3: Manuell mit Tools

#### Backend SBOM (.NET):

```powershell
# CycloneDX Tool installieren
dotnet tool install --global CycloneDX

# SBOM generieren
cd Backend
dotnet CycloneDX ShopAPI.csproj -o ../sbom -f backend-sbom.json --json
```

#### Frontend SBOM (React/Node.js):

```powershell
# CycloneDX NPM installieren
npm install -g @cyclonedx/cyclonedx-npm

# SBOM generieren
cd Frontend
cyclonedx-npm --output-file ../sbom/frontend-sbom.json --output-format json
```

## 📤 Upload zu Dependency-Track

### 1. API-Key erstellen

1. Öffnen Sie Dependency-Track: http://localhost:8080
2. Login mit `admin` / `admin`
3. Gehen Sie zu **Administration** → **Access Management** → **Teams**
4. Wählen Sie ein Team oder erstellen Sie ein neues
5. Klicken Sie auf **API Keys** → **Create API Key**
6. Kopieren Sie den Key

### 2. GitHub Secrets einrichten (für GitHub Actions)

1. Gehen Sie zu Ihrem GitHub Repository → **Settings** → **Secrets and variables** → **Actions**
2. Erstellen Sie folgende Secrets:
   - `DTRACK_URL`: `http://your-dependency-track-url:8081`
   - `DTRACK_API_KEY`: Ihr API Key

3. Aktivieren Sie den Upload in [.github/workflows/generate-sbom.yml](.github/workflows/generate-sbom.yml):
   ```yaml
   - name: Upload Backend SBOM to Dependency-Track
     if: true  # Ändern von 'false' zu 'true'
   ```

### 3. Manueller Upload mit cURL

```powershell
# Backend SBOM hochladen
curl -X POST "http://localhost:8081/api/v1/bom" `
  -H "Content-Type: multipart/form-data" `
  -H "X-Api-Key: your-api-key" `
  -F "autoCreate=true" `
  -F "projectName=Shop-Backend" `
  -F "projectVersion=1.0.0" `
  -F "bom=@sbom/backend-sbom.json"

# Frontend SBOM hochladen
curl -X POST "http://localhost:8081/api/v1/bom" `
  -H "Content-Type: multipart/form-data" `
  -H "X-Api-Key: your-api-key" `
  -F "autoCreate=true" `
  -F "projectName=Shop-Frontend" `
  -F "projectVersion=1.0.0" `
  -F "bom=@sbom/frontend-sbom.json"
```

## 📁 Generierte Dateien

Nach der Ausführung finden Sie die SBOMs unter:

```
DepdendencyTrack/
└── sbom/
    ├── backend-sbom.json    # .NET Backend SBOM
    └── frontend-sbom.json   # React Frontend SBOM
```

### SBOM-Struktur (CycloneDX)

Jede SBOM-Datei enthält:
- **metadata**: Informationen über die Erstellung
- **components**: Liste aller Abhängigkeiten mit:
  - Name, Version, Lizenz
  - Package URL (PURL)
  - Hashes (falls verfügbar)
- **dependencies**: Abhängigkeitsbaum

## 🔍 SBOM analysieren

### Mit jq (JSON Query Tool)

```powershell
# Anzahl der Komponenten
jq '.components | length' sbom/backend-sbom.json

# Alle Komponenten-Namen
jq '.components[].name' sbom/frontend-sbom.json

# Komponenten mit bekannten Schwachstellen
jq '.components[] | select(.vulnerabilities)' sbom/backend-sbom.json

# Lizenzen auflisten
jq '.components[].licenses' sbom/frontend-sbom.json
```

### Mit Dependency-Track

1. Upload SBOM (siehe oben)
2. Navigieren Sie zu **Projects**
3. Wählen Sie Ihr Projekt
4. Sehen Sie:
   - **Components**: Alle Abhängigkeiten
   - **Vulnerabilities**: Bekannte Schwachstellen
   - **License Compliance**: Lizenz-Risiken
   - **Policy Violations**: Richtlinienverstöße
   - **Metrics**: Risiko-Scores

## 🔄 Integration in CI/CD

### Azure DevOps

```yaml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

steps:
  - task: UseDotNet@2
    inputs:
      version: '9.0.x'
  
  - task: NodeTool@0
    inputs:
      versionSpec: '20.x'
  
  - script: |
      dotnet tool install --global CycloneDX
      dotnet CycloneDX Backend/ShopAPI.csproj -o sbom -f backend-sbom.json --json
    displayName: 'Generate Backend SBOM'
  
  - script: |
      npm install -g @cyclonedx/cyclonedx-npm
      cd Frontend
      cyclonedx-npm --output-file ../sbom/frontend-sbom.json
    displayName: 'Generate Frontend SBOM'
  
  - task: PublishPipelineArtifact@1
    inputs:
      targetPath: 'sbom'
      artifactName: 'sbom-files'
```

### GitLab CI

```yaml
generate-sbom:
  stage: build
  image: mcr.microsoft.com/dotnet/sdk:9.0
  before_script:
    - apt-get update && apt-get install -y nodejs npm curl
  script:
    - dotnet tool install --global CycloneDX
    - dotnet CycloneDX Backend/ShopAPI.csproj -o sbom -f backend-sbom.json --json
    - npm install -g @cyclonedx/cyclonedx-npm
    - cd Frontend && cyclonedx-npm --output-file ../sbom/frontend-sbom.json
  artifacts:
    paths:
      - sbom/*.json
    expire_in: 90 days
```

## 🛠️ Troubleshooting

### Problem: "dotnet tool not found"

```powershell
# Überprüfen Sie die PATH-Variable
$env:PATH

# Tool-Pfad hinzufügen
$env:PATH += ";$env:USERPROFILE\.dotnet\tools"
```

### Problem: "cyclonedx-npm not found"

```powershell
# Globalen NPM-Pfad prüfen
npm config get prefix

# NPM global prefix setzen
npm config set prefix "$env:APPDATA\npm"
```

### Problem: "No packages found"

Stellen Sie sicher, dass:
- `dotnet restore` ausgeführt wurde (Backend)
- `npm install` ausgeführt wurde (Frontend)
- `package-lock.json` bzw. `packages.lock.json` existieren

### Problem: Upload zu Dependency-Track schlägt fehl

```powershell
# Prüfen Sie die Verbindung
curl http://localhost:8081/api/version

# Prüfen Sie den API-Key
curl -H "X-Api-Key: your-key" http://localhost:8081/api/v1/project
```

## 📚 Weitere Ressourcen

- **CycloneDX**: https://cyclonedx.org/
- **Dependency-Track Docs**: https://docs.dependencytrack.org/
- **CycloneDX .NET Tool**: https://github.com/CycloneDX/cyclonedx-dotnet
- **CycloneDX NPM Tool**: https://github.com/CycloneDX/cyclonedx-node-npm
- **SBOM Best Practices**: https://www.cisa.gov/sbom

## 🎯 Best Practices

1. **Regelmäßige Generierung**: Erstellen Sie SBOMs bei jedem Build
2. **Versionierung**: Tracken Sie SBOMs zusammen mit Releases
3. **Automatisierung**: Integrieren Sie SBOM-Generierung in CI/CD
4. **Zentrale Verwaltung**: Nutzen Sie Dependency-Track für alle Projekte
5. **Monitoring**: Richten Sie Benachrichtigungen für neue Schwachstellen ein
6. **Policy Enforcement**: Definieren Sie Richtlinien für erlaubte Lizenzen
7. **Archivierung**: Bewahren Sie historische SBOMs auf (90+ Tage)

## 🔐 Sicherheit

- **Secrets**: Speichern Sie API-Keys niemals im Code
- **Access Control**: Beschränken Sie API-Key-Berechtigungen
- **HTTPS**: Verwenden Sie HTTPS für Dependency-Track in Production
- **Audit Logs**: Aktivieren Sie Audit-Logging in Dependency-Track

---

**Hinweis**: Diese Pipeline verwendet Open-Source-Tools und ist kostenfrei nutzbar. Für Enterprise-Features siehe Dependency-Track Enterprise Edition.
