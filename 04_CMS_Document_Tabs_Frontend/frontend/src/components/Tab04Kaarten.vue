<template>
  <div class="kaarten-viewport">
    <!-- MODERNIZR & GEOLOCATION DIAGNOSTICS BALK -->
    <div class="geo-topbar">
      <div class="modernizr-pills">
        <span class="mod-pill" :class="features.geolocation ? 'ok' : 'err'">
          Modernizr.geolocation: {{ features.geolocation ? 'TRUE' : 'FALSE' }}
        </span>
        <span class="mod-pill" :class="features.securecontext ? 'ok' : 'warn'">
          SecureContext: {{ features.securecontext ? 'JA' : 'NEE' }}
        </span>
        <span class="mod-pill" :class="features.history ? 'ok' : 'err'">
          Modernizr.history: {{ features.history ? 'TRUE' : 'FALSE' }}
        </span>
      </div>

      <div class="geo-actions">
        <button class="btn-geo primary" @click="locateUserViaModernizr" :disabled="locating">
          {{ locating ? '🛰️ GPS Peilen...' : '📍 Mijn GPS Positie (Geolocation API)' }}
        </button>
        <button class="btn-geo" @click="toggleWatchPosition">
          {{ watchingId !== null ? '⏹ Stop Live Track' : '📡 Live Volgen' }}
        </button>
        <button class="btn-geo" @click="jumpToPreset('lodijke')">
          🌊 Lodijke (1530)
        </button>
        <button class="btn-geo" @click="jumpToPreset('scherpenisse')">
          🏛️ Scherpenisse E 1552
        </button>
      </div>
    </div>

    <!-- FOUTMELDING OF STATUS MELDING -->
    <div v-if="geoError" class="geo-alert error">
      <strong>Geolocation API Melding:</strong> {{ geoError }}
    </div>
    <div v-else-if="geoStatus" class="geo-alert info">
      {{ geoStatus }}
    </div>

    <!-- KAART & TELEMETRIE GRID -->
    <div class="geo-workspace">
      <!-- Interactief RD & Kadastraal Canvas -->
      <div class="map-canvas-panel">
        <svg viewBox="0 0 600 340" class="rd-svg" preserveAspectRatio="xMidYMid meet">
          <defs>
            <pattern id="rdGridLines" width="30" height="30" patternUnits="userSpaceOnUse">
              <path d="M 30 0 L 0 0 0 30" fill="none" stroke="#fed7d7" stroke-width="0.7" />
            </pattern>
          </defs>
          <rect width="600" height="340" fill="#fffaf9" />
          <rect width="600" height="340" fill="url(#rdGridLines)" />

          <!-- Oosterschelde / Verdronken Land Contour -->
          <polygon
            points="70,60 510,45 545,270 95,295"
            fill="rgba(163, 28, 28, 0.07)"
            stroke="#a31c1c"
            stroke-width="2"
            stroke-dasharray="5,3"
          />

          <!-- Geselecteerde Perceel / GPS Positie Marker -->
          <g :transform="`translate(300, 170)`">
            <circle r="38" fill="rgba(163, 28, 28, 0.12)" stroke="#a31c1c" stroke-width="1" />
            <circle r="7" fill="#a31c1c" />
            <text x="14" y="-8" fill="#801b1b" font-size="12" font-weight="bold">
              {{ activeLocation.label }}
            </text>
            <text x="14" y="10" fill="#475569" font-size="11" font-family="monospace">
              RD X: {{ activeLocation.rdX }} | RD Y: {{ activeLocation.rdY }}
            </text>
            <text x="14" y="25" fill="#64748b" font-size="10" font-family="monospace">
              WGS84: {{ activeLocation.lat }}° N, {{ activeLocation.lon }}° E (±{{ activeLocation.accuracy }}m)
            </text>
          </g>
        </svg>

        <div class="map-footer-bar">
          <span><strong>CRS:</strong> EPSG:28992 (Amersfoort / RD New) &harr; EPSG:4326 (WGS84)</span>
          <a
            :href="`https://www.openstreetmap.org/?mlat=${activeLocation.lat}&mlon=${activeLocation.lon}#map=16/${activeLocation.lat}/${activeLocation.lon}`"
            target="_blank"
            rel="noopener"
            class="osm-link"
          >
            Open positie in OpenStreetMap ↗
          </a>
        </div>
      </div>

      <!-- PDOK Locatieserver & Axum GraphQL GeoJSON Zijpaneel -->
      <aside class="geo-telemetry-panel">
        <div class="panel-box">
          <h5>1. PDOK Locatieserver API v3.1 Zoeken</h5>
          <div class="pdok-search-row">
            <input
              v-model="pdokQuery"
              @keyup.enter="searchPdokApi"
              placeholder="Zoek perceel of adres (bijv. Scherpenisse)..."
            />
            <button @click="searchPdokApi">Zoek</button>
          </div>
          <ul class="pdok-list" v-if="pdokResults.length">
            <li v-for="item in pdokResults" :key="item.id" @click="selectPdokItem(item)">
              <strong>{{ item.weergavenaam }}</strong>
              <small>{{ item.type }} — {{ item.centroide_rd || 'RD gekoppeld' }}</small>
            </li>
          </ul>
        </div>

        <div class="panel-box">
          <h5>2. Gekoppelde Percelen uit Axum GraphQL API (<code>:8082</code>)</h5>
          <div v-for="p in graphqlParcels" :key="p.id" class="parcel-card" @click="selectGraphqlParcel(p)">
            <div class="parcel-head">
              <span class="parcel-id">{{ p.id }}</span>
              <span class="parcel-area">{{ Number(p.oppervlakteM2).toLocaleString('nl-NL') }} m²</span>
            </div>
            <div class="parcel-name">{{ p.naam }}</div>
            <div class="parcel-rd">RD: {{ p.rdX }} , {{ p.rdY }}</div>
          </div>
        </div>
      </aside>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, onBeforeUnmount } from 'vue';
