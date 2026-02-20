# 🚀 SCHNELLSTART-ANLEITUNG

## Voraussetzungen prüfen

Bevor Sie starten, stellen Sie sicher, dass Sie folgende Software installiert haben:

1. **.NET 10 SDK** - Download: https://dotnet.microsoft.com/download
   ```powershell
   dotnet --version
   ```

2. **Node.js** (Version 18+) - Download: https://nodejs.org
   ```powershell
   node --version
   npm --version
   ```

## ⚡ Anwendung starten

### Schritt 1: Backend starten

Öffnen Sie ein PowerShell-Terminal und führen Sie aus:

```powershell
cd c:\Users\tse\source\repos\DepdendencyTrack\Backend
dotnet run --urls "http://localhost:5000"
```

✅ Das Backend läuft jetzt auf http://localhost:5000
✅ Swagger UI ist verfügbar unter http://localhost:5000/swagger

**Lassen Sie dieses Terminal geöffnet!**

---

### Schritt 2: Frontend starten

Öffnen Sie ein **NEUES** PowerShell-Terminal und führen Sie aus:

```powershell
cd c:\Users\tse\source\repos\DepdendencyTrack\Frontend
npm install
npm run dev
```

✅ Das Frontend läuft jetzt auf http://localhost:3000

**Lassen Sie auch dieses Terminal geöffnet!**

---

## 🌐 Anwendung öffnen

Öffnen Sie Ihren Browser und navigieren Sie zu:

**http://localhost:3000**

Sie sollten jetzt den Online Shop mit 6 Produkten sehen! 🎉

---

## 🛑 Anwendung beenden

Um die Anwendung zu stoppen:
- Drücken Sie `STRG + C` in beiden Terminal-Fenstern

---

## 🔧 Troubleshooting

### Problem: Port 5000 ist bereits belegt
```powershell
# Ändern Sie den Port im Backend
dotnet run --urls "http://localhost:5001"

# Ändern Sie auch die URL im Frontend:
# Datei: Frontend/src/App.jsx
# Zeile: const response = await fetch('http://localhost:5001/api/products')
```

### Problem: Port 3000 ist bereits belegt
Der Vite-Server wird automatisch einen anderen Port (z.B. 3001) vorschlagen.
Folgen Sie einfach der Meldung im Terminal.

### Problem: npm install schlägt fehl
```powershell
# Cache löschen und erneut versuchen
npm cache clean --force
npm install
```

### Problem: .NET SDK nicht gefunden
Installieren Sie das .NET 10 SDK von https://dotnet.microsoft.com/download

---

## 📝 Hilfreiche Befehle

### Backend
```powershell
# Projekt erstmalig wiederherstellen
dotnet restore

# Projekt bauen
dotnet build

# Projekt ausführen
dotnet run
```

### Frontend
```powershell
# Dependencies installieren
npm install

# Entwicklungsserver starten
npm run dev

# Production Build erstellen
npm run build

# Production Build testen
npm run preview
```

---

## 🎯 API Testen

Sie können die API auch direkt testen:

### Mit dem Browser
- Öffnen Sie: http://localhost:5000/swagger

### Mit PowerShell
```powershell
# Alle Produkte abrufen
Invoke-WebRequest -Uri http://localhost:5000/api/products | Select-Object -Expand Content

# Einzelnes Produkt abrufen
Invoke-WebRequest -Uri http://localhost:5000/api/products/1 | Select-Object -Expand Content
```

---

## 💡 Nächste Schritte

Nach erfolgreichem Start können Sie:
- Die Produktliste im Browser erkunden
- Neue Produkte in `Backend/Data/ShopContext.cs` hinzufügen
- Das Design in den CSS-Dateien anpassen
- Neue Features im Frontend oder Backend implementieren

Viel Erfolg! 🚀
