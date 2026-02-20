# Online Shop Anwendung

Eine vollständige Shop-Anwendung mit React Frontend und .NET 10 Backend.

## 🎯 Funktionen

- Anzeige von Produkten in einer ansprechenden Grid-Ansicht
- InMemory-Datenbank mit vordefinierten Produkten
- Responsive Design für Desktop und Mobile
- REST API mit .NET 10
- React Frontend mit Vite

## 📁 Projektstruktur

```
DepdendencyTrack/
├── Backend/              # .NET 10 Web API
│   ├── Controllers/      # API Controller
│   ├── Data/            # Datenbankkontext
│   ├── Models/          # Datenmodelle
│   └── Program.cs       # Einstiegspunkt
└── Frontend/            # React Applikation
    ├── src/
    │   ├── components/  # React Komponenten
    │   ├── App.jsx      # Hauptkomponente
    │   └── main.jsx     # Einstiegspunkt
    └── package.json
```

## 🚀 Installation & Start

### Backend (Port 5000)

1. Navigieren Sie zum Backend-Ordner:
```powershell
cd Backend
```

2. Stellen Sie sicher, dass .NET 10 SDK installiert ist:
```powershell
dotnet --version
```

3. Starten Sie die API:
```powershell
dotnet run --urls "http://localhost:5000"
```

Die API läuft auf: `http://localhost:5000`
Swagger UI: `http://localhost:5000/swagger`

### Frontend (Port 3000)

1. Öffnen Sie ein neues Terminal und navigieren Sie zum Frontend-Ordner:
```powershell
cd Frontend
```

2. Installieren Sie die Dependencies:
```powershell
npm install
```

3. Starten Sie die React-Applikation:
```powershell
npm run dev
```

Die Anwendung läuft auf: `http://localhost:3000`

## 📋 API Endpoints

- `GET /api/products` - Alle Produkte abrufen
- `GET /api/products/{id}` - Einzelnes Produkt abrufen

## 🛠️ Technologien

### Backend
- .NET 10
- ASP.NET Core Web API
- Entity Framework Core (InMemory)
- Swagger/OpenAPI

### Frontend
- React 18
- Vite
- CSS3
- JavaScript (ES6+)

## 📦 Enthaltene Produkte

Die InMemory-Datenbank enthält folgende Beispielprodukte:
- Laptop (€1.299,99)
- Smartphone (€899,99)
- Kopfhörer (€199,99)
- Tastatur (€129,99)
- Maus (€49,99)
- Monitor (€549,99)

## 🎨 Features

- ✅ Moderne, benutzerfreundliche UI
- ✅ Responsive Design
- ✅ Produktbilder von Unsplash
- ✅ Lagerbestandsanzeige
- ✅ Preis-Formatierung (EUR)
- ✅ Hover-Effekte und Animationen
- ✅ Fehlerbehandlung

## 📝 Hinweise

- Das Backend verwendet eine InMemory-Datenbank, daher gehen alle Daten bei Neustart verloren
- CORS ist für localhost:3000 und localhost:5173 konfiguriert
- Die Produktbilder werden von Unsplash geladen

## 🔧 Entwicklung

### Backend erweitern
Fügen Sie neue Produkte in der Datei `Backend/Data/ShopContext.cs` hinzu.

### Frontend anpassen
Die Komponenten befinden sich im Ordner `Frontend/src/components/`.

## 📄 Lizenz

Dieses Projekt ist für Lernzwecke erstellt.
