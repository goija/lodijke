<template>
  <div class="space-y-4">
    <div class="flex flex-wrap gap-1.5 bg-zeeuws-sand p-2 rounded-lg border border-zeeuws-border">
      <button @click="store.subTabs.tabGenealogie = 'subGenBoom'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabGenealogie === 'subGenBoom' }]">1A. Voorouderboom (AVG)</button>
      <button @click="store.subTabs.tabGenealogie = 'subGenTakken'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabGenealogie === 'subGenTakken' }]">1B. 13 Kinderen B.W. Schot</button>
      <button @click="store.subTabs.tabGenealogie = 'subGenKwartier'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabGenealogie === 'subGenKwartier' }]">1C. Kwartierstaat Tabel</button>
      <button @click="store.subTabs.tabGenealogie = 'subGenPrivacy'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabGenealogie === 'subGenPrivacy' }]">1D. AVG Toelichting</button>
    </div>

    <div v-if="store.subTabs.tabGenealogie === 'subGenBoom'" class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-3.5">
      <div class="bg-zeeuws-sand p-3 rounded-lg border border-zeeuws-border space-y-2">
        <div class="font-mono font-bold text-xs text-zinc-600 uppercase">Generatie I (Huidig)</div>
        <button @click="selectPerson('locked_self')" class="w-full text-left node-shield rounded-md p-2.5">
          <div class="font-mono text-[10px] text-zinc-300">Afgeschermd conform AVG</div>
          <div class="font-bold text-sm">Beheerder / Uzelf</div>
        </button>
        <button @click="selectPerson('locked_broer')" class="w-full text-left node-shield rounded-md p-2.5">
          <div class="font-mono text-[10px] text-zinc-300">Afgeschermd conform AVG</div>
          <div class="font-bold text-sm">Broer (Zelfde generatie)</div>
        </button>
      </div>

      <div class="bg-zeeuws-sand p-3 rounded-lg border border-zeeuws-border space-y-2">
        <div class="font-mono font-bold text-xs text-zinc-600 uppercase">Generatie II (Ouders)</div>
        <button @click="selectPerson('locked_vader')" class="w-full text-left node-shield rounded-md p-2.5">
          <div class="font-mono text-[10px] text-zinc-300">Afgeschermd conform AVG</div>
          <div class="font-bold text-sm">Vader (Niet openbaar)</div>
        </button>
        <button @click="selectPerson('locked_moeder')" class="w-full text-left node-shield rounded-md p-2.5">
          <div class="font-mono text-[10px] text-zinc-300">Afgeschermd conform AVG</div>
          <div class="font-bold text-sm">Moeder (Niet openbaar)</div>
        </button>
      </div>

      <div class="bg-zeeuws-sand p-3 rounded-lg border border-zeeuws-border space-y-2">
        <div class="font-mono font-bold text-xs text-meekrab-800 uppercase">Generatie III (Openbaar)</div>
        <button @click="selectPerson('jacob_bout')" class="w-full text-left bg-white border border-zeeuws-border rounded-md p-2.5">
          <div class="font-mono text-[10px] text-meekrab-700">Echtgenoot</div>
          <div class="font-bold text-sm">Jacob Bout</div>
          <div class="text-xs text-zinc-600">Gehuwd met C.A. Schot</div>
        </button>
        <button @click="selectPerson('cornelia_schot')" class="w-full text-left bg-white border border-zeeuws-border rounded-md p-2.5">
          <div class="font-mono text-[10px] text-meekrab-700">Dochter B.W. Schot</div>
          <div class="font-bold text-sm">Cornelia Adriana Schot</div>
          <div class="text-xs text-zinc-600">Geboren 1867 te Tholen</div>
        </button>
      </div>

      <div class="bg-zeeuws-sand p-3 rounded-lg border border-zeeuws-border space-y-2">
        <div class="font-mono font-bold text-xs text-meekrab-800 uppercase">Generatie IV &amp; V (Stamvader)</div>
        <button @click="selectPerson('bw_schot')" class="w-full text-left bg-meekrab-700 text-white rounded-md p-2.5">
          <div class="font-mono text-[10px] text-meekrab-100">Stamvader (1840–1935)</div>
          <div class="font-bold text-sm">Benjamin Willem Schot</div>
          <div class="text-xs text-meekrab-100">Reder TH 2, TH 12, TH 90</div>
        </button>
        <button @click="selectPerson('maria_bolier')" class="w-full text-left bg-white border border-zeeuws-border rounded-md p-2 text-xs">
          <strong>1e Huwelijk (1863):</strong> Maria Mathea Bolier (1840–1909, 13 kinderen)
        </button>
        <button @click="selectPerson('dina_kegge')" class="w-full text-left bg-white border border-zeeuws-border rounded-md p-2 text-xs">
          <strong>2e Huwelijk (1915):</strong> Dina Pieternella Kegge (1868–1944)
        </button>
        <button @click="selectPerson('jan_schot')" class="w-full text-left bg-white border border-zeeuws-border rounded-md p-2 text-xs">
          <strong>Ouders:</strong> Jan Schot (1814–1882) &amp; Elisabeth Josina van Dijk
        </button>
      </div>
    </div>

    <div v-else-if="store.subTabs.tabGenealogie === 'subGenTakken'" class="grid grid-cols-1 md:grid-cols-3 gap-3 text-sm">
      <div class="p-3 bg-zeeuws-sand border border-zeeuws-border rounded-lg"><strong>Jan Schot B.W.zn. (1863):</strong> Aanvraag aankoop gemeentegrond Oud-Vossemeersepoort (januari 1901) met Jacob en Cathalina Schot.</div>
      <div class="p-3 bg-zeeuws-sand border border-zeeuws-border rounded-lg"><strong>Simon Leendert Schot (1865–1942):</strong> Oester- en mosselvisser op de Zeeuwse stromen.</div>
      <div class="p-3 bg-zeeuws-sand border border-zeeuws-border rounded-lg"><strong>Cornelia Adriana Schot (1867):</strong> Trouwde met Jacob Bout te Tholen.</div>
      <div class="p-3 bg-zeeuws-sand border border-zeeuws-border rounded-lg"><strong>Willem Karel Schot (1874):</strong> Bevaarder van de hoogaars TH 90 "Vijf Gebroeders / Eben Haëzer".</div>
      <div class="p-3 bg-zeeuws-sand border border-zeeuws-border rounded-lg"><strong>Kees, Jacob &amp; Willem Schot (1912/1913):</strong> Pacht Flauwers onder Zierikzee (1912) van mr. Fokker; vergroting oesterloods Contr'Escarpe (1913) met Jacob Kegge.</div>
      <div class="p-3 bg-zeeuws-sand border border-zeeuws-border rounded-lg"><strong>Karel Jacob Dingenus Schot (1888, kleinzoon):</strong> Ontving in 1917 de hoogaars TH 90.</div>
    </div>

    <div v-else-if="store.subTabs.tabGenealogie === 'subGenKwartier'" class="overflow-x-auto border border-zeeuws-border rounded-lg">
      <table class="w-full text-left border-collapse text-xs sm:text-sm">
        <thead class="bg-meekrab-800 text-white font-mono text-xs">
          <tr><th class="p-2.5">Kwartier</th><th class="p-2.5">Naam / Status</th><th class="p-2.5">Jaren</th><th class="p-2.5">Opmerking</th></tr>
        </thead>
        <tbody class="divide-y divide-zeeuws-border">
          <tr class="bg-zinc-100"><td class="p-2.5 font-mono font-bold">1 / 1b</td><td class="p-2.5 font-semibold">Afgeschermd conform AVG (Uzelf &amp; Broer)</td><td class="p-2.5">Privacy</td><td class="p-2.5">Huidige generatie niet zichtbaar</td></tr>
          <tr class="bg-zinc-100"><td class="p-2.5 font-mono font-bold">2 &amp; 3</td><td class="p-2.5 font-semibold">Afgeschermd conform AVG (Vader &amp; Moeder)</td><td class="p-2.5">Privacy</td><td class="p-2.5">Ouderlijke generatie niet zichtbaar</td></tr>
          <tr><td class="p-2.5 font-mono font-bold text-meekrab-800">4 &amp; 5</td><td class="p-2.5 font-bold">Jacob Bout x Cornelia Adriana Schot</td><td class="p-2.5">Geb. 1867</td><td class="p-2.5">Doortrekking lijn Tholen</td></tr>
          <tr><td class="p-2.5 font-mono font-bold text-meekrab-800">10 &amp; 11</td><td class="p-2.5 font-bold">Benjamin Willem Schot x Maria Mathea Bolier</td><td class="p-2.5">1840–1935</td><td class="p-2.5">Reder TH 2, TH 12, TH 90 (13 kinderen)</td></tr>
          <tr><td class="p-2.5 font-mono font-bold text-meekrab-800">20 &amp; 21</td><td class="p-2.5 font-bold">Jan Schot x Elisabeth Josina van Dijk</td><td class="p-2.5">1814–1882</td><td class="p-2.5">Ouders van B.W. Schot</td></tr>
        </tbody>
      </table>
    </div>

    <div v-else class="p-4 bg-zeeuws-sand border border-zeeuws-border rounded-lg text-sm">
      Conform de AVG zijn alle namen en persoonsgegevens van de huidige generatie (uzelf en broer) en de ouderlijke generatie (vader en moeder) volledig afgeschermd.
    </div>

    <div class="bg-zeeuws-sand border border-zeeuws-border rounded-lg p-3.5">
      <div class="flex items-center justify-between border-b border-zeeuws-border pb-1.5">
        <div>
          <span class="px-2 py-0.5 text-xs font-mono rounded bg-meekrab-700 text-white">{{ detail.badge }}</span>
          <h3 class="font-serif font-bold text-base text-zinc-900 mt-1">{{ detail.title }}</h3>
        </div>
        <span class="text-xs font-mono text-zinc-500">ID: I0103</span>
      </div>
      <div class="mt-2 text-sm">{{ detail.body }}</div>
    </div>
  </div>
