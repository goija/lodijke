<template>
  <div class="platform-wrapper">
    <!-- BORDEAUXRODE TOP NAVIGATIEBALK MET ALLE WERKENDE KOPPELINGEN -->
    <header class="navbar">
      <div class="nav-container">
        <a href="#home" class="brand" @click.prevent="navigateTo('home')">
          🏛️ <span>Lodijke Master Platform</span>
        </a>
        <nav class="nav-links">
          <button :class="['nav-btn', activeSection === 'home' ? 'active-pill' : '']" @click="navigateTo('home')">
            ⚓ Visserij Dossier (Home)
          </button>
          <button :class="['nav-btn', activeSection === 'architectuur' ? 'active-pill' : '']" @click="navigateTo('architectuur')">
            Systeemarchitectuur
          </button>
          <button :class="['nav-btn', activeSection === 'gis' ? 'active-pill' : '']" @click="navigateTo('gis')">
            Perceel 369 (GIS)
          </button>
          <button :class="['nav-btn', activeSection === 'woosporen' ? 'active-pill' : '']" @click="navigateTo('woosporen')">
            Woo Sporen (A-F)
          </button>
          <button :class="['nav-btn', activeSection === 'mappenboom' ? 'active-pill' : '']" @click="navigateTo('mappenboom')">
            Mappenboom
          </button>
          <a href="https://github.com/goija/geocentrum" target="_blank" rel="noopener noreferrer" class="nav-btn ext-link">
            GitHub Repository ↗
          </a>
        </nav>
      </div>
    </header>

    <!-- HERO BANNER -->
    <section id="home" class="hero-banner">
      <h1>Zeeuws Visserij Dossier &amp; Lodijke Archiefbeheer</h1>
      <button class="hero-cta" @click="navigateTo('woosporen')">
        Bekijk de 6 Woo-Sporen
      </button>
    </section>

    <!-- MAIN CONTENT CONTAINER -->
    <main class="main-container">

      <!-- SECTIE 1: GEODETISCHE KAARTWEERGAVE & PERCEEL NO. 369 -->
      <section id="gis" class="card-section">
        <h2 class="section-title">📍 Geodetische Kaartweergave &amp; Perceel No. 369</h2>
        <p class="section-subtitle">
          Oesterperceel No. 369 op de Bol van Lodijke (12,5 ha, RD X=68120 Y=388050) van Reder Benjamin Willem Schot (1840–1925).
        </p>

        <!-- KAARTLAAG SCHAKELAARS -->
        <div class="map-toolbar">
          <div class="layer-group">
            <strong>Basiskaart:</strong>
            <button :class="{ active: baseMode === 'osm' }" @click="setBaseLayer('osm')">OpenStreetMap</button>
            <button :class="{ active: baseMode === 'ortho' }" @click="setBaseLayer('ortho')">PDOK Luchtfoto (25cm)</button>
            <button :class="{ active: baseMode === 'dark' }" @click="setBaseLayer('dark')">Maritiem Donker</button>
          </div>
          <div class="layer-group">
            <strong>Overlays:</strong>
            <label><input type="checkbox" v-model="overlays.kadaster" @change="syncOverlays" /> PDOK Kadastrale Kaart v5</label>
            <label><input type="checkbox" v-model="overlays.bathymetrie" @change="syncOverlays" /> RWS Vaklodingen (-NAP)</label>
            <label><input type="checkbox" v-model="overlays.molenplaat" @change="syncOverlays" /> Molenplaat (150 ha)</label>
          </div>
          <div class="layer-group">
            <button class="recenter-btn" @click="focusPerceel369">🎯 Centreer Perceel 369</button>
          </div>
        </div>

        <!-- DE INTERACTIEVE LEAFLET KAART CONTAINER -->
        <div class="map-frame">
          <div id="lodijke-leaflet-map" ref="mapEl"></div>

          <!-- GEODETISCHE TELEMETRIE OVERLAY LINKSONDER (ZOALS IN SCREENSHOT) -->
          <div class="telemetry-overlay">
            <div>
              <strong>Coördinaten:</strong> RD EPSG:28992 (X:{{ cursorRd.x }}, Y:{{ cursorRd.y }}) |
              WGS84: {{ cursorWgs.lat }}°N, {{ cursorWgs.lng }}°E
            </div>
            <div>
              <strong>Diepte:</strong> -2.10m NAP (Bol van Lodijke) | Kasteel Lodijke (ARC-LOD-01): -3.20m NAP
            </div>
          </div>
        </div>
      </section>

      <!-- SECTIE 2: DE 6 WOO-SPOREN (A t/m F) -->
      <section id="woosporen" class="card-section">
        <h2 class="section-title">📂 De 6 Woo-Sporen (A t/m F) — Dossier &amp; Bewijsvoering</h2>
        <p class="section-subtitle">
          Klik op een spoor om de bijbehorende archiefstukken, kadastrale leggers en GraphQL-records (:8082) in te zien of op de kaart te lokaliseren.
        </p>
        <div class="grid-3">
          <div v-for="spoor in wooSporen" :key="spoor.code" class="spoor-card">
            <div class="spoor-header">
              <span class="spoor-badge">{{ spoor.code }}</span>
              <span class="spoor-status">{{ spoor.status }}</span>
            </div>
            <h3>{{ spoor.titel }}</h3>
            <p>{{ spoor.beschrijving }}</p>
            <div class="spoor-footer">
              <button class="link-btn" @click="zoomToSpoor(spoor)">📍 Toon op GIS-kaart</button>
              <a :href="spoor.archiefLink" class="link-btn secondary">📄 Open Dossier ({{ spoor.ref }})</a>
            </div>
          </div>
        </div>
      </section>

      <!-- SECTIE 3: SYSTEEMARCHITECTUUR (:8082 AXUM & :5173 VUE 3) -->
      <section id="architectuur" class="card-section">
        <h2 class="section-title">⚙️ Systeemarchitectuur &amp; GraphQL Koppeling</h2>
        <div class="grid-2">
          <div class="arch-box">
            <h3>Rust Axum GraphQL API (:8082)</h3>
            <p>Status: <strong :style="{ color: apiOnline ? '#16a34a' : '#d97706' }">{{ apiOnline ? 'ONLINE (Verbonden)' : 'FALLBACK MODUS (Snapshot geladen)' }}</strong></p>
            <ul>
              <li><code>grampsCore(grampsId: "I0103")</code> — Stamreeks W. Bout &amp; Guiljam</li>
              <li><code>geoParcels</code> — Oesterperceel No. 369 (12,5 ha), Kasteel Lodijke (-3,20m NAP), Molenplaat (150 ha)</li>
              <li><code>cmsRecords</code> — Gevalideerde Woo-besluiten en belanghebbende-dossiers</li>
            </ul>
            <a href="http://localhost:8082/graphql" target="_blank" class="link-btn">Open GraphiQL Playground (:8082) ↗</a>
          </div>
          <div class="arch-box">
            <h3>Geodetische Projectie &amp; Kadastrale Lagen</h3>
            <ul>
              <li><strong>Rijksdriehoeksstelsel (EPSG:28992):</strong> Ankerpunt Bol van Lodijke X=68120, Y=388050</li>
              <li><strong>Oesterperceel No. 369:</strong> Rederij B.W. Schot (1840–1925), 11x "Oesterputten", t.v.v. Yerseke</li>
              <li><strong>WMS Koppelingen:</strong> PDOK Kadastrale Kaart v5, PDOK Ortho 25cm &amp; RWS Vaklodingen</li>
            </ul>
          </div>
        </div>
      </section>

      <!-- SECTIE 4: MAPPENBOOM -->
      <section id="mappenboom" class="card-section">
        <h2 class="section-title">🌲 Mappenboom &amp; Dossierstructuur</h2>
        <pre class="tree-view">
