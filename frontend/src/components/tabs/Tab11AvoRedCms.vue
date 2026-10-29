<template>
  <div class="space-y-4">
    <div class="flex flex-wrap items-center justify-between gap-2 bg-zeeuws-sand p-2 rounded-lg border border-zeeuws-border">
      <div class="flex flex-wrap gap-1.5">
        <button @click="store.subTabs.tabRustCms = 'subRustEditor'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabRustCms === 'subRustEditor' }]">11A. Content Editor</button>
        <button @click="store.subTabs.tabRustCms = 'subAvoRedCollections'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabRustCms === 'subAvoRedCollections' }]">11B. Collecties &amp; Schema</button>
        <button @click="store.subTabs.tabRustCms = 'subGraphqlExplorer'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabRustCms === 'subGraphqlExplorer' }]">11C. GraphQL &amp; PDOK WFS</button>
        <button @click="store.subTabs.tabRustCms = 'subGeojsonCms'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabRustCms === 'subGeojsonCms' }]">11D. GeoJSON (RD &amp; WGS84)</button>
        <button @click="store.subTabs.tabRustCms = 'subGitSync'" :class="['sub-tab-btn', { 'sub-tab-active': store.subTabs.tabRustCms === 'subGitSync' }]">11E. Git-Sync ({{ store.gitBranch }})</button>
      </div>
      <span class="px-2.5 py-0.5 bg-green-800 text-white font-mono text-xs rounded">{{ store.avoredStatus }}</span>
    </div>

    <!-- 11A: CONTENT EDITOR -->
    <div v-if="store.subTabs.tabRustCms === 'subRustEditor'" class="space-y-4">
      <div class="p-4 bg-zeeuws-sand border border-zeeuws-border rounded-lg space-y-3">
        <div class="flex flex-wrap items-center justify-between gap-2">
          <h3 class="font-serif font-bold text-base text-zinc-900">Nieuw Archiefstuk Publiceren (Auto-Commit naar Git)</h3>
          <button @click="store.syncBackend(false)" class="px-2.5 py-1 bg-white border border-zeeuws-border rounded text-xs font-semibold">
            Synchroniseer met 127.0.0.1:8082
          </button>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-2.5">
          <input v-model="cmsTitle" type="text" placeholder="Titel van archiefstuk..." class="ui-input" />
          <select v-model="cmsCategory" class="ui-input">
            <option value="DOSSIER_SCHOT">Dossier B.W. Schot (1840–1935)</option>
            <option value="LODIJKE_369">Bol van Lodijke Perceel 369</option>
            <option value="VLOOT_HOOGAARS">Vloot TH 2 / TH 12 / TH 90</option>
            <option value="WOO_BESLUIT">Woo-Besluit / Rechtbank</option>
          </select>
          <input v-model="cmsDate" type="text" placeholder="Datering / Jaar" class="ui-input" />
          <textarea v-model="cmsBody" rows="3" placeholder="Volledige inhoud (AVG-conform)..." class="ui-input md:col-span-3"></textarea>
        </div>
        <div class="flex flex-wrap gap-2">
          <button @click="publishItem" class="ui-btn bg-meekrab-700 text-white">Publiceren + Auto Git-Commit</button>
          <button @click="exportCms" class="ui-btn bg-white border border-zeeuws-border">Exporteer CMS JSON</button>
        </div>
      </div>

      <div class="space-y-2.5">
        <article
          v-for="item in store.cmsRecords"
          :key="item.id"
          class="bg-white border border-zeeuws-border rounded-lg p-3.5 flex items-center justify-between gap-3"
        >
          <div>
            <div class="font-mono text-xs text-meekrab-700 font-semibold">[{{ item.category }}] {{ item.date }} — ID: {{ item.id }}</div>
            <h4 class="font-serif font-bold text-base text-zinc-900">{{ item.title }}</h4>
            <p class="text-xs sm:text-sm text-zinc-700 mt-0.5">{{ item.body }}</p>
          </div>
          <button @click="deleteItem(item.id)" class="px-2.5 py-1 bg-zeeuws-sand border border-zeeuws-border rounded text-xs font-semibold">
            Verwijder
          </button>
        </article>
      </div>
    </div>

    <!-- 11B: AVORED COLLECTIONS -->
    <div v-else-if="store.subTabs.tabRustCms === 'subAvoRedCollections'" class="space-y-4">
      <div class="p-4 bg-zeeuws-sand border border-zeeuws-border rounded-lg space-y-3">
        <h3 class="font-serif font-bold text-base text-meekrab-800">AvoRed Rust CMS — Collecties &amp; Velddefinities (Auto Git-Sync)</h3>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-2.5">
          <input v-model="colId" type="text" placeholder="Identifier (bijv. kadastrale_leggers)" class="ui-input font-mono" />
          <input v-model="colName" type="text" placeholder="Collectienaam" class="ui-input" />
          <button @click="createCollection" class="ui-btn bg-meekrab-700 text-white">+ Nieuwe AvoRed Collectie</button>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-3.5">
        <div
          v-for="col in store.avoredCollections"
          :key="col.identifier"
          class="bg-white border border-zeeuws-border rounded-lg p-3.5 space-y-2"
        >
          <div class="font-mono text-xs text-meekrab-700 font-bold">{{ col.identifier }}</div>
          <div class="font-serif font-bold text-base">{{ col.name }}</div>
          <div class="space-y-1 pt-1 border-t border-zeeuws-border text-xs font-mono">
            <div v-for="f in col.fields" :key="f.name" class="flex justify-between">
              <span>{{ f.name }}</span>
              <span class="text-meekrab-800 font-bold">{{ f.field_type }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 11C: GRAPHQL QUERY & PDOK WFS EXPLORER -->
    <div v-else-if="store.subTabs.tabRustCms === 'subGraphqlExplorer'" class="space-y-4">
      <div class="p-4 bg-zeeuws-sand border border-zeeuws-border rounded-lg space-y-3">
        <div class="flex flex-wrap items-center justify-between gap-2">
          <div>
            <h3 class="font-serif font-bold text-base text-meekrab-800">AvoRed Rust GraphQL &amp; PDOK WFS v5.0 Explorer (`POST /api/graphql`)</h3>
            <p class="text-xs text-zinc-600">Inclusief `pdokCadastralParcels` voor live Kadaster WFS geometrieën en Shoelace-oppervlakteverificatie.</p>
          </div>
          <a href="/api/graphql" target="_blank" class="px-3 py-1 bg-zinc-800 text-white font-mono text-xs rounded">Open Volledige GraphiQL IDE &nearr;</a>
        </div>

        <div class="flex flex-wrap gap-1.5">
          <button @click="setPresetQuery('pdok')" class="px-2.5 py-1 bg-meekrab-700 text-white rounded text-xs font-semibold">Preset 1: PDOK Kadaster WFS v5.0 (Tholen &amp; Scherpenisse)</button>
          <button @click="setPresetQuery('planimeter')" class="px-2.5 py-1 bg-white border border-zeeuws-border rounded text-xs font-semibold">Preset 2: Shoelace Planimeter Audit</button>
          <button @click="setPresetQuery('geojson')" class="px-2.5 py-1 bg-white border border-zeeuws-border rounded text-xs font-semibold">Preset 3: GeoJSON RD &amp; WGS84</button>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-3">
          <div class="space-y-1.5">
            <div class="font-mono text-xs font-bold text-zinc-700">GraphQL Query / Mutation:</div>
            <textarea v-model="gqlQuery" rows="11" class="w-full p-3 font-mono text-xs bg-white border border-zeeuws-border rounded"></textarea>
          </div>
          <div class="space-y-1.5">
            <div class="font-mono text-xs font-bold text-zinc-700">GraphQL JSON Response:</div>
            <pre class="w-full h-[250px] overflow-auto p-3 font-mono text-xs bg-zinc-900 text-green-300 rounded">{{ gqlResult }}</pre>
          </div>
        </div>

        <button @click="runGraphqlQuery" class="ui-btn bg-meekrab-700 text-white">Voer GraphQL Query Uit</button>
      </div>
    </div>

    <!-- 11D: GEOJSON COLLECTIE -->
    <div v-else-if="store.subTabs.tabRustCms === 'subGeojsonCms'" class="space-y-4">
      <div class="p-4 bg-zeeuws-sand border border-zeeuws-border rounded-lg flex flex-wrap items-center justify-between gap-2">
        <div>
          <h3 class="font-serif font-bold text-base text-meekrab-800">GeoJSON &amp; PDOK WFS Verificatie — Perceel 369 &amp; Schakerloo Sectie I nr. 360</h3>
          <p class="text-xs text-zinc-700">Rijksdriehoeksstelsel (`EPSG:28992`), WGS84 (`EPSG:4326`) en PDOK Kadaster WFS v5.0.</p>
        </div>
        <div class="flex gap-2">
          <a href="/api/pdok/percelen" target="_blank" class="ui-btn bg-zinc-800 text-white">PDOK WFS JSON (/api/pdok/percelen) &nearr;</a>
          <a href="/api/geojson" target="_blank" class="ui-btn bg-meekrab-700 text-white">GeoJSON (/api/geojson) &nearr;</a>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div
          v-for="p in store.geoParcels"
          :key="p.id"
          class="bg-white border border-zeeuws-border rounded-lg p-4 space-y-2"
        >
          <div class="flex items-center justify-between">
            <span class="px-2 py-0.5 bg-meekrab-700 text-white font-mono text-xs rounded">{{ p.cadastral_code }}</span>
            <span class="font-mono text-xs text-zinc-600 font-bold">{{ p.area_hectares }} ha / {{ p.area_gemeten }} gemeten</span>
          </div>
          <h4 class="font-serif font-bold text-base text-zinc-900">{{ p.name }}</h4>
          <p class="text-xs text-zinc-700"><strong>Eigenaar / Pachter:</strong> {{ p.owner_lessee }} ({{ p.period }})</p>
          <div class="p-2.5 bg-zeeuws-sand rounded border border-zeeuws-border font-mono text-xs space-y-1">
            <div><strong class="text-meekrab-800">RD (EPSG:28992):</strong> X={{ p.rd_centroid[0] }}, Y={{ p.rd_centroid[1] }}</div>
            <div><strong class="text-meekrab-800">WGS84 (EPSG:4326):</strong> {{ p.wgs84_centroid[1] }}°N, {{ p.wgs84_centroid[0] }}°E</div>
          </div>
        </div>
      </div>
    </div>

    <!-- 11E: GIT-SYNCHRONISATIE -->
    <div v-else class="space-y-4">
      <div class="p-4 bg-zeeuws-sand border border-zeeuws-border rounded-lg space-y-3">
        <div class="flex flex-wrap items-center justify-between gap-2">
          <div>
            <h3 class="font-serif font-bold text-base text-meekrab-800">Automatische Git-Synchronisatie (`/home/ontwerp/lodijke`)</h3>
            <p class="text-xs font-mono text-zinc-700">Remote: {{ store.gitRemote }} | Branch: <strong>{{ store.gitBranch }}</strong> | Laatste commit: {{ store.gitLastCommit }}</p>
          </div>
          <button @click="store.syncBackend(false)" class="px-2.5 py-1 bg-white border border-zeeuws-border rounded text-xs font-semibold">Ververs Status</button>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-2.5">
          <input v-model="gitCommitMsg" type="text" placeholder="Commit bericht voor collecties & PDOK WFS..." class="ui-input md:col-span-2" />
          <label class="flex items-center gap-2 text-xs font-semibold bg-white border border-zeeuws-border rounded px-3">
            <input type="checkbox" v-model="gitPushRemote" class="accent-meekrab-700" />
            Push naar GitHub (`origin main`)
          </label>
        </div>

        <button @click="triggerManualGitSync" class="ui-btn bg-meekrab-700 text-white">Nu Commit &amp; Git-Sync Uitvoeren</button>
      </div>

      <div class="overflow-x-auto border border-zeeuws-border rounded-lg">
        <table class="w-full text-left border-collapse text-xs sm:text-sm">
          <thead class="bg-meekrab-800 text-white font-mono text-xs">
            <tr>
              <th class="p-2.5">Tijdstip (UTC)</th>
              <th class="p-2.5">Trigger</th>
              <th class="p-2.5">Commit</th>
              <th class="p-2.5">Bericht</th>
              <th class="p-2.5">Status</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-zeeuws-border">
            <tr v-for="(log, idx) in store.gitLogs" :key="idx">
              <td class="p-2.5 font-mono text-xs">{{ log.timestamp }}</td>
              <td class="p-2.5 font-mono font-bold text-meekrab-800">{{ log.action }}</td>
              <td class="p-2.5 font-mono">{{ log.commit_hash }}</td>
              <td class="p-2.5">{{ log.message }}</td>
              <td class="p-2.5 font-mono text-xs font-bold">{{ log.status }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { store } from '../../store/archiveStore.js';

const cmsTitle = ref('');
const cmsCategory = ref('DOSSIER_SCHOT');
const cmsDate = ref('');
const cmsBody = ref('');

const colId = ref('');
const colName = ref('');

const gitCommitMsg = ref('[AvoRed CMS] Synchronisatie PDOK WFS v5.0 Kadaster & Shoelace Planimeter');
const gitPushRemote = ref(false);

const gqlQuery = ref(`query {
  pdokCadastralParcels(bbox: "67000,387000,75000,396000,EPSG:28992") {
    id
    kadastraleAanduiding
    gemeente
    sectie
    perceelnummer
    oppervlakteKadasterM2
    calculatedShoelaceM2
    deltaM2
    wfsCrs
  }
}`);

const gqlResult = ref('// Klik op "Voer GraphQL Query Uit" om live PDOK WFS v5.0 percelen op te halen...');

function setPresetQuery(type) {
  if (type === 'pdok') {
    gqlQuery.value = `query {
  pdokCadastralParcels(bbox: "67000,387000,75000,396000,EPSG:28992") {
    id
    kadastraleAanduiding
    gemeente
    sectie
    perceelnummer
    oppervlakteKadasterM2
    calculatedShoelaceM2
    deltaM2
    wfsCrs
  }
}`;
  } else if (type === 'planimeter') {
    gqlQuery.value = `query {
  planimeterAudit(mapScale: 2500) {
    cadastralCode
    areaHectares
    areaZeeuwseGemeten
    ott573DrumRevolutions
    verificationStatus
  }
}`;
  } else {
    gqlQuery.value = `query {
  geojsonParcels {
    id
    cadastralCode
    name
    areaHectares
    rdCentroid
    wgs84Centroid
  }
}`;
  }
}

async function runGraphqlQuery() {
  try {
    const res = await store.executeGraphQL(gqlQuery.value);
    gqlResult.value = JSON.stringify(res, null, 2);
    await store.syncBackend(true);
    store.showToast('GraphQL PDOK WFS query uitgevoerd op /api/graphql.');
  } catch (e) {
    gqlResult.value = JSON.stringify({ error: String(e) }, null, 2);
  }
}

async function triggerManualGitSync() {
  try {
    const res = await fetch('/api/git/sync', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        message: gitCommitMsg.value.trim() || '[AvoRed CMS] Git-Sync',
        push: gitPushRemote.value
      })
    });
    if (res.ok) {
      const data = await res.json();
      store.gitBranch = data.branch;
      store.gitLastCommit = data.last_commit;
      store.gitLogs = data.logs || [];
      store.showToast(`Git-Sync voltooid: ${data.latest.status} (${data.latest.commit_hash})`);
    }
  } catch (e) {
    store.showToast('Kon Git-Sync niet bereiken.');
  }
}

