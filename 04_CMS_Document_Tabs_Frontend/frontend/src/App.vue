<template>
  <div class="app-container">
    <header class="header">
      <div class="brand">
        <h1>🏛️ Lodijke Master Platform</h1>
        <p>Zeeuws Visserij Dossier, Sporen & Geodetische Percelen</p>
      </div>
      <div class="status-badge" :class="{ online: isConnected }">
        <span class="indicator"></span>
        Status: {{ statusText }}
      </div>
    </header>

    <!-- Navigatie Tabbladen -->
    <nav class="tab-nav">
      <button :class="{ active: activeTab === 'sporen' }" @click="setTab('sporen')">
        🗺️ Sporen & Kaarten (#sporen)
      </button>
      <button :class="{ active: activeTab === 'dossiers' }" @click="setTab('dossiers')">
        🎣 Visserij Dossiers (#dossiers)
      </button>
      <button :class="{ active: activeTab === 'percelen' }" @click="setTab('percelen')">
        📍 Perceel 369 Details (#percelen)
      </button>
    </nav>

    <main class="main-content">
      <!-- Sectie 1: Sporen & Kaarten -->
      <section class="card" v-show="activeTab === 'sporen' || activeTab === 'kaarten'">
        <h2>🗺️ Geodetische Percelen & Historische Sporen (GeoJSON / Leaflet)</h2>
        <p>
          Interactieve kaartweergave met de 4 geodetische percelen uit <code>lodijke-percelen.geojson</code>, waaronder <strong>Oesterperceel No. 369</strong> op de Bol van Lodijke en de polder-klepduiker.
        </p>
        
        <!-- Uniek expliciet ID voor de Leaflet container -->
        <div id="leaflet-map" ref="mapContainer" class="map-view"></div>
      </section>

      <!-- Sectie 2: Archiefstukken & Dossiers -->
      <section class="card" v-show="activeTab === 'dossiers'">
        <div class="card-header">
          <h2>🎣 Archiefstukken & Concessie Dossiers</h2>
          <button @click="fetchGraphQLData" class="btn">⚡ Herlaad Gegevens</button>
        </div>
        
        <div class="grid" v-if="records.length > 0">
          <article v-for="rec in records" :key="rec.id" class="record-card">
            <h3>{{ rec.title }}</h3>
            <p>{{ rec.content }}</p>
            <span class="date">📅 Registratie: {{ rec.createdAt }}</span>
          </article>
        </div>
      </section>

      <!-- Sectie 3: Perceel 369 Detail -->
      <section class="card" v-show="activeTab === 'percelen'">
        <h2>📍 Perceel 369 - Bol van Lodijke (12,5 ha)</h2>
        <p>
          Historische oesterkweekbank van B.W. Schot (1840–1935). Coördinaten: <strong>51.47833°N, 4.13750°E</strong> (RD X=68120, Y=388050).
        </p>
      </section>
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, watch, nextTick } from 'vue'
import L from 'leaflet'

const isConnected = ref(false)
const statusText = ref('Verbinden...')
const records = ref([])
const mapContainer = ref(null)
const activeTab = ref('sporen')
let leafletMap = null

// GeoJSON percelen data
const geoJsonData = {
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "id": "parcel-369",
      "properties": {
        "name": "Oesterperceel No. 369 (Bol van Lodijke)",
        "description": "Historisch oesterkweekperceel (12.5 ha) gepacht door B.W. Schot."
      },
      "geometry": {
        "type": "Polygon",
        "coordinates": [[[4.1349, 51.47708], [4.1401, 51.47708], [4.1401, 51.47958], [4.1349, 51.47958], [4.1349, 51.47708]]]
      }
    },
    {
      "type": "Feature",
      "id": "schakerloo-I-360",
      "properties": {
        "name": "Hofstede De Gortzak (Polder Schakerloo)",
        "description": "Tholen Sectie I nr. 360 (53.75 ha)."
      },
      "geometry": {
        "type": "Polygon",
        "coordinates": [[[4.1965, 51.524], [4.2071, 51.524], [4.2071, 51.5306], [4.1965, 51.5306], [4.1965, 51.524]]]
      }
    },
    {
      "type": "Feature",
      "id": "tholen-A-107",
      "properties": {
        "name": "Kruittoren 23 & Oesterloods",
        "description": "Woonhuis en oesterverzendloods maatschap Schot & Kegge."
      },
      "geometry": {
        "type": "Polygon",
        "coordinates": [[[4.2224, 51.53038], [4.22315, 51.53038], [4.22315, 51.53074], [4.2224, 51.53074], [4.2224, 51.53038]]]
      }
    },
    {
      "type": "Feature",
      "id": "scherpenisse-E-1551",
      "properties": {
        "name": "Platteweg & Klepduiker (Scherpenisse)",
        "description": "Eikenhouten polder-klepduiker langs de zeedijk."
      },
      "geometry": {
        "type": "Polygon",
        "coordinates": [[[4.1519, 51.54155], [4.1537, 51.54155], [4.1537, 51.54265], [4.1519, 51.54265], [4.1519, 51.54155]]]
      }
    }
  ]
}

const updateTabFromHash = () => {
  const hash = window.location.hash.replace('#', '')
  if (hash === 'sporen' || hash === 'dossiers' || hash === 'percelen') {
    activeTab.value = hash
  } else {
    activeTab.value = 'sporen'
  }
}

const setTab = (tabName) => {
  activeTab.value = tabName
  window.location.hash = tabName
}