import Modernizr, { wgs84ToRd, rdToWgs84 } from '../utils/modernizr.js';

const features = reactive({
  geolocation: Modernizr.geolocation,
  securecontext: Modernizr.securecontext,
  history: Modernizr.history,
  draganddrop: Modernizr.draganddrop
});

const locating = ref(false);
const watchingId = ref(null);
const geoError = ref('');
const geoStatus = ref('Modernizr Geolocation API gereed. Klik op "Mijn GPS Positie" of kies een Zeeuws perceel.');

const activeLocation = reactive({
  label: 'Verdronken Stad Lodijke (Reimerswaal)',
  lat: 51.466210,
  lon: 4.132450,
  rdX: 68450.0,
  rdY: 387210.0,
  accuracy: 5
});

const pdokQuery = ref('Platteweg Scherpenisse');
const pdokResults = ref([]);
const graphqlParcels = ref([]);

const PRESETS = {
  lodijke: {
    label: 'Verdronken Land van Lodijke (Oorkonde 1421/1530)',
    rdX: 68450.0,
    rdY: 387210.0,
    accuracy: 3
  },
  scherpenisse: {
    label: 'Scherpenisse Platteweg 3-7 (Sectie E 1552/1551)',
    rdX: 64210.0,
    rdY: 395410.0,
    accuracy: 1
  }
};

function jumpToPreset(key) {
  const p = PRESETS[key];
  if (!p) return;
  const wgs = rdToWgs84(p.rdX, p.rdY);
  activeLocation.label = p.label;
  activeLocation.rdX = p.rdX;
  activeLocation.rdY = p.rdY;
  activeLocation.lat = wgs.lat;
  activeLocation.lon = wgs.lon;
  activeLocation.accuracy = p.accuracy;
  geoError.value = '';
  geoStatus.value = `Positie ingesteld op ${p.label} (RD ${p.rdX}, ${p.rdY}).`;
}

/**
 * Gebruik Modernizr.geolocation om veilig de HTML5 Geolocation API aan te spreken
 */
function locateUserViaModernizr() {
  geoError.value = '';
  if (!Modernizr.geolocation) {
    geoError.value = 'Modernizr heeft gedetecteerd dat deze browser geen HTML5 Geolocation API ondersteunt (class: no-geolocation).';
    return;
  }

  locating.value = true;
  geoStatus.value = 'Modernizr.geolocation === true -> Positie opvragen bij apparaat...';

  navigator.geolocation.getCurrentPosition(
    (pos) => {
      locating.value = false;
      applyGeolocationCoords(pos, 'Live GPS Positie (HTML5 Geolocation API)');
    },
    (err) => {
      locating.value = false;
      const codes = {
        1: 'Toestemming geweigerd door gebruiker (PERMISSION_DENIED).',
        2: 'Positie niet beschikbaar (POSITION_UNAVAILABLE).',
        3: 'Time-out bij het opvragen van GPS-signaal (TIMEOUT).'
      };
      geoError.value = `${codes[err.code] || err.message} — Teruggevallen op RD-ankerpunt Lodijke.`;
    },
    {
      enableHighAccuracy: true,
      timeout: 10000,
      maximumAge: 0
    }
  );
}

