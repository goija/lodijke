<template>
  <div class="space-y-4">
    <div class="flex flex-wrap items-center justify-between gap-2 bg-zeeuws-sand p-2 rounded-lg border border-zeeuws-border">
      <div class="flex flex-wrap gap-1.5">
        <button @click="store.subTabs.tabKaarten = 'subKaartZeekaart'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabKaarten === 'subKaartZeekaart' }]">4A. Zeekaart Perceel 369</button>
        <button @click="store.subTabs.tabKaarten = 'subKaartKadaster'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabKaarten === 'subKaartKadaster' }]">4B. Kadastrale Kaart Tholen</button>
        <button @click="store.subTabs.tabKaarten = 'subKaartLegenda'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabKaarten === 'subKaartLegenda' }]">4C. RD &amp; WGS84 GeoJSON</button>
        <button @click="store.subTabs.tabKaarten = 'subPdokWfs'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabKaarten === 'subPdokWfs' }]">4D. PDOK Kadaster WFS v5.0</button>
      </div>
      <div class="flex items-center gap-3 text-xs">
        <label class="flex items-center gap-1 cursor-pointer"><input type="checkbox" v-model="showRoutes" class="accent-meekrab-700" /> Vaarroutes</label>
        <label class="flex items-center gap-1 cursor-pointer"><input type="checkbox" v-model="showLodijke" class="accent-meekrab-700" /> Perceel 369</label>
      </div>
    </div>

    <div v-if="store.subTabs.tabKaarten === 'subKaartZeekaart'">
      <svg viewBox="0 0 920 420" class="w-full h-auto bg-[#dfeef5] border border-zeeuws-border rounded-lg select-none">
        <path d="M 0,180 Q 260,165 470,220 T 920,205 L 920,285 Q 560,305 350,260 T 0,250 Z" fill="#a8cfe0" stroke="#4d7c94" stroke-width="1.5" />
        <text x="190" y="218" fill="#163547" font-size="13" font-family="JetBrains Mono" font-weight="bold">OOSTERSCHELDE / DE EENDRACHT (-8.5m)</text>
        <path d="M 0,0 L 920,0 L 920,135 L 790,155 L 640,125 L 520,145 L 400,115 L 220,145 L 0,105 Z" fill="#ffffff" stroke="#8b2229" stroke-width="2" />
        <text x="35" y="38" fill="#8b2229" font-size="18" font-weight="bold">EILAND THOLEN (SCHAKERLOO &amp; BROEKPOLDER)</text>
        <g class="cursor-pointer" @click="selectFeature('flauwers1912')">
          <rect x="25" y="55" width="205" height="36" rx="5" fill="#fdf7f7" stroke="#8b2229" stroke-width="1.5" />
          <text x="38" y="78" fill="#8b2229" font-size="12" font-weight="bold">Flauwers Zierikzee (1912)</text>
        </g>
        <g class="cursor-pointer" @click="selectFeature('kruittoren')">
          <circle cx="580" cy="130" r="7" fill="#8b2229" stroke="#ffffff" stroke-width="2" />
          <text x="435" y="114" fill="#8b2229" font-size="12" font-weight="bold">Haven Tholen &amp; Kruittoren 23</text>
        </g>
        <g class="cursor-pointer" @click="selectFeature('oudvossemeer1906')">
          <rect x="735" y="45" width="160" height="44" rx="5" fill="#fdf7f7" stroke="#8b2229" stroke-width="1.5" />
          <text x="748" y="66" fill="#8b2229" font-size="12" font-weight="bold">Oud-Vossemeer (1906)</text>
        </g>
        <path d="M 90,330 Q 300,275 510,310 T 900,320 L 920,420 L 0,420 L 0,365 Z" fill="#efe7d3" stroke="#8b2229" stroke-width="1.5" stroke-dasharray="6,4" />
        <g v-if="showLodijke" class="cursor-pointer" @click="selectFeature('lodijke369')">
          <rect x="320" y="270" width="215" height="75" rx="6" fill="#8b2229" fill-opacity="0.2" stroke="#8b2229" stroke-width="2.5" />
          <text x="335" y="298" fill="#561318" font-family="JetBrains Mono" font-size="13" font-weight="bold">BOL VAN LODIJKE</text>
          <text x="335" y="318" fill="#8b2229" font-size="12" font-weight="bold">Perceel No. 369 (12,5 ha)</text>
          <text x="335" y="335" fill="#18181b" font-size="11">RD: 68120, 388050 | WGS84: 51.4783°N, 4.1375°E</text>
        </g>
        <g class="cursor-pointer" @click="selectFeature('kasteelLodijke')">
          <rect x="130" y="315" width="165" height="42" rx="5" fill="#ffffff" stroke="#8b2229" stroke-width="1.5" />
          <text x="142" y="340" fill="#8b2229" font-size="11" font-weight="bold">ARC-LOD-01: Kasteel Lodijke</text>
        </g>
        <g class="cursor-pointer" @click="selectFeature('weerE')">
          <rect x="650" y="315" width="205" height="42" rx="5" fill="#ffffff" stroke="#8b2229" stroke-width="1.5" />
          <text x="665" y="340" fill="#8b2229" font-size="11" font-weight="bold">Weer E: Eldernissen (1825)</text>
        </g>
        <g v-if="showRoutes">
          <path d="M 580,138 Q 510,205 435,270" fill="none" stroke="#8b2229" stroke-width="2.5" stroke-dasharray="6,4" />
          <path d="M 590,128 Q 665,95 735,72" fill="none" stroke="#18181b" stroke-width="2" stroke-dasharray="4,4" />
        </g>
      </svg>
    </div>

    <div v-else-if="store.subTabs.tabKaarten === 'subKaartKadaster'">
      <svg viewBox="0 0 920 340" class="w-full h-auto bg-zeeuws-sand border border-zeeuws-border rounded-lg select-none">
        <g class="cursor-pointer" @click="selectFeature('gortzak360')">
          <polygon points="35,30 325,30 340,165 50,165" fill="#ffffff" stroke="#8b2229" stroke-width="2" />
          <text x="65" y="75" fill="#8b2229" font-weight="bold" font-size="14">Schakerloo Sectie I nr. 360</text>
          <text x="65" y="100" fill="#18181b" font-size="13">Hofstede De Gortzak (122 gemeten / 53,75 ha)</text>
          <text x="65" y="122" fill="#561318" font-family="JetBrains Mono" font-size="11">RD: X=72650, Y=393420 | WGS84: 51.5273°N, 4.2018°E</text>
        </g>
        <g class="cursor-pointer" @click="selectFeature('kandia')">
          <polygon points="360,30 650,30 665,165 375,165" fill="#ffffff" stroke="#8b2229" stroke-width="2" />
          <text x="390" y="80" fill="#8b2229" font-weight="bold" font-size="14">Broekpolder &amp; Rooland</text>
          <text x="390" y="105" fill="#18181b" font-size="13">Hofstede Kandia (&gt;76 hectare)</text>
        </g>
        <g class="cursor-pointer" @click="selectFeature('kruittoren')">
          <polygon points="685,30 890,30 890,310 695,310" fill="#fdf7f7" stroke="#8b2229" stroke-width="2" />
          <text x="708" y="85" fill="#8b2229" font-weight="bold" font-size="14">Stad Tholen</text>
          <text x="708" y="110" fill="#18181b" font-size="12">Kruittoren 23 (A 107)</text>
          <text x="708" y="135" fill="#18181b" font-size="12">RD: 74045, 393860</text>
        </g>
        <g class="cursor-pointer" @click="selectFeature('scherpenisse')">
          <polygon points="35,185 340,185 340,310 35,310" fill="#ffffff" stroke="#8b2229" stroke-width="2" />
          <text x="60" y="235" fill="#8b2229" font-weight="bold" font-size="14">Scherpenisse Sectie E 1551–1552</text>
          <text x="60" y="260" fill="#18181b" font-size="12">Platteweg &amp; Klepduiker (RD: 69215, 395110)</text>
        </g>
        <g class="cursor-pointer" @click="selectFeature('watervliet')">
          <polygon points="365,185 670,185 670,310 365,310" fill="#ffffff" stroke="#8b2229" stroke-width="2" />
          <text x="390" y="235" fill="#8b2229" font-weight="bold" font-size="14">Molenvliet (43 ha) &amp; Watervliet (77 ha)</text>
        </g>
      </svg>
    </div>

    <!-- 4C: GEOJSON -->
    <div v-else-if="store.subTabs.tabKaarten === 'subKaartLegenda'" class="space-y-3">
      <div class="flex flex-wrap items-center justify-between gap-2 bg-zeeuws-sand p-3 rounded-lg border border-zeeuws-border">
        <div class="text-xs sm:text-sm font-semibold">Geodetische Collectie: Rijksdriehoeksstelsel (EPSG:28992) &amp; WGS84 (EPSG:4326)</div>
        <a href="/api/geojson" target="_blank" class="px-3 py-1 bg-meekrab-700 text-white font-mono text-xs rounded">Download RFC 7946 GeoJSON &nearr;</a>
      </div>
      <div class="overflow-x-auto border border-zeeuws-border rounded-lg">
        <table class="w-full text-left border-collapse text-xs sm:text-sm">
          <thead class="bg-meekrab-800 text-white font-mono text-xs">
            <tr><th class="p-2.5">Perceelcode</th><th class="p-2.5">Naam</th><th class="p-2.5">Oppervlakte</th><th class="p-2.5">RD Centroïde</th><th class="p-2.5">WGS84 Centroïde</th></tr>
          </thead>
          <tbody class="divide-y divide-zeeuws-border">
            <tr v-for="p in store.geoParcels" :key="p.id">
              <td class="p-2.5 font-mono font-bold text-meekrab-800">{{ p.cadastral_code }}</td>
              <td class="p-2.5 font-semibold">{{ p.name }}</td>
              <td class="p-2.5 font-mono">{{ p.area_hectares }} ha ({{ p.area_gemeten }} gem.)</td>
              <td class="p-2.5 font-mono">X={{ p.rd_centroid[0] }}, Y={{ p.rd_centroid[1] }}</td>
              <td class="p-2.5 font-mono">{{ p.wgs84_centroid[1] }}°N, {{ p.wgs84_centroid[0] }}°E</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- 4D: PDOK WFS v5.0 -->
    <div v-else class="space-y-3">
      <div class="p-4 bg-zeeuws-sand border border-zeeuws-border rounded-lg flex flex-wrap items-center justify-between gap-2">
        <div>
          <h4 class="font-serif font-bold text-base text-meekrab-800">PDOK Kadastrale Kaart WFS v5.0 (Live BBOX Tholen &amp; Scherpenisse)</h4>
          <p class="text-xs text-zinc-700">Haalt live perceelpolygonen op via de officiële OGC API Features van het Kadaster.</p>
        </div>
        <button @click="fetchPdokLive" class="ui-btn bg-meekrab-700 text-white">Haal Live PDOK Percelen Op</button>
      </div>

      <div class="overflow-x-auto border border-zeeuws-border rounded-lg">
        <table class="w-full text-left border-collapse text-xs sm:text-sm">
          <thead class="bg-meekrab-800 text-white font-mono text-xs">
            <tr><th class="p-2.5">Kadastrale Aanduiding</th><th class="p-2.5">Gemeente</th><th class="p-2.5">Kadaster Opp. (m²)</th><th class="p-2.5">Shoelace Berekend (m²)</th><th class="p-2.5">Verschil (Δ m²)</th></tr>
          </thead>
          <tbody class="divide-y divide-zeeuws-border">
            <tr v-for="w in pdokList" :key="w.id">
              <td class="p-2.5 font-mono font-bold text-meekrab-800">{{ w.kadastrale_aanduiding }}</td>
              <td class="p-2.5">{{ w.gemeente }}</td>
              <td class="p-2.5 font-mono">{{ w.oppervlakte_kadaster_m2.toLocaleString('nl-NL') }} m²</td>
              <td class="p-2.5 font-mono font-bold">{{ w.calculated_shoelace_m2.toLocaleString('nl-NL') }} m²</td>
              <td class="p-2.5 font-mono text-xs text-green-800">Δ {{ w.delta_m2.toFixed(2) }} m²</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <div class="p-3.5 bg-zeeuws-sand border border-zeeuws-border rounded-lg">
      <div class="flex items-center justify-between">
        <h3 class="font-serif font-bold text-base text-meekrab-800">{{ selected.title }}</h3>
        <span class="font-mono text-xs font-bold text-meekrab-700">{{ selected.tag }}</span>
      </div>
      <p class="text-sm mt-1">{{ selected.desc }}</p>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue';
