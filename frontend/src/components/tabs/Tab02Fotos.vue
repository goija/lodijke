<template>
  <div class="space-y-4">
    <div class="flex flex-wrap items-center justify-between gap-2 bg-zeeuws-sand p-2 rounded-lg border border-zeeuws-border">
      <div class="flex flex-wrap gap-1.5">
        <button @click="store.subTabs.tabFotos = 'subFotosOverzicht'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabFotos === 'subFotosOverzicht' }]">2A. Fotogalerij</button>
        <button @click="store.subTabs.tabFotos = 'subFotosUpload'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabFotos === 'subFotosUpload' }]">2B. Foto Uploaden</button>
        <button @click="store.subTabs.tabFotos = 'subFotosFilter'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabFotos === 'subFotosFilter' }]">2C. Categorieën</button>
        <button @click="store.subTabs.tabFotos = 'subFotosBackup'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabFotos === 'subFotosBackup' }]">2D. Solid POD JSON</button>
      </div>
      <span class="font-mono text-xs text-zinc-600 font-semibold">{{ filteredPhotos.length }} van {{ store.photos.length }} items</span>
    </div>

    <div v-if="store.subTabs.tabFotos === 'subFotosUpload'" class="bg-zeeuws-sand border border-zeeuws-border rounded-lg p-4 space-y-3">
      <div
        @dragover.prevent
        @drop.prevent="onFileDrop"
        class="border-2 border-dashed border-meekrab-700 bg-white rounded-lg p-4 text-center space-y-2"
      >
        <div class="font-semibold text-sm">Sleep uw foto's hierheen of kies bestanden vanaf uw toestel</div>
        <label class="ui-btn bg-meekrab-700 text-white cursor-pointer">
          Kies Foto's
          <input type="file" accept="image/*" multiple class="hidden" @change="onFileSelect" />
        </label>
        <div class="text-xs font-mono text-zinc-600">
          {{ pendingFiles.length ? `${pendingFiles.length} bestand(en) geselecteerd.` : 'Nog geen bestand geselecteerd.' }}
        </div>
      </div>
      <div class="grid grid-cols-1 md:grid-cols-4 gap-2.5">
        <input v-model="upTitle" type="text" placeholder="Titel van de foto" class="ui-input" />
        <select v-model="upCategory" class="ui-input">
          <option value="Eigen Collectie">Eigen Collectie</option>
          <option value="Vloot TH 2 / TH 12 / TH 90">Vloot TH 2 / TH 12 / TH 90</option>
          <option value="Kruittoren 23 & Contr'Escarpe">Kruittoren 23 &amp; Contr'Escarpe</option>
          <option value="Bol van Lodijke & Percelen">Bol van Lodijke &amp; Percelen</option>
        </select>
        <input v-model="upYear" type="text" placeholder="Jaar (bijv. 1902)" class="ui-input" />
        <input v-model="upLocation" type="text" placeholder="Locatie (bijv. Tholen)" class="ui-input" />
        <input v-model="upDesc" type="text" placeholder="Toelichting..." class="ui-input md:col-span-4" />
      </div>
      <button @click="processUpload" class="ui-btn bg-meekrab-700 text-white">Toevoegen aan Fotoalbum</button>
    </div>

    <div v-else-if="store.subTabs.tabFotos === 'subFotosFilter'" class="p-3.5 bg-zeeuws-sand border border-zeeuws-border rounded-lg flex flex-wrap gap-2">
      <button @click="setCategory('ALLE')" class="ui-btn bg-meekrab-700 text-white">Alle Foto's</button>
      <button @click="setCategory('Vloot TH 2 / TH 12 / TH 90')" class="ui-btn bg-white border border-zeeuws-border">Vloot TH 2 / 12 / 90</button>
      <button @click="setCategory('Bol van Lodijke & Percelen')" class="ui-btn bg-white border border-zeeuws-border">Bol van Lodijke 369</button>
    </div>

    <div v-else-if="store.subTabs.tabFotos === 'subFotosBackup'" class="p-3.5 bg-zeeuws-sand border border-zeeuws-border rounded-lg flex flex-wrap gap-2">
      <button @click="exportPhotos" class="ui-btn bg-meekrab-700 text-white">Exporteer Fotoalbum JSON</button>
      <label class="ui-btn bg-white border border-zeeuws-border cursor-pointer">
        Importeer JSON
        <input type="file" accept=".json" class="hidden" @change="importPhotos" />
      </label>
    </div>

    <div v-else class="space-y-3">
      <div class="flex flex-wrap items-center justify-between gap-2">
        <div class="flex flex-wrap gap-1.5">
          <button @click="categoryFilter = 'ALLE'" class="px-2.5 py-1 bg-meekrab-700 text-white rounded text-xs font-semibold">Alle</button>
          <button @click="categoryFilter = 'Vloot TH 2 / TH 12 / TH 90'" class="px-2.5 py-1 bg-zeeuws-sand border border-zeeuws-border rounded text-xs font-semibold">Vloot TH 2/12/90</button>
          <button @click="categoryFilter = 'Bol van Lodijke & Percelen'" class="px-2.5 py-1 bg-zeeuws-sand border border-zeeuws-border rounded text-xs font-semibold">Perceel 369</button>
        </div>
        <div class="flex items-center gap-1.5">
          <input v-model="photoSearch" type="text" placeholder="Filter foto's..." class="px-2.5 py-1 bg-white border border-zeeuws-border rounded text-xs" />
          <button @click="layoutMode = 'cards'" :class="layoutMode === 'cards' ? 'px-2.5 py-1 bg-meekrab-700 text-white rounded text-xs' : 'px-2.5 py-1 bg-white border border-zeeuws-border rounded text-xs'">Kaarten</button>
          <button @click="layoutMode = 'table'" :class="layoutMode === 'table' ? 'px-2.5 py-1 bg-meekrab-700 text-white rounded text-xs' : 'px-2.5 py-1 bg-white border border-zeeuws-border rounded text-xs'">Tabel</button>
        </div>
      </div>

      <div v-if="layoutMode === 'cards'" class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <article
          v-for="item in filteredPhotos"
          :key="item.id"
          class="bg-white border border-zeeuws-border rounded-lg overflow-hidden flex flex-col justify-between"
        >
          <div>
            <div class="bg-zeeuws-sand border-b border-zeeuws-border px-3 py-1.5 flex items-center justify-between text-xs font-mono">
              <span class="text-meekrab-800 font-semibold">{{ item.category }}</span>
              <span>{{ item.year }}</span>
            </div>
            <div class="p-2.5 bg-zeeuws-sand flex items-center justify-center">
              <img
                :src="item.dataUrl"
                :alt="item.title"
                @click="store.lightboxPhoto = item"
                class="w-full h-52 object-contain bg-white rounded border border-zeeuws-border cursor-pointer"
              />
            </div>
            <div class="p-3.5 space-y-1">
              <h3 class="font-serif font-bold text-base text-zinc-900">{{ item.title }}</h3>
              <p class="text-xs sm:text-sm text-zinc-700">{{ item.desc }}</p>
            </div>
          </div>
          <div class="px-3.5 pb-3.5 flex items-center justify-between gap-2">
            <span class="text-xs font-mono text-zinc-500">{{ item.location }}</span>
            <button @click="store.lightboxPhoto = item" class="px-3 py-1 bg-meekrab-700 text-white rounded text-xs font-semibold">Vergroot</button>
          </div>
        </article>
      </div>

      <div v-else class="overflow-x-auto border border-zeeuws-border rounded-lg">
        <table class="w-full text-left border-collapse text-xs sm:text-sm">
          <thead class="bg-meekrab-800 text-white font-mono text-xs">
            <tr><th class="p-2.5">Beeld</th><th class="p-2.5">Titel</th><th class="p-2.5">Jaar &amp; Locatie</th><th class="p-2.5">Actie</th></tr>
          </thead>
          <tbody class="divide-y divide-zeeuws-border">
            <tr v-for="item in filteredPhotos" :key="item.id">
              <td class="p-2.5 w-28">
                <img :src="item.dataUrl" :alt="item.title" class="w-24 h-16 object-cover rounded cursor-pointer" @click="store.lightboxPhoto = item" />
              </td>
              <td class="p-2.5 font-bold">{{ item.title }}<div class="text-xs font-normal text-zinc-600">{{ item.desc }}</div></td>
              <td class="p-2.5 text-xs">{{ item.year }} | {{ item.location }}</td>
              <td class="p-2.5"><button @click="store.lightboxPhoto = item" class="px-2.5 py-1 bg-meekrab-700 text-white rounded text-xs">Vergroot</button></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import { store } from '../../store/archiveStore.js';

