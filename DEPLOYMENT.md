# Dependency-Track - Azure Deployment

Dieses Projekt enthält die Infrastruktur und Deployment-Pipelines für [OWASP Dependency-Track](https://dependencytrack.org/) auf Azure Container Apps.

## 📁 Projektstruktur

```
├── infrastructure/
│   ├── main.bicep          # Hauptinfrastruktur (PostgreSQL, Container Apps)
│   └── main.bicepparam     # Parameter für Bicep-Deployment
├── .github/workflows/
│   ├── infrastructure.yml  # Pipeline für Infrastruktur-Deployment
│   └── deploy.yml         # Pipeline für Updates
└── DependencyTrack-Setup/
    ├── docker-compose.yml # Lokale Entwicklung
    └── README.md          # Docker Compose Dokumentation
```

## 🚀 Deployment

### Voraussetzungen

1. **Azure Service Principal mit Federated Credentials erstellen**:

   ```bash
   # Variablen setzen
   SUBSCRIPTION_ID="<IHRE_SUBSCRIPTION_ID>"
   RESOURCE_GROUP="rg-dependency-track"
   APP_NAME="github-actions-dependency-track"
   
   # Service Principal erstellen
   az ad sp create-for-rbac --name "$APP_NAME" \
     --role contributor \
     --scopes /subscriptions/$SUBSCRIPTION_ID
   
   # Ausgabe notieren:
   # - appId (wird zu AZURE_CLIENT_ID)
   # - tenant (wird zu AZURE_TENANT_ID)
   ```

2. **Federated Credential für GitHub Actions hinzufügen**:

   ```bash
   # App ID vom vorherigen Schritt verwenden
   APP_ID="<APP_ID_AUS_VORHERIGEM_SCHRITT>"
   GITHUB_ORG="<IHR_GITHUB_USERNAME_ODER_ORG>"
   GITHUB_REPO="<IHR_REPO_NAME>"
   
   az ad app federated-credential create \
     --id $APP_ID \
     --parameters '{
       "name": "github-actions-deploy",
       "issuer": "https://token.actions.githubusercontent.com",
       "subject": "repo:'"$GITHUB_ORG"'/'"$GITHUB_REPO"':ref:refs/heads/main",
       "audiences": ["api://AzureADTokenExchange"]
     }'
   ```

2. **GitHub Secrets konfigurieren**:

   Gehe zu GitHub Repository → Settings → Secrets and variables → Actions → New repository secret
   
   - `AZURE_CLIENT_ID` - Die `appId` aus Schritt 1
   - `AZURE_TENANT_ID` - Die `tenant` aus Schritt 1
   - `AZURE_SUBSCRIPTION_ID` - Ihre Azure Subscription ID
   - `POSTGRES_PASSWORD` - Sicheres Passwort für die PostgreSQL Datenbank

   ```bash
   # IDs anzeigen falls vergessen:
   az account show --query "{subscriptionId:id, tenantId:tenantId}"
   az ad sp list --display-name "$APP_NAME" --query "[].{appId:appId}"
   ```

### Schritt 1: Infrastruktur deployen

1. Gehe zu **Actions** → **Deploy Dependency-Track Infrastructure**
2. Klicke auf **Run workflow**
3. Warte bis das Deployment abgeschlossen ist (ca. 5-10 Minuten)

Dies erstellt:
- Azure Database for PostgreSQL Flexible Server (persistente Daten)
- Azure Container Registry (optional, für Image-Mirror)
- Container Apps Environment mit Log Analytics
- API Server Container App (mit PostgreSQL-Anbindung)
- Frontend Container App

### Schritt 2: Auf Dependency-Track zugreifen

Nach erfolgreichem Deployment:
- **Frontend URL**: In Workflow-Logs oder via `az containerapp show` (siehe unten)
- **API Server URL**: Parallel zur Frontend URL

**Standard-Anmeldedaten**:
- Benutzername: `admin`
- Passwort: `admin`

⚠️ **WICHTIG**: Passwort nach dem ersten Login ändern!

### Schritt 3: Dependency-Track aktualisieren (Optional)

Um auf eine neuere Version zu aktualisieren:
1. **Actions** → **Update Dependency-Track** → **Run workflow**
2. Optional: Gebe die gewünschte Version an (z.B. `4.11.0`)
3. Standardmäßig wird `latest` verwendet

## 🏗️ Architektur

```
┌─────────────────────────────────────────────────────────┐
│  Azure DB for PostgreSQL Flexible Server                │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Database: dtrack                                │  │
│  │  - PostgreSQL 16, Standard_B2s, 32 GB            │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  Container Apps Environment                             │
│  ┌────────────────────────────────────┐               │
│  │  API Server Container App          │               │
│  │  - dependencytrack/apiserver       │               │
│  │  - Port 8080                       │               │
│  │  - 2 CPU, 4 GB RAM                 │               │
│  │  - PostgreSQL (extern)             │               │
│  │  - Auto-scaling (1-2 replicas)     │               │
│  └────────────────────────────────────┘               │
│                                                         │
│  ┌────────────────────────────────────┐               │
│  │  Frontend Container App            │               │
│  │  - dependencytrack/frontend        │               │
│  │  - Port 8080                       │               │
│  │  - 0.5 CPU, 1 GB RAM               │               │
│  │  - Auto-scaling (1-3 replicas)     │               │
│  └────────────────────────────────────┘               │
└─────────────────────────────────────────────────────────┘
```

## 🔧 Lokale Entwicklung

Für lokale Entwicklung mit Docker Compose:

```bash
cd DependencyTrack-Setup
docker compose up -d
```

Siehe [DependencyTrack-Setup/README.md](DependencyTrack-Setup/README.md) für Details.

## 📝 Bicep-Parameter anpassen

Bearbeite [infrastructure/main.bicepparam](infrastructure/main.bicepparam):

```bicep
param containerRegistryName = 'deinregistryname'   // 3-50 alphanumerische Zeichen
param postgresServerName    = 'dein-postgres-srv'  // Global eindeutig, Kleinbuchstaben/Zahlen/Bindestriche
param postgresDatabaseName  = 'dtrack'             // Datenbankname
param postgresAdminUser     = 'dtrackadmin'        // DB Admin Benutzername
// postgresAdminPassword → GitHub Secret POSTGRES_PASSWORD
```

**Wichtig**:
- PostgreSQL Server Name: global eindeutig, 3-63 Zeichen (Kleinbuchstaben, Zahlen, Bindestriche)
- Container Registry Name: 3-50 alphanumerische Zeichen (nur Kleinbuchstaben und Zahlen)

## 🌐 URLs nach Deployment

URLs abrufen:

```bash
# Frontend URL
az containerapp show \
  --name dependencytrack-frontend \
  --resource-group rg-dependency-track \
  --query properties.configuration.ingress.fqdn \
  --output tsv

# API Server URL
az containerapp show \
  --name dependencytrack-apiserver \
  --resource-group rg-dependency-track \
  --query properties.configuration.ingress.fqdn \
  --output tsv
```

## 🛠️ Manuelle Deployment-Befehle

### Infrastruktur deployen
```bash
az group create --name rg-dependency-track --location germanywestcentral

az deployment group create \
  --resource-group rg-dependency-track \
  --template-file infrastructure/main.bicep \
  --parameters infrastructure/main.bicepparam \
  --parameters postgresAdminPassword="<SICHERES_PASSWORT>"
```

### Container Apps manuell aktualisieren
```bash
# API Server updaten
az containerapp update \
  --name dependencytrack-apiserver \
  --resource-group rg-dependency-track \
  --image dependencytrack/apiserver:latest

# Frontend updaten
az containerapp update \
  --name dependencytrack-frontend \
  --resource-group rg-dependency-track \
  --image dependencytrack/frontend:latest
```

### Auf spezifische Version aktualisieren
```bash
# API Server auf Version 4.11.0
az containerapp update \
  --name dependencytrack-apiserver \
  --resource-group rg-dependency-track \
  --image dependencytrack/apiserver:4.11.0

# Frontend auf Version 4.11.0
az containerapp update \
  --name dependencytrack-frontend \
  --resource-group rg-dependency-track \
  --image dependencytrack/frontend:4.11.0
```

## 📊 Monitoring und Logs

### Logs anzeigen
```bash
# API Server Logs
az containerapp logs show \
  --name dependencytrack-apiserver \
  --resource-group rg-dependency-track \
  --follow

# Frontend Logs
az containerapp logs show \
  --name dependencytrack-frontend \
  --resource-group rg-dependency-track \
  --follow
```

### Log Analytics Workspace
Alle Logs werden im Log Analytics Workspace `dependencytrack-env-logs` gespeichert.

## 💾 Datenpersistenz

Alle Dependency-Track Daten werden in **Azure Database for PostgreSQL Flexible Server** gespeichert:

- **Server**: `ok-dtrack-postgres.postgres.database.azure.com`
- **Datenbank**: `dtrack`
- **Version**: PostgreSQL 16
- **SKU**: Standard_B2s (Burstable, 2 vCores)
- **Storage**: 32 GB
- **Backup**: 7 Tage automatisch
- **SSL**: Erforderlich (`sslmode=require`)

Die Verbindungsdaten werden als **Container App Secrets** gespeichert (kein Klartext im Code).

### PostgreSQL-Verbindung testen
```bash
# FQDN des Servers abrufen
az deployment group show \
  --resource-group rg-dependency-track \
  --name main \
  --query properties.outputs.postgresServerFqdn.value

# Verbindung testen (falls psql installiert)
psql "host=ok-dtrack-postgres.postgres.database.azure.com dbname=dtrack user=dtrackadmin sslmode=require"
```

## 🔒 Sicherheit

- ✅ HTTPS automatisch für Container Apps Ingress
- ✅ PostgreSQL mit SSL-Pflicht (`sslmode=require`)
- ✅ DB-Passwort als GitHub Secret (nie im Code)
- ✅ DB-Passwort als Container App Secret (kein Klartext in der App)
- ✅ Log Analytics für Monitoring
- ✅ CORS aktiviert für API Server
- ⚠️ Admin-User Passwort nach erstem Login ändern
- 💡 Empfehlung: Managed Identity für DB-Zugriff verwenden

## 🔄 SBOM Upload Integration

Das Repository enthält ein PowerShell-Skript für automatischen SBOM-Upload:

```powershell
cd .github/workflows
.\sbom-local.ps1
```

Generiert SBOMs für Shop-Backend und Shop-Frontend und lädt sie automatisch zu Dependency-Track hoch.

## 📈 Skalierung

### CPU und Memory anpassen

Bearbeite [infrastructure/main.bicep](infrastructure/main.bicep):

```bicep
// API Server Resources
resources: {
  cpu: json('4.0')      // Standard: 2.0
  memory: '8Gi'         // Standard: 4Gi
}

// Frontend Resources
resources: {
  cpu: json('1.0')      // Standard: 0.5
  memory: '2Gi'         // Standard: 1Gi
}
```

### Replica-Anzahl anpassen

```bicep
scale: {
  minReplicas: 2        // Standard: 1
  maxReplicas: 5        // Standard: 2 (API), 3 (Frontend)
}
```

## 🐛 Troubleshooting

### Container startet nicht
```bash
# Prüfe Replica Status
az containerapp revision list \
  --name dependencytrack-apiserver \
  --resource-group rg-dependency-track

# Prüfe Container Logs
az containerapp logs show \
  --name dependencytrack-apiserver \
  --resource-group rg-dependency-track \
  --tail 100
```

### Daten nach PostgreSQL-Fehler prüfen
```bash
# DB-Verbindung aus Logs prüfen
az containerapp logs show \
  --name dependencytrack-apiserver \
  --resource-group rg-dependency-track \
  --tail 50

# Sicherstellen, dass PostgreSQL läuft
az postgres flexible-server show \
  --name ok-dtrack-postgres \
  --resource-group rg-dependency-track \
  --query state
```

### Slow Performance
- API Server benötigt mindestens 4 GB RAM
- Erhöhe CPU/Memory in der Bicep-Datei
- Prüfe Log Analytics für Resource Constraints

## 💡 Weitere Schritte

- [ ] Custom Domain für Container Apps konfigurieren
- [ ] PostgreSQL SKU auf Standard_D2s skalieren (für höhere Last)
- [ ] PostgreSQL High Availability aktivieren (für Production)
- [ ] Application Insights für erweiterte Metriken
- [ ] Managed Identity für DB-Verbindung (statt Passwort)
- [ ] Azure Key Vault für Secrets integrieren
- [ ] Staging Environment hinzufügen
- [ ] Point-in-Time Restore für PostgreSQL prüfen

## 📚 Weiterführende Links

- [Dependency-Track Dokumentation](https://docs.dependencytrack.org/)
- [Azure Container Apps Docs](https://docs.microsoft.com/azure/container-apps/)
- [Bicep Dokumentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
