#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${HOME}/lodijke"
REPO_URL="https://github.com/goija/lodijke.git"
PORT=8082

mkdir -p "${PROJECT_DIR}/src" "${PROJECT_DIR}/data"
cd "${PROJECT_DIR}"

if [ ! -f "${PROJECT_DIR}/data/cms_records.json" ]; then
cat << 'JSONEOF' > "${PROJECT_DIR}/data/cms_records.json"
[
  {
    "id": "cms-01",
    "title": "Concessie Perceel No. 369 Bol van Lodijke (12,5 Hectare)",
    "category": "LODIJKE_369",
    "date": "1892 / 1915",
    "body": "Exploitatie van oesterperceel No. 369 op de Bol van Lodijke door Benjamin Willem Schot met de houten hoogaarzen TH 2 Eben Haëzer en TH 90 Vijf Gebroeders."
  },
  {
    "id": "cms-02",
    "title": "Reddingsoperatie Watersnood Oud-Vossemeer (TH 12)",
    "category": "VLOOT_HOOGAARS",
    "date": "12-13 maart 1906",
    "body": "Inzet van de roeiboot van hoogaars TH 12 'Niets zonder Gods zegen' door Thoolse vissers bij de evacuatie van Oud-Vossemeer."
  }
]
JSONEOF
fi

cat << 'TOMLEOF' > "${PROJECT_DIR}/Cargo.toml"
[package]
name = "lodijke-rust-cms"
version = "1.0.0"
edition = "2021"

[dependencies]
axum = "0.7"
tokio = { version = "1.38", features = ["full"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
tower-http = { version = "0.5", features = ["fs", "cors"] }
TOMLEOF

cat << 'RSEOF' > "${PROJECT_DIR}/src/main.rs"
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
RSEOF

cat << 'VCEOF' > "${PROJECT_DIR}/vercel.json"
{
  "version": 2,
  "cleanUrls": true,
  "trailingSlash": false
}
VCEOF

cat << 'GIEOF' > "${PROJECT_DIR}/.gitignore"
/target
.DS_Store
.vercel
GIEOF

if [ ! -d "${PROJECT_DIR}/.git" ]; then
  git init
  git branch -M main
  git remote add origin "${REPO_URL}" || git remote set-url origin "${REPO_URL}"
fi

git add .
git commit -m "Update: Rustige A+ interface, bugvrije JS & Rust Axum CMS" || true

if [[ "${1:-}" == "--deploy" ]]; then
  git push -u origin main
  if command -v vercel >/dev/null 2>&1; then
    vercel --prod
  else
    npx vercel --prod
  fi
fi

if command -v cargo >/dev/null 2>&1; then
  cargo run --release
else
  python3 -m http.server "${PORT}"
fi
