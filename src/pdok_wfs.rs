use crate::planimeter::integrate_rd_polygon;
use async_graphql::SimpleObject;
use serde::{Deserialize, Serialize};
use serde_json::Value;

const PDOK_WFS_V5_URL: &str = "https://geodata.nationaalgeoregister.nl/kadastralekaart/wfs/v5_0";

#[derive(Debug, Clone, Serialize, Deserialize, SimpleObject)]
pub struct PdokPerceelFeature {
    pub id: String,
    pub kadastrale_aanduiding: String,
    pub gemeente: String,
    pub sectie: String,
    pub perceelnummer: String,
    pub oppervlakte_kadaster_m2: f64,
    pub calculated_shoelace_m2: f64,
    pub delta_m2: f64,
    pub wfs_crs: String,
}

pub async fn fetch_pdok_kadaster_bbox(bbox: &str) -> Result<Vec<PdokPerceelFeature>, String> {
    // Voorbeeld WFS v5.0 GetFeature request in EPSG:28992 (RD New)
    let url = format!(
        "{}?service=WFS&version=2.0.0&request=GetFeature&typeNames=kadastralekaart:perceel&outputFormat=application/json&srsName=EPSG:28992&bbox={}",
        PDOK_WFS_V5_URL, bbox
    );

    let client = reqwest::Client::new();
    let resp = client
        .get(&url)
        .header("User-Agent", "Lodijke-Archief-CMS/2.3 (woo-tholen@proton.me)")
        .send()
        .await
        .map_err(|e| format!("PDOK WFS Netwerkfout: {}", e))?;

    if !resp.status().is_success() {
        return Err(format!("PDOK WFS HTTP Status: {}", resp.status()));
    }

    let json_val: Value = resp
        .json()
        .await
        .map_err(|e| format!("Kon PDOK JSON niet parsen: {}", e))?;

    let mut results = Vec::new();
    if let Some(features) = json_val.get("features").and_then(|f| f.as_array()) {
        for f in features {
            let id = f.get("id").and_then(|v| v.as_str()).unwrap_or("onbekend").to_string();
            let props = f.get("properties");
            let gemeente = props.and_then(|p| p.get("gemeentenaam")).and_then(|v| v.as_str()).unwrap_or("Tholen").to_string();
            let sectie = props.and_then(|p| p.get("sectie")).and_then(|v| v.as_str()).unwrap_or("A").to_string();
            let perceelnummer = props.and_then(|p| p.get("perceelnummer")).and_then(|v| v.as_str()).unwrap_or("1").to_string();
            let kadastrale_aanduiding = format!("{} Sectie {} nr. {}", gemeente, sectie, perceelnummer);
            let opp_kad = props.and_then(|p| p.get("grootte")).and_then(|v| v.as_f64()).unwrap_or(0.0);

            // Haal RD-coördinaten uit geometry polygon
            let mut polygon_pts = Vec::new();
            if let Some(coords) = f.get("geometry").and_then(|g| g.get("coordinates")).and_then(|c| c.as_array()) {
                // Polygon outer ring
                if let Some(ring) = coords.first().and_then(|r| r.as_array()) {
                    for pt in ring {
                        if let Some(pt_arr) = pt.as_array() {
                            if pt_arr.len() >= 2 {
                                let x = pt_arr[0].as_f64().unwrap_or(0.0);
                                let y = pt_arr[1].as_f64().unwrap_or(0.0);
                                polygon_pts.push(vec![x, y]);
                            }
                        }
                    }
                }
            }

            let calc = if !polygon_pts.is_empty() {
                integrate_rd_polygon(&id, &kadastrale_aanduiding, &polygon_pts, Some(opp_kad / 10000.0), 2500)
            } else {
                crate::planimeter::PlanimeterIntegrationResult {
                    parcel_id: id.clone(),
                    cadastral_code: kadastral_aanduiding.clone(),
                    vertices_count: 0,
                    area_m2: opp_kad,
                    area_hectares: opp_kad / 10000.0,
                    area_zeeuwse_gemeten: opp_kad / crate::planimeter::ZEEUWS_GEMET_M2,
                    area_zeeuwse_roeden: 0.0,
                    perimeter_m: 0.0,
                    computed_rd_centroid: vec![0.0, 0.0],
                    map_scale: "1:2500".to_string(),
                    paper_area_cm2: 0.0,
                    ott_573_drum_revolutions: 0.0,
                    ott_573_vernier_units: 0,
                    archive_delta_ha: 0.0,
                    verification_status: "PDOK_WFS_DIRECT".to_string(),
                }
            };

            let delta = (calc.area_m2 - opp_kad).abs();
            results.push(PdokPerceelFeature {
                id,
                kadastrale_aanduiding,
                gemeente,
                sectie,
                perceelnummer,
                oppervlakte_kadaster_m2: opp_kad,
                calculated_shoelace_m2: calc.area_m2,
                delta_m2: delta,
                wfs_crs: "EPSG:28992".to_string(),
            });
        }
    }

    Ok(results)
}