const categoryFilter = ref('ALLE');
const photoSearch = ref('');
const layoutMode = ref('cards');
const pendingFiles = ref([]);
const upTitle = ref('');
const upCategory = ref('Eigen Collectie');
const upYear = ref('');
const upLocation = ref('');
const upDesc = ref('');

const filteredPhotos = computed(() => {
  const q = photoSearch.value.toLowerCase().trim();
  return store.photos.filter(item => {
    const matchCat = categoryFilter.value === 'ALLE' || item.category === categoryFilter.value;
    const matchQ = !q || item.title.toLowerCase().includes(q) || item.desc.toLowerCase().includes(q);
    return matchCat && matchQ;
  });
});

function setCategory(cat) {
  categoryFilter.value = cat;
  store.subTabs.tabFotos = 'subFotosOverzicht';
}

function onFileSelect(e) {
  if (e.target?.files?.length) pendingFiles.value = Array.from(e.target.files);
}
function onFileDrop(e) {
  if (e.dataTransfer?.files?.length) pendingFiles.value = Array.from(e.dataTransfer.files);
}

function processUpload() {
  if (!pendingFiles.value.length) {
    store.showToast('Selecteer eerst een foto.');
    return;
  }
  let done = 0;
  pendingFiles.value.forEach((file, idx) => {
    const reader = new FileReader();
    reader.onload = evt => {
      const dataUrl = evt.target.result;
      store.photos.unshift({
        id: 'upload-' + Date.now() + '-' + idx,
        title: upTitle.value.trim() || file.name.replace(/\.[^/.]+$/, ''),
        category: upCategory.value,
        year: upYear.value.trim() || 'Archief',
        location: upLocation.value.trim() || 'Tholen',
        desc: upDesc.value.trim() || 'Geüploade archieffoto.',
        dimensions: 'Origineel',
        sizeText: `${Math.round(file.size / 1024)} KB`,
        dataUrl
      });
      done++;
      if (done === pendingFiles.value.length) {
        store.saveLocalPhotos();
        pendingFiles.value = [];
        store.subTabs.tabFotos = 'subFotosOverzicht';
        store.showToast('Foto toegevoegd aan Solid POD Fotoalbum.');
      }
    };
    reader.readAsDataURL(file);
  });
}

function exportPhotos() {
  const a = document.createElement('a');
  a.href = 'data:text/json;charset=utf-8,' + encodeURIComponent(JSON.stringify(store.photos, null, 2));
  a.download = 'solid-pod-fotoalbum-schot-tholen.json';
  a.click();
}

function importPhotos(e) {
  const file = e.target.files?.[0];
  if (!file) return;
  const r = new FileReader();
  r.onload = evt => {
    try {
      const parsed = JSON.parse(evt.target.result);
      if (Array.isArray(parsed)) {
        store.photos = parsed;
        store.saveLocalPhotos();
        store.showToast('Fotoalbum JSON geïmporteerd.');
      }
    } catch (err) {
      store.showToast('Ongeldig JSON-bestand.');
    }
  };
  r.readAsText(file);
}
</script>
