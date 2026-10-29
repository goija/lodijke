use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::env;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PdokPerceel {
    pub id: String,
    pub perceelnummer: String,
    pub gemeente: String,
    pub sectie: String,
    pub oppervlakte: Option<f64>,
    pub geometrie: serde_json::Value,
}

pub struct PdokClient {
    client: Client,
    base_url: String,
}

impl PdokClient {
    pub fn new() -> Self {
        PdokClient {
            client: Client::builder().timeout(std::time::Duration::from_secs(30)).build().unwrap(),
            base_url: env::var("PDOK_WFS_URL").unwrap_or("https://service.pdok.nl/kadaster/kadastralekaart/wfs/v5_0".into()),
        }
    }

    pub async fn get_bbox(&self, xmin: f64, ymin: f64, xmax: f64, ymax: f64) -> Result<Vec<PdokPerceel>, String> {
        let bbox = format!("{},{},{},{}", xmin, ymin, xmax, ymax);
        let url = format!("{}?service=WFS&request=GetFeature&version=2.0.0&typeNames=kadastralekaart:Perceel&bbox={},EPSG:28992&outputFormat=application/json", self.base_url, bbox);
        
        let resp = self.client.get(&url).send().await.map_err(|e| format!("Request: {}", e))?;
        if !resp.status().is_success() { return Err(format!("Status: {}", resp.status())); }
        
        let json: serde_json::Value = resp.json().await.map_err(|e| format!("JSON: {}", e))?;
        
        let features = json.get("features").and_then(|f| f.as_array()).map(|arr| {
            arr.iter().filter_map(|feat| {
                let props = feat.get("properties")?;
                Some(PdokPerceel {
                    id: feat.get("id").and_then(|i| i.as_str())?.to_string(),
                    perceelnummer: props.get("perceelnummer").and_then(|p| p.as_str()).unwrap_or("").to_string(),
                    gemeente: props.get("gemeente").and_then(|p| p.as_str()).unwrap_or("").to_string(),
                    sectie: props.get("sectie").and_then(|p| p.as_str()).unwrap_or("").to_string(),
                    oppervlakte: props.get("oppervlakte").and_then(|p| p.as_f64()),
                    geometrie: feat.get("geometry").cloned().unwrap_or(serde_json::Value::Null),
                })
            }).collect()
        }).unwrap_or_default();
        
        Ok(features)
    }

    pub async fn health(&self) -> bool {
        self.client.get(&format!("{}/?", self.base_url)).timeout(std::time::Duration::from_secs(5)).send().await.is_ok_and(|r| r.status().is_success())
    }
}
