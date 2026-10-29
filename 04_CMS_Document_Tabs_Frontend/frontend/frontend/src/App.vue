<template>
  <div class="cockpit">
    <header class="top-bar">
      <div class="brand">
        <span class="badge">GEOPARK SCHELDE DELTA</span>
        <h1>LODIJKE // REIMERSWAAL PORTAAL</h1>
      </div>
      <nav class="tabs">
        <button :class="{ active: activeTab === 'tab01' }" @click="activeTab = 'tab01'">
          [TAB 01] GRAMPS & WOO DOSSIERS
        </button>
        <button :class="{ active: activeTab === 'tab06' }" @click="activeTab = 'tab06'">
          [TAB 06] INTERACTIVE LEAFLET GIS (PERCEEL 369)
        </button>
      </nav>
      <div class="status">
        API :8082 <span :class="['dot', apiOnline ? 'online' : 'offline']"></span>
      </div>
    </header>

    <main class="content">
      <!-- TAB 06: LEAFLET GIS KAART -->
      <section v-if="activeTab === 'tab06'" class="gis-layout">
        <div class="sidebar">
          <h3>GEODETISCHE LAGEN (RD / WGS84)</h3>
          <div class="layer-toggles">
            <label><input type="checkbox" v-model="layers.perceel369" @change="renderLayers" /> Oesterperceel No. 369 (12,5 ha)</label>
            <label><input type="checkbox" v-model="layers.molenplaat" @change="renderLayers" /> Molenplaat Visserij (150 ha)</label>
            <label><input type="checkbox" v-model="layers.verdronken" @change="renderLayers" /> Kasteel Lodijke & Reimerswaal</label>
          </div>

          <hr />
          <h3>ACTIEVE OBJECTEN</h3>
          <div v-for="p in geoParcels" :key="p.parcelId" class="parcel-card" @click="focusParcel(p)">
            <div class="parcel-header">
              <strong>{{ p.naam }}</strong>
              <span class="tag">{{ p.wooReferentie }}</span>
            </div>
            <div class="coords">
              RD X:{{ p.rdX }} Y:{{ p.rdY }} | {{ p.napDiepteM.toFixed(2) }}m NAP | {{ p.oppervlakteHa }} ha
            </div>
          </div>
        </div>

        <div id="map-container" ref="mapContainer"></div>
      </section>

      <!-- TAB 01: GRAMPS & WOO OVERZICHT -->
      <section v-if="activeTab === 'tab01'" class="data-layout">
        <div class="panel">
          <h2>GRAMPS Core Genealogie (GraphQL :8082)</h2>
          <div v-for="person in grampsCore" :key="person.grampsId" class="record-box">
            <h4>[{{ person.grampsId }}] {{ person.naam }}</h4>
            <p><strong>Status:</strong> {{ person.beroepStatus }}</p>
            <p><strong>Reimerswaal Verbinding:</strong> {{ person.relatieReimerswaal }}</p>
            <small>Relaties: {{ person.familieRelaties.join(', ') }}</small>
          </div>
        </div>
        <div class="panel">
          <h2>Woo-Documenten & Archiefstukken</h2>
          <div v-for="doc in cmsRecords" :key="doc.id" class="record-box">
            <h4>[{{ doc.code }}] {{ doc.titel }}</h4>
            <p>Datum: {{ doc.datum }} | Categorie: {{ doc.categorie }}</p>
            <span class="status-pill">{{ doc.status }}</span>
          </div>
        </div>
      </section>
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted, watch, nextTick } from 'vue'
import L from 'leaflet'

const activeTab = ref('tab06')
const apiOnline = ref(false)
const mapContainer = ref(null)
let mapInstance = null
let layerGroup = null

const layers = ref({
  perceel369: true,
  molenplaat: true,
  verdronken: true
})

