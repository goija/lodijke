<template>
  <div class="space-y-4">
    <div class="flex flex-wrap gap-1.5 bg-zeeuws-sand p-2 rounded-lg border border-zeeuws-border">
      <button @click="store.subTabs.tabUitbreiding = 'subUitNieuwTab'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabUitbreiding === 'subUitNieuwTab' }]">10A. + Nieuw Hoofdtabblad</button>
      <button @click="store.subTabs.tabUitbreiding = 'subUitViewportCode'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabUitbreiding === 'subUitViewportCode' }]">10B. Google Sites Embed-Code</button>
    </div>

    <div v-if="store.subTabs.tabUitbreiding === 'subUitNieuwTab'" class="p-4 bg-zeeuws-sand border border-zeeuws-border rounded-lg space-y-2.5">
      <div class="grid grid-cols-1 md:grid-cols-2 gap-2.5">
        <input v-model="tabName" type="text" placeholder="Naam nieuw tabblad" class="ui-input" />
        <select v-model="tabType" class="ui-input">
          <option value="DOSSIER">Onderzoeksdossier</option>
          <option value="ARCHIEFTABEL">Archieftabel</option>
        </select>
        <textarea v-model="tabBody" rows="3" placeholder="Inhoud..." class="ui-input md:col-span-2"></textarea>
      </div>
      <button @click="createMainTab" class="ui-btn bg-meekrab-700 text-white">Tabblad Aanmaken</button>
    </div>

    <div v-else class="p-4 bg-zeeuws-sand border border-zeeuws-border rounded-lg space-y-2.5">
      <textarea v-model="embedSnippet" rows="5" readonly class="w-full p-2.5 font-mono text-xs bg-white border border-zeeuws-border rounded"></textarea>
      <button @click="copySnippet" class="ui-btn bg-meekrab-700 text-white">Kopieer Embed-Code</button>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { store } from '../../store/archiveStore.js';

const tabName = ref('');
const tabType = ref('DOSSIER');
const tabBody = ref('');
const embedSnippet = ref(`<div style="font-size:19px;line-height:1.6;font-family:'Inter',sans-serif;background:#f9f7f2;color:#18181b;border:2px solid #8b2229;border-radius:10px;padding:20px;"><strong>Archief Familie Schot & Bout (Tholen & Bol van Lodijke Perceel 369)</strong><p>Benjamin Willem Schot (1840–1935) • Hoogaarzen TH 2, TH 12 & TH 90 • AVG-afgeschermd • AvoRed Rust CMS.</p></div>`);

function createMainTab() {
  if (!tabName.value.trim()) return;
  const id = 'tabCustom_' + Date.now();
  store.customMainTabs.push({
    id,
    name: tabName.value.trim(),
    type: tabType.value,
    body: tabBody.value.trim()
  });
  tabName.value = '';
  tabBody.value = '';
  store.switchTab(id);
  store.showToast('Nieuw hoofdtabblad aangemaakt.');
}

function copySnippet() {
  navigator.clipboard.writeText(embedSnippet.value).then(() => store.showToast('Embed-code gekopieerd.'));
}
</script>
