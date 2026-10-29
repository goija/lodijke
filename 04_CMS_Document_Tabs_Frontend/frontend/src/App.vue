<template>
  <div class="app-container">
    <header class="header">
      <div class="brand">
        <h1>🏛️ Lodijke Master Platform</h1>
        <p>Zeeuws Visserij Dossier, Sporen & Live Data-Invoer</p>
      </div>
      <div class="status-badge" :class="{ online: isConnected }">
        <span class="indicator"></span>
        Status: {{ statusText }}
      </div>
    </header>

    <main class="main-content">
      <!-- Sectie 1: Kaart -->
      <section class="card">
        <h2>🗺️ Geodetische Percelen (GeoJSON / Leaflet)</h2>
        <div id="leaflet-map" class="map-view"></div>
      </section>

      <!-- Sectie 2: Invoerformulier (GraphQL Mutation) -->
      <section class="card">
        <h2>⚡ Nieuw Archiefstuk / Woo-Dossier Invoeren</h2>
        <form @submit.prevent="submitMutation" class="form-grid">
          <input 
            v-model="newTitle" 
            placeholder="Titel (bijv. Woo-besluit Zaak 1456324)" 
            required 
            class="input-field" 
          />
          <textarea 
            v-model="newContent" 
            placeholder="Inhoud / Transcriptie van het document..." 
            required 
            class="textarea-field"
          ></textarea>
          <button type="submit" class="btn">💾 Document Opslaan (GraphQL Mutation)</button>
        </form>
      </section>

      <!-- Sectie 3: Live Overzicht -->
      <section class="card">
        <div class="card-header">
          <h2>🎣 Live Opgeslagen Archiefstukken (Axum JSON)</h2>
          <button @click="fetchGraphQLData" class="btn btn-secondary">⚡ Herlaad</button>
        </div>

        <div class="grid" v-if="records.length > 0">
          <article v-for="rec in records" :key="rec.id" class="record-card">
            <h3>{{ rec.title }}</h3>
            <p>{{ rec.content }}</p>
            <span class="date">📅 Registratie: {{ rec.createdAt }}</span>
          </article>
        </div>
      </section>
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted, nextTick } from 'vue'
import L from 'leaflet'

const isConnected = ref(false)
const statusText = ref('Verbinden...')
const records = ref([])
const newTitle = ref('')
const newContent = ref('')
let leafletMap = null

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
    }
  ]
}

const initMap = async () => {
  await nextTick()
  const el = document.getElementById('leaflet-map')
  if (!el || leafletMap) return

  leafletMap = L.map(el).setView([51.51, 4.18], 12)
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 19 }).addTo(leafletMap)

  const geoLayer = L.geoJSON(geoJsonData, {
    style: { color: '#8B1E1E', weight: 3, fillColor: '#B22222', fillOpacity: 0.45 }
  }).addTo(leafletMap)

  leafletMap.fitBounds(geoLayer.getBounds())
  setTimeout(() => { if (leafletMap) leafletMap.invalidateSize() }, 300)
}

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
        statusText.value = 'Rust GraphQL Actief'
      }
    }
  } catch (err) {
    isConnected.value = false
    statusText.value = 'Offline'
  }
}

const submitMutation = async () => {
  if (!newTitle.value || !newContent.value) return

  const payload = {
    query: `
      mutation AddRecord($title: String!, $content: String!) {
        addCmsRecord(title: $title, content: $content) {
          id
          title
          content
          createdAt
        }
      }
    `,
    variables: {
      title: newTitle.value,
      content: newContent.value
    }
  }

  try {
    const res = await fetch('/api/graphql', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    })

    if (res.ok) {
      const result = await res.json()
      if (result.errors && result.errors.length > 0) {
        alert('GraphQL Fout: ' + result.errors[0].message)
        return
      }
      newTitle.value = ''
      newContent.value = ''
      await fetchGraphQLData()
    } else {
      alert('Fout bij verzenden naar backend')
    }
  } catch (err) {
    alert('Kan geen verbinding maken met de Axum backend.')
  }
}

onMounted(() => {
  fetchGraphQLData()
  initMap()
})
</script>

<style scoped>
.app-container { min-height: 100vh; font-family: system-ui, sans-serif; background: #F9F8F6; color: #2C2221; }
.header { background: #8B1E1E; color: white; padding: 1.5rem 2rem; display: flex; justify-content: space-between; align-items: center; }
.brand h1 { margin: 0; font-size: 1.6rem; }
.brand p { margin: 0.2rem 0 0 0; opacity: 0.85; font-size: 0.9rem; }
.status-badge { background: rgba(0,0,0,0.25); padding: 0.5rem 1rem; border-radius: 20px; font-size: 0.85rem; display: flex; align-items: center; gap: 0.5rem; }
.indicator { width: 10px; height: 10px; border-radius: 50%; background: #FF5555; }
.status-badge.online .indicator { background: #55FF55; }
.main-content { max-width: 1100px; margin: 2rem auto; padding: 0 1.5rem; display: flex; flex-direction: column; gap: 1.5rem; }
.card { background: white; padding: 1.8rem; border-radius: 10px; border-top: 4px solid #8B1E1E; box-shadow: 0 4px 10px rgba(0,0,0,0.05); }
.card h2 { color: #8B1E1E; margin-top: 0; }
.map-view { height: 450px; width: 100%; border-radius: 8px; border: 2px solid #8B1E1E; margin-top: 1rem; }
.form-grid { display: flex; flex-direction: column; gap: 0.8rem; margin-top: 1rem; }
.input-field, .textarea-field { width: 100%; padding: 0.8rem; border: 1px solid #CCC; border-radius: 6px; font-size: 0.95rem; box-sizing: border-box; }
.textarea-field { min-height: 90px; }
.btn { background: #8B1E1E; color: white; border: none; padding: 0.7rem 1.4rem; font-weight: bold; border-radius: 6px; cursor: pointer; }
.btn:hover { background: #661010; }
.btn-secondary { background: #555; }
.card-header { display: flex; justify-content: space-between; align-items: center; }
.grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 1rem; margin-top: 1rem; }
.record-card { background: #F9F8F6; border: 1px solid #E2D7D5; padding: 1rem; border-radius: 8px; }
.record-card h3 { margin: 0 0 0.5rem 0; color: #8B1E1E; }
.date { font-size: 0.8rem; color: #666; margin-top: 0.8rem; display: block; }
</style>
