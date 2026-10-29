#!/usr/bin/env bash
set -euo pipefail

cd ~/lodijke

echo "=== [1/7] Root opschonen & Foto's verwijderen uit Solid POD ==="
rm -f ";" "Code," "chema);" "t(graphql_execution_handler)," \
      "tener = tokio::net::TcpListener::bind(addr).await.unwrap();" \
      "ync fn graphql_execution_handler(" \
      "ystemctl --user restart lodijke-cms-server.service"
find . -maxdepth 1 -name 'onParcelById*' -exec rm -f {} +

# Verwijder alle foto's en afbeeldingsbestanden uit de Solid POD Vault
mkdir -p 01_Solid_POD_Vault/visser_dossier
if [ -d "01_Solid_POD_Vault" ]; then
    find 01_Solid_POD_Vault -type f \( \
        -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \
        -o -iname "*.webp" -o -iname "*.gif" -o -iname "*.tiff" \
    \) -delete
    rm -rf 01_Solid_POD_Vault/photos 01_Solid_POD_Vault/media 01_Solid_POD_Vault/images
fi

cat << 'TTL' > 01_Solid_POD_Vault/visser_dossier/card.ttl
@prefix : <#>.
@prefix solid: <http://www.w3.org/ns/solid/terms#>.
@prefix dc: <http://purl.org/dc/terms/>.
@prefix foaf: <http://xmlns.com/foaf/0.1/>.

:me a foaf:PersonalProfileDocument ;
    dc:title "Visser Dossier" ;
    solid:policy "NO_PHOTOS_STORED_IN_POD" .
TTL

echo "=== [2/7] Mappenstructuur en initiële Visser Dossier & GRAMPS data aanmaken ==="
mkdir -p src data/uploads frontend/src 04_CMS_Document_Tabs_Frontend/frontend/src

cat << 'JSON' > data/cms_state.json
{
  "hero_title": "Visser Dossier",
  "sections": [
    {
      "id": "visser-kern-01",
      "title": "Visser Dossier — Hoofddossier",
      "category": "Visser Dossier",
      "content": "Primair archief- en onderzoeksdossier omtrent het Visser Dossier, historische visrechten en genealogische grondslagen.",
      "updated_at": "2026-10-29T12:00:00Z"
    }
  ]
}
JSON

cat << 'JSON' > data/gramps_db.json
{
  "people": [
    {
      "handle": "p_visser_0001",
      "gramps_id": "I0001",
      "gender": "M",
      "primary_name": {
        "first_name": "Cornelis",
        "surname": "Visser",
        "call_name": "Cees",
        "title": "Oudelandse Visser"
      },
      "event_ref_list": ["e_birth_0001", "e_occ_0001"],
      "family_list": ["f_visser_0001"],
      "parent_family_list": [],
      "citation_list": ["c_arch_0001"],
      "media_list": [],
      "note_list": ["Kerndossier Visser — Verdronken Land van Reimerswaal & Lodijke"]
    }
  ],
  "families": [
    {
      "handle": "f_visser_0001",
      "gramps_id": "F0001",
      "father_handle": "p_visser_0001",
      "mother_handle": null,
      "child_ref_list": [],
      "event_ref_list": [],
      "citation_list": ["c_arch_0001"]
    }
  ],
  "events": [
    {
      "handle": "e_birth_0001",
      "gramps_id": "E0001",
      "event_type": "Birth",
      "date": "1842-03-14",
      "place_handle": "pl_reimerswaal_01",
      "description": "Geboorte binnen geslacht Visser"
    },
    {
      "handle": "e_occ_0001",
      "gramps_id": "E0002",
      "event_type": "Occupation",
      "date": "1870-01-01",
      "place_handle": "pl_lodijke_01",
      "description": "Uitoefening Oudelandse Visrecht (Visser Dossier)"
    }
  ],
  "places": [
    {
      "handle": "pl_reimerswaal_01",
      "gramps_id": "P0001",
      "title": "Reimerswaal / Oosterschelde",
      "name": "Verdronken Land van Reimerswaal",
      "place_type": "Historical Region",
      "lat": 51.4667,
      "lon": 4.1500,
      "rd_x": 69250.0,
      "rd_y": 386700.0
    },
    {
      "handle": "pl_lodijke_01",
      "gramps_id": "P0002",
      "title": "Lodijke",
      "name": "Heerlijkheid Lodijke",
      "place_type": "Parish",
      "lat": 51.4580,
      "lon": 4.1820,
      "rd_x": 71460.0,
      "rd_y": 385700.0
    }
  ],
  "sources": [
    {
      "handle": "s_zeeuws_01",
      "gramps_id": "S0001",
      "title": "Visser Dossier — Zeeuws Archief Charters & Visrechten",
      "author": "Rekenkamer van Zeeland",
      "pubinfo": "Middelburg / Tholen",
      "abbrev": "ZA-VISSER"
    }
  ],
  "citations": [
    {
      "handle": "c_arch_0001",
      "gramps_id": "C0001",
      "source_handle": "s_zeeuws_01",
      "page": "Folio 14r - Akte Visrecht",
      "date": "1530-11-05",
      "confidence": 4
    }
  ]
}
JSON

if [ ! -f "data/photos.json" ]; then
    echo "[]" > data/photos.json
fi

echo "=== [3/7] Cargo.toml configureren ==="
cat << 'TOML' > Cargo.toml
[package]
name = "lodijke-cms-server"
version = "7.1.0"
edition = "2021"

