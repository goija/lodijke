<template>
  <div class="tree-viewer-container">
    <header class="tree-header">
      <div class="header-main">
        <h2>📂 Platform Mappenbomen & Archiefstructuren</h2>
        <span class="tree-count-badge">{{ activeTreeData.title }}</span>
      </div>

      <!-- Boom Selector Tabs -->
      <div class="tree-selector-bar">
        <button 
          v-for="(tree, key) in treeCatalog" 
          :key="key"
          :class="['btn-tree-select', { active: activeTreeKey === key }]"
          @click="activeTreeKey = key"
        >
          {{ tree.icon }} {{ tree.shortLabel }}
        </button>
      </div>

      <!-- Zoek- & Filterbalk -->
      <div class="tree-actions-bar">
        <input 
          type="text" 
          v-model="searchQuery" 
          placeholder="🔍 Zoek op bestandsnaam, Woo-zaak, coördinaten of documenttype..."
          class="search-input"
        />
      </div>
    </header>

    <div class="tree-workspace">
      <!-- Mappenboom Canvas -->
      <div class="tree-canvas">
        <div class="root-folder-title">
          📂 <strong>{{ activeTreeData.rootName }}</strong>
        </div>

        <ul class="tree-node-list">
          <tree-item 
            v-for="(child, idx) in filteredTree" 
            :key="idx" 
            :model="child" 
            :search-query="searchQuery"
            @select-file="selectFile"
          />
        </ul>
      </div>

      <!-- Rechter Detailpaneel -->
      <aside class="file-detail-panel" v-if="selectedNode">
        <div class="panel-header">
          <span class="file-type-badge">{{ selectedNode.ext || 'MAP' }}</span>
          <h3>{{ selectedNode.name }}</h3>
          <button class="btn-close" @click="selectedNode = null">✕</button>
        </div>

        <div class="panel-body">
          <div class="detail-group">
            <label>📁 Volledig Pad:</label>
            <code>{{ selectedNode.path }}</code>
          </div>

          <div class="detail-group" v-if="selectedNode.description">
            <label>📝 Omschrijving & Inhoud:</label>
            <p>{{ selectedNode.description }}</p>
          </div>

          <div class="detail-group" v-if="selectedNode.wooCase">
            <label>⚖️ Woo / Juridische Koppeling:</label>
            <span class="woo-tag">{{ selectedNode.wooCase }}</span>
          </div>

          <div class="detail-actions">
            <a href="http://127.0.0.1:8082" target="_blank" class="btn-studio">
              ⚡ Inspecteer in Axum GraphQL Studio (:8082)
            </a>
          </div>
        </div>
      </aside>
    </div>
  </div>
</template>

<script>
import { ref, computed, defineComponent, h } from 'vue';

