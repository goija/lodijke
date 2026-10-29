use chrono::Datelike;
//==============================================================================
// src/main.rs — Lodijke CMS met Fotomodule v10
//
// Modules:
//   - Foto's (CRUD, upload, filters)
//   - Health endpoint
//   - Frontend serveer
//   - GeoJSON export
//
// API Endpoints:
//   GET  /health                  — status
//   GET  /api/photos              — lijst foto's
//   GET  /api/photos/{id}         — foto details
//   DELETE /api/photos/{id}       — verwijder foto
//   POST /api/photos/upload       — upload bestand
//   GET  /api/photos/categories   — alle categorieën
//   GET  /api/photos/search?q=... — zoeken
//==============================================================================

use axum::{
    extract::{Multipart, Path, Query, State},
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::json;
use std::{
    fs,
    net::SocketAddr,
    path::PathBuf,
    sync::Arc,
};
use tokio::sync::RwLock;
use tower_http::{
    cors::CorsLayer,
    services::{ServeDir, ServeFile},
};
use uuid::Uuid;

//------------------------------------------------------------------------------
// DATA STRUCTURES
//------------------------------------------------------------------------------

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Photo {
    pub id: String,
    pub title: String,
    pub description: Option<String>,
    pub category: Option<String>,
    pub fleet: Option<String>,        // TH 2, TH 12, TH 90
    pub parcel_id: Option<String>,    // perceel-369
    pub filename: String,
    pub thumbnail_filename: Option<String>,
    pub uploaded_at: DateTime<Utc>,
    pub date_taken: Option<DateTime<Utc>>,
    pub location: Option<String>,
    pub photographer: Option<String>,
    pub tags: Vec<String>,
    pub archived: bool,
}

impl Default for Photo {
    fn default() -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            title: String::new(),
            description: None,
            category: None,
            fleet: None,
            parcel_id: None,
            filename: String::new(),
            thumbnail_filename: None,
            uploaded_at: Utc::now(),
            date_taken: None,
            location: None,
            photographer: None,
            tags: Vec::new(),
            archived: false,
        }
    }
}

#[derive(Deserialize)]
pub struct PhotoQuery {
    pub category: Option<String>,
    pub fleet: Option<String>,
    pub parcel: Option<String>,
    pub year: Option<i32>,
    pub search: Option<String>,
    pub limit: Option<i32>,
    pub offset: Option<i32>,
}

#[derive(Clone)]
pub struct AppState {
    pub base_dir: PathBuf,
    pub photos: Arc<RwLock<Vec<Photo>>>,
}

