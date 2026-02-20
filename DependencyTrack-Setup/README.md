# 🐳 Dependency-Track Docker Compose Setup

Dieses Repository enthält die Docker Compose Konfiguration für [OWASP Dependency-Track](https://dependencytrack.org/), eine kontinuierliche Software Composition Analysis (SCA) Plattform.

## 📋 Was ist Dependency-Track?

Dependency-Track ist eine intelligente Komponenten-Analyse-Plattform, die:
- Schwachstellen in Abhängigkeiten identifiziert
- Kontinuierliche Risikoanalyse durchführt
- SBOM (Software Bill of Materials) verwaltet
- Policy-basierte Compliance ermöglicht
- Integration in CI/CD-Pipelines bietet

## 🚀 Schnellstart

### Voraussetzungen

- **Docker Desktop** installiert ([Download](https://www.docker.com/products/docker-desktop))
- Mindestens **8 GB RAM** für den API Server verfügbar
- **10 GB freier Festplattenspeicher**

### Dependency-Track starten

```powershell
# Navigieren Sie zum Projektverzeichnis
cd c:\Users\tse\source\repos\DepdendencyTrack

# Starten Sie alle Services
docker compose up -d
```

### Zugriff auf die Anwendung

Nach dem Start (ca. 2-3 Minuten beim ersten Start):

- **Frontend UI**: http://localhost:8080
- **API Server**: http://localhost:8081
- **API Swagger Docs**: http://localhost:8081/api/swagger.json

### Standard-Anmeldedaten

- **Benutzername**: `admin`
- **Passwort**: `admin`

⚠️ **WICHTIG**: Ändern Sie das Passwort nach dem ersten Login!

## 📦 Enthaltene Services

### 1. API Server (`dtrack-apiserver`)
- **Image**: `dependencytrack/apiserver:latest`
- **Port**: 8081
- **RAM**: 8-12 GB
- **Funktion**: Backend-API, Datenverarbeitung, Schwachstellenanalyse

### 2. Frontend (`dtrack-frontend`)
- **Image**: `dependencytrack/frontend:latest`
- **Port**: 8080
- **RAM**: 512 MB - 1 GB
- **Funktion**: Web-UI für Benutzerinteraktion

## 🛠️ Verwaltung

### Services stoppen

```powershell
docker compose stop
```

### Services neustarten

```powershell
docker compose restart
```

### Services stoppen und entfernen

```powershell
docker compose down
```

### Services mit Daten löschen (VORSICHT!)

```powershell
# Entfernt auch das Volume mit allen Daten
docker compose down -v
```

### Logs anzeigen

```powershell
# Alle Logs
docker compose logs -f

# Nur API Server Logs
docker compose logs -f dtrack-apiserver

# Nur Frontend Logs
docker compose logs -f dtrack-frontend
```

### Status prüfen

```powershell
docker compose ps
```

## 🗄️ Datenpersistenz

Alle Daten werden im Docker Volume `dependency-track` gespeichert:

```powershell
# Volume-Informationen anzeigen
docker volume inspect dependency-track

# Volume-Speicherort anzeigen
docker volume ls
```

## 🔧 Konfiguration

### API Server anpassen

Bearbeiten Sie [docker-compose.yml](docker-compose.yml) und passen Sie die Umgebungsvariablen unter `dtrack-apiserver.environment` an.

Wichtige Konfigurationen:
- **Logging**: `LOGGING_LEVEL` (DEBUG, INFO, WARN, ERROR)
- **System Requirements**: `SYSTEM_REQUIREMENT_CHECK_ENABLED`
- **Datenbank**: Siehe PostgreSQL-Konfiguration unten

### PostgreSQL für Production nutzen (empfohlen)

Für Production-Umgebungen empfiehlt sich eine externe Datenbank:

1. Entkommentieren Sie den `postgres` Service in [docker-compose.yml](docker-compose.yml)
2. Entkommentieren Sie die Datenbank-Umgebungsvariablen im `dtrack-apiserver` Service
3. Passen Sie die Passwörter an
4. Starten Sie die Services neu:

```powershell
docker compose up -d
```

### Frontend API URL ändern

Wenn Sie Dependency-Track auf einem Server betreiben, ändern Sie:

```yaml
environment:
  - API_BASE_URL=http://your-server-ip:8081
```

## 📊 Systemanforderungen

### Minimum
- **API Server**: 4.5 GB RAM, 2 CPU Cores
- **Frontend**: 512 MB RAM, 1 CPU Core
- **Festplatte**: 10 GB

### Empfohlen
- **API Server**: 16 GB RAM, 4 CPU Cores
- **Frontend**: 1 GB RAM, 2 CPU Cores
- **Festplatte**: 50 GB

### Anforderungen deaktivieren (nur Development!)

```yaml
environment:
  - SYSTEM_REQUIREMENT_CHECK_ENABLED=false
```

## 🔐 Sicherheit

### Produktions-Checkliste

- [ ] Standard-Admin-Passwort ändern
- [ ] PostgreSQL statt H2 InMemory verwenden
- [ ] Starke Datenbank-Passwörter setzen
- [ ] HTTPS mit Reverse Proxy (nginx/traefik) einrichten
- [ ] Firewall-Regeln konfigurieren
- [ ] Regelmäßige Backups des Volumes einrichten
- [ ] LDAP/OpenID Connect für Single Sign-On konfigurieren

## 📖 Verwendung

### SBOM hochladen

1. Öffnen Sie http://localhost:8080
2. Erstellen Sie ein neues Projekt
3. Laden Sie eine SBOM-Datei hoch (CycloneDX, SPDX)
4. Warten Sie auf die Analyse
5. Überprüfen Sie die identifizierten Schwachstellen

### CI/CD Integration

Dependency-Track bietet APIs für CI/CD-Integration:

```powershell
# Beispiel: SBOM hochladen via API
$apiKey = "your-api-key"
$projectName = "MyProject"
$projectVersion = "1.0.0"

# SBOM generieren und hochladen
# siehe: https://docs.dependencytrack.org/usage/cicd/
```

## 🔍 Troubleshooting

### Problem: Container startet nicht

```powershell
# Logs prüfen
docker compose logs dtrack-apiserver

# Oft: Nicht genug RAM
# Lösung: Docker Desktop RAM erhöhen (Settings > Resources)
```

### Problem: Port bereits belegt

```yaml
# Ändern Sie die Ports in docker-compose.yml
ports:
  - "8082:8080"  # Statt 8081
```

### Problem: Langsamer Start

Der erste Start dauert 2-5 Minuten, da:
- Datenbank initialisiert wird
- NVD-Daten heruntergeladen werden
- Indizes erstellt werden

```powershell
# Fortschritt überwachen
docker compose logs -f dtrack-apiserver
```

### Problem: "Unhealthy" Status

```powershell
# Health-Status prüfen
docker compose ps

# Warten Sie 2-3 Minuten nach dem Start
# API Server braucht Zeit zum Initialisieren
```

## 📚 Weitere Ressourcen

- **Offizielle Dokumentation**: https://docs.dependencytrack.org/
- **GitHub Repository**: https://github.com/DependencyTrack/dependency-track
- **Docker Hub**: https://hub.docker.com/r/dependencytrack/
- **Community**: https://dependencytrack.org/community

## 🤝 Support

- **Issues**: https://github.com/DependencyTrack/dependency-track/issues
- **Slack**: https://owasp.slack.com (#dependency-track)
- **Discussions**: https://github.com/DependencyTrack/dependency-track/discussions

## 📄 Lizenz

Dependency-Track ist unter der Apache License 2.0 lizenziert.

---

**Hinweis**: Diese Konfiguration ist für Development und Testing optimiert. Für Production-Umgebungen sollten Sie zusätzliche Sicherheitsmaßnahmen implementieren.
