<template>
  <div class="cockpit">
    <header class="top-bar">
      <div class="brand">
        <span class="badge">GEOPARK SCHELDE DELTA // EPSG:28992</span>
        <h1>LODIJKE // REIMERSWAAL GEODETISCH PORTAAL</h1>
      </div>
      <nav class="tabs">
        <button :class="{ active: activeTab === 'tab01' }" @click="activeTab = 'tab01'">
          [TAB 01] GRAMPS & WOO DOSSIERS
        </button>
        <button :class="{ active: activeTab === 'tab06' }" @click="activeTab = 'tab06'">
          [TAB 06] LEAFLET GIS + PDOK / BATHYMETRIE
        </button>
      </nav>
      <div class="status">
        <span>CURSOR RD X:{{ cursorRd.x }} Y:{{ cursorRd.y }}</span>
        <span class="divider">|</span>
        API :8082 <span :class="['dot', apiOnline ? 'online' : 'offline']"></span>
      </div>
    </header>

    <main class="content">
      <!-- TAB 06: LEAFLET GIS KAART MET PDOK, BATHYMETRIE & EXPORT -->
      <section v-if="activeTab === 'tab06'" class="gis-layout">
        <div class="sidebar">
          <h3>PDOK & RWS RIJKSKAARTLAGEN (WMS)</h3>
          <div class="layer-toggles">
            <label>
              <input type="checkbox" v-model="wmsLayers.luchtfoto" @change="toggleWmsLayers" />
              PDOK Luchtfoto Actueel Ortho (25cm)
            </label>
            <label>
              <input type="checkbox" v-model="wmsLayers.bathymetrie" @change="toggleWmsLayers" />
              RWS Vaklodingen Bathymetrie (Diepte -NAP)
            </label>
            <label>
              <input type="checkbox" v-model="wmsLayers.kadaster" @change="toggleWmsLayers" />
              PDOK Kadastrale Kaart v5 (Perceelgrenzen)
            </label>
            <label>
              <input type="checkbox" v-model="wmsLayers.ahn" @change="toggleWmsLayers" />
              PDOK AHN4 Hoogtebestand (DSM 0.5m)
            </label>
          </div>

          <div class="opacity-control">
            <label>Transparantie Bathymetrie / AHN: {{ Math.round(wmsOpacity * 100) }}%</label>
            <input type="range" min="0.1" max="1.0" step="0.05" v-model.number="wmsOpacity" @input="updateWmsOpacity" />
          </div>

          <hr />
          <h3>VECTORLAGEN (WOO & ERFGOED)</h3>
          <div class="layer-toggles">
            <label><input type="checkbox" v-model="layers.perceel369" @change="renderLayers" /> Oesterperceel No. 369 (12,5 ha)</label>
            <label><input type="checkbox" v-model="layers.molenplaat" @change="renderLayers" /> Molenplaat Visserij (150 ha)</label>
            <label><input type="checkbox" v-model="layers.verdronken" @change="renderLayers" /> Kasteel Lodijke & Reimerswaal</label>
          </div>

          <div class="export-box">
            <h4>EXPORTEER ACTIEVE LAGEN ({{ filteredParcels.length }})</h4>
            <div class="export-buttons">
              <button class="btn-export geojson" @click="exportGeoJSON">
                ⬇ Download .GeoJSON (QGIS)
              </button>
              <button class="btn-export csv" @click="exportCSV">
                ⬇ Download .CSV (R / Scilab)
              </button>
            </div>
          </div>

          <hr />
          <h3>GEODETISCHE OBJECTEN (KLIK OM TE ZOOMEN)</h3>
          <div v-for="p in filteredParcels" :key="p.parcelId" class="parcel-card" @click="focusParcel(p)">
            <div class="parcel-header">
              <strong>{{ p.naam }}</strong>
              <span class="tag">{{ p.wooReferentie }}</span>
            </div>
            <div class="coords">
              RD X:{{ p.rdX }} Y:{{ p.rdY }} | <strong>{{ p.napDiepteM.toFixed(2) }}m NAP</strong> | {{ p.oppervlakteHa }} ha
            </div>
          </div>
        </div>

        <div class="map-wrapper">
          <div id="map-container" ref="mapContainer"></div>
          <div class="nap-legend">
            <strong>DIEPTE & HOOGTE PROFIEL (Oosterschelde Kom)</strong>
            <div><span class="swatch" style="background:#10b981"></span> Perceel 369 (Bol van Lodijke): <b>-1,80m NAP</b></div>
            <div><span class="swatch" style="background:#3b82f6"></span> Molenplaat Visserij (150 ha): <b>-2,10m NAP</b></div>
            <div><span class="swatch" style="background:#f59e0b"></span> Kasteel Lodijke (ARC-LOD-01): <b>-3,20m NAP</b></div>
            <div><span class="swatch" style="background:#ef4444"></span> Stad Reimerswaal (Rijksmon.): <b>-1,50m NAP</b></div>
          </div>
        </div>
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
import { ref, computed, onMounted, watch, nextTick } from 'vue'
import L from 'leaflet'

