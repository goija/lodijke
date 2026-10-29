use async_graphql::SimpleObject;
use serde::{Deserialize, Serialize};

/// 1 Zeeuws / Thools gemet (à 300 vierkante roeden) = 4405,6 m²
pub const ZEEUWS_GEMET_M2: f64 = 4405.6;
/// 1 Zeeuwse vierkante roede = 4405,6 / 300 = 14,685333... m²
pub const ZEEUWSE_ROEDE_M2: f64 = 4405.6 / 300.0;

#[derive(Debug, Clone, Serialize, Deserialize, SimpleObject)]
pub struct PlanimeterIntegrationResult {
    pub parcel_id: String,
    pub cadastral_code: String,
    pub vertices_count: usize,
    /// Oppervlakte in vierkante meters (RD EPSG:28992 Shoelace-integratie)
    pub area_m2: f64,
    /// Oppervlakte in hectaren (m² / 10.000)
    pub area_hectares: f64,
    /// Oppervlakte in Zeeuwse gemeten (m² / 4405,6)
    pub area_zeeuwse_gemeten: f64,
    /// Oppervlakte in Zeeuwse vierkante roeden (gemeten * 300)
    pub area_zeeuwse_roeden: f64,
    /// Omtrek van het perceel in meters (RD)
    pub perimeter_m: f64,
    /// Berekend zwaartepunt [X, Y] in RD-coördinaten (EPSG:28992)
    pub computed_rd_centroid: Vec<f64>,
    /// Kaartschaal voor mechanische planimeter-simulatie (standaard 1:2500)
    pub map_scale: String,
    /// Oppervlakte op de papieren kadastrale kaart in cm² bij gekozen schaal
    pub paper_area_cm2: f64,
    /// A. Ott Compensatie-Planimeter (Model Nr. 573) trommelomwentelingen (1 rev = 10 cm²)
    pub ott_573_drum_revolutions: f64,
    /// A. Ott Model Nr. 573 aflezing in nonius-eenheden (1 eenheid = 0,01 cm²)
    pub ott_573_vernier_units: i64,
    /// Verschil t.o.v. kadastraal archiefregister in hectaren
    pub archive_delta_ha: f64,
    /// Verificatiestatus
    pub verification_status: String,
}

/// Bereken oppervlakte, omtrek, zwaartepunt, Zeeuwse gemeten en A. Ott Nr. 573 planimeterwaarden
pub fn integrate_rd_polygon(
    parcel_id: &str,
    cadastral_code: &str,
    rd_polygon: &[Vec<f64>],
    recorded_ha: Option<f64>,
    scale_denom: u32,
) -> PlanimeterIntegrationResult {
    let n = rd_polygon.len();
    if n < 3 {
        return PlanimeterIntegrationResult {
            parcel_id: parcel_id.to_string(),
            cadastral_code: cadastral_code.to_string(),
            vertices_count: n,
            area_m2: 0.0,
            area_hectares: 0.0,
            area_zeeuwse_gemeten: 0.0,
            area_zeeuwse_roeden: 0.0,
            perimeter_m: 0.0,
            computed_rd_centroid: vec![0.0, 0.0],
            map_scale: format!("1:{}", scale_denom),
            paper_area_cm2: 0.0,
            ott_573_drum_revolutions: 0.0,
            ott_573_vernier_units: 0,
            archive_delta_ha: 0.0,
            verification_status: "INVALID_POLYGON".to_string(),
        };
    }

    let mut signed_double_area = 0.0_f64;
    let mut perimeter = 0.0_f64;
    let mut cx_acc = 0.0_f64;
    let mut cy_acc = 0.0_f64;

    for i in 0..n {
        let j = (i + 1) % n;
        let x_i = rd_polygon[i].first().copied().unwrap_or(0.0);
        let y_i = rd_polygon[i].get(1).copied().unwrap_or(0.0);
        let x_j = rd_polygon[j].first().copied().unwrap_or(0.0);
        let y_j = rd_polygon[j].get(1).copied().unwrap_or(0.0);

        let cross = x_i * y_j - x_j * y_i;
        signed_double_area += cross;
        cx_acc += (x_i + x_j) * cross;
        cy_acc += (y_i + y_j) * cross;

        let dx = x_j - x_i;
        let dy = y_j - y_i;
        perimeter += (dx * dx + dy * dy).sqrt();
    }

    let area_m2 = 0.5 * signed_double_area.abs();
    let area_ha = area_m2 / 10_000.0;
    let gemeten = area_m2 / ZEEUWS_GEMET_M2;
    let roeden = area_m2 / ZEEUWSE_ROEDE_M2;

    let (cx, cy) = if signed_double_area.abs() > 1e-9 {
        (
            cx_acc / (3.0 * signed_double_area),
            cy_acc / (3.0 * signed_double_area),
        )
    } else {
        (rd_polygon[0][0], rd_polygon[0][1])
    };

    // Bij schaal 1:S komt 1 cm op de kaart overeen met (S / 100) meter in het veld.
    // Dus 1 cm² op de kaart = (S / 100)² m² in het veld.
    let s_meters_per_cm = (scale_denom.max(100) as f64) / 100.0;
    let m2_per_cm2 = s_meters_per_cm * s_meters_per_cm;
    let paper_cm2 = area_m2 / m2_per_cm2;

    // A. Ott Polaire Compensatie-Planimeter Model Nr. 573:
    // Standaard poolarm-instelling: 1 volledige trommelomwenteling (1000 nonius-eenheden) = 10,0 cm²
    let drum_revs = paper_cm2 / 10.0;
    let vernier_units = (paper_cm2 * 100.0).round() as i64;

    let delta_ha = recorded_ha.map(|r| (area_ha - r).abs()).unwrap_or(0.0);
    let status = if delta_ha < 0.01 {
        "EXACT_KADASTRAAL_GEVERIFIEERD".to_string()
    } else {
        "GEINTEGREERD_UIT_RD_POLYGOON".to_string()
    };

    PlanimeterIntegrationResult {
        parcel_id: parcel_id.to_string(),
        cadastral_code: cadastral_code.to_string(),
        vertices_count: n,
        area_m2: round4(area_m2),
        area_hectares: round4(area_ha),
        area_zeeuwse_gemeten: round4(gemeten),
        area_zeeuwse_roeden: round2(roeden),
        perimeter_m: round2(perimeter),
        computed_rd_centroid: vec![round2(cx), round2(cy)],
        map_scale: format!("1:{}", scale_denom),
        paper_area_cm2: round4(paper_cm2),
        ott_573_drum_revolutions: round4(drum_revs),
        ott_573_vernier_units: vernier_units,
        archive_delta_ha: round4(delta_ha),
        verification_status: status,
    }
}

fn round2(v: f64) -> f64 {
    (v * 100.0).round() / 100.0
}

fn round4(v: f64) -> f64 {
    (v * 10_000.0).round() / 10_000.0
}
