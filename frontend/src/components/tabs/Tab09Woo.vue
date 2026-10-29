<template>
  <div class="space-y-4">
    <div class="flex flex-wrap gap-1.5 bg-zeeuws-sand p-2 rounded-lg border border-zeeuws-border">
      <button @click="store.subTabs.tabWoo = 'subWooKeten'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabWoo === 'subWooKeten' }]">9A. Bestuursrechtelijke Keten</button>
      <button @click="store.subTabs.tabWoo = 'subWooRegister'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabWoo === 'subWooRegister' }]">9B. Zaakregister</button>
      <button @click="store.subTabs.tabWoo = 'subWooNieuw'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabWoo === 'subWooNieuw' }]">9C. + Nieuw Besluit</button>
    </div>

    <div v-if="store.subTabs.tabWoo === 'subWooKeten'" class="grid grid-cols-1 md:grid-cols-2 gap-3.5 text-sm">
      <div class="p-3.5 bg-zeeuws-sand border-l-4 border-meekrab-700 rounded"><strong>1. Art. 4.1 Woo:</strong> Openbaarmaking concessieregisters Perceel 369 &amp; bouwakten 1901/1913.</div>
      <div class="p-3.5 bg-zeeuws-sand border-l-4 border-meekrab-700 rounded"><strong>2. Art. 5.1 lid 2e Woo:</strong> Strikte AVG-afscherming huidige en ouderlijke generatie.</div>
      <div class="p-3.5 bg-zeeuws-sand border-l-4 border-meekrab-700 rounded"><strong>3. Art. 7:13 Awb:</strong> Adviescommissie bezwaarschriften inzake archiefzoekslag.</div>
      <div class="p-3.5 bg-zeeuws-sand border-l-4 border-meekrab-700 rounded"><strong>4. Art. 8:1 Awb:</strong> Bestuursrechter Rechtbank Zeeland-West-Brabant.</div>
    </div>

    <div v-else-if="store.subTabs.tabWoo === 'subWooRegister'" class="overflow-x-auto border border-zeeuws-border rounded-lg">
      <table class="w-full text-left border-collapse text-xs sm:text-sm">
        <thead class="bg-meekrab-800 text-white font-mono text-xs">
          <tr><th class="p-2.5">Zaaknr.</th><th class="p-2.5">Instantie</th><th class="p-2.5">Uitkomst</th></tr>
        </thead>
        <tbody class="divide-y divide-zeeuws-border">
          <tr v-for="z in zaken" :key="z.code">
            <td class="p-2.5 font-mono font-bold text-meekrab-800">{{ z.code }}</td>
            <td class="p-2.5 font-semibold">{{ z.instantie }}</td>
            <td class="p-2.5">{{ z.besluit }}</td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-else class="p-4 bg-zeeuws-sand border border-zeeuws-border rounded-lg space-y-2.5">
      <div class="grid grid-cols-1 md:grid-cols-3 gap-2.5">
        <input v-model="code" type="text" placeholder="Zaaknummer" class="ui-input" />
        <input v-model="instantie" type="text" placeholder="Instantie" class="ui-input" />
        <input v-model="besluit" type="text" placeholder="Besluit" class="ui-input" />
      </div>
      <button @click="addZaak" class="ui-btn bg-meekrab-700 text-white">Zaak Opslaan</button>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { store } from '../../store/archiveStore.js';

const zaken = ref([
  { code: 'WOO-THO-01', instantie: 'Gemeente / Archief', besluit: 'Historische stukken openbaar; levende generaties afgeschermd' },
  { code: 'RB-ZWB-03', instantie: 'Rechtbank Zeeland-West-Brabant', besluit: 'Bevestiging AVG-schild en belanghebbendestatus' }
]);

const code = ref('');
const instantie = ref('');
const besluit = ref('');

function addZaak() {
  if (!besluit.value.trim()) return;
  zaken.value.unshift({
    code: code.value.trim() || 'WOO-NEW',
    instantie: instantie.value.trim() || 'Rechtbank',
    besluit: besluit.value.trim()
  });
  besluit.value = '';
  store.subTabs.tabWoo = 'subWooRegister';
}
</script>
