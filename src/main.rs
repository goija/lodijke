use axum::{
    extract::State,
    http::StatusCode,
    routing::{get, get_service},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use std::{fs, net::SocketAddr, path::PathBuf, sync::Arc};
use tokio::sync::RwLock;
use tower_http::{cors::CorsLayer, services::ServeDir};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CmsRecord {
    pub id: String,
    pub title: String,
    pub category: String,
    pub date: String,
    pub body: String,
}

#[derive(Clone)]
pub struct AppState {
    pub data_file: PathBuf,
    pub cache: Arc<RwLock<Vec<CmsRecord>>>,
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
        cache: Arc::new(RwLock::new(initial_records)),
    };

    let app = Router::new()
        .route("/api/cms", get(get_cms_records).post(add_cms_record))
        .fallback_service(get_service(ServeDir::new(".")))
        .layer(CorsLayer::permissive())
        .with_state(state);

    let addr = SocketAddr::from(([127, 0, 0, 1], 8082));
    println!("==================================================================");
    println!("Rust Axum CMS & Solid POD Server actief op: http://{}", addr);
    println!("==================================================================");

    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn get_cms_records(State(state): State<AppState>) -> Json<Vec<CmsRecord>> {
    let records = state.cache.read().await;
    Json(records.clone())
}

async fn add_cms_record(
    State(state): State<AppState>,
    Json(payload): Json<CmsRecord>,
) -> (StatusCode, Json<Vec<CmsRecord>>) {
    let mut records = state.cache.write().await;
    records.insert(0, payload);
    if let Ok(serialized) = serde_json::to_string_pretty(&*records) {
        let _ = fs::write(&state.data_file, serialized);
    }
    (StatusCode::CREATED, Json(records.clone()))
}
