# Azure Setup für GitHub Actions

Schritt-für-Schritt Anleitung für die Einrichtung von Azure Federated Credentials für GitHub Actions.

## 📋 Voraussetzungen

- Azure CLI installiert: `az --version`
- Bei Azure angemeldet: `az login`
- GitHub Repository erstellt

## 🔐 Schritt 1: Service Principal erstellen

```bash
az ad sp create-for-rbac \
  --name "github-actions-dependency-track" \
  --role contributor \
  --scopes /subscriptions/86d31f2c-9326-4104-b228-3e33c3cb8cab

# ⚠️ WICHTIG: Ausgabe aufbewahren!
# Sie erhalten:
# {
#   "appId": "12345678-1234-1234-1234-123456789abc",      ← AZURE_CLIENT_ID
#   "displayName": "github-actions-dependency-track",
#   "password": "xxxxx",                                   ← Nicht mehr benötigt für OIDC!
#   "tenant": "87654321-4321-4321-4321-cba987654321"      ← AZURE_TENANT_ID
# }
```

**Notieren Sie sich**:
- `appId` → Wird zu `AZURE_CLIENT_ID`
- `tenant` → Wird zu `AZURE_TENANT_ID`
- `SUBSCRIPTION_ID` → Wird zu `AZURE_SUBSCRIPTION_ID`

## 🔗 Schritt 2: Federated Credential erstellen

```bash
# Variablen aus Schritt 1 verwenden
APP_ID="12345678-1234-1234-1234-123456789abc"  # Die appId von oben

# GitHub Infos (anpassen!)
GITHUB_ORG="IhrGitHubUsername"    # oder Organisation
GITHUB_REPO="DepdendencyTrack"    # Ihr Repository-Name

# Federated Credential hinzufügen
az ad app federated-credential create \
  --id $APP_ID \
  --parameters "{
    \"name\": \"github-actions-deploy\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:${GITHUB_ORG}/${GITHUB_REPO}:ref:refs/heads/main\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"

# Erfolgsmeldung sollte erscheinen
```

**Was passiert hier?**
- GitHub kann sich jetzt bei Azure mit einem Token authentifizieren
- Kein Passwort/Secret mehr nötig (sicherer!)
- Funktioniert nur für den angegebenen Branch (main) und Repository

## 🔑 Schritt 3: GitHub Secrets einrichten

1. Gehe zu deinem GitHub Repository
2. **Settings** → **Secrets and variables** → **Actions**
3. Klicke auf **"New repository secret"**

Erstelle diese 3 Secrets:

### AZURE_CLIENT_ID
```
Name: AZURE_CLIENT_ID
Secret: <Die appId aus Schritt 1>
```

### AZURE_TENANT_ID
```
Name: AZURE_TENANT_ID
Secret: <Die tenant aus Schritt 1>
```

### AZURE_SUBSCRIPTION_ID
```
Name: AZURE_SUBSCRIPTION_ID
Secret: <Ihre Azure Subscription ID>
```

## ✅ Schritt 4: Testen

```bash
# Secrets nochmal verifizieren
echo "AZURE_CLIENT_ID: $APP_ID"
echo "AZURE_TENANT_ID: $(az account show --query tenantId -o tsv)"
echo "AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
```

Dann in GitHub:
1. **Actions** Tab öffnen
2. **Deploy Dependency-Track Infrastructure** auswählen
3. **Run workflow** klicken
4. Logs beobachten

## 🐛 Troubleshooting

### Fehler: "Not all values are present"
- ✅ Alle 3 Secrets in GitHub angelegt?
- ✅ Secret-Namen korrekt geschrieben? (Groß-/Kleinschreibung!)
- ✅ App ID und Tenant ID aus der richtigen Ausgabe kopiert?

### Fehler: "Federated credential does not match"
```bash
# Federated Credentials anzeigen
az ad app federated-credential list --id $APP_ID

# Subject muss exakt sein: repo:USERNAME/REPO:ref:refs/heads/main
# Falls falsch, löschen und neu erstellen:
az ad app federated-credential delete --id $APP_ID --federated-credential-id <ID>
```

### Fehler: "Insufficient privileges"
```bash
# Service Principal Rolle prüfen
az role assignment list \
  --assignee $APP_ID \
  --query "[].{Role:roleDefinitionName, Scope:scope}"

# Falls nicht "Contributor", hinzufügen:
az role assignment create \
  --assignee $APP_ID \
  --role Contributor \
  --scope /subscriptions/$SUBSCRIPTION_ID
```

### IDs vergessen?
```bash
# Subscription ID finden
az account show --query id -o tsv

# Tenant ID finden
az account show --query tenantId -o tsv

# App ID finden
az ad sp list --display-name "github-actions-dependency-track" --query "[].appId" -o tsv
```

## 🔄 Alternative: Password-basierte Authentifizierung

Falls Federated Credentials nicht funktionieren, können Sie auch die klassische Methode verwenden:

```bash
# Service Principal mit Secret erstellen
az ad sp create-for-rbac \
  --name "github-actions-dependency-track" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --json-auth

# Kompletten JSON-Output als Secret speichern
```

Dann in der Pipeline `azure/login@v1` verwenden:
```yaml
- uses: azure/login@v1
  with:
    creds: ${{ secrets.AZURE_CREDENTIALS }}  # Der komplette JSON
```

## 📚 Weiterführende Links

- [Azure Login Action Dokumentation](https://github.com/Azure/login)
- [Federated Credentials Docs](https://learn.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation-create-trust)
- [GitHub Actions OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
