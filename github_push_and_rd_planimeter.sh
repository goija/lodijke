#!/usr/bin/env bash
set -euo pipefail

cd ~/lodijke

echo "================================================================="
echo " STAP 1: EERST HUIDIGE STAAT COMMITTEN EN PUSHEN NAAR GITHUB"
echo "================================================================="

# Zorg dat grote build-artefacten niet per ongeluk meegepusht worden
if ! grep -q "^/target" .gitignore 2>/dev/null; then
    echo "/target" >> .gitignore
fi

git add -A
if ! git diff --cached --quiet; then
    git commit -m "feat(visser-dossier): clean main page, purge Solid POD photos, add GRAMPS XML 1.7.1 API & offline Vue CMS"
    git push origin main
    echo "[GitHub] Eerste push succesvol afgerond!"
else
    echo "[GitHub] Working tree was al schoon, we pushen eventuele lokale commits..."
    git push origin main || true
fi

echo "================================================================="
echo " STAP 2: RD-PLANIMETER & GEODETISCHE ENGINE IN RUST TOEVOEGEN"
echo "================================================================="

cat << 'RUST' > src/planimeter.rs
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
RUST

echo "=== [3/5] Koppelen van planimeter-module aan src/main.rs ==="
python3 - << 'PYEOF'
with open("src/main.rs", "r") as f:
    code = f.read()

if "mod planimeter;" not in code:
    code = "mod planimeter;\nuse planimeter::{compute_rd_planimeter, PlanimeterRequest};\n" + code

handler_fn = """
async fn calculate_planimeter_handler(
    Json(req): Json<PlanimeterRequest>,
) -> impl IntoResponse {
    let result = compute_rd_planimeter(&req);
    Json(result)
}
"""

if "calculate_planimeter_handler" not in code:
    code = code.replace("#[tokio::main]", handler_fn + "\n#[tokio::main]")
    code = code.replace(
        '.route("/api/geojson", get(export_geojson))',
        '.route("/api/geojson", get(export_geojson))\n        .route("/api/planimeter/calculate", post(calculate_planimeter_handler))'
    )

with open("src/main.rs", "w") as f:
    f.write(code)
PYEOF

echo "=== [4/5] Toevoegen van RD-Planimeter Tab & Offline Kaartcanvas aan index.html ==="
python3 - << 'PYEOF'
with open("index.html", "r") as f:
    html = f.read()

# 1. Voeg de knop toe in de navigatiebalk
nav_target = """<button @click="activeTab = 'solid'" :class="tabClass('solid')">Solid POD</button>"""
nav_replacement = """<button @click="activeTab = 'planimeter'" :class="tabClass('planimeter')">RD-Planimeter & Kaart</button>
      <button @click="activeTab = 'solid'" :class="tabClass('solid')">Solid POD</button>"""

if "activeTab = 'planimeter'" not in html:
    html = html.replace(nav_target, nav_replacement)

