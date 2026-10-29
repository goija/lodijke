<template>
  <div class="platform-wrapper">
    <!-- BORDEAUXRODE TOP NAVIGATIEBALK MET SLIDING DRAWER TOGGLE & TABS -->
    <header class="navbar">
      <div class="nav-container">
        <div class="brand-left">
          <button class="hamburger-btn" @click="leftDrawerOpen = !leftDrawerOpen" title="Open Sliding Navigatie Menu">
            ☰
          </button>
          <a href="#home" class="brand" @click.prevent="switchTab('overzicht')">
            🏛️ <span>Lodijke Master Platform</span>
          </a>
        </div>

        <nav class="nav-links">
          <button :class="['nav-btn', activeMainTab === 'overzicht' ? 'active-pill' : '']" @click="switchTab('overzicht')">
            ⚓ Visserij Dossier (Home)
          </button>
          <button :class="['nav-btn', activeMainTab === 'gis' ? 'active-pill' : '']" @click="switchTab('gis')">
            📍 Perceel 369 (GIS)
          </button>
          <button :class="['nav-btn', activeMainTab === 'woosporen' ? 'active-pill' : '']" @click="switchTab('woosporen')">
            ⚖️ Woo Sporen (A-F) <span class="count-pill">{{ wooSporen.length }}</span>
          </button>
          <button :class="['nav-btn', activeMainTab === 'mappenboom' ? 'active-pill' : '']" @click="switchTab('mappenboom')">
            📂 Mappenboom (6)
          </button>
          <button :class="['nav-btn', activeMainTab === 'beoostenschelde' ? 'active-pill' : '']" @click="switchTab('beoostenschelde')">
            📡 API, RSS &amp; Media Beoosten Schelde
          </button>
          <a href="https://github.com/goija/geocentrum" target="_blank" rel="noopener noreferrer" class="nav-btn ext-link">
            GitHub ↗
          </a>
        </nav>
      </div>
    </header>

    <!-- LINKER SLIDING MENU DRAWER (SNELMENU, API STATUS & FILTERING) -->
    <transition name="slide-left">
      <aside v-if="leftDrawerOpen" class="sliding-drawer left-drawer">
        <div class="drawer-header">
          <h3>🧭 Lodijke Command Menu</h3>
          <button class="close-drawer-btn" @click="leftDrawerOpen = false">✕</button>
        </div>

        <div class="drawer-section">
          <h4>DIRECTE MODULES (TABS)</h4>
          <ul class="drawer-nav-list">
            <li @click="switchTab('overzicht'); leftDrawerOpen = false">⚓ Kompleet Dossier Overzicht</li>
            <li @click="switchTab('gis'); leftDrawerOpen = false">📍 Geodetische GIS Kaart (Perceel 369)</li>
            <li @click="switchTab('woosporen'); leftDrawerOpen = false">⚖️ De 6 Woo-Sporen (A t/m F) Beheer</li>
            <li @click="switchTab('mappenboom'); leftDrawerOpen = false">📂 6 Geïntegreerde Mappenbomen</li>
            <li @click="switchTab('beoostenschelde'); leftDrawerOpen = false">🎙️ Beoosten Schelde RSS, Podcasts &amp; API's</li>
          </ul>
        </div>

        <div class="drawer-section">
          <h4>LIVE BACKEND NODES</h4>
          <div class="node-status-row">
            <span>🦀 Axum GraphQL (:8082)</span>
            <span class="badge-online">ACTIEF</span>
          </div>
          <div class="node-status-row">
            <span>🎙️ Rust Podcast RSS (:8081)</span>
            <span class="badge-online">SYSTEMD</span>
          </div>
          <div class="node-status-row">
            <span>🐍 Python Geodesy REST (:8080)</span>
            <span class="badge-online">STANDBY</span>
          </div>
          <div class="node-status-row">
            <span>🗺️ PDOK BRK WFS v5.0</span>
            <span class="badge-online">VERBONDEN</span>
          </div>
        </div>

        <div class="drawer-section">
          <h4>HISTORISCHE ANKERPUNTEN</h4>
          <p class="drawer-meta">
            <strong>Oesterperceel No. 369:</strong> 12,5 ha op de Bol van Lodijke (RD X=68120, Y=388050, -1.80m tot -2.10m NAP).<br/>
            <strong>Concessiehouder:</strong> Reder B.W. Schot (1840–1925).<br/>
            <strong>Stamreeks:</strong> I0103 (W. Bout) &amp; I0088 (C.M. Guiljam).
          </p>
        </div>
      </aside>
    </transition>

    <!-- RECHTER SLIDING DOSSIER INSPECTOR (OPENT BIJ KLIK OP EEN WOO-SPOOR OF BRON) -->
    <transition name="slide-right">
      <aside v-if="activeDrawerSpoor" class="sliding-drawer right-drawer">
        <div class="drawer-header">
          <div>
            <span class="spoor-badge">{{ activeDrawerSpoor.code }}</span>
            <h3 style="margin: 6px 0 0 0;">{{ activeDrawerSpoor.titel }}</h3>
          </div>
          <button class="close-drawer-btn" @click="activeDrawerSpoor = null">✕</button>
        </div>

        <div class="drawer-body">
          <div class="meta-strip">
            <span><strong>Referentie:</strong> {{ activeDrawerSpoor.ref }}</span>
            <span><strong>Status:</strong> {{ activeDrawerSpoor.status }}</span>
          </div>

          <p class="drawer-lead">{{ activeDrawerSpoor.beschrijving }}</p>

          <h4>📜 Primair Historisch &amp; Juridisch Bewijs (Beoosten Schelde)</h4>
          <ul class="evidence-list">
            <li v-for="(stuk, i) in activeDrawerSpoor.bewijsstukken" :key="i">
              📄 {{ stuk }}
            </li>
          </ul>

          <h4>🔗 Gekoppelde API &amp; Geodetische Query</h4>
          <pre class="code-snippet">{{ activeDrawerSpoor.graphqlQuery }}</pre>

          <div class="drawer-actions">
            <button class="link-btn" @click="zoomToSpoor(activeDrawerSpoor)">📍 Lokaliseer op GIS-Kaart</button>
            <button class="btn-delete-spoor" @click="deleteSpoorByCode(activeDrawerSpoor.code)">
              🗑️ Verwijder {{ activeDrawerSpoor.code }}
            </button>
          </div>
        </div>
      </aside>
    </transition>

    <!-- HERO BANNER -->
    <section id="home" class="hero-banner">
      <h1>Zeeuws Visserij Dossier &amp; Lodijke Archiefbeheer — Beoosten Schelde</h1>
      <div class="hero-sub">
        Oesterperceel No. 369 (Bol van Lodijke) • Molenplaat (150 ha) • Kasteel Lodijke (-3,20m NAP) • Stamreeks I0103
      </div>
      <div class="hero-btn-group">
        <button class="hero-cta" @click="switchTab('woosporen')">
          Bekijk &amp; Beheer de {{ wooSporen.length }} Woo-Sporen (A–F)
        </button>
        <button class="hero-cta secondary-cta" @click="switchTab('beoostenschelde')">
          📡 Open Beoosten Schelde API, RSS &amp; Podcast Hub
        </button>
      </div>
    </section>

    <!-- MAIN CONTENT CONTAINER MET DYNAMISCHE TABS -->
    <main class="main-container">

      <!-- =====================================================================
           ONDERDEEL 1: GEODETISCHE KAARTWEERGAVE & PERCEEL NO. 369 (GIS)
           ===================================================================== -->
      <section v-show="activeMainTab === 'overzicht' || activeMainTab === 'gis'" id="gis" class="card-section">
        <div class="section-header-flex">
          <div>
            <h2 class="section-title">📍 Geodetische Kaartweergave &amp; Perceel No. 369 (Beoosten Schelde)</h2>
            <p class="section-subtitle">
              Oesterperceel No. 369 op de Bol van Lodijke (12,5 ha, RD X=68120 Y=388050) van Reder Benjamin Willem Schot (1840–1925).
            </p>
          </div>
          <button class="recenter-btn" @click="focusPerceel369">🎯 Centreer Perceel 369</button>
        </div>

        <div class="map-toolbar">
          <div class="layer-group">
            <strong>Basiskaart:</strong>
            <button :class="{ active: baseMode === 'osm' }" @click="setBaseLayer('osm')">OpenStreetMap</button>
            <button :class="{ active: baseMode === 'ortho' }" @click="setBaseLayer('ortho')">PDOK Luchtfoto (25cm)</button>
            <button :class="{ active: baseMode === 'dark' }" @click="setBaseLayer('dark')">Maritiem Donker</button>
          </div>
          <div class="layer-group">
            <strong>Rijkslagen (WMS):</strong>
            <label><input type="checkbox" v-model="overlays.kadaster" @change="syncOverlays" /> PDOK Kadastrale Kaart v5</label>
            <label><input type="checkbox" v-model="overlays.bathymetrie" @change="syncOverlays" /> RWS Vaklodingen (-NAP)</label>
            <label><input type="checkbox" v-model="overlays.molenplaat" @change="syncOverlays" /> Molenplaat (150 ha)</label>
          </div>
        </div>

        <div class="map-frame">
          <div id="lodijke-leaflet-map" ref="mapEl"></div>
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

      <!-- =====================================================================
           ONDERDEEL 2: DE 6 WOO-SPOREN (A t/m F) MET FILTER-TABS, SLIDING DRAWER & DELETE KNOPPEN
           ===================================================================== -->
      <section v-show="activeMainTab === 'overzicht' || activeMainTab === 'woosporen'" id="woosporen" class="card-section">
        <div class="section-header-flex">
          <div>
            <h2 class="section-title">⚖️ De 6 Woo-Sporen (A t/m F) — Dossier &amp; Bewijsvoering</h2>
            <p class="section-subtitle">
              Klik op een spoor om het <strong>Sliding Dossier Menu</strong> met archiefstukken, kadastrale leggers en GraphQL-records (:8082) te openen, op de kaart te lokaliseren of met 🗑️ te verwijderen.
            </p>
          </div>
          <div class="spoor-admin-controls">
            <button class="btn-restore" @click="restoreDefaultSporen" title="Herstel alle 6 oorspronkelijke Woo-Sporen">
              ↺ Herstel 6 Sporen ({{ wooSporen.length }}/6)
            </button>
          </div>
        </div>

        <!-- Sub-Tabs voor snelle filtering van de Woo-Sporen -->
        <div class="sub-tabs-bar">
          <button :class="['sub-tab', spoorFilter === 'ALLE' ? 'active' : '']" @click="spoorFilter = 'ALLE'">
            Alle Sporen ({{ wooSporen.length }})
          </button>
          <button :class="['sub-tab', spoorFilter === 'VISSERIJ' ? 'active' : '']" @click="spoorFilter = 'VISSERIJ'">
            🐟 Visserij &amp; Pacht (A, C, E)
          </button>
          <button :class="['sub-tab', spoorFilter === 'ERFGOED' ? 'active' : '']" @click="spoorFilter = 'ERFGOED'">
            🏰 Archeologie &amp; Genealogie (B, D)
          </button>
          <button :class="['sub-tab', spoorFilter === 'BESTUURSRECHT' ? 'active' : '']" @click="spoorFilter = 'BESTUURSRECHT'">
            ⚖️ Bestuursrecht &amp; m.e.r. (F)
          </button>
        </div>

        <div class="grid-3">
          <div v-for="(spoor, idx) in filteredWooSporen" :key="spoor.code" class="spoor-card">
            <div>
              <div class="spoor-header">
                <span class="spoor-badge">{{ spoor.code }}</span>
                <span class="spoor-status">{{ spoor.status }}</span>
                <!-- GEVRAAGDE DELETE KNOP PER WOO-SPOOR -->
                <button
                  class="btn-card-delete"
                  @click.stop="deleteSpoorByCode(spoor.code)"
                  :title="`Verwijder ${spoor.code} uit het overzicht`"
                >
                  🗑️ Verwijder
                </button>
              </div>
              <h3 @click="openSpoorDrawer(spoor)" class="clickable-title">{{ spoor.titel }}</h3>
              <p>{{ spoor.beschrijving }}</p>
            </div>

            <div class="spoor-footer">
              <button class="link-btn" @click="zoomToSpoor(spoor)">📍 Toon op GIS-kaart</button>
              <button class="link-btn secondary" @click="openSpoorDrawer(spoor)">
                📄 Open Dossier ({{ spoor.ref }}) ➔
              </button>
            </div>
          </div>
        </div>
      </section>

      <!-- =====================================================================
           ONDERDEEL 3: HISTORISCH VISSERIJDOSSIER BEOOSTEN SCHELDE —
                        API PROVIDERS, RSS READERS, PODCASTS & LOKALE MEDIA
           ===================================================================== -->
      <section v-show="activeMainTab === 'overzicht' || activeMainTab === 'beoostenschelde'" id="beoostenschelde" class="card-section">
        <div class="section-header-flex">
          <div>
            <h2 class="section-title">📡 Historisch Visserijdossier Beoosten Schelde — API's, RSS, Podcasts &amp; Lokale Media</h2>
            <p class="section-subtitle">
              Real-time koppeling met kadastrale/hydrografische API-providers, de lokale Rust Axum Podcast/RSS-server (<code>:8081</code>) en historische media uit Tholen, Sint-Maartensdijk, Scherpenisse, Yerseke en het Verdronken Land van Reimerswaal.
            </p>
          </div>
        </div>

        <!-- INTERNE TABS VOOR DE BEOOSTEN SCHELDE HUB -->
        <div class="sub-tabs-bar">
          <button :class="['sub-tab', mediaSubTab === 'apis' ? 'active' : '']" @click="mediaSubTab = 'apis'">
            🔌 API Providers &amp; Geodata Endpoints (6)
          </button>
          <button :class="['sub-tab', mediaSubTab === 'rss' ? 'active' : '']" @click="mediaSubTab = 'rss'">
            📰 RSS Reader Beoosten Schelde &amp; Archief Feeds
          </button>
          <button :class="['sub-tab', mediaSubTab === 'podcasts' ? 'active' : '']" @click="mediaSubTab = 'podcasts'">
            🎙️ Podcasts &amp; Audio-Archief (:8081)
          </button>
          <button :class="['sub-tab', mediaSubTab === 'media' ? 'active' : '']" @click="mediaSubTab = 'media'">
            🗞️ Lokale Media &amp; Visserijkroniek (1530–2026)
          </button>
        </div>

        <!-- TAB 3A: API PROVIDERS -->
        <div v-if="mediaSubTab === 'apis'" class="grid-3">
          <div v-for="(api, i) in apiProviders" :key="api.id" class="media-card">
            <div class="spoor-header">
              <span class="api-protocol-badge">{{ api.protocol }}</span>
              <span class="spoor-status">{{ api.status }}</span>
              <button class="btn-card-delete" @click="apiProviders.splice(i, 1)">🗑️</button>
            </div>
            <h3>{{ api.naam }}</h3>
            <code class="endpoint-url">{{ api.endpoint }}</code>
            <p>{{ api.toepassing }}</p>
            <div class="spoor-footer">
              <a :href="api.endpoint" target="_blank" rel="noopener noreferrer" class="link-btn">⚡ Test Endpoint ↗</a>
            </div>
          </div>
        </div>

        <!-- TAB 3B: RSS READER BEOOSTEN SCHELDE -->
        <div v-if="mediaSubTab === 'rss'" class="rss-layout">
          <div class="rss-sidebar">
            <h4>GEABONNEERDE FEEDS (BEOOSTEN SCHELDE)</h4>
            <div
              v-for="feed in rssChannels"
              :key="feed.id"
              :class="['rss-channel-item', { active: selectedRssChannel === feed.id }]"
              @click="selectedRssChannel = feed.id"
            >
              <span>{{ feed.icon }} {{ feed.naam }}</span>
              <small>{{ feed.regio }}</small>
            </div>
          </div>
          <div class="rss-feed-list">
            <div v-for="(item, idx) in filteredRssItems" :key="item.id" class="rss-article">
              <div class="rss-article-header">
                <span class="rss-source-tag">{{ item.bron }}</span>
                <span class="rss-date">{{ item.datum }}</span>
                <button class="btn-card-delete" @click="deleteRssItem(item.id)">🗑️ Verwijder</button>
              </div>
              <h4>{{ item.titel }}</h4>
              <p>{{ item.samenvatting }}</p>
              <div class="rss-meta-links">
                <span class="woo-chip">Dossier: {{ item.dossierKoppeling }}</span>
                <button class="link-btn secondary" @click="switchTab('gis')">📍 Bekijk Locatie in Beoosten Schelde</button>
              </div>
            </div>
          </div>
        </div>

        <!-- TAB 3C: PODCASTS & AUDIO-ARCHIEF (RUST AXUM :8081) -->
        <div v-if="mediaSubTab === 'podcasts'" class="grid-2">
          <div v-for="(pod, idx) in podcastEpisodes" :key="pod.id" class="podcast-card">
            <div class="spoor-header">
              <span class="spoor-badge">{{ pod.reeks }}</span>
              <span class="rss-date">Duur: {{ pod.duur }} | {{ pod.bronServer }}</span>
              <button class="btn-card-delete" @click="podcastEpisodes.splice(idx, 1)">🗑️</button>
            </div>
            <h3>🎙️ {{ pod.titel }}</h3>
            <p>{{ pod.beschrijving }}</p>
            <div class="audio-player-bar">
              <button class="play-btn" @click="activeAudio = pod">
                {{ activeAudio && activeAudio.id === pod.id ? '⏸ Speelt af...' : '▶ Afspelen via :8081 Stream' }}
              </button>
              <code class="stream-path">{{ pod.streamUrl }}</code>
            </div>
          </div>
        </div>

        <!-- TAB 3D: LOKALE MEDIA & HISTORISCHE VISSERIJKRONIEK BEOOSTEN SCHELDE -->
        <div v-if="mediaSubTab === 'media'" class="grid-3">
          <div v-for="(krant, idx) in lokaleMediaArchief" :key="krant.id" class="media-card">
            <div class="spoor-header">
              <span class="spoor-badge">{{ krant.jaar }}</span>
              <span class="spoor-status">{{ krant.publicatie }}</span>
              <button class="btn-card-delete" @click="lokaleMediaArchief.splice(idx, 1)">🗑️</button>
            </div>
            <h3>{{ krant.kop }}</h3>
            <p>{{ krant. citaat }}</p>
            <div class="spoor-footer">
              <span class="woo-chip">{{ krant.locatie }}</span>
              <button class="link-btn secondary" @click="switchTab('mappenboom')">📂 Open Archiefstuk</button>
            </div>
          </div>
        </div>
      </section>

      <!-- =====================================================================
           ONDERDEEL 4: DE 6 GEÏNTEGREERDE MAPPENBOMEN COMPONENT
           ===================================================================== -->
      <section v-show="activeMainTab === 'overzicht' || activeMainTab === 'mappenboom'" id="mappenboom" class="card-section">
        <TabMappenbomen />
      </section>

    </main>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