const TreeItem = defineComponent({
  name: 'TreeItem',
  props: {
    model: Object,
    searchQuery: String
  },
  emits: ['select-file'],
  setup(props, { emit }) {
    const isOpen = ref(true);

    const isFolder = computed(() => {
      return props.model.children && props.model.children.length > 0;
    });

    function toggle() {
      if (isFolder.value) {
        isOpen.value = !isOpen.value;
      } else {
        emit('select-file', props.model);
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
          item.ext ? h('span', { class: 'node-ext-tag' }, item.ext) : null
        ]),
        isFolder.value && isOpen.value ? h('ul', { class: 'tree-sub-list' }, 
          item.children.map((child, i) => h(TreeItem, {
            key: i,
            model: child,
            searchQuery: props.searchQuery,
            onSelectFile: (node) => emit('select-file', node)
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
    case 'ttl': return '🔐';
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

    const treeCatalog = {
      master: {
        icon: '🏛️',
        shortLabel: '1. Master Platform',
        title: 'Lodijke Master Platform Architectuur',
        rootName: 'lodijke_master_platform/',
        children: [
          {
            name: '01_Solid_POD_Vault',
            children: [
              { name: 'profile/card#me', ext: 'TTL', path: '01_Solid_POD_Vault/profile/card#me', description: 'W3C Solid WebID Profiel' },
              { name: 'public/photoalbum/photos.json', ext: 'JSON', path: '01_Solid_POD_Vault/public/photoalbum/photos.json', description: 'Solid POD Fotodatabase POD-01 t/m POD-08' },
              { name: 'public/percelen/geojson_parcels.json', ext: 'GEOJSON', path: '01_Solid_POD_Vault/public/percelen/geojson_parcels.json', description: 'GeoJSON RD EPSG:28992 & WGS84 percelen' },
              { name: 'private/woo_dossiers/brp_auditlogs_firewall.json', ext: 'JSON', path: '01_Solid_POD_Vault/private/woo_dossiers/brp_auditlogs_firewall.json', wooCase: 'Spoor C: BRP Auditlogs Makelaarsuite', description: 'AVG-geïsoleerde BRP auditlogs' }
            ]
          },
          {
            name: '02_GRAMPS_Genealogy_Core',
            children: [
              { name: 'db/gramps_db_tholen_schot.familytree', ext: 'SQLITE', path: '02_GRAMPS_Genealogy_Core/db/gramps_db_tholen_schot.familytree', description: 'Primaire Gramps SQLite stamboom' },
              { name: 'exports/stamboom_schot_bout.ged', ext: 'GED', path: '02_GRAMPS_Genealogy_Core/exports/stamboom_schot_bout.ged', description: 'GEDCOM 5.5.1 exportbestand' },
              { name: 'exports/kwartierstaat_I0103.json', ext: 'JSON', path: '02_GRAMPS_Genealogy_Core/exports/kwartierstaat_I0103.json', description: 'Stamvader B.W. Schot (1840–1935)' }
            ]
          },
          {
            name: '03_Axum_Rust_&_GraphQL_API',
            children: [
              { name: 'src/main.rs', ext: 'RS', path: '03_Axum_Rust_&_GraphQL_API/src/main.rs', description: 'Axum Rust Router & Standalone Studio op :8082' },
              { name: 'data/cms_records.json', ext: 'JSON', path: '03_Axum_Rust_&_GraphQL_API/data/cms_records.json', description: 'Persistente AvoRed CMS records' }
            ]
          },
          {
            name: '04_CMS_Document_Tabs_Frontend',
            children: [
              { name: 'frontend/src/components/MainInterface.vue', ext: 'VUE', path: '04_CMS_Document_Tabs_Frontend/frontend/src/components/MainInterface.vue', description: 'Multi-Viewport Interface Manager' },
              { name: 'frontend/src/components/Tab04Kaarten.vue', ext: 'VUE', path: '04_CMS_Document_Tabs_Frontend/frontend/src/components/Tab04Kaarten.vue', description: 'Leaflet GIS Kaart met Zeekaart 1892 Overlay' }
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
              { name: 'Spoor_B_Rechtbank_Zeeland_West_Brabant_BRE_24_5455/Uitspraak_Rechtbank_ZWB_09-10-2025_ECLI_NL_RBZWB_2025_6823.pdf', ext: 'PDF', wooCase: 'BRE 24/5455 WOO', description: 'Uitspraak Bestuursrechter Beroep Niet Tijdig Beslissen' },
              { name: 'Spoor_D_Woo_Hoofdzaak_1456324_Visserij_Molenplaat/Hernieuwd_Woo_Verzoek_13-01-2026.pdf', ext: 'PDF', wooCase: 'Zaak 1456324', description: 'Woo-Hoofdverzoek Visserijrechten Molenplaat' },
              { name: 'Spoor_E_Bezwaarschrift_Zaak_1425030_&_Herroeping/Advies_Bezwaarschriftencommissie_28-08-2026.pdf', ext: 'PDF', wooCase: 'Zaak 1425030', description: 'Advies Commissie Bezwaarschriften B&W Tholen' }
            ]
          },
          {
            name: '03_Historische_Visserijrechten_&_Pacht_Reimerswaal',
            children: [
              { name: 'Bestuur_der_Visserijen/Pachtveiling_Middelburg_22-24-11-1892_203_Percelen.pdf', ext: 'PDF', description: 'Veilingcatalogus 203 Percelen Schelpdierenvisserij' },
              { name: 'Concessie_Perceel_369_Bol_van_Lodijke/Pachtcontract_12.5ha_BW_Schot_1892_1915.pdf', ext: 'PDF', description: 'Oesterconcessie No. 369 B.W. Schot op 12,5 ha' }
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
              { name: 'Middeleeuwse_Strijd_1301/Slag_bij_Lodijke_1301_Melis_Stoke.md', ext: 'MD', description: 'Slag bij Lodijke 1301 graaf Jan II van Avesnes' },
              { name: 'Overstromingen_1530_1532/Sint_Felixvloed_1530_Quade_Saterdach.md', ext: 'MD', description: 'Ondergang Kasteel & Land van Lodijke 1530-1532' }
            ]
          },
          {
            name: '02_Onderwaterarcheologie_&_Vondsten',
            children: [
              { name: 'ARC-LOD-01_Kasteel_Lodijke_Fundamenten/Sonar_&_Duikrapport_Goyvaerts_2005.pdf', ext: 'PDF', description: 'Duikrapport kasteelmuur 15x16m op -3.20m NAP' }
            ]
          },
          {
            name: '03_Geodatabases_&_Geosites',
            children: [
              { name: 'Geosite_Register/G-01_Verdronken_Stad_Reimerswaal_Oesterdam.csv', ext: 'CSV', description: 'UNESCO Geosite G-01 Geodata' },
              { name: 'Kadastrale_Percelen/Perceel_369_Bol_van_Lodijke_RD28992_WGS84.geojson', ext: 'GEOJSON', description: 'GeoJSON Coördinaten X:68120 Y:388050' }
            ]
          }
        ]
      },
      stamboom: {
        icon: '🌳',
        shortLabel: '4. Stamvader & Gezin',
        title: 'Stamvader Profielen & Familiearchief Schot, Bout, Kerpel',
        rootName: 'stamvader_profielen_familiearchief/',
        children: [
          {
            name: '01_Stamvader_Benjamin_Willem_Schot_1840_1935',
            children: [
              { name: 'Tab_01_Persoonlijk_Profiel/B_W_Schot_1840_1935_Gramps_I0103.json', ext: 'JSON', description: 'Stamvader I0103 Profiel' },
              { name: 'Tab_01_Persoonlijk_Profiel/1e_Huwelijk_1863_Maria_Bolier_13_Kinderen.md', ext: 'MD', description: '13 Kinderen Tak Bolier-Schot' },
              { name: 'Tab_01_Persoonlijk_Profiel/2e_Huwelijk_1915_Dina_Pieternella_Kegge.md', ext: 'MD', description: 'D.P. Kegge Oesterkoopvrouw' },
              { name: 'Tab_03_Vloot_&_Perceel_369/Hoogaars_TH_2_Eben_Haezer_Van_Duivendijk.json', ext: 'JSON', description: 'TH 2 Eben Haëzer Werf Van Duivendijk' }
            ]
          },
          {
            name: '02_Stamvader_Takken_Bout_&_Reimerswaalse_Erfgenamen',
            children: [
              { name: 'Tab_02_Aansluiting_Tholen/Willem_Bout_1966_Erfgenaam_Plaatsvervulling.json', ext: 'JSON', description: 'W. Bout (*1966) Erfgenaam bij Plaatsvervulling' },
              { name: 'Tab_03_Eigendomstitels/Waal_Arrest_Ruilverkaveling_1964_Platteweg_E108.pdf', ext: 'PDF', description: 'Akte van Toedeling Platteweg E108' }
            ]
          }
        ]
      },
      visserij: {
        icon: '🐟',
        shortLabel: '5. Bestuur Visserijen',
        title: 'Bestuur der Visserijen op de Schelde en Zeeuwsche Stromen',
        rootName: 'bestuur_der_visserijen_zeeuwsche_stromen/',
        children: [
          {
            name: '01_Organisatie_&_Reglementen_1870_1918',
            children: [
              { name: 'Algemeen_Reglement_Visserij_Zeeuwsche_Stromen_1873.pdf', ext: 'PDF', description: 'Algemeen Visserijreglement 1873' },
              { name: 'Jaarverslagen/Jaarrekening_Bestuur_der_Visserijen_1891_1918.csv', ext: 'CSV', description: 'Financiële retributieregisters' }
            ]
          },
          {
            name: '03_Concessieregisters_&_Pachtleggers',
            children: [
              { name: 'Pachtlegger_Perceel_369/Concessieakte_Benjamin_Willem_Schot_1892_1915.pdf', ext: 'PDF', description: 'Pachtovereenkomst 12,5 ha B.W. Schot' },
              { name: 'Retributieregister_Molenplaat_150ha/Dossier_Zuurdeeg_Historische_Pachtkaarten.pdf', ext: 'PDF', wooCase: 'Zaak 1456324', description: 'Ambtelijk Dossier-Zuurdeeg Visserijpachtkaarten' }
            ]
          }
        ]
      },
      belanghebbenden: {
        icon: '👥',
        shortLabel: '6. Belanghebbenden',
        title: 'Belanghebbenden & Pachtrechten Reimerswaal',
        rootName: 'belanghebbenden_visserijpercelen_reimerswaal/',
        children: [
          {
            name: '01_Reimerswaalse_Erfgenamen_&_Visserijfamilies',
            children: [
              { name: 'Tak_Bout_Goijarts/Mw_M_J_M_M_Goijarts_Bout_Woo_Verzoeker.md', ext: 'MD', description: 'Beneficiair Erfgenaam & Verzoeker' },
              { name: 'Tak_Bout_Goijarts/W_Bout_Mede_Erfgenaam_Plaatsvervulling_1966.md', ext: 'MD', description: 'Mede-Erfgenaam W. Bout (1966)' },
              { name: 'Tak_Schot_Reders/Benjamin_Willem_Schot_1840_1935_Stamvader.md', ext: 'MD', description: 'Stamvader Reder B.W. Schot' }
            ]
          },
          {
            name: '03_Overheidsorganen_Pachtbeheerders',
            children: [
              { name: 'Gemeente_Tholen/College_van_B_en_W_Tholen_Zaak_1456324_Brief_1504535.md', ext: 'MD', description: 'College van B&W Tholen' },
              { name: 'Rechterlijke_Macht/Rechtbank_Zeeland_West_Brabant_BRE_24_5455_WOO.md', ext: 'MD', description: 'Bestuursrechter Rechtbank ZWB' }
            ]
          }
        ]
      }
    };

    const activeTreeData = computed(() => {
      return treeCatalog[activeTreeKey.value] || treeCatalog.master;
    });

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

    return {
      activeTreeKey,
      treeCatalog,
      activeTreeData,
      filteredTree,
      searchQuery,
      selectedNode,
      selectFile
    };
  }
};
</script>

<style scoped>
.tree-viewer-container { display: flex; flex-direction: column; height: 100%; background: #1e1e2e; color: #cdd6f4; }
.tree-header { background: #181825; padding: 1rem 1.25rem; border-bottom: 1px solid #313244; display: flex; flex-direction: column; gap: 0.75rem; flex-shrink: 0; }
.header-main { display: flex; justify-content: space-between; align-items: center; }
.header-main h2 { margin: 0; font-size: 1.25rem; color: #f38ba8; }
.tree-count-badge { background: #89b4fa; color: #11111b; font-size: 0.75rem; font-weight: bold; padding: 0.2rem 0.6rem; border-radius: 10px; }

.tree-selector-bar { display: flex; gap: 0.4rem; flex-wrap: wrap; }
.btn-tree-select { background: #313244; color: #cdd6f4; border: 1px solid #45475a; padding: 0.4rem 0.65rem; border-radius: 6px; font-weight: bold; font-size: 0.8rem; cursor: pointer; transition: all 0.2s; }
.btn-tree-select.active { background: #a6e3a1; color: #11111b; border-color: #a6e3a1; }

.tree-actions-bar { display: flex; gap: 0.5rem; align-items: center; }
.search-input { flex: 1; background: #1e1e2e; border: 1px solid #313244; color: #a6e3a1; padding: 0.45rem 0.75rem; border-radius: 6px; font-size: 0.85rem; outline: none; }

.tree-workspace { flex: 1; display: flex; overflow: hidden; position: relative; min-height: 0; }
.tree-canvas { flex: 1; padding: 1rem; overflow-y: auto; font-family: "Fira Code", monospace; font-size: 0.9rem; }
.root-folder-title { font-size: 1rem; color: #fab387; margin-bottom: 0.75rem; }

.file-detail-panel { width: 340px; background: #181825; border-left: 1px solid #313244; padding: 1.25rem; display: flex; flex-direction: column; overflow-y: auto; box-shadow: -4px 0 16px rgba(0,0,0,0.4); }
.panel-header { display: flex; align-items: center; gap: 0.5rem; margin-bottom: 1rem; border-bottom: 1px solid #313244; padding-bottom: 0.75rem; }
.file-type-badge { background: #f38ba8; color: #11111b; font-size: 0.7rem; font-weight: bold; padding: 0.15rem 0.4rem; border-radius: 4px; }
.panel-header h3 { margin: 0; font-size: 1.05rem; color: #89b4fa; word-break: break-all; }
.btn-close { margin-left: auto; background: transparent; border: none; color: #a6adc8; font-size: 1.1rem; cursor: pointer; }

.detail-group { margin-bottom: 1rem; }
.detail-group label { display: block; font-size: 0.75rem; font-weight: bold; color: #f9e2af; margin-bottom: 0.25rem; text-transform: uppercase; }
.detail-group code { background: #11111b; color: #a6e3a1; padding: 0.4rem; border-radius: 4px; display: block; word-break: break-all; font-size: 0.8rem; }
.detail-group p { margin: 0; font-size: 0.88rem; color: #bac2de; line-height: 1.4; }
.woo-tag { background: #f38ba8; color: #11111b; font-weight: bold; font-size: 0.75rem; padding: 0.2rem 0.5rem; border-radius: 4px; display: inline-block; }

.btn-studio { display: inline-block; width: 100%; text-align: center; background: #a6e3a1; color: #11111b; padding: 0.6rem; border-radius: 6px; text-decoration: none; font-weight: bold; font-size: 0.82rem; margin-top: 1rem; }
</style>

<style>
.tree-node-list, .tree-sub-list { list-style: none; margin: 0; padding-left: 1.25rem; }
.tree-item-node { margin: 0.25rem 0; }
.tree-node-label { display: flex; align-items: center; gap: 0.4rem; padding: 0.2rem 0.4rem; border-radius: 4px; cursor: pointer; transition: background 0.15s; }
.tree-node-label:hover { background: #313244; }
.tree-node-label.is-folder { color: #89b4fa; font-weight: bold; }
.tree-node-label.is-file { color: #bac2de; }
.toggle-arrow { font-size: 0.7rem; color: #6c7086; }
.node-ext-tag { font-size: 0.65rem; background: #313244; color: #f5e0dc; padding: 0.1rem 0.35rem; border-radius: 3px; margin-left: auto; }
</style>
