<template>
  <div class="tree-viewer-container">
    <header class="tree-header">
      <div class="header-main">
        <h2>📂 Master-Verzameling: Alle 6 Mappenbomen &amp; Archiefstructuren</h2>
        <span class="tree-count-badge">{{ activeTreeData.title }}</span>
      </div>

      <div class="tree-selector-bar">
        <button
          v-for="(tree, key) in treeCatalog"
          :key="key"
          :class="['btn-tree-select', { active: activeTreeKey === key }]"
          @click="activeTreeKey = key; selectedNode = null"
        >
          {{ tree.icon }} {{ tree.shortLabel }}
        </button>
      </div>

      <div class="tree-actions-bar">
        <input
          type="text"
          v-model="searchQuery"
          placeholder="🔍 Zoek in alle 6 bomen op bijv. 369, Schot, Bout, Zuurdeeg, TH2, 1456324, Kandia, Knook..."
          class="search-input"
        />
        <button class="btn-action" @click="expandAll">➕ Alles Uitklappen</button>
        <button class="btn-action" @click="collapseAll">➖ Alles Inklappen</button>
        <button class="btn-action" @click="resetTrees">↺ Herstel Bomen</button>
      </div>
    </header>

    <div class="tree-workspace">
      <div class="tree-canvas">
        <div class="root-folder-title">
          📂 <strong>{{ activeTreeData.rootName }}</strong>
        </div>

        <ul class="tree-node-list">
          <tree-item
            v-for="(child, idx) in filteredTree"
            :key="child.name + idx + expandVersion"
            :model="child"
            :parent-path="activeTreeData.rootName"
            :default-open="globalExpandState"
            @select-file="selectFile"
            @delete-node="deleteFromTree(activeTreeData.children, idx)"
          />
        </ul>
      </div>

      <transition name="slide-panel">
        <aside class="file-detail-panel" v-if="selectedNode">
          <div class="panel-header">
            <span class="file-type-badge">{{ selectedNode.ext || 'MAP' }}</span>
            <h3>{{ selectedNode.name }}</h3>
            <button class="btn-close" @click="selectedNode = null">✕</button>
          </div>

          <div class="panel-body">
            <div class="detail-group">
              <label>📁 Volledig Pad in Master-Verzameling:</label>
              <code>{{ selectedNode.path }}</code>
            </div>

            <div class="detail-group" v-if="selectedNode.description">
              <label>📝 Dossier- &amp; Archiefomschrijving:</label>
              <p>{{ selectedNode.description }}</p>
            </div>

            <div class="detail-group" v-if="selectedNode.wooCase">
              <label>⚖️ Juridische / Geodetische Sleutel:</label>
              <span class="woo-tag">{{ selectedNode.wooCase }}</span>
            </div>

            <div class="detail-actions">
              <a href="http://127.0.0.1:8082/graphql" target="_blank" class="btn-studio">
                ⚡ Open in Axum GraphQL Studio (:8082)
              </a>
            </div>
          </div>
        </aside>
      </transition>
    </div>
  </div>
</template>

<script>
import { ref, reactive, computed, defineComponent, h } from 'vue';

function getExtFromName(name) {
  if (name.includes('#')) return 'TTL';
  if (!name.includes('.')) return '';
  const parts = name.split('.');
  return parts[parts.length - 1].toUpperCase();
}

function getFileIcon(ext) {
  if (!ext) return '📄';
  switch (ext.toLowerCase()) {
    case 'pdf': return '📕';
    case 'json': return '⚙️';
    case 'geojson': return '🗺️';
    case 'csv': return '📊';
    case 'md': return '📝';
    case 'vue': return '🟢';
    case 'rs': return '🦀';
    case 'ged': return '🌳';
    case 'familytree':
    case 'sqlite': return '🗄️';
    case 'ttl': return '🔐';
    default: return '📄';
  }
}

// Bouwt automatisch geneste mappenbomen op uit compacte pad-strings
function buildTree(entries) {
  const root = [];
  for (const entry of entries) {
    const [rawPath, wooCase = '', description = ''] = entry.split('|').map(s => s.trim());
    const parts = rawPath.split('/').filter(Boolean);
    let currentLevel = root;
    parts.forEach((part, idx) => {
      const isLast = idx === parts.length - 1;
      const isExplicitFolder = rawPath.endsWith('/');
      let existing = currentLevel.find(n => n.name === part);
      if (!existing) {
        existing = {
          name: part,
          wooCase: isLast ? wooCase : '',
          description: isLast ? description : ''
        };
        if (!isLast || isExplicitFolder) {
          existing.children = [];
        }
        currentLevel.push(existing);
      }
      if (!isLast) {
        if (!existing.children) existing.children = [];
        currentLevel = existing.children;
      }
    });
  }
  return root;
}

const TreeItem = defineComponent({
  name: 'TreeItem',
  props: {
    model: Object,
    parentPath: { type: String, default: '' },
    defaultOpen: { type: Boolean, default: true }
  },
  emits: ['select-file', 'delete-node'],
  setup(props, { emit }) {
    const isOpen = ref(props.defaultOpen);
    const isFolder = computed(() => Array.isArray(props.model.children));
    const currentPath = computed(() => `${props.parentPath}${props.model.name}${isFolder.value ? '/' : ''}`);

    function toggle() {
      if (isFolder.value) {
        isOpen.value = !isOpen.value;
      } else {
        const ext = props.model.ext || getExtFromName(props.model.name);
        emit('select-file', {
          ...props.model,
          ext,
          path: props.model.path || currentPath.value
        });
      }
    }

    function removeChild(index) {
      if (props.model.children) {
        props.model.children.splice(index, 1);
      }
    }

    return () => {
      const item = props.model;
      const ext = isFolder.value ? '' : (item.ext || getExtFromName(item.name));
      const icon = isFolder.value ? (isOpen.value ? '📂' : '📁') : getFileIcon(ext);

      return h('li', { class: 'tree-item-node' }, [
        h('div', {
          class: ['tree-node-label', { 'is-folder': isFolder.value, 'is-file': !isFolder.value }],
          onClick: toggle
        }, [
          isFolder.value ? h('span', { class: 'toggle-arrow' }, isOpen.value ? '▼ ' : '▶ ') : null,
          h('span', { class: 'node-icon' }, icon + ' '),
          h('span', { class: 'node-name' }, item.name),
          item.description ? h('span', { class: 'node-inline-desc' }, `— ${item.description}`) : null,
          ext ? h('span', { class: 'node-ext-tag' }, ext) : null,
          h('button', {
            class: 'node-delete-btn',
            title: 'Verwijder uit mappenboom',
            onClick: (e) => {
              e.stopPropagation();
              emit('delete-node', item);
            }
          }, '🗑️')
        ]),
        isFolder.value && isOpen.value ? h('ul', { class: 'tree-sub-list' },
          item.children.map((child, i) => h(TreeItem, {
            key: child.name + i,
            model: child,
            parentPath: currentPath.value,
            defaultOpen: props.defaultOpen,
            onSelectFile: (node) => emit('select-file', node),
            onDeleteNode: () => removeChild(i)
          }))
        ) : null
      ]);
    };
  }
});