import L from 'leaflet'
import TabMappenbomen from './components/TabMappenbomen.vue'

const activeMainTab = ref('overzicht')
const leftDrawerOpen = ref(false)
const activeDrawerSpoor = ref(null)
const spoorFilter = ref('ALLE')
const mediaSubTab = ref('apis')
const selectedRssChannel = ref('ALLE')
const activeAudio = ref(null)

const mapEl = ref(null)
const baseMode = ref('osm')
const cursorRd = ref({ x: 68120, y: 388050 })
const cursorWgs = ref({ lat: '51.47633', lng: '4.13750' })

const overlays = ref({
  kadaster: true,
  bathymetrie: true,
  molenplaat: true
})

// Originele 6 Woo-Sporen dataset (zodat verwijderde sporen met 1 klik hersteld kunnen worden)
const initialWooSporen = () => [
  {
    code: 'SPOOR A',
    categorie: 'VISSERIJ',
    ref: 'WOO-369-SCHOT',
    titel: 'Oesterperceel No. 369 — Bol van Lodijke (12,5 ha)',
    status: 'Gevalideerd',
    beschrijving: 'Historische concessie en kadastrale legger van Reder Benjamin Willem Schot (1840–1925), omvattende 11 oesterputten t.v.v. Yerseke op RD X=68120, Y=388050.',
    lat: 51.47633,
    lng: 4.13750,
    zoom: 15,
    bewijsstukken: [
      'Pachtcontract Bestuur der Visserijen (1892–1915) voor Oesterperceel No. 369 (12,5 ha)',
      'Kadastrale kaart & legger Yerseke / Reimerswaal: 11 oesterputten op naam van B.W. Schot',
      'Veilingcatalogus Middelburg 22–24 november 1892 (203 Percelen Schelpdierenvisserij)'
    ],
    graphqlQuery: '{ geoParcels(parcelId: "PERCEEL-369") { naam rdX rdY oppervlakteHa napDiepteM } }'
  },
  {
    code: 'SPOOR B',
    categorie: 'ERFGOED',
    ref: 'ARC-LOD-01',
    titel: 'Kasteel Lodijke & Verdronken Dorp (-3,20m NAP)',
    status: 'Archeologisch Anker',
    beschrijving: 'Geodetische en archeologische vastlegging van de fundamenten van Kasteel Lodijke op -3,20m NAP na de Sint-Felixvloed (1530).',
    lat: 51.47310,
    lng: 4.13620,
    zoom: 15,
    bewijsstukken: [
      'Sonar- en duikrapportage Kasteel Lodijke (muurwerk 15x16m op -3,20m NAP)',
      'Middelnederlandse Rijmkroniek van Melis Stoke inzake de Slag bij Lodijke (1301)',
      'UNESCO Geopark Schelde Delta Geosite-registratie & RWS Vaklodingen bathymetrie'
    ],
    graphqlQuery: '{ geoParcels(parcelId: "ARC-LOD-01") { naam rdX rdY napDiepteM wooReferentie } }'
  },
  {
    code: 'SPOOR C',
    categorie: 'VISSERIJ',
    ref: 'WOO-MOL-150',
    titel: 'Visserijpercelen Molenplaat (150 ha)',
    status: 'Actief Woo-Dossier',
    beschrijving: 'Percelen rondom de Molenplaat en Bergse Diepsluis (Oosterschelde Kom, -2,10m NAP) gekoppeld aan historische gebruiks- en visrechten.',
    lat: 51.49650,
    lng: 4.19450,
    zoom: 14,
    bewijsstukken: [
      'Woo-Hoofdzaak 1456324: Hernieuwd Woo-verzoek 13-01-2026 Visserijrechten Molenplaat',
      'Ambtelijk Dossier-Zuurdeeg: Historische pachtkaarten Beoosten Schelde & Bergse Diepsluis',
      'Retributieregisters Bestuur der Visserijen op de Schelde en Zeeuwsche Stromen'
    ],
    graphqlQuery: '{ cmsRecords(code: "WOO-MOL-150") { titel datum status } }'
  },
  {
    code: 'SPOOR D',
    categorie: 'ERFGOED',
    ref: 'GRAMPS-I0103',
    titel: 'Stamreeks W. Bout (I0103) & C.M. Guiljam (I0088)',
    status: 'Genealogisch Bewijs',
    beschrijving: 'Directe afstammingslijn en erfrechtelijke verankering vanuit Sint-Maartensdijk, Tholen en het Verdronken Land van Reimerswaal.',
    lat: 51.52650,
    lng: 4.08150,
    zoom: 13,
    bewijsstukken: [
      'GRAMPS Core SQLite & GEDCOM 5.5.1 stamboom: I0103 (W. Bout) & I0104 (M.J.M.M. Goijarts-Bout)',
      'Archiefstukken C.M. Guiljam (07-08-1944 – 11-09-2021, Sint-Maartensdijk) & Hein Guiljam',
      'Gerechtsdeurwaardersexploot 08-10-2026 (Marco Rave te Goes) en Aktenummer 317/2025 Rechtbank Middelburg'
    ],
    graphqlQuery: '{ grampsCore(grampsId: "I0103") { grampsId naam beroepStatus relatieReimerswaal } }'
  },
  {
    code: 'SPOOR E',
    categorie: 'VISSERIJ',
    ref: 'REI-VISRECHT',
    titel: 'Oudelandse Visrechten & Stad Reimerswaal',
    status: 'Historisch Recht',
    beschrijving: '14e- en 16e-eeuwse charters en visrechten binnen de grenzen van het verdronken rechtsgebied van de stad Reimerswaal (Rijksmonument).',
    lat: 51.48660,
    lng: 4.16140,
    zoom: 14,
    bewijsstukken: [
      '14e-eeuwse Middelnederlandse charters betreffende de ambachtsheerlijkheden Beoosten Schelde',
      'Oudelandse visrechten verankerd op de verdronken gronden van Reimerswaal (-1,50m NAP)',
      'Kadastrale reconstructie Verdronken Land van Zuid-Beveland en Tholen'
    ],
    graphqlQuery: '{ geoParcels(parcelId: "STAD-REIMERSWAAL") { naam oppervlakteHa rdX rdY } }'
  },
  {
    code: 'SPOOR F',
    categorie: 'BESTUURSRECHT',
    ref: 'AWB-MER-2026',
    titel: 'Belanghebbende Status (Awb / m.e.r. Schelde Delta)',
    status: 'Onherroepelijk',
    beschrijving: 'Formeel vastgestelde belanghebbendestatus in het kader van de Wet open overheid (Woo) en milieueffectrapportages in het Oosterscheldebekken.',
    lat: 51.47633,
    lng: 4.13750,
    zoom: 13,
    bewijsstukken: [
      'Uitspraak Rechtbank Zeeland-West-Brabant (BRE 24/5455 WOO, ECLI:NL:RBZWB:2025:6823)',
      'Advies Bezwaarschriftencommissie 28-08-2026 (Zaak 1425030) & derde gewonnen Woo-procedure (oktober 2026)',
      'Formele erkenning als belanghebbende onder de Awb en m.e.r.-richtlijnen Oosterschelde'
    ],
    graphqlQuery: '{ cmsRecords { id code titel status } }'
  }
]

