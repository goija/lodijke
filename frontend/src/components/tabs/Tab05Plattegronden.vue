<template>
  <div class="space-y-4">
    <div class="flex flex-wrap gap-1.5 bg-zeeuws-sand p-2 rounded-lg border border-zeeuws-border">
      <button @click="store.subTabs.tabPlattegronden = 'subPlatHoogaars'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabPlattegronden === 'subPlatHoogaars' }]">5A. Lijnenplan Hoogaars TH 2 (1902)</button>
      <button @click="store.subTabs.tabPlattegronden = 'subPlatKlepduiker'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabPlattegronden === 'subPlatKlepduiker' }]">5B. Eikenhouten Klepduiker 1:5</button>
      <button @click="store.subTabs.tabPlattegronden = 'subPlatRegister'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabPlattegronden === 'subPlatRegister' }]">5C. Bouwregister 1901–1913</button>
    </div>

    <div v-if="store.subTabs.tabPlattegronden === 'subPlatHoogaars'" class="p-4 bg-zeeuws-sand border border-zeeuws-border rounded-lg">
      <svg viewBox="0 0 680 240" class="w-full h-auto bg-white border border-zeeuws-border rounded">
        <path d="M 50,65 Q 160,190 570,165 L 615,95 L 560,90 Q 340,110 50,65 Z" fill="#fdf7f7" stroke="#8b2229" stroke-width="2.5" />
        <ellipse cx="305" cy="145" rx="42" ry="54" fill="#8b2229" fill-opacity="0.2" stroke="#8b2229" stroke-width="2" />
        <text x="80" y="220" fill="#18181b" font-size="13" font-family="JetBrains Mono" font-weight="bold">TH 2 "Eben Haëzer" (1902) — Werf Van Duivendijk, Contr'Escarpe Tholen (14,80m x 4,35m)</text>
      </svg>
    </div>

    <div v-else-if="store.subTabs.tabPlattegronden === 'subPlatKlepduiker'" class="p-4 bg-zeeuws-sand border border-zeeuws-border rounded-lg">
      <svg viewBox="0 0 680 230" class="w-full h-auto bg-white border border-zeeuws-border rounded">
        <polygon points="55,200 230,45 415,45 595,200" fill="#f9f7f2" stroke="#8b2229" stroke-width="2.5" />
        <rect x="35" y="170" width="600" height="30" fill="#efe7d3" stroke="#18181b" stroke-width="2" />
        <text x="165" y="190" fill="#18181b" font-size="13" font-family="JetBrains Mono" font-weight="bold">Eikenhouten Polder-Klepduiker met Getijdeklep (Schaal 1:5)</text>
      </svg>
    </div>

    <div v-else class="p-4 bg-zeeuws-sand border border-zeeuws-border rounded-lg text-sm space-y-1.5">
      <div><strong>PG-01 (1902):</strong> Lijnenplan Houten Hoogaars TH 2 "Eben Haëzer" — Scheepswerf Van Duivendijk.</div>
      <div><strong>PG-02 (18e/19e eeuw):</strong> Eikenhouten Polderklepduiker Schakerloo / Scherpenisse Sectie E 1551.</div>
      <div><strong>PG-03 (1901) &amp; PG-04 (1913):</strong> Drie woningen Oud-Vossemeersepoort &amp; Oesterloods Contr'Escarpe.</div>
    </div>
  </div>
</template>

<script setup>
import { store } from '../../store/archiveStore.js';
</script>
