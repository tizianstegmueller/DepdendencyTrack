# 🚀 SBOM Schnellanleitung

## Lokal SBOM generieren

```powershell
# 1. Zum Projektverzeichnis navigieren
cd c:\Users\tse\source\repos\DepdendencyTrack

# 2. SBOM-Script ausführen
.\.github\workflows\sbom-local.ps1
```

**Ergebnis**: `sbom/backend-sbom.json` und `sbom/frontend-sbom.json`

---

## Mit Upload zu Dependency-Track

### 1. API-Key holen

1. Öffne http://localhost:8080
2. Login: `admin` / `admin`
3. **Administration** → **Access Management** → **Teams** → Team auswählen
4. **API Keys** → **Create API Key** → Key kopieren

### 2. Upload ausführen

```powershell
# Mit API-Key
.\.github\workflows\sbom-local.ps1 -UploadToDTrack -DTrackApiKey "dein-api-key"
```

---

## GitHub Actions (Automatisch)

Die Pipeline läuft automatisch bei:
- Push auf `main`/`master`/`develop`
- Pull Requests
- Täglich um 2:00 Uhr UTC

**Artifacts downloaden**:
1. GitHub → Actions → Generate SBOM
2. Run auswählen
3. Artifacts → Download

---

## Troubleshooting

### Script kann nicht ausgeführt werden
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

### Tool nicht gefunden
```powershell
# .NET Tools PATH
$env:PATH += ";$env:USERPROFILE\.dotnet\tools"

# NPM global PATH
$env:PATH += ";$env:APPDATA\npm"
```

---

Vollständige Dokumentation: [SBOM-PIPELINE-README.md](SBOM-PIPELINE-README.md)