const wooSporen = ref(initialWooSporen())

const filteredWooSporen = computed(() => {
  if (spoorFilter.value === 'ALLE') return wooSporen.value
  return wooSporen.value.filter(s => s.categorie === spoorFilter.value)
})

function deleteSpoorByCode(code) {
  wooSporen.value = wooSporen.value.filter(s => s.code !== code)
  if (activeDrawerSpoor.value && activeDrawerSpoor.value.code === code) {
    activeDrawerSpoor.value = null
  }
}

function restoreDefaultSporen() {
  wooSporen.value = initialWooSporen()
}

function openSpoorDrawer(spoor) {
  activeDrawerSpoor.value = spoor
}

// =====================================================================
// DATA VOOR BEOOSTEN SCHELDE: API PROVIDERS, RSS, PODCASTS & LOKALE MEDIA
// =====================================================================
const apiProviders = ref([
  {
    id: 'api-axum',
    naam: 'Lodijke Rust Axum GraphQL API',
    protocol: 'GraphQL / HTTP',
    status: 'ONLINE (:8082)',
    endpoint: 'http://localhost:8082/graphql',
    toepassing: 'Levert grampsCore (I0103), geoParcels (Perceel 369, Kasteel Lodijke, Molenplaat) en cmsRecords.'
  },
  {
    id: 'api-pdok-brk',
    naam: 'PDOK Kadastrale Kaart WFS/WMS v5.0',
    protocol: 'OGC WMS / WFS',
    status: 'ACTIEF (EPSG:28992)',
    endpoint: 'https://service.pdok.nl/kadaster/kadastralekaart/wms/v5_0',
    toepassing: 'Officiële kadastrale perceelgrenzen voor Yerseke, Reimerswaal, Tholen en Scherpenisse (Sectie E 1552/1551).'
  },
  {
    id: 'api-rws-vaklodingen',
    naam: 'Rijkswaterstaat Vaklodingen & Waterinfo',
    protocol: 'OGC WMS / REST',
    status: 'LIVE (-NAP)',
    endpoint: 'https://geo.rijkswaterstaat.nl/services/ogc/gdr/vaklodingen/ows',
    toepassing: 'Bathymetrische dieptemetingen Oosterschelde Kom: Bol van Lodijke (-1,80m NAP) en Kasteel Lodijke (-3,20m NAP).'
  },
  {
    id: 'api-podcast-rss',
    naam: 'Self-Hosted Rust Axum Podcast & RSS Server',
    protocol: 'RSS 2.0 / systemd',
    status: 'ONLINE (:8081)',
    endpoint: 'http://localhost:8081/rss.xml',
    toepassing: 'Lokale systemd-service die historische audioverslagen, hoorzittingen en veldopnames uit Beoosten Schelde serveert.'
  },
  {
    id: 'api-zeeuws-archief',
    naam: 'Zeeuws Archief & Krantenbank Zeeland API',
    protocol: 'OAI-PMH / IIIF',
    status: 'GEKOPPELD',
    endpoint: 'https://www.zeeuwsarchief.nl/',
    toepassing: 'Ontsluiting van de leggers van het Bestuur der Visserijen (1825–1935) en veilingcatalogi van oesterpercelen.'
  },
  {
    id: 'api-burn-ocr',
    naam: 'Rust Burn Neural OCR Engine (Middelnederlands)',
    protocol: 'Lokaal / Python :8080',
    status: 'STANDBY',
    endpoint: 'http://localhost:8080/api/ocr/charters',
    toepassing: 'Automatische transcriptie van 14e-eeuwse Zeeuwse oorkonden, visrecht-charters en rekeningen van Beoosten Schelde.'
  }
])