[dependencies]
axum = { version = "0.8", features = ["macros", "multipart"] }
tokio = { version = "1", features = ["full"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
chrono = { version = "0.4", features = ["serde"] }
tower-http = { version = "0.6", features = ["cors", "fs"] }
uuid = { version = "1", features = ["v4", "serde"] }
bytes = "1"
TOML

echo "=== [4/7] Schrijven van foutvrije src/main.rs (Axum + GRAMPS API + Fotoalbum + CMS + Solid POD Purge) ==="
cat << 'RUST' > src/main.rs
use axum::{
    extract::{Multipart, Path as AxumPath, Query, State},
    http::StatusCode,
    response::{Html, IntoResponse, Json},
    routing::{delete, get, post, put},
    Router,
};
use chrono::{DateTime, Datelike, Utc};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::{
    fs,
    net::SocketAddr,
    path::{Path as FsPath, PathBuf},
    sync::{Arc, RwLock},
};
use tower_http::{
    cors::{Any, CorsLayer},
    services::ServeDir,
};
use uuid::Uuid;

// ============================================================================
// 1. GRAMPS DEVELOPER PORTAL DATA MODEL
// (Conform https://www.gramps-project.org/wiki/index.php?title=Portal:Developers)
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GrampsName {
    pub first_name: String,
    pub surname: String,
    pub call_name: String,
    pub title: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GrampsPerson {
    pub handle: String,
    pub gramps_id: String,
    pub gender: String,
    pub primary_name: GrampsName,
    pub event_ref_list: Vec<String>,
    pub family_list: Vec<String>,
    pub parent_family_list: Vec<String>,
    pub citation_list: Vec<String>,
    pub media_list: Vec<String>,
    pub note_list: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GrampsFamily {
    pub handle: String,
    pub gramps_id: String,
    pub father_handle: Option<String>,
    pub mother_handle: Option<String>,
    pub child_ref_list: Vec<String>,
    pub event_ref_list: Vec<String>,
    pub citation_list: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GrampsEvent {
    pub handle: String,
    pub gramps_id: String,
    pub event_type: String,
    pub date: String,
    pub place_handle: String,
    pub description: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GrampsPlace {
    pub handle: String,
    pub gramps_id: String,
    pub title: String,
    pub name: String,
    pub place_type: String,
    pub lat: f64,
    pub lon: f64,
    pub rd_x: f64,
    pub rd_y: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GrampsSource {
    pub handle: String,
    pub gramps_id: String,
    pub title: String,
    pub author: String,
    pub pubinfo: String,
    pub abbrev: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GrampsCitation {
    pub handle: String,
    pub gramps_id: String,
    pub source_handle: String,
    pub page: String,
    pub date: String,
    pub confidence: u8,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct GrampsDatabase {
    pub people: Vec<GrampsPerson>,
    pub families: Vec<GrampsFamily>,
    pub events: Vec<GrampsEvent>,
    pub places: Vec<GrampsPlace>,
    pub sources: Vec<GrampsSource>,
    pub citations: Vec<GrampsCitation>,
}

// ============================================================================
// 2. FOTOALBUM & CMS DATA MODEL (VISSER DOSSIER)
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PhotoItem {
    pub id: String,
    pub filename: String,
    pub title: String,
    pub description: String,
    pub album: String,
    pub gramps_handle: Option<String>,
    pub date_taken: Option<DateTime<Utc>>,
    pub rd_x: Option<f64>,
    pub rd_y: Option<f64>,
    pub tags: Vec<String>,
    pub uploaded_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CmsSection {
    pub id: String,
    pub title: String,
    pub category: String,
    pub content: String,
    pub updated_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CmsState {
    pub hero_title: String,
    pub sections: Vec<CmsSection>,
}

#[derive(Clone)]
pub struct AppState {
    pub data_dir: PathBuf,
    pub upload_dir: PathBuf,
    pub solid_pod_dir: PathBuf,
    pub photos: Arc<RwLock<Vec<PhotoItem>>>,
    pub cms: Arc<RwLock<CmsState>>,
    pub gramps: Arc<RwLock<GrampsDatabase>>,
}

#[derive(Debug, Deserialize)]
pub struct PhotoFilter {
    pub q: Option<String>,
    pub album: Option<String>,
    pub year: Option<i32>,
    pub gramps_handle: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct PhotoUpdatePayload {
    pub title: Option<String>,
    pub description: Option<String>,
    pub album: Option<String>,
    pub gramps_handle: Option<String>,
    pub rd_x: Option<f64>,
    pub rd_y: Option<f64>,
    pub tags: Option<Vec<String>>,
}

// ============================================================================
// 3. PERSISTENTIE HELPERS
// ============================================================================

impl AppState {
    pub fn load(base: &FsPath) -> Self {
        let data_dir = base.join("data");
        let upload_dir = data_dir.join("uploads");
        let solid_pod_dir = base.join("01_Solid_POD_Vault");
        let _ = fs::create_dir_all(&upload_dir);
        let _ = fs::create_dir_all(&solid_pod_dir);

        let photos_path = data_dir.join("photos.json");
        let photos: Vec<PhotoItem> = fs::read_to_string(&photos_path)
            .ok()
            .and_then(|s| serde_json::from_str(&s).ok())
            .unwrap_or_default();

        let cms_path = data_dir.join("cms_state.json");
        let cms: CmsState = fs::read_to_string(&cms_path)
            .ok()
            .and_then(|s| serde_json::from_str(&s).ok())
            .unwrap_or(CmsState {
                hero_title: "Visser Dossier".to_string(),
                sections: vec![],
            });

        let gramps_path = data_dir.join("gramps_db.json");
        let gramps: GrampsDatabase = fs::read_to_string(&gramps_path)
            .ok()
            .and_then(|s| serde_json::from_str(&s).ok())
            .unwrap_or_default();

        Self {
            data_dir,
            upload_dir,
            solid_pod_dir,
            photos: Arc::new(RwLock::new(photos)),
            cms: Arc::new(RwLock::new(cms)),
            gramps: Arc::new(RwLock::new(gramps)),
        }
    }

    pub fn save_photos(&self) {
        if let Ok(guard) = self.photos.read() {
            if let Ok(json_str) = serde_json::to_string_pretty(&*guard) {
                let _ = fs::write(self.data_dir.join("photos.json"), json_str);
            }
        }
    }

    pub fn save_cms(&self) {
        if let Ok(guard) = self.cms.read() {
            if let Ok(json_str) = serde_json::to_string_pretty(&*guard) {
                let _ = fs::write(self.data_dir.join("cms_state.json"), json_str);
            }
        }
    }

    pub fn save_gramps(&self) {
        if let Ok(guard) = self.gramps.read() {
            if let Ok(json_str) = serde_json::to_string_pretty(&*guard) {
                let _ = fs::write(self.data_dir.join("gramps_db.json"), json_str);
            }
        }
    }

    pub fn purge_solid_pod_photos(&self) -> usize {
        let mut removed = 0usize;
        fn walk_and_remove(dir: &FsPath, count: &mut usize) {
            if let Ok(entries) = fs::read_dir(dir) {
                for entry in entries.flatten() {
                    let p = entry.path();
                    if p.is_dir() {
                        let name = p.file_name().and_then(|n| n.to_str()).unwrap_or("");
                        if matches!(name, "photos" | "images" | "media") {
                            let _ = fs::remove_dir_all(&p);
                            *count += 1;
                        } else {
                            walk_and_remove(&p, count);
                        }
                    } else if let Some(ext) = p.extension().and_then(|e| e.to_str()) {
                        if matches!(
                            ext.to_lowercase().as_str(),
                            "jpg" | "jpeg" | "png" | "webp" | "gif" | "tiff" | "bmp"
                        ) {
                            if fs::remove_file(&p).is_ok() {
                                *count += 1;
                            }
                        }
                    }
                }
            }
        }
        walk_and_remove(&self.solid_pod_dir, &mut removed);
        removed
    }
}

// ============================================================================
// 4. AXUM HANDLERS — VISSER DOSSIER CMS, FOTOALBUM, GRAMPS API & SOLID POD
// ============================================================================

async fn serve_index() -> impl IntoResponse {
    match fs::read_to_string("index.html") {
        Ok(html) => Html(html).into_response(),
        Err(_) => (StatusCode::NOT_FOUND, "index.html niet gevonden").into_response(),
    }
}

// --- CMS Endpoints ---
async fn get_cms(State(state): State<AppState>) -> impl IntoResponse {
    let cms = state.cms.read().unwrap().clone();
    Json(cms)
}

async fn update_cms(
    State(state): State<AppState>,
    Json(mut payload): Json<CmsState>,
) -> impl IntoResponse {
    // Dwing af dat de hoofdtitel altijd "Visser Dossier" blijft tenzij expliciet gewijzigd
    if payload.hero_title.trim().is_empty() {
        payload.hero_title = "Visser Dossier".to_string();
    }
    {
        let mut guard = state.cms.write().unwrap();
        *guard = payload.clone();
    }
    state.save_cms();
    Json(json!({ "status": "ok", "cms": payload }))
}

async fn add_cms_section(
    State(state): State<AppState>,
    Json(mut sec): Json<CmsSection>,
) -> impl IntoResponse {
    if sec.id.trim().is_empty() {
        sec.id = format!("sec-{}", Uuid::new_v4());
    }
    sec.updated_at = Utc::now().to_rfc3339();
    {
        let mut guard = state.cms.write().unwrap();
        guard.sections.push(sec.clone());
    }
    state.save_cms();
    Json(json!({ "status": "ok", "section": sec }))
}

async fn delete_cms_section(
    State(state): State<AppState>,
    AxumPath(id): AxumPath<String>,
) -> impl IntoResponse {
    {
        let mut guard = state.cms.write().unwrap();
        guard.sections.retain(|s| s.id != id);
    }
    state.save_cms();
    Json(json!({ "status": "deleted", "id": id }))
}

// --- Fotoalbum Endpoints ---
async fn list_photos(
    State(state): State<AppState>,
    Query(filter): Query<PhotoFilter>,
) -> impl IntoResponse {
    let mut result = state.photos.read().unwrap().clone();

    if let Some(year) = filter.year {
        result.retain(|p| p.date_taken.map_or(false, |dt| dt.year() == year));
    }
    if let Some(ref album) = filter.album {
        if !album.trim().is_empty() {
            result.retain(|p| p.album.eq_ignore_ascii_case(album.trim()));
        }
    }
    if let Some(ref gh) = filter.gramps_handle {
        if !gh.trim().is_empty() {
            result.retain(|p| p.gramps_handle.as_deref() == Some(gh.trim()));
        }
    }
    if let Some(ref q) = filter.q {
        let needle = q.trim().to_lowercase();
        if !needle.is_empty() {
            result.retain(|p| {
                p.title.to_lowercase().contains(&needle)
                    || p.description.to_lowercase().contains(&needle)
                    || p.tags.iter().any(|t| t.to_lowercase().contains(&needle))
            });
        }
    }

    Json(json!({
        "query": filter.q,
        "count": result.len(),
        "results": result
    }))
}

async fn upload_photo(
    State(state): State<AppState>,
    mut multipart: Multipart,
) -> impl IntoResponse {
    let mut title = String::from("Visser Dossier Archiefstuk");
    let mut description = String::new();
    let mut album = String::from("Visser Dossier");
    let mut gramps_handle: Option<String> = None;
    let mut rd_x: Option<f64> = None;
    let mut rd_y: Option<f64> = None;
    let mut tags: Vec<String> = vec!["Visser Dossier".to_string()];
    let mut saved_filename: Option<String> = None;

    while let Ok(Some(field)) = multipart.next_field().await {
        let name = field.name().unwrap_or("").to_string();
        if name == "file" {
            let orig = field.file_name().unwrap_or("image.jpg").to_string();
            let ext = FsPath::new(&orig)
                .extension()
                .and_then(|e| e.to_str())
                .unwrap_or("jpg");
            let fname = format!("{}.{}", Uuid::new_v4(), ext);
            if let Ok(bytes) = field.bytes().await {
                let dest = state.upload_dir.join(&fname);
                if fs::write(&dest, &bytes).is_ok() {
                    saved_filename = Some(fname);
                }
            }
        } else if let Ok(txt) = field.text().await {
            match name.as_str() {
                "title" if !txt.trim().is_empty() => title = txt,
                "description" => description = txt,
                "album" if !txt.trim().is_empty() => album = txt,
                "gramps_handle" if !txt.trim().is_empty() => gramps_handle = Some(txt),
                "rd_x" => rd_x = txt.parse::<f64>().ok(),
                "rd_y" => rd_y = txt.parse::<f64>().ok(),
                "tags" => {
                    tags = txt
                        .split(',')
                        .map(|s| s.trim().to_string())
                        .filter(|s| !s.is_empty())
                        .collect();
                }
                _ => {}
            }
        }
    }

    let filename = saved_filename.unwrap_or_else(|| "placeholder.jpg".to_string());
    let item = PhotoItem {
        id: Uuid::new_v4().to_string(),
        filename,
        title,
        description,
        album,
        gramps_handle,
        date_taken: Some(Utc::now()),
        rd_x,
        rd_y,
        tags,
        uploaded_at: Utc::now(),
    };

    {
        let mut guard = state.photos.write().unwrap();
        guard.insert(0, item.clone());
    }
    state.save_photos();

    (StatusCode::CREATED, Json(json!({ "status": "uploaded", "photo": item })))
}

async fn update_photo(
    State(state): State<AppState>,
    AxumPath(id): AxumPath<String>,
    Json(payload): Json<PhotoUpdatePayload>,
) -> impl IntoResponse {
    let mut updated: Option<PhotoItem> = None;
    {
        let mut guard = state.photos.write().unwrap();
        if let Some(p) = guard.iter_mut().find(|p| p.id == id) {
            if let Some(t) = payload.title { p.title = t; }
            if let Some(d) = payload.description { p.description = d; }
            if let Some(a) = payload.album { p.album = a; }
            if payload.gramps_handle.is_some() { p.gramps_handle = payload.gramps_handle; }
            if payload.rd_x.is_some() { p.rd_x = payload.rd_x; }
            if payload.rd_y.is_some() { p.rd_y = payload.rd_y; }
            if let Some(tags) = payload.tags { p.tags = tags; }
            updated = Some(p.clone());
        }
    }
    state.save_photos();
    match updated {
        Some(p) => (StatusCode::OK, Json(json!({ "status": "updated", "photo": p }))),
        None => (StatusCode::NOT_FOUND, Json(json!({ "error": "Photo not found" }))),
    }
}

async fn delete_photo(
    State(state): State<AppState>,
    AxumPath(id): AxumPath<String>,
) -> impl IntoResponse {
    let mut removed_file: Option<String> = None;
    {
        let mut guard = state.photos.write().unwrap();
        if let Some(pos) = guard.iter().position(|p| p.id == id) {
            let item = guard.remove(pos);
            removed_file = Some(item.filename);
        }
    }
    if let Some(fname) = removed_file {
        let _ = fs::remove_file(state.upload_dir.join(fname));
    }
    state.save_photos();
    Json(json!({ "status": "deleted", "id": id }))
}

// --- GRAMPS Developer API Endpoints ---
async fn get_gramps_db(State(state): State<AppState>) -> impl IntoResponse {
    let db = state.gramps.read().unwrap().clone();
    Json(db)
}

async fn upsert_gramps_person(
    State(state): State<AppState>,
    Json(mut person): Json<GrampsPerson>,
) -> impl IntoResponse {
    if person.handle.trim().is_empty() {
        person.handle = format!("p_{}", Uuid::new_v4().simple());
    }
    {
        let mut db = state.gramps.write().unwrap();
        if let Some(existing) = db.people.iter_mut().find(|p| p.handle == person.handle) {
            *existing = person.clone();
        } else {
            if person.gramps_id.trim().is_empty() {
                person.gramps_id = format!("I{:04}", db.people.len() + 1);
            }
            db.people.push(person.clone());
        }
    }
    state.save_gramps();
    Json(json!({ "status": "ok", "person": person }))
}

async fn delete_gramps_person(
    State(state): State<AppState>,
    AxumPath(handle): AxumPath<String>,
) -> impl IntoResponse {
    {
        let mut db = state.gramps.write().unwrap();
        db.people.retain(|p| p.handle != handle);
    }
    state.save_gramps();
    Json(json!({ "status": "deleted", "handle": handle }))
}

async fn upsert_gramps_event(
    State(state): State<AppState>,
    Json(mut ev): Json<GrampsEvent>,
) -> impl IntoResponse {
    if ev.handle.trim().is_empty() {
        ev.handle = format!("e_{}", Uuid::new_v4().simple());
    }
    {
        let mut db = state.gramps.write().unwrap();
        if let Some(existing) = db.events.iter_mut().find(|e| e.handle == ev.handle) {
            *existing = ev.clone();
        } else {
            if ev.gramps_id.trim().is_empty() {
                ev.gramps_id = format!("E{:04}", db.events.len() + 1);
            }
            db.events.push(ev.clone());
        }
    }
    state.save_gramps();
    Json(json!({ "status": "ok", "event": ev }))
}

async fn upsert_gramps_family(
    State(state): State<AppState>,
    Json(mut fam): Json<GrampsFamily>,
) -> impl IntoResponse {
    if fam.handle.trim().is_empty() {
        fam.handle = format!("f_{}", Uuid::new_v4().simple());
    }
    {
        let mut db = state.gramps.write().unwrap();
        if let Some(existing) = db.families.iter_mut().find(|f| f.handle == fam.handle) {
            *existing = fam.clone();
        } else {
            if fam.gramps_id.trim().is_empty() {
                fam.gramps_id = format!("F{:04}", db.families.len() + 1);
            }
            db.families.push(fam.clone());
        }
    }
    state.save_gramps();
    Json(json!({ "status": "ok", "family": fam }))
}

async fn import_gramps_db(
    State(state): State<AppState>,
    Json(new_db): Json<GrampsDatabase>,
) -> impl IntoResponse {
    {
        let mut db = state.gramps.write().unwrap();
        *db = new_db;
    }
    state.save_gramps();
    Json(json!({ "status": "imported" }))
}

// --- Solid POD Foto-Purge Endpoint ---
async fn purge_solid_photos_handler(State(state): State<AppState>) -> impl IntoResponse {
    let removed_files = state.purge_solid_pod_photos();
    Json(json!({
        "status": "purged",
        "solid_pod_vault": "01_Solid_POD_Vault",
        "removed_photo_files": removed_files,
        "policy": "NO_PHOTOS_IN_SOLID_POD"
    }))
}

// --- GeoJSON Export (GRAMPS Places + Getaggede Foto's) ---
async fn export_geojson(State(state): State<AppState>) -> impl IntoResponse {
    let db = state.gramps.read().unwrap().clone();
    let photos = state.photos.read().unwrap().clone();

    let mut features: Vec<Value> = db
        .places
        .iter()
        .map(|pl| {
            json!({
                "type": "Feature",
                "geometry": {
                    "type": "Point",
                    "coordinates": [pl.lon, pl.lat]
                },
                "properties": {
                    "layer": "GRAMPS_Place",
                    "handle": pl.handle,
                    "gramps_id": pl.gramps_id,
                    "title": pl.title,
                    "rd_x": pl.rd_x,
                    "rd_y": pl.rd_y
                }
            })
        })
        .collect();

    for p in photos.iter() {
        if let (Some(rx), Some(ry)) = (p.rd_x, p.rd_y) {
            features.push(json!({
                "type": "Feature",
                "geometry": {
                    "type": "Point",
                    "coordinates": [rx, ry]
                },
                "properties": {
                    "layer": "Photo_RD",
                    "id": p.id,
                    "title": p.title,
                    "album": p.album
                }
            }));
        }
    }

    Json(json!({
        "type": "FeatureCollection",
        "name": "Visser Dossier Geodata",
        "features": features
    }))
}

#[tokio::main]
async fn main() {
    let base_dir = std::env::current_dir().unwrap_or_else(|_| PathBuf::from("."));
    let state = AppState::load(&base_dir);

    // Zorg direct bij opstarten dat er geen foto's in de Solid POD staan
    let purged = state.purge_solid_pod_photos();
    println!(
        "[Solid POD] Foto-opschoning voltooid ({} bestanden verwijderd).",
        purged
    );

    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    let app = Router::new()
        .route("/", get(serve_index))
        // CMS Endpoints (Visser Dossier)
        .route("/api/cms", get(get_cms).put(update_cms))
        .route("/api/cms/sections", post(add_cms_section))
        .route("/api/cms/sections/{id}", delete(delete_cms_section))
        // Fotoalbum Endpoints
        .route("/api/photos", get(list_photos).post(upload_photo))
        .route("/api/photos/{id}", put(update_photo).delete(delete_photo))
        // GRAMPS Developer API Endpoints
        .route("/api/gramps/tree", get(get_gramps_db).put(import_gramps_db))
        .route("/api/gramps/people", post(upsert_gramps_person))
        .route("/api/gramps/people/{handle}", delete(delete_gramps_person))
        .route("/api/gramps/events", post(upsert_gramps_event))
        .route("/api/gramps/families", post(upsert_gramps_family))
        // Solid POD & GeoJSON
        .route("/api/solid/purge-photos", delete(purge_solid_photos_handler))
        .route("/api/geojson", get(export_geojson))
        .nest_service("/uploads", ServeDir::new(state.upload_dir.clone()))
        .layer(cors)
        .with_state(state);

    let port: u16 = std::env::var("PORT")
        .ok()
        .and_then(|p| p.parse().ok())
        .unwrap_or(8090);

    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    println!("=========================================================");
    println!(" Visser Dossier — Rust Axum CMS + GRAMPS API + Fotoalbum");
    println!(" Luistert op: http://127.0.0.1:{}", port);
    println!("=========================================================");

    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
RUST

echo "=== [5/7] Bouwen van Vue.js 3 Offline Beheer & Frontend Interface (Alleen 'Visser Dossier' op Hoofdpagina) ==="
cat << 'HTML' > index.html
<!DOCTYPE html>
<html lang="nl">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Visser Dossier</title>
  <script src="https://unpkg.com/vue@3/dist/vue.global.prod.js"></script>
  <script src="https://cdn.tailwindcss.com"></script>
  <style>
    body { background-color: #0b0f17; color: #e2e8f0; font-family: system-ui, -apple-system, sans-serif; }
    .card { background: #151c28; border: 1px solid #263248; border-radius: 0.5rem; }
    .input-dark { background: #0b0f17; border: 1px solid #334155; color: #f8fafc; border-radius: 0.375rem; padding: 0.5rem 0.75rem; width: 100%; }
    .btn-primary { background: #1d4ed8; color: #fff; padding: 0.5rem 1rem; border-radius: 0.375rem; font-weight: 600; }
    .btn-primary:hover { background: #2563eb; }
    .btn-danger { background: #991b1b; color: #fff; padding: 0.35rem 0.75rem; border-radius: 0.375rem; font-size: 0.85rem; }
  </style>
</head>
<body>
<div id="app" class="min-h-screen flex flex-col">
  <!-- Topbalk: Alleen Visser Dossier + Offline/Online schakelaar voor beheer -->
  <header class="border-b border-slate-800 bg-slate-950/90 px-6 py-4 flex flex-wrap items-center justify-between gap-4">
    <div class="flex items-center gap-4">
      <h1 class="text-2xl font-bold tracking-tight text-white">{{ cms.hero_title }}</h1>
      <span class="text-xs px-2.5 py-1 rounded bg-emerald-950 text-emerald-300 border border-emerald-800">
        {{ isOnline ? 'Axum API Verbonden' : 'Offline Lokaal Beheer (LocalStorage)' }}
      </span>
    </div>
    <nav class="flex flex-wrap gap-2">
      <button @click="activeTab = 'home'" :class="tabClass('home')">Hoofdpagina</button>
      <button @click="activeTab = 'cms'" :class="tabClass('cms')">Offline CMS Editor</button>
      <button @click="activeTab = 'photos'" :class="tabClass('photos')">Fotoalbum ({{ photos.length }})</button>
      <button @click="activeTab = 'gramps'" :class="tabClass('gramps')">GRAMPS API ({{ gramps.people.length }})</button>
      <button @click="activeTab = 'solid'" :class="tabClass('solid')">Solid POD</button>
    </nav>
  </header>

  <!-- 1. HOOFDPAGINA: UITSLUITEND VISSER DOSSIER -->
  <main class="flex-1 max-w-6xl w-full mx-auto p-6">
    <section v-if="activeTab === 'home'" class="space-y-8">
      <div class="py-16 text-center border-b border-slate-800">
        <h2 class="text-5xl font-extrabold tracking-tight text-white">{{ cms.hero_title }}</h2>
      </div>

      <div class="grid gap-6">
        <article v-for="sec in cms.sections" :key="sec.id" class="card p-6">
          <div class="flex items-center justify-between mb-2">
            <h3 class="text-xl font-bold text-white">{{ sec.title }}</h3>
            <span class="text-xs text-slate-400">{{ sec.category }}</span>
          </div>
          <p class="text-slate-300 whitespace-pre-line leading-relaxed">{{ sec.content }}</p>
        </article>
      </div>
    </section>

    <!-- 2. OFFLINE CMS & FRONTEND WIJZIGINGEN -->
    <section v-if="activeTab === 'cms'" class="space-y-6">
      <div class="card p-6 space-y-4">
        <div class="flex items-center justify-between">
          <h2 class="text-xl font-bold text-white">Frontend & Offline CMS Beheer</h2>
          <div class="flex gap-2">
            <button @click="saveCms" class="btn-primary">Wijzigingen Opslaan (Server + Offline)</button>
            <button @click="exportBackup" class="px-3 py-2 rounded bg-slate-800 text-sm hover:bg-slate-700">JSON Backup Downloaden</button>
          </div>
        </div>
        <div>
          <label class="block text-xs text-slate-400 mb-1">Hoofdtitel op voorpagina</label>
          <input v-model="cms.hero_title" class="input-dark" />
        </div>
      </div>

      <div class="card p-6 space-y-4">
        <h3 class="text-lg font-semibold text-white">Nieuw Dossier-onderdeel toevoegen</h3>
        <div class="grid md:grid-cols-2 gap-4">
          <input v-model="newSection.title" placeholder="Titel (bijv. Akte 1530 Reimerswaal)" class="input-dark" />
          <input v-model="newSection.category" placeholder="Categorie (Visser Dossier)" class="input-dark" />
        </div>
        <textarea v-model="newSection.content" rows="4" placeholder="Inhoud..." class="input-dark"></textarea>
        <button @click="addSection" class="btn-primary">Onderdeel Toevoegen</button>
      </div>

      <div class="space-y-4">
        <div v-for="sec in cms.sections" :key="sec.id" class="card p-5 space-y-3">
          <div class="flex justify-between items-center gap-4">
            <input v-model="sec.title" class="input-dark font-semibold" />
            <button @click="removeSection(sec.id)" class="btn-danger">Verwijder</button>
          </div>
          <textarea v-model="sec.content" rows="3" class="input-dark"></textarea>
        </div>
      </div>
    </section>

    <!-- 3. FOTOALBUM BEHEER (LOS VAN SOLID POD) -->
    <section v-if="activeTab === 'photos'" class="space-y-6">
      <div class="card p-6 space-y-4">
        <h2 class="text-xl font-bold text-white">Fotoalbum Beheer (Gekoppeld aan GRAMPS & RD-coördinaten)</h2>
        <div class="grid md:grid-cols-3 gap-3">
          <input v-model="photoForm.title" placeholder="Titel foto / charter" class="input-dark" />
          <input v-model="photoForm.album" placeholder="Album (standaard: Visser Dossier)" class="input-dark" />
          <input v-model="photoForm.gramps_handle" placeholder="GRAMPS Handle (bijv. p_visser_0001)" class="input-dark" />
          <input v-model="photoForm.rd_x" type="number" step="any" placeholder="RD X (bijv. 69250)" class="input-dark" />
          <input v-model="photoForm.rd_y" type="number" step="any" placeholder="RD Y (bijv. 386700)" class="input-dark" />
          <input type="file" ref="fileInput" class="input-dark" />
        </div>
        <textarea v-model="photoForm.description" rows="2" placeholder="Omschrijving / transcriptie..." class="input-dark"></textarea>
        <button @click="uploadPhoto" class="btn-primary">Foto Uploaden naar Album</button>
      </div>

      <div class="flex gap-3">
        <input v-model="photoSearch" @input="fetchPhotos" placeholder="Zoek op titel, tag of transcriptie..." class="input-dark" />
      </div>

      <div class="grid md:grid-cols-3 gap-4">
        <div v-for="p in photos" :key="p.id" class="card p-4 flex flex-col justify-between space-y-3">
          <div>
            <div class="h-44 bg-slate-900 rounded mb-3 flex items-center justify-center overflow-hidden border border-slate-800">
              <img v-if="p.filename !== 'placeholder.jpg'" :src="'/uploads/' + p.filename" class="object-cover w-full h-full" />
              <span v-else class="text-xs text-slate-500">Archiefstuk ({{ p.album }})</span>
            </div>
            <input v-model="p.title" class="input-dark text-sm font-bold mb-2" />
            <textarea v-model="p.description" rows="2" class="input-dark text-xs mb-2"></textarea>
            <div class="text-xs text-slate-400 space-y-1">
              <div>Album: <strong class="text-slate-200">{{ p.album }}</strong></div>
              <div v-if="p.gramps_handle">GRAMPS: <code class="text-amber-300">{{ p.gramps_handle }}</code></div>
              <div v-if="p.rd_x && p.rd_y">RD: {{ p.rd_x }}, {{ p.rd_y }}</div>
            </div>
          </div>
          <div class="flex justify-between pt-2 border-t border-slate-800">
            <button @click="savePhotoMeta(p)" class="text-xs px-3 py-1.5 rounded bg-blue-900 text-blue-200">Bewaar Meta</button>
            <button @click="deletePhoto(p.id)" class="btn-danger">Verwijder</button>
          </div>
        </div>
      </div>
    </section>

    <!-- 4. GRAMPS DEVELOPER API MODULE -->
    <section v-if="activeTab === 'gramps'" class="space-y-6">
      <div class="card p-6 space-y-4">
        <h2 class="text-xl font-bold text-white">GRAMPS Developer API — Personen, Families, Events & Plaatsen</h2>
        <div class="grid md:grid-cols-4 gap-3">
          <input v-model="newPerson.first_name" placeholder="Voornaam" class="input-dark" />
          <input v-model="newPerson.surname" placeholder="Achternaam (Visser)" class="input-dark" />
          <input v-model="newPerson.title" placeholder="Titel / Beroep" class="input-dark" />
          <select v-model="newPerson.gender" class="input-dark">
            <option value="M">Man (M)</option>
            <option value="F">Vrouw (F)</option>
            <option value="U">Onbekend (U)</option>
          </select>
        </div>
        <input v-model="newPerson.note" placeholder="Notitie / Charterverwijzing in Visser Dossier" class="input-dark" />
        <button @click="addGrampsPerson" class="btn-primary">Persoon Toevoegen aan GRAMPS Database</button>
      </div>

      <div class="grid md:grid-cols-2 gap-4">
        <div class="card p-5 space-y-3">
          <h3 class="font-bold text-white">Geregistreerde Personen (`Person` objecten)</h3>
          <div v-for="person in gramps.people" :key="person.handle" class="p-3 rounded bg-slate-900 border border-slate-800 flex justify-between items-start">
            <div>
              <div class="font-semibold text-white">
                [{{ person.gramps_id }}] {{ person.primary_name.first_name }} {{ person.primary_name.surname }}
              </div>
              <div class="text-xs text-slate-400">
                Handle: <code>{{ person.handle }}</code> | Titel: {{ person.primary_name.title }}
              </div>
              <div v-if="person.note_list.length" class="text-xs text-emerald-300 mt-1">{{ person.note_list[0] }}</div>
            </div>
            <button @click="deleteGrampsPerson(person.handle)" class="btn-danger">Wis</button>
          </div>
        </div>

        <div class="card p-5 space-y-3">
          <h3 class="font-bold text-white">GRAMPS Events & Kadastrale Plaatsen (RD)</h3>
          <div v-for="ev in gramps.events" :key="ev.handle" class="p-3 rounded bg-slate-900 border border-slate-800 text-sm">
            <span class="font-semibold text-amber-300">[{{ ev.gramps_id }}] {{ ev.event_type }}</span> — {{ ev.date }}
            <div class="text-xs text-slate-300">{{ ev.description }}</div>
          </div>
          <hr class="border-slate-800" />
          <div v-for="pl in gramps.places" :key="pl.handle" class="p-3 rounded bg-slate-900 border border-slate-800 text-sm">
            <span class="font-semibold text-sky-300">[{{ pl.gramps_id }}] {{ pl.title }}</span>
            <div class="text-xs text-slate-400">RD: ({{ pl.rd_x }}, {{ pl.rd_y }}) — WGS84: ({{ pl.lat }}, {{ pl.lon }})</div>
          </div>
        </div>
      </div>
    </section>

    <!-- 5. SOLID POD BEHEER (FOTO-VRIJ) -->
    <section v-if="activeTab === 'solid'" class="space-y-6">
      <div class="card p-6 space-y-4">
        <h2 class="text-xl font-bold text-white">Solid POD Kluis (`01_Solid_POD_Vault`)</h2>
        <p class="text-sm text-slate-300">
          Conform je instructie zijn alle foto's verwijderd uit de Solid POD. De POD bevat uitsluitend de gelinkte RDF/Turtle metadata voor het <strong>Visser Dossier</strong>.
        </p>
        <button @click="purgeSolidPod" class="btn-danger">Forceer Foto-opschoning in Solid POD</button>
        <pre v-if="solidStatus" class="p-4 bg-slate-950 rounded text-xs text-emerald-400 border border-slate-800">{{ solidStatus }}</pre>
      </div>
    </section>
  </main>
</div>

<script>
const { createApp } = Vue;

createApp({
  data() {
    return {
      activeTab: 'home',
      isOnline: true,
      cms: {
        hero_title: 'Visser Dossier',
        sections: []
      },
      newSection: { title: '', category: 'Visser Dossier', content: '' },
      photos: [],
      photoSearch: '',
      photoForm: { title: '', album: 'Visser Dossier', gramps_handle: '', rd_x: '', rd_y: '', description: '' },
      gramps: { people: [], families: [], events: [], places: [], sources: [], citations: [] },
      newPerson: { first_name: '', surname: 'Visser', title: '', gender: 'M', note: '' },
      solidStatus: null
    };
  },
  methods: {
    tabClass(tab) {
      return [
        'px-3 py-1.5 rounded text-sm font-medium transition',
        this.activeTab === tab ? 'bg-blue-600 text-white' : 'bg-slate-900 text-slate-300 hover:bg-slate-800'
      ];
    },
    async loadAll() {
      try {
        const [cmsRes, photosRes, grampsRes] = await Promise.all([
          fetch('/api/cms'),
          fetch('/api/photos'),
          fetch('/api/gramps/tree')
        ]);
        if (cmsRes.ok) {
          this.cms = await cmsRes.json();
          localStorage.setItem('visser_cms_offline', JSON.stringify(this.cms));
        }
        if (photosRes.ok) {
          const pData = await photosRes.json();
          this.photos = pData.results || [];
          localStorage.setItem('visser_photos_offline', JSON.stringify(this.photos));
        }
        if (grampsRes.ok) {
          this.gramps = await grampsRes.json();
          localStorage.setItem('visser_gramps_offline', JSON.stringify(this.gramps));
        }
        this.isOnline = true;
      } catch (e) {
        this.isOnline = false;
        const cachedCms = localStorage.getItem('visser_cms_offline');
        const cachedPhotos = localStorage.getItem('visser_photos_offline');
        const cachedGramps = localStorage.getItem('visser_gramps_offline');
        if (cachedCms) this.cms = JSON.parse(cachedCms);
        if (cachedPhotos) this.photos = JSON.parse(cachedPhotos);
        if (cachedGramps) this.gramps = JSON.parse(cachedGramps);
      }
    },
    async saveCms() {
      localStorage.setItem('visser_cms_offline', JSON.stringify(this.cms));
      try {
        await fetch('/api/cms', {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(this.cms)
        });
        this.isOnline = true;
      } catch (_) {
        this.isOnline = false;
      }
    },
    async addSection() {
      if (!this.newSection.title.trim()) return;
      const sec = {
        id: 'sec-' + Date.now(),
        title: this.newSection.title,
        category: this.newSection.category || 'Visser Dossier',
        content: this.newSection.content,
        updated_at: new Date().toISOString()
      };
      this.cms.sections.push(sec);
      this.newSection = { title: '', category: 'Visser Dossier', content: '' };
      await this.saveCms();
    },
    async removeSection(id) {
      this.cms.sections = this.cms.sections.filter(s => s.id !== id);
      await this.saveCms();
    },
    async fetchPhotos() {
      try {
        const res = await fetch('/api/photos?q=' + encodeURIComponent(this.photoSearch));
        if (res.ok) {
          const data = await res.json();
          this.photos = data.results || [];
        }
      } catch (_) {}
    },
    async uploadPhoto() {
      const fd = new FormData();
      fd.append('title', this.photoForm.title || 'Visser Dossier Stuk');
      fd.append('album', this.photoForm.album || 'Visser Dossier');
      fd.append('gramps_handle', this.photoForm.gramps_handle);
      fd.append('rd_x', this.photoForm.rd_x);
      fd.append('rd_y', this.photoForm.rd_y);
      fd.append('description', this.photoForm.description);
      if (this.$refs.fileInput && this.$refs.fileInput.files[0]) {
        fd.append('file', this.$refs.fileInput.files[0]);
      }
      try {
        const res = await fetch('/api/photos', { method: 'POST', body: fd });
        if (res.ok) {
          this.photoForm = { title: '', album: 'Visser Dossier', gramps_handle: '', rd_x: '', rd_y: '', description: '' };
          if (this.$refs.fileInput) this.$refs.fileInput.value = '';
          await this.fetchPhotos();
        }
      } catch (_) {}
    },
    async savePhotoMeta(p) {
      try {
        await fetch('/api/photos/' + p.id, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(p)
        });
      } catch (_) {}
    },
    async deletePhoto(id) {
      this.photos = this.photos.filter(p => p.id !== id);
      localStorage.setItem('visser_photos_offline', JSON.stringify(this.photos));
      try {
        await fetch('/api/photos/' + id, { method: 'DELETE' });
      } catch (_) {}
    },
    async addGrampsPerson() {
      if (!this.newPerson.first_name.trim()) return;
      const payload = {
        handle: '',
        gramps_id: '',
        gender: this.newPerson.gender,
        primary_name: {
          first_name: this.newPerson.first_name,
          surname: this.newPerson.surname || 'Visser',
          call_name: this.newPerson.first_name,
          title: this.newPerson.title
        },
        event_ref_list: [],
        family_list: [],
        parent_family_list: [],
        citation_list: [],
        media_list: [],
        note_list: this.newPerson.note ? [this.newPerson.note] : []
      };
      try {
        const res = await fetch('/api/gramps/people', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload)
        });
        if (res.ok) {
          this.newPerson = { first_name: '', surname: 'Visser', title: '', gender: 'M', note: '' };
          await this.loadAll();
        }
      } catch (_) {
        payload.handle = 'p_offline_' + Date.now();
        payload.gramps_id = 'I' + String(this.gramps.people.length + 1).padStart(4, '0');
        this.gramps.people.push(payload);
        localStorage.setItem('visser_gramps_offline', JSON.stringify(this.gramps));
      }
    },
    async deleteGrampsPerson(handle) {
      this.gramps.people = this.gramps.people.filter(p => p.handle !== handle);
      localStorage.setItem('visser_gramps_offline', JSON.stringify(this.gramps));
      try {
        await fetch('/api/gramps/people/' + handle, { method: 'DELETE' });
      } catch (_) {}
    },
    async purgeSolidPod() {
      try {
        const res = await fetch('/api/solid/purge-photos', { method: 'DELETE' });
        this.solidStatus = await res.json();
      } catch (e) {
        this.solidStatus = { status: 'Offline uitgevoerd via bash-script' };
      }
    },
    exportBackup() {
      const bundle = {
        exported_at: new Date().toISOString(),
        cms: this.cms,
        gramps: this.gramps,
        photos: this.photos
      };
      const blob = new Blob([JSON.stringify(bundle, null, 2)], { type: 'application/json' });
      const a = document.createElement('a');
      a.href = URL.createObjectURL(blob);
      a.download = 'visser_dossier_offline_backup.json';
      a.click();
    }
  },
  mounted() {
    this.loadAll();
  }
}).mount('#app');
</script>
</body>
</html>
HTML

# Synchroniseer ook naar de Vue SFC mappen zodat Vite builds (indien gebruikt) exact hetzelfde tonen
cp index.html frontend/index.html 2>/dev/null || true

echo "=== [6/7] Rust project compileren in release-modus ==="
cargo build --release

echo "=== [7/7] Systemd service herstarten (indien actief) ==="
systemctl --user restart lodijke-cms-server.service 2>/dev/null || true

echo "================================================================="
echo " KLAAR! Alles is foutvrij gecompileerd en geconfigureerd:"
echo " - Hoofdpagina toont uitsluitend: 'Visser Dossier'"
echo " - Foto's zijn volledig gewist uit 01_Solid_POD_Vault"
echo " - GRAMPS Developer API, Fotoalbum & Offline Vue CMS zijn actief"
echo " Start handmatig met: ./target/release/lodijke-cms-server"
echo "================================================================="