# 2. Voeg de RD-Planimeter sectie toe voor de Solid POD sectie
planimeter_section = """    <!-- 5. RD-PLANIMETER & GEODETISCHE KAART (LODIJKE / REIMERSWAAL / SCHERPENISSE) -->
    <section v-if="activeTab === 'planimeter'" class="space-y-6">
      <div class="card p-6 space-y-4">
        <div class="flex flex-wrap items-center justify-between gap-4 border-b border-slate-800 pb-4">
          <div>
            <h2 class="text-xl font-bold text-white">RD-Planimeter (EPSG:28992) & A. Ott Nr. 573 Integrator</h2>
            <p class="text-xs text-slate-400">
              Klik op het RD-kaartvlak of voer Rijksdriehoekscoördinaten (X, Y) in om exacte oppervlakte in m², Hectare, Zeeuwse Gemeten en A. Ott trommel-eenheden te berekenen.
            </p>
          </div>
          <div class="flex flex-wrap gap-2">
            <button @click="loadPresetParcel('lodijke')" class="px-3 py-1.5 rounded bg-blue-900 text-blue-200 text-xs font-semibold hover:bg-blue-800">
              Preset: Bol van Lodijke (Visrecht)
            </button>
            <button @click="loadPresetParcel('reimerswaal')" class="px-3 py-1.5 rounded bg-emerald-900 text-emerald-200 text-xs font-semibold hover:bg-emerald-800">
              Preset: Verdronken Land Reimerswaal
            </button>
            <button @click="loadPresetParcel('scherpenisse')" class="px-3 py-1.5 rounded bg-amber-900 text-amber-200 text-xs font-semibold hover:bg-amber-800">
              Preset: Scherpenisse Sectie E
            </button>
            <button @click="clearPlanimeter" class="btn-danger">Wis Hoekpunten</button>
          </div>
        </div>

        <div class="grid md:grid-cols-3 gap-6">
          <!-- Interactief Offline SVG RD-Kaartvlak -->
          <div class="md:col-span-2 space-y-2">
            <div class="flex justify-between text-xs text-slate-400 font-mono">
              <span>RD-Venster: X [{{ rdViewBox.minX }} .. {{ rdViewBox.maxX }}] | Y [{{ rdViewBox.minY }} .. {{ rdViewBox.maxY }}]</span>
              <span>Klik in het vlak om een RD-hoekpunt te plaatsen</span>
            </div>
            <svg
              @click="addPointFromSvgClick"
              viewBox="0 0 600 400"
              class="w-full h-96 bg-slate-950 border border-slate-800 rounded cursor-crosshair select-none"
            >
              <!-- RD Gridlijnen -->
              <g stroke="#1e293b" stroke-width="1">
                <line v-for="gx in [100,200,300,400,500]" :key="'gx'+gx" :x1="gx" y1="0" :x2="gx" y2="400" />
                <line v-for="gy in [80,160,240,320]" :key="'gy'+gy" x1="0" :y1="gy" x2="600" :y2="gy" />
              </g>

              <!-- GRAMPS Places uit Database -->
              <g v-for="pl in gramps.places" :key="pl.handle">
                <circle
                  :cx="rdToSvgX(pl.rd_x)"
                  :cy="rdToSvgY(pl.rd_y)"
                  r="5"
                  fill="#38bdf8"
                />
                <text
                  :x="rdToSvgX(pl.rd_x) + 8"
                  :y="rdToSvgY(pl.rd_y) + 4"
                  fill="#bae6fd"
                  font-size="11"
                  font-family="monospace"
                >{{ pl.title }} ({{ pl.rd_x }}, {{ pl.rd_y }})</text>
              </g>

              <!-- Getekend Planimeter Polygoon -->
              <polygon
                v-if="planimeterVertices.length >= 3"
                :points="svgPolygonPoints"
                fill="rgba(37, 99, 235, 0.28)"
                stroke="#60a5fa"
                stroke-width="2"
              />
              <polyline
                v-else-if="planimeterVertices.length === 2"
                :points="svgPolygonPoints"
                fill="none"
                stroke="#60a5fa"
                stroke-width="2"
              />

              <!-- Hoekpunten -->
              <g v-for="(pt, idx) in planimeterVertices" :key="'pt'+idx">
                <circle :cx="rdToSvgX(pt.x)" :cy="rdToSvgY(pt.y)" r="4.5" fill="#f59e0b" />
                <text
                  :x="rdToSvgX(pt.x) + 6"
                  :y="rdToSvgY(pt.y) - 6"
                  fill="#fde68a"
                  font-size="10"
                  font-family="monospace"
                >#{{ idx + 1 }}</text>
              </g>

              <!-- Zwaartepunt (Centroid) -->
              <g v-if="planimeterStats.vertex_count >= 3">
                <circle
                  :cx="rdToSvgX(planimeterStats.centroid_rd.x)"
                  :cy="rdToSvgY(planimeterStats.centroid_rd.y)"
                  r="5"
                  fill="#10b981"
                />
              </g>
            </svg>
          </div>

          <!-- Numerieke RD-Planimeter Uitlezing -->
          <div class="space-y-4">
            <div class="p-4 rounded bg-slate-900 border border-slate-800 space-y-2 font-mono text-xs">
              <div class="text-slate-400 font-sans font-bold text-sm border-b border-slate-800 pb-1">
                Planimetrische Uitkomst
              </div>
              <div class="flex justify-between">
                <span class="text-slate-400">Hoekpunten (N):</span>
                <span class="text-white font-bold">{{ planimeterStats.vertex_count }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-400">Oppervlakte (m²):</span>
                <span class="text-emerald-400 font-bold">{{ planimeterStats.area_m2.toFixed(2) }} m²</span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-400">Hectare (ha):</span>
                <span class="text-emerald-300 font-bold">{{ planimeterStats.area_hectares.toFixed(4) }} ha</span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-400">Zeeuwse Gemeten:</span>
                <span class="text-amber-300 font-bold">{{ planimeterStats.area_zeeuwse_gemeten.toFixed(4) }} gemet</span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-400">Zeeuwse Roeden:</span>
                <span class="text-amber-200">{{ planimeterStats.area_zeeuwse_roeden.toFixed(2) }} roeden</span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-400">Omtrek (Perimeter):</span>
                <span class="text-sky-300">{{ planimeterStats.perimeter_m.toFixed(2) }} m</span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-400">RD Centroid (X, Y):</span>
                <span class="text-slate-200">{{ planimeterStats.centroid_rd.x.toFixed(1) }}, {{ planimeterStats.centroid_rd.y.toFixed(1) }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-400">A. Ott Nr. 573 (ΔN @ 1:{{ planimeterScale }}):</span>
                <span class="text-purple-300 font-bold">{{ planimeterStats.ott_573_drum_delta.toFixed(1) }} eenh.</span>
              </div>
            </div>

            <!-- Handmatig RD-punt toevoegen -->
            <div class="p-4 rounded bg-slate-900 border border-slate-800 space-y-2">
              <div class="text-xs font-semibold text-white">Handmatig RD-punt (X, Y) invoeren</div>
              <div class="grid grid-cols-2 gap-2">
                <input v-model.number="manualRdPoint.x" type="number" step="any" placeholder="RD X (bijv. 71460)" class="input-dark text-xs" />
                <input v-model.number="manualRdPoint.y" type="number" step="any" placeholder="RD Y (bijv. 385700)" class="input-dark text-xs" />
              </div>
              <button @click="addManualRdPoint" class="btn-primary w-full text-xs">Voeg RD-Punt Toe</button>
            </div>

            <!-- Hoekpuntenlijst -->
            <div class="max-h-40 overflow-y-auto space-y-1 text-xs font-mono">
              <div
                v-for="(pt, idx) in planimeterVertices"
                :key="'list'+idx"
                class="flex justify-between items-center px-2.5 py-1 bg-slate-950 rounded border border-slate-800"
              >
                <span>#{{ idx + 1 }}: X={{ pt.x.toFixed(1) }}, Y={{ pt.y.toFixed(1) }}</span>
                <button @click="removePlanimeterPoint(idx)" class="text-red-400 hover:text-red-300">×</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- 6. SOLID POD BEHEER (FOTO-VRIJ) -->"""