const rssChannels = ref([
  { id: 'ALLE', icon: '📡', naam: 'Alle Beoosten Schelde Feeds', regio: 'Oosterschelde & Tholen' },
  { id: 'VISSERIJ', icon: '🦪', naam: 'Bestuur der Visserijen & Pacht', regio: 'Yerseke / Bol van Lodijke' },
  { id: 'THOLEN', icon: '🏛️', naam: 'Bestuursrecht & Erfgoed Tholen', regio: 'Scherpenisse / Sint-Maartensdijk' },
  { id: 'REIMERSWAAL', icon: '🌊', naam: 'Archeologie Verdronken Land', regio: 'Lodijke / Stad Reimerswaal' }
])

const rssItems = ref([
  {
    id: 'rss-1',
    channel: 'VISSERIJ',
    bron: 'Archief Bestuur der Visserijen (Zeeuwsche Stromen)',
    datum: '29 okt 2026',
    titel: 'Kadastrale verificatie Oesterperceel No. 369 (12,5 ha) op de Bol van Lodijke voltooid',
    samenvatting: 'De exacte hoekpunten van de concessie van Reder Benjamin Willem Schot (1840–1925) zijn gekoppeld aan de 11 oesterputten ten voordele van Yerseke op RD X=68120, Y=388050.',
    dossierKoppeling: 'SPOOR A (WOO-369-SCHOT)'
  },
  {
    id: 'rss-2',
    channel: 'THOLEN',
    bron: 'Bestuursrechtelijke Monitor Gemeente Tholen & ZWB',
    datum: '15 okt 2026',
    titel: 'Derde Woo-procedure gewonnen: Belanghebbende-status Awb & m.e.r. formeel verankerd',
    samenvatting: 'Na eerdere uitspraak ECLI:NL:RBZWB:2025:6823 (BRE 24/5455) en bezwaaradvies Zaak 1425030 is de belanghebbende-positie voor het Oosterscheldebekken en Beoosten Schelde onherroepelijk vastgesteld.',
    dossierKoppeling: 'SPOOR F (AWB-MER-2026)'
  },
  {
    id: 'rss-3',
    channel: 'VISSERIJ',
    bron: 'Dossier-Zuurdeeg & Molenplaat Pachtregister',
    datum: '08 okt 2026',
    titel: 'Analyse van de 150 ha visserijpercelen op de Molenplaat en Bergse Diepsluis',
    samenvatting: 'Samenhang tussen de oude kreekruggen van het Verdronken Land en de hedendaagse pachtpercelen onder Zaak 1456324 in kaart gebracht met RWS Vaklodingen.',
    dossierKoppeling: 'SPOOR C (WOO-MOL-150)'
  },
  {
    id: 'rss-4',
    channel: 'REIMERSWAAL',
    bron: 'Geopark Schelde Delta — Onderwaterarcheologie',
    datum: '22 sep 2026',
    titel: 'Muurresten Kasteel Lodijke (ARC-LOD-01) op -3,20m NAP gekoppeld aan 14e-eeuwse bronnen',
    samenvatting: 'De bakstenen fundamenten op de rand van het Gat van Lodijke bevestigen de ligging uit de kroniek van Melis Stoke (1301) en de inundatie bij de Sint-Felixvloed (1530).',
    dossierKoppeling: 'SPOOR B (ARC-LOD-01)'
  }
])

