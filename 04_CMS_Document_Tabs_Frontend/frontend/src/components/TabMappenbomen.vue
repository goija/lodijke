<template>
  <div class="tree-viewer-container">
    <!-- Header Controls -->
    <header class="tree-header">
      <div class="header-main">
        <h2>📂 Platform Mappenbomen &amp; Archiefstructuren (6 Hoofdboomen)</h2>
        <span class="tree-count-badge">{{ activeTreeData.title }}</span>
      </div>

      <!-- Boom-Selector Tabs (Alle 6 de geïntegreerde bomen) -->
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

      <!-- Zoek- & Filterbalk -->
      <div class="tree-actions-bar">
        <input
          type="text"
          v-model="searchQuery"
          placeholder="🔍 Zoek op Perceel 369, I0103, BRE 24/5455, Zuurdeeg, Beoosten Schelde..."
          class="search-input"
        />
        <button class="btn-action" @click="expandAll">➕ Alles Uitklappen</button>
        <button class="btn-action" @click="collapseAll">➖ Alles Inklappen</button>
      </div>
    </header>

    <!-- Main Workspace: Tree View + Sliding Detail Panel -->
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
            :default-open="globalExpandState"
            @select-file="selectFile"
            @delete-node="deleteFromTree(activeTreeData.children, idx)"
          />
        </ul>
      </div>

      <!-- Sliding Selected File Details Panel -->
      <transition name="slide-panel">
        <aside class="file-detail-panel" v-if="selectedNode">
          <div class="panel-header">
            <span class="file-type-badge">{{ selectedNode.ext || 'MAP' }}</span>
            <h3>{{ selectedNode.name }}</h3>
            <button class="btn-close" @click="selectedNode = null">✕</button>
          </div>

          <div class="panel-body">
            <div class="detail-group">
              <label>📁 Volledig Archiefpad:</label>
              <code>{{ selectedNode.path || (activeTreeData.rootName + selectedNode.name) }}</code>
            </div>

            <div class="detail-group" v-if="selectedNode.description">
              <label>📝 Omschrijving &amp; Bewijslast:</label>
              <p>{{ selectedNode.description }}</p>
            </div>

            <div class="detail-group" v-if="selectedNode.wooCase">
              <label>⚖️ Woo / Juridische Koppeling:</label>
              <span class="woo-tag">{{ selectedNode.wooCase }}</span>
            </div>

            <div class="detail-actions">
              <a href="http://127.0.0.1:8082/graphql" target="_blank" class="btn-studio">
                ⚡ Inspecteer in Axum GraphQL Studio (:8082)
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