if "activeTab === 'planimeter'" not in html:
    html = html.replace("    <!-- 5. SOLID POD BEHEER (FOTO-VRIJ) -->", planimeter_section)

# 3. Voeg Vue data & methods voor de RD-Planimeter toe
data_target = "solidStatus: null"
data_replacement = """solidStatus: null,
      planimeterScale: 2500,
      manualRdPoint: { x: 71460, y: 385700 },
      planimeterVertices: [
        { x: 71350.0, y: 385600.0 },
        { x: 71620.0, y: 385600.0 },
        { x: 71620.0, y: 385840.0 },
        { x: 71350.0, y: 385840.0 }
      ],
      planimeterStats: {
        vertex_count: 4,
        area_m2: 64800.0,
        area_hectares: 6.48,
        area_zeeuwse_gemeten: 15.8374,
        area_zeeuwse_roeden: 4751.22,
        perimeter_m: 1020.0,
        centroid_rd: { x: 71485.0, y: 385720.0 },
        ott_573_drum_delta: 1036.8
      }"""

if "planimeterVertices" not in html:
    html = html.replace(data_target, data_replacement)

computed_block = """  computed: {
    rdViewBox() {
      const pts = [...this.planimeterVertices];
      for (const pl of (this.gramps.places || [])) {
        if (pl.rd_x && pl.rd_y) pts.push({ x: pl.rd_x, y: pl.rd_y });
      }
      if (!pts.length) {
        return { minX: 68500, maxX: 72500, minY: 384500, maxY: 387500 };
      }
      const xs = pts.map(p => p.x);
      const ys = pts.map(p => p.y);
      const padX = Math.max(250, (Math.max(...xs) - Math.min(...xs)) * 0.25);
      const padY = Math.max(250, (Math.max(...ys) - Math.min(...ys)) * 0.25);
      return {
        minX: Math.floor(Math.min(...xs) - padX),
        maxX: Math.ceil(Math.max(...xs) + padX),
        minY: Math.floor(Math.min(...ys) - padY),
        maxY: Math.ceil(Math.max(...ys) + padY)
      };
    },
    svgPolygonPoints() {
      return this.planimeterVertices
        .map(p => `${this.rdToSvgX(p.x)},${this.rdToSvgY(p.y)}`)
        .join(' ');
    }
  },
  methods: {"""