const filteredRssItems = computed(() => {
  if (selectedRssChannel.value === 'ALLE') return rssItems.value
  return rssItems.value.filter(i => i.channel === selectedRssChannel.value)
})

function deleteRssItem(id) {
  rssItems.value = rssItems.value.filter(i => i.id !== id)
}

const podcastEpisodes = ref([
  {
    id: 'pod-1',
    reeks: 'AFLEVERING 01 • BEOOSTEN SCHELDE AUDIO',
    titel: 'De Oesterputten van Benjamin Willem Schot (Perceel 369 & De Veiling van 1892)',
    duur: '28:14',
    bronServer: 'Rust Axum :8081',
    streamUrl: 'http://localhost:8081/streams/aflevering01_perceel369_schot.mp3',
    beschrijving: 'Reconstructie van de grote oesterpachtveiling in Middelburg (november 1892) en de exploitatie van 12,5 hectare op de Bol van Lodijke.'
  },
  {
    id: 'pod-2',
    reeks: 'AFLEVERING 02 • ARCHIEF & RECHT',
    titel: 'Het Oudelandse Visrecht van Reimerswaal en het Dossier-Zuurdeeg',
    duur: '34:40',
    bronServer: 'Rust Axum :8081',
    streamUrl: 'http://localhost:8081/streams/aflevering02_visrecht_zuurdeeg.mp3',
    beschrijving: 'Juridische en historisch-cartografische analyse van de visrechten op verdronken ambachtsheerlijkheden tussen Tholen, Yerseke en Bergen op Zoom.'
  },
  {
    id: 'pod-3',
    reeks: 'AFLEVERING 03 • STAMREEKS & WATERSNOOD',
    titel: 'Van Sint-Maartensdijk (1953) tot de Stuiting van 8 oktober 2026',
    duur: '24:05',
    bronServer: 'Rust Axum :8081',
    streamUrl: 'http://localhost:8081/streams/aflevering03_guiljam_bout_tholen.mp3',
    beschrijving: 'Mondelinge geschiedenis en archiefstukken rond C.M. Guiljam (I0088), schaapherder Hein Guiljam en de hedendaagse erfrechtelijke en bestuursrechtelijke procedures.'
  },
  {
    id: 'pod-4',
    reeks: 'AFLEVERING 04 • MIDDELNEDERLANDSE BRONNEN',
    titel: 'Kasteel Lodijke (1301–1530) voorgelezen in het oorspronkelijke Middelnederlands',
    duur: '19:50',
    bronServer: 'Rust Axum :8081',
    streamUrl: 'http://localhost:8081/streams/aflevering04_middelnederlands_lodijke.mp3',
    beschrijving: 'Integrale voordracht en bespreking van de 14e-eeuwse passages over Lodijke, het Rentmeesterschap Beoosten Schelde en Quade Saterdach (5 november 1530).'
  }
])