📦 lodijke-master-platform/
 ┣ 📂 backend/ (Rust Axum GraphQL Server :8082)
 ┃ ┣ 📜 Cargo.toml
 ┃ ┗ 📜 src/main.rs (Resolvers: cmsRecords, grampsCore I0103, geoParcels Perceel 369)
 ┣ 📂 frontend/ (Vue 3 + Leaflet GIS :5173)
 ┃ ┣ 📂 public/data/lodijke_snapshot.json
 ┃ ┣ 📜 index.html (Leaflet 1.9.4 CSS + Rode Popup Styling)
 ┃ ┗ 📜 src/App.vue (Navigatie, PDOK WMS, Perceel 369 &amp; 6 Woo-Sporen)
 ┣ 📂 archief_woo_sporen/
 ┃ ┣ 📂 Spoor_A_Perceel_369_Bol_van_Lodijke/ (B.W. Schot 1840-1925, 12.5 ha)
 ┃ ┣ 📂 Spoor_B_Kasteel_Lodijke_ARC_LOD_01/ (-3.20m NAP Archeologie)
 ┃ ┣ 📂 Spoor_C_Molenplaat_150ha_Visrechten/ (Bergse Diepsluis)
 ┃ ┣ 📂 Spoor_D_GRAMPS_Stamreeks_I0103_Bout_Guiljam/
 ┃ ┣ 📂 Spoor_E_Oudelandse_Visrecht_Reimerswaal/
 ┃ ┗ 📂 Spoor_F_Bestuursrecht_Belanghebbende_M_E_R/
 ┣ 📜 opstart_all.sh (1-Click Master Launcher)
 ┣ 📜 push_github.sh (Automatische Vercel Deployment -> https://lodijke.vercel.app/)
 ┗ 📜 vercel.json
        </pre>
      </section>

    </main>
  </div>
</template>

<script setup>
import { ref, onMounted, nextTick } from 'vue'
import L from 'leaflet'

const activeSection = ref('home')
const mapEl = ref(null)
const apiOnline = ref(false)
const baseMode = ref('osm')

const cursorRd = ref({ x: 68120, y: 388050 })
const cursorWgs = ref({ lat: '51.47633', lng: '4.13750' })

const overlays = ref({
  kadaster: true,
  bathymetrie: true,
  molenplaat: true
})

const wooSporen = ref([
  {
    code: 'SPOOR A',
    ref: 'WOO-369-SCHOT',
    titel: 'Oesterperceel No. 369 — Bol van Lodijke (12,5 ha)',
    status: 'Gevalideerd',
    beschrijving: 'Historische concessie en kadastrale legger van Reder Benjamin Willem Schot (1840–1925), omvattende 11 oesterputten t.v.v. Yerseke op RD X=68120, Y=388050.',
    lat: 51.47633,
    lng: 4.13750,
    zoom: 15,
    archiefLink: '#gis'
  },
  {
    code: 'SPOOR B',
    ref: 'ARC-LOD-01',
    titel: 'Kasteel Lodijke & Verdronken Dorp (-3,20m NAP)',
    status: 'Archeologisch Anker',
    beschrijving: 'Geodetische en archeologische vastlegging van de fundamenten van Kasteel Lodijke op -3,20m NAP na de Sint-Felixvloed (1530).',
    lat: 51.47310,
    lng: 4.13620,
    zoom: 15,
    archiefLink: '#gis'
  },
  {
    code: 'SPOOR C',
    ref: 'WOO-MOL-150',
    titel: 'Visserijpercelen Molenplaat (150 ha)',
    status: 'Actief Woo-Dossier',
    beschrijving: 'Percelen rondom de Molenplaat en Bergse Diepsluis (Oosterschelde Kom, -2,10m NAP) gekoppeld aan historische gebruiks- en visrechten.',
    lat: 51.49650,
    lng: 4.19450,
    zoom: 14,
    archiefLink: '#gis'
  },
  {
    code: 'SPOOR D',
    ref: 'GRAMPS-I0103',
    titel: 'Stamreeks W. Bout (I0103) & C.M. Guiljam (I0088)',
    status: 'Genealogisch Bewijs',
    beschrijving: 'Directe afstammingslijn en erfrechtelijke verankering vanuit Sint-Maartensdijk, Tholen en het Verdronken Land van Reimerswaal.',
    lat: 51.47633,
    lng: 4.13750,
    zoom: 14,
    archiefLink: '#architectuur'
  },
  {
    code: 'SPOOR E',
    ref: 'REI-VISRECHT',
    titel: 'Oudelandse Visrechten & Stad Reimerswaal',
    status: 'Historisch Recht',
    beschrijving: '14e- en 16e-eeuwse charters en visrechten binnen de grenzen van het verdronken rechtsgebied van de stad Reimerswaal (Rijksmonument).',
    lat: 51.48660,
    lng: 4.16140,
    zoom: 14,
    archiefLink: '#gis'
  },
  {
    code: 'SPOOR F',
    ref: 'AWB-MER-2026',
    titel: 'Belanghebbende Status (Awb / m.e.r. Schelde Delta)',
    status: 'Onherroepelijk',
    beschrijving: 'Formeel vastgestelde belanghebbendestatus in het kader van de Wet open overheid (Woo) en milieueffectrapportages in het Oosterscheldebekken.',
    lat: 51.47633,
    lng: 4.13750,
    zoom: 13,
    archiefLink: '#mappenboom'
  }
])

let map = null
let baseTileLayers = {}
let wmsOverlayLayers = {}
let perceel369Marker = null

function wgs84ToRd(lat, lng) {
  const dF = 0.36 * (lat - 52.15517440)
  const dL = 0.36 * (lng - 5.38720621)
  const somX =
    190094.945 * dL +
    -11832.228 * dF * dL +
    -114.221 * Math.pow(dF, 2) * dL +
    -32.391 * Math.pow(dL, 3)
  const somY =
    309056.544 * dF +
    3638.893 * Math.pow(dL, 2) +
    73.077 * Math.pow(dF, 2) +
    -157.984 * dF * Math.pow(dL, 2)
  return {
    x: Math.round(155000 + somX),
    y: Math.round(463000 + somY)
  }
}

function navigateTo(sectionId) {
  activeSection.value = sectionId
  const el = document.getElementById(sectionId)
  if (el) {
    el.scrollIntoView({ behavior: 'smooth', block: 'start' })
  }
  if (sectionId === 'gis' && map) {
    setTimeout(() => map.invalidateSize(), 250)
  }
}

function initLeafletMap() {
  if (!mapEl.value) return
  if (map) {
    map.remove()
  }

  // Ankercoördinaten uit screenshot: 51.47633°N, 4.13750°E (RD X:68120, Y:388050)
  const centerLat = 51.47633
  const centerLng = 4.13750

  map = L.map(mapEl.value, {
    center: [centerLat, centerLng],
    zoom: 14,
    zoomControl: true
  })

  // 1. Basiskaarten (OpenStreetMap, PDOK Luchtfoto, Donker Maritiem)
  baseTileLayers.osm = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    attribution: '&copy; OpenStreetMap | PDOK | Lodijke Master Platform'
  })

  baseTileLayers.ortho = L.tileLayer.wms('https://service.pdok.nl/hwh/luchtfotorgb/wms/v1_0', {
    layers: 'Actueel_orthoHR',
    format: 'image/jpeg',
    transparent: false,
    maxZoom: 19,
    attribution: 'PDOK Luchtfoto 25cm'
  })

  baseTileLayers.dark = L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
    maxZoom: 19,
    attribution: '&copy; CartoDB Dark Matter | Geopark Schelde Delta'
  })

  baseTileLayers.osm.addTo(map)

  // 2. WMS Overlays (PDOK Kadastrale Kaart v5 & RWS Vaklodingen Bathymetrie)
  wmsOverlayLayers.bathymetrie = L.tileLayer.wms('https://geo.rijkswaterstaat.nl/services/ogc/gdr/vaklodingen/ows', {
    layers: 'vaklodingen_kb131_2634',
    format: 'image/png',
    transparent: true,
    opacity: 0.55,
    attribution: 'RWS Vaklodingen (-NAP)'
  })

  wmsOverlayLayers.kadaster = L.tileLayer.wms('https://service.pdok.nl/kadaster/kadastralekaart/wms/v5_0', {
    layers: 'Kadastralekaart',
    format: 'image/png',
    transparent: true,
    opacity: 0.85,
    attribution: 'Kadaster v5'
  })

  // 3. Polygoon Oesterperceel No. 369 (12,5 ha, Bol van Lodijke)
  const perceel369Bounds = [
    [51.4745, 4.1335],
    [51.4745, 4.1415],
    [51.4782, 4.1415],
    [51.4782, 4.1335]
  ]
  L.polygon(perceel369Bounds, {
    color: '#dc2626',
    weight: 2.5,
    fillColor: '#ef4444',
    fillOpacity: 0.28
  }).addTo(map)

  // Rode pulserende cirkel + originele rode popup van Oesterperceel No. 369
  perceel369Marker = L.circleMarker([centerLat, centerLng], {
    radius: 9,
    color: '#ffffff',
    weight: 2.5,
    fillColor: '#b91c1c',
    fillOpacity: 1
  })
    .addTo(map)
    .bindPopup(
      `<div>
        <strong>Oesterperceel No. 369 (12,5 ha)</strong><br/>
        Bol van Lodijke | Reder B.W. Schot (1840–1925)<br/>
        Toegewezen: 11x "Oesterputten", t.v.v. Yerseke
      </div>`,
      { className: 'custom-red-popup', closeButton: false, autoClose: false }
    )
    .openPopup()

  // 4. Kasteel Lodijke (ARC-LOD-01 op -3.20m NAP)
  L.circleMarker([51.4731, 4.1362], {
    radius: 7,
    color: '#ffffff',
    weight: 2,
    fillColor: '#d97706',
    fillOpacity: 0.95
  })
    .addTo(map)
    .bindPopup(
      `<div>
        <strong>Kasteel Lodijke (ARC-LOD-01)</strong><br/>
        Diepte: -3,20m NAP | RD X:68450 Y:387600<br/>
        Verdronken bij de Sint-Felixvloed (5 nov 1530)
      </div>`,
      { className: 'custom-red-popup' }
    )

  // 5. Stad Reimerswaal (Rijksmonument)
  L.circleMarker([51.4866, 4.1614], {
    radius: 7,
    color: '#ffffff',
    weight: 2,
    fillColor: '#2563eb',
    fillOpacity: 0.95
  })
    .addTo(map)
    .bindPopup(
      `<div>
        <strong>Verdronken Stad Reimerswaal</strong><br/>
        Diepte: -1,50m NAP | Oudelandse Visrechten<br/>
        GRAMPS Stamreeks: I0103 (W. Bout)
      </div>`,
      { className: 'custom-red-popup' }
    )

  // 6. Molenplaat Visserijpercelen (150 ha)
  wmsOverlayLayers.molenplaat = L.polygon(
    [
      [51.4910, 4.1820],
      [51.4910, 4.2070],
      [51.5020, 4.2070],
      [51.5020, 4.1820]
    ],
    {
      color: '#0284c7',
      weight: 2,
      fillColor: '#38bdf8',
      fillOpacity: 0.25
    }
  ).bindPopup(
    `<div>
      <strong>Visserijpercelen Molenplaat (150 ha)</strong><br/>
      Diepte: -2,10m NAP | Woo-Dossier: WOO-MOL-150
    </div>`,
    { className: 'custom-red-popup' }
  )

  syncOverlays()

  // Live coördinatenbalk onderin bijwerken bij muisbeweging
  map.on('mousemove', (e) => {
    cursorWgs.value = {
      lat: e.latlng.lat.toFixed(5),
      lng: e.latlng.lng.toFixed(5)
    }
    cursorRd.value = wgs84ToRd(e.latlng.lat, e.latlng.lng)
  })

  // Forceer herberekening van kaartafmetingen zodat tegels altijd direct zichtbaar zijn
  setTimeout(() => {
    map.invalidateSize()
    perceel369Marker.openPopup()
  }, 200)
}

