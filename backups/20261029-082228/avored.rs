use async_graphql::{InputObject, SimpleObject};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};

#[derive(Debug, Clone, Serialize, Deserialize, SimpleObject, InputObject)]
#[graphql(input_name = "AvoRedFieldInput")]
pub struct AvoRedField {
    pub name: String,
    pub field_type: String,
    pub required: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, SimpleObject)]
pub struct AvoRedCollection {
    pub identifier: String,
    pub name: String,
    pub fields: Vec<AvoRedField>,
}

#[derive(Debug, Clone, Serialize, Deserialize, InputObject)]
pub struct CreateCollectionInput {
    pub identifier: String,
    pub name: String,
    pub fields: Vec<AvoRedField>,
}

#[derive(Debug, Clone, Serialize, Deserialize, SimpleObject)]
pub struct CmsRecord {
    pub id: String,
    pub title: String,
    pub category: String,
    #[serde(default = "default_collection")]
    pub collection: String,
    pub date: String,
    #[serde(default = "default_author")]
    pub author_id: String,
    #[serde(default = "default_shield")]
    pub avg_shield: bool,
    pub body: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, InputObject)]
pub struct CreateCmsRecordInput {
    pub id: Option<String>,
    pub title: String,
    pub category: String,
    pub collection: Option<String>,
    pub date: String,
    pub body: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, SimpleObject)]
pub struct GeoParcelFeature {
    pub id: String,
    pub cadastral_code: String,
    pub name: String,
    pub municipality: String,
    pub section: String,
    pub parcel_number: String,
    pub area_hectares: f64,
    pub area_gemeten: f64,
    pub owner_lessee: String,
    pub period: String,
    pub rd_epsg: i32,
    pub rd_centroid: Vec<f64>,
    pub rd_polygon: Vec<Vec<f64>>,
    pub wgs84_epsg: i32,
    pub wgs84_centroid: Vec<f64>,
    pub wgs84_polygon: Vec<Vec<f64>>,
}

impl GeoParcelFeature {
    pub fn to_rfc7946_feature(&self) -> Value {
        json!({
            "type": "Feature",
            "id": self.id,
            "properties": {
                "cadastral_code": self.cadastral_code,
                "name": self.name,
                "municipality": self.municipality,
                "section": self.section,
                "parcel_number": self.parcel_number,
                "area_hectares": self.area_hectares,
                "area_gemeten": self.area_gemeten,
                "owner_lessee": self.owner_lessee,
                "period": self.period,
                "rd_epsg": self.rd_epsg,
                "rd_centroid": self.rd_centroid,
                "wgs84_centroid": self.wgs84_centroid
            },
            "geometry": {
                "type": "Polygon",
                "crs": "EPSG:4326",
                "coordinates": [self.wgs84_polygon]
            },
            "rd_geometry": {
                "type": "Polygon",
                "crs": "EPSG:28992",
                "coordinates": [self.rd_polygon]
            }
        })
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, InputObject)]
pub struct CreateGeoParcelInput {
    pub id: Option<String>,
    pub cadastral_code: String,
    pub name: String,
    pub municipality: String,
    pub section: String,
    pub parcel_number: String,
    pub area_hectares: f64,
    pub owner_lessee: String,
    pub period: String,
    pub rd_x: f64,
    pub rd_y: f64,
    pub wgs84_lon: f64,
    pub wgs84_lat: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize, SimpleObject)]
pub struct AuthorProfile {
    pub id: String,
    pub name: String,
    pub lifespan: String,
    pub residence: String,
    pub parcel: String,
    pub fleet: Vec<String>,
    pub avg_shield: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, SimpleObject)]
pub struct GitSyncEntry {
    pub timestamp: String,
    pub action: String,
    pub commit_hash: String,
    pub message: String,
    pub status: String,
}

fn default_collection() -> String {
    "dossiers_schot_bout".to_string()
}
fn default_author() -> String {
    "I0103".to_string()
}
fn default_shield() -> bool {
    true
}
