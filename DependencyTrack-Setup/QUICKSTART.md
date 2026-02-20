# 🚀 Dependency-Track Schnellstart

## Start

```powershell
docker compose up -d
```

## Zugriff

- **URL**: http://localhost:8080
- **Benutzername**: `admin`
- **Passwort**: `admin`

⚠️ Passwort nach dem ersten Login ändern!

## Warten auf Start

Beim ersten Start: 2-3 Minuten warten

```powershell
# Status prüfen
docker compose ps

# Logs verfolgen
docker compose logs -f
```

## Stop

```powershell
docker compose down
```

## Logs

```powershell
# Alle Services
docker compose logs -f

# Nur API
docker compose logs -f dtrack-apiserver
```

## Problemlösung

### Container startet nicht
- Docker Desktop RAM erhöhen (min. 10 GB)
- Logs prüfen: `docker compose logs`

### Port belegt
Ändere Ports in `docker-compose.yml`

## Dokumentation

https://docs.dependencytrack.org/