import { store } from '../../store/archiveStore.js';

const showRoutes = ref(true);
const showLodijke = ref(true);
const pdokList = ref([]);

const selected = reactive({
  title: 'Oesterperceel No. 369 — Bol van Lodijke',
  tag: 'RD: 68120, 388050 | 12,5 ha',
  desc: 'Geëxploiteerd door Benjamin Willem Schot met de houten hoogaarzen TH 2 "Eben Haëzer" en TH 90 "Vijf Gebroeders". WGS84: 51.47833°N, 4.13750°E.'
});

const FEATURES = {
  lodijke369: { title: 'Oesterperceel No. 369 — Bol van Lodijke', tag: 'RD: 68120, 388050 | 12,5 ha', desc: 'Kweekperceel No. 369 op de Bol van Lodijke (12,5 ha / 28,37 gemeten), WGS84: 51.47833°N, 4.13750°E.' },
  kasteelLodijke: { title: 'Verdronken Kasteel Lodijke (ARC-LOD-01)', tag: 'Reimerswaal 1530', desc: 'Fundamentresten van kasteel en ambacht Lodijke nabij Perceel 369.' },
  weerE: { title: 'Weervisserij Weer E op Eldernissen', tag: 'Sinds 1825', desc: 'Gepacht door de familie Van Dort; vanaf 1877 verpacht voor fl. 7.200 per jaar.' },
  oudvossemeer1906: { title: 'Watersnood Oud-Vossemeer (12–13 maart 1906)', tag: 'Redding TH 12', desc: 'Evacuatie met de roeiboot van hoogaars TH 12 "Niets zonder Gods zegen" van B.W. Schot.' },
  flauwers1912: { title: 'Flauwers onder Zierikzee (1912)', tag: 'Pacht mr. Fokker', desc: 'Uitbreiding door Kees, Jacob en Willem Schot naar Schouwen-Duiveland.' },
  gortzak360: { title: 'Hofstede De Gortzak (Schakerloo Sectie I nr. 360)', tag: 'RD: 72650, 393420 | 122 Gemeten', desc: '53,75 hectare (122 Zeeuwse gemeten), WGS84: 51.52730°N, 4.20180°E. Boogaart (1768) -> Wagtho (1893) -> Moelker (1915).' },
  kandia: { title: 'Hofstede Kandia (Broekpolder & Rooland)', tag: '>76 Hectare', desc: 'Eigendom P.J. de Caters / V. Claeijssens; pachters Adam en M.C. van Tilburg.' },
  kruittoren: { title: "Kruittoren 23 & Contr'Escarpe Tholen (Sectie A 107)", tag: 'RD: 74045, 393860', desc: 'Woonhuis B.W. Schot (Wijk A 107), werf Van Duivendijk en oesterloods Schot & Kegge (1913). WGS84: 51.53056°N, 4.22278°E.' },
  scherpenisse: { title: 'Scherpenisse Sectie E 1551–1552 (Platteweg)', tag: 'RD: 69215, 395110', desc: 'Geboortegrond van Maria Mathea Bolier (1840) en locatie van eikenhouten polder-klepduikers. WGS84: 51.54210°N, 4.15280°E.' },
  watervliet: { title: 'Hofstede Molenvliet (43,3 ha) & Watervliet (77 ha)', tag: 'Thoolse Polders', desc: 'Eigendom van A. Dumont Catshoek en mr. François Ermerins.' }
};

function selectFeature(key) {
  if (FEATURES[key]) {
    selected.title = FEATURES[key].title;
    selected.tag = FEATURES[key].tag;
    selected.desc = FEATURES[key].desc;
  }
}

async function fetchPdokLive() {
  try {
    store.showToast('Contact maken met PDOK Kadaster WFS v5.0...');
    const res = await fetch('/api/pdok/percelen');
    const data = await res.json();
    if (data.parcels) {
      pdokList.value = data.parcels;
      store.showToast(`${pdokList.value.length} kadastrale percelen opgehaald van PDOK WFS.`);
    }
  } catch (e) {
    store.showToast('Kon PDOK WFS niet bereiken.');
  }
}

onMounted(() => {
  fetchPdokLive();
});
</script>