function toggleWatchPosition() {
  if (!Modernizr.geolocation) {
    geoError.value = 'Geolocation API niet ondersteund volgens Modernizr.';
    return;
  }
  if (watchingId.value !== null) {
    navigator.geolocation.clearWatch(watchingId.value);
    watchingId.value = null;
    geoStatus.value = 'Live GPS-tracking gestopt.';
    return;
  }
  watchingId.value = navigator.geolocation.watchPosition(
    (pos) => applyGeolocationCoords(pos, 'Live GPS Tracking Actief'),
    (err) => { geoError.value = `WatchPosition fout: ${err.message}`; },
    { enableHighAccuracy: true, maximumAge: 5000 }
  );
}

function applyGeolocationCoords(pos, labelPrefix) {
  const lat = Number(pos.coords.latitude.toFixed(6));
  const lon = Number(pos.coords.longitude.toFixed(6));
  const acc = Math.round(pos.coords.accuracy || 10);
  const rd = wgs84ToRd(lat, lon);

  activeLocation.label = labelPrefix;
  activeLocation.lat = lat;
  activeLocation.lon = lon;
  activeLocation.rdX = rd.rdX;
  activeLocation.rdY = rd.rdY;
  activeLocation.accuracy = acc;
  geoStatus.value = `GPS ontvangen via Modernizr.geolocation: ${lat}°N, ${lon}°E -> RD (${rd.rdX}, ${rd.rdY})`;
}

/**
 * Koppel PDOK Locatieserver API v3.1 (via directe HTTPS of lokale Vite proxy)
 */
async function searchPdokApi() {
  if (!pdokQuery.value.trim()) return;
  try {
    const q = encodeURIComponent(pdokQuery.value.trim());
    const url = `https://api.pdok.nl/bzk/locatieserver/search/v3_1/free?q=${q}&rows=5`;
    const res = await fetch(url, { headers: { Accept: 'application/json' } });
    const data = await res.json();
    pdokResults.value = data?.response?.docs || [];
  } catch (e) {
    geoError.value = `PDOK API melding: ${e.message}`;
  }
}

function selectPdokItem(item) {
  activeLocation.label = item.weergavenaam;
  if (item.centroide_rd) {
    const m = item.centroide_rd.match(/POINT\(([\d.]+)\s+([\d.]+)\)/);
    if (m) {
      activeLocation.rdX = Number(parseFloat(m[1]).toFixed(2));
      activeLocation.rdY = Number(parseFloat(m[2]).toFixed(2));
    }
  }
  if (item.centroide_ll) {
    const m = item.centroide_ll.match(/POINT\(([\d.]+)\s+([\d.]+)\)/);
    if (m) {
      activeLocation.lon = Number(parseFloat(m[1]).toFixed(6));
      activeLocation.lat = Number(parseFloat(m[2]).toFixed(6));
    }
  }
  geoStatus.value = `PDOK Perceel geselecteerd: ${item.weergavenaam}`;
}

/**
 * Haal GeoJSON Percelen op uit de gekoppelde Axum GraphQL API (:8082 / Vercel)
 */
async function fetchGraphqlParcels() {
  try {
    const res = await fetch('/api/graphql', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        query: `query { geojsonParcels { id naam rdX rdY oppervlakteM2 } }`
      })
    });
    const json = await res.json();
    if (json?.data?.geojsonParcels) {
      graphqlParcels.value = json.data.geojsonParcels;
    }
  } catch (_) {
    graphqlParcels.value = [
      { id: 'LOD-1421-01', naam: 'Verdronken Stad Lodijke (Reimerswaal)', rdX: 68450.0, rdY: 387210.0, oppervlakteM2: 14520.5 },
      { id: 'SCH-E-1552', naam: 'Scherpenisse Platteweg 3-7 (Sectie E 1552)', rdX: 64210.0, rdY: 395410.0, oppervlakteM2: 4120.0 }
    ];
  }
}

function selectGraphqlParcel(p) {
  const wgs = rdToWgs84(p.rdX, p.rdY);
  activeLocation.label = `${p.id} — ${p.naam}`;
  activeLocation.rdX = p.rdX;
  activeLocation.rdY = p.rdY;
  activeLocation.lat = wgs.lat;
  activeLocation.lon = wgs.lon;
  geoStatus.value = `GraphQL Perceel geladen: ${p.naam}`;
}

