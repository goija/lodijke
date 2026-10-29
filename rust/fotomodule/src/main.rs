use axum::{
    extract::{DefaultBodyLimit, Multipart, Path, Query, State},
    http::StatusCode,
    response::{Html, IntoResponse, Json},
    routing::get,
    Router,
};
use base64::Engine;
use serde::{Deserialize, Serialize};
use std::{collections::HashMap, fs, path::PathBuf, sync::Arc};
use tokio::sync::RwLock;
use tower_http::{cors::CorsLayer, services::ServeDir};

// ---------------------------------------------------------------------------
// Datamodellen
// ---------------------------------------------------------------------------

#[derive(Clone, Serialize, Deserialize)]
struct PhotoRecord {
    id: String,
    title: String,
    category: String,
    year: String,
    location: String,
    desc: String,
    filename: String,
    content_type: String,
    size_bytes: u64,
    created_at: String,
}

#[derive(Deserialize)]
struct PhotoQuery {
    q: Option<String>,
    category: Option<String>,
    limit: Option<usize>,
    offset: Option<usize>,
}

#[derive(Deserialize)]
struct PhotoUpdate {
    title: Option<String>,
    category: Option<String>,
    year: Option<String>,
    location: Option<String>,
    desc: Option<String>,
}

/// Importformaat: compatibel met de JSON-export van het bestaande front-end
/// (velden `dataUrl`, `dimensions`, `sizeText` uit de Solid POD-opslag).
#[derive(Deserialize)]
struct PhotoImport {
    id: Option<String>,
    #[serde(default = "default_title")]
    title: String,
    #[serde(default)]
    category: String,
    #[serde(default)]
    year: String,
    #[serde(default)]
    location: String,
    #[serde(default)]
    desc: String,
    /// data-URL: ondersteunt zowel ";base64," als "data:<mime>;utf8,<uri-encoded>"
    #[serde(rename = "dataUrl", default)]
    data_url: Option<String>,
    #[serde(default)]
    filename: Option<String>,
}

fn default_title() -> String { "Naamloze archieffoto".to_string() }

#[derive(Serialize)]
struct Stats {
    total: usize,
    total_size_bytes: u64,
    categories: HashMap<String, usize>,
}

struct AppState {
    photos: RwLock<Vec<PhotoRecord>>,
    categories: RwLock<Vec<String>>,
    data_dir: PathBuf,
    uploads_dir: PathBuf,
}

type SharedState = Arc<AppState>;

type ApiError = (StatusCode, String);

// ---------------------------------------------------------------------------
// Persistentie
// ---------------------------------------------------------------------------

fn load_json<T: serde::de::DeserializeOwned>(path: &PathBuf, fallback: T) -> T {
    fs::read_to_string(path)
        .ok()
        .and_then(|txt| serde_json::from_str(&txt).ok())
        .unwrap_or(fallback)
}

async fn persist(state: &AppState) -> Result<(), String> {
    let photos = state.photos.read().await;
    let cats = state.categories.read().await;
    let bytes =
        serde_json::to_vec_pretty(&*photos).map_err(|e| format!("serialiseren mislukt: {e}"))?;
    fs::write(state.data_dir.join("photos.json"), bytes)
        .map_err(|e| format!("wegschrijven photos.json mislukt: {e}"))?;
    let cat_bytes = serde_json::to_vec_pretty(&*cats)
        .map_err(|e| format!("serialiseren mislukt: {e}"))?;
    fs::write(state.data_dir.join("categories.json"), cat_bytes)
        .map_err(|e| format!("wegschrijven categories.json mislukt: {e}"))?;
    Ok(())
}

async fn ensure_category(state: &AppState, category: &str) {
    let trimmed = category.trim();
    if trimmed.is_empty() {
        return;
    }
    {
        let cats = state.categories.read().await;
        if cats.iter().any(|c| c.eq_ignore_ascii_case(trimmed)) {
            return;
        }
    }
    let mut cats = state.categories.write().await;
        cats.push(trimmed.to_string());
        cats.sort();
}

// ---------------------------------------------------------------------------
// Hulpfuncties voor bestanden
// ---------------------------------------------------------------------------