const lokaleMediaArchief = ref([
  {
    id: 'med-1',
    jaar: '1892',
    publicatie: 'Middelburgsche Courant / Staatsblad',
    locatie: 'Bol van Lodijke / Yerseke',
    kop: 'Verpachting van 203 Visserijpercelen op de Schelde en Zeeuwsche Stromen',
    citaat: 'Toewijzing van Oesterperceel No. 369 (groot 12,50.00 hectare op de Bol van Lodijke) aan reder en oesterkweker B.W. Schot, gekoppeld aan 11 oesterputten te Yerseke.'
  },
  {
    id: 'med-2',
    jaar: '1530–1532',
    publicatie: 'Rekeningen Rentmeester Beoosten Schelde',
    locatie: 'Kasteel & Ambacht Lodijke',
    kop: 'Inundatie van het Land van Lodijke en de dorpen rond Reimerswaal',
    citaat: 'Op Quade Saterdach (Sint-Felixvloed, 5 november 1530) en de Allerheiligenvloed van 1532 bezwijken de dijken van het ambacht Lodijke; de visrechten blijven als heerlijk recht bestaan.'
  },
  {
    id: 'med-3',
    jaar: '1953–2026',
    publicatie: 'Regionale Kroniek Tholen & Eendrachtbode',
    locatie: 'Sint-Maartensdijk & Scherpenisse',
    kop: 'Van de Rampnacht in Sint-Maartensdijk tot Kadastrale Reconstructie Platteweg',
    citaat: 'Verankering van de familiegeschiedenis Guiljam-Bout op het eiland Tholen, gecorreleerd met kadastrale percelen in Sint-Maartensdijk en Scherpenisse (Sectie E 1552/1551).'
  }
])

// =====================================================================
// LEAFLET GIS KAART LOGICA
// =====================================================================
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

function switchTab(tabName) {
  activeMainTab.value = tabName
  if ((tabName === 'overzicht' || tabName === 'gis') && map) {
    setTimeout(() => {
      map.invalidateSize()
    }, 200)
  }
}

function initLeafletMap() {
  if (!mapEl.value) return
  if (map) map.remove()

  const centerLat = 51.47633
  const centerLng = 4.13750

  map = L.map(mapEl.value, {
    center: [centerLat, centerLng],
    zoom: 14,
    zoomControl: true
  })

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
    attribution: '&copy; CartoDB Dark | Beoosten Schelde'
  })

  baseTileLayers.osm.addTo(map)

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
        Diepte: -3,20m NAP | RD X:68450 Y:387600
      </div>`,
      { className: 'custom-red-popup' }
    )

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
        Diepte: -1,50m NAP | Oudelandse Visrechten
      </div>`,
      { className: 'custom-red-popup' }
    )

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

  map.on('mousemove', (e) => {
    cursorWgs.value = {
      lat: e.latlng.lat.toFixed(5),
      lng: e.latlng.lng.toFixed(5)
    }
    cursorRd.value = wgs84ToRd(e.latlng.lat, e.latlng.lng)
  })

  setTimeout(() => {
    map.invalidateSize()
    perceel369Marker.openPopup()
  }, 200)
}