const initMap = async () => {
  await nextTick()
  const el = document.getElementById('leaflet-map') || mapContainer.value
  if (!el) return

  if (leafletMap) {
    leafletMap.remove()
    leafletMap = null
  }

  // Initialiseer Leaflet kaart
  leafletMap = L.map(el, {
    center: [51.51, 4.18],
    zoom: 12
  })

  // OpenStreetMap tegellaag via HTTPS
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    attribution: '© OpenStreetMap contributors | Lodijke Geodata'
  }).addTo(leafletMap)

  // GeoJSON percelen toevoegen
  const geoLayer = L.geoJSON(geoJsonData, {
    style: {
      color: '#8B1E1E',
      weight: 3,
      fillColor: '#B22222',
      fillOpacity: 0.45
    },
    onEachFeature: (feature, layer) => {
      if (feature.properties) {
        layer.bindPopup(`
          <div style="font-family: sans-serif; padding: 2px;">
            <h3 style="margin:0 0 5px 0; color:#8B1E1E;">${feature.properties.name}</h3>
            <p style="margin:0; font-size:13px; color:#333;">${feature.properties.description}</p>
          </div>
        `)
      }
    }
  }).addTo(leafletMap)

  // Zoom in op de percelen
  leafletMap.fitBounds(geoLayer.getBounds(), { padding: [30, 30] })

  // Meervoudige tegel-herberekening garandeert weergave op Vercel
  setTimeout(() => { if (leafletMap) leafletMap.invalidateSize() }, 100)
  setTimeout(() => { if (leafletMap) leafletMap.invalidateSize() }, 500)
  setTimeout(() => { if (leafletMap) leafletMap.invalidateSize() }, 1000)
}

watch(activeTab, async (newTab) => {
  if (newTab === 'sporen' || newTab === 'kaarten') {
    await nextTick()
    if (leafletMap) {
      leafletMap.invalidateSize()
    } else {
      initMap()
    }
  }
})

const fetchGraphQLData = async () => {
  try {
    const query = `
      query {
        cmsRecords {
          id
          title
          content
          createdAt
        }
      }
    `
    const res = await fetch('/api/graphql', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ query })
    })

    if (res.ok) {
      const result = await res.json()
      if (result.data && result.data.cmsRecords) {
        records.value = result.data.cmsRecords
        isConnected.value = true
        statusText.value = 'Rust API Online'
        return
      }
    }
  } catch (err) {}

  records.value = [
    {
      id: "doc-369",
      title: "Oesterperceel No. 369 Concessie",
      content: "Concessie op de Bol van Lodijke (12,5 ha) van B.W. Schot.",
      createdAt: "1892-11-22"
    },
    {
      id: "doc-gortzak",
      title: "Hofstede De Gortzak Schakerloo",
      content: "Tholen Sectie I nr. 360 (53,75 ha / 122 gemeten).",
      createdAt: "1873-12-23"
    }
  ]
  isConnected.value = true
  statusText.value = 'Vercel Live (Sporen)'
}

onMounted(() => {
  updateTabFromHash()
  window.addEventListener('hashchange', updateTabFromHash)
  window.addEventListener('resize', () => { if (leafletMap) leafletMap.invalidateSize() })
  fetchGraphQLData()
  initMap()
})

onUnmounted(() => {
  window.removeEventListener('hashchange', updateTabFromHash)
  if (leafletMap) {
    leafletMap.remove()
    leafletMap = null
  }
})
</script>

<style scoped>
.app-container {
  min-height: 100vh;
  font-family: system-ui, -apple-system, sans-serif;
  background-color: #F9F8F6;
  color: #2C2221;
}

.header {
  background-color: #8B1E1E;
  color: white;
  padding: 1.5rem 2rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.brand h1 { margin: 0; font-size: 1.6rem; }
.brand p { margin: 0.2rem 0 0 0; opacity: 0.85; font-size: 0.9rem; }

.status-badge {
  background-color: rgba(0,0,0,0.25);
  padding: 0.5rem 1rem;
  border-radius: 20px;
  font-size: 0.85rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.indicator {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background-color: #FF5555;
}

.status-badge.online .indicator { background-color: #55FF55; }

.tab-nav {
  display: flex;
  background-color: #661010;
  padding: 0 2rem;
  gap: 0.5rem;
}

.tab-nav button {
  background: transparent;
  border: none;
  color: #FFDDDD;
  padding: 0.8rem 1.2rem;
  font-weight: bold;
  font-size: 0.95rem;
  cursor: pointer;
  border-bottom: 3px solid transparent;
  transition: all 0.2s;
}

.tab-nav button:hover, .tab-nav button.active {
  color: white;
  border-bottom-color: #FFD700;
  background-color: rgba(255,255,255,0.1);
}

.main-content {
  max-width: 1100px;
  margin: 2rem auto;
  padding: 0 1.5rem;
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.card {
  background: white;
  padding: 1.8rem;
  border-radius: 10px;
  border-top: 4px solid #8B1E1E;
  box-shadow: 0 4px 10px rgba(0,0,0,0.05);
}

.card h2 { color: #8B1E1E; margin-top: 0; }

.map-view {
  height: 520px !important;
  min-height: 520px !important;
  width: 100% !important;
  display: block !important;
  position: relative !important;
  border-radius: 8px;
  border: 2px solid #8B1E1E;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  margin-top: 1rem;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.btn {
  background-color: #8B1E1E;
  color: white;
  border: none;
  padding: 0.6rem 1.2rem;
  font-weight: bold;
  border-radius: 6px;
  cursor: pointer;
}

.btn:hover { background-color: #661010; }

.grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 1rem;
  margin-top: 1rem;
}

.record-card {
  background: #F9F8F6;
  border: 1px solid #E2D7D5;
  padding: 1rem;
  border-radius: 8px;
}

.record-card h3 { margin: 0 0 0.5rem 0; color: #8B1E1E; }
.date { font-size: 0.8rem; color: #666; margin-top: 0.8rem; display: block; }
</style>