const TreeItem = defineComponent({
  name: 'TreeItem',
  props: {
    model: Object,
    defaultOpen: { type: Boolean, default: true }
  },
  emits: ['select-file', 'delete-node'],
  setup(props, { emit }) {
    const isOpen = ref(props.defaultOpen);
    const isFolder = computed(() => props.model.children && props.model.children.length > 0);

    function toggle() {
      if (isFolder.value) {
        isOpen.value = !isOpen.value;
      } else {
        emit('select-file', props.model);
      }
    }

    function removeChild(index) {
      if (props.model.children) {
        props.model.children.splice(index, 1);
      }
    }

    return () => {
      const item = props.model;
      const icon = isFolder.value ? (isOpen.value ? '📂' : '📁') : getFileIcon(item.ext);

      return h('li', { class: 'tree-item-node' }, [
        h('div', {
          class: ['tree-node-label', { 'is-folder': isFolder.value, 'is-file': !isFolder.value }],
          onClick: toggle
        }, [
          isFolder.value ? h('span', { class: 'toggle-arrow' }, isOpen.value ? '▼ ' : '▶ ') : null,
          h('span', { class: 'node-icon' }, icon + ' '),
          h('span', { class: 'node-name' }, item.name),
          item.ext ? h('span', { class: 'node-ext-tag' }, item.ext) : null,
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
            defaultOpen: props.defaultOpen,
            onSelectFile: (node) => emit('select-file', node),
            onDeleteNode: () => removeChild(i)
          }))
        ) : null
      ]);
    };
  }
});

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
    case 'sqlite': return '🗄️';
    default: return '📄';
  }
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

    const treeCatalog = reactive({
      master: {
        icon: '🏛️',
        shortLabel: '1. Master Platform',
        title: 'Lodijke Master Platform Architectuur',
        rootName: 'lodijke_master_platform/',
        children: [
          {
            name: '01_Solid_POD_Vault',
            children: [
              { name: 'profile/card#me', ext: 'TTL', path: '01_Solid_POD_Vault/profile/card#me', description: 'W3C Solid WebID Profiel & Cryptografische Sleutels' },
              { name: 'public/percelen/geojson_parcels.json', ext: 'GEOJSON', path: '01_Solid_POD_Vault/public/percelen/geojson_parcels.json', description: 'GeoJSON RD EPSG:28992 & WGS84 percelen (Perceel 369 & Molenplaat)' },
              { name: 'private/woo_dossiers/brp_auditlogs_firewall.json', ext: 'JSON', path: '01_Solid_POD_Vault/private/woo_dossiers/brp_auditlogs_firewall.json', wooCase: 'AVG / BRP Handhaving Tholen', description: 'AVG-geïsoleerde BRP auditlogs en verzoekschriften' }
            ]
          },
          {
            name: '02_GRAMPS_Genealogy_Core',
            children: [
              { name: 'db/gramps_db_tholen_schot.familytree', ext: 'SQLITE', path: '02_GRAMPS_Genealogy_Core/db/gramps_db_tholen_schot.familytree', description: 'Primaire Gramps SQLite stamboom Beoosten Schelde' },
              { name: 'exports/kwartierstaat_I0103.json', ext: 'JSON', path: '02_GRAMPS_Genealogy_Core/exports/kwartierstaat_I0103.json', description: 'Kwartierstaat W. Bout (I0103), C.M. Guiljam (I0088) & B.W. Schot' }
            ]
          },
          {
            name: '03_Axum_Rust_&_GraphQL_API',
            children: [
              { name: 'src/main.rs', ext: 'RS', path: '03_Axum_Rust_&_GraphQL_API/src/main.rs', description: 'Axum Rust Router & GraphQL Resolvers op poort :8082' },
              { name: 'src/podcast_rss_server.rs', ext: 'RS', path: '03_Axum_Rust_&_GraphQL_API/src/podcast_rss_server.rs', description: 'Lokale Rust Axum Podcast & RSS Feed Engine op poort :8081' }
            ]
          }
        ]
      },
      woo: {
        icon: '⚖️',
        shortLabel: '2. Woo & Visserij',
        title: 'Woo-Procedures & Visserijrechten Reimerswaal',
        rootName: 'woo_visserij_reimerswaal_provincies/',
        children: [
          {
            name: '01_Bestuursrechtelijke_Sporen_&_Keten_Woo',
            children: [
              { name: 'Uitspraak_Rechtbank_ZWB_09-10-2025_ECLI_NL_RBZWB_2025_6823.pdf', ext: 'PDF', wooCase: 'BRE 24/5455 WOO', description: 'Uitspraak Bestuursrechter Beroep Niet Tijdig Beslissen' },
              { name: 'Hernieuwd_Woo_Verzoek_13-01-2026_Molenplaat.pdf', ext: 'PDF', wooCase: 'Zaak 1456324', description: 'Woo-Hoofdverzoek Visserijrechten Molenplaat (150 ha)' },
              { name: 'Advies_Bezwaarschriftencommissie_28-08-2026.pdf', ext: 'PDF', wooCase: 'Zaak 1425030', description: 'Advies Commissie Bezwaarschriften B&W Tholen & Belanghebbende-erkenning' }
            ]
          },
          {
            name: '02_Historische_Visserijrechten_&_Pacht_Reimerswaal',
            children: [
              { name: 'Pachtveiling_Middelburg_22-24-11-1892_203_Percelen.pdf', ext: 'PDF', wooCase: 'WOO-369-SCHOT', description: 'Veilingcatalogus 203 Percelen Schelpdierenvisserij Oosterschelde' },
              { name: 'Pachtcontract_Perceel_369_12.5ha_BW_Schot_1892_1915.pdf', ext: 'PDF', wooCase: 'WOO-369-SCHOT', description: 'Oesterconcessie No. 369 B.W. Schot op 12,5 ha (Bol van Lodijke)' }
            ]
          }
        ]
      },
      geopark: {
        icon: '🌍',
        shortLabel: '3. UNESCO Geopark',
        title: 'Geopark Schelde Delta & Kasteel Lodijke',
        rootName: 'geopark_lodijke_schelde_delta/',
        children: [
          {
            name: '01_Historische_Documenten_Lodijke',
            children: [
              { name: 'Slag_bij_Lodijke_1301_Melis_Stoke.md', ext: 'MD', description: 'Rijmkroniek Melis Stoke (Middelnederlands) over de strijd bij Lodijke in 1301' },
              { name: 'Sint_Felixvloed_1530_Quade_Saterdach.md', ext: 'MD', description: 'Primaire bronnen over de inundatie van het Land van Reimerswaal en Lodijke op 5 nov 1530' }
            ]
          },
          {
            name: '02_Onderwaterarcheologie_&_Geodata',
            children: [
              { name: 'Sonar_&_Duikrapport_Kasteel_Lodijke_ARC-LOD-01.pdf', ext: 'PDF', wooCase: 'ARC-LOD-01', description: 'Archeologische waarneming kasteelmuur 15x16m op -3.20m NAP' },
              { name: 'Perceel_369_Bol_van_Lodijke_RD28992.geojson', ext: 'GEOJSON', description: 'Exacte polygoon RD X:68120 Y:388050 (12,5 ha)' }
            ]
          }
        ]
      },
      stamvader: {
        icon: '🌳',
        shortLabel: '4. Stamvader & Familie',
        title: 'Stamvader- & Familiearchief (Beoosten Schelde)',
        rootName: 'stamvader_profielen_familiearchief/',
        children: [
          {
            name: '01_Stamreeks_Bout_Guiljam_Schot',
            children: [
              { name: 'Profiel_I0103_W_Bout_&_M_J_M_M_Goijarts_Bout.json', ext: 'JSON', wooCase: 'GRAMPS-I0103', description: 'Rechthebbenden & Erfgenamen dossier Oudelandse Visrecht' },
              { name: 'Profiel_I0088_Catharina_Machalina_Guiljam_1944_2021.pdf', ext: 'PDF', description: 'Overlevende Watersnoodramp 1953 Sint-Maartensdijk & erfopvolging' },
              { name: 'Stamvader_Hein_Guiljam_Schaapherder_Sint_Maartensdijk.md', ext: 'MD', description: '19e-eeuwse kadastrale en genealogische akten Sint-Maartensdijk (Tholen)' }
            ]
          },
          {
            name: '02_Rederij_Benjamin_Willem_Schot_1840_1925',
            children: [
              { name: 'Vlootregister_&_Oesterputten_Yerseke_Tholen.csv', ext: 'CSV', wooCase: 'WOO-369-SCHOT', description: 'Overzicht van de 11 oesterputten en vaartuigen op de Oosterschelde' },
              { name: 'Familiearchief_Loncke_&_Longueville_15e_Eeuw.pdf', ext: 'PDF', description: 'Middelnederlandse charters Roosendaal, Tholen en Reimerswaal' }
            ]
          }
        ]
      },
      visserij: {
        icon: '🐟',
        shortLabel: '5. Bestuur Visserijen',
        title: 'Bestuur der Visserijen op de Schelde en Zeeuwsche Stromen (1825–1935)',
        rootName: 'bestuur_der_visserijen_zeeuwsche_stromen/',
        children: [
          {
            name: '01_Reglementen_&_Veilingen_1825_1935',
            children: [
              { name: 'Algemeen_Reglement_Visserij_Zeeuwsche_Stromen_1873.pdf', ext: 'PDF', description: 'Wettelijk kader voor oester- en mosselpercelen Beoosten Schelde' },
              { name: 'Jaarrekening_Bestuur_der_Visserijen_1891_1918.csv', ext: 'CSV', description: 'Pachtopbrengsten en retributieregisters Oosterschelde Kom' }
            ]
          },
          {
            name: '02_Dossier_Zuurdeeg_&_Pachtleggers',
            children: [
              { name: 'Dossier_Zuurdeeg_Historische_Pachtkaarten_Beoosten_Schelde.pdf', ext: 'PDF', wooCase: 'Zaak 1456324', description: 'Ambtelijk Dossier-Zuurdeeg met de pachtkaarten van de Bol van Lodijke en Molenplaat' }
            ]
          }
        ]
      },
      belanghebbenden: {
        icon: '👥',
        shortLabel: '6. Belanghebbenden & Pacht',
        title: 'Belanghebbenden & Pachtrechten Visserijpercelen Reimerswaal',
        rootName: 'belanghebbenden_visserijpercelen_reimerswaal/',
        children: [
          {
            name: '01_Erkenning_Belanghebbende_Awb_&_MER',
            children: [
              { name: 'Besluit_Belanghebbende_Status_Oktober_2026_Awb_MER.pdf', ext: 'PDF', wooCase: 'AWB-MER-2026', description: 'Derde gewonnen Woo-procedure met formele erkenning als belanghebbende (m.e.r. & Awb)' },
              { name: 'Gerechtsdeurwaardersexploot_08-10-2026_Stuiting_Verjaring.pdf', ext: 'PDF', description: 'Betekend exploot Marco Rave te Goes inzake rechten en stuiting verjaringstermijn' }
            ]
          },
          {
            name: '02_Kadastrale_En_Visrecht_Aanspraken',
            children: [
              { name: 'Oudelandse_Visrecht_Verdronken_Land_van_Reimerswaal.pdf', ext: 'PDF', wooCase: 'REI-VISRECHT', description: 'Bewijsstukken heerlijk en oudelands visrecht op geïnundeerde gronden' },
              { name: 'Scherpenisse_Platteweg_Sectie_E_1552_1551_Kadaster.geojson', ext: 'GEOJSON', description: 'Kadastrale BBOX en perceelgrenzen Scherpenisse (Gemeente Tholen)' }
            ]
          }
        ]
      }
    });

    const activeTreeData = computed(() => treeCatalog[activeTreeKey.value] || treeCatalog.master);

    const filteredTree = computed(() => {
      if (!searchQuery.value.trim()) return activeTreeData.value.children;
      return filterNodes(activeTreeData.value.children, searchQuery.value.toLowerCase());
    });

    function filterNodes(nodes, query) {
      return nodes.map(node => {
        if (node.children) {
          const matchingChildren = filterNodes(node.children, query);
          if (matchingChildren.length > 0 || node.name.toLowerCase().includes(query)) {
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
      collapseAll
    };
  }
};
</script>

<style scoped>
.tree-viewer-container { display: flex; flex-direction: column; height: 100%; background: #1e1e2e; color: #cdd6f4; border-radius: 8px; overflow: hidden; }
.tree-header { background: #181825; padding: 1rem 1.25rem; border-bottom: 1px solid #313244; display: flex; flex-direction: column; gap: 0.75rem; }
.header-main { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 8px; }
.header-main h2 { margin: 0; font-size: 1.15rem; color: #f38ba8; }
.tree-count-badge { background: #89b4fa; color: #11111b; font-size: 0.75rem; font-weight: bold; padding: 0.2rem 0.6rem; border-radius: 10px; }
.tree-selector-bar { display: flex; gap: 0.45rem; flex-wrap: wrap; }
.btn-tree-select { background: #313244; color: #cdd6f4; border: 1px solid #45475a; padding: 0.4rem 0.7rem; border-radius: 6px; font-weight: bold; font-size: 0.8rem; cursor: pointer; transition: all 0.15s; }
.btn-tree-select.active { background: #a6e3a1; color: #11111b; border-color: #a6e3a1; }
.tree-actions-bar { display: flex; gap: 0.5rem; align-items: center; }
.search-input { flex: 1; background: #1e1e2e; border: 1px solid #313244; color: #a6e3a1; padding: 0.45rem 0.75rem; border-radius: 6px; font-size: 0.85rem; outline: none; }
.btn-action { background: #313244; color: #bac2de; border: 1px solid #45475a; padding: 0.45rem 0.65rem; border-radius: 6px; font-size: 0.75rem; cursor: pointer; }
.btn-action:hover { background: #45475a; color: #fff; }
.tree-workspace { flex: 1; display: flex; overflow: hidden; position: relative; min-height: 360px; }
.tree-canvas { flex: 1; padding: 1rem; overflow-y: auto; font-family: ui-monospace, monospace; font-size: 0.88rem; }
.root-folder-title { font-size: 0.95rem; color: #fab387; margin-bottom: 0.75rem; }
.file-detail-panel { width: 360px; background: #181825; border-left: 1px solid #313244; padding: 1.25rem; display: flex; flex-direction: column; overflow-y: auto; box-shadow: -4px 0 16px rgba(0,0,0,0.45); }
.panel-header { display: flex; align-items: center; gap: 0.5rem; margin-bottom: 1rem; border-bottom: 1px solid #313244; padding-bottom: 0.75rem; }
.file-type-badge { background: #f38ba8; color: #11111b; font-size: 0.7rem; font-weight: bold; padding: 0.15rem 0.4rem; border-radius: 4px; }
.panel-header h3 { margin: 0; font-size: 0.95rem; color: #89b4fa; word-break: break-all; }
.btn-close { margin-left: auto; background: transparent; border: none; color: #a6adc8; font-size: 1.1rem; cursor: pointer; }
.detail-group { margin-bottom: 1rem; }
.detail-group label { display: block; font-size: 0.72rem; font-weight: bold; color: #f9e2af; margin-bottom: 0.25rem; text-transform: uppercase; }
.detail-group code { background: #11111b; color: #a6e3a1; padding: 0.4rem; border-radius: 4px; display: block; word-break: break-all; font-size: 0.78rem; }
.detail-group p { margin: 0; font-size: 0.85rem; color: #bac2de; line-height: 1.45; }
.woo-tag { background: #f38ba8; color: #11111b; font-weight: bold; font-size: 0.75rem; padding: 0.2rem 0.5rem; border-radius: 4px; display: inline-block; }
.btn-studio { display: inline-block; width: 100%; text-align: center; background: #a6e3a1; color: #11111b; padding: 0.6rem; border-radius: 6px; text-decoration: none; font-weight: bold; font-size: 0.82rem; margin-top: 0.75rem; }
.slide-panel-enter-active, .slide-panel-leave-active { transition: transform 0.25s ease, opacity 0.25s ease; }
.slide-panel-enter-from, .slide-panel-leave-to { transform: translateX(100%); opacity: 0; }
</style>

<style>
.tree-node-list, .tree-sub-list { list-style: none; margin: 0; padding-left: 1.25rem; }
.tree-item-node { margin: 0.2rem 0; }
.tree-node-label { display: flex; align-items: center; gap: 0.4rem; padding: 0.25rem 0.5rem; border-radius: 4px; cursor: pointer; transition: background 0.15s; }
.tree-node-label:hover { background: #313244; }
.tree-node-label.is-folder { color: #89b4fa; font-weight: bold; }
.tree-node-label.is-file { color: #bac2de; }
.toggle-arrow { font-size: 0.7rem; color: #6c7086; }
.node-ext-tag { font-size: 0.65rem; background: #313244; color: #f5e0dc; padding: 0.1rem 0.35rem; border-radius: 3px; margin-left: auto; }
.node-delete-btn { background: transparent; border: none; cursor: pointer; font-size: 0.75rem; opacity: 0.35; padding: 0 4px; transition: opacity 0.15s; }
.tree-node-label:hover .node-delete-btn { opacity: 1; }
</style>