fn ext_for(content_type: &str, original_name: &str) -> String {
    if let Some(ext) = original_name.rsplit('.').next() {
        if original_name.contains('.') && ext.len() <= 5 && ext.chars().all(|c| c.is_ascii_alphanumeric()) {
            return ext.to_lowercase();
        }
    }
    match content_type {
        "image/jpeg" => "jpg".into(),
        "image/png" => "png".into(),
        "image/webp" => "webp".into(),
        "image/gif" => "gif".into(),
        "image/svg+xml" => "svg".into(),
        _ => "bin".into(),
    }
}

/// Decodeert een %-encoded data-URL-body (zoals de utf8 SVG-platen van het front-end).
fn percent_decode_bytes(input: &str) -> Vec<u8> {
    let bytes = input.as_bytes();
    let mut out = Vec::with_capacity(bytes.len());
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'%' && i + 2 < bytes.len() + 1 && i + 2 <= bytes.len() - 1 + 1 {
            if i + 2 < bytes.len() || i + 2 == bytes.len() - 1 {
                // val hieronder door naar hex-check
            }
            if let (Some(h), Some(l)) = (
                bytes.get(i + 1).and_then(|b| (*b as char).to_digit(16)),
                bytes.get(i + 2).and_then(|b| (*b as char).to_digit(16)),
            ) {
                out.push((h * 16 + l) as u8);
                i += 3;
                continue;
            }
            out.push(bytes[i]);
            i += 1;
        } else {
            out.push(bytes[i]);
            i += 1;
        }
    }
    out
}

/// Splitst "data:image/svg+xml;utf8,..." of "data:image/png;base64,...."
/// in (content_type, bytes).
fn parse_data_url(data_url: &str) -> Result<(String, Vec<u8>), String> {
    let rest = data_url
        .strip_prefix("data:")
        .ok_or_else(|| "dataUrl moet beginnen met 'data:'".to_string())?;
    let (header, body) = rest
        .split_once(',')
        .ok_or_else(|| "dataUrl mist ',' separator".to_string())?;
    let (mime_part, encoding) = match header.rsplit_once(';') {
        Some((m, enc)) => (m.to_string(), enc.to_string()),
        None => (header.to_string(), String::new()),
    };
    let mime = if mime_part.is_empty() {
        "application/octet-stream".to_string()
    } else {
        mime_part
    };
    if encoding == "base64" {
        let bytes = base64::engine::general_purpose::STANDARD
            .decode(body.trim())
            .map_err(|e| format!("base64-decodering mislukt: {e}"))?;
        Ok((mime, bytes))
    } else {
        // utf8 of uri-encoded tekst (bijv. SVG-platen)
        Ok((mime, percent_decode_bytes(body)))
    }
}

// ---------------------------------------------------------------------------
// Handlers
// ---------------------------------------------------------------------------

async fn root() -> Html<&'static str> {
    Html("<h1>Lodijke Fotomodule</h1><p>Beheerinterface: <a href='/admin'>/admin</a> — API: <a href='/api/photos'>/api/photos</a></p>")
}

async fn admin_page() -> Html<&'static str> {
    Html(include_str!("admin.html"))
}

async fn list_photos(
    State(state): State<SharedState>,
    Query(q): Query<PhotoQuery>,
) -> Json<Vec<PhotoRecord>> {
    let photos = state.photos.read().await;
    let needle = q
        .q
        .as_deref()
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .map(str::to_lowercase);
    let category = q
        .category
        .as_deref()
        .map(str::trim)
        .filter(|s| !s.is_empty() && !s.eq_ignore_ascii_case("ALLE"));

    let mut out: Vec<PhotoRecord> = photos
        .iter()
        .filter(|p| match &category {
            Some(c) => p.category.to_lowercase().contains(&c.to_lowercase()),
            None => true,
        })
        .filter(|p| match &needle {
            Some(s) => {
                p.title.to_lowercase().contains(s)
                    || p.desc.to_lowercase().contains(s)
                    || p.location.to_lowercase().contains(s)
                    || p.year.to_lowercase().contains(s)
            }
            None => true,
        })
        .cloned()
        .collect();

    if let Some(off) = q.offset.filter(|o| *o < out.len()) {
        out.drain(..off);
    } else if q.offset.unwrap_or(0) >= photos.len() && q.offset.is_some() {
        out.clear();
    }
    if let Some(lim) = q.limit {
        out.truncate(lim);
    }
    Json(out)
}

