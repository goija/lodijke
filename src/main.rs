use axum::{
    extract::State,
    http::{Method, StatusCode},
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use std::{
    fs,
    net::SocketAddr,
    path::PathBuf,
    sync::{Arc, RwLock},
};
use tower_http::{
    cors::{Any, CorsLayer},
    services::ServeDir,
};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CmsRecord {
    pub id: String,
    pub category: String,
    pub title: String,
    pub period: String,
    pub location: String,
    pub summary: String,
    pub avg_shield: bool,
}

#[derive(Debug, Serialize)]
pub struct CmsStatus {
    pub service: &'static str,
    pub status: &'static str,
    pub avg_compliant: bool,
    pub record_count: usize,
    pub parcel_focus: &'static str,
}

#[derive(Clone)]
pub struct AppState {
    pub data_file: PathBuf,
    pub records: Arc<RwLock<Vec<CmsRecord>>>,
}

#[tokio::main]
async fn main() {
    let data_file = PathBuf::from("data/cms_records.json");
    let initial_records: Vec<CmsRecord> = if data_file.exists() {
        let raw = fs::read_to_string(&data_file).unwrap_or_else(|_| "[]".to_string());
        serde_json::from_str(&raw).unwrap_or_default()
    } else {
        Vec::new()
    };

    let state = AppState {
        data_file,
        records: Arc::new(RwLock::new(initial_records)),
    };

    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods([Method::GET, Method::POST, Method::OPTIONS])
        .allow_headers(Any);

    let app = Router::new()
        .route("/api/status", get(get_status))
        .route("/api/records", get(list_records).post(add_record))
        .fallback_service(ServeDir::new("."))
        .layer(cors)
        .with_state(state);

    let addr = SocketAddr::from(([0, 0, 0, 0], 8082));
    println!("==================================================================");
    println!("LODIJKE RUST AXUM CMS & SOLID POD SERVER ACTIEF OP http://{}", addr);
    println!("API Endpoints: GET /api/status | GET & POST /api/records");
    println!("==================================================================");

    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn get_status(State(state): State<AppState>) -> Json<CmsStatus> {
    let count = state.records.read().map(|r| r.len()).unwrap_or(0);
    Json(CmsStatus {
        service: "Lodijke Rust Axum CMS v1.0",
        status: "ONLINE",
        avg_compliant: true,
        record_count: count,
        parcel_focus: "Bol van Lodijke Perceel 369 (12,5 ha) & Kruittoren 23 Tholen",
    })
}

async fn list_records(State(state): State<AppState>) -> Json<Vec<CmsRecord>> {
    let list = state.records.read().map(|r| r.clone()).unwrap_or_default();
    Json(list)
}

async fn add_record(
    State(state): State<AppState>,
    Json(payload): Json<CmsRecord>,
) -> Result<(StatusCode, Json<Vec<CmsRecord>>), StatusCode> {
    let mut guard = state.records.write().map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    guard.insert(0, payload);
    let serialized = serde_json::to_string_pretty(&*guard).map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    let _ = fs::write(&state.data_file, serialized);
    Ok((StatusCode::CREATED, Json(guard.clone())))
}