const activeTab = ref('tab06')
const apiOnline = ref(false)
const mapContainer = ref(null)
const wmsOpacity = ref(0.65)
const cursorRd = ref({ x: 68120, y: 388050 })

let mapInstance = null
let layerGroup = null
let activeWms = {
  luchtfoto: null,
  bathymetrie: null,
  kadaster: null,
  ahn: null
}

const wmsLayers = ref({
  luchtfoto: false,
  bathymetrie: true,
  kadaster: true,
  ahn: false
})

const layers = ref({
  perceel369: true,
  molenplaat: true,
  verdronken: true
})

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

const filteredParcels = computed(() => {
  return geoParcels.value.filter((p) => {
    if (p.parcelId === 'PERCEEL-369' && !layers.value.perceel369) return false
    if (p.parcelId === 'MOLENPLAAT-150' && !layers.value.molenplaat) return false
    if ((p.parcelId === 'ARC-LOD-01' || p.parcelId === 'STAD-REIMERSWAAL') && !layers.value.verdronken) return false
    return true
  })
})

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

function exportGeoJSON() {
  const features = filteredParcels.value.map((p) => {
    let geometry = null
    try {
      geometry = JSON.parse(p.geojsonPolygon)
    } catch (_) {
      geometry = { type: 'Point', coordinates: [p.lng, p.lat] }
    }
    return {
      type: 'Feature',
      id: p.parcelId,
      properties: {
        parcel_id: p.parcelId,
        naam: p.naam,
        gebied: p.gebied,
        oppervlakte_ha: p.oppervlakteHa,
        rd_x: p.rdX,
        rd_y: p.rdY,
        lat_wgs84: p.lat,
        lng_wgs84: p.lng,
        nap_diepte_m: p.napDiepteM,
        woo_referentie: p.wooReferentie,
        gramps_stamreeks: 'I0103 (W. Bout) / I0104 (M.J.M.M. Goijarts-Bout)',
        crs_rd: 'EPSG:28992'
      },
      geometry
    }
  })

  const featureCollection = {
    type: 'FeatureCollection',
    name: 'Lodijke_Reimerswaal_Perceel369_Molenplaat',
    crs: {
      type: 'name',
      properties: { name: 'urn:ogc:def:crs:OGC:1.3:CRS84' }
    },
    features
  }

  const blob = new Blob([JSON.stringify(featureCollection, null, 2)], {
    type: 'application/geo+json;charset=utf-8'
  })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `lodijke_reimerswaal_${new Date().toISOString().slice(0, 10)}.geojson`
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
}

function exportCSV() {
  const headers = [
    'parcel_id',
    'naam',
    'gebied',
    'oppervlakte_ha',
    'rd_x',
    'rd_y',
    'lat_wgs84',
    'lng_wgs84',
    'nap_diepte_m',
    'woo_referentie'
  ]
  const rows = filteredParcels.value.map((p) => [
    `"${p.parcelId}"`,
    `"${p.naam}"`,
    `"${p.gebied}"`,
    p.oppervlakteHa,
    p.rdX,
    p.rdY,
    p.lat,
    p.lng,
    p.napDiepteM,
    `"${p.wooReferentie}"`
  ])
  const csvContent = [headers.join(','), ...rows.map((r) => r.join(','))].join('\n')
  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `lodijke_rd_coordinaten_${new Date().toISOString().slice(0, 10)}.csv`
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
}