async fn get_photo(
    State(state): State<SharedState>,
    Path(id): Path<String>,
) -> Result<Json<PhotoRecord>, ApiError> {
    let photos = state.photos.read().await;
    photos
        .iter()
        .find(|p| p.id == id)
        .cloned()
        .map(Json)
        .ok_or_else(|| (StatusCode::NOT_FOUND, format!("Foto {id} bestaat niet.")))
}

async fn create_photo(
    State(state): State<SharedState>,
    mut multipart: Multipart,
) -> Result<(StatusCode, Json<PhotoRecord>), ApiError> {
    let mut title = String::new();
    let mut category = String::new();
    let mut year = String::new();
    let mut location = String::new();
    let mut desc = String::new();
    let mut file: Option<(String, String, Vec<u8>)> = None;

    while let Some(field) = multipart
        .next_field()
        .await
        .map_err(|e| (StatusCode::BAD_REQUEST, format!("Multipart-fout: {e}")))?
    {
        let name = field.name().unwrap_or_default().to_string();
        match name.as_str() {
            "file" => {
                let filename = field
                    .file_name()
                    .unwrap_or("upload")
                    .to_string();
                let content_type = field
                    .content_type()
                    .unwrap_or("application/octet-stream")
                    .to_string();
                let data = field
                    .bytes()
                    .await
                    .map_err(|e| (StatusCode::BAD_REQUEST, format!("Lezen bestand mislukt: {e}")))?
                    .to_vec();
                file = Some((filename, content_type, data));
            }
            "title" => title = field.text().await.unwrap_or_default(),
            "category" => category = field.text().await.unwrap_or_default(),
            "year" => year = field.text().await.unwrap_or_default(),
            "location" => location = field.text().await.unwrap_or_default(),
            "desc" => desc = field.text().await.unwrap_or_default(),
            _ => { let _ = field.bytes().await; }
        }
    }

    let (orig_name, content_type, data) =
        file.ok_or((StatusCode::BAD_REQUEST, "Geen bestand ontvangen (veld 'file').".into()))?;

    if !content_type.starts_with("image/") {
        return Err((StatusCode::UNSUPPORTED_MEDIA_TYPE, format!("Alleen afbeeldingen toegestaan, ontvangen: {content_type}")));
    }

    let id = uuid::Uuid::new_v4().to_string();
    let filename = format!("{id}.{}", ext_for(&content_type, &orig_name));
    fs::write(state.uploads_dir.join(&filename), &data)
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Opslaan mislukt: {e}")))?;

    let record = PhotoRecord {
        id,
        title: if title.trim().is_empty() {
            orig_name.trim_end_matches(".jpeg").trim_end_matches(".jpg").trim_end_matches(".png").trim_end_matches(".webp").to_string()
        } else {
            title.trim().to_string()
        },
        category: if category.trim().is_empty() { "Eigen Collectie".into() } else { category.trim().to_string() },
        year: if year.trim().is_empty() { "Archief".into() } else { year.trim().to_string() },
        location: if location.trim().is_empty() { "Tholen".into() } else { location.trim().to_string() },
        desc: if desc.trim().is_empty() { "Geuploade archieffoto.".into() } else { desc.trim().to_string() },
        filename,
        content_type,
        size_bytes: data.len() as u64,
        created_at: chrono::Utc::now().to_rfc3339(),
    };

    ensure_category(&state, &record.category).await;
    {
        let mut photos = state.photos.write().await;
        photos.insert(0, record.clone());
    }
    persist(&state).await.map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e))?;
    Ok((StatusCode::CREATED, Json(record)))
}

