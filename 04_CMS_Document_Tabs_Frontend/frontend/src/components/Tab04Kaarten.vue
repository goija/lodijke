<template>
  <div class="gis-container">
    <!-- Header / Control Panel -->
    <header class="gis-header">
      <div class="header-titles">
        <h2>📍 GIS & Geodetische Kaartweergave</h2>
        <p class="subtitle">
          RD (EPSG:28992) & WGS84 Coördinatennetwerk | Perceel 369, Geopark & Historische Zeekaart 1892
        </p>
      </div>
      <div class="layer-controls">
        <button 
          :class="['btn-filter', { active: layers.zeekaart1892 }]" 
          @click="toggleLayer('zeekaart1892')"
        >
          📜 Historische Zeekaart (1892)
        </button>
        <button 
          :class="['btn-filter', { active: layers.perceel369 }]" 
          @click="toggleLayer('perceel369')"
        >
          🦪 Perceel 369 (12,5 ha)
        </button>
        <button 
          :class="['btn-filter', { active: layers.kasteel }]" 
          @click="toggleLayer('kasteel')"
        >
          🏰 Kasteel Lodijke (ARC-LOD-01)
        </button>
        <button 
          :class="['btn-filter', { active: layers.molenplaat }]" 
          @click="toggleLayer('molenplaat')"
        >
          🌾 Molenplaat (150 ha)
        </button>
        <button 
          :class="['btn-filter', { active: layers.geosites }]" 
          @click="toggleLayer('geosites')"
        >
          🌍 UNESCO Geosites
        </button>
      </div>
    </header>

    <!-- Transparantie schuifregelaar voor 1892 Zeekaart -->
    <div class="opacity-bar" v-if="layers.zeekaart1892">
      <label for="opacityRange">🔍 Transparantie Historische Zeekaart (1892): <strong>{{ Math.round(opacity * 100) }}%</strong></label>
      <input 
        id="opacityRange" 
        type="range" 
        min="0.1" 
        max="1.0" 
        step="0.05" 
        v-model="opacity" 
        @input="updateOpacity" 
      />
    </div>

    <!-- Workspace: Map + Sidebar -->
    <div class="gis-workspace" ref="workspaceRef">
      <!-- Leaflet Map Canvas Container -->
      <div id="leaflet-map-canvas" class="map-canvas" ref="mapContainerRef"></div>

      <!-- Detail Sidebar -->
      <aside class="gis-sidebar" v-if="selectedFeature">
        <div class="sidebar-header">
          <span class="badge">{{ selectedFeature.category }}</span>
          <h3>{{ selectedFeature.title }}</h3>
          <button class="btn-close" @click="selectedFeature = null">✕</button>
        </div>

        <div class="sidebar-body">
          <p class="feature-desc">{{ selectedFeature.description }}</p>

          <div class="info-block">
            <h4>📐 Geodetische Coördinaten</h4>
            <ul>
              <li><strong>RD (EPSG:28992):</strong> X={{ selectedFeature.rdX }}, Y={{ selectedFeature.rdY }}</li>
              <li><strong>WGS84:</strong> {{ selectedFeature.lat }}°N, {{ selectedFeature.lng }}°E</li>
              <li><strong>Diepte / Hoogte:</strong> {{ selectedFeature.depth }}</li>
            </ul>
          </div>

          <div class="info-block" v-if="selectedFeature.history">
            <h4>📜 Historische Context & Vloot</h4>
            <p>{{ selectedFeature.history }}</p>
          </div>

          <div class="info-block" v-if="selectedFeature.wooCase">
            <h4>⚖️ Juridische Woo-Koppeling</h4>
            <p><strong>Dossier:</strong> {{ selectedFeature.wooCase }}</p>
            <a href="http://127.0.0.1:8082" target="_blank" class="btn-woo">
              ⚡ Open in GraphQL Studio (:8082)
            </a>
          </div>
        </div>
      </aside>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, nextTick } from 'vue';

const selectedFeature = ref(null);
const opacity = ref(0.70);
const mapContainerRef = ref(null);
const workspaceRef = ref(null);

// Plain non-reactive variables to prevent Vue reactivity proxy bugs with Leaflet
let mapInstance = null;
let layerGroups = {};
let historicalTileLayer = null;
let resizeObserver = null;