function setBaseLayer(mode) {
  baseMode.value = mode
  if (!map) return
  Object.values(baseTileLayers).forEach((layer) => {
    if (map.hasLayer(layer)) map.removeLayer(layer)
  })
  if (baseTileLayers[mode]) {
    baseTileLayers[mode].addTo(map)
  }
}

function syncOverlays() {
  if (!map) return
  Object.keys(overlays.value).forEach((key) => {
    const layer = wmsOverlayLayers[key]
    if (!layer) return
    if (overlays.value[key]) {
      if (!map.hasLayer(layer)) map.addLayer(layer)
    } else {
      if (map.hasLayer(layer)) map.removeLayer(layer)
    }
  })
}

function focusPerceel369() {
  if (!map) return
  map.flyTo([51.47633, 4.13750], 15, { duration: 0.8 })
  if (perceel369Marker) perceel369Marker.openPopup()
}

function zoomToSpoor(spoor) {
  navigateTo('gis')
  if (map) {
    map.flyTo([spoor.lat, spoor.lng], spoor.zoom || 15, { duration: 0.9 })
  }
}

async function checkBackendHealth() {
  try {
    const res = await fetch('http://localhost:8082/api/health')
    if (res.ok) apiOnline.value = true
  } catch (_) {
    apiOnline.value = false
  }
}