async fn update_photo(
    State(state): State<SharedState>,
    Path(id): Path<String>,
    Json(patch): Json<PhotoUpdate>,
) -> Result<Json<PhotoRecord>, ApiError> {
    {
        let mut photos = state.photos.write().await;
        let rec = photos
            .iter_mut()
            .find(|p| p.id == id)
            .ok_or((StatusCode::NOT_FOUND, format!("Foto {id} bestaat niet.")))?;
        if let Some(t) = patch.title.filter(|s| !s.trim().is_empty()) {
            rec.title = t.trim().to_string();
        }
        if let Some(c) = patch.category.filter(|s| !s.trim().is_empty()) {
            rec.category = c.trim().to_string();
        }
        if let Some(y) = patch.year.filter(|s| !s.trim().is_empty()) {
            rec.year = y.trim().to_string();
        }
        if let Some(l) = patch.location.filter(|s| !s.trim().is_empty()) {
            rec.location = l.trim().to_string();
        }
        if let Some(d) = patch.desc {
            rec.desc = d.trim().to_string();
        }
        let cloned = rec.clone();
        drop(photos);
        ensure_category(&state, &cloned.category).await;
        persist(&state).await.map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e))?;
        return Ok(Json(cloned));
    }
}

async fn delete_photo(
    State(state): State<SharedState>,
    Path(id): Path<String>,
) -> Result<StatusCode, ApiError> {
    let removed = {
        let mut photos = state.photos.write().await;
        let pos = photos.iter().position(|p| p.id == id);
        match pos {
            Some(i) => Some(photos.remove(i)),
            None => None,
        }
    };
    match removed {
        Some(rec) => {
            let _ = fs::remove_file(state.uploads_dir.join(&rec.filename));
            persist(&state).await.map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e))?;
            Ok(StatusCode::NO_CONTENT)
        }
        None => Err((StatusCode::NOT_FOUND, format!("Foto {id} bestaat niet."))),
    }
}

async fn stats(State(state): State<SharedState>) -> Json<Stats> {
    let photos = state.photos.read().await;
    let mut categories: HashMap<String, usize> = HashMap::new();
    let mut total_size = 0u64;
    for p in photos.iter() {
        *categories.entry(p.category.clone()).or_insert(0) += 1;
        total_size += p.size_bytes;
    }
    Json(Stats { total: photos.len(), total_size_bytes: total_size, categories })
}

async fn export_photos(State(state): State<SharedState>) -> Json<Vec<PhotoRecord>> {
    let photos = state.photos.read().await;
    Json(photos.clone())
}

/// Importeert een lijst foto's. Ondersteunt data-URL's uit de bestaande
/// Solid POD-export van het front-end (zowel base64 als utf8-gecodeerd).
async fn import_photos(
    State(state): State<SharedState>,
    Json(items): Json<Vec<PhotoImport>>,
) -> Result<(StatusCode, Json<serde_json::Value>), ApiError> {
    let mut imported = 0usize;
    let mut skipped = 0usize;
    for item in items {
        let (filename, content_type, size) = if let Some(data_url) = item.data_url.as_deref() {
            match parse_data_url(data_url) {
                Ok((mime, bytes)) => {
                    let id = uuid::Uuid::new_v4().to_string();
                    let fname = format!("{id}.{}", ext_for(&mime, ""));
                    match fs::write(state.uploads_dir.join(&fname), &bytes) {
                        Ok(_) => (fname, mime, bytes.len() as u64),
                        Err(e) => {
                            eprintln!("Importfout bij '{}': {e}", item.title);
                            skipped += 1;
                            continue;
                        }
                    }
                }
                Err(e) => {
                    eprintln!("Ongeldige dataUrl bij '{}': {e}", item.title);
                    skipped += 1;
                    continue;
                }
            }
        } else if let Some(existing) = item.filename.as_deref() {
            if !state.uploads_dir.join(existing).exists() {
                skipped += 1;
                continue;
            }
            (existing.to_string(), "image/*".to_string(), 0)
        } else {
            skipped += 1;
            continue;
        };

        let record = PhotoRecord {
            id: item.id.unwrap_or_else(|| uuid::Uuid::new_v4().to_string()),
            title: if item.title.trim().is_empty() { default_title() } else { item.title.trim().to_string() },
            category: if item.category.trim().is_empty() { "Eigen Collectie".into() } else { item.category.trim().to_string() },
            year: if item.year.trim().is_empty() { "Archief".into() } else { item.year.trim().to_string() },
            location: if item.location.trim().is_empty() { "Tholen".into() } else { item.location.trim().to_string() },
            desc: item.desc.trim().to_string(),
            filename,
            content_type,
            size_bytes: size,
            created_at: chrono::Utc::now().to_rfc3339(),
        };
        ensure_category(&state, &record.category).await;
        let mut photos = state.photos.write().await;
        if photos.iter().any(|p| p.id == record.id) {
            skipped += 1;
        } else {
            photos.push(record);
            imported += 1;
        }
    }
    persist(&state).await.map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e))?;
    Ok((
        StatusCode::OK,
        Json(serde_json::json!({ "imported": imported, "skipped": skipped })),
    ))
}