async function fetchGraphQL() {
  const endpoint = import.meta.env.VITE_GRAPHQL_ENDPOINT || 'http://localhost:8082/graphql'
  const query = `
    query {
      cmsRecords { id code titel datum categorie status }
      grampsCore { grampsId naam beroepStatus relatieReimerswaal familieRelaties }
      geoParcels { parcelId naam gebied oppervlakteHa rdX rdY lat lng napDiepteM wooReferentie geojsonPolygon }
    }
  `
  try {
    const res = await fetch(endpoint, {
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
    try {
      const snap = await fetch('/data/lodijke_snapshot.json')
      const snapJson = await snap.json()
      if (snapJson.data) {
        cmsRecords.value = snapJson.data.cmsRecords
        grampsCore.value = snapJson.data.grampsCore
        geoParcels.value = snapJson.data.geoParcels
        renderLayers()
      }
    } catch (_) {}
  }
}

function initMap() {
  if (!mapContainer.value) return
  if (mapInstance) {
    mapInstance.remove()
  }
  mapInstance = L.map(mapContainer.value).setView([51.4840, 4.1600], 13)

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    attribution: '&copy; OpenStreetMap | PDOK Kadastrale Kaart v5 | RWS Vaklodingen'
  }).addTo(mapInstance)

  activeWms.luchtfoto = L.tileLayer.wms('https://service.pdok.nl/hwh/luchtfotorgb/wms/v1_0', {
    layers: 'Actueel_orthoHR',
    format: 'image/jpeg',
    transparent: false,
    attribution: 'PDOK Luchtfoto'
  })

  activeWms.bathymetrie = L.tileLayer.wms('https://geo.rijkswaterstaat.nl/services/ogc/gdr/vaklodingen/ows', {
    layers: 'vaklodingen_kb131_2634',
    format: 'image/png',
    transparent: true,
    opacity: wmsOpacity.value,
    attribution: 'RWS Vaklodingen NAP'
  })

  activeWms.ahn = L.tileLayer.wms('https://service.pdok.nl/rws/ahn/wms/v1_0', {
    layers: 'dsm_05m',
    format: 'image/png',
    transparent: true,
    opacity: wmsOpacity.value,
    attribution: 'PDOK AHN4'
  })

  activeWms.kadaster = L.tileLayer.wms('https://service.pdok.nl/kadaster/kadastralekaart/wms/v5_0', {
    layers: 'Kadastralekaart',
    format: 'image/png',
    transparent: true,
    opacity: 0.85,
    attribution: 'Kadaster BRK v5'
  })

  toggleWmsLayers()

  layerGroup = L.layerGroup().addTo(mapInstance)
  renderLayers()

  mapInstance.on('mousemove', (e) => {
    cursorRd.value = wgs84ToRd(e.latlng.lat, e.latlng.lng)
  })
}

function toggleWmsLayers() {
  if (!mapInstance) return
  Object.keys(wmsLayers.value).forEach((key) => {
    const layer = activeWms[key]
    if (!layer) return
    if (wmsLayers.value[key]) {
      if (!mapInstance.hasLayer(layer)) mapInstance.addLayer(layer)
    } else {
      if (mapInstance.hasLayer(layer)) mapInstance.removeLayer(layer)
    }
  })
}

function updateWmsOpacity() {
  if (activeWms.bathymetrie) activeWms.bathymetrie.setOpacity(wmsOpacity.value)
  if (activeWms.ahn) activeWms.ahn.setOpacity(wmsOpacity.value)
}