onMounted(async () => {
  await nextTick()
  initLeafletMap()
  checkBackendHealth()
})
</script>

<style scoped>
/* BORDEAUXRODE HEADER & HERO (EXACT ZOALS SCREENSHOT) */
.navbar {
  background: #7f1d1d;
  border-bottom: 1px solid #991b1b;
  color: #ffffff;
  position: sticky;
  top: 0;
  z-index: 2000;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.25);
}
.nav-container {
  max-width: 1280px;
  margin: 0 auto;
  padding: 10px 20px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
}
.brand {
  color: #ffffff;
  text-decoration: none;
  font-weight: 700;
  font-size: 1.05rem;
  display: flex;
  align-items: center;
  gap: 8px;
}
.nav-links {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}
.nav-btn {
  background: transparent;
  border: none;
  color: #fecaca;
  font-size: 0.85rem;
  padding: 7px 14px;
  border-radius: 6px;
  cursor: pointer;
  text-decoration: none;
  transition: all 0.15s ease;
  font-family: inherit;
}
.nav-btn:hover {
  background: rgba(255, 255, 255, 0.12);
  color: #ffffff;
}
.nav-btn.active-pill {
  background: #ffffff;
  color: #7f1d1d;
  font-weight: 600;
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.2);
}

.hero-banner {
  background: linear-gradient(180deg, #651212 0%, #7f1d1d 100%);
  color: #ffffff;
  text-align: center;
  padding: 44px 20px;
  border-bottom: 3px solid #991b1b;
}
.hero-banner h1 {
  margin: 0 0 18px 0;
  font-size: 2rem;
  font-weight: 700;
  letter-spacing: 0.2px;
}
.hero-cta {
  background: #ffffff;
  color: #7f1d1d;
  border: none;
  padding: 10px 22px;
  font-size: 0.88rem;
  font-weight: 700;
  border-radius: 6px;
  cursor: pointer;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.25);
  transition: transform 0.15s ease;
}
.hero-cta:hover {
  transform: translateY(-1px);
  background: #fef2f2;
}

