<template>
  <aside :class="['sliding-drawer-right', { open: store.rightDrawerOpen }]" aria-label="Detailpaneel">
    <div class="bg-meekrab-800 text-white p-3.5 flex items-center justify-between">
      <div>
        <span class="font-mono text-[11px] text-meekrab-100 uppercase">{{ store.rightInspector.badge }}</span>
        <h2 class="font-serif font-bold text-sm text-white">{{ store.rightInspector.title }}</h2>
      </div>
      <button @click="store.rightDrawerOpen = false" class="px-2.5 py-1 bg-white text-meekrab-900 rounded text-xs font-bold">Sluit</button>
    </div>
    <div class="flex-1 overflow-y-auto p-4 space-y-3 bg-zeeuws-sand text-sm">
      <div class="bg-white border border-zeeuws-border rounded-lg p-3.5 space-y-1.5">
        <div class="font-mono text-xs text-meekrab-700 font-semibold">{{ store.rightInspector.badge }}</div>
        <h3 class="font-serif font-bold text-base">{{ store.rightInspector.title }}</h3>
        <p>{{ store.rightInspector.body }}</p>
      </div>
    </div>
  </aside>
</template>

<script setup>
import { store } from '../store/archiveStore.js';
</script>