onMounted(() => {
  fetchGraphqlParcels();
  searchPdokApi();
});

onBeforeUnmount(() => {
  if (watchingId.value !== null && Modernizr.geolocation) {
    navigator.geolocation.clearWatch(watchingId.value);
  }
});
</script>

<style scoped>
.kaarten-viewport { display: flex; flex-direction: column; height: 100%; background: #ffffff; color: #1e293b; }
.geo-topbar { display: flex; flex-wrap: wrap; justify-content: space-between; align-items: center; gap: 0.5rem; padding: 0.55rem 0.85rem; background: #fff5f5; border-bottom: 1px solid #fed7d7; }
.modernizr-pills { display: flex; flex-wrap: wrap; gap: 0.35rem; }
.mod-pill { font-size: 0.7rem; font-weight: 800; padding: 0.2rem 0.5rem; border-radius: 4px; font-family: monospace; }
.mod-pill.ok { background: #def7ec; color: #03543f; border: 1px solid #84e1bc; }
.mod-pill.warn { background: #fef3c7; color: #92400e; border: 1px solid #fcd34d; }
.mod-pill.err { background: #fde8e8; color: #9b1c1c; border: 1px solid #f8b4b4; }
.geo-actions { display: flex; flex-wrap: wrap; gap: 0.35rem; }
.btn-geo { background: #ffffff; color: #a31c1c; border: 1px solid #feb2b2; padding: 0.35rem 0.65rem; border-radius: 6px; font-size: 0.76rem; font-weight: 700; cursor: pointer; }
.btn-geo.primary { background: #a31c1c; color: #ffffff; border-color: #a31c1c; }
.geo-alert { padding: 0.4rem 0.85rem; font-size: 0.78rem; font-weight: 600; border-bottom: 1px solid #e2e8f0; }
.geo-alert.info { background: #f8fafc; color: #334155; }
.geo-alert.error { background: #fff5f5; color: #c53030; }
.geo-workspace { flex: 1; display: grid; grid-template-columns: 1.35fr 0.85fr; min-height: 0; overflow: hidden; }
.map-canvas-panel { display: flex; flex-direction: column; border-right: 1px solid #e2e8f0; min-height: 0; }
.rd-svg { flex: 1; width: 100%; min-height: 220px; }
.map-footer-bar { display: flex; justify-content: space-between; align-items: center; padding: 0.4rem 0.75rem; background: #f8fafc; border-top: 1px solid #e2e8f0; font-size: 0.74rem; color: #475569; flex-wrap: wrap; gap: 0.4rem; }
.osm-link { color: #a31c1c; font-weight: 700; text-decoration: none; }
.geo-telemetry-panel { display: flex; flex-direction: column; gap: 0.75rem; padding: 0.75rem; overflow-y: auto; background: #fcfcfc; }
.panel-box { border: 1px solid #e2e8f0; border-radius: 6px; padding: 0.65rem; background: #ffffff; }
.panel-box h5 { margin: 0 0 0.5rem; font-size: 0.78rem; color: #a31c1c; text-transform: uppercase; }
.pdok-search-row { display: flex; gap: 0.35rem; margin-bottom: 0.5rem; }
.pdok-search-row input { flex: 1; padding: 0.35rem 0.5rem; border: 1px solid #cbd5e1; border-radius: 4px; font-size: 0.8rem; }
.pdok-search-row button { background: #a31c1c; color: #fff; border: none; border-radius: 4px; padding: 0.35rem 0.65rem; font-size: 0.78rem; font-weight: 700; cursor: pointer; }
.pdok-list { list-style: none; padding: 0; margin: 0; display: flex; flex-direction: column; gap: 0.3rem; }
.pdok-list li { padding: 0.4rem 0.5rem; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 4px; cursor: pointer; display: flex; flex-direction: column; font-size: 0.78rem; }
.pdok-list li:hover { border-color: #a31c1c; background: #fff5f5; }
.parcel-card { padding: 0.5rem; border: 1px solid #fed7d7; border-left: 3px solid #a31c1c; border-radius: 4px; margin-bottom: 0.4rem; cursor: pointer; background: #fffafa; }
.parcel-head { display: flex; justify-content: space-between; font-size: 0.74rem; font-weight: 800; color: #a31c1c; }
.parcel-name { font-size: 0.8rem; font-weight: 700; margin: 0.15rem 0; }
.parcel-rd { font-size: 0.72rem; color: #64748b; font-family: monospace; }
@media (max-width: 860px) { .geo-workspace { grid-template-columns: 1fr; overflow-y: auto; } }
</style>