// Fallback data zodat Vercel en offline modus altijd direct werken
const geoParcels = ref([
  {
    parcelId: 'PERCEEL-369',
    naam: 'Oesterperceel No. 369 (Bol van Lodijke)',
    gebied: 'Oosterschelde / Verdronken Land van Reimerswaal',
    oppervlakteHa: 12.5,
    rdX: 68120,
    rdY: 388050,
    lat: 51.4772,
    lng: 4.1315,
    napDiepteM: -1.80,
    wooReferentie: 'WOO-2026-369',
    geojsonPolygon: '{"type":"Polygon","coordinates":[[[4.1280,51.4755],[4.1350,51.4755],[4.1350,51.4790],[4.1280,51.4790],[4.1280,51.4755]]]}'
  },
  {
    parcelId: 'ARC-LOD-01',
    naam: 'Kasteel Lodijke & Verdronken Dorp Lodijke',
    gebied: 'Geopark Schelde Delta / Reimerswaal',
    oppervlakteHa: 4.2,
    rdX: 68450,
    rdY: 387600,
    lat: 51.4731,
    lng: 4.1362,
    napDiepteM: -3.20,
    wooReferentie: 'ARC-LOD-01',
    geojsonPolygon: '{"type":"Point","coordinates":[4.1362,51.4731]}'
  },
  {
    parcelId: 'MOLENPLAAT-150',
    naam: 'Visserijpercelen Molenplaat (150 ha)',
    gebied: 'Bergse Diepsluis / Oosterschelde Kom',
    oppervlakteHa: 150.0,
    rdX: 72500,
    rdY: 390200,
    lat: 51.4965,
    lng: 4.1945,
    napDiepteM: -2.10,
    wooReferentie: 'WOO-MOL-150',
    geojsonPolygon: '{"type":"Polygon","coordinates":[[[4.1820,51.4910],[4.2070,51.4910],[4.2070,51.5020],[4.1820,51.5020],[4.1820,51.4910]]]}'
  },
  {
    parcelId: 'STAD-REIMERSWAAL',
    naam: 'Verdronken Stad Reimerswaal (Rijksmonument)',
    gebied: 'Verdronken Land van Zuid-Beveland',
    oppervlakteHa: 45.0,
    rdX: 70200,
    rdY: 389100,
    lat: 51.4866,
    lng: 4.1614,
    napDiepteM: -1.50,
    wooReferentie: 'WOO-REI-1530',
    geojsonPolygon: '{"type":"Point","coordinates":[4.1614,51.4866]}'
  }
])

const grampsCore = ref([
  {
    grampsId: 'I0103',
    naam: 'W. Bout',
    beroepStatus: 'Rechthebbende / Erfgenaam Stamreeks',
    relatieReimerswaal: 'Directe lijn erfopvolging en historische visrechten Verdronken Land van Reimerswaal',
    familieRelaties: ['F0042 (Gezin Guiljam-Bout)', 'I0104 (M.J.M.M. Goijarts-Bout)']
  }
])

const cmsRecords = ref([
  {
    id: '1',
    code: 'WOO-2026-369',
    titel: 'Oesterperceel No. 369 - Bol van Lodijke & Oudelandse Visrechten',
    datum: '2026-10-15',
    categorie: 'Visserij & Erfgoed',
    status: 'Gevalideerd (Belanghebbende)'
  }
])

async function fetchGraphQL() {
  const query = `
    query {
      cmsRecords { id code titel datum categorie status }
      grampsCore { grampsId naam beroepStatus relatieReimerswaal familieRelaties }
      geoParcels { parcelId naam gebied oppervlakteHa rdX rdY lat lng napDiepteM wooReferentie geojsonPolygon }
    }
  `
  try {
    const res = await fetch('http://localhost:8082/graphql', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ query })
    })
    const json = await res.json()
    if (json.data) {
      cmsRecords.value = json.data.cmsRecords
      grampsCore.value = json.data.grampsCore
      geoParcels.value = json.data.geoParcels
      apiOnline.value = true
      renderLayers()
    }
  } catch (e) {
    apiOnline.value = false
  }
}

function initMap() {
  if (!mapContainer.value) return
  if (mapInstance) {
    mapInstance.remove()
  }
  mapInstance = L.map(mapContainer.value).setView([51.4840, 4.1600], 13)
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; OpenStreetMap | PDOK RD Referentie | Geopark Schelde Delta'
  }).addTo(mapInstance)

  layerGroup = L.layerGroup().addTo(mapInstance)
  renderLayers()
}

