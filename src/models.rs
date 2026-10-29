use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CmsRecord {
    pub id: String,
    pub title: String,
    pub content: String,
    pub category: String,
    pub tags: Vec<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub status: RecordStatus,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum RecordStatus { Draft, Published, Archived }

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GeoParcelFeature {
    pub id: String,
    pub name: String,
    pub area_sqm: f64,
    pub geometry: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PdokPerceel {
    pub id: String,
    pub perceelnummer: String,
    pub gemeente: String,
    pub sectie: String,
    pub oppervlakte: Option<f64>,
    pub geometrie: serde_json::Value,
}