const layers = ref({
  zeekaart1892: true,
  perceel369: true,
  kasteel: true,
  molenplaat: true,
  geosites: true
});

const gisFeatures = [
  {
    id: 'p369',
    layerKey: 'perceel369',
    category: 'OESTERCONCESSIE 1892-1935',
    title: 'Oesterperceel No. 369 (Bol van Lodijke)',
    lat: 51.47833,
    lng: 4.13750,
    rdX: 68120,
    rdY: 388050,
    depth: '-2.10m NAP',
    description: '12,5 hectare oesterkweekgronden gepacht door Reder Benjamin Willem Schot (1840–1935). Overeenkomstig de pachtveiling Middelburg 1892.',
    history: 'Vloot hoogaarzen: TH 2 "Eben Haëzer", TH 12 "Niets zonder Gods zegen", TH 90 "Vijf Gebroeders".',
    wooCase: 'Zaak 1456324 (Molenplaat / Visserijrechten B&W Tholen)',
    color: '#a6e3a1'
  },
  {
    id: 'kasteel',
    layerKey: 'kasteel',
    category: 'ONDERWATERARCHEOLOGIE',
    title: 'Kasteel Lodijke (ARC-LOD-01)',
    lat: 51.47700,
    lng: 4.13300,
    rdX: 67800,
    rdY: 387900,
    depth: '-3.20m NAP (tot -20m in Gat van Lodijk)',
    description: 'Verdronken stamslot van de Heren van Reimerswaal. Fundamenten gemeten in 2005 (15x16m kasteelmuur).',
    history: 'Verdronken tijdens de Sint-Felixvloed op 5 november 1530 en Allerheiligenvloed 1532.',
    wooCase: 'Rijksmonument RCE / Erfgoedwet protection',
    color: '#f38ba8'
  },
  {
    id: 'molenplaat',
    layerKey: 'molenplaat',
    category: 'VISSERIJPERCELEN 150 HA',
    title: 'Molenplaat Visserijpachtgronden',
    lat: 51.46500,
    lng: 4.15000,
    rdX: 69000,
    rdY: 386500,
    depth: '-1.50m tot -4.00m NAP',
    description: '150 hectare historische visserij- en oesterpercelen in het Verdronken Land van Reimerswaal.',
    history: 'Pachtveilingen Bestuur der Visserijen 1873 & 1892. Dossier-Zuurdeeg.',
    wooCase: 'Zaak 1456324 & Zaak 1425030 (Bezwaarschrift B&W Tholen)',
    color: '#fab387'
  },
  {
    id: 'g01',
    layerKey: 'geosites',
    category: 'UNESCO GEOSITE G-01',
    title: 'Verdronken Stad Reimerswaal & Oesterdam',
    lat: 51.43333,
    lng: 4.18333,
    rdX: 71200,
    rdY: 383000,
    depth: '0.00m NAP (Oesterdam)',
    description: 'Sleutelgeosite binnen UNESCO Global Geopark Schelde Delta.',
    history: 'Rijksmonument Verdronken Stad Reimerswaal (Aanwijzing RCE Sept 2017).',
    wooCase: 'Provincie Zeeland Zaak 417521 (Erfgoed & Visserij)',
    color: '#89b4fa'
  },
  {
    id: 'g16',
    layerKey: 'geosites',
    category: 'UNESCO GEOSITE G-16',
    title: 'Verdronken Land van Saeftinghe',
    lat: 51.35000,
    lng: 4.15000,
    rdX: 68500,
    rdY: 373800,
    depth: 'Estuarien Getijdengebied',
    description: 'Grootste schorrengebied van West-Europa en geologische zand-klei sequentie.',
    history: 'Estuariene sedimentologie & Formatie van Naaldwijk.',
    wooCase: 'Natura2000 LIFE Oosterschelde & Westerschelde',
    color: '#cba6f7'
  }
];

