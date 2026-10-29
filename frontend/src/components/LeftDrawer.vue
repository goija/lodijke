<template>
  <aside :class="['sliding-drawer-left', { open: store.leftDrawerOpen }]" aria-label="Hoofdnavigatie">
    <div class="bg-meekrab-800 text-white p-3.5 border-b border-meekrab-950 space-y-2">
      <div class="flex items-center justify-between">
        <span class="font-mono text-[11px] uppercase tracking-wider text-meekrab-100 font-semibold">Archiefmenu</span>
        <div class="flex items-center gap-1">
          <button
            @click="store.leftDrawerPinned = !store.leftDrawerPinned"
            class="hidden xl:inline-flex px-2 py-0.5 bg-white/15 hover:bg-white/25 text-white rounded text-[11px]"
          >
            {{ store.leftDrawerPinned ? 'Vastgezet' : 'Vastzetten' }}
          </button>
          <button @click="closeLeft" class="px-2 py-0.5 bg-white text-meekrab-900 rounded text-[11px] font-bold">Sluit</button>
        </div>
      </div>
      <div class="font-serif font-bold text-sm text-white">Schot, Bout &amp; Bol van Lodijke</div>
      <input
        v-model="menuFilter"
        type="text"
        placeholder="Filter hoofdstuk..."
        class="w-full px-2.5 py-1 bg-white text-black rounded text-xs placeholder-gray-500"
      />
    </div>

    <div class="flex-1 overflow-y-auto p-3 space-y-4 bg-zeeuws-sand text-xs">
      <div class="space-y-1.5">
        <div class="font-mono font-bold text-[10px] text-meekrab-800 uppercase tracking-wider px-1">1. Genealogie &amp; Dossiers</div>

        <div v-if="matches('stamboom genealogie kwartierstaat avg schot bout')" class="bg-white border border-zeeuws-border rounded-md p-2 space-y-1">
          <div class="flex items-center justify-between">
            <button @click="store.switchTab('tabGenealogie')" class="font-bold text-zinc-900 hover:text-meekrab-700">01. Stamboom &amp; AVG</button>
            <button @click="store.openInSecondaryViewport('stamboom')" class="text-[10px] text-meekrab-700 font-semibold">+ VP 2</button>
          </div>
          <div class="grid grid-cols-2 gap-1 text-[11px]">
            <button @click="store.switchTab('tabGenealogie', 'subGenBoom')" class="px-1.5 py-0.5 bg-zeeuws-sand rounded text-left">1A. Boom</button>
            <button @click="store.switchTab('tabGenealogie', 'subGenTakken')" class="px-1.5 py-0.5 bg-zeeuws-sand rounded text-left">1B. 13 Kinderen</button>
            <button @click="store.switchTab('tabGenealogie', 'subGenKwartier')" class="px-1.5 py-0.5 bg-zeeuws-sand rounded text-left">1C. Kwartierstaat</button>
            <button @click="store.switchTab('tabGenealogie', 'subGenPrivacy')" class="px-1.5 py-0.5 bg-zeeuws-sand rounded text-left">1D. AVG-Schild</button>
          </div>
        </div>

        <div v-if="matches('fotoalbum uploads beeldbank fotos camera solid pod')" class="bg-white border border-zeeuws-border rounded-md p-2 space-y-1">
          <div class="flex items-center justify-between">
            <button @click="store.switchTab('tabFotos')" class="font-bold text-zinc-900 hover:text-meekrab-700">02. Fotoalbum &amp; Uploads</button>
            <button @click="store.openInSecondaryViewport('fotos')" class="text-[10px] text-meekrab-700 font-semibold">+ VP 2</button>
          </div>
          <div class="grid grid-cols-2 gap-1 text-[11px]">
            <button @click="store.switchTab('tabFotos', 'subFotosOverzicht')" class="px-1.5 py-0.5 bg-zeeuws-sand rounded text-left">2A. Galerij</button>
            <button @click="store.switchTab('tabFotos', 'subFotosUpload')" class="px-1.5 py-0.5 bg-zeeuws-sand rounded text-left">2B. Uploaden</button>
            <button @click="store.switchTab('tabFotos', 'subFotosFilter')" class="px-1.5 py-0.5 bg-zeeuws-sand rounded text-left">2C. Filter</button>
            <button @click="store.switchTab('tabFotos', 'subFotosBackup')" class="px-1.5 py-0.5 bg-zeeuws-sand rounded text-left">2D. JSON POD</button>
          </div>
        </div>

        <div v-if="matches('documenten dossiers bw schot regenten hofsteden kruittoren watersnood 1906')" class="bg-white border border-zeeuws-border rounded-md p-2 space-y-1">
          <div class="flex items-center justify-between">
            <button @click="store.switchTab('tabDocumenten')" class="font-bold text-zinc-900 hover:text-meekrab-700">03. Dossier B.W. Schot</button>
            <button @click="store.openInSecondaryViewport('dossier')" class="text-[10px] text-meekrab-700 font-semibold">+ VP 2</button>
          </div>
          <div class="grid grid-cols-2 gap-1 text-[11px]">
            <button @click="store.switchTab('tabDocumenten', 'docA')" class="px-1.5 py-0.5 bg-zeeuws-sand rounded text-left">B.W. Schot (6)</button>
            <button @click="store.switchTab('tabDocumenten', 'docB')" class="px-1.5 py-0.5 bg-zeeuws-sand rounded text-left">Regenten</button>
            <button @click="store.switchTab('tabDocumenten', 'docC')" class="px-1.5 py-0.5 bg-zeeuws-sand rounded text-left">Akten 1901/13</button>
            <button @click="store.switchTab('tabDocumenten', 'docNew')" class="px-1.5 py-0.5 bg-zeeuws-sand rounded text-left">+ Nieuw</button>
          </div>
        </div>
      </div>

      <div class="space-y-1.5">
        <div class="font-mono font-bold text-[10px] text-meekrab-800 uppercase tracking-wider px-1">2. Kaarten &amp; Scheepsbouw</div>
        <div v-if="matches('zeekaart bol van lodijke perceel 369 oosterschelde')" class="bg-white border border-zeeuws-border rounded-md p-2 flex items-center justify-between">
          <button @click="store.switchTab('tabKaarten')" class="font-bold text-zinc-900 hover:text-meekrab-700 text-left">04. Zeekaart Perceel 369</button>
          <button @click="store.openInSecondaryViewport('zeekaart')" class="text-[10px] text-meekrab-700 font-semibold">+ VP 2</button>
        </div>
        <div v-if="matches('plattegronden hoogaars th 2 eben haezer klepduiker')" class="bg-white border border-zeeuws-border rounded-md p-2 flex items-center justify-between">
          <button @click="store.switchTab('tabPlattegronden')" class="font-bold text-zinc-900 hover:text-meekrab-700 text-left">05. Hoogaars TH 2 &amp; Sluis</button>
          <button @click="store.openInSecondaryViewport('plattegronden')" class="text-[10px] text-meekrab-700 font-semibold">+ VP 2</button>
        </div>
      </div>

      <div class="space-y-1.5">
        <div class="font-mono font-bold text-[10px] text-meekrab-800 uppercase tracking-wider px-1">3. Onderzoeksregisters (DB)</div>
        <div v-if="matches('archeologie vondsten kasteel lodijke reimerswaal')" class="bg-white border border-zeeuws-border rounded-md p-2 flex items-center justify-between">
          <button @click="store.switchTab('tabArcheologie')" class="font-bold text-zinc-900 hover:text-meekrab-700 text-left">06. Archeologie Lodijke</button>
          <button @click="store.openInSecondaryViewport('archeologie')" class="text-[10px] text-meekrab-700 font-semibold">+ VP 2</button>
        </div>
        <div v-if="matches('geologie boorprofielen bodem klei veen')" class="bg-white border border-zeeuws-border rounded-md p-2 flex items-center justify-between">
          <button @click="store.switchTab('tabGeologie')" class="font-bold text-zinc-900 hover:text-meekrab-700 text-left">07. Geologie &amp; Boringen</button>
          <button @click="store.openInSecondaryViewport('geologie')" class="text-[10px] text-meekrab-700 font-semibold">+ VP 2</button>
        </div>
        <div v-if="matches('percelen kadaster historie gortzak kandia gemeten')" class="bg-white border border-zeeuws-border rounded-md p-2 flex items-center justify-between">
          <button @click="store.switchTab('tabKadaster')" class="font-bold text-zinc-900 hover:text-meekrab-700 text-left">08. Percelen &amp; Gemeten</button>
          <button @click="store.openInSecondaryViewport('kadaster')" class="text-[10px] text-meekrab-700 font-semibold">+ VP 2</button>
        </div>
      </div>

      <div class="space-y-1.5">
        <div class="font-mono font-bold text-[10px] text-meekrab-800 uppercase tracking-wider px-1">4. Bestuursrecht &amp; AvoRed CMS</div>
        <div v-if="matches('woo besluiten commissies rechters awb')" class="bg-white border border-zeeuws-border rounded-md p-2 flex items-center justify-between">
          <button @click="store.switchTab('tabWoo')" class="font-bold text-zinc-900 hover:text-meekrab-700 text-left">09. Woo &amp; Rechtbank</button>
          <button @click="store.openInSecondaryViewport('woo')" class="text-[10px] text-meekrab-700 font-semibold">+ VP 2</button>
        </div>
        <div v-if="matches('google sites viewport generator nieuw tabblad')" class="bg-white border border-zeeuws-border rounded-md p-2 flex items-center justify-between">
          <button @click="store.switchTab('tabUitbreiding')" class="font-bold text-zinc-900 hover:text-meekrab-700 text-left">10. Eigen Tabs &amp; Embed</button>
        </div>
        <div v-if="matches('avored rust axum cms api backend server solid pod')" class="bg-meekrab-50 border border-meekrab-700 rounded-md p-2 flex items-center justify-between">
          <button @click="store.switchTab('tabRustCms')" class="font-bold text-meekrab-800 text-left">11. AvoRed Rust CMS</button>
          <button @click="store.openInSecondaryViewport('rustcms')" class="text-[10px] text-meekrab-700 font-semibold">+ VP 2</button>
        </div>
      </div>
    </div>

    <div class="p-2.5 bg-zinc-900 text-white flex items-center justify-between text-[11px] font-mono">
      <span>STANDAARD: A+ ({{ store.fontSizePx }}PX)</span>
      <button @click="store.viewportMode = 'split'" class="px-2 py-0.5 bg-meekrab-700 text-white rounded font-sans font-semibold">Split-VP</button>
    </div>
  </aside>
</template>

<script setup>
import { ref } from 'vue';
import { store } from '../store/archiveStore.js';

const menuFilter = ref('');

function matches(keywords) {
  const q = menuFilter.value.toLowerCase().trim();
  if (!q) return true;
  return keywords.toLowerCase().includes(q);
}

function closeLeft() {
  store.leftDrawerPinned = false;
  store.leftDrawerOpen = false;
}
</script>
