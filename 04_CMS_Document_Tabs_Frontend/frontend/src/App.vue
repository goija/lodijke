<template>
  <div class="platform-wrapper">
    <!-- BORDEAUX / MEEKRAP-RODE TOP NAVIGATIEBALK -->
    <header class="navbar">
      <div class="nav-container">
        <div class="brand-left">
          <button
            class="hamburger-btn"
            @click="leftDrawerOpen = !leftDrawerOpen"
            :title="leftDrawerOpen ? 'Linker Meekrap-paneel inklappen' : 'Linker Meekrap-paneel openen'"
          >
            {{ leftDrawerOpen ? '◀ Paneel Open' : '☰ Open Paneel' }}
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

    <!-- DOCKED BODY MET PERMANENT GEOPEND WIT + MEEKRAP-ROOD LINKERPANEEL -->
    <div class="platform-body">

      <!-- LINKER PANEEL: STANDAARD OPEN, WIT MET ZEEUWSE MEEKRAP KLEUREN -->
      <aside v-show="leftDrawerOpen" class="meekrap-left-panel">
        <div class="meekrap-panel-header">
          <div>
            <span class="meekrap-kicker">THOOLS &amp; ZEEUWS ERFGOED</span>
            <h3>🧭 Lodijke Navigatie &amp; Dossier</h3>
          </div>
          <button class="meekrap-close-btn" @click="leftDrawerOpen = false" title="Verberg paneel">✕</button>
        </div>

        <!-- 1. WEERGAVE MODULES -->
        <div class="meekrap-section">
          <h4>PLATFORM WEERGAVE TABS</h4>
          <ul class="meekrap-nav-list">
            <li :class="{ active: activeMainTab === 'overzicht' }" @click="switchTab('overzicht')">
              <span>⚓ Kompleet Dossier (Home)</span>
              <span class="meekrap-tag">Alles</span>
            </li>
            <li :class="{ active: activeMainTab === 'gis' }" @click="switchTab('gis')">
              <span>📍 Perceel 369 (Leaflet GIS)</span>
              <span class="meekrap-tag">12,5 ha</span>
            </li>
            <li :class="{ active: activeMainTab === 'woosporen' }" @click="switchTab('woosporen')">
              <span>⚖️ De 6 Woo-Sporen (A–F)</span>
              <span class="meekrap-tag">{{ wooSporen.length }}/6</span>
            </li>
            <li :class="{ active: activeMainTab === 'mappenboom' }" @click="switchTab('mappenboom')">
              <span>📂 6 Master Mappenbomen</span>
              <span class="meekrap-tag">100%</span>
            </li>
            <li :class="{ active: activeMainTab === 'beoostenschelde' }" @click="switchTab('beoostenschelde')">
              <span>📡 Beoosten Schelde Hub</span>
              <span class="meekrap-tag">API/RSS</span>
            </li>
          </ul>
        </div>

        <!-- 2. SNELKOPPELINGEN NAAR DE 6 MAPPENBOMEN -->
        <div class="meekrap-section">
          <h4>DE 6 MASTER MAPPENBOMEN</h4>
          <ul class="meekrap-sub-list">
            <li @click="switchTab('mappenboom')">1. 🏛️ <code>lodijke_master_platform/</code></li>
            <li @click="switchTab('mappenboom')">2. ⚖️ <code>woo_visserij_reimerswaal.../</code></li>
            <li @click="switchTab('mappenboom')">3. 🌍 <code>geopark_lodijke_schelde.../</code></li>
            <li @click="switchTab('mappenboom')">4. 🌳 <code>stamvader_profielen.../</code></li>
            <li @click="switchTab('mappenboom')">5. 🐟 <code>bestuur_der_visserijen.../</code></li>
            <li @click="switchTab('mappenboom')">6. 👥 <code>belanghebbenden_visserij.../</code></li>
          </ul>
        </div>

        <!-- 3. GEODETISCHE KAARTSPRONGEN (BEOOSTEN SCHELDE) -->
        <div class="meekrap-section">
          <h4>GEODETISCHE ANKERPUNTEN (RD)</h4>
          <ul class="meekrap-nav-list compact">
            <li @click="flyToLocation(51.47633, 4.13750, 15)">
              🎯 <strong>Perceel No. 369</strong> (X:68120 Y:388050)
            </li>
            <li @click="flyToLocation(51.47310, 4.13620, 16)">
              🏰 <strong>Kasteel Lodijke</strong> (-3,20m NAP)
            </li>
            <li @click="flyToLocation(51.49650, 4.19450, 14)">
              🐟 <strong>Molenplaat</strong> (150 ha Visrecht)
            </li>
            <li @click="flyToLocation(51.48660, 4.16140, 14)">
              🌊 <strong>Stad Reimerswaal</strong> (-1,50m NAP)
            </li>
            <li @click="flyToLocation(51.52650, 4.08150, 14)">
              🏛️ <strong>Tholen / Scherpenisse</strong> (E 108)
            </li>
          </ul>
        </div>

        <!-- 4. LIVE SYSTEEM & STAMREEKS STATUS -->
        <div class="meekrap-section meekrap-footer-card">
          <h4>KERNGEGEVENS DOSSIER</h4>
          <div class="meekrap-kv"><span>Stamvader:</span> <strong>B.W. Schot (I0103)</strong></div>
          <div class="meekrap-kv"><span>Erfgenamen:</span> <strong>Goijarts-Bout &amp; W. Bout (I0120)</strong></div>
          <div class="meekrap-kv"><span>Vloot Tholen:</span> <strong>TH 2, TH 12, TH 90</strong></div>
          <div class="meekrap-kv"><span>Hoofdzaak:</span> <strong>Woo 1456324 / BRE 24/5455</strong></div>
          <div class="meekrap-kv"><span>Axum API:</span> <strong class="meekrap-online">Poort :8082 Actief</strong></div>
        </div>
      </aside>

      <!-- RECHTER CONTENT KOLOM (HERO + KAART + WOO-SPOREN + MAPPENBOMEN) -->
      <div class="content-column">

        <!-- HERO BANNER -->
        <section id="home" class="hero-banner">
          <h1>Zeeuws Visserij Dossier &amp; Lodijke Archiefbeheer</h1>
          <div class="hero-sub">
            Oesterperceel No. 369 (Bol van Lodijke, 12,5 ha) • Kasteel Lodijke (-3,20m NAP) • Molenplaat (150 ha) • Stamreeks I0103 &amp; I0120
          </div>
          <div class="hero-btn-group">
            <button class="hero-cta" @click="switchTab('woosporen')">
              Bekijk de {{ wooSporen.length }} Woo-Sporen
            </button>
            <button class="hero-cta secondary-cta" @click="focusPerceel369">
              📍 Centreer Perceel No. 369 op Kaart
            </button>
          </div>
        </section>

        <main class="main-container">

          <!-- 1. GEODETISCHE KAARTWEERGAVE & PERCEEL NO. 369 -->
          <section v-show="activeMainTab === 'overzicht' || activeMainTab === 'gis'" id="gis" class="card-section">
            <div class="section-header-flex">
              <div>
                <h2 class="section-title">📍 Geodetische Kaartweergave &amp; Perceel No. 369</h2>
                <p class="section-subtitle">
                  Oesterperceel No. 369 op de Bol van Lodijke (12,5 ha, RD X=68120 Y=388050) van Reder Benjamin Willem Schot (1840–1935).
                </p>
              </div>
              <div class="map-status-pill" :class="{ ready: mapReady }">
                {{ mapReady ? '✔ Kaart & PDOK Lagen Geladen' : '⏳ Kaarttegels laden...' }}
              </div>
            </div>

            <div class="map-toolbar">
              <div class="layer-group">
                <strong>Basiskaart:</strong>
                <button :class="{ active: baseMode === 'osm' }" @click="setBaseLayer('osm')">OpenStreetMap (Snel)</button>
                <button :class="{ active: baseMode === 'pdok_brt' }" @click="setBaseLayer('pdok_brt')">PDOK Topografisch (BRT)</button>
                <button :class="{ active: baseMode === 'ortho' }" @click="setBaseLayer('ortho')">PDOK Luchtfoto (25cm)</button>
              </div>
              <div class="layer-group">
                <strong>Overlays:</strong>
                <label><input type="checkbox" v-model="overlays.kadaster" @change="syncOverlays" /> PDOK Kadastrale Kaart v5</label>
                <label><input type="checkbox" v-model="overlays.ahn" @change="syncOverlays" /> PDOK AHN4 Diepte/Hoogte</label>
                <label><input type="checkbox" v-model="overlays.molenplaat" @change="syncOverlays" /> Molenplaat (150 ha)</label>
              </div>
              <div class="layer-group">
                <button class="recenter-btn" @click="focusPerceel369">🎯 Perceel 369</button>
              </div>
            </div>

            <div class="map-frame" ref="mapWrapperEl">
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

          <!-- 2. DE 6 WOO-SPOREN (A t/m F) MET DELETE KNOPPEN & SLIDING DOSSIER -->
          <section v-show="activeMainTab === 'overzicht' || activeMainTab === 'woosporen'" id="woosporen" class="card-section">
            <div class="section-header-flex">
              <div>
                <h2 class="section-title">⚖️ De 6 Woo-Sporen (A t/m F) — Dossier &amp; Bewijsvoering</h2>
                <p class="section-subtitle">
                  Klik op een spoor om de bijbehorende archiefstukken, kadastrale leggers en GraphQL-records (:8082) in te zien of op de kaart te lokaliseren.
                </p>
              </div>
              <button class="btn-restore" @click="restoreDefaultSporen">
                ↺ Herstel 6 Sporen ({{ wooSporen.length }}/6)
              </button>
            </div>

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
              <div v-for="spoor in filteredWooSporen" :key="spoor.code" class="spoor-card">
                <div>
                  <div class="spoor-header">
                    <span class="spoor-badge">{{ spoor.code }}</span>
                    <span class="spoor-status">{{ spoor.status }}</span>
                    <button
                      class="btn-card-delete"
                      @click.stop="deleteSpoorByCode(spoor.code)"
                      :title="`Verwijder ${spoor.code}`"
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
                    📄 Open Dossier ({{ spoor.ref }})
                  </button>
                </div>
              </div>
            </div>
          </section>

          <!-- 3. DE 6 GEÏNTEGREERDE MAPPENBOMEN (VOLLEDIGE MASTER-VERZAMELING) -->
          <section v-show="activeMainTab === 'overzicht' || activeMainTab === 'mappenboom'" id="mappenboom" class="card-section">
            <TabMappenbomen />
          </section>

          <!-- 4. HISTORISCH VISSERIJDOSSIER BEOOSTEN SCHELDE (API, RSS, PODCASTS) -->
          <section v-show="activeMainTab === 'overzicht' || activeMainTab === 'beoostenschelde'" id="beoostenschelde" class="card-section">
            <div class="section-header-flex">
              <div>
                <h2 class="section-title">📡 Historisch Visserijdossier Beoosten Schelde — API's, RSS, Podcasts &amp; Lokale Media</h2>
                <p class="section-subtitle">
                  Koppeling met kadastrale/hydrografische API-providers, de lokale Rust Axum Podcast/RSS-server (<code>:8081</code>) en historische bronnen uit Tholen, Sint-Maartensdijk, Scherpenisse, Yerseke en Reimerswaal.
                </p>
              </div>
            </div>

            <div class="sub-tabs-bar">
              <button :class="['sub-tab', mediaSubTab === 'apis' ? 'active' : '']" @click="mediaSubTab = 'apis'">
                🔌 API Providers &amp; Geodata Endpoints ({{ apiProviders.length }})
              </button>
              <button :class="['sub-tab', mediaSubTab === 'rss' ? 'active' : '']" @click="mediaSubTab = 'rss'">
                📰 RSS Reader Beoosten Schelde ({{ rssItems.length }})
              </button>
              <button :class="['sub-tab', mediaSubTab === 'podcasts' ? 'active' : '']" @click="mediaSubTab = 'podcasts'">
                🎙️ Podcasts &amp; Audio-Archief (:8081)
              </button>
              <button :class="['sub-tab', mediaSubTab === 'media' ? 'active' : '']" @click="mediaSubTab = 'media'">
                🗞️ Lokale Media &amp; Visserijkroniek (1530–2026)
              </button>
            </div>

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
                  <a :href="api.endpoint" target="_blank" rel="noopener noreferrer" class="link-btn">⚡ Open Endpoint ↗</a>
                </div>
              </div>
            </div>

            <div v-if="mediaSubTab === 'rss'" class="rss-layout">
              <div class="rss-sidebar">
                <h4>KANALEN BEOOSTEN SCHELDE</h4>
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
                <div v-for="item in filteredRssItems" :key="item.id" class="rss-article">
                  <div class="rss-article-header">
                    <span class="rss-source-tag">{{ item.bron }}</span>
                    <span class="rss-date">{{ item.datum }}</span>
                    <button class="btn-card-delete" @click="deleteRssItem(item.id)">🗑️ Verwijder</button>
                  </div>
                  <h4>{{ item.titel }}</h4>
                  <p>{{ item.samenvatting }}</p>
                  <div class="rss-meta-links">
                    <span class="woo-chip">{{ item.dossierKoppeling }}</span>
                    <button class="link-btn secondary" @click="focusPerceel369">📍 Toon op GIS-Kaart</button>
                  </div>
                </div>
              </div>
            </div>

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
                    {{ activeAudio && activeAudio.id === pod.id ? '⏸ Stream Actief' : '▶ Start Audio (:8081)' }}
                  </button>
                  <code class="stream-path">{{ pod.streamUrl }}</code>
                </div>
              </div>
            </div>

            <div v-if="mediaSubTab === 'media'" class="grid-3">
              <div v-for="(krant, idx) in lokaleMediaArchief" :key="krant.id" class="media-card">
                <div class="spoor-header">
                  <span class="spoor-badge">{{ krant.jaar }}</span>
                  <span class="spoor-status">{{ krant.publicatie }}</span>
                  <button class="btn-card-delete" @click="lokaleMediaArchief.splice(idx, 1)">🗑️</button>
                </div>
                <h3>{{ krant.kop }}</h3>
                <p>{{ krant.citaat }}</p>
                <div class="spoor-footer">
                  <span class="woo-chip">{{ krant.locatie }}</span>
                  <button class="link-btn secondary" @click="switchTab('mappenboom')">📂 Bekijk in Mappenboom</button>
                </div>
              </div>
            </div>
          </section>

        </main>
      </div>
    </div>

    <!-- RECHTER SLIDING DOSSIER INSPECTOR (WIT MET MEEKRAP ACCENTEN) -->
    <transition name="slide-right">
      <aside v-if="activeDrawerSpoor" class="sliding-drawer right-drawer">
        <div class="drawer-header">
          <div>
            <span class="spoor-badge">{{ activeDrawerSpoor.code }}</span>
            <h3 style="margin: 6px 0 0 0; color: #7f1d1d;">{{ activeDrawerSpoor.titel }}</h3>
          </div>
          <button class="close-drawer-btn" @click="activeDrawerSpoor = null">✕</button>
        </div>

        <div class="drawer-body">
          <div class="meta-strip">
            <span><strong>Referentie:</strong> {{ activeDrawerSpoor.ref }}</span>
            <span><strong>Status:</strong> {{ activeDrawerSpoor.status }}</span>
          </div>

          <p class="drawer-lead">{{ activeDrawerSpoor.beschrijving }}</p>

          <h4 style="color: #8b1a1a;">📜 Primair Historisch &amp; Juridisch Bewijs</h4>
          <ul class="evidence-list">
            <li v-for="(stuk, i) in activeDrawerSpoor.bewijsstukken" :key="i">
              📄 {{ stuk }}
            </li>
          </ul>

          <h4 style="color: #8b1a1a;">🔗 Gekoppelde API &amp; Geodetische Query</h4>
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
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount, nextTick } from 'vue'
import L from 'leaflet'
import TabMappenbomen from './components/TabMappenbomen.vue'

