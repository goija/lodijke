<template>
  <header class="bg-meekrab-800 text-white border-b border-meekrab-950 sticky top-0 z-40">
    <div class="max-w-[1520px] mx-auto px-4 py-2.5 flex flex-col lg:flex-row lg:items-center lg:justify-between gap-2.5">
      <div class="flex items-center gap-2.5">
        <button @click="store.leftDrawerOpen = !store.leftDrawerOpen" class="ui-btn bg-white text-meekrab-900 hover:bg-meekrab-50">Menu</button>
        <div>
          <h1 class="font-serif font-bold text-base sm:text-lg text-white leading-tight">
            Archief Familie Schot, Bout &amp; Van Vrijberghe — Tholen &amp; Bol van Lodijke
          </h1>
          <p class="text-xs text-meekrab-100">
            Dossier B.W. Schot (1840–1935) • Perceel No. 369 (12,5 ha) • Hoogaarzen TH 2, TH 12 &amp; TH 90 • AvoRed Rust CMS
          </p>
        </div>
      </div>

      <div class="flex flex-wrap items-center gap-2">
        <input
          v-model="store.globalSearchQuery"
          type="text"
          placeholder="Zoek in archief..."
          class="w-44 sm:w-52 px-2.5 py-1.5 bg-white text-black rounded text-xs font-medium placeholder-gray-500"
        />
        <div class="flex items-center bg-meekrab-950 p-0.5 rounded border border-meekrab-600" role="group" aria-label="Lettergrootte">
          <button
            @click="store.setFontSize(17)"
            :class="store.fontSizePx === 17 ? 'px-2.5 py-1 rounded text-xs font-bold bg-white text-meekrab-950 shadow-sm' : 'px-2 py-1 rounded text-xs font-semibold text-white'"
          >A</button>
          <button
            @click="store.setFontSize(19)"
            :class="store.fontSizePx === 19 ? 'px-2.5 py-1 rounded text-xs font-bold bg-white text-meekrab-950 shadow-sm' : 'px-2 py-1 rounded text-xs font-semibold text-white'"
          >A+</button>
          <button
            @click="store.setFontSize(22)"
            :class="store.fontSizePx === 22 ? 'px-2.5 py-1 rounded text-xs font-bold bg-white text-meekrab-950 shadow-sm' : 'px-2 py-1 rounded text-xs font-semibold text-white'"
          >A++</button>
        </div>
        <button @click="store.switchTab('tabRustCms')" class="ui-btn bg-white/15 hover:bg-white/25 text-white border border-white/25 text-xs">
          AvoRed CMS
        </button>
      </div>
    </div>
  </header>
</template>

<script setup>
import { store } from '../store/archiveStore.js';
</script>