//------------------------------------------------------------------------------
// MAIN
//------------------------------------------------------------------------------

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    let base_dir = std::env::current_dir().unwrap_or_else(|_| PathBuf::from("."));
    let port: u16 = std::env::var("PORT")
        .unwrap_or_else(|_| "8082".to_string())
        .parse()
        .unwrap_or(8082);

    // Mappen aanmaken
    let data_dir = base_dir.join("data");
    let photo_dir = data_dir.join("photos");
    let dist_dir = base_dir.join("frontend").join("dist");

    fs::create_dir_all(&data_dir).ok();
    fs::create_dir_all(&photo_dir).ok();
    fs::create_dir_all(dist_dir.join("assets")).ok();

    // Index.html (fallback)
    let index_html = dist_dir.join("index.html");
    if !index_html.exists() {
        let _ = fs::write(
            &index_html,
            format!(r#"<!DOCTYPE html>
<html lang="nl">
<head>
  <meta charset="UTF-8">
  <title>Lodijke Archief</title>
  <style>
    body { font-family: system-ui; max-width: 800px; margin: 40px auto; padding: 20px; }
    h1 { color: #8b2229; border-bottom: 2px solid #8b2229; padding-bottom: 10px; }
    .status { background: #f0fff0; padding: 15px; border-radius: 5px; }
    a { color: #6d4aff; }
  </style>
</head>
<body>
  <h1>🏛️ Archief Familie Schot, Bout & Van Vrijberghe</h1>
  <div class="status">
    <strong>Status:</strong> ✅ OK<br>
    <strong>Poort:</strong> {}<br>
    <strong>Tijd:</strong> {}
  </div>
  <h2>Snelkoppelingen</h2>
  <ul>
    <li><a href="/api/photos">Foto's</a></li>
    <li><a href="/api/photos/categories">Categorieën</a></li>
    <li><a href="/health">Health Check</a></li>
  </ul>
</body>
</html>"#, port, Utc::now().to_rfc3339()));
    }

    // Foto's laden
    let photos = load_photos(&data_dir);

    let state = AppState {
        base_dir: base_dir.clone(),
        photos: Arc::new(RwLock::new(photos)),
    };

    // Router opbouwen
    let app = Router::new()
        // Health
        .route("/health", get(health_handler))
        // Foto's CRUD
        .route("/api/photos", get(list_photos))
        .route("/api/photos/:id", get(get_photo).delete(delete_photo))
        .route("/api/photos/upload", post(upload_photo))
        .route("/api/photos/categories", get(get_categories))
        .route("/api/photos/fleets", get(get_fleets))
        .route("/api/photos/search", get(search_photos))
        // GeoJSON export
        .route("/api/geojson", get(export_geojson))
        // Frontend serve
        .route_service("/", ServeFile::new(index_html))
        .nest_service("/assets", ServeDir::new(dist_dir.join("assets")))
        .nest_service("/media", ServeDir::new(photo_dir))
        .layer(CorsLayer::permissive())
        .with_state(state);

    let addr = SocketAddr::from(([127, 0, 0, 1], port));

    tracing::info!("═══════════════════════════════════════════════");
    tracing::info!("  🚀 Lodijke CMS start op http://{}", addr);
    tracing::info!("═══════════════════════════════════════════════");

    let listener = match tokio::net::TcpListener::bind(addr).await {
        Ok(l) => l,
        Err(e) => {
            tracing::error!("❌ Kan poort {} niet binden: {}", port, e);
            std::process::exit(1);
        }
    };

    if let Err(e) = axum::serve(listener, app).await {
        tracing::error!("❌ Serverfout: {}", e);
        std::process::exit(1);
    }
}

//------------------------------------------------------------------------------
// HANDLERS
//------------------------------------------------------------------------------

async fn health_handler() -> impl IntoResponse {
    Json(json!({
        "status": "OK",
        "engine": "Lodijke CMS v10 — AvoRed Rust + Photomodule + Vue 3",
        "version": "10.0.0",
        "timestamp": Utc::now().to_rfc3339(),
        "features": [
            "foto_crud",
            "upload",
            "categories",
            "search",
            "geojson_export",
            "vue3_frontend"
        ]
    }))
}

async fn list_photos(
    State(state): State<AppState>,
    Query(query): Query<PhotoQuery>,
) -> impl IntoResponse {
    let photos = state.photos.read().await;
    let mut result: Vec<&Photo> = photos.iter().collect();

    // Filters toepassen
    if let Some(ref cat) = query.category {
        result.retain(|p| p.category.as_ref().map_or(false, |c| c == cat));
    }
    if let Some(ref fl) = query.fleet {
        result.retain(|p| p.fleet.as_ref().map_or(false, |f| f.contains(fl)));
    }
    if let Some(ref pl) = query.parcel {
        result.retain(|p| p.parcel_id.as_ref().map_or(false, |pid| pid.contains(pl)));
    }
    if let Some(year) = query.year {
        result.retain(|p| p.date_taken.map_or(false, |dt| dt.year() == year));
    }
    if let Some(ref search) = query.search {
        let q = search.to_lowercase();
        result.retain(|p| {
            p.title.to_lowercase().contains(&q)
                || p.description
                    .as_ref()
                    .map_or(false, |d| d.to_lowercase().contains(&q))
                || p.tags.iter().any(|t| t.to_lowercase().contains(&q))
        });
    }

    // Paginatie
    let limit = query.limit.unwrap_or(100) as usize;
    let offset = query.offset.unwrap_or(0) as usize;
    let page: Vec<_> = result
        .into_iter()
        .skip(offset)
        .take(limit)
        .cloned()
        .collect();

    Json(json!({
        "total": result.len(),
        "returned": page.len(),
        "offset": offset,
        "photos": page
    }))
}

async fn get_photo(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> impl IntoResponse {
    let photos = state.photos.read().await;
    match photos.iter().find(|p| p.id == id) {
        Some(photo) => (StatusCode::OK, Json(json!(photo))).into_response(),
        None => (
            StatusCode::NOT_FOUND,
            Json(json!({ "error": "Foto niet gevonden", "id": id })),
        )
            .into_response(),
    }
}

async fn delete_photo(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> impl IntoResponse {
    let mut photos = state.photos.write().await;
    let before = photos.len();
    photos.retain(|p| p.id != id);
    let removed = before - photos.len();

    save_photos(&state.base_dir, &photos);

    Json(json!({
        "success": true,
        "deleted": removed,
        "remaining": photos.len()
    }))
}

async fn upload_photo(
    State(state): State<AppState>,
    mut multipart: Multipart,
) -> impl IntoResponse {
    let upload_dir = state.base_dir.join("data").join("photos");
    fs::create_dir_all(&upload_dir).ok();

    let mut file_data: Option<(bytes::Bytes, String)> = None;
    let mut title: Option<String> = None;
    let mut category: Option<String> = None;
    let mut fleet: Option<String> = None;
    let mut parcel_id: Option<String> = None;
    let mut tags: Vec<String> = Vec::new();

    while let Ok(Some(field)) = multipart.next_field().await {
        let name = field.name().unwrap_or("").to_string();

        match name.as_str() {
            "file" => {
                if let Ok(data) = field.bytes().await {
                    let orig = field.file_name().unwrap_or("image.jpg").to_string();
                    let ext = std::path::Path::new(&orig)
                        .extension()
                        .and_then(|e| e.to_str())
                        .unwrap_or("jpg")
                        .to_string();
                    let filename = format!("{}_{}.{}", Uuid::new_v4(), Utc::now().timestamp(), ext);
                    let filepath = upload_dir.join(&filename);

                    if let Err(e) = fs::write(&filepath, &data) {
                        return (
                            StatusCode::INTERNAL_SERVER_ERROR,
                            Json(json!({ "error": format!("Opslag mislukt: {}", e) })),
                        ).into_response();
                    }

                    file_data = Some((data, filename));
                }
            }
            "title" => {
                title = field.text().await.ok().filter(|t| !t.trim().is_empty());
            }
            "category" => {
                category = field.text().await.ok().filter(|t| !t.trim().is_empty());
            }
            "fleet" => {
                fleet = field.text().await.ok().filter(|t| !t.trim().is_empty());
            }
            "parcel_id" => {
                parcel_id = field.text().await.ok().filter(|t| !t.trim().is_empty());
            }
            "tags" => {
                if let Ok(txt) = field.text().await {
                    tags = txt
                        .split(',')
                        .map(|t| t.trim().to_string())
                        .filter(|t| !t.is_empty())
                        .collect();
                }
            }
            _ => {}
        }
    }

    match file_data {
        Some((_data, filename)) => {
            let photo = Photo {
                id: Uuid::new_v4().to_string(),
                title: title.unwrap_or_else(|| "Geüploade foto".into()),
                description: None,
                category,
                fleet,
                parcel_id,
                filename,
                thumbnail_filename: None,
                uploaded_at: Utc::now(),
                date_taken: None,
                location: None,
                photographer: None,
                tags,
                archived: false,
            };

            let mut photos = state.photos.write().await;
            photos.insert(0, photo.clone());
            save_photos(&state.base_dir, &photos);

            (
                StatusCode::CREATED,
                Json(json!({
                    "success": true,
                    "photo": photo
                })),
            )
                .into_response()
        }
        None => (
            StatusCode::BAD_REQUEST,
            Json(json!({ "error": "Geen bestand ontvangen" })),
        )
            .into_response(),
    }
}

async fn get_categories(State(state): State<AppState>) -> impl IntoResponse {
    let photos = state.photos.read().await;
    let mut cats: Vec<&str> = photos.iter().filter_map(|p| p.category.as_deref()).collect();
    cats.sort();
    cats.dedup();
    Json(json!({ "categories": cats }))
}

async fn get_fleets(State(state): State<AppState>) -> impl IntoResponse {
    let photos = state.photos.read().await;
    let mut fleets: Vec<&str> = photos.iter().filter_map(|p| p.fleet.as_deref()).collect();
    fleets.sort();
    fleets.dedup();
    Json(json!({ "fleets": fleets }))
}

async fn search_photos(
    Query(query): Query<Option<String>>,
    State(state): State<AppState>,
) -> impl IntoResponse {
    let photos = state.photos.read().await;

    let filtered: Vec<Photo> = match query {
        Some(ref q) if !q.trim().is_empty() => {
            let q = q.to_lowercase();
            photos
                .iter()
                .filter(|p| {
                    p.title.to_lowercase().contains(&q)
                        || p.description
                            .as_ref()
                            .map_or(false, |d| d.to_lowercase().contains(&q))
                        || p.tags.iter().any(|t| t.to_lowercase().contains(&q))
                })
                .cloned()
                .collect()
        }
        _ => photos.iter().cloned().collect(),
    };

    Json(json!({
        "query": query,
        "results": filtered,
        "count": filtered.len()
    }))
}

async fn export_geojson(State(_state): State<AppState>) -> impl IntoResponse {
    // Placeholder — in productie: kadaster percelen
    Json(json!({
        "type": "FeatureCollection",
        "name": "lodijke_perceel_369",
        "features": [
            {
                "type": "Feature",
                "properties": {
                    "id": "perceel-369",
                    "name": "Bol van Lodijke",
                    "area_hectares": 12.5
                },
                "geometry": null
            }
        ]
    }))
}

//------------------------------------------------------------------------------
// HELPERS
//------------------------------------------------------------------------------

fn save_photos(base_dir: &PathBuf, photos: &Vec<Photo>) {
    let path = base_dir.join("data").join("photos.json");
    if let Ok(text) = serde_json::to_string_pretty(photos) {
        let _ = fs::write(path, text);
    }
}

fn load_photos(data_dir: &PathBuf) -> Vec<Photo> {
    let path = data_dir.join("photos.json");

    if let Ok(text) = fs::read_to_string(&path) {
        if let Ok(list) = serde_json::from_str::<Vec<Photo>>(&text) {
            return list;
        }
    }

    // Demo foto's
    vec![
        Photo {
            id: "demo-001".into(),
            title: "Hoogaars TH 2 \"Eben Haëzer\"".into(),
            description: Some("Gebouwd 1902, werf Van Duivendijk, Tholen".into()),
            category: Some("Schepen".into()),
            fleet: Some("TH 2".into()),
            parcel_id: Some("perceel-369".into()),
            filename: "hoogaars-th2.jpg".into(),
            thumbnail_filename: Some("thumb_hoogaars-th2.jpg".into()),
            uploaded_at: Utc::now(),
            date_taken: None,
            location: Some("Tholen, Contr'Escarpe".into()),
            photographer: Some("B.W. Schot".into()),
            tags: vec!["schip".into(), "hoogaars".into(), "1902".into()],
            archived: false,
        },
        Photo {
            id: "demo-002".into(),
            title: "Visserijhaven Tholen".into(),
            description: Some("Vissersboten bij de pier".into()),
            category: Some("Haven".into()),
            fleet: Some("TH 12".into()),
            parcel_id: None,
            filename: "haven-tholen.jpg".into(),
            thumbnail_filename: Some("thumb_haven-tholen.jpg".into()),
            uploaded_at: Utc::now(),
            date_taken: None,
            location: Some("Tholen haven".into()),
            photographer: None,
            tags: vec!["haven".into(), "vissers".into()],
            archived: false,
        },
        Photo {
            id: "demo-003".into(),
            title: "Perceel 369 — Bol van Lodijke".into(),
            description: Some("12,5 hectare, kadastraal bekend".into()),
            category: Some("Perceel".into()),
            fleet: None,
            parcel_id: Some("perceel-369".into()),
            filename: "perceel-369.jpg".into(),
            thumbnail_filename: None,
            uploaded_at: Utc::now(),
            date_taken: None,
            location: Some("Scherpenisse".into()),
            photographer: None,
            tags: vec!["landbouw".into(), "kadastraal".into()],
            archived: false,
        },
    ]
}