/* MAIN CONTENT & KAART SECTIE */
.main-container {
  max-width: 1120px;
  margin: 0 auto;
  padding: 28px 20px 60px;
}
.card-section {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 24px;
  margin-bottom: 32px;
  box-shadow: 0 4px 14px rgba(15, 23, 42, 0.05);
}
.section-title {
  margin: 0 0 6px 0;
  color: #881313;
  font-size: 1.25rem;
}
.section-subtitle {
  margin: 0 0 16px 0;
  color: #475569;
  font-size: 0.9rem;
}

.map-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
  background: #f1f5f9;
  padding: 10px 14px;
  border-radius: 8px;
  margin-bottom: 12px;
  font-size: 0.82rem;
}
.layer-group {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}
.layer-group button {
  background: #ffffff;
  border: 1px solid #cbd5e1;
  padding: 5px 10px;
  border-radius: 5px;
  cursor: pointer;
  font-size: 0.78rem;
}
.layer-group button.active {
  background: #7f1d1d;
  color: #ffffff;
  border-color: #7f1d1d;
}
.recenter-btn {
  background: #881313 !important;
  color: #ffffff !important;
  font-weight: 600;
}

.map-frame {
  position: relative;
  width: 100%;
  height: 520px;
  border-radius: 8px;
  overflow: hidden;
  border: 2px solid #1e293b;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.18);
}
#lodijke-leaflet-map {
  width: 100%;
  height: 100%;
}