function renderLayers() {
  if (!layerGroup) return
  layerGroup.clearLayers()

  filteredParcels.value.forEach((p) => {
    const popupHtml = `
      <div style="font-family: monospace; color: #0f172a; min-width: 250px;">
        <h4 style="margin:0 0 6px 0; border-bottom: 2px solid #0284c7; padding-bottom:4px;">${p.naam}</h4>
        <p style="margin:3px 0;"><b>Gebied:</b> ${p.gebied}</p>
        <p style="margin:3px 0;"><b>Oppervlakte:</b> ${p.oppervlakteHa} ha</p>
        <p style="margin:3px 0;"><b>RD-Nieuw (EPSG:28992):</b> X:${p.rdX} / Y:${p.rdY}</p>
        <p style="margin:3px 0;"><b>Hoogte / Diepte:</b> <span style="color:#0369a1;font-weight:bold;">${p.napDiepteM.toFixed(2)}m NAP</span></p>
        <p style="margin:6px 0 0 0; background:#e2e8f0; padding:5px; border-radius:4px;">
          📄 <b>Woo-Dossier:</b> <a href="#${p.wooReferentie}">${p.wooReferentie}</a><br/>
          👤 <b>GRAMPS Stamreeks:</b> I0103 (W. Bout) / I0104
        </p>
      </div>
    `

    try {
      const geo = JSON.parse(p.geojsonPolygon)
      if (geo.type === 'Polygon') {
        const latlngs = geo.coordinates[0].map(c => [c[1], c[0]])
        const color = p.parcelId === 'PERCEEL-369' ? '#10b981' : '#3b82f6'
        L.polygon(latlngs, { color, weight: 3, fillOpacity: 0.35 })
          .bindPopup(popupHtml)
          .addTo(layerGroup)
      } else {
        const markerColor = p.parcelId === 'ARC-LOD-01' ? '#f59e0b' : '#ef4444'
        L.circleMarker([p.lat, p.lng], {
          radius: 10,
          fillColor: markerColor,
          color: '#ffffff',
          weight: 2,
          fillOpacity: 0.95
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
.brand h1 { margin: 0; font-size: 1.05rem; color: #38bdf8; }
.badge { font-size: 0.7rem; background: #0284c7; padding: 2px 6px; border-radius: 3px; }
.tabs button { background: #0f172a; color: #94a3b8; border: 1px solid #334155; padding: 8px 14px; margin-right: 8px; cursor: pointer; font-family: inherit; }
.tabs button.active { background: #0284c7; color: #fff; border-color: #38bdf8; }
.status { font-size: 0.8rem; display: flex; align-items: center; gap: 8px; color: #cbd5e1; }
.divider { color: #475569; }
.dot { width: 10px; height: 10px; border-radius: 50%; display: inline-block; }
.dot.online { background: #10b981; box-shadow: 0 0 8px #10b981; }
.dot.offline { background: #f59e0b; }
.content { flex: 1; overflow: hidden; }
.gis-layout { display: grid; grid-template-columns: 380px 1fr; height: 100%; }
.sidebar { background: #0f172a; padding: 16px; border-right: 1px solid #334155; overflow-y: auto; }
.sidebar h3 { font-size: 0.85rem; color: #38bdf8; margin-top: 0; }
.layer-toggles label { display: block; margin-bottom: 8px; font-size: 0.82rem; cursor: pointer; }
.opacity-control { margin: 12px 0; font-size: 0.8rem; color: #94a3b8; }
.opacity-control input { width: 100%; margin-top: 4px; }
.export-box { background: #1e293b; border: 1px solid #334155; padding: 10px; border-radius: 4px; margin-top: 12px; }
.export-box h4 { margin: 0 0 8px 0; font-size: 0.78rem; color: #94a3b8; }
.export-buttons { display: flex; gap: 8px; }
.btn-export { flex: 1; padding: 7px 8px; font-size: 0.75rem; font-family: inherit; font-weight: bold; border: 1px solid transparent; border-radius: 4px; cursor: pointer; color: #fff; }
.btn-export.geojson { background: #059669; border-color: #10b981; }
.btn-export.geojson:hover { background: #047857; }
.btn-export.csv { background: #0284c7; border-color: #38bdf8; }
.btn-export.csv:hover { background: #0369a1; }
.parcel-card { background: #1e293b; border: 1px solid #334155; padding: 10px; margin-bottom: 10px; border-radius: 4px; cursor: pointer; transition: border 0.2s; }
.parcel-card:hover { border-color: #38bdf8; }
.parcel-header { display: flex; justify-content: space-between; font-size: 0.83rem; margin-bottom: 4px; }
.tag { background: #065f46; color: #6ee7b7; padding: 1px 6px; border-radius: 3px; font-size: 0.72rem; }
.coords { font-size: 0.75rem; color: #94a3b8; }
.map-wrapper { position: relative; width: 100%; height: 100%; }
#map-container { width: 100%; height: 100%; }
.nap-legend { position: absolute; bottom: 24px; right: 16px; z-index: 1000; background: rgba(15, 23, 42, 0.92); border: 1px solid #334155; padding: 12px; border-radius: 6px; font-size: 0.78rem; line-height: 1.6; box-shadow: 0 4px 12px rgba(0,0,0,0.5); }
.swatch { display: inline-block; width: 10px; height: 10px; margin-right: 6px; border-radius: 2px; }
.data-layout { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; padding: 20px; height: 100%; overflow-y: auto; }
.panel { background: #1e293b; padding: 16px; border-radius: 6px; border: 1px solid #334155; }
.record-box { background: #0f172a; padding: 12px; margin-bottom: 12px; border-left: 3px solid #38bdf8; }
.status-pill { font-size: 0.75rem; background: #1e3a8a; color: #93c5fd; padding: 2px 8px; border-radius: 4px; }
</style>
