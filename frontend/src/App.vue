<template>
  <div :class="[{ 'drawer-pinned': store.leftDrawerPinned }, 'flex flex-col pb-16 lg:pb-8 min-h-screen']">
    <!-- TOAST MELDING -->
    <div
      v-if="store.toastMessage"
      class="fixed top-4 left-1/2 -translate-x-1/2 z-[70] max-w-lg w-[90vw] bg-meekrab-800 text-white border border-white shadow-xl rounded-lg p-3"
    >
      <div class="flex items-center justify-between gap-3">
        <div class="font-medium text-xs sm:text-sm">{{ store.toastMessage }}</div>
        <button @click="store.toastMessage = ''" class="px-2.5 py-1 bg-white text-meekrab-900 rounded text-xs font-bold">Sluiten</button>
      </div>
    </div>

    <!-- SCHUIFMENU LINKS & RECHTS -->
    <LeftDrawer />
    <RightInspector />

    <!-- HOOFDSCHIL -->
    <div class="app-shell-content flex-1 flex flex-col transition-all duration-200">
      <TopHeader />

      <!-- AVG-WAARBORG & VIEWPORT BALK -->
      <section class="bg-white border-b border-zeeuws-border px-4 py-1.5">
        <div class="max-w-[1520px] mx-auto flex flex-wrap items-center justify-between gap-2 text-xs">
          <div class="flex items-center gap-2">
            <span class="px-2 py-0.5 bg-zinc-800 text-white font-mono rounded text-[11px]">AVG-Waarborg</span>
            <span class="text-zinc-700">Namen van mijzelf, broer, vader en moeder zijn afgeschermd.</span>
          </div>
          <div class="flex items-center gap-1.5">
            <button
              @click="store.viewportMode = 'single'"
              :class="store.viewportMode === 'single' ? 'px-2.5 py-1 rounded bg-meekrab-700 text-white font-semibold' : 'px-2.5 py-1 rounded bg-zeeuws-sand text-zinc-800 border border-zeeuws-border font-semibold'"
            >1 Viewport</button>
            <button
              @click="store.viewportMode = 'split'"
              :class="store.viewportMode === 'split' ? 'px-2.5 py-1 rounded bg-meekrab-700 text-white font-semibold' : 'px-2.5 py-1 rounded bg-zeeuws-sand text-zinc-800 border border-zeeuws-border font-semibold'"
            >2 Viewports naast elkaar</button>
            <button
              @click="store.viewportMode = 'stacked'"
              :class="store.viewportMode === 'stacked' ? 'px-2.5 py-1 rounded bg-meekrab-700 text-white font-semibold' : 'px-2.5 py-1 rounded bg-zeeuws-sand text-zinc-800 border border-zeeuws-border font-semibold'"
            >Gestapeld</button>
          </div>
        </div>
      </section>

      <!-- GLOBALE ZOEKRESULTATEN -->
      <section v-if="store.globalSearchQuery.trim()" class="bg-meekrab-50 border-b border-meekrab-200 px-4 py-2">
        <div class="max-w-[1520px] mx-auto flex items-center justify-between text-xs">
          <div class="font-medium text-meekrab-950">
            Zoekterm <strong>"{{ store.globalSearchQuery }}"</strong>:
            <button @click="store.switchTab('tabFotos')" class="underline font-bold mx-1">{{ searchPhotoHits }} foto's</button> |
            <button @click="store.switchTab('tabRustCms')" class="underline font-bold mx-1">{{ searchCmsHits }} AvoRed CMS-records</button>
          </div>
          <button @click="store.globalSearchQuery = ''" class="px-2 py-0.5 bg-meekrab-700 text-white rounded font-semibold">Sluit</button>
        </div>
      </section>

      <!-- HORIZONTALE TABSTRIP -->
      <nav class="bg-zeeuws-sand border-b border-zeeuws-border sticky top-[56px] z-30" aria-label="Hoofdtabbladen">
        <div class="max-w-[1520px] mx-auto px-2 sm:px-4 flex items-center gap-1.5">
          <button @click="scrollStrip(-280)" class="px-2 py-1 bg-white border border-zeeuws-border rounded text-xs font-mono font-bold">&lsaquo;</button>
          <div ref="tabStripRef" class="sliding-tab-strip flex-1">
            <button
              v-for="t in mainTabs"
              :key="t.id"
              @click="store.switchTab(t.id)"
              :class="['folder-tab-btn', { 'folder-tab-active': store.activeTab === t.id }]"
            >{{ t.label }}</button>
            <button
              v-for="ct in store.customMainTabs"
              :key="ct.id"
              @click="store.switchTab(ct.id)"
              :class="['folder-tab-btn', { 'folder-tab-active': store.activeTab === ct.id }]"
            >{{ ct.name }}</button>
          </div>
          <button @click="scrollStrip(280)" class="px-2 py-1 bg-white border border-zeeuws-border rounded text-xs font-mono font-bold">&rsaquo;</button>
        </div>
      </nav>

      <!-- MULTI-VIEWPORT WERKGEBIED -->
      <main class="flex-1 max-w-[1520px] w-full mx-auto p-3 sm:p-5">
        <div :class="viewportGridClass">
          <!-- VIEWPORT 1 -->
          <section class="bg-white border border-zeeuws-border rounded-xl p-4 sm:p-5 shadow-sm space-y-4">
            <div class="flex items-center justify-between pb-2.5 border-b border-zeeuws-border">
              <div class="flex items-center gap-2">
                <span class="px-2 py-0.5 bg-meekrab-700 text-white font-mono text-xs rounded">Viewport 1</span>
                <h2 class="font-serif font-bold text-base sm:text-lg text-zinc-900">{{ currentTabTitle }}</h2>
              </div>
              <button @click="store.rightDrawerOpen = true" class="text-xs font-mono text-meekrab-700 underline">Inspectiepaneel</button>
            </div>

            <Tab01Genealogie v-if="store.activeTab === 'tabGenealogie'" />
            <Tab02Fotos v-else-if="store.activeTab === 'tabFotos'" />
            <Tab03Documenten v-else-if="store.activeTab === 'tabDocumenten'" />
            <Tab04Kaarten v-else-if="store.activeTab === 'tabKaarten'" />
            <Tab05Plattegronden v-else-if="store.activeTab === 'tabPlattegronden'" />
            <Tab06Archeologie v-else-if="store.activeTab === 'tabArcheologie'" />
            <Tab07Geologie v-else-if="store.activeTab === 'tabGeologie'" />
            <Tab08Kadaster v-else-if="store.activeTab === 'tabKadaster'" />
            <Tab09Woo v-else-if="store.activeTab === 'tabWoo'" />
            <Tab10Uitbreiding v-else-if="store.activeTab === 'tabUitbreiding'" />
            <Tab11AvoRedCms v-else-if="store.activeTab === 'tabRustCms'" />

            <div
              v-for="ct in store.customMainTabs"
              :key="ct.id"
              v-show="store.activeTab === ct.id"
              class="p-4 bg-zeeuws-sand border border-zeeuws-border rounded-lg space-y-2"
            >
              <div class="font-serif font-bold text-base text-meekrab-800">{{ ct.name }} ({{ ct.type }})</div>
              <p class="text-sm whitespace-pre-line">{{ ct.body }}</p>
            </div>
          </section>

          <!-- VIEWPORT 2 -->
          <SecondaryViewport v-if="store.viewportMode !== 'single'" />
        </div>
      </main>

      <footer class="bg-zinc-900 text-zinc-300 py-4 px-4 mt-8 text-xs">
        <div class="max-w-[1520px] mx-auto flex flex-col sm:flex-row items-center justify-between gap-2">
          <div>Archiefplatform Familie Schot &amp; Bout — Tholen, Scherpenisse &amp; Bol van Lodijke (1684–1935)</div>
          <div class="font-mono text-zinc-400">Standaard A+ ({{ store.fontSizePx }}px) • Vue 3 + AvoRed Rust CMS • Solid POD • AVG-Compliant</div>
        </div>
      </footer>
    </div>

    <!-- FOTO LIGHTBOX MODAL -->
    <div v-if="store.lightboxPhoto" class="fixed inset-0 bg-black/80 z-[65] flex items-center justify-center p-4">
      <div class="bg-white border border-zeeuws-border rounded-xl max-w-4xl w-full p-4 sm:p-5 space-y-3 shadow-2xl">
        <div class="flex items-center justify-between border-b border-zeeuws-border pb-2">
          <div>
            <span class="px-2 py-0.5 bg-meekrab-700 text-white font-mono text-xs rounded">{{ store.lightboxPhoto.category }}</span>
            <h3 class="font-serif font-bold text-base sm:text-lg text-zinc-900 mt-1">{{ store.lightboxPhoto.title }}</h3>
          </div>
          <button @click="store.lightboxPhoto = null" class="ui-btn bg-meekrab-700 text-white">Sluiten</button>
        </div>
        <div class="bg-zeeuws-sand rounded-lg p-2 flex items-center justify-center max-h-[58dvh] overflow-hidden">
          <img :src="store.lightboxPhoto.dataUrl" :alt="store.lightboxPhoto.title" class="max-h-[54dvh] w-auto object-contain rounded" />
        </div>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-2 text-xs bg-zeeuws-sand p-3 rounded-lg">
          <div><strong>Datering:</strong> {{ store.lightboxPhoto.year }}</div>
          <div><strong>Locatie:</strong> {{ store.lightboxPhoto.location }}</div>
          <div><strong>Bestand:</strong> <span class="font-mono">{{ store.lightboxPhoto.dimensions }} ({{ store.lightboxPhoto.sizeText }})</span></div>
          <div class="md:col-span-3"><strong>Toelichting:</strong> {{ store.lightboxPhoto.desc }}</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { store } from './store/archiveStore.js';