/* TELEMETRIE OVERLAY LINKSONDER */
.telemetry-overlay {
  position: absolute;
  bottom: 12px;
  left: 12px;
  z-index: 1000;
  background: rgba(15, 23, 42, 0.92);
  color: #f8fafc;
  padding: 8px 14px;
  border-radius: 6px;
  border-left: 3px solid #ef4444;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  font-size: 0.76rem;
  line-height: 1.5;
  pointer-events: none;
}

/* WOO SPOREN KAARTEN */
.grid-3 {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 16px;
}
.spoor-card {
  border: 1px solid #e2e8f0;
  border-top: 3px solid #7f1d1d;
  border-radius: 8px;
  padding: 16px;
  background: #fafafa;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}
.spoor-header {
  display: flex;
  justify-content: space-between;
  margin-bottom: 8px;
}
.spoor-badge {
  background: #7f1d1d;
  color: #ffffff;
  font-size: 0.72rem;
  font-weight: 700;
  padding: 2px 8px;
  border-radius: 4px;
}
.spoor-status {
  font-size: 0.72rem;
  color: #047857;
  font-weight: 600;
}
.spoor-card h3 {
  margin: 4px 0 8px 0;
  font-size: 0.98rem;
  color: #1e293b;
}
.spoor-card p {
  font-size: 0.84rem;
  color: #475569;
  line-height: 1.45;
  margin: 0 0 14px 0;
}
.spoor-footer {
  display: flex;
  gap: 8px;
}
.link-btn {
  display: inline-block;
  background: #7f1d1d;
  color: #ffffff;
  border: none;
  padding: 6px 12px;
  border-radius: 5px;
  font-size: 0.78rem;
  cursor: pointer;
  text-decoration: none;
}
.link-btn.secondary {
  background: #e2e8f0;
  color: #1e293b;
}

.grid-2 {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(380px, 1fr));
  gap: 20px;
}
.arch-box {
  background: #f8fafc;
  border: 1px solid #cbd5e1;
  padding: 16px;
  border-radius: 8px;
  font-size: 0.88rem;
}
.arch-box ul {
  padding-left: 18px;
  line-height: 1.65;
}
.tree-view {
  background: #0f172a;
  color: #38bdf8;
  padding: 18px;
  border-radius: 8px;
  font-size: 0.82rem;
  line-height: 1.6;
  overflow-x: auto;
}
</style>
