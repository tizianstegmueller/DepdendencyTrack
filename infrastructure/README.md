# Dependency-Track Infrastructure (Bicep)

Dieses Verzeichnis enthält die Azure Bicep Templates für das Deployment von Dependency-Track auf Azure Container Apps.

## 📦 Enthaltene Ressourcen

### Storage
- **Storage Account**: Für persistente Daten
- **File Share**: `dependencytrackdata` (50 GB) - gemountet auf `/data` im API Server

### Container Apps
- **Environment**: Mit Log Analytics Integration
- **API Server App**: 
  - Image: `dependencytrack/apiserver:latest`
  - Resources: 2 CPU, 4 GB RAM
  - Persistent Storage Mount
  - CORS aktiviert
- **Frontend App**:
  - Image: `dependencytrack/frontend:latest`
  - Resources: 0.5 CPU, 1 GB RAM
  - Verbindung zum API Server

### Optional
- **Container Registry**: Für Mirror der Docker Hub Images

## 🚀 Quick Start

### 1. Parameter anpassen

Bearbeite `main.bicepparam`:

```bicep
param containerRegistryName = 'deinuniquerregistryname'  // 3-50 alphanumerische Zeichen
param storageAccountName = 'deinuniquestoragename'       // 3-24 Kleinbuchstaben/Zahlen
```

### 2. Deployment ausführen

```bash
# Resource Group erstellen
az group create --name rg-dependency-track --location germanywestcentral

# Template deployen
az deployment group create \
  --resource-group rg-dependency-track \
  --template-file main.bicep \
  --parameters main.bicepparam
```

### 3. URLs abrufen

```bash
# Frontend URL
az deployment group show \
  --resource-group rg-dependency-track \
  --name main \
  --query properties.outputs.frontendUrl.value

# API Server URL
az deployment group show \
  --resource-group rg-dependency-track \
  --name main \
  --query properties.outputs.apiServerUrl.value
```

## ⚙️ Parameter

| Parameter | Beschreibung | Standard | Erforderlich |
|-----------|--------------|----------|--------------|
| `containerRegistryName` | Name der Azure Container Registry | - | Ja |
| `storageAccountName` | Name des Storage Accounts | - | Ja |
| `location` | Azure Region | Von Resource Group | Nein |
| `environmentName` | Container Apps Environment Name | `dependencytrack-env` | Nein |
| `apiServerAppName` | API Server Container App Name | `dependencytrack-apiserver` | Nein |
| `frontendAppName` | Frontend Container App Name | `dependencytrack-frontend` | Nein |
| `apiServerImage` | API Server Docker Image | `dependencytrack/apiserver:latest` | Nein |
| `frontendImage` | Frontend Docker Image | `dependencytrack/frontend:latest` | Nein |

## 🔄 Updates

### Infrastruktur aktualisieren

```bash
az deployment group create \
  --resource-group rg-dependency-track \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --mode Incremental
```

### Auf neue Dependency-Track Version aktualisieren

Option 1: Parameter-Datei anpassen
```bicep
param apiServerImage = 'dependencytrack/apiserver:4.11.0'
param frontendImage = 'dependencytrack/frontend:4.11.0'
```

Option 2: Direkt die Container Apps updaten
```bash
az containerapp update \
  --name dependencytrack-apiserver \
  --resource-group rg-dependency-track \
  --image dependencytrack/apiserver:4.11.0
```

## 🎯 Outputs

Das Template gibt folgende Werte zurück:

- `storageAccountName`: Name des Storage Accounts
- `containerRegistryName`: Name der Container Registry (falls erstellt)
- `containerRegistryLoginServer`: Login Server der Registry
- `apiServerUrl`: HTTPS URL des API Servers
- `frontendUrl`: HTTPS URL des Frontends
- `environmentId`: Resource ID des Container Apps Environment

## 🔍 Validation

Template validieren ohne Deployment:

```bash
az deployment group validate \
  --resource-group rg-dependency-track \
  --template-file main.bicep \
  --parameters main.bicepparam
```

What-If Preview:

```bash
az deployment group what-if \
  --resource-group rg-dependency-track \
  --template-file main.bicep \
  --parameters main.bicepparam
```

## 🧹 Cleanup

Alle Ressourcen löschen:

```bash
az group delete --name rg-dependency-track --yes
```

## 📚 Weitere Informationen

- [DEPLOYMENT.md](../DEPLOYMENT.md) - Vollständige Deployment-Dokumentation
- [Bicep Dokumentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [Container Apps Dokumentation](https://docs.microsoft.com/azure/container-apps/)