import TopHeader from './components/TopHeader.vue';
import LeftDrawer from './components/LeftDrawer.vue';
import RightInspector from './components/RightInspector.vue';
import SecondaryViewport from './components/SecondaryViewport.vue';
import Tab01Genealogie from './components/tabs/Tab01Genealogie.vue';
import Tab02Fotos from './components/tabs/Tab02Fotos.vue';
import Tab03Documenten from './components/tabs/Tab03Documenten.vue';
import Tab04Kaarten from './components/tabs/Tab04Kaarten.vue';
import Tab05Plattegronden from './components/tabs/Tab05Plattegronden.vue';
import Tab06Archeologie from './components/tabs/Tab06Archeologie.vue';
import Tab07Geologie from './components/tabs/Tab07Geologie.vue';
import Tab08Kadaster from './components/tabs/Tab08Kadaster.vue';
import Tab09Woo from './components/tabs/Tab09Woo.vue';
import Tab10Uitbreiding from './components/tabs/Tab10Uitbreiding.vue';
import Tab11AvoRedCms from './components/tabs/Tab11AvoRedCms.vue';

const tabStripRef = ref(null);

const mainTabs = [
  { id: 'tabGenealogie', label: '01. Stamboom & AVG', title: '01. Stamboom & Kwartierstaat (AVG-Afgeschermd)' },
  { id: 'tabFotos', label: '02. Fotoalbum & Uploads', title: '02. Solid POD Fotoalbum & Uploads' },
  { id: 'tabDocumenten', label: '03. Dossier B.W. Schot', title: '03. Historisch Dossier B.W. Schot (1840–1935)' },
  { id: 'tabKaarten', label: '04. Zeekaart Perceel 369', title: '04. Zeekaart Bol van Lodijke (Perceel 369) & Kadaster' },
  { id: 'tabPlattegronden', label: '05. Hoogaars TH 2 & Sluis', title: '05. Lijnenplan Hoogaars TH 2 & Polder-Klepduiker' },
  { id: 'tabArcheologie', label: '06. Archeologie DB', title: '06. Archeologisch Onderzoek Bol van Lodijke' },
  { id: 'tabGeologie', label: '07. Geologie DB', title: '07. Geologie & Boorprofielen Tholen' },
  { id: 'tabKadaster', label: '08. Percelen & Gemeten', title: '08. Kadastrale Percelen & Zeeuwse Gemeten Calculator' },
  { id: 'tabWoo', label: '09. Woo & Rechtbank', title: '09. Bestuursrechtelijke Keten (Woo & Rechtbank)' },
  { id: 'tabUitbreiding', label: '10. Eigen Tabs & Embed', title: '10. Eigen Tabbladen & Google Sites Embed' },
  { id: 'tabRustCms', label: '11. AvoRed Rust CMS', title: '11. AvoRed Rust CMS & Decentrale API' }
];

const currentTabTitle = computed(() => {
  const found = mainTabs.find(t => t.id === store.activeTab);
  if (found) return found.title;
  const custom = store.customMainTabs.find(c => c.id === store.activeTab);
  return custom ? custom.name : store.activeTab;
});

const viewportGridClass = computed(() => {
  if (store.viewportMode === 'split') return 'viewport-grid-split';
  if (store.viewportMode === 'stacked') return 'viewport-grid-stacked';
  return 'viewport-grid-single';
});

const searchPhotoHits = computed(() => {
  const q = store.globalSearchQuery.toLowerCase().trim();
  if (!q) return 0;
  return store.photos.filter(p => p.title.toLowerCase().includes(q) || p.desc.toLowerCase().includes(q)).length;
});

const searchCmsHits = computed(() => {
  const q = store.globalSearchQuery.toLowerCase().trim();
  if (!q) return 0;
  return store.cmsRecords.filter(c => c.title.toLowerCase().includes(q) || c.body.toLowerCase().includes(q)).length;
});

function scrollStrip(dx) {
  tabStripRef.value?.scrollBy({ left: dx, behavior: 'smooth' });
}

onMounted(() => {
  store.loadLocalPhotos();
  store.syncBackend(true);
});
</script>