const activeMainTab = ref('overzicht')
// LINKER PANEEL STANDAARD GEOPEND ZOALS GEVRAAGD
const leftDrawerOpen = ref(true)
const activeDrawerSpoor = ref(null)
const spoorFilter = ref('ALLE')
const mediaSubTab = ref('apis')
const selectedRssChannel = ref('ALLE')
const activeAudio = ref(null)

const mapEl = ref(null)
const mapWrapperEl = ref(null)
const mapReady = ref(false)
const baseMode = ref('osm')

const cursorRd = ref({ x: 68120, y: 388050 })
const cursorWgs = ref({ lat: '51.47633', lng: '4.13750' })

const overlays = ref({
  kadaster: true,
  ahn: false,
  molenplaat: true
})

const initialWooSporen = () => [
  {
    code: 'SPOOR A',
    categorie: 'VISSERIJ',
    ref: 'WOO-369-SCHOT',
    titel: 'Oesterperceel No. 369 — Bol van Lodijke (12,5 ha)',
    status: 'Gevalideerd',
    beschrijving: 'Historische concessie en kadastrale legger van Reder Benjamin Willem Schot (1840–1935), omvattende 11 oesterputten t.v.v. Yerseke op RD X=68120, Y=388050.',
    lat: 51.47633,
    lng: 4.13750,
    zoom: 15,
    bewijsstukken: [
      'Concessieakte_Benjamin_Willem_Schot_1892_1915.pdf (12,5 ha Bol van Lodijke)',
      'Scheepsmeetbrieven_Hoogaarzen_TH2_TH12_TH90.pdf (Werf Van Duivendijk, Tholen)',
      'Veilingcatalogus_203_Percelen_Schelpdierenvisserij.pdf (Middelburg 22–24 nov 1892)'
    ],
    graphqlQuery: '{ geoParcels(parcelId: "PERCEEL-369") { naam rdX rdY oppervlakteHa napDiepteM } }'
  },
  {
    code: 'SPOOR B',
    categorie: 'ERFGOED',
    ref: 'ARC-LOD-01',
    titel: 'Kasteel Lodijke & Verdronken Dorp (-3,20m NAP)',
    status: 'Archeologisch Anker',
    beschrijving: 'Geodetische en archeologische vastlegging van de fundamenten van Kasteel Lodijke op -3,20m NAP na de Sint-Felixvloed (1530) en Uitspraak BRE 24/5455.',
    lat: 51.47310,
    lng: 4.13620,
    zoom: 15,
    bewijsstukken: [
      'Sonar_&_Duikrapport_Goyvaerts_2005.pdf & Kloostermoppen_Tufsteen_NAP_min3m20.json',
      'Slag_bij_Lodijke_1301_Melis_Stoke.md & Sint_Felixvloed_1530_Quade_Saterdach.md',
      'Uitspraak_Rechtbank_ZWB_09-10-2025_ECLI_NL_RBZWB_2025_6823.pdf (BRE 24/5455)'
    ],
    graphqlQuery: '{ geoParcels(parcelId: "ARC-LOD-01") { naam rdX rdY napDiepteM wooReferentie } }'
  },
  {
    code: 'SPOOR C',
    categorie: 'VISSERIJ',
    ref: 'WOO-MOL-150',
    titel: 'Visserijpercelen Molenplaat (150 ha) & BRP Auditlogs',
    status: 'Actief Woo-Dossier',
    beschrijving: 'Percelen rondom de Molenplaat (150 ha, Zaak 1456324) en forensische BRP/Makelaarsuite auditlogs (Zaak 1463739).',
    lat: 51.49650,
    lng: 4.19450,
    zoom: 14,
    bewijsstukken: [
      'Dossier_Zuurdeeg_Historische_Pachtkaarten.pdf & Retributieregister_Molenplaat_1873_1964.csv',
      'BRP_GBA_V_Auditlogs_11-01-2017_24-04-2017.csv & Makelaarsuite_Chronologie_11-03-2024.json',
      'Zaak_Z2026-00003749_Leidingstraat_Molenplaat.pdf (Provincie Noord-Brabant & OMWB)'
    ],
    graphqlQuery: '{ cmsRecords(code: "WOO-MOL-150") { titel datum status } }'
  },
  {
    code: 'SPOOR D',
    categorie: 'ERFGOED',
    ref: 'GRAMPS-I0103',
    titel: 'Stamreeks B.W. Schot (I0103), W. Bout (I0120) & C.M. Guiljam (I0121)',
    status: 'Genealogisch Bewijs',
    beschrijving: 'Directe 500-jarige afstammingslijn en erfrechtelijke verankering vanuit Sint-Maartensdijk, Tholen en het Verdronken Land van Reimerswaal.',
    lat: 51.52650,
    lng: 4.08150,
    zoom: 13,
    bewijsstukken: [
      'stamboom_schot_bout.ged & kwartierstaat_I0103.json (B.W. Schot 1840–1935)',
      'I0120_Willem_Bout_1966.json & I0121_C_M_Guiljam.json',
      'Herverkaveling_Tholen_1964_Platteweg_E108_W_Bout.pdf (Waal-arrest)'
    ],
    graphqlQuery: '{ grampsCore(grampsId: "I0103") { grampsId naam beroepStatus relatieReimerswaal } }'
  },
  {
    code: 'SPOOR E',
    categorie: 'VISSERIJ',
    ref: 'REI-VISRECHT',
    titel: 'Oudelandse Visrechten, Stad Reimerswaal & Bezwaar Zaak 1425030',
    status: 'Historisch Recht',
    beschrijving: '14e- en 16e-eeuwse charters en visrechten binnen de grenzen van de stad Reimerswaal (Rijksmonument) en Advies Bezwaarschriftencommissie 28-08-2026.',
    lat: 51.48660,
    lng: 4.16140,
    zoom: 14,
    bewijsstukken: [
      'Advies_Bezwaarschriftencommissie_28-08-2026.pdf (Zaak 1425030)',
      'Formele_Ingebrekestelling_IGS-2026-1122_22-11-2026.pdf & Brief 1504535',
      'Erfgoedwet_Aanwijzing_RCE_Sept_2017.pdf (Rijksmonument Verdronken Stad Reimerswaal)'
    ],
    graphqlQuery: '{ geoParcels(parcelId: "STAD-REIMERSWAAL") { naam oppervlakteHa rdX rdY } }'
  },
  {
    code: 'SPOOR F',
    categorie: 'BESTUURSRECHT',
    ref: 'AWB-MER-2026',
    titel: 'Belanghebbende Status (Awb / m.e.r.) & Provincie Zeeland Zaak 417521',
    status: 'Onherroepelijk',
    beschrijving: 'Formeel vastgestelde belanghebbendestatus onder de Awb, de provinciale doorzendketen ex art. 4.2 Woo (Zaak 417521) en het Verdrag van Aarhus.',
    lat: 51.47633,
    lng: 4.13750,
    zoom: 13,
    bewijsstukken: [
      'Doorzendsommatie_PM-02_Visserij_&_Erfgoed_Zaak_417521.pdf (Gedeputeerde Staten Zeeland)',
      'Inhoudelijke_Afbakeningsmatrix_PM-01_24-10-2026.pdf',
      'Natura2000_LIFE_Oosterschelde_Beheersplan.pdf & Aarhus-verdrag'
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

const apiProviders = ref([
  {
    id: 'api-axum',
    naam: 'Lodijke Rust Axum GraphQL API',
    protocol: 'GraphQL / HTTP',
    status: 'ONLINE (:8082)',
    endpoint: 'http://localhost:8082/graphql',
    toepassing: 'Levert grampsCore (I0103–I0121), geoParcels (Perceel 369, Kasteel Lodijke, Molenplaat) en cmsRecords.'
  },
  {
    id: 'api-pdok-brk',
    naam: 'PDOK Kadastrale Kaart WMS v5.0',
    protocol: 'OGC WMS 1.3.0',
    status: 'ACTIEF (EPSG:28992)',
    endpoint: 'https://service.pdok.nl/kadaster/kadastralekaart/wms/v5_0?request=GetCapabilities&service=WMS',
    toepassing: 'Kadastrale perceelgrenzen voor Yerseke, Reimerswaal, Tholen, Schakerloo en Scherpenisse (E 108).'
  },
  {
    id: 'api-pdok-ortho',
    naam: 'PDOK Luchtfoto Actueel Ortho 25cm WMTS',
    protocol: 'OGC WMTS REST',
    status: 'SNELLE TEGELS',
    endpoint: 'https://service.pdok.nl/hwh/luchtfotorgb/wmts/v1_0?request=GetCapabilities&service=WMTS',
    toepassing: 'Direct gecachete 25cm luchtfoto-tegels van de Bol van Lodijke, Molenplaat en Bergse Diepsluis.'
  },
  {
    id: 'api-solid-pod',
    naam: 'W3C Solid POD Vault (Tholen Erfgoed)',
    protocol: 'W3C Solid / RDF',
    status: 'ACTIEF',
    endpoint: 'https://solid.tholen-erfgoed.nl/profile/card#me',
    toepassing: 'Decentrale datakluis met publieke GeoJSON-percelen en AVG-afgeschermde kwartierstaten.'
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
    titel: 'Kadastrale verificatie Oesterperceel No. 369 (12,5 ha) & Vloot TH 2, TH 12, TH 90',
    samenvatting: 'De concessieakte (1892–1915) en retributiekwitanties (1892–1935) van B.W. Schot zijn gekoppeld aan de scheepsmeetbrieven van Werf Van Duivendijk.',
    dossierKoppeling: 'SPOOR A (PERCEEL-369)'
  },
  {
    id: 'rss-2',
    channel: 'THOLEN',
    bron: 'Bestuursrechtelijke Monitor Gemeente Tholen & Provincie Zeeland',
    datum: '24 okt 2026',
    titel: 'Inhoudelijke Afbakeningsmatrix PM-01 & Doorzendsommatie PM-02 (Zaak 417521)',
    samenvatting: 'Volledige koppeling tussen Hoofdzaak 1456324 (Molenplaat/Zuurdeeg), Bezwaar 1425030 en de provinciale doorzendketen ex art. 4.2 Woo.',
    dossierKoppeling: 'SPOOR D / E / F'
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
    titel: 'De Oesterputten van Benjamin Willem Schot (Perceel 369 & De Hoogaarzen TH 2, TH 12, TH 90)',
    duur: '28:14',
    bronServer: 'Rust Axum :8081',
    streamUrl: 'http://localhost:8081/streams/aflevering01_perceel369_schot.mp3',
    beschrijving: 'Reconstructie van de oesterpachtveiling in Middelburg (22–24 november 1892) en de oesterloods Schot & Kegge aan de Contre-Escarpe te Tholen.'
  },
  {
    id: 'pod-2',
    reeks: 'AFLEVERING 02 • ARCHIEF & RECHT',
    titel: 'Het Dossier-Zuurdeeg, het Waal-Arrest en 500 Jaar Stamlijn Bout–Schot',
    duur: '34:40',
    bronServer: 'Rust Axum :8081',
    streamUrl: 'http://localhost:8081/streams/aflevering02_visrecht_zuurdeeg.mp3',
    beschrijving: 'Juridische en historisch-cartografische analyse van de 150 ha visserijpercelen op de Molenplaat en de ruilverkaveling van 1964 (Platteweg E 108).'
  }
])

const lokaleMediaArchief = ref([
  {
    id: 'med-1',
    jaar: '1892–1913',
    publicatie: 'Bestuur der Visserijen / Gemeente Tholen',
    locatie: 'Bol van Lodijke & Contre-Escarpe Tholen',
    kop: 'Concessie Perceel No. 369 (12,5 ha) & Oesterloods Schot en Kegge',
    citaat: 'Toewijzing van Oesterperceel No. 369 op de Bol van Lodijke aan B.W. Schot (1840–1935) en exploitatie met de hoogaarzen TH 2 Eben Haëzer, TH 12 en TH 90.'
  },
  {
    id: 'med-2',
    jaar: '1301–1532',
    publicatie: 'Kroniek Melis Stoke & Vierlingh',
    locatie: 'Kasteel & Ambacht Lodijke (-3,20m NAP)',
    kop: 'Van de Slag bij Lodijke (1301) tot Quade Saterdach (1530)',
    citaat: 'Onderwaterarcheologisch ankerpunt ARC-LOD-01 met kloostermoppen en tufsteen op -3,20m NAP en loodzegels op de oesterbanken (ARC-LOD-02).'
  }
])

// LEAFLET KAART ENGINE
let map = null
let resizeObserver = null
let baseTileLayers = {}
let overlayLayers = {}
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

function initLeafletMap() {
  if (!mapEl.value) return
  if (map) {
    map.remove()
    map = null
  }

  const centerLat = 51.47633
  const centerLng = 4.13750

  map = L.map(mapEl.value, {
    center: [centerLat, centerLng],
    zoom: 14,
    preferCanvas: true,
    zoomControl: true
  })

  baseTileLayers.osm = L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    crossOrigin: true,
    updateWhenIdle: false,
    keepBuffer: 4,
    attribution: '&copy; OpenStreetMap | PDOK | Lodijke Platform'
  })

  baseTileLayers.pdok_brt = L.tileLayer(
    'https://service.pdok.nl/brt/achtergrondkaart/wmts/v2_0/standaard/EPSG:3857/{z}/{x}/{y}.png',
    { maxZoom: 19, crossOrigin: true, attribution: 'PDOK BRT Achtergrondkaart' }
  )

  baseTileLayers.ortho = L.tileLayer(
    'https://service.pdok.nl/hwh/luchtfotorgb/wmts/v1_0/Actueel_orthoHR/EPSG:3857/{z}/{x}/{y}.jpeg',
    { maxZoom: 19, crossOrigin: true, attribution: 'PDOK Luchtfoto 25cm WMTS' }
  )

  baseTileLayers.osm.on('load', () => { mapReady.value = true })
  baseTileLayers.osm.addTo(map)

  overlayLayers.kadaster = L.tileLayer.wms('https://service.pdok.nl/kadaster/kadastralekaart/wms/v5_0', {
    layers: 'KadastraleGrens,Perceel,Nummeraanduidingreeks',
    format: 'image/png',
    transparent: true,
    version: '1.3.0',
    crs: L.CRS.EPSG3857,
    opacity: 0.85,
    attribution: 'Kadaster v5'
  })

  overlayLayers.ahn = L.tileLayer.wms('https://service.pdok.nl/rws/ahn/wms/v1_0', {
    layers: 'dsm_05m',
    format: 'image/png',
    transparent: true,
    version: '1.3.0',
    crs: L.CRS.EPSG3857,
    opacity: 0.55,
    attribution: 'PDOK AHN4'
  })

  const perceel369Bounds = [
    [51.4745, 4.1335],
    [51.4745, 4.1415],
    [51.4782, 4.1415],
    [51.4782, 4.1335]
  ]
  L.polygon(perceel369Bounds, {
    color: '#8b1a1a',
    weight: 2.5,
    fillColor: '#b91c1c',
    fillOpacity: 0.32
  }).addTo(map)

  perceel369Marker = L.circleMarker([centerLat, centerLng], {
    radius: 9,
    color: '#ffffff',
    weight: 2.5,
    fillColor: '#8b1a1a',
    fillOpacity: 1
  })
    .addTo(map)
    .bindPopup(
      `<div>
        <strong>Oesterperceel No. 369 (12,5 ha)</strong><br/>
        Bol van Lodijke | Reder B.W. Schot (1840–1935)<br/>
        Vloot: TH 2, TH 12 &amp; TH 90 | 11x "Oesterputten"
      </div>`,
      { className: 'custom-red-popup', closeButton: false, autoClose: false }
    )
    .openPopup()

  L.circleMarker([51.4731, 4.1362], {
    radius: 8,
    color: '#ffffff',
    weight: 2,
    fillColor: '#d97706',
    fillOpacity: 0.95
  })
    .addTo(map)
    .bindPopup(
      `<div>
        <strong>Kasteel Lodijke (ARC-LOD-01)</strong><br/>
        Diepte: -3,20m NAP | Kloostermoppen &amp; Tufsteen
      </div>`,
      { className: 'custom-red-popup' }
    )

  L.circleMarker([51.4866, 4.1614], {
    radius: 8,
    color: '#ffffff',
    weight: 2,
    fillColor: '#2563eb',
    fillOpacity: 0.95
  })
    .addTo(map)
    .bindPopup(
      `<div>
        <strong>Verdronken Stad Reimerswaal (G-01)</strong><br/>
        Diepte: -1,50m NAP | Rijksmonument RCE
      </div>`,
      { className: 'custom-red-popup' }
    )

  overlayLayers.molenplaat = L.polygon(
    [
      [51.4910, 4.1820],
      [51.4910, 4.2070],
      [51.5020, 4.2070],
      [51.5020, 4.1820]
    ],
    {
      color: '#0284c7',
      weight: 2.5,
      fillColor: '#38bdf8',
      fillOpacity: 0.25
    }
  ).bindPopup(
    `<div>
      <strong>Visserijpercelen Molenplaat (150 ha)</strong><br/>
      Dossier-Zuurdeeg | Woo-Hoofdzaak 1456324
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

  if (window.ResizeObserver && mapWrapperEl.value) {
    resizeObserver = new ResizeObserver(() => {
      if (map) map.invalidateSize({ animate: false })
    })
    resizeObserver.observe(mapWrapperEl.value)
  }

  setTimeout(() => {
    if (map) {
      map.invalidateSize()
      mapReady.value = true
      if (perceel369Marker) perceel369Marker.openPopup()
    }
  }, 150)
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
    const layer = overlayLayers[key]
    if (!layer) return
    if (overlays.value[key]) {
      if (!map.hasLayer(layer)) map.addLayer(layer)
    } else {
      if (map.hasLayer(layer)) map.removeLayer(layer)
    }
  })
}

function switchTab(tabName) {
  activeMainTab.value = tabName
  nextTick(() => {
    if (map) map.invalidateSize()
  })
}

function flyToLocation(lat, lng, zoom = 15) {
  switchTab('overzicht')
  nextTick(() => {
    if (map) {
      map.invalidateSize()
      map.flyTo([lat, lng], zoom, { duration: 0.7 })
    }
  })
}

function focusPerceel369() {
  flyToLocation(51.47633, 4.13750, 15)
  setTimeout(() => {
    if (perceel369Marker) perceel369Marker.openPopup()
  }, 750)
}

function zoomToSpoor(spoor) {
  activeDrawerSpoor.value = null
  flyToLocation(spoor.lat, spoor.lng, spoor.zoom || 15)
}

onMounted(async () => {
  await nextTick()
  initLeafletMap()
})

onBeforeUnmount(() => {
  if (resizeObserver) resizeObserver.disconnect()
  if (map) map.remove()
})
</script>

<style scoped>
/* MEEKRAP-RODE TOP NAVBAR */
.navbar {
  background: #7f1d1d;
  border-bottom: 2px solid #5c1111;
  color: #ffffff;
  position: sticky;
  top: 0;
  z-index: 2500;
  box-shadow: 0 2px 10px rgba(0,0,0,0.25);
}
.nav-container {
  max-width: 1600px;
  margin: 0 auto;
  padding: 10px 20px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 10px;
}
.brand-left { display: flex; align-items: center; gap: 12px; }
.hamburger-btn {
  background: #ffffff;
  color: #7f1d1d;
  border: 1px solid #fecaca;
  border-radius: 6px;
  font-size: 0.8rem;
  font-weight: 800;
  padding: 6px 12px;
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
}
.nav-btn:hover { background: rgba(255,255,255,0.14); color: #fff; }
.nav-btn.active-pill { background: #ffffff; color: #7f1d1d; font-weight: 700; }
.count-pill {
  background: #991b1b;
  color: #fff;
  padding: 1px 6px;
  border-radius: 10px;
  font-size: 0.72rem;
  margin-left: 4px;
}

/* FLEX LAYOUT MET PERMANENT GEOPEND WIT & MEEKRAP-ROOD LINKERPANEEL */
.platform-body {
  display: flex;
  align-items: stretch;
  min-height: calc(100vh - 56px);
}

.meekrap-left-panel {
  width: 320px;
  min-width: 320px;
  background: #ffffff;
  color: #1e293b;
  border-right: 3px solid #8b1a1a;
  box-shadow: 4px 0 18px rgba(139, 26, 26, 0.08);
  padding: 18px 16px;
  display: flex;
  flex-direction: column;
  gap: 18px;
  position: sticky;
  top: 56px;
  height: calc(100vh - 56px);
  overflow-y: auto;
  z-index: 1500;
}
.meekrap-panel-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  border-bottom: 2px solid #8b1a1a;
  padding-bottom: 12px;
}
.meekrap-kicker {
  display: block;
  font-size: 0.68rem;
  font-weight: 800;
  color: #b91c1c;
  letter-spacing: 0.7px;
}
.meekrap-panel-header h3 {
  margin: 2px 0 0 0;
  font-size: 1.02rem;
  color: #7f1d1d;
}
.meekrap-close-btn {
  background: #fef2f2;
  color: #8b1a1a;
  border: 1px solid #fca5a5;
  border-radius: 5px;
  padding: 3px 8px;
  cursor: pointer;
  font-weight: bold;
}
.meekrap-section h4 {
  margin: 0 0 8px 0;
  font-size: 0.73rem;
  font-weight: 800;
  color: #8b1a1a;
  letter-spacing: 0.5px;
  text-transform: uppercase;
}
.meekrap-nav-list {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 5px;
}
.meekrap-nav-list li {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 11px;
  border-radius: 6px;
  background: #fdf8f8;
  border: 1px solid #f2dada;
  color: #334155;
  font-size: 0.84rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s;
}
.meekrap-nav-list li:hover {
  background: #fef2f2;
  border-color: #8b1a1a;
  color: #7f1d1d;
}
.meekrap-nav-list li.active {
  background: #8b1a1a;
  border-color: #651212;
  color: #ffffff;
}
.meekrap-nav-list li.active .meekrap-tag {
  background: #ffffff;
  color: #8b1a1a;
}
.meekrap-tag {
  font-size: 0.68rem;
  font-weight: 700;
  background: #fee2e2;
  color: #8b1a1a;
  padding: 2px 6px;
  border-radius: 10px;
}
.meekrap-sub-list {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.meekrap-sub-list li {
  padding: 6px 9px;
  border-left: 3px solid #8b1a1a;
  background: #fdf8f8;
  font-size: 0.78rem;
  color: #7f1d1d;
  cursor: pointer;
  border-radius: 0 4px 4px 0;
}
.meekrap-sub-list li:hover { background: #fee2e2; }
.meekrap-footer-card {
  background: #fdf8f8;
  border: 1px solid #e5c5c5;
  border-top: 3px solid #8b1a1a;
  border-radius: 6px;
  padding: 12px;
  margin-top: auto;
}
.meekrap-kv {
  display: flex;
  justify-content: space-between;
  font-size: 0.76rem;
  padding: 4px 0;
  border-bottom: 1px dashed #edd5d5;
  color: #475569;
}
.meekrap-kv strong { color: #7f1d1d; }
.meekrap-online { color: #15803d !important; }

.content-column {
  flex: 1;
  min-width: 0;
  background: #f8f9fa;
}

/* RECHTER SLIDING DOSSIER DRAWER (WIT & MEEKRAP) */
.sliding-drawer.right-drawer {
  position: fixed;
  top: 56px;
  right: 0;
  bottom: 0;
  width: 440px;
  max-width: 92vw;
  background: #ffffff;
  color: #1e293b;
  border-left: 3px solid #8b1a1a;
  z-index: 3000;
  box-shadow: -10px 0 30px rgba(139, 26, 26, 0.2);
  display: flex;
  flex-direction: column;
  overflow-y: auto;
  padding: 20px;
}
.drawer-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  border-bottom: 2px solid #8b1a1a;
  padding-bottom: 12px;
  margin-bottom: 16px;
}
.close-drawer-btn {
  background: #fef2f2;
  color: #8b1a1a;
  border: 1px solid #fca5a5;
  border-radius: 5px;
  padding: 4px 9px;
  cursor: pointer;
}
.meta-strip { display: flex; gap: 14px; font-size: 0.8rem; color: #475569; margin-bottom: 10px; }
.drawer-lead { font-size: 0.88rem; color: #1e293b; line-height: 1.5; }
.evidence-list { padding-left: 18px; font-size: 0.84rem; color: #334155; line-height: 1.6; }
.code-snippet {
  background: #fdf8f8;
  color: #8b1a1a;
  border: 1px solid #e5c5c5;
  padding: 10px;
  border-radius: 6px;
  font-size: 0.76rem;
  overflow-x: auto;
}
.drawer-actions { display: flex; gap: 10px; margin-top: 16px; }
.slide-right-enter-active, .slide-right-leave-active { transition: transform 0.22s ease, opacity 0.22s ease; }
.slide-right-enter-from, .slide-right-leave-to { transform: translateX(100%); opacity: 0; }

/* HERO BANNER */
.hero-banner {
  background: linear-gradient(180deg, #651212 0%, #8b1a1a 100%);
  color: #ffffff;
  text-align: center;
  padding: 30px 20px;
  border-bottom: 3px solid #991b1b;
}
.hero-banner h1 { margin: 0 0 8px 0; font-size: 1.75rem; font-weight: 700; }
.hero-sub { font-size: 0.88rem; color: #fecaca; margin-bottom: 16px; }
.hero-btn-group { display: flex; justify-content: center; gap: 12px; flex-wrap: wrap; }
.hero-cta {
  background: #ffffff;
  color: #7f1d1d;
  border: none;
  padding: 9px 18px;
  font-size: 0.85rem;
  font-weight: 700;
  border-radius: 6px;
  cursor: pointer;
}
.hero-cta.secondary-cta {
  background: rgba(0,0,0,0.28);
  color: #ffffff;
  border: 1px solid #fca5a5;
}

/* MAIN CONTAINER & KAART */
.main-container { max-width: 1220px; margin: 0 auto; padding: 22px 20px 60px; }
.card-section {
  background: #ffffff;
  border: 1px solid #e5d5d5;
  border-radius: 10px;
  padding: 20px;
  margin-bottom: 26px;
  box-shadow: 0 4px 14px rgba(139, 26, 26, 0.04);
}
.section-header-flex {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  flex-wrap: wrap;
  gap: 12px;
  margin-bottom: 12px;
}
.section-title { margin: 0 0 4px 0; color: #8b1a1a; font-size: 1.2rem; }
.section-subtitle { margin: 0; color: #475569; font-size: 0.87rem; }

.map-status-pill {
  font-size: 0.75rem;
  font-weight: 700;
  padding: 5px 12px;
  border-radius: 20px;
  background: #fef3c7;
  color: #92400e;
}
.map-status-pill.ready { background: #dcfce7; color: #166534; }

.map-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
  background: #fdf8f8;
  border: 1px solid #f2dada;
  padding: 10px 14px;
  border-radius: 8px;
  margin-bottom: 12px;
  font-size: 0.82rem;
}
.layer-group { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.layer-group button {
  background: #ffffff;
  border: 1px solid #d4a5a5;
  color: #7f1d1d;
  padding: 5px 10px;
  border-radius: 5px;
  cursor: pointer;
  font-size: 0.78rem;
  font-weight: 600;
}
.layer-group button.active { background: #8b1a1a; color: #ffffff; border-color: #8b1a1a; }
.recenter-btn { background: #8b1a1a !important; color: #ffffff !important; font-weight: 700; }

.map-frame {
  position: relative;
  width: 100%;
  height: 500px;
  min-height: 500px;
  border-radius: 8px;
  overflow: hidden;
  border: 2px solid #8b1a1a;
  background: #cad2d3;
}
#lodijke-leaflet-map {
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  width: 100%; height: 100%;
}
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

/* SUB-TABS & CARDS */
.sub-tabs-bar {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  margin-bottom: 18px;
  border-bottom: 2px solid #fdf2f2;
  padding-bottom: 10px;
}
.sub-tab {
  background: #fdf8f8;
  color: #7f1d1d;
  border: 1px solid #d4a5a5;
  padding: 7px 14px;
  border-radius: 6px;
  font-size: 0.82rem;
  font-weight: 700;
  cursor: pointer;
}
.sub-tab.active { background: #8b1a1a; color: #ffffff; border-color: #8b1a1a; }
.btn-restore {
  background: #8b1a1a;
  color: #ffffff;
  border: none;
  padding: 7px 13px;
  border-radius: 6px;
  font-size: 0.8rem;
  font-weight: 700;
  cursor: pointer;
}
.grid-3 { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 16px; }
.grid-2 { display: grid; grid-template-columns: repeat(auto-fit, minmax(380px, 1fr)); gap: 16px; }
.spoor-card, .media-card, .podcast-card {
  border: 1px solid #e5d5d5;
  border-top: 3px solid #8b1a1a;
  border-radius: 8px;
  padding: 16px;
  background: #ffffff;
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
  background: #8b1a1a;
  color: #ffffff;
  font-size: 0.72rem;
  font-weight: 700;
  padding: 2px 8px;
  border-radius: 4px;
}
.api-protocol-badge {
  background: #fdf2f2;
  color: #8b1a1a;
  border: 1px solid #fca5a5;
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
.btn-card-delete:hover, .btn-delete-spoor:hover { background: #dc2626; color: #ffffff; }
.clickable-title { cursor: pointer; margin: 4px 0 8px 0; font-size: 0.98rem; color: #7f1d1d; }
.clickable-title:hover { text-decoration: underline; }
.spoor-card p, .media-card p, .podcast-card p {
  font-size: 0.84rem;
  color: #475569;
  line-height: 1.48;
  margin: 0 0 14px 0;
}
.spoor-footer { display: flex; gap: 8px; flex-wrap: wrap; align-items: center; }
.link-btn {
  background: #8b1a1a;
  color: #ffffff;
  border: none;
  padding: 6px 12px;
  border-radius: 5px;
  font-size: 0.78rem;
  font-weight: 600;
  cursor: pointer;
  text-decoration: none;
}
.link-btn.secondary { background: #fdf2f2; color: #8b1a1a; border: 1px solid #fca5a5; }
.endpoint-url {
  display: block;
  background: #fdf8f8;
  color: #8b1a1a;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 0.74rem;
  margin-bottom: 8px;
  word-break: break-all;
}
.rss-layout { display: grid; grid-template-columns: 240px 1fr; gap: 18px; }
.rss-sidebar { background: #fdf8f8; border: 1px solid #e5d5d5; padding: 12px; border-radius: 8px; }
.rss-sidebar h4 { margin: 0 0 10px 0; font-size: 0.75rem; color: #8b1a1a; }
.rss-channel-item {
  padding: 9px 10px;
  border-radius: 6px;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  margin-bottom: 6px;
  font-size: 0.83rem;
  font-weight: 600;
}
.rss-channel-item small { font-weight: 400; color: #64748b; font-size: 0.72rem; }
.rss-channel-item.active { background: #8b1a1a; color: #ffffff; }
.rss-channel-item.active small { color: #fecaca; }
.rss-article {
  border: 1px solid #e5d5d5;
  border-left: 4px solid #8b1a1a;
  padding: 14px;
  border-radius: 8px;
  margin-bottom: 12px;
  background: #ffffff;
}
.rss-article-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px; }
.rss-source-tag { font-size: 0.75rem; font-weight: 700; color: #8b1a1a; }
.rss-date { font-size: 0.74rem; color: #64748b; }
.rss-article h4 { margin: 4px 0 6px 0; font-size: 0.95rem; color: #1e293b; }
.rss-article p { margin: 0 0 10px 0; font-size: 0.84rem; color: #475569; }
.rss-meta-links { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 8px; }
.woo-chip {
  background: #fef2f2;
  color: #8b1a1a;
  border: 1px solid #fca5a5;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 0.74rem;
  font-weight: 700;
}
.audio-player-bar {
  display: flex;
  align-items: center;
  gap: 10px;
  background: #fdf8f8;
  border: 1px solid #e5c5c5;
  padding: 8px 10px;
  border-radius: 6px;
  flex-wrap: wrap;
}
.play-btn {
  background: #8b1a1a;
  color: #ffffff;
  border: none;
  padding: 5px 10px;
  border-radius: 4px;
  font-weight: 700;
  font-size: 0.76rem;
  cursor: pointer;
}
.stream-path { color: #7f1d1d; font-size: 0.72rem; }
</style>
