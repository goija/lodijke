use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub struct RdPoint {
    pub x: f64,
    pub y: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlanimeterRequest {
    pub name: Option<String>,
    pub scale_denominator: Option<f64>,
    pub vertices: Vec<RdPoint>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlanimeterResult {
    pub name: String,
    pub vertex_count: usize,
    pub area_m2: f64,
    pub area_hectares: f64,
    pub area_zeeuwse_gemeten: f64,
    pub area_zeeuwse_roeden: f64,
    pub perimeter_m: f64,
    pub centroid_rd: RdPoint,
    pub centroid_wgs84: [f64; 2],
    pub ott_573_drum_delta: f64,
    pub scale_denominator: f64,
}

/// Exacte Gauss-veterformule (Shoelace) + omtrek + zwaartepunt in RD (EPSG:28992)
pub fn compute_rd_planimeter(req: &PlanimeterRequest) -> PlanimeterResult {
    let n = req.vertices.len();
    let name = req
        .name
        .clone()
        .unwrap_or_else(|| "Visser Dossier Perceel".to_string());
    let scale = req.scale_denominator.unwrap_or(2500.0).max(1.0);

    if n < 3 {
        let first = req.vertices.first().copied().unwrap_or(RdPoint {
            x: 71460.0,
            y: 385700.0,
        });
        let wgs = rd_to_wgs84(first.x, first.y);
        return PlanimeterResult {
            name,
            vertex_count: n,
            area_m2: 0.0,
            area_hectares: 0.0,
            area_zeeuwse_gemeten: 0.0,
            area_zeeuwse_roeden: 0.0,
            perimeter_m: 0.0,
            centroid_rd: first,
            centroid_wgs84: wgs,
            ott_573_drum_delta: 0.0,
            scale_denominator: scale,
        };
    }

    let mut signed_double_area = 0.0_f64;
    let mut perimeter = 0.0_f64;
    let mut cx = 0.0_f64;
    let mut cy = 0.0_f64;

    for i in 0..n {
        let p0 = req.vertices[i];
        let p1 = req.vertices[(i + 1) % n];

        let cross = p0.x * p1.y - p1.x * p0.y;
        signed_double_area += cross;
        cx += (p0.x + p1.x) * cross;
        cy += (p0.y + p1.y) * cross;

        let dx = p1.x - p0.x;
        let dy = p1.y - p0.y;
        perimeter += (dx * dx + dy * dy).sqrt();
    }

    let area_m2 = 0.5 * signed_double_area.abs();
    let area_hectares = area_m2 / 10_000.0;

    // Historische Zeeuwse / Thoolse maatvoering (1 Gemet = 300 Roeden ≈ 4091.58 m2)
    let area_zeeuwse_gemeten = area_m2 / 4091.58;
    let area_zeeuwse_roeden = area_m2 / 13.6386;

    let (centroid_x, centroid_y) = if signed_double_area.abs() > 1e-9 {
        (
            cx / (3.0 * signed_double_area),
            cy / (3.0 * signed_double_area),
        )
    } else {
        let sum_x: f64 = req.vertices.iter().map(|p| p.x).sum();
        let sum_y: f64 = req.vertices.iter().map(|p| p.y).sum();
        (sum_x / (n as f64), sum_y / (n as f64))
    };

    // A. Ott Compensation Polar Planimeter Model Nr. 573:
    // Kaartoppervlak in cm^2 bij gegeven schaal 1:S -> 1 cm^2 op kaart = (S / 100)^2 m^2 in terrein.
    // Standaard nonius-eenheid = 0.1 cm^2 (10 mm^2) per telwerk-eenheid.
    let m2_per_cm2_on_map = (scale / 100.0).powi(2);
    let map_area_cm2 = area_m2 / m2_per_cm2_on_map;
    let ott_573_drum_delta = map_area_cm2 * 10.0;

    let wgs = rd_to_wgs84(centroid_x, centroid_y);

    PlanimeterResult {
        name,
        vertex_count: n,
        area_m2,
        area_hectares,
        area_zeeuwse_gemeten,
        area_zeeuwse_roeden,
        perimeter_m: perimeter,
        centroid_rd: RdPoint {
            x: centroid_x,
            y: centroid_y,
        },
        centroid_wgs84: wgs,
        ott_573_drum_delta,
        scale_denominator: scale,
    }
}

/// RDNAP / Schreutelkamp-benadering van RD (Amersfoort X0=155000, Y0=463000) naar WGS84 [lat, lon]
pub fn rd_to_wgs84(x: f64, y: f64) -> [f64; 2] {
    let dx = (x - 155_000.0) * 1e-5;
    let dy = (y - 463_000.0) * 1e-5;

    let sum_lat = (3235.65389 * dy)
        + (-32.58297 * dx.powi(2))
        + (-0.24750 * dy.powi(2))
        + (-0.84978 * dx.powi(2) * dy)
        + (-0.06550 * dy.powi(3))
        + (-0.01709 * dx.powi(2) * dy.powi(2))
        + (-0.00738 * dx)
        + (0.00530 * dx.powi(4));

    let sum_lon = (5260.52916 * dx)
        + (105.94684 * dx * dy)
        + (2.45656 * dx * dy.powi(2))
        + (-0.81885 * dx.powi(3))
        + (0.05594 * dx * dy.powi(3))
        + (-0.05607 * dx.powi(3) * dy)
        + (0.01199 * dy)
        + (-0.00256 * dx.powi(3) * dy.powi(2));

    let lat = 52.15517440 + (sum_lat / 3600.0);
    let lon = 5.38720621 + (sum_lon / 3600.0);
    [lat, lon]
}
