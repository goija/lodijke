use serde::{Deserialize, Serialize};

pub struct AreaConverter;

impl AreaConverter {
    pub fn shoelace(coords: &[(f64, f64)]) -> f64 {
        if coords.len() < 3 { return 0.0; }
        let n = coords.len();
        let mut sum = 0.0;
        for i in 0..n {
            let j = (i + 1) % n;
            sum += coords[i].0 * coords[j].1 - coords[j].0 * coords[i].1;
        }
        (sum.abs() / 2.0).abs()
    }

    pub fn zeeuw_to_sqm(val: f64, unit: &str) -> f64 {
        match unit {
            "gemeten" => val * 3650.0,
            "roeden2" => val * 24.6,
            _ => val,
        }
    }

    pub fn sqm_to_gemeten(sq_m: f64) -> f64 { sq_m / 3650.0 }
    
    pub fn simulate_ott(measured_cm2: f64, scale: f64) -> f64 {
        measured_cm2 * (scale * scale) / 10000.0 * (1.0 + (rand::random::<f64>() - 0.5) * 0.01)
    }
}
