use axum::{routing::{get, post}, Json, Router};
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use std::fs;
use chrono::{DateTime, Utc};
use uuid::Uuid;

#[derive(Clone, Debug, Serialize, Deserialize, Default)]
pub struct Photo {
    pub id: String,
    pub title: String,
    pub description: Option<String>,
    pub category: Option<String>,
    pub filename: String,
    pub uploaded_at: DateTime<Utc>,
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/api/photos/categories", get(get_categories))
        .route("/api/photos/search", get(search_photos))
}

pub async fn get_categories(State(s): State<AppState>) -> Json<serde_json::Value> {
    let p = s.photos.read().await;
    let cats: Vec<_> = p.iter().filter_map(|ph| ph.category.as_deref()).collect();
    let unique: Vec<_> = cats.into_iter().collect::<std::collections::HashSet<_>>().into_iter().collect();
    Json(json!({"categories": unique}))
}

pub async fn search_photos(query: Option<String>, State(s): State<AppState>) -> Json<serde_json::Value> {
    let p = s.photos.read().await;
    let filtered: Vec<_> = if let Some(q) = query {
        let q = q.to_lowercase();
        p.iter().filter(|ph| ph.title.to_lowercase().contains(&q)).cloned().collect()
    } else {
        p.iter().cloned().collect()
    };
    Json(json!({"results": filtered}))
}

pub async fn load_photos(base_dir: &PathBuf) -> Vec<Photo> {
    let fp = base_dir.join("data").join("photos.json");
    if let Ok(c) = fs::read_to_string(fp) {
        serde_json::from_str(&c).unwrap_or(vec![
            Photo {
                id: Uuid::new_v4().to_string(),
                title: "Demo: Hoogaars TH 2".into(),
                description: Some("Gebouwd 1902".into()),
                category: Some("Schepen".into()),
                filename: "demo.jpg".into(),
                uploaded_at: Utc::now(),
            },
        ])
    } else {
        vec![
            Photo {
                id: "demo-001".into(),
                title: "Hoogaars TH 2 Eben Haëzer".into(),
                description: Some("Gebouwd 1902, werf Van Duivendijk".into()),
                category: Some("Schepen".into()),
                filename: "hoogaars-th2.jpg".into(),
                uploaded_at: Utc::now(),
            },
            Photo {
                id: "demo-002".into(),
                title: "Visserijhaven Tholen".into(),
                category: Some("Haven".into()),
                filename: "haven-tholen.jpg".into(),
                uploaded_at: Utc::now(),
            },
        ]
    }
}