async function publishItem() {
  if (!cmsTitle.value.trim() || !cmsBody.value.trim()) {
    store.showToast('Vul titel en inhoud in.');
    return;
  }
  const rec = {
    id: 'cms-' + Date.now(),
    title: cmsTitle.value.trim(),
    category: cmsCategory.value,
    collection: 'dossiers_schot_bout',
    date: cmsDate.value.trim() || 'Archief',
    author_id: 'I0103',
    avg_shield: true,
    body: cmsBody.value.trim()
  };
  try {
    const res = await fetch('/api/cms', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(rec)
    });
    if (res.ok) {
      store.cmsRecords = await res.json();
      setTimeout(() => store.syncBackend(true), 400);
    } else {
      store.cmsRecords.unshift(rec);
    }
  } catch (e) {
    store.cmsRecords.unshift(rec);
  }
  cmsTitle.value = '';
  cmsBody.value = '';
  store.showToast('Archiefstuk gepubliceerd + automatisch gecommit in Git.');
}

async function deleteItem(id) {
  try {
    const res = await fetch(`/api/cms/${id}`, { method: 'DELETE' });
    if (res.ok) {
      store.cmsRecords = await res.json();
      setTimeout(() => store.syncBackend(true), 400);
      return;
    }
  } catch (e) {}
  store.cmsRecords = store.cmsRecords.filter(c => c.id !== id);
}

async function createCollection() {
  if (!colId.value.trim() || !colName.value.trim()) return;
  const newCol = {
    identifier: colId.value.trim().toLowerCase().replace(/\s+/g, '_'),
    name: colName.value.trim(),
    fields: [
      { name: 'title', field_type: 'TEXT', required: true },
      { name: 'avg_shield', field_type: 'SWITCH', required: true },
      { name: 'content', field_type: 'RICH_TEXT', required: true }
    ]
  };
  try {
    const res = await fetch('/api/avored/collections', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(newCol)
    });
    if (res.ok) {
      store.avoredCollections = await res.json();
      setTimeout(() => store.syncBackend(true), 400);
    }
  } catch (e) {
    store.avoredCollections.push(newCol);
  }
  colId.value = '';
  colName.value = '';
  store.showToast('Nieuwe AvoRed Collectie opgeslagen + gecommit in Git.');
}

function exportCms() {
  const a = document.createElement('a');
  a.href = 'data:text/json;charset=utf-8,' + encodeURIComponent(JSON.stringify(store.cmsRecords, null, 2));
  a.download = 'avored-rust-cms-lodijke.json';
  a.click();
}
</script>