if "svgPolygonPoints()" not in html:
    html = html.replace("  methods: {", computed_block)

planimeter_methods = """    rdToSvgX(x) {
      const vb = this.rdViewBox;
      const span = Math.max(1, vb.maxX - vb.minX);
      return ((x - vb.minX) / span) * 600;
    },
    rdToSvgY(y) {
      const vb = this.rdViewBox;
      const span = Math.max(1, vb.maxY - vb.minY);
      return 400 - ((y - vb.minY) / span) * 400;
    },
    addPointFromSvgClick(ev) {
      const rect = ev.currentTarget.getBoundingClientRect();
      const sx = ((ev.clientX - rect.left) / rect.width) * 600;
      const sy = ((ev.clientY - rect.top) / rect.height) * 400;
      const vb = this.rdViewBox;
      const rx = vb.minX + (sx / 600) * (vb.maxX - vb.minX);
      const ry = vb.minY + ((400 - sy) / 400) * (vb.maxY - vb.minY);
      this.planimeterVertices.push({ x: Math.round(rx * 10) / 10, y: Math.round(ry * 10) / 10 });
      this.recalculatePlanimeter();
    },
    addManualRdPoint() {
      if (typeof this.manualRdPoint.x === 'number' && typeof this.manualRdPoint.y === 'number') {
        this.planimeterVertices.push({ x: this.manualRdPoint.x, y: this.manualRdPoint.y });
        this.recalculatePlanimeter();
      }
    },
    removePlanimeterPoint(idx) {
      this.planimeterVertices.splice(idx, 1);
      this.recalculatePlanimeter();
    },
    clearPlanimeter() {
      this.planimeterVertices = [];
      this.recalculatePlanimeter();
    },
    loadPresetParcel(preset) {
      if (preset === 'lodijke') {
        this.planimeterVertices = [
          { x: 71350.0, y: 385600.0 },
          { x: 71620.0, y: 385600.0 },
          { x: 71620.0, y: 385840.0 },
          { x: 71350.0, y: 385840.0 }
        ];
      } else if (preset === 'reimerswaal') {
        this.planimeterVertices = [
          { x: 69050.0, y: 386500.0 },
          { x: 69520.0, y: 386500.0 },
          { x: 69580.0, y: 386920.0 },
          { x: 69010.0, y: 386890.0 }
        ];
      } else if (preset === 'scherpenisse') {
        this.planimeterVertices = [
          { x: 65910.0, y: 395720.0 },
          { x: 65965.0, y: 395720.0 },
          { x: 65965.0, y: 395785.0 },
          { x: 65910.0, y: 395785.0 }
        ];
      }
      this.recalculatePlanimeter();
    },
    async recalculatePlanimeter() {
      // 1. Directe lokale (offline) Shoelace berekening
      const pts = this.planimeterVertices;
      const n = pts.length;
      if (n < 3) {
        this.planimeterStats = {
          vertex_count: n,
          area_m2: 0,
          area_hectares: 0,
          area_zeeuwse_gemeten: 0,
          area_zeeuwse_roeden: 0,
          perimeter_m: 0,
          centroid_rd: pts[0] || { x: 71460, y: 385700 },
          ott_573_drum_delta: 0
        };
        return;
      }
      let signed2A = 0, perim = 0, cx = 0, cy = 0;
      for (let i = 0; i < n; i++) {
        const p0 = pts[i], p1 = pts[(i + 1) % n];
        const cross = p0.x * p1.y - p1.x * p0.y;
        signed2A += cross;
        cx += (p0.x + p1.x) * cross;
        cy += (p0.y + p1.y) * cross;
        perim += Math.hypot(p1.x - p0.x, p1.y - p0.y);
      }
      const area_m2 = 0.5 * Math.abs(signed2A);
      const m2PerCm2 = Math.pow(this.planimeterScale / 100.0, 2);
      this.planimeterStats = {
        vertex_count: n,
        area_m2,
        area_hectares: area_m2 / 10000.0,
        area_zeeuwse_gemeten: area_m2 / 4091.58,
        area_zeeuwse_roeden: area_m2 / 13.6386,
        perimeter_m: perim,
        centroid_rd: {
          x: Math.abs(signed2A) > 1e-9 ? cx / (3 * signed2A) : pts[0].x,
          y: Math.abs(signed2A) > 1e-9 ? cy / (3 * signed2A) : pts[0].y
        },
        ott_573_drum_delta: (area_m2 / m2PerCm2) * 10.0
      };

      // 2. Synchroniseer met de Rust-backend indien online
      try {
        const res = await fetch('/api/planimeter/calculate', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            name: 'Visser Dossier Perceel',
            scale_denominator: this.planimeterScale,
            vertices: this.planimeterVertices
          })
        });
        if (res.ok) {
          this.planimeterStats = await res.json();
        }
      } catch (_) {}
    },
    exportBackup() {"""

if "recalculatePlanimeter()" not in html:
    html = html.replace("    exportBackup() {", planimeter_methods)

with open("index.html", "w") as f:
    f.write(html)

try:
    with open("frontend/index.html", "w") as f2:
        f2.write(html)
except Exception:
    pass
PYEOF

echo "=== [5/5] Compileren, herstarten en RD-Planimeter pushen naar GitHub ==="
cargo build --release
systemctl --user restart lodijke-cms-server.service 2>/dev/null || true

git add -A
if ! git diff --cached --quiet; then
    git commit -m "feat(planimeter): add RD (EPSG:28992) Shoelace planimeter, Zeeuwse gemeten & A. Ott 573 integration"
    git push origin main
    echo "[GitHub] Tweede push (inclusief RD-Planimeter) succesvol voltooid!"
fi

echo "================================================================="
echo " KLAAR! Beide stappen zijn afgerond:"
echo " 1. Eerste GitHub-update is gepusht naar origin/main."
echo " 2. RD-Planimeter (Shoelace + Zeeuwse Gemeten + A. Ott Nr. 573)"
echo "    is gebouwd, actief in Vue én gepusht naar GitHub."
echo "================================================================="
