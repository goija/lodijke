# Fotomodule — Rust Axum (Lodijke Archief)

Uitgebreide fotomodule met beheerinterface voor het archief van Familie Schot,
Bout & Bol van Lodijke (Tholen). Server draait op poort 8082, naast het bestaande CMS.

## Starten
```bash
cd rust/fotomodule
cargo run --release
```

- Beheerinterface: http://127.0.0.1:8082/admin
- Foto's (static): http://127.0.0.1:8082/uploads/<bestand>

## API

| Methode | Route | Beschrijving |
|---|---|---|
| GET | `/api/photos?q=&category=&limit=&offset=` | Lijst met zoeken/filteren |
| POST | `/api/photos` | Multipart-upload (`file,title,category,year,location,desc`) |
| GET | `/api/photos/:id` | Eén foto |
| PATCH | `/api/photos/:id` | Metadata bewerken (JSON) |
| DELETE | `/api/photos/:id` | Verwijderen incl. bestand |
| GET | `/api/photos/stats` | Statistieken |
| GET | `/api/photos/export` | Volledige database als JSON |
| POST | `/api/photos/import` | Import (ook Solid POD `dataUrl`-formaat) |
| GET/POST | `/api/categories` | Categorieen beheren |

De import-endpoint accepteert de JSON-export van het bestaande front-end
(zowel `;base64,`- als `;utf8,`-gecodeerde data-URL's, waaronder de SVG-platen).

## Opslag
- `data/photos.json` + `data/categories.json` — metadata
- `uploads/` — afbeeldingsbestanden