</template>

<script setup>
import { reactive } from 'vue';
import { store } from '../../store/archiveStore.js';

const detail = reactive({
  badge: 'Stamvader Dossier',
  title: 'Benjamin Willem Schot (1840–1935)',
  body: 'Geboorte & Overlijden: 26 september 1840 te Tholen – 17 november 1935 te Tholen (95 jaar oud). Woonhuis & Bedrijf: Kruittoren 23 (Wijk A 107). Pachter van Perceel No. 369 op de Bol van Lodijke (12,5 ha) en reder van de hoogaarzen TH 2, TH 12 en TH 90.'
});

function selectPerson(key) {
  if (key.startsWith('locked_')) {
    detail.badge = 'Afgeschermd conform AVG';
    detail.title = 'Persoonsgegevens Niet Openbaar';
    detail.body = 'De namen en persoonsgegevens van uzelf, uw broer, uw vader en uw moeder zijn strikt afgeschermd conform de AVG.';
  } else if (key === 'bw_schot') {
    detail.badge = 'Stamvader Dossier (1840–1935)';
    detail.title = 'Benjamin Willem Schot (26 sep 1840 – 17 nov 1935)';
    detail.body = 'Oestervisser en reder te Tholen (Kruittoren 23). Pachter van Perceel No. 369 op de Bol van Lodijke (12,5 ha) en eigenaar van de hoogaarzen TH 2, TH 12 en TH 90.';
  } else if (key === 'jacob_bout' || key === 'cornelia_schot') {
    detail.badge = 'Generatie III';
    detail.title = 'Jacob Bout x Cornelia Adriana Schot (geb. 1867)';
    detail.body = 'Cornelia Adriana Schot (geb. 1867 te Tholen), dochter van B.W. Schot en Maria Mathea Bolier, gehuwd met Jacob Bout.';
  } else if (key === 'maria_bolier') {
    detail.badge = '1e Huwelijk (1863)';
    detail.title = 'Maria Mathea Bolier (27 aug 1840 Scherpenisse – 1909)';
    detail.body = 'Moeder van de 13 kinderen uit het eerste huwelijk van Benjamin Willem Schot.';
  } else if (key === 'dina_kegge') {
    detail.badge = '2e Huwelijk (1 okt 1915)';
    detail.title = 'Dina Pieternella Kegge (1868–1944)';
    detail.body = 'Oesterkoopvrouw te Tholen, weduwe van visser Willem Frederik van der Stel.';
  } else {
    detail.badge = 'Generatie V';
    detail.title = 'Jan Schot (1814–1882) x Elisabeth Josina van Dijk (1812–1895)';
    detail.body = 'Ouders van stamvader Benjamin Willem Schot te Tholen.';
  }
}
</script>