function renderLayers() {
  if (!layerGroup) return
  layerGroup.clearLayers()

  geoParcels.value.forEach((p) => {
    if (p.parcelId === 'PERCEEL-369' && !layers.value.perceel369) return
    if (p.parcelId === 'MOLENPLAAT-150' && !layers.value.molenplaat) return
    if ((p.parcelId === 'ARC-LOD-01' || p.parcelId === 'STAD-REIMERSWAAL') && !layers.value.verdronken) return

    const popupHtml = `
      <div style="font-family: monospace; color: #0f172a; min-width: 240px;">
        <h4 style="margin:0 0 6px 0; border-bottom: 1px solid #cbd5e1; padding-bottom:4px;">${p.naam}</h4>
        <p style="margin:3px 0;"><b>Gebied:</b> ${p.gebied}</p>
        <p style="margin:3px 0;"><b>Oppervlakte:</b> ${p.oppervlakteHa} ha</p>
        <p style="margin:3px 0;"><b>RD-Coördinaten:</b> X:${p.rdX} / Y:${p.rdY}</p>
        <p style="margin:3px 0;"><b>Diepte:</b> ${p.napDiepteM.toFixed(2)}m NAP</p>
        <p style="margin:6px 0 0 0; background:#e2e8f0; padding:4px; border-radius:4px;">
          📄 <b>Woo-Dossier:</b> <a href="#${p.wooReferentie}">${p.wooReferentie}</a> (I0103 / W. Bout)
        </p>
      </div>
    `

    try {
      const geo = JSON.parse(p.geojsonPolygon)
      if (geo.type === 'Polygon') {
        const latlngs = geo.coordinates[0].map(c => [c[1], c[0]])
        const color = p.parcelId === 'PERCEEL-369' ? '#10b981' : '#3b82f6'
        L.polygon(latlngs, { color, weight: 2, fillOpacity: 0.35 })
          .bindPopup(popupHtml)
          .addTo(layerGroup)
      } else {
        L.circleMarker([p.lat, p.lng], {
          radius: 9,
          fillColor: '#f59e0b',
          color: '#ffffff',
          weight: 2,
          fillOpacity: 0.9
        })
          .bindPopup(popupHtml)
          .addTo(layerGroup)
      }
    } catch (err) {
      console.error(err)
    }
  })
}

function focusParcel(p) {
  if (!mapInstance) return
  mapInstance.flyTo([p.lat, p.lng], 15, { duration: 0.8 })
}

watch(activeTab, async (val) => {
  if (val === 'tab06') {
    await nextTick()
    initMap()
  }
})

onMounted(() => {
  initMap()
  fetchGraphQL()
})
</script>

<style scoped>
.cockpit { display: flex; flex-direction: column; height: 100vh; }
.top-bar { display: flex; justify-content: space-between; align-items: center; background: #1e293b; padding: 10px 20px; border-bottom: 1px solid #334155; }
.brand h1 { margin: 0; font-size: 1.1rem; color: #38bdf8; }
.badge { font-size: 0.7rem; background: #0284c7; padding: 2px 6px; border-radius: 3px; }
.tabs button { background: #0f172a; color: #94a3b8; border: 1px solid #334155; padding: 8px 14px; margin-right: 8px; cursor: pointer; font-family: inherit; }
.tabs button.active { background: #0284c7; color: #fff; border-color: #38bdf8; }
.status { font-size: 0.85rem; display: flex; align-items: center; gap: 6px; }
.dot { width: 10px; height: 10px; border-radius: 50%; display: inline-block; }
.dot.online { background: #10b981; box-shadow: 0 0 8px #10b981; }
.dot.offline { background: #f59e0b; }
.content { flex: 1; overflow: hidden; }
.gis-layout { display: grid; grid-template-columns: 360px 1fr; height: 100%; }
.sidebar { background: #0f172a; padding: 16px; border-right: 1px solid #334155; overflow-y: auto; }
.layer-toggles label { display: block; margin-bottom: 8px; font-size: 0.85rem; cursor: pointer; }
.parcel-card { background: #1e293b; border: 1px solid #334155; padding: 10px; margin-bottom: 10px; border-radius: 4px; cursor: pointer; transition: border 0.2s; }
.parcel-card:hover { border-color: #38bdf8; }
.parcel-header { display: flex; justify-content: space-between; font-size: 0.85rem; margin-bottom: 4px; }
.tag { background: #065f46; color: #6ee7b7; padding: 1px 6px; border-radius: 3px; font-size: 0.75rem; }
.coords { font-size: 0.75rem; color: #94a3b8; }
#map-container { width: 100%; height: 100%; }
.data-layout { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; padding: 20px; height: 100%; overflow-y: auto; }
.panel { background: #1e293b; padding: 16px; border-radius: 6px; border: 1px solid #334155; }
.record-box { background: #0f172a; padding: 12px; margin-bottom: 12px; border-left: 3px solid #38bdf8; }
.status-pill { font-size: 0.75rem; background: #1e3a8a; color: #93c5fd; padding: 2px 8px; border-radius: 4px; }
</style>