onMounted(() => {
  const cdnBase = 'https://' + '[suspicious link removed]';
  
  if (!document.getElementById('leaflet-css')) {
    const link = document.createElement('link');
    link.id = 'leaflet-css';
    link.rel = 'stylesheet';
    link.href = cdnBase + 'leaflet.css';
    document.head.appendChild(link);
  }

  if (window.L) {
    nextTick(() => initMap());
  } else {
    const script = document.createElement('script');
    script.id = 'leaflet-js';
    script.src = cdnBase + 'leaflet.js';
    script.onload = () => nextTick(() => initMap());
    document.head.appendChild(script);
  }

  // ResizeObserver om container-wijzigingen op te vangen
  if (window.ResizeObserver && workspaceRef.value) {
    resizeObserver = new ResizeObserver(() => {
      if (mapInstance) {
        setTimeout(() => mapInstance.invalidateSize(), 150);
      }
    });
    resizeObserver.observe(workspaceRef.value);
  }
});

function initMap() {
  const L = window.L;
  if (!L) return;

  const container = document.getElementById('leaflet-map-canvas');
  if (!container) return;

  // FIX BUG 1: Opruimen van oude instantie
  if (mapInstance) {
    mapInstance.remove();
    mapInstance = null;
  }
  if (container._leaflet_id) {
    container._leaflet_id = null;
  }

  // Initialiseren op Bol van Lodijke (51.472°N, 4.145°E)
  mapInstance = L.map('leaflet-map-canvas', {
    center: [51.4720, 4.1450],
    zoom: 12,
    zoomControl: true,
    attributionControl: true
  });

  const cartoUrl = 'https://{s}.' + 'basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
  L.tileLayer(cartoUrl, {
    attribution: '&copy; OpenStreetMap &copy; CARTO &copy; Lodijke GIS Core',
    maxZoom: 18,
    subdomains: 'abcd'
  }).addTo(mapInstance);

  const pdokUrl = 'https://' + 'service.pdok.nl/brt/achtergrondkaart/wmts/v2_0/official/EPSG:3857/{z}/{x}/{y}.png';
  historicalTileLayer = L.tileLayer(
    pdokUrl,
    {
      attribution: 'PDOK Topotijdreis 1892 & Bestuur der Visserijen Middelburg 1892',
      opacity: opacity.value,
      maxZoom: 18
    }
  );

  if (layers.value.zeekaart1892) {
    historicalTileLayer.addTo(mapInstance);
  }

  ['perceel369', 'kasteel', 'molenplaat', 'geosites'].forEach(key => {
    layerGroups[key] = L.layerGroup().addTo(mapInstance);
  });

  gisFeatures.forEach(feat => {
    const marker = L.circleMarker([feat.lat, feat.lng], {
      radius: feat.id === 'p369' ? 12 : 9,
      fillColor: feat.color,
      color: '#11111b',
      weight: 2,
      opacity: 1,
      fillOpacity: 0.90
    });

    marker.on('click', () => {
      selectedFeature.value = feat;
    });

    marker.bindTooltip(`<b>${feat.title}</b><br>${feat.depth}`, { permanent: false, direction: 'top' });

    if (layerGroups[feat.layerKey]) {
      layerGroups[feat.layerKey].addLayer(marker);
    }
  });

  const perceel369Poly = L.circle([51.47833, 4.13750], {
    color: '#a6e3a1',
    fillColor: '#a6e3a1',
    fillOpacity: 0.30,
    radius: 200
  });
  perceel369Poly.bindTooltip("Oesterperceel No. 369 (12,5 ha - Pacht 1892)");
  layerGroups.perceel369.addLayer(perceel369Poly);

  const molenplaatPoly = L.polygon([
    [51.468, 4.142],
    [51.471, 4.158],
    [51.461, 4.162],
    [51.458, 4.145]
  ], {
    color: '#fab387',
    fillColor: '#fab387',
    fillOpacity: 0.25,
    weight: 2
  });
  molenplaatPoly.bindTooltip("Molenplaat Visserijpercelen (150 ha)");
  layerGroups.molenplaat.addLayer(molenplaatPoly);

  // FIX BUG 2: Herberekenen afmetingen
  setTimeout(() => {
    if (mapInstance) {
      mapInstance.invalidateSize();
    }
  }, 200);
}

function updateOpacity() {
  if (historicalTileLayer) {
    historicalTileLayer.setOpacity(parseFloat(opacity.value));
  }
}

