# 🎯 Dependency Track Demo Projekt

Dieses Repository enthält eine vollständige Demo-Umgebung für Software Composition Analysis (SCA) mit OWASP Dependency-Track.

## 📁 Projektstruktur

```
DepdendencyTrack/
│
├── Shop/                           # Demo Shop-Anwendung
│   ├── Backend/                    # .NET 9.0 Web API
│   ├── Frontend/                   # React 18 + Vite
│   ├── README.md                   # Shop-Dokumentation
│   └── SCHNELLSTART.md             # Shop Quick-Start Guide
│
├── DependencyTrack-Setup/          # Dependency-Track Installation
│   ├── docker-compose.yml          # Docker Compose für DTrack
│   ├── README.md                   # DTrack-Dokumentation
│   ├── QUICKSTART.md               # DTrack Quick-Start
│   ├── SBOM-README.md              # SBOM Pipeline-Dokumentation
│   └── SBOM-QUICKSTART.md          # SBOM Quick-Start
│
├── infrastructure/                 # Azure Infrastructure (Bicep)
│   ├── main.bicep                  # Dependency-Track auf Container Apps
│   ├── main.bicepparam             # Deployment-Parameter
│   └── README.md                   # Infrastructure-Dokumentation
│
├── .github/workflows/              # CI/CD Pipelines
│   ├── infrastructure.yml          # Azure Infrastructure Deployment
│   ├── deploy.yml                  # Update Dependency-Track
│   ├── generate-sbom.yml           # GitHub Actions SBOM Pipeline
│   └── sbom-local.ps1              # Lokales SBOM-Script
│
├── DEPLOYMENT.md                   # Azure Deployment Guide
└── README.md                       # Diese Datei
```

## 🚀 Quick Start

### 1. Shop-Anwendung starten

Die Demo-Shop-Anwendung besteht aus einem .NET Backend und React Frontend:

```powershell
# Backend starten (Terminal 1)
cd Shop\Backend
dotnet run --urls "http://localhost:5000"

# Frontend starten (Terminal 2)
cd Shop\Frontend
npm install
npm run dev
```

**Öffnen Sie**: http://localhost:3000

📖 Vollständige Anleitung: [Shop/README.md](Shop/README.md)

---

### 2. Azure Deployment (Production)

Dependency-Track auf Azure Container Apps deployen:

#### Voraussetzungen
```bash
# Azure CLI installiert
az --version

# Service Principal erstellen
az ad sp create-for-rbac --name "github-actions-dependency-track" \
  --role contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID>

# Notieren Sie: appId, tenant (aus der Ausgabe)

# Federated Credential für GitHub hinzufügen
az ad app federated-credential create \
  --id <APP_ID> \
  --parameters '{
    "name": "github-actions-deploy",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:<GITHUB_USER>/<REPO_NAME>:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

#### GitHub Secrets konfigurieren
- `AZURE_CLIENT_ID` - appId aus Service Principal
- `AZURE_TENANT_ID` - tenant aus Service Principal
- `AZURE_SUBSCRIPTION_ID` - Ihre Subscription ID

#### Deployment ausführen
1. GitHub Actions → "Deploy Dependency-Track Infrastructure" → Run workflow
2. Warten (ca. 5-10 Minuten)
3. URLs werden in den Workflow-Logs angezeigt

**Enthält**:
- Azure Storage Account (persistente Daten)
- Container Apps (API Server + Frontend)
- Log Analytics
- Auto-Scaling

📖 Vollständige Anleitung: [DEPLOYMENT.md](DEPLOYMENT.md)

---

### 3. Dependency-Track lokal starten

OWASP Dependency-Track für Schwachstellenanalyse:

```powershell
cd DependencyTrack-Setup
docker compose up -d
```

Nach 2-3 Minuten öffnen Sie: http://localhost:8080
- **Login**: `admin` / `admin`

📖 Vollständige Anleitung: [DependencyTrack-Setup/README.md](DependencyTrack-Setup/README.md)

---

### 4. SBOM generieren und analysieren

Software Bill of Materials (SBOM) für die Shop-Anwendung erstellen:

```powershell
# Zum Projekt-Root navigieren
cd c:\Users\tse\source\repos\DepdendencyTrack

# Dependency-Track API Key setzen (aus der DTrack UI)
$env:DTRACK_API_KEY="ihr-api-key"

# Optional: Defaults ueberschreiben
$env:DTRACK_URL="http://localhost:8081"
$env:DTRACK_PROJECT_VERSION="1.0.0"
$env:DTRACK_BACKEND_PROJECT_NAME="Shop-Backend"
$env:DTRACK_FRONTEND_PROJECT_NAME="Shop-Frontend"

# SBOM generieren + automatisch zu Dependency-Track hochladen
.\.github\workflows\sbom-local.ps1
```

**Ergebnis**: 
- `sbom/backend-sbom.xml`
- `sbom/frontend-sbom.json`

Die SBOMs werden danach direkt an Dependency-Track (`/api/v1/bom`) hochgeladen.

#### Alternative mit `.env`

```powershell
# Einmalig .env aus Template erstellen
Copy-Item .env.example .env

# Werte in .env anpassen (mindestens DTRACK_API_KEY), dann in Session laden
Get-Content .env | ForEach-Object {
   if ($_ -match '^[ ]*([^#=]+)[ ]*=[ ]*(.*)$') {
      [Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim(), 'Process')
   }
}

