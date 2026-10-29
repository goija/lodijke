<template>
  <div class="space-y-4">
    <div class="flex flex-wrap gap-1.5 bg-zeeuws-sand p-2 rounded-lg border border-zeeuws-border">
      <button @click="store.subTabs.tabGeologie = 'subGeoBoringen'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabGeologie === 'subGeoBoringen' }]">7A. Boorstaten</button>
      <button @click="store.subTabs.tabGeologie = 'subGeoNieuw'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabGeologie === 'subGeoNieuw' }]">7B. + Nieuw Boorprofiel</button>
    </div>

    <div v-if="store.subTabs.tabGeologie === 'subGeoBoringen'" class="grid grid-cols-1 md:grid-cols-3 gap-3.5 text-sm">
      <div v-for="g in profiles" :key="g.code" class="p-3.5 bg-zeeuws-sand border border-zeeuws-border rounded-lg">
        <strong>{{ g.code }} ({{ g.polder }}):</strong> {{ g.layer }}
      </div>
    </div>

    <div v-else class="p-4 bg-zeeuws-sand border border-zeeuws-border rounded-lg space-y-2.5">
      <div class="grid grid-cols-1 md:grid-cols-3 gap-2.5">
        <input v-model="code" type="text" placeholder="Code (GEO-04)" class="ui-input" />
        <input v-model="polder" type="text" placeholder="Polder" class="ui-input" />
        <input v-model="layer" type="text" placeholder="Laagbeschrijving" class="ui-input" />
      </div>
      <button @click="addGeo" class="ui-btn bg-meekrab-700 text-white">Boorprofiel Opslaan</button>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { store } from '../../store/archiveStore.js';

const profiles = ref([
  { code: 'GEO-01', polder: 'Perceel 369', layer: 'Formatie van Naaldwijk (kalkrijk marien zand) op Laagpakket van Walcheren en Hollandveen.' },
  { code: 'GEO-02', polder: 'Schakerloo', layer: 'Jonge zeeklei geschikt voor meekrabteelt (Rubia tinctorum) op kreekrug Deurloo.' },
  { code: 'GEO-03', polder: 'Oud-Vossemeer', layer: 'Zandlens stormvloedlaag 12–13 maart 1906 op Formatie van Boxtel.' }
]);

const code = ref('');
const polder = ref('');
const layer = ref('');

function addGeo() {
  if (!layer.value.trim()) return;
  profiles.value.push({
    code: code.value.trim() || 'GEO-04',
    polder: polder.value.trim() || 'Tholen',
    layer: layer.value.trim()
  });
  layer.value = '';
  store.subTabs.tabGeologie = 'subGeoBoringen';
}
</script>