function toggleLayer(key) {
  layers.value[key] = !layers.value[key];
  if (!mapInstance) return;

  if (key === 'zeekaart1892') {
    if (layers.value.zeekaart1892) {
      if (historicalTileLayer) historicalTileLayer.addTo(mapInstance);
    } else {
      if (historicalTileLayer) mapInstance.removeLayer(historicalTileLayer);
    }
  } else if (layerGroups[key]) {
    if (layers.value[key]) {
      mapInstance.addLayer(layerGroups[key]);
    } else {
      mapInstance.removeLayer(layerGroups[key]);
    }
  }
}

onUnmounted(() => {
  if (resizeObserver) {
    resizeObserver.disconnect();
  }
  if (mapInstance) {
    mapInstance.remove();
    mapInstance = null;
  }
});
</script>

<style scoped>
.gis-container {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: #1e1e2e;
  color: #cdd6f4;
}
.gis-header {
  background: #181825;
  padding: 1rem 1.25rem;
  border-bottom: 1px solid #313244;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 1rem;
}
.gis-header h2 { margin: 0; color: #f38ba8; font-size: 1.3rem; }
.subtitle { margin: 0.25rem 0 0 0; color: #a6adc8; font-size: 0.85rem; }
.layer-controls { display: flex; gap: 0.4rem; flex-wrap: wrap; }
.btn-filter {
  background: #313244;
  color: #cdd6f4;
  border: 1px solid #45475a;
  padding: 0.4rem 0.75rem;
  border-radius: 6px;
  font-weight: bold;
  font-size: 0.8rem;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-filter.active {
  background: #89b4fa;
  color: #11111b;
  border-color: #89b4fa;
}

.opacity-bar {
  background: #181825;
  border-bottom: 1px solid #313244;
  padding: 0.5rem 1.25rem;
  display: flex;
  align-items: center;
  gap: 1rem;
  font-size: 0.85rem;
  color: #f9e2af;
}
.opacity-bar input[type="range"] {
  width: 200px;
  accent-color: #f9e2af;
  cursor: pointer;
}

.gis-workspace {
  flex: 1;
  display: flex;
  position: relative;
  overflow: hidden;
  min-height: 0;
}
.map-canvas {
  flex: 1;
  height: 100%;
  min-height: 300px;
  z-index: 1;
  background: #11111b;
}

.gis-sidebar {
  width: 320px;
  background: #181825;
  border-left: 1px solid #313244;
  display: flex;
  flex-direction: column;
  z-index: 2;
  overflow-y: auto;
  box-shadow: -4px 0 16px rgba(0,0,0,0.4);
}
.sidebar-header {
  padding: 1rem;
  border-bottom: 1px solid #313244;
  position: relative;
}
.badge {
  background: #89b4fa;
  color: #11111b;
  font-size: 0.68rem;
  font-weight: bold;
  padding: 0.15rem 0.45rem;
  border-radius: 4px;
}
.sidebar-header h3 { margin: 0.4rem 0 0 0; color: #a6e3a1; font-size: 1.1rem; }
.btn-close {
  position: absolute;
  top: 0.8rem;
  right: 0.8rem;
  background: transparent;
  border: none;
  color: #a6adc8;
  font-size: 1.1rem;
  cursor: pointer;
}
.sidebar-body { padding: 1rem; }
.feature-desc { color: #bac2de; font-size: 0.88rem; line-height: 1.4; margin-bottom: 1rem; }
.info-block {
  background: #1e1e2e;
  border: 1px solid #313244;
  border-radius: 8px;
  padding: 0.75rem;
  margin-bottom: 0.85rem;
}
.info-block h4 { margin: 0 0 0.4rem 0; color: #f9e2af; font-size: 0.8rem; text-transform: uppercase; }
.info-block ul { margin: 0; padding-left: 1rem; color: #cdd6f4; font-size: 0.82rem; }
.info-block p { margin: 0; color: #cdd6f4; font-size: 0.82rem; line-height: 1.4; }
.btn-woo {
  display: inline-block;
  margin-top: 0.5rem;
  background: #a6e3a1;
  color: #11111b;
  padding: 0.4rem 0.75rem;
  border-radius: 6px;
  text-decoration: none;
  font-weight: bold;
  font-size: 0.78rem;
}
</style>