function setBaseLayer(mode) {
  baseMode.value = mode
  if (!map) return
  Object.values(baseTileLayers).forEach(layer => {
    if (map.hasLayer(layer)) map.removeLayer(layer)
  })
  if (baseTileLayers[mode]) baseTileLayers[mode].addTo(map)
}

function syncOverlays() {
  if (!map) return
  Object.keys(overlays.value).forEach(key => {
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
  switchTab('gis')
  if (!map) return
  map.flyTo([51.47633, 4.13750], 15, { duration: 0.8 })
  if (perceel369Marker) perceel369Marker.openPopup()
}

function zoomToSpoor(spoor) {
  activeDrawerSpoor.value = null
  switchTab('gis')
  if (map) {
    setTimeout(() => {
      map.invalidateSize()
      map.flyTo([spoor.lat, spoor.lng], spoor.zoom || 15, { duration: 0.9 })
    }, 150)
  }
}

onMounted(async () => {
  await nextTick()
  initLeafletMap()
})
</script>

<style scoped>
/* TOP NAVBAR & SLIDING DRAWERS */
.navbar {
  background: #7f1d1d;
  border-bottom: 1px solid #991b1b;
  color: #ffffff;
  position: sticky;
  top: 0;
  z-index: 2500;
  box-shadow: 0 2px 10px rgba(0,0,0,0.3);
}
.nav-container {
  max-width: 1360px;
  margin: 0 auto;
  padding: 10px 20px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 10px;
}
.brand-left { display: flex; align-items: center; gap: 10px; }
.hamburger-btn {
  background: rgba(255,255,255,0.14);
  color: #fff;
  border: 1px solid rgba(255,255,255,0.3);
  border-radius: 6px;
  font-size: 1.1rem;
  padding: 4px 10px;
  cursor: pointer;
}
.brand {
  color: #ffffff;
  text-decoration: none;
  font-weight: 700;
  font-size: 1.05rem;
  display: flex;
  align-items: center;
  gap: 6px;
}
.nav-links { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; }
.nav-btn {
  background: transparent;
  border: none;
  color: #fecaca;
  font-size: 0.84rem;
  padding: 7px 13px;
  border-radius: 6px;
  cursor: pointer;
  text-decoration: none;
  font-family: inherit;
  transition: all 0.15s;
}
.nav-btn:hover { background: rgba(255,255,255,0.14); color: #fff; }
.nav-btn.active-pill {
  background: #ffffff;
  color: #7f1d1d;
  font-weight: 700;
}
.count-pill {
  background: #991b1b;
  color: #fff;
  padding: 1px 6px;
  border-radius: 10px;
  font-size: 0.72rem;
  margin-left: 4px;
}

/* SLIDING DRAWERS (LINKS & RECHTS) */
.sliding-drawer {
  position: fixed;
  top: 54px;
  bottom: 0;
  width: 380px;
  max-width: 92vw;
  background: #0f172a;
  color: #f8fafc;
  z-index: 3000;
  box-shadow: 0 10px 30px rgba(0,0,0,0.55);
  display: flex;
  flex-direction: column;
  overflow-y: auto;
  padding: 20px;
}
.left-drawer { left: 0; border-right: 2px solid #7f1d1d; }
.right-drawer { right: 0; width: 440px; border-left: 3px solid #dc2626; }

.drawer-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  border-bottom: 1px solid #334155;
  padding-bottom: 12px;
  margin-bottom: 16px;
}
.drawer-header h3 { margin: 0; color: #f8fafc; font-size: 1.05rem; }
.close-drawer-btn {
  background: #1e293b;
  color: #cbd5e1;
  border: 1px solid #475569;
  border-radius: 5px;
  padding: 4px 9px;
  cursor: pointer;
}
.drawer-section { margin-bottom: 20px; }
.drawer-section h4 { font-size: 0.75rem; color: #f87171; letter-spacing: 0.5px; margin: 0 0 8px 0; }
.drawer-nav-list { list-style: none; padding: 0; margin: 0; }
.drawer-nav-list li {
  padding: 9px 12px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.88rem;
  color: #e2e8f0;
  margin-bottom: 4px;
  background: #1e293b;
}
.drawer-nav-list li:hover { background: #7f1d1d; color: #fff; }
.node-status-row {
  display: flex;
  justify-content: space-between;
  font-size: 0.8rem;
  padding: 6px 0;
  border-bottom: 1px dashed #334155;
}
.badge-online {
  background: #065f46;
  color: #6ee7b7;
  padding: 1px 6px;
  border-radius: 4px;
  font-size: 0.7rem;
  font-weight: 700;
}
.drawer-meta { font-size: 0.8rem; color: #94a3b8; line-height: 1.5; }
.meta-strip { display: flex; gap: 14px; font-size: 0.8rem; color: #cbd5e1; margin-bottom: 10px; }
.drawer-lead { font-size: 0.88rem; color: #e2e8f0; line-height: 1.5; }
.evidence-list { padding-left: 18px; font-size: 0.84rem; color: #cbd5e1; line-height: 1.6; }
.code-snippet {
  background: #020617;
  color: #4ade80;
  padding: 10px;
  border-radius: 6px;
  font-size: 0.76rem;
  overflow-x: auto;
}
.drawer-actions { display: flex; gap: 10px; margin-top: 16px; }

.slide-left-enter-active, .slide-left-leave-active,
.slide-right-enter-active, .slide-right-leave-active {
  transition: transform 0.25s ease, opacity 0.25s ease;
}
.slide-left-enter-from, .slide-left-leave-to { transform: translateX(-100%); opacity: 0; }
.slide-right-enter-from, .slide-right-leave-to { transform: translateX(100%); opacity: 0; }

/* HERO BANNER */
.hero-banner {
  background: linear-gradient(180deg, #651212 0%, #7f1d1d 100%);
  color: #ffffff;
  text-align: center;
  padding: 36px 20px;
  border-bottom: 3px solid #991b1b;
}
.hero-banner h1 { margin: 0 0 8px 0; font-size: 1.85rem; font-weight: 700; }
.hero-sub { font-size: 0.9rem; color: #fecaca; margin-bottom: 18px; }
.hero-btn-group { display: flex; justify-content: center; gap: 12px; flex-wrap: wrap; }
.hero-cta {
  background: #ffffff;
  color: #7f1d1d;
  border: none;
  padding: 10px 20px;
  font-size: 0.86rem;
  font-weight: 700;
  border-radius: 6px;
  cursor: pointer;
  box-shadow: 0 4px 12px rgba(0,0,0,0.25);
}
.hero-cta.secondary-cta {
  background: rgba(0,0,0,0.28);
  color: #ffffff;
  border: 1px solid #fca5a5;
}

/* CARDS & SUB-TABS */
.main-container { max-width: 1240px; margin: 0 auto; padding: 24px 20px 60px; }
.card-section {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 22px;
  margin-bottom: 28px;
  box-shadow: 0 4px 14px rgba(15,23,42,0.05);
}
.section-header-flex {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  flex-wrap: wrap;
  gap: 12px;
  margin-bottom: 12px;
}
.section-title { margin: 0 0 4px 0; color: #881313; font-size: 1.22rem; }
.section-subtitle { margin: 0; color: #475569; font-size: 0.88rem; }

.sub-tabs-bar {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  margin-bottom: 18px;
  border-bottom: 2px solid #f1f5f9;
  padding-bottom: 10px;
}
.sub-tab {
  background: #f1f5f9;
  color: #334155;
  border: 1px solid #cbd5e1;
  padding: 7px 14px;
  border-radius: 6px;
  font-size: 0.82rem;
  font-weight: 600;
  cursor: pointer;
}
.sub-tab.active {
  background: #7f1d1d;
  color: #ffffff;
  border-color: #7f1d1d;
}

.btn-restore {
  background: #0f172a;
  color: #ffffff;
  border: none;
  padding: 7px 13px;
  border-radius: 6px;
  font-size: 0.8rem;
  font-weight: 600;
  cursor: pointer;
}

/* KAART SECTIE */
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
.layer-group { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.layer-group button {
  background: #ffffff;
  border: 1px solid #cbd5e1;
  padding: 5px 10px;
  border-radius: 5px;
  cursor: pointer;
  font-size: 0.78rem;
}
.layer-group button.active { background: #7f1d1d; color: #ffffff; border-color: #7f1d1d; }
.recenter-btn {
  background: #881313;
  color: #ffffff;
  border: none;
  padding: 8px 14px;
  border-radius: 6px;
  font-weight: 600;
  cursor: pointer;
}
.map-frame {
  position: relative;
  width: 100%;
  height: 500px;
  border-radius: 8px;
  overflow: hidden;
  border: 2px solid #1e293b;
}
#lodijke-leaflet-map { width: 100%; height: 100%; }
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
  font-family: ui-monospace, monospace;
  font-size: 0.76rem;
  line-height: 1.5;
  pointer-events: none;
}

/* WOO SPOREN KAARTEN + DELETE KNOPPEN */
.grid-3 { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 16px; }
.grid-2 { display: grid; grid-template-columns: repeat(auto-fit, minmax(420px, 1fr)); gap: 16px; }
.spoor-card, .media-card, .podcast-card {
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
  align-items: center;
  justify-content: space-between;
  gap: 6px;
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
.api-protocol-badge {
  background: #0f172a;
  color: #38bdf8;
  font-size: 0.72rem;
  font-weight: 700;
  padding: 2px 8px;
  border-radius: 4px;
}
.spoor-status { font-size: 0.74rem; color: #047857; font-weight: 700; }
.btn-card-delete, .btn-delete-spoor {
  background: #fee2e2;
  color: #991b1b;
  border: 1px solid #fca5a5;
  padding: 3px 8px;
  border-radius: 4px;
  font-size: 0.72rem;
  font-weight: 700;
  cursor: pointer;
}
.btn-card-delete:hover, .btn-delete-spoor:hover {
  background: #dc2626;
  color: #ffffff;
}
.clickable-title { cursor: pointer; margin: 4px 0 8px 0; font-size: 1rem; color: #1e293b; }
.clickable-title:hover { color: #7f1d1d; text-decoration: underline; }
.spoor-card p, .media-card p, .podcast-card p {
  font-size: 0.84rem;
  color: #475569;
  line-height: 1.48;
  margin: 0 0 14px 0;
}
.spoor-footer { display: flex; gap: 8px; flex-wrap: wrap; align-items: center; }
.link-btn {
  background: #7f1d1d;
  color: #ffffff;
  border: none;
  padding: 6px 12px;
  border-radius: 5px;
  font-size: 0.78rem;
  font-weight: 600;
  cursor: pointer;
  text-decoration: none;
}
.link-btn.secondary { background: #e2e8f0; color: #1e293b; }

/* RSS & PODCAST STYLING */
.endpoint-url {
  display: block;
  background: #f1f5f9;
  color: #0f172a;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 0.74rem;
  margin-bottom: 8px;
  word-break: break-all;
}
.rss-layout { display: grid; grid-template-columns: 260px 1fr; gap: 18px; }
.rss-sidebar {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  padding: 12px;
  border-radius: 8px;
}
.rss-sidebar h4 { margin: 0 0 10px 0; font-size: 0.76rem; color: #64748b; }
.rss-channel-item {
  padding: 9px 10px;
  border-radius: 6px;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  margin-bottom: 6px;
  font-size: 0.84rem;
  font-weight: 600;
}
.rss-channel-item small { font-weight: 400; color: #64748b; font-size: 0.73rem; }
.rss-channel-item.active { background: #7f1d1d; color: #ffffff; }
.rss-channel-item.active small { color: #fecaca; }
.rss-article {
  border: 1px solid #e2e8f0;
  border-left: 4px solid #7f1d1d;
  padding: 14px;
  border-radius: 8px;
  margin-bottom: 12px;
  background: #ffffff;
}
.rss-article-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px; }
.rss-source-tag { font-size: 0.75rem; font-weight: 700; color: #7f1d1d; }
.rss-date { font-size: 0.74rem; color: #64748b; }
.rss-article h4 { margin: 4px 0 6px 0; font-size: 0.96rem; }
.rss-article p { margin: 0 0 10px 0; font-size: 0.84rem; color: #475569; }
.rss-meta-links { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 8px; }
.woo-chip {
  background: #fef2f2;
  color: #991b1b;
  border: 1px solid #fecaca;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 0.74rem;
  font-weight: 600;
}
.audio-player-bar {
  display: flex;
  align-items: center;
  gap: 10px;
  background: #0f172a;
  padding: 8px 10px;
  border-radius: 6px;
  flex-wrap: wrap;
}
.play-btn {
  background: #10b981;
  color: #022c22;
  border: none;
  padding: 5px 10px;
  border-radius: 4px;
  font-weight: 700;
  font-size: 0.76rem;
  cursor: pointer;
}
.stream-path { color: #38bdf8; font-size: 0.72rem; }
</style>
