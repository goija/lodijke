<template>
  <div class="gis-container">
    <!-- Header / Control Panel -->
    <header class="gis-header">
      <div class="header-titles">
        <h2>📍 GIS & Geodetische Kaartweergave</h2>
        <p class="subtitle">
          RD (EPSG:28992) & WGS84 Coördinatennetwerk | Perceel 369 & Geopark Schelde Delta
        </p>
      </div>
      <div class="layer-controls">
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

    <!-- Main Content Area: Map + Sidebar -->
    <div class="gis-workspace">
      <!-- Leaflet Map Canvas -->
      <div id="leaflet-map" class="map-canvas"></div>

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
import { ref, onMounted, onUnmounted } from 'vue';

const selectedFeature = ref(null);
let map = null;
let layerGroups = {};

const layers = ref({
  perceel369: true,
  kasteel: true,
  molenplaat: true,
  geosites: true
});

// Geodata Punten & Percelen
const gisFeatures = [
  {
    id: 'p369',
    layerKey: 'perceel369',
    category: 'OESTERCONCESSIE',
    title: 'Oesterperceel No. 369 (Bol van Lodijke)',
    lat: 51.47833,
    lng: 4.13750,
    rdX: 68120,
    rdY: 388050,
    depth: '-2.10m NAP',
    description: '12,5 hectare oesterkweekgronden gepacht door Reder Benjamin Willem Schot (1840–1935).',
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
  // Dynamisch Leaflet CSS inladen
  if (!document.getElementById('leaflet-css')) {
    const link = document.createElement('link');
    link.id = 'leaflet-css';
    link.rel = 'stylesheet';
    link.href = '[suspicious link removed]';
    document.head.appendChild(link);
  }

  // Dynamisch Leaflet JS inladen en kaart initieëren
  if (window.L) {
    initMap();
  } else {
    const script = document.createElement('script');
    script.src = '[suspicious link removed]';
    script.onload = () => initMap();
    document.head.appendChild(script);
  }
});

function initMap() {
  const L = window.L;
  if (!L) return;

  // Kaart centreren op de Bol van Lodijke / Oosterschelde (51.478°N, 4.137°E)
  map = L.map('leaflet-map').setView([51.4720, 4.1450], 12);

  // Donkere / Topografische Kaartlaag (CartoDB Dark Matter)
  L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
    attribution: '&copy; OpenStreetMap &copy; CARTO &copy; Lodijke GIS Core',
    maxZoom: 18
  }).addTo(map);

  // Laag-groepen initialiseren
  ['perceel369', 'kasteel', 'molenplaat', 'geosites'].forEach(key => {
    layerGroups[key] = L.layerGroup().addTo(map);
  });

  // Punten & Polygonen toevoegen
  gisFeatures.forEach(feat => {
    const marker = L.circleMarker([feat.lat, feat.lng], {
      radius: feat.id === 'p369' ? 12 : 9,
      fillColor: feat.color,
      color: '#11111b',
      weight: 2,
      opacity: 1,
      fillOpacity: 0.85
    });

    marker.on('click', () => {
      selectedFeature.value = feat;
    });

    marker.bindTooltip(`<b>${feat.title}</b><br>${feat.depth}`, { permanent: false, direction: 'top' });

    if (layerGroups[feat.layerKey]) {
      layerGroups[feat.layerKey].addLayer(marker);
    }
  });

  // Cirkel-polygoon voor Perceel No. 369 (12,5 ha op de Bol van Lodijke)
  const perceel369Poly = L.circle([51.47833, 4.13750], {
    color: '#a6e3a1',
    fillColor: '#a6e3a1',
    fillOpacity: 0.25,
    radius: 200
  });
  perceel369Poly.bindTooltip("Oesterperceel No. 369 (12,5 ha)");
  layerGroups.perceel369.addLayer(perceel369Poly);

  // Polygoon voor Molenplaat (150 ha)
  const molenplaatPoly = L.polygon([
    [51.468, 4.142],
    [51.471, 4.158],
    [51.461, 4.162],
    [51.458, 4.145]
  ], {
    color: '#fab387',
    fillColor: '#fab387',
    fillOpacity: 0.20,
    weight: 2
  });
  molenplaatPoly.bindTooltip("Molenplaat Visserijpercelen (150 ha)");
  layerGroups.molenplaat.addLayer(molenplaatPoly);
}

