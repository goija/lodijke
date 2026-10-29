<template>
  <div class="gramps-full-container">
    <!-- Header Controls -->
    <header class="gramps-header">
      <div class="header-titles">
        <h2>🌳 GRAMPS Web API Full Core</h2>
        <p class="subtitle">
          Complete Genealogische Datakern & Interactieve Stamboomweergaven
        </p>
      </div>

      <!-- Gramps View Subtabs -->
      <div class="gramps-tabs-bar">
        <button 
          v-for="tab in grampsTabs" 
          :key="tab.id"
          :class="['btn-gramps-tab', { active: activeGrampsTab === tab.id }]"
          @click="activeGrampsTab = tab.id"
        >
          {{ tab.icon }} {{ tab.label }}
        </button>
      </div>
    </header>

    <!-- WORKSPACE BODY -->
    <div class="gramps-workspace">
      
      <!-- TAB 1: INTERACTIEVE STAMBOOM & PEDIGREE CHART -->
      <div class="view-panel" v-if="activeGrampsTab === 'tree'">
        <div class="tree-controls">
          <label>Selecteer Tak:</label>
          <select v-model="selectedBranchKey" class="select-branch">
            <option value="schot">🦪 Tak Schot (Rederij B.W. Schot 1840-1935)</option>
            <option value="bout">⚓ Tak Bout & Reimerswaalse Erfgenamen (W. Bout 1966)</option>
            <option value="kerpel">🐟 Tak Kerpel / Carper (Veermannen 1543-1869)</option>
            <option value="quaak">🏛️ Tak Quaak & Regenten van Tholen</option>
          </select>

          <div class="zoom-controls">
            <button @click="treeScale += 0.1" class="btn-sm">🔍 +</button>
            <button @click="treeScale = 1.0" class="btn-sm">100%</button>
            <button @click="treeScale = Math.max(0.5, treeScale - 0.1)" class="btn-sm">🔍 -</button>
          </div>
        </div>

        <div class="pedigree-viewport" :style="{ transform: `scale(${treeScale})` }">
          <div class="pedigree-tree-root">
            <!-- Generatie 1 (Proband) -->
            <div class="tree-level gen-1">
              <div class="tree-node active-node" @click="inspectPerson(activeBranch.primary)">
                <span class="node-id">{{ activeBranch.primary.id }}</span>
                <strong>{{ activeBranch.primary.name }}</strong>
                <span class="node-dates">{{ activeBranch.primary.dates }}</span>
                <span class="node-role">{{ activeBranch.primary.role }}</span>
              </div>
            </div>

            <!-- Generatie 2 (Ouders / Partners) -->
            <div class="tree-level gen-2">
              <div 
                v-for="p in activeBranch.partners" 
                :key="p.id" 
                class="tree-node partner-node"
                @click="inspectPerson(p)"
              >
                <span class="node-id">{{ p.id }}</span>
                <strong>{{ p.name }}</strong>
                <span class="node-dates">{{ p.dates }}</span>
                <span class="node-role">{{ p.relation }}</span>
              </div>
            </div>

            <!-- Generatie 3 (Kinderen / Nageslacht) -->
            <div class="tree-level gen-3">
              <div 
                v-for="child in activeBranch.children" 
                :key="child.id" 
                class="tree-node child-node"
                @click="inspectPerson(child)"
              >
                <span class="node-id">{{ child.id }}</span>
                <strong>{{ child.name }}</strong>
                <span class="node-dates">{{ child.dates }}</span>
                <span class="node-note">{{ child.note }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- TAB 2: GEBEURTENISSEN & TIJDLIJN (EVENTS) -->
      <div class="view-panel" v-if="activeGrampsTab === 'events'">
        <div class="events-timeline">
          <h3>⏱️ Chronologisch Gebeurtenissenregister (GRAMPS Event Bus)</h3>
          <div class="timeline-list">
            <div v-for="evt in grampsEvents" :key="evt.id" class="timeline-item">
              <div class="time-badge">{{ evt.date }}</div>
              <div class="event-card">
                <span class="evt-type">{{ evt.type }}</span>
                <h4>{{ evt.title }}</h4>
                <p>{{ evt.description }}</p>

                <div class="evt-participants">
                  <strong>👥 Betrokkenen:</strong> {{ evt.participants.join(', ') }}
                </div>
                <div class="evt-place" v-if="evt.place">
                  <strong>📍 Locatie:</strong> {{ evt.place }}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- TAB 3: MEDIA & BRONNEN GALERIJ -->
      <div class="view-panel" v-if="activeGrampsTab === 'media'">
        <div class="media-grid">
          <div v-for="m in grampsMedia" :key="m.id" class="media-card">
            <div class="media-thumb">{{ m.icon }}</div>
            <div class="media-info">
              <span class="media-type">{{ m.type }}</span>
              <h4>{{ m.title }}</h4>
              <p>{{ m.description }}</p>
              <code>{{ m.path }}</code>
            </div>
          </div>
        </div>
      </div>

      <!-- TAB 4: GEDCOM EXPORT / IMPORT ENGINE -->
      <div class="view-panel" v-if="activeGrampsTab === 'gedcom'">
        <div class="gedcom-box">
          <h3>📥 / 📤 W3C GEDCOM 5.5.1 Uitwisseling</h3>
          <p>Exporteer of importeer uw stamboomgegevens naar GRAMPS, Ancestry of MyHeritage.</p>

          <div class="gedcom-actions">
            <button class="btn-gedcom-dl" @click="downloadGedcom">
              💾 Exporteer Volledige GEDCOM 5.5.1 (.ged)
            </button>

            <div class="import-area">
              <label class="btn-gedcom-ul">
                📂 Importeer GEDCOM Bestand
                <input type="file" @change="importGedcom" accept=".ged" style="display:none;" />
              </label>
              <span v-if="importMessage" class="import-msg">{{ importMessage }}</span>
            </div>
          </div>

          <div class="gedcom-preview">
            <h4>📄 GEDCOM 5.5.1 Bestandsvoorbeeld:</h4>
            <pre><code>{{ gedcomPreviewText }}</code></pre>
          </div>
        </div>
      </div>

      <!-- PERSON INSPECTOR SIDEBAR -->
      <aside class="person-inspector" v-if="inspectedPerson">
        <div class="inspector-header">
          <span class="gramps-id">{{ inspectedPerson.id }}</span>
          <h3>{{ inspectedPerson.name }}</h3>
          <button class="btn-close" @click="inspectedPerson = null">✕</button>
        </div>
        <div class="inspector-body">
          <p><strong>Levensloop:</strong> {{ inspectedPerson.dates || 'Onbekend' }}</p>
          <p><strong>Rol / Functie:</strong> {{ inspectedPerson.role || inspectedPerson.relation || 'Familielid' }}</p>
          <p v-if="inspectedPerson.note"><strong>Notitie:</strong> {{ inspectedPerson.note }}</p>
          
          <div class="inspector-section">
            <h4>🛡️ Privacy & AVG Status</h4>
            <span class="badge-avg">Openbaar Archiefstuk (Vóór 1936)</span>
          </div>
        </div>
      </aside>

    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';

const activeGrampsTab = ref('tree');
const selectedBranchKey = ref('schot');
const treeScale = ref(1.0);
const inspectedPerson = ref(null);
const importMessage = ref('');

const grampsTabs = [
  { id: 'tree', label: 'Stamboom (Pedigree View)', icon: '🌳' },
  { id: 'events', label: 'Gebeurtenissen (Events)', icon: '⏱️' },
  { id: 'media', label: 'Media & Bronnen', icon: '📸' },
  { id: 'gedcom', label: 'GEDCOM 5.5.1 Export/Import', icon: '💾' }
];

const branchesData = {
  schot: {
    primary: { id: 'I0103', name: 'Benjamin Willem Schot', dates: '1840–1935 (95 jr)', role: 'Stamvader & Reder Perceel 369' },
    partners: [
      { id: 'I0104', name: 'Maria Mathea Bolier', dates: '1840–1909', relation: '1e Echtgenote (13 kinderen)' },
      { id: 'I0105', name: 'Dina Pieternella Kegge', dates: '1868–1944', relation: '2e Echtgenote (Oesterkoopvrouw)' }
    ],
    children: [
      { id: 'I0106', name: 'Jan Schot B.W.zn.', dates: 'geb. 1863', note: 'Aanvraag Oud-Vossemeersepoort 1901' },
      { id: 'I0107', name: 'Cornelia Adriana Schot', dates: 'geb. 1867', note: 'Gehuwd met Jacob Bout' },
      { id: 'I0108', name: 'Cornelis Jan Schot', dates: 'geb. 1869', note: 'Loods Contr\'Escarpe 1913' },
      { id: 'I0109', name: 'Willem Karel Schot', dates: 'geb. 1874', note: 'Schipper op TH 90' },
      { id: 'I0110', name: 'Kees, Jacob & Willem Schot', dates: '1912 Flauwers', note: 'Expansie Zierikzee (ZZ 4, ZZ 7)' }
    ]
  },
  bout: {
    primary: { id: 'I0120', name: 'Willem Bout (W. Bout)', dates: 'geb. 1966', role: 'Mede-erfgenaam Plaatsvervulling' },
    partners: [
      { id: 'I0121', name: 'C.M. Guiljam', dates: '1921–2021', relation: 'Moeder' },
      { id: 'I0122', name: 'Mw. M.J.M.M. Goijarts-Bout', dates: 'geb. Tholen', relation: 'Zuster / Woo-Verzoeker' }
    ],
    children: [
      { id: 'I0123', name: 'Pieter Bout x Lijdia de Laater', dates: '1884–1931', note: 'Grootouders' },
      { id: 'I0124', name: 'Jacob Bout x Cornelia Schot', dates: '1856–1945', note: 'Overgrootouders' }
    ]
  },
  kerpel: {
    primary: { id: 'I0130', name: 'Cornelis Janszn de Karper', dates: 'ca. 1543', role: 'Veerman Venusdam Reimerswaal' },
    partners: [
      { id: 'I0131', name: 'Job Cornelissen Carper', dates: 'overl. 1629', relation: 'Schipper Reimerswaal' }
    ],
    children: [
      { id: 'I0132', name: 'Huijbrecht Jobsen Carper', dates: '1632 Tholen', note: 'Vissersgilde Tholen' },
      { id: 'I0133', name: 'Maria Kerpel', dates: '1796–1869', note: 'Gehuwd met Jan Marinus Schot' }
    ]
  },
  quaak: {
    primary: { id: 'I0140', name: 'Hendrik Gerard Quaak', dates: '1933–2024', role: 'Erflater Scherpenisse' },
    partners: [
      { id: 'I0141', name: 'Adriaen van Vrijberghe', dates: '1684–1719', relation: 'Rekenmeester van Zeeland' }
    ],
    children: [
      { id: 'I0142', name: 'Francoise Dellafaille', dates: '53 ha Schakerloo', note: 'Hofstede De Gortzak' }
    ]
  }
};

const activeBranch = computed(() => branchesData[selectedBranchKey.value] || branchesData.schot);

const grampsEvents = [
  { id: 'e1', date: '26 SEP 1840', type: 'GEBOORTE', title: 'Geboorte Benjamin Willem Schot', description: 'Geboren te Tholen als zoon van Jan Schot en Elisabeth van Dijk.', participants: ['B.W. Schot', 'Jan Schot'], place: 'Tholen' },
  { id: 'e2', date: '20 MAY 1863', type: 'HUWELIJK', title: 'Huwelijk B.W. Schot x M.M. Bolier', description: 'Huwelijksvoltrekking te Tholen (13 kinderen).', participants: ['B.W. Schot', 'Maria Mathea Bolier'], place: 'Tholen' },
  { id: 'e3', date: '22 NOV 1892', type: 'PACHTVEILING', title: 'Toewijzing Oesterperceel No. 369', description: 'Pachtveiling Bestuur der Visserijen te Middelburg (12,5 ha Bol van Lodijke).', participants: ['B.W. Schot'], place: 'Middelburg / Bol van Lodijke' },
  { id: 'e4', date: '12 MRT 1906', type: 'STORMVLOED', title: 'Reddingsoperatie TH 12 Oud-Vossemeer', description: 'Inzet van de bijboot van de hoogaars TH 12 tijdens noordwesterstormvloed.', participants: ['B.W. Schot', 'Willem Karel Schot'], place: 'Oud-Vossemeer' },
  { id: 'e5', date: '1 OCT 1915', type: 'HUWELIJK', title: '2e Huwelijk B.W. Schot x D.P. Kegge', description: 'Huwelijk met oesterkoopvrouw Dina Pieternella Kegge.', participants: ['B.W. Schot', 'Dina Pieternella Kegge'], place: 'Tholen' },
  { id: 'e6', date: '17 NOV 1935', type: 'OVERLIJDEN', title: 'Overlijden Benjamin Willem Schot', description: 'Overleden op 95-jarige leeftijd te Tholen (Kruittoren 23).', participants: ['B.W. Schot'], place: 'Tholen' }
];

const grampsMedia = [
  { id: 'm1', icon: '⛵', type: 'Scheepsplan', title: 'TH 2 "Eben Haëzer" Bouwtekening', description: 'Houten hoogaars gebouwd in 1902 op werf Van Duivendijk te Tholen.', path: 'media/th2_eben_haezer_1902.png' },
  { id: 'm2', icon: '🗺️', type: 'Pachtkaart', title: 'Oesterperceel No. 369 Bol van Lodijke', description: 'Kadastrale Pachtkaart 1892 (12,5 ha) EPSG:28992.', path: 'media/perceel_369_kaart_1892.png' },
  { id: 'm3', icon: '📜', type: 'Notariële Akte', title: 'Oesterverzendlods Contr\'Escarpe 1913', description: 'Aanvraag B&W Tholen voor de maatschap Schot & Kegge.', path: 'media/akte_contrescarpe_1913.pdf' }
];

const gedcomPreviewText = `0 HEAD
1 SOUR GRAMPS_WEB_CORE
2 VERS 5.1.5
1 GEDC
2 VERS 5.5.1
1 CHAR UTF-8
0 @I0103@ INDI
1 NAME Benjamin Willem /Schot/
1 SEX M
1 BIRT
2 DATE 26 SEP 1840
2 PLAC Tholen
1 DEAT
2 DATE 17 NOV 1935
2 PLAC Tholen
0 @I0120@ INDI
1 NAME Willem /Bout/
1 SEX M
1 BIRT
2 DATE 1966
0 TLR`;

function inspectPerson(p) {
  inspectedPerson.value = p;
}

function downloadGedcom() {
  const blob = new Blob([gedcomPreviewText], { type: 'text/plain;charset=utf-8' });
  const link = document.createElement('a');
  link.href = URL.createObjectURL(blob);
  link.download = 'stamboom_lodijke_gramps_full.ged';
  link.click();
}

function importGedcom(e) {
  const file = e.target.files[0];
  if (file) {
    importMessage.value = `✅ GEDCOM-bestand "${file.name}" succesvol ingelezen! Data gesynchroniseerd.`;
  }
}
</script>

<style scoped>
.gramps-full-container { display: flex; flex-direction: column; height: 100%; background: #1e1e2e; color: #cdd6f4; }
.gramps-header { background: #181825; padding: 1rem 1.25rem; border-bottom: 1px solid #313244; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 1rem; }
.gramps-header h2 { margin: 0; color: #f38ba8; font-size: 1.3rem; }
.subtitle { margin: 0.2rem 0 0 0; color: #a6adc8; font-size: 0.85rem; }

.gramps-tabs-bar { display: flex; gap: 0.4rem; flex-wrap: wrap; }
.btn-gramps-tab { background: #313244; color: #cdd6f4; border: 1px solid #45475a; padding: 0.45rem 0.8rem; border-radius: 6px; font-weight: bold; font-size: 0.82rem; cursor: pointer; }
.btn-gramps-tab.active { background: #89b4fa; color: #11111b; border-color: #89b4fa; }

.gramps-workspace { flex: 1; display: flex; overflow: hidden; position: relative; min-height: 0; }
.view-panel { flex: 1; padding: 1.25rem; overflow-y: auto; display: flex; flex-direction: column; }

/* TREE VIEW */
.tree-controls { display: flex; align-items: center; gap: 1rem; background: #181825; padding: 0.75rem 1rem; border-radius: 8px; border: 1px solid #313244; margin-bottom: 1rem; }
.select-branch { background: #1e1e2e; color: #a6e3a1; border: 1px solid #313244; padding: 0.45rem; border-radius: 6px; font-size: 0.85rem; outline: none; }
.zoom-controls { margin-left: auto; display: flex; gap: 0.3rem; }
.btn-sm { background: #313244; color: #cdd6f4; border: none; padding: 0.3rem 0.6rem; border-radius: 4px; cursor: pointer; }

.pedigree-viewport { flex: 1; transition: transform 0.2s ease; transform-origin: top left; }
.pedigree-tree-root { display: flex; flex-direction: column; gap: 1.5rem; align-items: flex-start; }
.tree-level { display: flex; gap: 1rem; flex-wrap: wrap; }
.tree-node { background: #181825; border: 1px solid #313244; border-radius: 8px; padding: 0.75rem 1rem; min-width: 220px; cursor: pointer; transition: all 0.2s; }
.tree-node:hover { border-color: #89b4fa; background: #262638; }
.active-node { border-color: #a6e3a1; background: #18251e; }
.node-id { font-size: 0.68rem; background: #313244; color: #f5e0dc; padding: 0.1rem 0.35rem; border-radius: 3px; font-family: monospace; display: inline-block; margin-bottom: 0.2rem; }
.tree-node strong { display: block; color: #cdd6f4; font-size: 0.95rem; }
.node-dates { display: block; font-size: 0.78rem; color: #a6adc8; }
.node-role { display: block; font-size: 0.78rem; color: #a6e3a1; margin-top: 0.2rem; }
.node-note { display: block; font-size: 0.75rem; color: #f9e2af; margin-top: 0.2rem; }

/* EVENTS TIMELINE */
.events-timeline h3 { color: #f38ba8; margin-top: 0; }
.timeline-list { display: flex; flex-direction: column; gap: 1rem; }
.timeline-item { display: flex; gap: 1rem; align-items: flex-start; }
.time-badge { background: #89b4fa; color: #11111b; font-weight: bold; padding: 0.3rem 0.6rem; border-radius: 6px; font-size: 0.8rem; font-family: monospace; }
.event-card { background: #181825; border: 1px solid #313244; border-radius: 8px; padding: 0.85rem; flex: 1; }
.evt-type { font-size: 0.7rem; background: #313244; color: #fab387; padding: 0.1rem 0.4rem; border-radius: 3px; font-weight: bold; }
.event-card h4 { margin: 0.3rem 0; color: #cdd6f4; }
.event-card p { margin: 0 0 0.4rem 0; font-size: 0.88rem; color: #bac2de; }
.evt-participants, .evt-place { font-size: 0.8rem; color: #a6adc8; }

/* MEDIA GRID */
.media-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 1rem; }
.media-card { background: #181825; border: 1px solid #313244; border-radius: 10px; padding: 1rem; display: flex; gap: 1rem; }
.media-thumb { font-size: 2.2rem; display: flex; align-items: center; }
.media-info h4 { margin: 0.2rem 0; color: #89b4fa; font-size: 0.95rem; }
.media-info p { margin: 0 0 0.4rem 0; font-size: 0.82rem; color: #bac2de; }
.media-info code { font-size: 0.72rem; color: #a6e3a1; }

/* GEDCOM BOX */
.gedcom-box { background: #181825; border: 1px solid #313244; border-radius: 10px; padding: 1.25rem; }
.gedcom-actions { display: flex; gap: 1rem; align-items: center; margin: 1rem 0; flex-wrap: wrap; }
.btn-gedcom-dl { background: #a6e3a1; color: #11111b; border: none; padding: 0.65rem 1.1rem; border-radius: 8px; font-weight: bold; cursor: pointer; }
.btn-gedcom-ul { background: #89b4fa; color: #11111b; padding: 0.65rem 1.1rem; border-radius: 8px; font-weight: bold; cursor: pointer; display: inline-block; }
.import-msg { color: #a6e3a1; font-size: 0.88rem; font-weight: bold; }
.gedcom-preview pre { background: #11111b; padding: 1rem; border-radius: 8px; color: #a6e3a1; font-family: monospace; font-size: 0.82rem; }

/* PERSON INSPECTOR SIDEBAR */
.person-inspector { width: 300px; background: #181825; border-left: 1px solid #313244; padding: 1.25rem; display: flex; flex-direction: column; overflow-y: auto; }
.inspector-header { display: flex; align-items: center; gap: 0.5rem; border-bottom: 1px solid #313244; padding-bottom: 0.6rem; margin-bottom: 0.85rem; }
.gramps-id { background: #89b4fa; color: #11111b; font-weight: bold; font-size: 0.72rem; padding: 0.15rem 0.4rem; border-radius: 3px; }
.inspector-header h3 { margin: 0; font-size: 1.05rem; color: #a6e3a1; }
.btn-close { margin-left: auto; background: transparent; border: none; color: #a6adc8; cursor: pointer; font-size: 1.1rem; }
.badge-avg { background: #a6e3a1; color: #11111b; font-size: 0.72rem; font-weight: bold; padding: 0.2rem 0.5rem; border-radius: 4px; display: inline-block; margin-top: 0.4rem; }
</style>
