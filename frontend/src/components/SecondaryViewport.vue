<template>
  <aside class="bg-white border border-zeeuws-border rounded-xl p-4 sm:p-5 shadow-sm space-y-4">
    <div class="flex items-center justify-between pb-2.5 border-b border-zeeuws-border">
      <span class="px-2 py-0.5 bg-zinc-800 text-white font-mono text-xs rounded">Viewport 2</span>
      <select v-model="store.secondaryViewportTopic" class="ui-input text-xs py-1 min-h-[34px]">
        <option value="fotos">Fotoalbum &amp; Uploads</option>
        <option value="zeekaart">Zeekaart Perceel 369</option>
        <option value="dossier">Dossier B.W. Schot</option>
        <option value="stamboom">Kwartierstaat (AVG)</option>
        <option value="plattegronden">Hoogaars TH 2 &amp; Klepduiker</option>
        <option value="archeologie">Archeologie Lodijke</option>
        <option value="geologie">Geologie &amp; Boringen</option>
        <option value="kadaster">Percelen &amp; Gemeten</option>
        <option value="woo">Woo &amp; Rechtbank</option>
        <option value="rustcms">AvoRed Rust CMS</option>
      </select>
    </div>

    <div class="space-y-3 text-sm">
      <div v-if="store.secondaryViewportTopic === 'fotos'" class="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <div
          v-for="p in store.photos.slice(0, 4)"
          :key="p.id"
          class="border border-zeeuws-border rounded-lg p-2.5 bg-zeeuws-sand space-y-1.5"
        >
          <img
            :src="p.dataUrl"
            :alt="p.title"
            class="w-full h-32 object-cover rounded cursor-pointer"
            @click="store.lightboxPhoto = p"
          />
          <div class="font-bold text-xs">{{ p.title }}</div>
        </div>
      </div>

      <div v-else-if="store.secondaryViewportTopic === 'zeekaart'" class="p-3.5 bg-zeeuws-sand border border-zeeuws-border rounded-lg space-y-2">
        <div class="font-mono text-xs text-meekrab-800 font-bold">Perceel No. 369 — Bol van Lodijke</div>
        <p>12,5 hectare oesterbank in de Oosterschelde, geëxploiteerd door B.W. Schot met de hoogaarzen TH 2 en TH 90.</p>
        <button @click="store.switchTab('tabKaarten')" class="ui-btn bg-meekrab-700 text-white w-full">Open Zeekaart in Viewport 1</button>
      </div>

      <div v-else-if="store.secondaryViewportTopic === 'dossier'" class="p-3.5 bg-zeeuws-sand border border-zeeuws-border rounded-lg space-y-1.5">
        <strong>Benjamin Willem Schot (1840–1935):</strong> Kruittoren 23 Tholen, Perceel 369 Bol van Lodijke (12,5 ha), hoogaarzen TH 2, TH 12 (watersnoodredding 1906) en TH 90.
      </div>

      <div v-else-if="store.secondaryViewportTopic === 'stamboom'" class="space-y-2">
        <div class="p-2.5 bg-zinc-800 text-white rounded text-xs">Generatie I &amp; II: Afgeschermd conform AVG</div>
        <div class="p-2.5 bg-zeeuws-sand border border-zeeuws-border rounded text-xs"><strong>Generatie III:</strong> Jacob Bout x Cornelia Adriana Schot (1867)</div>
        <div class="p-2.5 bg-zeeuws-sand border border-zeeuws-border rounded text-xs"><strong>Generatie IV:</strong> B.W. Schot (1840–1935) x Maria Mathea Bolier (1840–1909)</div>
      </div>

      <div v-else-if="store.secondaryViewportTopic === 'rustcms'" class="space-y-2">
        <div v-for="c in store.cmsRecords" :key="c.id" class="p-2.5 bg-zeeuws-sand border border-zeeuws-border rounded text-xs">
          <div class="font-mono text-meekrab-700">[{{ c.category }}] {{ c.date }}</div>
          <div class="font-bold">{{ c.title }}</div>
        </div>
      </div>

      <div v-else class="p-3.5 bg-zeeuws-sand border border-zeeuws-border rounded-lg">
        Onderdeel <strong>{{ store.secondaryViewportTopic }}</strong> actief in Viewport 2.
      </div>
    </div>
  </aside>
</template>

<script setup>
import { store } from '../store/archiveStore.js';
</script>
