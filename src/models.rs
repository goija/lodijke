//! Shared data models voor Lodijke CMS

use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use std::collections::HashMap;

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct CmsRecord {
    pub id: String,
    pub title: String,
    pub content: Option<String>,
    pub author: Option<String>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
    pub tags: Vec<String>,
    pub status: String, // "draft", "published", "archived"
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Collection {
    pub identifier: String,
    pub title: String,
    pub description: Option<String>,
    pub items_count: usize,
    pub created_at: DateTime<Utc>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct GeoParcel {
    pub id: String,
    pub cadastral_code: String,
    pub area_hectares: Option<f64>,
    pub rd_polygon: Vec<[f64; 2]>,
    pub metadata: HashMap<String, String>,
}