# Script ausführen
.\.github\workflows\sbom-local.ps1
```

📖 Vollständige Anleitung: [DependencyTrack-Setup/SBOM-README.md](DependencyTrack-Setup/SBOM-README.md)

---

## 📚 Was ist enthalten?

### Shop-Anwendung
Eine moderne Full-Stack Webanwendung zum Demonstrieren von SCA:
- **Backend**: .NET 9.0 Web API mit InMemory-Datenbank
- **Frontend**: React 18 mit Vite
- **Features**: Produktkatalog mit 6 Demo-Produkten
- **Zweck**: Realistische Anwendung für SBOM-Analyse

### Dependency-Track
Enterprise-grade Software Composition Analysis Plattform:
- **Container-basiert**: Docker Compose Setup
- **Features**: 
  - Schwachstellenerkennung (NVD, OSV, GitHub Advisories, etc.)
  - Lizenz-Compliance
  - Policy-Management
  - REST API
- **Dashboard**: Web-basierte Benutzeroberfläche

### SBOM Pipeline
Automatisierte Pipeline zur SBOM-Generierung:
- **GitHub Actions**: Automatische SBOM-Erstellung bei Push
- **Lokales Script**: PowerShell-Script für lokale Entwicklung
- **Format**: CycloneDX JSON (Industry Standard)
- **Integration**: Direkter Upload zu Dependency-Track

---

## 🎓 Kompletter Workflow

Ein typischer Workflow sieht so aus:

```
1. Entwicklung
   └─> Shop-Anwendung entwickeln und testen

2. SBOM-Generierung
   └─> Automatisch via GitHub Actions oder manuell via Script

3. Analyse
   └─> SBOM zu Dependency-Track hochladen

4. Review
   └─> Schwachstellen und Compliance-Probleme prüfen

5. Remediation
   └─> Dependencies aktualisieren oder Risiken akzeptieren
```

---

## 🛠️ Voraussetzungen

### Für Shop-Anwendung
- **.NET 9.0 SDK** - https://dotnet.microsoft.com/download
- **Node.js 20+** - https://nodejs.org/

### Für Dependency-Track
- **Docker Desktop** - https://www.docker.com/products/docker-desktop
- **Mindestens 10 GB RAM** für Docker

### Für SBOM-Generierung
- Alle oben genannten Tools
- **CycloneDX CLI Tools** (werden automatisch installiert)

---

## 📖 Detaillierte Dokumentation

Jeder Bereich hat seine eigene ausführliche Dokumentation:

| Bereich | Dokumentation | Quick-Start |
|---------|---------------|-------------|
| **Shop-Anwendung** | [Shop/README.md](Shop/README.md) | [Shop/SCHNELLSTART.md](Shop/SCHNELLSTART.md) |
| **Dependency-Track** | [DependencyTrack-Setup/README.md](DependencyTrack-Setup/README.md) | [DependencyTrack-Setup/QUICKSTART.md](DependencyTrack-Setup/QUICKSTART.md) |
| **SBOM-Pipeline** | [DependencyTrack-Setup/SBOM-README.md](DependencyTrack-Setup/SBOM-README.md) | [DependencyTrack-Setup/SBOM-QUICKSTART.md](DependencyTrack-Setup/SBOM-QUICKSTART.md) |

---

## 🎯 Lernziele

Dieses Projekt demonstriert:

✅ **Software Composition Analysis** - Wie man Abhängigkeiten analysiert
✅ **SBOM-Erstellung** - Best Practices für Bill of Materials
✅ **Schwachstellenmanagement** - Identifikation und Tracking
✅ **Lizenz-Compliance** - Überwachung von Software-Lizenzen
✅ **CI/CD Integration** - Automatisierung der Sicherheitsanalyse
✅ **Supply Chain Security** - Transparenz in der Software-Lieferkette

---

## 🔍 Weitere Ressourcen

- **OWASP Dependency-Track**: https://dependencytrack.org/
- **CycloneDX SBOM Standard**: https://cyclonedx.org/
- **CISA SBOM Guidelines**: https://www.cisa.gov/sbom
- **NTIA SBOM Minimum Elements**: https://www.ntia.gov/SBOM

---

## 🤝 Support & Community

- **Dependency-Track Issues**: https://github.com/DependencyTrack/dependency-track/issues
- **Dependency-Track Slack**: https://owasp.slack.com (#dependency-track)
- **CycloneDX Issues**: https://github.com/CycloneDX

---

## 📄 Lizenz

- **Shop-Anwendung**: MIT License (Demo-Zwecke)
- **Dependency-Track**: Apache License 2.0
- **CycloneDX**: Apache License 2.0

---

## ⚠️ Hinweis

Dieses Projekt ist für **Lern- und Demo-Zwecke** erstellt. Für Production-Einsatz:
- Ändern Sie alle Standard-Passwörter
- Verwenden Sie HTTPS/TLS
- Konfigurieren Sie eine externe Datenbank (PostgreSQL)
- Implementieren Sie Backup-Strategien
- Aktivieren Sie erweiterte Sicherheitsfeatures

---

**Viel Erfolg beim Erkunden von Software Composition Analysis!** 🚀