function toggleLayer(key) {
  layers.value[key] = !layers.value[key];
  if (map && layerGroups[key]) {
    if (layers.value[key]) {
      map.addLayer(layerGroups[key]);
    } else {
      map.removeLayer(layerGroups[key]);
    }
  }
}

onUnmounted(() => {
  if (map) map.remove();
});
</script>

<style scoped>
.gis-container {
  display: flex;
  flex-direction: column;
  height: 100vh;
  background: #1e1e2e;
  color: #cdd6f4;
}
.gis-header {
  background: #181825;
  padding: 1rem 1.5rem;
  border-bottom: 1px solid #313244;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 1rem;
}
.gis-header h2 { margin: 0; color: #f38ba8; font-size: 1.5rem; }
.subtitle { margin: 0.25rem 0 0 0; color: #a6adc8; font-size: 0.88rem; }
.layer-controls { display: flex; gap: 0.5rem; flex-wrap: wrap; }
.btn-filter {
  background: #313244;
  color: #cdd6f4;
  border: 1px solid #45475a;
  padding: 0.45rem 0.85rem;
  border-radius: 6px;
  font-weight: bold;
  font-size: 0.82rem;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-filter.active {
  background: #89b4fa;
  color: #11111b;
  border-color: #89b4fa;
}

.gis-workspace {
  flex: 1;
  display: flex;
  position: relative;
  overflow: hidden;
}
.map-canvas {
  flex: 1;
  height: 100%;
  z-index: 1;
}

.gis-sidebar {
  width: 360px;
  background: #181825;
  border-left: 1px solid #313244;
  display: flex;
  flex-direction: column;
  z-index: 2;
  overflow-y: auto;
  box-shadow: -4px 0 16px rgba(0,0,0,0.4);
}
.sidebar-header {
  padding: 1.25rem;
  border-bottom: 1px solid #313244;
  position: relative;
}
.badge {
  background: #89b4fa;
  color: #11111b;
  font-size: 0.7rem;
  font-weight: bold;
  padding: 0.15rem 0.5rem;
  border-radius: 4px;
}
.sidebar-header h3 { margin: 0.5rem 0 0 0; color: #a6e3a1; font-size: 1.2rem; }
.btn-close {
  position: absolute;
  top: 1rem;
  right: 1rem;
  background: transparent;
  border: none;
  color: #a6adc8;
  font-size: 1.2rem;
  cursor: pointer;
}
.sidebar-body { padding: 1.25rem; }
.feature-desc { color: #bac2de; font-size: 0.9rem; line-height: 1.4; margin-bottom: 1.25rem; }
.info-block {
  background: #1e1e2e;
  border: 1px solid #313244;
  border-radius: 8px;
  padding: 0.85rem;
  margin-bottom: 1rem;
}
.info-block h4 { margin: 0 0 0.5rem 0; color: #f9e2af; font-size: 0.85rem; text-transform: uppercase; }
.info-block ul { margin: 0; padding-left: 1.1rem; color: #cdd6f4; font-size: 0.85rem; }
.info-block p { margin: 0; color: #cdd6f4; font-size: 0.85rem; line-height: 1.4; }
.btn-woo {
  display: inline-block;
  margin-top: 0.6rem;
  background: #a6e3a1;
  color: #11111b;
  padding: 0.45rem 0.8rem;
  border-radius: 6px;
  text-decoration: none;
  font-weight: bold;
  font-size: 0.8rem;
}
</style>