async fn list_categories(State(state): State<SharedState>) -> Json<Vec<String>> {
    let cats = state.categories.read().await;
    let mut merged: Vec<String> = cats.clone();
    {
        let photos = state.photos.read().await;
        for p in photos.iter() {
            if !merged.iter().any(|c| c.eq_ignore_ascii_case(&p.category)) {
                merged.push(p.category.clone());
            }
        }
    }
    merged.sort();
    Json(merged)
}

async fn add_category(
    State(state): State<SharedState>,
    Json(body): Json<serde_json::Value>,
) -> (StatusCode, Json<Vec<String>>) {
    if let Some(name) = body.get("name").and_then(|v| v.as_str()) {
        ensure_category(&state, name).await;
        let _ = persist(&state).await;
    }
    (StatusCode::CREATED, Json(state.categories.read().await.clone()))
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

#[tokio::main]
async fn main() {
    let module_root = std::env::current_dir().expect("kon werkmap niet bepalen");
    let data_dir = module_root.join("data");
    let uploads_dir = module_root.join("uploads");
    fs::create_dir_all(&data_dir).expect("kon data/ niet aanmaken");
    fs::create_dir_all(&uploads_dir).expect("kon uploads/ niet aanmaken");

    let default_cats: Vec<String> = vec![
        "Eigen Collectie".into(),
        "Vloot TH 2 / TH 12 / TH 90".into(),
        "Kruittoren 23 & Contr'Escarpe".into(),
        "Bol van Lodijke & Percelen".into(),
        "Hofsteden & Schakerloo".into(),
        "Archeologie & Klepduiker".into(),
    ];

    let photos = load_json(&data_dir.join("photos.json"), Vec::<PhotoRecord>::new());
    let categories = load_json(&data_dir.join("categories.json"), default_cats);

    println!("==> Fotomodule: {} foto('s) geladen uit data/photos.json", photos.len());

    let state = Arc::new(AppState {
        photos: RwLock::new(photos),
        categories: RwLock::new(categories),
        data_dir,
        uploads_dir: uploads_dir.clone(),
    });

    let app = Router::new()
        .route("/", get(root))
        .route("/admin", get(admin_page))
        .route("/api/photos", get(list_photos).post(create_photo))
        .route("/api/photos/stats", get(stats))
        .route("/api/photos/export", get(export_photos))
        .route("/api/photos/import", axum::routing::post(import_photos))
        .route(
            "/api/photos/:id",
            get(get_photo)
                .patch(update_photo)
                .delete(delete_photo),
        )
        .route("/api/categories", get(list_categories).post(add_category))
        .nest_service("/uploads", ServeDir::new(&uploads_dir))
        .layer(DefaultBodyLimit::max(64 * 1024 * 1024))
        .layer(CorsLayer::permissive())
        .with_state(state);

    let listener = tokio::net::TcpListener::bind("0.0.0.0:8082")
        .await
        .expect("kon poort 8082 niet binden (draait de CMS-server al?)");
    println!("==> Fotomodule live op http://127.0.0.1:8082");
    println!("==> Beheerinterface:  http://127.0.0.1:8082/admin");
    println!("==> API:             GET|POST /api/photos  |  GET|PATCH|DELETE /api/photos/:id");
    axum::serve(listener, app).await.expect("serverfout");
}