function createInitialCatalog() {
  return {
    master: {
      icon: '🏛️',
      shortLabel: '1. Master Platform',
      title: '1. Master Platform Architectuur (lodijke_master_platform/)',
      rootName: 'lodijke_master_platform/',
      children: buildTree([
        '01_Solid_POD_Vault/profile/card#me | W3C Solid WebID | WebID: https://solid.tholen-erfgoed.nl/profile/card#me',
        '01_Solid_POD_Vault/public/photoalbum/photos.json | POD-01..08 | Solid POD fotodatabase (POD-01 t/m POD-08)',
        '01_Solid_POD_Vault/public/photoalbum/uploads/ | Media | Geüploade archiefscans & media',
        '01_Solid_POD_Vault/public/percelen/geojson_parcels.json | EPSG:28992 | GeoJSON RD (EPSG:28992) & WGS84 (EPSG:4326)',
        '01_Solid_POD_Vault/public/cms/cms_records.json | AvoRed CMS | AvoRed CMS archiefstukken',
        '01_Solid_POD_Vault/private/genealogie/kwartierstaat_locked.json | AVG Schild | Afgeschermde persoonsgegevens levende generaties',
        '01_Solid_POD_Vault/private/woo_dossiers/brp_auditlogs_firewall.json | Zaak 1463739 | Makelaarsuite BRP-logs & 5-minuten discrepantie',
        '01_Solid_POD_Vault/private/woo_dossiers/bestuurlijke_correspondentie/ | Zaak 1456324 | Woo-hoofdzaak 1456324 & Zuurdeeg-dossier',
        '01_Solid_POD_Vault/inbox/ | Art. 4.2 Woo | LDP Linked Data Notifications & Woo-sommaties ex art. 4.2',
        '01_Solid_POD_Vault/settings/prefs.ttl | W3C ACL | Access Control Lists (ACL) & W3C LDP voorkeuren',
        '02_GRAMPS_Genealogy_Core/db/gramps_db_tholen_schot.familytree | SQLite DB | Primaire Gramps SQLite/BSD DB',
        '02_GRAMPS_Genealogy_Core/db/gramps_cache/ | Cache | Offline JSON-cache voor snelle terugval',
        '02_GRAMPS_Genealogy_Core/exports/stamboom_schot_bout.ged | GEDCOM 5.5.1 | GEDCOM 5.5.1 exportbestand (inclusief W. Bout 1966)',
        '02_GRAMPS_Genealogy_Core/exports/kwartierstaat_I0103.json | GRAMPS I0103 | Geëxporteerde kwartierstaat stamvader I0103',
        '02_GRAMPS_Genealogy_Core/profiles/I0103_Benjamin_Willem_Schot.json | GRAMPS I0103 | Stamvader B.W. Schot (1840-1935)',
        '02_GRAMPS_Genealogy_Core/profiles/I0104_Maria_Mathea_Bolier.json | GRAMPS I0104 | 1e Echtgenote (1840-1909, 13 kinderen)',
        '02_GRAMPS_Genealogy_Core/profiles/I0105_Dina_Pieternella_Kegge.json | GRAMPS I0105 | 2e Echtgenote (1868-1944, oesterkoopvrouw)',
        '02_GRAMPS_Genealogy_Core/profiles/I0120_Willem_Bout_1966.json | GRAMPS I0120 | Erfgenaam bij plaatsvervulling W. Bout (*1966)',
        '02_GRAMPS_Genealogy_Core/profiles/I0121_C_M_Guiljam.json | GRAMPS I0121 | Moeder C.M. Guiljam (overl. 2021)',
        '03_Axum_Rust_&_GraphQL_API/src/main.rs | Poort :8082 | Axum Router & Standalone Studio (:8082)',
        '03_Axum_Rust_&_GraphQL_API/src/graphql.rs | GraphQL | Async-GraphQL QueryRoot & MutationRoot',
        '03_Axum_Rust_&_GraphQL_API/src/avored.rs | Models | Datastructuren CmsRecord & GeoParcelFeature',
        '03_Axum_Rust_&_GraphQL_API/src/gramps_api.rs | REST/GraphQL | Proxy-handlers voor /api/gramps/core & gedcom',
        '03_Axum_Rust_&_GraphQL_API/data/cms_records.json | Data | Persistente AvoRed CMS records',
        '03_Axum_Rust_&_GraphQL_API/data/kwartierstaat_I0103.json | Data | GraphQL stamboom feed',
        '04_CMS_Document_Tabs_Frontend/frontend/src/components/MainInterface.vue | Vue 3 | Collapsible Menu Panel & Viewport Grid Manager',
        '04_CMS_Document_Tabs_Frontend/frontend/src/components/Tab00Home.vue | Vue 3 | Platform Dashboard & Modulekaarten',
        '04_CMS_Document_Tabs_Frontend/frontend/src/components/Tab01Genealogie.vue | Vue 3 | GRAMPS Stamboom & GEDCOM 5.5.1 Downloader',
        '04_CMS_Document_Tabs_Frontend/frontend/src/components/Tab04Kaarten.vue | Vue 3 | Leaflet GIS Kaart + Zeekaart 1892 Transparante Overlay',
        '04_CMS_Document_Tabs_Frontend/frontend/src/components/TabMappenbomen.vue | Vue 3 | Mappenboom Viewer met zoekfilter',
        '04_CMS_Document_Tabs_Frontend/frontend/src/App.vue | Root | Root Component (Wit & Meekrap-rood thema)',
        '04_CMS_Document_Tabs_Frontend/vercel.json | Vercel | SPA Rewrites & Clean URLs',
        '05_Tijdmodule_&_Bron_Herstructurering/chronology_1301_2026.json | Chronologie | Tijdlijn van Slag bij Lodijke (1301) tot Woo (2026)',
        '05_Tijdmodule_&_Bron_Herstructurering/termijnbewaker_woo.rs | Rust Core | Rust module voor ingebrekestellingen & beroepstermijnen',
        '05_Tijdmodule_&_Bron_Herstructurering/audit_trail_log.json | Audit Log | UTC-gestempelde logboeken'
      ])
    },
    woo: {
      icon: '⚖️',
      shortLabel: '2. Woo & Visserij',
      title: '2. Bestuursrechtelijke Woo-Procedures & Visserijrechten (woo_visserij_reimerswaal_provincies/)',
      rootName: 'woo_visserij_reimerswaal_provincies/',
      children: buildTree([
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_A_Oorspronkelijk_Woo_Verzoek_2024/Verzoek_B_en_W_Tholen_01-03-2024.pdf | Spoor A | Oorspronkelijk Woo-verzoek B&W Tholen (01-03-2024)',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_A_Oorspronkelijk_Woo_Verzoek_2024/Primaire_Afwijzing_B_en_W_25-04-2024.pdf | Spoor A | Primaire afwijzing B&W Tholen (25-04-2024)',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_B_Rechtbank_Zeeland_West_Brabant_BRE_24_5455/Beroepschrift_Niet_Tijdig_Beslissen.pdf | BRE 24/5455 | Beroepschrift Niet Tijdig Beslissen',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_B_Rechtbank_Zeeland_West_Brabant_BRE_24_5455/Uitspraak_Rechtbank_ZWB_09-10-2025_ECLI_NL_RBZWB_2025_6823.pdf | ECLI:NL:RBZWB:2025:6823 | Uitspraak Rechtbank ZWB (09-10-2025)',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_C_AVG_Auditlogs_&_BRP_Bevragingen/BRP_GBA_V_Auditlogs_11-01-2017_24-04-2017.csv | Zaak 1463739 | BRP & GBA-V Auditlogs 2017',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_C_AVG_Auditlogs_&_BRP_Bevragingen/Makelaarsuite_Chronologie_11-03-2024_Tijdsdiscrepantie.json | Zaak 1463739 | Makelaarsuite 5-minuten tijdsdiscrepantie',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_C_AVG_Auditlogs_&_BRP_Bevragingen/Correspondentie_FG_Tholen_Zaak_1463739.pdf | Zaak 1463739 | Correspondentie Functionaris Gegevensbescherming Tholen',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_D_Woo_Hoofdzaak_1456324_Visserij_Molenplaat/Hernieuwd_Woo_Verzoek_13-01-2026.pdf | Zaak 1456324 | Hernieuwd Woo-verzoek Visserij Molenplaat',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_D_Woo_Hoofdzaak_1456324_Visserij_Molenplaat/Ontvangstbevestiging_Gemeente_Tholen_14-01-2026.pdf | Zaak 1456324 | Ontvangstbevestiging Gemeente Tholen',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_D_Woo_Hoofdzaak_1456324_Visserij_Molenplaat/Inhoudelijke_Afbakeningsmatrix_PM-01_24-10-2026.pdf | PM-01 | Inhoudelijke Afbakeningsmatrix PM-01',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_E_Bezwaarschrift_Zaak_1425030_&_Herroeping/Primair_Besluit_1398201_Antimisbruik_27-01-2026.pdf | Zaak 1398201 | Primair besluit 1398201 (27-01-2026)',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_E_Bezwaarschrift_Zaak_1425030_&_Herroeping/Bezwaarschrift_Verzoeker_28-01-2026.pdf | Zaak 1425030 | Bezwaarschrift (28-01-2026)',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_E_Bezwaarschrift_Zaak_1425030_&_Herroeping/Advies_Bezwaarschriftencommissie_28-08-2026.pdf | Zaak 1425030 | Advies Commissie Bezwaarschriften (28-08-2026)',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_E_Bezwaarschrift_Zaak_1425030_&_Herroeping/Brief_B_en_W_Tholen_1504535_Precisering_08-10-2026.pdf | Brief 1504535 | Brief B&W Tholen precisering (08-10-2026)',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_E_Bezwaarschrift_Zaak_1425030_&_Herroeping/PostNL_Afhaalbew
cat << 'EOF' > /home/ontwerp/lodijke/04_CMS_Document_Tabs_Frontend/frontend/src/components/TabMappenbomen.vue
<template>
  <div class="tree-viewer-container">
    <header class="tree-header">
      <div class="header-main">
        <h2>📂 Master-Verzameling: Alle 6 Mappenbomen &amp; Archiefstructuren</h2>
        <span class="tree-count-badge">{{ activeTreeData.title }}</span>
      </div>

      <div class="tree-selector-bar">
        <button
          v-for="(tree, key) in treeCatalog"
          :key="key"
          :class="['btn-tree-select', { active: activeTreeKey === key }]"
          @click="activeTreeKey = key; selectedNode = null"
        >
          {{ tree.icon }} {{ tree.shortLabel }}
        </button>
      </div>

      <div class="tree-actions-bar">
        <input
          type="text"
          v-model="searchQuery"
          placeholder="🔍 Zoek in alle 6 bomen op bijv. 369, Schot, Bout, Zuurdeeg, TH2, 1456324, Kandia, Knook..."
          class="search-input"
        />
        <button class="btn-action" @click="expandAll">➕ Alles Uitklappen</button>
        <button class="btn-action" @click="collapseAll">➖ Alles Inklappen</button>
        <button class="btn-action" @click="resetTrees">↺ Herstel Bomen</button>
      </div>
    </header>

    <div class="tree-workspace">
      <div class="tree-canvas">
        <div class="root-folder-title">
          📂 <strong>{{ activeTreeData.rootName }}</strong>
        </div>

        <ul class="tree-node-list">
          <tree-item
            v-for="(child, idx) in filteredTree"
            :key="child.name + idx + expandVersion"
            :model="child"
            :parent-path="activeTreeData.rootName"
            :default-open="globalExpandState"
            @select-file="selectFile"
            @delete-node="deleteFromTree(activeTreeData.children, idx)"
          />
        </ul>
      </div>

      <transition name="slide-panel">
        <aside class="file-detail-panel" v-if="selectedNode">
          <div class="panel-header">
            <span class="file-type-badge">{{ selectedNode.ext || 'MAP' }}</span>
            <h3>{{ selectedNode.name }}</h3>
            <button class="btn-close" @click="selectedNode = null">✕</button>
          </div>

          <div class="panel-body">
            <div class="detail-group">
              <label>📁 Volledig Pad in Master-Verzameling:</label>
              <code>{{ selectedNode.path }}</code>
            </div>

            <div class="detail-group" v-if="selectedNode.description">
              <label>📝 Dossier- &amp; Archiefomschrijving:</label>
              <p>{{ selectedNode.description }}</p>
            </div>

            <div class="detail-group" v-if="selectedNode.wooCase">
              <label>⚖️ Juridische / Geodetische Sleutel:</label>
              <span class="woo-tag">{{ selectedNode.wooCase }}</span>
            </div>

            <div class="detail-actions">
              <a href="http://127.0.0.1:8082/graphql" target="_blank" class="btn-studio">
                ⚡ Open in Axum GraphQL Studio (:8082)
              </a>
            </div>
          </div>
        </aside>
      </transition>
    </div>
  </div>
</template>

<script>
import { ref, reactive, computed, defineComponent, h } from 'vue';

function getExtFromName(name) {
  if (name.includes('#')) return 'TTL';
  if (!name.includes('.')) return '';
  const parts = name.split('.');
  return parts[parts.length - 1].toUpperCase();
}

function getFileIcon(ext) {
  if (!ext) return '📄';
  switch (ext.toLowerCase()) {
    case 'pdf': return '📕';
    case 'json': return '⚙️';
    case 'geojson': return '🗺️';
    case 'csv': return '📊';
    case 'md': return '📝';
    case 'vue': return '🟢';
    case 'rs': return '🦀';
    case 'ged': return '🌳';
    case 'familytree':
    case 'sqlite': return '🗄️';
    case 'ttl': return '🔐';
    default: return '📄';
  }
}

// Bouwt automatisch geneste mappenbomen op uit compacte pad-strings
function buildTree(entries) {
  const root = [];
  for (const entry of entries) {
    const [rawPath, wooCase = '', description = ''] = entry.split('|').map(s => s.trim());
    const parts = rawPath.split('/').filter(Boolean);
    let currentLevel = root;
    parts.forEach((part, idx) => {
      const isLast = idx === parts.length - 1;
      const isExplicitFolder = rawPath.endsWith('/');
      let existing = currentLevel.find(n => n.name === part);
      if (!existing) {
        existing = {
          name: part,
          wooCase: isLast ? wooCase : '',
          description: isLast ? description : ''
        };
        if (!isLast || isExplicitFolder) {
          existing.children = [];
        }
        currentLevel.push(existing);
      }
      if (!isLast) {
        if (!existing.children) existing.children = [];
        currentLevel = existing.children;
      }
    });
  }
  return root;
}

const TreeItem = defineComponent({
  name: 'TreeItem',
  props: {
    model: Object,
    parentPath: { type: String, default: '' },
    defaultOpen: { type: Boolean, default: true }
  },
  emits: ['select-file', 'delete-node'],
  setup(props, { emit }) {
    const isOpen = ref(props.defaultOpen);
    const isFolder = computed(() => Array.isArray(props.model.children));
    const currentPath = computed(() => `${props.parentPath}${props.model.name}${isFolder.value ? '/' : ''}`);

    function toggle() {
      if (isFolder.value) {
        isOpen.value = !isOpen.value;
      } else {
        const ext = props.model.ext || getExtFromName(props.model.name);
        emit('select-file', {
          ...props.model,
          ext,
          path: props.model.path || currentPath.value
        });
      }
    }

    function removeChild(index) {
      if (props.model.children) {
        props.model.children.splice(index, 1);
      }
    }

    return () => {
      const item = props.model;
      const ext = isFolder.value ? '' : (item.ext || getExtFromName(item.name));
      const icon = isFolder.value ? (isOpen.value ? '📂' : '📁') : getFileIcon(ext);

      return h('li', { class: 'tree-item-node' }, [
        h('div', {
          class: ['tree-node-label', { 'is-folder': isFolder.value, 'is-file': !isFolder.value }],
          onClick: toggle
        }, [
          isFolder.value ? h('span', { class: 'toggle-arrow' }, isOpen.value ? '▼ ' : '▶ ') : null,
          h('span', { class: 'node-icon' }, icon + ' '),
          h('span', { class: 'node-name' }, item.name),
          item.description ? h('span', { class: 'node-inline-desc' }, `— ${item.description}`) : null,
          ext ? h('span', { class: 'node-ext-tag' }, ext) : null,
          h('button', {
            class: 'node-delete-btn',
            title: 'Verwijder uit mappenboom',
            onClick: (e) => {
              e.stopPropagation();
              emit('delete-node', item);
            }
          }, '🗑️')
        ]),
        isFolder.value && isOpen.value ? h('ul', { class: 'tree-sub-list' },
          item.children.map((child, i) => h(TreeItem, {
            key: child.name + i,
            model: child,
            parentPath: currentPath.value,
            defaultOpen: props.defaultOpen,
            onSelectFile: (node) => emit('select-file', node),
            onDeleteNode: () => removeChild(i)
          }))
        ) : null
      ]);
    };
  }
});

function createInitialCatalog() {
  return {
    master: {
      icon: '🏛️',
      shortLabel: '1. Master Platform',
      title: '1. Master Platform Architectuur (lodijke_master_platform/)',
      rootName: 'lodijke_master_platform/',
      children: buildTree([
        '01_Solid_POD_Vault/profile/card#me | W3C Solid WebID | WebID: https://solid.tholen-erfgoed.nl/profile/card#me',
        '01_Solid_POD_Vault/public/photoalbum/photos.json | POD-01..08 | Solid POD fotodatabase (POD-01 t/m POD-08)',
        '01_Solid_POD_Vault/public/photoalbum/uploads/ | Media | Geüploade archiefscans & media',
        '01_Solid_POD_Vault/public/percelen/geojson_parcels.json | EPSG:28992 | GeoJSON RD (EPSG:28992) & WGS84 (EPSG:4326)',
        '01_Solid_POD_Vault/public/cms/cms_records.json | AvoRed CMS | AvoRed CMS archiefstukken',
        '01_Solid_POD_Vault/private/genealogie/kwartierstaat_locked.json | AVG Schild | Afgeschermde persoonsgegevens levende generaties',
        '01_Solid_POD_Vault/private/woo_dossiers/brp_auditlogs_firewall.json | Zaak 1463739 | Makelaarsuite BRP-logs & 5-minuten discrepantie',
        '01_Solid_POD_Vault/private/woo_dossiers/bestuurlijke_correspondentie/ | Zaak 1456324 | Woo-hoofdzaak 1456324 & Zuurdeeg-dossier',
        '01_Solid_POD_Vault/inbox/ | Art. 4.2 Woo | LDP Linked Data Notifications & Woo-sommaties ex art. 4.2',
        '01_Solid_POD_Vault/settings/prefs.ttl | W3C ACL | Access Control Lists (ACL) & W3C LDP voorkeuren',
        '02_GRAMPS_Genealogy_Core/db/gramps_db_tholen_schot.familytree | SQLite DB | Primaire Gramps SQLite/BSD DB',
        '02_GRAMPS_Genealogy_Core/db/gramps_cache/ | Cache | Offline JSON-cache voor snelle terugval',
        '02_GRAMPS_Genealogy_Core/exports/stamboom_schot_bout.ged | GEDCOM 5.5.1 | GEDCOM 5.5.1 exportbestand (inclusief W. Bout 1966)',
        '02_GRAMPS_Genealogy_Core/exports/kwartierstaat_I0103.json | GRAMPS I0103 | Geëxporteerde kwartierstaat stamvader I0103',
        '02_GRAMPS_Genealogy_Core/profiles/I0103_Benjamin_Willem_Schot.json | GRAMPS I0103 | Stamvader B.W. Schot (1840-1935)',
        '02_GRAMPS_Genealogy_Core/profiles/I0104_Maria_Mathea_Bolier.json | GRAMPS I0104 | 1e Echtgenote (1840-1909, 13 kinderen)',
        '02_GRAMPS_Genealogy_Core/profiles/I0105_Dina_Pieternella_Kegge.json | GRAMPS I0105 | 2e Echtgenote (1868-1944, oesterkoopvrouw)',
        '02_GRAMPS_Genealogy_Core/profiles/I0120_Willem_Bout_1966.json | GRAMPS I0120 | Erfgenaam bij plaatsvervulling W. Bout (*1966)',
        '02_GRAMPS_Genealogy_Core/profiles/I0121_C_M_Guiljam.json | GRAMPS I0121 | Moeder C.M. Guiljam (overl. 2021)',
        '03_Axum_Rust_&_GraphQL_API/src/main.rs | Poort :8082 | Axum Router & Standalone Studio (:8082)',
        '03_Axum_Rust_&_GraphQL_API/src/graphql.rs | GraphQL | Async-GraphQL QueryRoot & MutationRoot',
        '03_Axum_Rust_&_GraphQL_API/src/avored.rs | Models | Datastructuren CmsRecord & GeoParcelFeature',
        '03_Axum_Rust_&_GraphQL_API/src/gramps_api.rs | REST/GraphQL | Proxy-handlers voor /api/gramps/core & gedcom',
        '03_Axum_Rust_&_GraphQL_API/data/cms_records.json | Data | Persistente AvoRed CMS records',
        '03_Axum_Rust_&_GraphQL_API/data/kwartierstaat_I0103.json | Data | GraphQL stamboom feed',
        '04_CMS_Document_Tabs_Frontend/frontend/src/components/MainInterface.vue | Vue 3 | Collapsible Menu Panel & Viewport Grid Manager',
        '04_CMS_Document_Tabs_Frontend/frontend/src/components/Tab00Home.vue | Vue 3 | Platform Dashboard & Modulekaarten',
        '04_CMS_Document_Tabs_Frontend/frontend/src/components/Tab01Genealogie.vue | Vue 3 | GRAMPS Stamboom & GEDCOM 5.5.1 Downloader',
        '04_CMS_Document_Tabs_Frontend/frontend/src/components/Tab04Kaarten.vue | Vue 3 | Leaflet GIS Kaart + Zeekaart 1892 Transparante Overlay',
        '04_CMS_Document_Tabs_Frontend/frontend/src/components/TabMappenbomen.vue | Vue 3 | Mappenboom Viewer met zoekfilter',
        '04_CMS_Document_Tabs_Frontend/frontend/src/App.vue | Root | Root Component (Wit & Meekrap-rood thema)',
        '04_CMS_Document_Tabs_Frontend/vercel.json | Vercel | SPA Rewrites & Clean URLs',
        '05_Tijdmodule_&_Bron_Herstructurering/chronology_1301_2026.json | Chronologie | Tijdlijn van Slag bij Lodijke (1301) tot Woo (2026)',
        '05_Tijdmodule_&_Bron_Herstructurering/termijnbewaker_woo.rs | Rust Core | Rust module voor ingebrekestellingen & beroepstermijnen',
        '05_Tijdmodule_&_Bron_Herstructurering/audit_trail_log.json | Audit Log | UTC-gestempelde logboeken'
      ])
    },
    woo: {
      icon: '⚖️',
      shortLabel: '2. Woo & Visserij',
      title: '2. Bestuursrechtelijke Woo-Procedures & Visserijrechten (woo_visserij_reimerswaal_provincies/)',
      rootName: 'woo_visserij_reimerswaal_provincies/',
      children: buildTree([
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_A_Oorspronkelijk_Woo_Verzoek_2024/Verzoek_B_en_W_Tholen_01-03-2024.pdf | Spoor A | Oorspronkelijk Woo-verzoek B&W Tholen (01-03-2024)',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_A_Oorspronkelijk_Woo_Verzoek_2024/Primaire_Afwijzing_B_en_W_25-04-2024.pdf | Spoor A | Primaire afwijzing B&W Tholen (25-04-2024)',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_B_Rechtbank_Zeeland_West_Brabant_BRE_24_5455/Beroepschrift_Niet_Tijdig_Beslissen.pdf | BRE 24/5455 | Beroepschrift Niet Tijdig Beslissen',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_B_Rechtbank_Zeeland_West_Brabant_BRE_24_5455/Uitspraak_Rechtbank_ZWB_09-10-2025_ECLI_NL_RBZWB_2025_6823.pdf | ECLI:NL:RBZWB:2025:6823 | Uitspraak Rechtbank ZWB (09-10-2025)',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_C_AVG_Auditlogs_&_BRP_Bevragingen/BRP_GBA_V_Auditlogs_11-01-2017_24-04-2017.csv | Zaak 1463739 | BRP & GBA-V Auditlogs 2017',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_C_AVG_Auditlogs_&_BRP_Bevragingen/Makelaarsuite_Chronologie_11-03-2024_Tijdsdiscrepantie.json | Zaak 1463739 | Makelaarsuite 5-minuten tijdsdiscrepantie',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_C_AVG_Auditlogs_&_BRP_Bevragingen/Correspondentie_FG_Tholen_Zaak_1463739.pdf | Zaak 1463739 | Correspondentie Functionaris Gegevensbescherming Tholen',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_D_Woo_Hoofdzaak_1456324_Visserij_Molenplaat/Hernieuwd_Woo_Verzoek_13-01-2026.pdf | Zaak 1456324 | Hernieuwd Woo-verzoek Visserij Molenplaat',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_D_Woo_Hoofdzaak_1456324_Visserij_Molenplaat/Ontvangstbevestiging_Gemeente_Tholen_14-01-2026.pdf | Zaak 1456324 | Ontvangstbevestiging Gemeente Tholen',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_D_Woo_Hoofdzaak_1456324_Visserij_Molenplaat/Inhoudelijke_Afbakeningsmatrix_PM-01_24-10-2026.pdf | PM-01 | Inhoudelijke Afbakeningsmatrix PM-01',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_E_Bezwaarschrift_Zaak_1425030_&_Herroeping/Primair_Besluit_1398201_Antimisbruik_27-01-2026.pdf | Zaak 1398201 | Primair besluit 1398201 (27-01-2026)',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_E_Bezwaarschrift_Zaak_1425030_&_Herroeping/Bezwaarschrift_Verzoeker_28-01-2026.pdf | Zaak 1425030 | Bezwaarschrift (28-01-2026)',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_E_Bezwaarschrift_Zaak_1425030_&_Herroeping/Advies_Bezwaarschriftencommissie_28-08-2026.pdf | Zaak 1425030 | Advies Commissie Bezwaarschriften (28-08-2026)',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_E_Bezwaarschrift_Zaak_1425030_&_Herroeping/Brief_B_en_W_Tholen_1504535_Precisering_08-10-2026.pdf | Brief 1504535 | Brief B&W Tholen precisering (08-10-2026)',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_E_Bezwaarschrift_Zaak_1425030_&_Herroeping/PostNL_Afhaalbewijs_Blaricum_23-10-2026.pdf | PostNL Bewijs | Afhaalbewijs Blaricum (23-10-2026)',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_E_Bezwaarschrift_Zaak_1425030_&_Herroeping/Formele_Ingebrekestelling_IGS-2026-1122_22-11-2026.pdf | IGS-2026-1122 | Formele Ingebrekestelling (22-11-2026)',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_F_Provincie_Zeeland_Zaak_417521/Woo_Verzoek_GS_Zeeland_Erfgoed_en_Visserij.pdf | Zaak 417521 | Woo-verzoek Gedeputeerde Staten Zeeland',
        '01_Bestuursrechtelijke_Sporen_&_Keten_Woo/Spoor_F_Provincie_Zeeland_Zaak_417521/Besluit_en_Correspondentie_GS_Zeeland_Zaak_417521.pdf | Zaak 417521 | Besluit en correspondentie GS Zeeland',
        '02_Provinciale_&_Landelijke_Doorzendketen_Art4.2/Provincie_Zeeland_Gedeputeerde_Staten/Doorzendsommatie_PM-02_Visserij_&_Erfgoed_Zaak_417521.pdf | Art. 4.2 Woo | Doorzendsommatie PM-02 Zaak 417521',
        '02_Provinciale_&_Landelijke_Doorzendketen_Art4.2/Provincie_Noord_Brabant_&_OMWB/Zaak_Z2026-00003749_Leidingstraat_Molenplaat.pdf | Z2026-00003749 | Dossier Noord-Brabant & OMWB Leidingstraat Molenplaat',
        '02_Provinciale_&_Landelijke_Doorzendketen_Art4.2/Landelijke_Organen_RVO_RWS_LVVN/RVO_Landelijke_Pachtleggers_&_Concessies.pdf | RVO | Landelijke Pachtleggers & Concessies',
        '02_Provinciale_&_Landelijke_Doorzendketen_Art4.2/Landelijke_Organen_RVO_RWS_LVVN/Rijkswaterstaat_Waterbodembeheer_Oosterschelde.pdf | RWS | Waterbodembeheer Oosterschelde',
        '03_Historische_Visserijrechten_&_Pacht_Reimerswaal/Bestuur_der_Visserijen_Zeeuwsche_Stromen/Pachtveiling_Tholen_23-12-1873.pdf | Veiling 1873 | Pachtveiling Tholen (23-12-1873)',
        '03_Historische_Visserijrechten_&_Pacht_Reimerswaal/Bestuur_der_Visserijen_Zeeuwsche_Stromen/Pachtveiling_Middelburg_22-24-11-1892_203_Percelen.pdf | Veiling 1892 | Pachtveiling Middelburg 203 Percelen (1892)',
        '03_Historische_Visserijrechten_&_Pacht_Reimerswaal/Bestuur_der_Visserijen_Zeeuwsche_Stromen/Retributieregisters_Molenplaat_150ha.csv | Molenplaat 150ha | Retributieregisters Molenplaat (150 ha)',
        '03_Historische_Visserijrechten_&_Pacht_Reimerswaal/Concessie_Perceel_369_Bol_van_Lodijke/Pachtcontract_12.5ha_BW_Schot_1892_1915.pdf | Perceel 369 | Pachtcontract 12,5 ha B.W. Schot (1892-1915)',
        '03_Historische_Visserijrechten_&_Pacht_Reimerswaal/Concessie_Perceel_369_Bol_van_Lodijke/Scheepsmeetbrieven_TH2_TH12_TH90_Van_Duivendijk.pdf | Vloot TH2/12/90 | Scheepsmeetbrieven Werf Van Duivendijk',
        '03_Historische_Visserijrechten_&_Pacht_Reimerswaal/Juridische_Eigendomstitels_&_Waal_Arrest/Herverkaveling_Tholen_1964_Platteweg_E108_W_Bout.pdf | Platteweg E108 | Herverkaveling Tholen 1964 Platteweg E 108',
        '03_Historische_Visserijrechten_&_Pacht_Reimerswaal/Juridische_Eigendomstitels_&_Waal_Arrest/Juridische_Bewijsvoering_Directe_Stamlijn_Bout_Schot.pdf | Stamlijn | Bewijsvoering directe stamlijn Bout-Schot',
        '04_Milieu_Erfgoed_&_AVG_Dataminimalisatie/Rijksmonument_Verdronken_Stad_Reimerswaal/Erfgoedwet_Aanwijzing_RCE_Sept_2017.pdf | RCE Monument | Erfgoedwet Aanwijzing RCE (sept 2017)',
        '04_Milieu_Erfgoed_&_AVG_Dataminimalisatie/Rijksmonument_Verdronken_Stad_Reimerswaal/Archeologisch_Onderzoeksrapport_ARC-LOD-01.pdf | ARC-LOD-01 | Archeologisch Onderzoeksrapport Kasteel Lodijke',
        '04_Milieu_Erfgoed_&_AVG_Dataminimalisatie/Milieudossiers_&_Aarhus_Verdrag/Natura2000_LIFE_Oosterschelde_Beheersplan.pdf | Natura2000 | LIFE Oosterschelde Beheersplan & Aarhus',
        '04_Milieu_Erfgoed_&_AVG_Dataminimalisatie/Milieudossiers_&_Aarhus_Verdrag/Visserijzaak_3M_PFOS_Westerschelde_Jurisprudentie.pdf | Jurisprudentie | Visserijzaak 3M PFOS Westerschelde',
        '04_Milieu_Erfgoed_&_AVG_Dataminimalisatie/AVG_Privacy_Schild_&_Dataminimalisatie/Art_5.1_lid_2_sub_e_Woo_Afschermingsmatrix.pdf | Art. 5.1 Woo | Afschermingsmatrix persoonlijke levenssfeer',
        '04_Milieu_Erfgoed_&_AVG_Dataminimalisatie/AVG_Privacy_Schild_&_Dataminimalisatie/Geisoleerde_Zone_Levende_Generaties_Privacy.pdf | AVG Schild | Geïsoleerde Zone Levende Generaties'
      ])
    },
    geopark: {
      icon: '🌍',
      shortLabel: '3. UNESCO Geopark',
      title: '3. UNESCO Geopark Schelde Delta & Kasteel Lodijke (geopark_lodijke_schelde_delta/)',
      rootName: 'geopark_lodijke_schelde_delta/',
      children: buildTree([
        '01_Historische_Documenten_Lodijke/Middeleeuwse_Strijd_1301/Slag_bij_Lodijke_1301_Melis_Stoke.md | 1301 Kroniek | Rijmkroniek Melis Stoke over de Slag bij Lodijke',
        '01_Historische_Documenten_Lodijke/Middeleeuwse_Strijd_1301/Conflict_Avesnes_vs_Renesse_Malcontenten.pdf | 1301 | Conflict Avesnes vs. Renesse',
        '01_Historische_Documenten_Lodijke/Overstromingen_&_Ondergang_1530_1532/Sint_Felixvloed_1530_Quade_Saterdach.md | 5 nov 1530 | Sint-Felixvloed (Quade Saterdach)',
        '01_Historische_Documenten_Lodijke/Overstromingen_&_Ondergang_1530_1532/Allerheiligenvloed_1532_Gat_van_Lodijk.md | 1532 | Allerheiligenvloed & Gat van Lodijke',
        '01_Historische_Documenten_Lodijke/Overstromingen_&_Ondergang_1530_1532/Rapportage_Adriaan_van_Reimerswaal_Vierlingh.md | 16e Eeuw | Rapportage Adriaan van Reimerswaal & Vierlingh',
        '01_Historische_Documenten_Lodijke/Literatuur_&_Historiografie/Ewoud_van_Lodijke_Loosjes_1808.pdf | 1808 | Ewoud van Lodijke (Adriaan Loosjes, 1808)',
        '02_Onderwaterarcheologie_&_Vondsten/ARC-LOD-01_Kasteel_Lodijke_Fundamenten/Sonar_&_Duikrapport_Goyvaerts_2005.pdf | ARC-LOD-01 | Sonar- & Duikrapport Goyvaerts (2005)',
        '02_Onderwaterarcheologie_&_Vondsten/ARC-LOD-01_Kasteel_Lodijke_Fundamenten/Kloostermoppen_Tufsteen_NAP_min3m20.json | -3.20m NAP | Kloostermoppen & Tufsteen op -3,20m NAP',
        '02_Onderwaterarcheologie_&_Vondsten/ARC-LOD-02_Oesterbanken_Bol_van_Lodijke/Kalkpannen_Loodzegels_Perceel_369.json | ARC-LOD-02 | Kalkpannen & Loodzegels op Perceel 369',
        '03_Geodatabases_&_Geosites/Geosite_Register_Schelde_Delta/G-01_Verdronken_Stad_Reimerswaal_Oesterdam.csv | Geosite G-01 | Verdronken Stad Reimerswaal & Oesterdam',
        '03_Geodatabases_&_Geosites/Geosite_Register_Schelde_Delta/G-03_Oosterschelde_Estuariene_Morfologie.csv | Geosite G-03 | Oosterschelde Estuariene Morfologie',
        '03_Geodatabases_&_Geosites/Geosite_Register_Schelde_Delta/G-16_G-17_Saeftinghe_Westerschelde.csv | Geosite G-16/17 | Verdronken Land van Saeftinghe',
        '03_Geodatabases_&_Geosites/Kadastrale_&_Geodetische_Percelen/Perceel_369_Bol_van_Lodijke_RD28992_WGS84.geojson | RD X:68120 Y:388050 | Perceel 369 Bol van Lodijke (EPSG:28992)',
        '03_Geodatabases_&_Geosites/Kadastrale_&_Geodetische_Percelen/Oesterpercelen_Concessie_Schot_12.5ha.json | 12,5 ha | Oesterpercelen Concessie B.W. Schot',
        '03_Geodatabases_&_Geosites/Lithostratigrafie_&_Boorstaten/GEO-01_Formatie_van_Naaldwijk_Schelpzand.json | GEO-01 | Formatie van Naaldwijk (Schelpzand)',
        '03_Geodatabases_&_Geosites/Lithostratigrafie_&_Boorstaten/GEO-01_Laagpakket_van_Walcheren_Getijdeklei.json | GEO-01 | Laagpakket van Walcheren (Getijdeklei)',
        '03_Geodatabases_&_Geosites/Lithostratigrafie_&_Boorstaten/GEO-01_Hollandveen_Laagpakket.json | GEO-01 | Hollandveen Laagpakket',
        '04_UNESCO_Geopark_Indieningsdossiers/UNESCO_Application_Dossier_Schelde_Delta/UNESCO_Global_Geopark_Nomination_Main.pdf | UNESCO | Global Geopark Nomination Main Dossier',
        '04_UNESCO_Geopark_Indieningsdossiers/UNESCO_Application_Dossier_Schelde_Delta/Bijlagen_Indieningsdossier_Schelde_Delta.pdf | UNESCO | Bijlagen Indieningsdossier Schelde Delta',
        '04_UNESCO_Geopark_Indieningsdossiers/Beheersplannen_&_Natuurbescherming/Natura2000_LIFE_Oosterschelde_Project.pdf | Natura2000 | LIFE Oosterschelde Project',
        '04_UNESCO_Geopark_Indieningsdossiers/Beheersplannen_&_Natuurbescherming/Erfgoedwet_Rijksmonument_Reimerswaal_RCE.pdf | RCE | Erfgoedwet Rijksmonument Reimerswaal'
      ])
    },
    stamvader: {
      icon: '🌳',
      shortLabel: '4. Stamvader & Familie',
      title: '4. Stamvader- & Familiearchief (stamvader_profielen_familiearchief/)',
      rootName: 'stamvader_profielen_familiearchief/',
      children: buildTree([
        '01_Stamvader_Benjamin_Willem_Schot_1840_1935/Tab_01_Persoonlijk_Profiel_&_Gezin/B_W_Schot_1840_1935_Gramps_I0103.json | GRAMPS I0103 | Stamvader Benjamin Willem Schot (1840-1935)',
        '01_Stamvader_Benjamin_Willem_Schot_1840_1935/Tab_01_Persoonlijk_Profiel_&_Gezin/1e_Huwelijk_1863_Maria_Mathea_Bolier_13_Kinderen.md | GRAMPS I0104 | 1e Huwelijk (1863) Maria Mathea Bolier (13 kinderen)',
        '01_Stamvader_Benjamin_Willem_Schot_1840_1935/Tab_01_Persoonlijk_Profiel_&_Gezin/2e_Huwelijk_1915_Dina_Pieternella_Kegge.md | GRAMPS I0105 | 2e Huwelijk (1915) Dina Pieternella Kegge',
        '01_Stamvader_Benjamin_Willem_Schot_1840_1935/Tab_01_Persoonlijk_Profiel_&_Gezin/Ouders_Jan_Schot_1814_1882_x_Elisabeth_van_Dijk.md | Genealogie | Ouders Jan Schot (1814-1882) x Elisabeth van Dijk',
        '01_Stamvader_Benjamin_Willem_Schot_1840_1935/Tab_02_Woonhuizen_&_Loodsen_Tholen/Kruittoren_23_Wijk_A107_Kruistoren_113h.md | Tholen | Kruittoren 23 / Wijk A 107 / Kruistoren 113h',
        '01_Stamvader_Benjamin_Willem_Schot_1840_1935/Tab_02_Woonhuizen_&_Loodsen_Tholen/Raadsbesluit_1901_3_Woningen_Oud_Vossemeersepoort.pdf | Raadsbesluit 1901 | 3 Woningen aan de Oud-Vossemeersepoort',
        '01_Stamvader_Benjamin_Willem_Schot_1840_1935/Tab_02_Woonhuizen_&_Loodsen_Tholen/Oesterloods_Schot_&_Kegge_ContrEscarpe_1913.pdf | Oesterloods 1913 | Oesterloods Schot & Kegge aan de Contre-Escarpe',
        '01_Stamvader_Benjamin_Willem_Schot_1840_1935/Tab_03_Vloot_&_Concessie_Perceel_369/Oesterkweekbank_Perceel_369_Bol_van_Lodijke_12.5ha.geojson | Perceel 369 | Oesterkweekbank Perceel 369 Bol van Lodijke (12,5 ha)',
        '01_Stamvader_Benjamin_Willem_Schot_1840_1935/Tab_03_Vloot_&_Concessie_Perceel_369/Hoogaars_TH_2_Eben_Haezer_Van_Duivendijk_1902.json | TH 2 (1902) | Hoogaars TH 2 Eben Haezer (Werf Van Duivendijk)',
        '01_Stamvader_Benjamin_Willem_Schot_1840_1935/Tab_03_Vloot_&_Concessie_Perceel_369/Hoogaars_TH_12_Niets_Zonder_Gods_Zegen_1906.json | TH 12 (1906) | Hoogaars TH 12 Niets Zonder Gods Zegen',
        '01_Stamvader_Benjamin_Willem_Schot_1840_1935/Tab_03_Vloot_&_Concessie_Perceel_369/Hoogaars_TH_90_Vijf_Gebroeders_1917.json | TH 90 (1917) | Hoogaars TH 90 Vijf Gebroeders',
        '01_Stamvader_Benjamin_Willem_Schot_1840_1935/Tab_04_Expansie_Flauwers_Zierikzee_1912/Pachtcontract_Flauwers_Zierikzee_mr_Fokker.pdf | Flauwers 1912 | Pachtcontract Flauwers Zierikzee (mr. Fokker)',
        '01_Stamvader_Benjamin_Willem_Schot_1840_1935/Tab_04_Expansie_Flauwers_Zierikzee_1912/Zierikzeese_Tak_Kees_Jacob_Willem_Schot.md | Zierikzee | Zierikzeese tak Kees, Jacob en Willem Schot',
        '01_Stamvader_Benjamin_Willem_Schot_1840_1935/Tab_05_Watersnood_1906_&_Reddingsoperatie/Reddingsactie_Oud_Vossemeer_Roeiboot_TH_12.pdf | Stormvloed 1906 | Reddingsactie Oud-Vossemeer met roeiboot TH 12',
        '02_Stamvader_Takken_Bout_&_Reimerswaalse_Erfgenamen/Tab_01_Stamreeks_de_Boet_&_Reimerswaal_1511_1749/Stamvader_Jacob_Willemssen_de_Boet_1511_1556.md | 1511-1556 | Stamvader Jacob Willemssen de Boet',
        '02_Stamvader_Takken_Bout_&_Reimerswaalse_Erfgenamen/Tab_01_Stamreeks_de_Boet_&_Reimerswaal_1511_1749/Jacob_Willemse_Moeliker_Reimerswaal_1610_1680.md | 1610-1680 | Jacob Willemse Moeliker te Reimerswaal',
        '02_Stamvader_Takken_Bout_&_Reimerswaalse_Erfgenamen/Tab_01_Stamreeks_de_Boet_&_Reimerswaal_1511_1749/Adriaen_Bout_Heer_van_Lieshout_1749.pdf | 1749 | Adriaen Bout, Heer van Lieshout',
        '02_Stamvader_Takken_Bout_&_Reimerswaalse_Erfgenamen/Tab_02_Aansluiting_Tholen_Bout_x_Schot/Jacob_Bout_x_Cornelia_Adriana_Schot_geb1867.md | Stamlijn | Jacob Bout x Cornelia Adriana Schot (*1867)',
        '02_Stamvader_Takken_Bout_&_Reimerswaalse_Erfgenamen/Tab_02_Aansluiting_Tholen_Bout_x_Schot/Kwartierstaat_M_J_M_M_Bout_Generatie_IV_V.json | Kwartierstaat | Kwartierstaat M.J.M.M. Goijarts-Bout (Gen. IV & V)',
        '02_Stamvader_Takken_Bout_&_Reimerswaalse_Erfgenamen/Tab_02_Aansluiting_Tholen_Bout_x_Schot/Pieter_Bout_1884_1931_x_Lijdia_de_Laater.md | 1884-1931 | Pieter Bout x Lijdia de Laater',
        '02_Stamvader_Takken_Bout_&_Reimerswaalse_Erfgenamen/Tab_02_Aansluiting_Tholen_Bout_x_Schot/Willem_Bout_1966_Erfgenaam_Plaatsvervulling.json | GRAMPS I0120 | Willem Bout (*1966) Erfgenaam bij plaatsvervulling',
        '02_Stamvader_Takken_Bout_&_Reimerswaalse_Erfgenamen/Tab_03_Juridische_Eigendomstitels_Molenplaat/Juridische_Bewijsvoering_500_Jaar_Stamlijn.pdf | 500 Jaar Recht | Juridische bewijsvoering 500 jaar stamlijn',
        '02_Stamvader_Takken_Bout_&_Reimerswaalse_Erfgenamen/Tab_03_Juridische_Eigendomstitels_Molenplaat/Waal_Arrest_Ruilverkaveling_1964_Platteweg_E108.pdf | Waal-Arrest | Ruilverkaveling 1964 Platteweg Sectie E 108',
        '03_Stamvader_Carper_Kerpel_Reimerswaal_Tholen_1543_1869/Tab_01_Reimerswaalse_Veermannen_1543_1630/Cornelis_Janszn_de_Karper_Schipper_Reimerswaal.md | 1543 | Cornelis Janszn de Karper, Schipper van Reimerswaal',
        '03_Stamvader_Carper_Kerpel_Reimerswaal_Tholen_1543_1869/Tab_01_Reimerswaalse_Veermannen_1543_1630/Job_Cornelissen_Carper_overl1629_Reimerswaal.md | 1629 | Job Cornelissen Carper (overl. 1629 te Reimerswaal)',
        '03_Stamvader_Carper_Kerpel_Reimerswaal_Tholen_1543_1869/Tab_02_Laatste_Thoolse_Tak/Maria_Kerpel_1796_1869_x_Jan_Marinus_Schot.md | 1796-1869 | Maria Kerpel x Jan Marinus Schot',
        '04_Regenten_&_Polderheren_Tholen_1684_1915/Tab_01_Familie_van_Vrijberghe_&_Turcq/Adriaen_van_Vrijberghe_Rekenmeester_1684_1719.pdf | 1684-1719 | Adriaen van Vrijberghe, Rekenmeester',
        '04_Regenten_&_Polderheren_Tholen_1684_1915/Tab_01_Familie_van_Vrijberghe_&_Turcq/Mr_Johan_Turcq_Leenman_&_Boedelbeheerder.pdf | Tholen | Mr. Johan Turcq, Leenman & Boedelbeheerder',
        '04_Regenten_&_Polderheren_Tholen_1684_1915/Tab_02_Belgische_Bankiers_&_Rentmeesters/Pierre_Joseph_de_Caters_Hofstede_Kandia.pdf | Kandia | Pierre Joseph de Caters & Hofstede Kandia',
        '04_Regenten_&_Polderheren_Tholen_1684_1915/Tab_02_Belgische_Bankiers_&_Rentmeesters/Francoise_Dellafaille_de_Leverghem_53ha_Schakerloo.pdf | Schakerloo 53ha | Francoise Dellafaille de Leverghem (53 ha)',
        '04_Regenten_&_Polderheren_Tholen_1684_1915/Tab_03_Prominente_Thoolse_Hofsteden/Hofstede_De_Gortzak_Schakerloo_Sectie_I_360.pdf | Sectie I 360 | Hofstede De Gortzak te Schakerloo',
        '04_Regenten_&_Polderheren_Tholen_1684_1915/Tab_03_Prominente_Thoolse_Hofsteden/Hofstede_Molenvliet_43.3ha_Dumont_Catshoek.pdf | 43,3 ha | Hofstede Molenvliet (Dumont / Catshoek)',
        '04_Regenten_&_Polderheren_Tholen_1684_1915/Tab_03_Prominente_Thoolse_Hofsteden/Buitenplaats_Watervliet_77ha_mr_Francois_Ermerins.pdf | 77 ha | Buitenplaats Watervliet (mr. Francois Ermerins)',
        '05_AVG_Dataminimalisatie_&_Isolatiezone/Tab_01_AVG_Schild_Levende_Generaties/Generatie_I_Beheerder_&_Broer_Afgeschermd.json | AVG Schild | Generatie I Beheerder & Broer Afgeschermd',
        '05_AVG_Dataminimalisatie_&_Isolatiezone/Tab_01_AVG_Schild_Levende_Generaties/Generatie_II_Vader_&_Moeder_Afgeschermd.json | AVG Schild | Generatie II Vader & Moeder Afgeschermd',
        '05_AVG_Dataminimalisatie_&_Isolatiezone/Tab_02_BRP_Auditlogs_&_Doelbinding/Makelaarsuite_Logs_11_Jan_2017_&_24_Apr_2017.csv | Zaak 1463739 | Makelaarsuite Auditlogs 11 jan & 24 apr 2017'
      ])
    },
    visserij: {
      icon: '🐟',
      shortLabel: '5. Bestuur Visserijen',
      title: '5. Bestuur der Visserijen op de Schelde en Zeeuwsche Stromen (bestuur_der_visserijen_zeeuwsche_stromen/)',
      rootName: 'bestuur_der_visserijen_zeeuwsche_stromen/',
      children: buildTree([
        '01_Organisatie_&_Reglementen_1870_1918/Oprichting_&_Privatisering_Schelpdiergronden_1870.pdf | 1870 | Oprichting & Privatisering Schelpdiergronden',
        '01_Organisatie_&_Reglementen_1870_1918/Algemeen_Reglement_Visserij_Zeeuwsche_Stromen_1873.pdf | 1873 | Algemeen Reglement Visserij Zeeuwsche Stromen',
        '01_Organisatie_&_Reglementen_1870_1918/Instellingsbesluit_Bestuur_der_Visserijen.pdf | KB Besluit | Instellingsbesluit Bestuur der Visserijen',
        '01_Organisatie_&_Reglementen_1870_1918/Jaarverslagen_&_Financiële_Jaarrekeningen_1873_1918/Jaarrekening_Bestuur_der_Visserijen_1873_1890.csv | 1873-1890 | Financiële Jaarrekeningen 1873-1890',
        '01_Organisatie_&_Reglementen_1870_1918/Jaarverslagen_&_Financiële_Jaarrekeningen_1873_1918/Jaarrekening_Bestuur_der_Visserijen_1891_1918.csv | 1891-1918 | Financiële Jaarrekeningen 1891-1918',
        '02_Openbare_Pachtveilingen_&_Concessies/Pachtveiling_Tholen_23_December_1873/Veilingvoorwaarden_Oosterschelde_Percelen_1873.pdf | 23-12-1873 | Veilingvoorwaarden Oosterschelde Percelen',
        '02_Openbare_Pachtveilingen_&_Concessies/Pachtveiling_Tholen_23_December_1873/Proces_Verbaal_Toewijzing_Oestergronden_Tholen.pdf | 23-12-1873 | Proces-verbaal Toewijzing Oestergronden Tholen',
        '02_Openbare_Pachtveilingen_&_Concessies/Pachtveiling_Middelburg_22_24_November_1892/Veilingcatalogus_203_Percelen_Schelpdierenvisserij.pdf | 22-11-1892 | Veilingcatalogus 203 Percelen Schelpdierenvisserij',
        '02_Openbare_Pachtveilingen_&_Concessies/Pachtveiling_Middelburg_22_24_November_1892/Kaartbladen_Oosterschelde_Noord_Beveland_Tholen.geojson | Zeekaart 1892 | Kaartbladen Oosterschelde, Noord-Beveland & Tholen',
        '02_Openbare_Pachtveilingen_&_Concessies/Pachtveiling_Middelburg_22_24_November_1892/Toewijzingsregister_203_Percelen_1892.csv | Register 1892 | Toewijzingsregister 203 Percelen',
        '02_Openbare_Pachtveilingen_&_Concessies/Weervisserijen_Eldernissen_&_Markiezaat_1825_1877/Pachtcontract_Weer_E_Eldernissen_Familie_Van_Dort.pdf | Weer E | Pachtcontract Weer E (Eldernissen) Familie Van Dort',
        '02_Openbare_Pachtveilingen_&_Concessies/Weervisserijen_Eldernissen_&_Markiezaat_1825_1877/Retributie_Opbodveiling_fl7200_per_jaar_1877.pdf | fl. 7.200,- | Retributie Opbodveiling 1877',
        '03_Concessieregisters_&_Pachtleggers_Perceel_369_&_Molenplaat/Pachtlegger_Perceel_369_Bol_van_Lodijke_12.5ha/Concessieakte_Benjamin_Willem_Schot_1892_1915.pdf | Perceel 369 | Concessieakte B.W. Schot (1892-1915)',
        '03_Concessieregisters_&_Pachtleggers_Perceel_369_&_Molenplaat/Pachtlegger_Perceel_369_Bol_van_Lodijke_12.5ha/Retributie_Kwitanties_Perceel_369_1892_1935.csv | Perceel 369 | Retributie-kwitanties Perceel 369 (1892-1935)',
        '03_Concessieregisters_&_Pachtleggers_Perceel_369_&_Molenplaat/Pachtlegger_Perceel_369_Bol_van_Lodijke_12.5ha/Scheepsmeetbrieven_Hoogaarzen_TH2_TH12_TH90.pdf | TH 2/12/90 | Scheepsmeetbrieven Hoogaarzen TH 2, TH 12, TH 90',
        '03_Concessieregisters_&_Pachtleggers_Perceel_369_&_Molenplaat/Retributieregister_Molenplaat_150ha_Reimerswaal/Pachtpieren_&_Concessiekaarten_Molenplaat_150ha.geojson | Molenplaat 150ha | Pachtpieren & Concessiekaarten Molenplaat',
        '03_Concessieregisters_&_Pachtleggers_Perceel_369_&_Molenplaat/Retributieregister_Molenplaat_150ha_Reimerswaal/Retributieregister_Molenplaat_1873_1964.csv | 1873-1964 | Retributieregister Molenplaat',
        '03_Concessieregisters_&_Pachtleggers_Perceel_369_&_Molenplaat/Retributieregister_Molenplaat_150ha_Reimerswaal/Dossier_Zuurdeeg_Historische_Pachtkaarten.pdf | Zaak 1456324 | Dossier-Zuurdeeg Historische Pachtkaarten',
        '03_Concessieregisters_&_Pachtleggers_Perceel_369_&_Molenplaat/Pachtconcessies_Flauwers_onder_Zierikzee_1912/Pachtcontract_Oester_en_Mosselgronden_mr_Fokker.pdf | Flauwers 1912 | Pachtcontract Oester- en Mosselgronden (mr. Fokker)',
        '03_Concessieregisters_&_Pachtleggers_Perceel_369_&_Molenplaat/Pachtconcessies_Flauwers_onder_Zierikzee_1912/Registratie_Firma_WK_Schot_ZZ4_ZZ7_ZZ9_ZZ10.pdf | ZZ 4/7/9/10 | Registratie Firma W.K. Schot Zierikzee',
        '04_Woo_Procedures_&_Archiefontsluiting_Zaak_1456324/Woo_Verzoek_Visserijrechten_&_Molenplaat_13_01_2026.pdf | Zaak 1456324 | Woo-verzoek Visserijrechten & Molenplaat (13-01-2026)',
        '04_Woo_Procedures_&_Archiefontsluiting_Zaak_1456324/Besluit_B_en_W_Tholen_Zaak_1456324_Dossier_Zuurdeeg.pdf | Zaak 1456324 | Besluit B&W Tholen inzake Dossier-Zuurdeeg',
        '04_Woo_Procedures_&_Archiefontsluiting_Zaak_1456324/Beroepschrift_Rechtbank_Zeeland_West_Brabant_BRE_24_5455.pdf | BRE 24/5455 | Beroepschrift Rechtbank Zeeland-West-Brabant',
        '04_Woo_Procedures_&_Archiefontsluiting_Zaak_1456324/Provinciale_Doorzendketen_GS_Zeeland_Zaak_417521.pdf | Zaak 417521 | Provinciale Doorzendketen GS Zeeland',
        '04_Woo_Procedures_&_Archiefontsluiting_Zaak_1456324/Inhoudelijke_Afbakeningsmatrix_PM_01_Visserijpacht.pdf | PM-01 | Inhoudelijke Afbakeningsmatrix PM-01 Visserijpacht'
      ])
    },
    belanghebbenden: {
      icon: '👥',
      shortLabel: '6. Belanghebbenden & Pacht',
      title: '6. Belanghebbenden & Pachtrechten Reimerswaal (belanghebbenden_visserijpercelen_reimerswaal/)',
      rootName: 'belanghebbenden_visserijpercelen_reimerswaal/',
      children: buildTree([
        '01_Reimerswaalse_Erfgenamen_&_Visserijfamilies/Tak_Bout_Goijarts_&_Erfgenamen_Reimerswaal/Mw_M_J_M_M_Goijarts_Bout_Woo_Verzoeker_Erfgenaam.md | Belanghebbende | Mw. M.J.M.M. Goijarts-Bout (Woo-verzoeker & Erfgenaam)',
        '01_Reimerswaalse_Erfgenamen_&_Visserijfamilies/Tak_Bout_Goijarts_&_Erfgenamen_Reimerswaal/W_Bout_Mede_Erfgenaam_Plaatsvervulling_1966.md | GRAMPS I0120 | W. Bout (*1966) Mede-erfgenaam bij plaatsvervulling',
        '01_Reimerswaalse_Erfgenamen_&_Visserijfamilies/Tak_Bout_Goijarts_&_Erfgenamen_Reimerswaal/C_M_Guiljam_Moeder_overl_2021.md | GRAMPS I0121 | C.M. Guiljam (Moeder, overl. 2021)',
        '01_Reimerswaalse_Erfgenamen_&_Visserijfamilies/Tak_Bout_Goijarts_&_Erfgenamen_Reimerswaal/Hendrik_Gerard_Quaak_Oudoom_Erflater_1933_2024.md | Akte 317/2025 | H.G. Quaak (1933-2024, Scherpenisse)',
        '01_Reimerswaalse_Erfgenamen_&_Visserijfamilies/Tak_Bout_Goijarts_&_Erfgenamen_Reimerswaal/Elisabeth_Machelina_Sels_van_der_Wulp_Mede_Erfgenaam.md | Mede-erfgenaam | E.M. Sels-van der Wulp',
        '01_Reimerswaalse_Erfgenamen_&_Visserijfamilies/Tak_Schot_Reders_&_Oesterkwekers_Tholen_Zierikzee/Benjamin_Willem_Schot_1840_1935_Stamvader_Perceel_369.md | Perceel 369 | B.W. Schot (1840-1935) Stamvader Perceel 369',
        '01_Reimerswaalse_Erfgenamen_&_Visserijfamilies/Tak_Schot_Reders_&_Oesterkwekers_Tholen_Zierikzee/Maria_Mathea_Bolier_1840_1909_1e_Echtgenote.md | GRAMPS I0104 | Maria Mathea Bolier (1840-1909)',
        '01_Reimerswaalse_Erfgenamen_&_Visserijfamilies/Tak_Schot_Reders_&_Oesterkwekers_Tholen_Zierikzee/Dina_Pieternella_Kegge_1868_1944_2e_Echtgenote_Oesterkoopvrouw.md | GRAMPS I0105 | Dina Pieternella Kegge (1868-1944, Oesterkoopvrouw)',
        '01_Reimerswaalse_Erfgenamen_&_Visserijfamilies/Tak_Schot_Reders_&_Oesterkwekers_Tholen_Zierikzee/Zonen_Kees_Jacob_Willem_Schot_Expansie_Flauwers_1912.md | Flauwers 1912 | Zonen Kees, Jacob & Willem Schot',
        '01_Reimerswaalse_Erfgenamen_&_Visserijfamilies/Tak_Schot_Reders_&_Oesterkwekers_Tholen_Zierikzee/Firma_WK_Schot_Zierikzeese_Vloot_ZZ4_ZZ7_ZZ9_ZZ10.md | ZZ 4/7/9/10 | Firma W.K. Schot Zierikzeese Vloot',
        '01_Reimerswaalse_Erfgenamen_&_Visserijfamilies/Tak_Bout_Heren_van_Lieshout_&_Thoolse_Vissers/Stamvader_Jacob_Willemssen_de_Boet_ca1511_1556_Vrijberghe.md | 1511-1556 | Stamvader Jacob Willemssen de Boet (Vrijberghe)',
        '01_Reimerswaalse_Erfgenamen_&_Visserijfamilies/Tak_Bout_Heren_van_Lieshout_&_Thoolse_Vissers/Pieter_Bout_1884_1931_x_Lijdia_de_Laater_1887_1956.md | 1884-1931 | Pieter Bout x Lijdia de Laater',
        '01_Reimerswaalse_Erfgenamen_&_Visserijfamilies/Tak_Bout_Heren_van_Lieshout_&_Thoolse_Vissers/Willem_Bout_1914_1985_&_Huibrecht_Bout.md | 1914-1985 | Willem Bout & Huibrecht Bout',
        '02_Geallieerde_Visserij_Pacht_&_Kapitaalverstrekkers/Visserijfamilies_&_Borgstellers/Familie_Van_Dort_Pachters_Weer_E_Eldernissen_fl7200.md | Weer E | Familie Van Dort (Pachters Weer E Eldernissen)',
        '02_Geallieerde_Visserij_Pacht_&_Kapitaalverstrekkers/Visserijfamilies_&_Borgstellers/Familie_Van_t_Rosevelt_Borgstellers_18e_Eeuw.md | 18e Eeuw | Familie Van t Rosevelt (Borgstellers)',
        '02_Geallieerde_Visserij_Pacht_&_Kapitaalverstrekkers/Grondeigenaren_&_Kapitaalverstrekkers_Tholen/Pierre_Joseph_de_Caters_Bankier_Antwerpen_Hofstede_Kandia.md | Kandia | Pierre Joseph de Caters (Bankier Antwerpen)',
        '02_Geallieerde_Visserij_Pacht_&_Kapitaalverstrekkers/Grondeigenaren_&_Kapitaalverstrekkers_Tholen/Francoise_Dellafaille_de_Leverghem_53ha_Schakerloo.md | Schakerloo | Francoise Dellafaille de Leverghem (53 ha)',
        '02_Geallieerde_Visserij_Pacht_&_Kapitaalverstrekkers/Grondeigenaren_&_Kapitaalverstrekkers_Tholen/Adam_&_Marinus_Cornelis_van_Tilburg_Pachters_Kandia.md | Kandia | Adam & Marinus Cornelis van Tilburg',
        '02_Geallieerde_Visserij_Pacht_&_Kapitaalverstrekkers/Scheepswerven_&_Hellingbouwers/Werf_Van_Duivendijk_ContrEscarpe_Hoogaarzen_TH2_TH12_TH90.md | Van Duivendijk | Werf Van Duivendijk aan de Contre-Escarpe (TH 2, TH 12, TH 90)',
        '03_Overheidsorganen_Pachtbeheerders_&_Toezichthouders/Bestuur_der_Visserijen_op_de_Schelde_en_Zeeuwsche_Stromen/Pachtveiling_Tholen_23_12_1873.md | 1873 | Pachtveiling Tholen (23-12-1873)',
        '03_Overheidsorganen_Pachtbeheerders_&_Toezichthouders/Bestuur_der_Visserijen_op_de_Schelde_en_Zeeuwsche_Stromen/Pachtveiling_Middelburg_22_24_11_1892_203_Percelen.md | 1892 | Pachtveiling Middelburg 203 Percelen',
        '03_Overheidsorganen_Pachtbeheerders_&_Toezichthouders/Gemeente_Tholen_Bestuursorgaan/College_van_B_en_W_Tholen_Zaak_1456324_Brief_1504535.md | Zaak 1456324 | College van B&W Tholen (Brief 1504535)',
        '03_Overheidsorganen_Pachtbeheerders_&_Toezichthouders/Gemeente_Tholen_Bestuursorgaan/Adviescommissie_Bezwaarschriften_Zaak_1425030.md | Zaak 1425030 | Adviescommissie Bezwaarschriften Tholen',
        '03_Overheidsorganen_Pachtbeheerders_&_Toezichthouders/Gemeente_Tholen_Bestuursorgaan/Functionaris_Gegevensbescherming_J_H_Theunisse_Auditlogs.md | Zaak 1463739 | Functionaris Gegevensbescherming Auditlogs',
        '03_Overheidsorganen_Pachtbeheerders_&_Toezichthouders/Rechterlijke_Macht_&_Provinciale_Bestuursorganen/Rechtbank_Zeeland_West_Brabant_BRE_24_5455_WOO_ECLI_2025_6823.md | BRE 24/5455 | Rechtbank Zeeland-West-Brabant',
        '03_Overheidsorganen_Pachtbeheerders_&_Toezichthouders/Rechterlijke_Macht_&_Provinciale_Bestuursorganen/Gedeputeerde_Staten_van_Zeeland_Zaak_417521.md | Zaak 417521 | Gedeputeerde Staten van Zeeland',
        '03_Overheidsorganen_Pachtbeheerders_&_Toezichthouders/Rechterlijke_Macht_&_Provinciale_Bestuursorganen/Gedeputeerde_Staten_Noord_Brabant_OMWB_Zaak_Z2026_00003749.md | Z2026-00003749 | GS Noord-Brabant & OMWB',
        '03_Overheidsorganen_Pachtbeheerders_&_Toezichthouders/Landelijke_Organen_&_Erfgoedtoezicht/Rijksdienst_voor_Ondernemend_Nederland_RVO_Pachtleggers.md | RVO | RVO Pachtleggers',
        '03_Overheidsorganen_Pachtbeheerders_&_Toezichthouders/Landelijke_Organen_&_Erfgoedtoezicht/Rijkswaterstaat_RWS_Waterbodembeheer_Oosterschelde.md | RWS | Rijkswaterstaat Waterbodembeheer Oosterschelde',
        '03_Overheidsorganen_Pachtbeheerders_&_Toezichthouders/Landelijke_Organen_&_Erfgoedtoezicht/Ministerie_van_LVVN_Visserijbeheer.md | LVVN | Ministerie van LVVN Visserijbeheer',
        '03_Overheidsorganen_Pachtbeheerders_&_Toezichthouders/Landelijke_Organen_&_Erfgoedtoezicht/Rijksdienst_voor_het_Cultureel_Erfgoed_RCE_Rijksmonument_Reimerswaal.md | RCE | RCE Rijksmonument Reimerswaal',
        '04_Juridische_Dienstverleners_Notariaat_&_Gemachtigden/Rechtsbijstand_&_Advocatenkantoren/DAS_Rechtsbijstand_mr_S_N_Dommisse_Hess.md | DAS | DAS Rechtsbijstand (mw. mr. S.N. Dommisse-Hess)',
        '04_Juridische_Dienstverleners_Notariaat_&_Gemachtigden/Rechtsbijstand_&_Advocatenkantoren/De_Bakker_Advocaten_mr_J_J_Barendregt_de_Vries.md | Advocatuur | De Bakker Advocaten (mr. J.J. Barendregt-de Vries)',
        '04_Juridische_Dienstverleners_Notariaat_&_Gemachtigden/Rechtsbijstand_&_Advocatenkantoren/Zeeland_Advocaten_mr_R_A_A_Maat.md | Advocatuur | Advocatenkantoor Zeeland (mr. R.A.A. Maat)',
        '04_Juridische_Dienstverleners_Notariaat_&_Gemachtigden/Notariskantoren_&_Boedelvereffening/Knook_&_Schot_Notarissen_Tholen_mr_P_C_Knook.md | Notariaat | Knook & Schot Notarissen Tholen (mr. P.C. Knook)',
        '04_Juridische_Dienstverleners_Notariaat_&_Gemachtigden/Notariskantoren_&_Boedelvereffening/Notariskantoor_Dongen_Middelburg.md | Notariaat | Notariskantoor Dongen Middelburg'
      ])
    }
  };
}

export default {
  name: 'TabMappenbomen',
  components: { TreeItem },
  setup() {
    const activeTreeKey = ref('master');
    const searchQuery = ref('');
    const selectedNode = ref(null);
    const globalExpandState = ref(true);
    const expandVersion = ref(0);
    const treeCatalog = reactive(createInitialCatalog());

    const activeTreeData = computed(() => treeCatalog[activeTreeKey.value] || treeCatalog.master);

    const filteredTree = computed(() => {
      if (!searchQuery.value.trim()) return activeTreeData.value.children;
      return filterNodes(activeTreeData.value.children, searchQuery.value.toLowerCase());
    });

    function filterNodes(nodes, query) {
      return nodes.map(node => {
        if (node.children) {
          const matchingChildren = filterNodes(node.children, query);
          if (
            matchingChildren.length > 0 ||
            node.name.toLowerCase().includes(query) ||
            (node.description && node.description.toLowerCase().includes(query))
          ) {
            return { ...node, children: matchingChildren };
          }
        } else if (
          node.name.toLowerCase().includes(query) ||
          (node.description && node.description.toLowerCase().includes(query)) ||
          (node.wooCase && node.wooCase.toLowerCase().includes(query))
        ) {
          return node;
        }
        return null;
      }).filter(Boolean);
    }

    function selectFile(file) {
      selectedNode.value = file;
    }

    function deleteFromTree(list, idx) {
      list.splice(idx, 1);
    }

    function expandAll() {
      globalExpandState.value = true;
      expandVersion.value++;
    }

    function collapseAll() {
      globalExpandState.value = false;
      expandVersion.value++;
    }

    function resetTrees() {
      const fresh = createInitialCatalog();
      Object.keys(fresh).forEach(k => {
        treeCatalog[k].children = fresh[k].children;
      });
      expandVersion.value++;
    }

    return {
      activeTreeKey,
      treeCatalog,
      activeTreeData,
      filteredTree,
      searchQuery,
      selectedNode,
      globalExpandState,
      expandVersion,
      selectFile,
      deleteFromTree,
      expandAll,
      collapseAll,
      resetTrees
    };
  }
};
</script>

<style scoped>
.tree-viewer-container {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: #ffffff;
  color: #1e293b;
  border: 1px solid #e5d5d5;
  border-radius: 8px;
  overflow: hidden;
}
.tree-header {
  background: #fdf8f8;
  padding: 1rem 1.25rem;
  border-bottom: 2px solid #8b1a1a;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}
.header-main { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 8px; }
.header-main h2 { margin: 0; font-size: 1.15rem; color: #7f1d1d; }
.tree-count-badge {
  background: #8b1a1a;
  color: #ffffff;
  font-size: 0.75rem;
  font-weight: bold;
  padding: 0.25rem 0.7rem;
  border-radius: 12px;
}
.tree-selector-bar { display: flex; gap: 0.45rem; flex-wrap: wrap; }
.btn-tree-select {
  background: #ffffff;
  color: #7f1d1d;
  border: 1px solid #d4a5a5;
  padding: 0.45rem 0.75rem;
  border-radius: 6px;
  font-weight: 700;
  font-size: 0.8rem;
  cursor: pointer;
}
.btn-tree-select:hover { background: #fef2f2; border-color: #8b1a1a; }
.btn-tree-select.active {
  background: #8b1a1a;
  color: #ffffff;
  border-color: #651212;
}
.tree-actions-bar { display: flex; gap: 0.5rem; align-items: center; flex-wrap: wrap; }
.search-input {
  flex: 1;
  min-width: 240px;
  background: #ffffff;
  border: 1.5px solid #d4a5a5;
  color: #1e293b;
  padding: 0.48rem 0.8rem;
  border-radius: 6px;
  font-size: 0.85rem;
  outline: none;
}
.btn-action {
  background: #ffffff;
  color: #7f1d1d;
  border: 1px solid #d4a5a5;
  padding: 0.45rem 0.7rem;
  border-radius: 6px;
  font-size: 0.76rem;
  font-weight: 700;
  cursor: pointer;
}
.btn-action:hover { background: #8b1a1a; color: #ffffff; }
.tree-workspace { flex: 1; display: flex; overflow: hidden; position: relative; min-height: 460px; }
.tree-canvas {
  flex: 1;
  padding: 1rem 1.25rem;
  overflow-y: auto;
  font-family: ui-monospace, monospace;
  font-size: 0.85rem;
  background: #ffffff;
}
.root-folder-title {
  font-size: 0.96rem;
  color: #8b1a1a;
  margin-bottom: 0.75rem;
  padding-bottom: 0.4rem;
  border-bottom: 1px dashed #e5d5d5;
}
.file-detail-panel {
  width: 380px;
  background: #fdf8f8;
  border-left: 2px solid #8b1a1a;
  padding: 1.25rem;
  display: flex;
  flex-direction: column;
  overflow-y: auto;
}
.panel-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 1rem;
  border-bottom: 1px solid #e5d5d5;
  padding-bottom: 0.75rem;
}
.file-type-badge {
  background: #8b1a1a;
  color: #ffffff;
  font-size: 0.7rem;
  font-weight: bold;
  padding: 0.18rem 0.45rem;
  border-radius: 4px;
}
.panel-header h3 { margin: 0; font-size: 0.92rem; color: #7f1d1d; word-break: break-all; }
.btn-close { margin-left: auto; background: transparent; border: none; color: #7f1d1d; font-size: 1.1rem; cursor: pointer; }
.detail-group { margin-bottom: 1rem; }
.detail-group label {
  display: block;
  font-size: 0.72rem;
  font-weight: 800;
  color: #8b1a1a;
  margin-bottom: 0.25rem;
  text-transform: uppercase;
}
.detail-group code {
  background: #ffffff;
  color: #7f1d1d;
  border: 1px solid #e5d5d5;
  padding: 0.45rem;
  border-radius: 4px;
  display: block;
  word-break: break-all;
  font-size: 0.78rem;
}
.detail-group p { margin: 0; font-size: 0.85rem; color: #334155; line-height: 1.5; }
.woo-tag {
  background: #fef2f2;
  color: #8b1a1a;
  border: 1px solid #fca5a5;
  font-weight: bold;
  font-size: 0.75rem;
  padding: 0.22rem 0.55rem;
  border-radius: 4px;
  display: inline-block;
}
.btn-studio {
  display: inline-block;
  width: 100%;
  text-align: center;
  background: #8b1a1a;
  color: #ffffff;
  padding: 0.65rem;
  border-radius: 6px;
  text-decoration: none;
  font-weight: bold;
  font-size: 0.82rem;
  margin-top: 0.75rem;
}
</style>

<style>
.tree-node-list, .tree-sub-list { list-style: none; margin: 0; padding-left: 1.35rem; border-left: 1px dotted #d4a5a5; }
.tree-item-node { margin: 0.18rem 0; }
.tree-node-label {
  display: flex;
  align-items: center;
  gap: 0.35rem;
  padding: 0.24rem 0.5rem;
  border-radius: 4px;
  cursor: pointer;
}
.tree-node-label:hover { background: #fef2f2; }
.tree-node-label.is-folder { color: #8b1a1a; font-weight: 700; }
.tree-node-label.is-file { color: #1e293b; }
.toggle-arrow { font-size: 0.68rem; color: #8b1a1a; }
.node-inline-desc { font-size: 0.76rem; color: #64748b; font-weight: 400; margin-left: 4px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 420px; }
.node-ext-tag {
  font-size: 0.64rem;
  background: #fef2f2;
  color: #8b1a1a;
  border: 1px solid #fca5a5;
  padding: 0.08rem 0.35rem;
  border-radius: 3px;
  margin-left: auto;
  font-weight: 700;
}
.node-delete-btn { background: transparent; border: none; cursor: pointer; font-size: 0.75rem; opacity: 0.35; padding: 0 4px; }
.tree-node-label:hover .node-delete-btn { opacity: 1; }
</style>
