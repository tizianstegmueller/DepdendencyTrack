# Azure Setup Helper Script für GitHub Actions
# Dieses Skript hilft beim Einrichten des Service Principals

param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$true)]
    [string]$GitHubOrg,
    
    [Parameter(Mandatory=$true)]
    [string]$GitHubRepo,
    
    [Parameter(Mandatory=$false)]
    [string]$AppName = "github-actions-dependency-track"
)

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Azure Service Principal Setup" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Azure Login prüfen
Write-Host "Prüfe Azure Login..." -ForegroundColor Yellow
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "Nicht bei Azure angemeldet. Führe 'az login' aus..." -ForegroundColor Yellow
    az login
    $account = az account show | ConvertFrom-Json
}

Write-Host "✅ Angemeldet als: $($account.user.name)" -ForegroundColor Green
Write-Host ""

# Subscription setzen
Write-Host "Setze Subscription: $SubscriptionId" -ForegroundColor Yellow
az account set --subscription $SubscriptionId

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Fehler beim Setzen der Subscription" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Subscription gesetzt" -ForegroundColor Green
Write-Host ""

# Service Principal erstellen
Write-Host "Erstelle Service Principal '$AppName'..." -ForegroundColor Yellow
$spOutput = az ad sp create-for-rbac `
    --name $AppName `
    --role contributor `
    --scopes "/subscriptions/$SubscriptionId" `
    --query "{appId:appId, tenant:tenant}" `
    -o json | ConvertFrom-Json

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Fehler beim Erstellen des Service Principals" -ForegroundColor Red
    Write-Host "Prüfe ob der Name bereits existiert:" -ForegroundColor Yellow
    az ad sp list --display-name $AppName --query "[].{appId:appId}" -o table
    exit 1
}

$appId = $spOutput.appId
$tenantId = $spOutput.tenant

Write-Host "✅ Service Principal erstellt" -ForegroundColor Green
Write-Host "   App ID (Client ID): $appId" -ForegroundColor Cyan
Write-Host "   Tenant ID: $tenantId" -ForegroundColor Cyan
Write-Host ""

# Federated Credential erstellen
Write-Host "Erstelle Federated Credential für GitHub Actions..." -ForegroundColor Yellow
$subject = "repo:${GitHubOrg}/${GitHubRepo}:ref:refs/heads/main"

$credentialParams = @{
    name = "github-actions-deploy"
    issuer = "https://token.actions.githubusercontent.com"
    subject = $subject
    audiences = @("api://AzureADTokenExchange")
} | ConvertTo-Json -Compress

az ad app federated-credential create `
    --id $appId `
    --parameters $credentialParams

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Fehler beim Erstellen des Federated Credentials" -ForegroundColor Red
    Write-Host "Möglicherweise existiert es bereits. Versuche fortzufahren..." -ForegroundColor Yellow
}
else {
    Write-Host "✅ Federated Credential erstellt" -ForegroundColor Green
}
Write-Host ""

# Zusammenfassung
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Setup abgeschlossen!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 Füge diese Secrets zu deinem GitHub Repository hinzu:" -ForegroundColor Yellow
Write-Host "   Repository → Settings → Secrets and variables → Actions" -ForegroundColor Gray
Write-Host ""
Write-Host "Secret Name: AZURE_CLIENT_ID" -ForegroundColor Cyan
Write-Host "Value: $appId" -ForegroundColor White
Write-Host ""
Write-Host "Secret Name: AZURE_TENANT_ID" -ForegroundColor Cyan
Write-Host "Value: $tenantId" -ForegroundColor White
Write-Host ""
Write-Host "Secret Name: AZURE_SUBSCRIPTION_ID" -ForegroundColor Cyan
Write-Host "Value: $SubscriptionId" -ForegroundColor White
Write-Host ""
Write-Host "Federated Credential Subject:" -ForegroundColor Cyan
Write-Host "$subject" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Danach kannst du die GitHub Action ausführen!" -ForegroundColor Green

# Optional: In Zwischenablage kopieren (Windows)
if ($IsWindows -or $env:OS -match "Windows") {
    $secretsText = @"
AZURE_CLIENT_ID=$appId
AZURE_TENANT_ID=$tenantId
AZURE_SUBSCRIPTION_ID=$SubscriptionId
"@
    $secretsText | Set-Clipboard
    Write-Host ""
    Write-Host "✅ Secrets wurden in die Zwischenablage kopiert!" -ForegroundColor Green
}
