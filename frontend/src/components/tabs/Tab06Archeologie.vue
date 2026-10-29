<template>
  <div class="space-y-4">
    <div class="flex flex-wrap gap-1.5 bg-zeeuws-sand p-2 rounded-lg border border-zeeuws-border">
      <button @click="store.subTabs.tabArcheologie = 'subArcRegister'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabArcheologie === 'subArcRegister' }]">6A. Vondstenregister</button>
      <button @click="store.subTabs.tabArcheologie = 'subArcNieuw'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabArcheologie === 'subArcNieuw' }]">6B. + Nieuwe Vondst</button>
    </div>

    <div v-if="store.subTabs.tabArcheologie === 'subArcRegister'" class="overflow-x-auto border border-zeeuws-border rounded-lg">
      <table class="w-full text-left border-collapse text-xs sm:text-sm">
        <thead class="bg-meekrab-800 text-white font-mono text-xs">
          <tr><th class="p-2.5">Code</th><th class="p-2.5">Diepte</th><th class="p-2.5">Artefact</th><th class="p-2.5">Locatie</th></tr>
        </thead>
        <tbody class="divide-y divide-zeeuws-border">
          <tr v-for="r in records" :key="r.code">
            <td class="p-2.5 font-mono font-bold text-meekrab-800">{{ r.code }}</td>
            <td class="p-2.5">{{ r.depth }}</td>
            <td class="p-2.5 font-semibold">{{ r.desc }}</td>
            <td class="p-2.5">{{ r.loc }}</td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-else class="p-4 bg-zeeuws-sand border border-zeeuws-border rounded-lg space-y-2.5">
      <div class="grid grid-cols-1 md:grid-cols-3 gap-2.5">
        <input v-model="code" type="text" placeholder="Code (ARC-LOD-09)" class="ui-input" />
        <input v-model="loc" type="text" placeholder="Locatie" class="ui-input" />
        <input v-model="desc" type="text" placeholder="Omschrijving" class="ui-input" />
      </div>
      <button @click="addRecord" class="ui-btn bg-meekrab-700 text-white">Vondst Opslaan</button>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { store } from '../../store/archiveStore.js';

const records = ref([
  { code: 'ARC-LOD-01', depth: '-3,20m NAP', desc: 'Kloostermoppen en tufsteen Kasteel Lodijke', loc: 'Bol van Lodijke (Perceel 369)' },
  { code: 'ARC-LOD-02', depth: '-2,10m NAP', desc: 'Kalkpannen met oesterbroed', loc: 'Perceel No. 369 Bol van Lodijke' },
  { code: 'ARC-SCH-04', depth: '-1,45m NAP', desc: 'Eikenhouten klepduiker', loc: 'Scherpenisse Sectie E 1551' }
]);

const code = ref('');
const loc = ref('');
const desc = ref('');

function addRecord() {
  if (!desc.value.trim()) return;
  records.value.unshift({
    code: code.value.trim() || 'ARC-LOD-09',
    depth: '-2,00m NAP',
    desc: desc.value.trim(),
    loc: loc.value.trim() || 'Bol van Lodijke'
  });
  desc.value = '';
  store.subTabs.tabArcheologie = 'subArcRegister';
}
</script>
