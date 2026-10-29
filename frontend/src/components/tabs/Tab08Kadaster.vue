<template>
  <div class="space-y-4">
    <div class="flex flex-wrap gap-1.5 bg-zeeuws-sand p-2 rounded-lg border border-zeeuws-border">
      <button @click="store.subTabs.tabKadaster = 'subKadRegister'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabKadaster === 'subKadRegister' }]">8A. Kadastraal Register</button>
      <button @click="store.subTabs.tabKadaster = 'subKadCalculator'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabKadaster === 'subKadCalculator' }]">8B. Rust Shoelace &amp; A. Ott Nr. 573 Planimeter</button>
      <button @click="store.subTabs.tabKadaster = 'subKadNieuw'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabKadaster === 'subKadNieuw' }]">8C. + Nieuw Perceel</button>
    </div>

    <!-- 8A: KADASTRAAL REGISTER -->
    <div v-if="store.subTabs.tabKadaster === 'subKadRegister'" class="overflow-x-auto border border-zeeuws-border rounded-lg">
      <table class="w-full text-left border-collapse text-xs sm:text-sm">
        <thead class="bg-meekrab-800 text-white font-mono text-xs">
          <tr><th class="p-2.5">Perceel</th><th class="p-2.5">Object</th><th class="p-2.5">Grootte</th><th class="p-2.5">Eigenaar / Pachter</th></tr>
        </thead>
        <tbody class="divide-y divide-zeeuws-border">
          <tr v-for="p in parcels" :key="p.sectie">
            <td class="p-2.5 font-mono font-bold text-meekrab-800">{{ p.sectie }}</td>
            <td class="p-2.5 font-semibold">{{ p.naam }}</td>
            <td class="p-2.5">{{ p.grootte }}</td>
            <td class="p-2.5">{{ p.eigenaar }}</td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- 8B: RUST SHOELACE & POLAIRE PLANIMETER (A. OTT NR. 573) -->
    <div v-else-if="store.subTabs.tabKadaster === 'subKadCalculator'" class="space-y-4">
      <div class="p-4 bg-zeeuws-sand border border-zeeuws-border rounded-lg flex flex-wrap items-center gap-3 text-sm">
        <span class="font-bold text-meekrab-800">Snelle Omrekening:</span>
        <input v-model.number="gemeten" type="number" class="ui-input w-28 font-mono font-bold" />
        <span>Zeeuwse gemeten (à 300 roeden = 4.405,6 m²) =</span>
        <span class="px-3 py-1 bg-meekrab-700 text-white font-mono font-bold rounded">{{ hectareText }}</span>
      </div>

      <div class="overflow-x-auto border border-zeeuws-border rounded-lg">
        <table class="w-full text-left border-collapse text-xs sm:text-sm">
          <thead class="bg-meekrab-800 text-white font-mono text-xs">
            <tr>
              <th class="p-2.5">Perceel (RD EPSG:28992)</th>
              <th class="p-2.5">Shoelace m²</th>
              <th class="p-2.5">Hectaren</th>
              <th class="p-2.5">Zeeuwse Gemeten &amp; Roeden</th>
              <th class="p-2.5">A. Ott Nr. 573 (1:2500)</th>
              <th class="p-2.5">Status</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-zeeuws-border">
            <tr v-for="a in store.planimeterAudits" :key="a.parcel_id">
              <td class="p-2.5 font-mono font-bold text-meekrab-800">{{ a.cadastral_code }}</td>
              <td class="p-2.5 font-mono">{{ a.area_m2.toLocaleString('nl-NL') }} m²</td>
              <td class="p-2.5 font-mono font-bold">{{ a.area_hectares }} ha</td>
              <td class="p-2.5 font-mono">{{ a.area_zeeuwse_gemeten }} gem. ({{ a.area_zeeuwse_roeden }} r.)</td>
              <td class="p-2.5 font-mono text-xs">
                {{ a.paper_area_cm2 }} cm² | {{ a.ott_573_drum_revolutions }} omw. ({{ a.ott_573_vernier_units }} nonius)
              </td>
              <td class="p-2.5 font-mono text-xs font-bold text-green-800">{{ a.verification_status }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="p-4 bg-zeeuws-sand border border-zeeuws-border rounded-lg space-y-3">
        <div class="flex flex-wrap items-center justify-between gap-2">
          <h4 class="font-serif font-bold text-base text-meekrab-800">Interactieve Rust RD-Polygoon Integrator (`POST /api/planimeter/integrate`)</h4>
          <div class="flex gap-1.5">
            <button @click="loadSamplePolygon('lodijke')" class="px-2.5 py-1 bg-white border border-zeeuws-border rounded text-xs font-semibold">Laad Perceel 369</button>
            <button @click="loadSamplePolygon('gortzak')" class="px-2.5 py-1 bg-white border border-zeeuws-border rounded text-xs font-semibold">Laad Schakerloo I 360</button>
          </div>
        </div>
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-3">
          <textarea v-model="customPolyJson" rows="6" class="w-full p-2.5 font-mono text-xs bg-white border border-zeeuws-border rounded"></textarea>
          <pre class="w-full h-[155px] overflow-auto p-3 font-mono text-xs bg-zinc-900 text-green-300 rounded">{{ customPolyResult }}</pre>
        </div>
        <button @click="runCustomIntegration" class="ui-btn bg-meekrab-700 text-white">Integreer RD-Polygoon in Rust</button>
      </div>
    </div>

    <!-- 8C: NIEUW PERCEEL -->
    <div v-else class="p-4 bg-zeeuws-sand border border-zeeuws-border rounded-lg space-y-2.5">
      <div class="grid grid-cols-1 md:grid-cols-4 gap-2.5">
        <input v-model="sectie" type="text" placeholder="Sectie & Nr." class="ui-input" />
        <input v-model="naam" type="text" placeholder="Naam / Hofstede" class="ui-input" />
        <input v-model="grootte" type="text" placeholder="Oppervlakte" class="ui-input" />
        <input v-model="eigenaar" type="text" placeholder="Eigenaar" class="ui-input" />
      </div>
      <button @click="addParcel" class="ui-btn bg-meekrab-700 text-white">Perceel Opslaan</button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import { store } from '../../store/archiveStore.js';

const parcels = ref([
  { sectie: 'Perceel No. 369', naam: 'Oesterbank Bol van Lodijke', grootte: '12,50 ha (28,37 gemeten)', eigenaar: 'Benjamin Willem Schot (TH 2 & TH 90)' },
  { sectie: 'Sectie A nr. 107', naam: 'Kruittoren 23 Tholen', grootte: '0,18 ha (0,41 gemeten)', eigenaar: 'B.W. Schot & familie' },
  { sectie: 'Sectie I nr. 360', naam: 'Hofstede De Gortzak', grootte: '122,00 gemeten (53,75 ha)', eigenaar: 'Boogaart (1768) • Wagtho (1893) • Moelker (1915)' },
  { sectie: 'Sectie E 1551/1552', naam: 'Platteweg Scherpenisse', grootte: '1,45 ha (3,29 gemeten)', eigenaar: 'Geboortegrond Maria Mathea Bolier (1840)' }
]);

const gemeten = ref(122);
const hectareText = computed(() => {
  const g = parseFloat(gemeten.value);
  return isNaN(g) ? '0,00 ha' : (g * 0.44056).toFixed(2).replace('.', ',') + ' ha';
});

const customPolyJson = ref(JSON.stringify([
  [67945.0, 387871.428571],
  [68295.0, 387871.428571],
  [68295.0, 388228.571429],
  [67945.0, 388228.571429],
  [67945.0, 387871.428571]
], null, 2));

const customPolyResult = ref('// Klik op "Integreer RD-Polygoon in Rust" voor de Shoelace & A. Ott Nr. 573 uitkomst...');

function loadSamplePolygon(which) {
  if (which === 'lodijke') {
    customPolyJson.value = JSON.stringify([
      [67945.0, 387871.428571],
      [68295.0, 387871.428571],
      [68295.0, 388228.571429],
      [67945.0, 388228.571429],
      [67945.0, 387871.428571]
    ], null, 2);
  } else {
    customPolyJson.value = JSON.stringify([
      [72280.0, 393056.835676],
      [73020.0, 393056.835676],
      [73020.0, 393783.164324],
      [72280.0, 393783.164324],
      [72280.0, 393056.835676]
    ], null, 2);
  }
}

async function runCustomIntegration() {
  try {
    const pts = JSON.parse(customPolyJson.value);
    const res = await fetch('/api/planimeter/integrate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        label: 'Handmatige RD-Verificatie',
        rd_polygon: pts,
        map_scale: 2500
      })
    });
    const data = await res.json();
    customPolyResult.value = JSON.stringify(data, null, 2);
    store.showToast(`Geïntegreerd: ${data.area_hectares} ha = ${data.area_zeeuwse_gemeten} gemeten`);
  } catch (e) {
    customPolyResult.value = 'Fout in RD-coördinaten JSON: ' + String(e);
  }
}

const sectie = ref('');
const naam = ref('');
const grootte = ref('');
const eigenaar = ref('');

function addParcel() {
  if (!sectie.value.trim() || !naam.value.trim()) return;
  parcels.value.unshift({
    sectie: sectie.value.trim(),
    naam: naam.value.trim(),
    grootte: grootte.value.trim() || '-',
    eigenaar: eigenaar.value.trim() || '-'
  });
  sectie.value = '';
  naam.value = '';
  store.subTabs.tabKadaster = 'subKadRegister';
}
</script>
