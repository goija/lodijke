<template>
  <div class="gramps-comparator-container">
    <!-- Header / Navigatie Modus -->
    <header class="module-header">
      <div class="header-titles">
        <h2>🌳 GRAMPS Genealogy Core & 🔍 Bronvergelijker</h2>
        <p class="subtitle">
          Geïntegreerde Stambomen (Schot, Bout, Kerpel, Quaak) & Veld-voor-Veld Bronnenanalyse
        </p>
      </div>

      <div class="mode-switch-bar">
        <button 
          :class="['btn-mode', { active: currentMode === 'trees' }]" 
          @click="currentMode = 'trees'"
        >
          🌳 Alle Stambomen (GRAMPS Web API)
        </button>
        <button 
          :class="['btn-mode', { active: currentMode === 'comparator' }]" 
          @click="currentMode = 'comparator'"
        >
          ⚖️ Bronvergelijker & Matrix
        </button>
      </div>
    </header>

    <!-- MODUS 1: ALLE STAMBOMEN (GRAMPS CORE) -->
    <div class="trees-view" v-if="currentMode === 'trees'">
      <div class="branch-selector-bar">
        <button 
          v-for="(branch, key) in familyBranches" 
          :key="key"
          :class="['btn-branch', { active: activeBranchKey === key }]"
          @click="activeBranchKey = key"
        >
          {{ branch.icon }} {{ branch.title }}
        </button>
      </div>

      <div class="branch-content-grid">
        <div class="main-person-card">
          <div class="card-badge">{{ activeBranch.grampsId }}</div>
          <h3>{{ activeBranch.primaryPerson }}</h3>
          <p class="lifespan">🗓️ {{ activeBranch.lifespan }}</p>
          <p class="location">📍 {{ activeBranch.location }}</p>

          <div class="info-box">
            <h4>📜 Historische Rol & Concessies</h4>
            <p>{{ activeBranch.role }}</p>
          </div>

          <div class="info-box" v-if="activeBranch.fleet">
            <h4>⛵ Schepen & Vloot</h4>
            <ul>
              <li v-for="(vessel, i) in activeBranch.fleet" :key="i">{{ vessel }}</li>
            </ul>
          </div>

          <div class="actions-bar">
            <button class="btn-action" @click="downloadBranchGedcom(activeBranchKey)">
              📥 Download GEDCOM 5.5.1 ({{ activeBranch.title }})
            </button>
          </div>
        </div>

        <div class="relations-panel">
          <h3>👨‍👩‍👧‍👦 Relaties & Nageslacht ({{ activeBranch.members.length }} Personen)</h3>
          
          <div class="members-list">
            <div 
              v-for="member in activeBranch.members" 
              :key="member.id"
              class="member-card"
            >
              <div class="member-header">
                <span class="member-id">{{ member.id }}</span>
                <strong>{{ member.name }}</strong>
                <span class="member-relation">{{ member.relation }}</span>
              </div>
              <p class="member-details">{{ member.details }}</p>
              <div class="member-note" v-if="member.note">
                💡 {{ member.note }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- MODUS 2: BRONVERGELIJKER & MATRIX -->
    <div class="comparator-view" v-if="currentMode === 'comparator'">
      <div class="comparator-controls">
        <div class="selector-group">
          <label>📜 Selecteer Bron A:</label>
          <select v-model="selectedSourceAId" class="select-source">
            <option v-for="src in sourcesCatalog" :key="src.id" :value="src.id">
              {{ src.icon }} [{{ src.category }}] {{ src.title }}
            </option>
          </select>
        </div>

        <div class="swap-icon" @click="swapSources" title="Wissel Bron A en B">🔄</div>

        <div class="selector-group">
          <label>📑 Selecteer Bron B:</label>
          <select v-model="selectedSourceBId" class="select-source">
            <option v-for="src in sourcesCatalog" :key="src.id" :value="src.id">
              {{ src.icon }} [{{ src.category }}] {{ src.title }}
            </option>
          </select>
        </div>
      </div>

      <div class="comparison-matrix-grid">
        <div class="source-panel panel-a">
          <div class="panel-header">
            <span class="src-tag">BRON A</span>
            <h3>{{ sourceA.title }}</h3>
            <span class="type-badge">{{ sourceA.type }}</span>
          </div>
          <div class="panel-body">
            <div class="field-item">
              <label>📆 Datum / Tijdstip:</label>
              <div class="field-value">{{ sourceA.date }}</div>
            </div>
            <div class="field-item">
              <label>🏛️ Instantie / Auteur:</label>
              <div class="field-value">{{ sourceA.author }}</div>
            </div>
            <div class="field-item">
              <label>👥 Betrokken Personen:</label>
              <div class="field-value">{{ sourceA.people }}</div>
            </div>
            <div class="field-item">
              <label>📍 Locatie & Kadaster:</label>
              <div class="field-value">{{ sourceA.location }}</div>
            </div>
            <div class="field-item">
              <label>⚖️ Juridische Status / Woo-Spoor:</label>
              <div class="field-value woo-tag">{{ sourceA.wooCase }}</div>
            </div>
            <div class="field-item">
              <label>📝 Inhoud & Citaten:</label>
              <div class="field-value text-quote">{{ sourceA.content }}</div>
            </div>
          </div>
        </div>

        <div class="analysis-panel">
          <div class="analysis-header">
            📊 Vergelijkingsanalyse & Conflictdetectie
          </div>
          <div class="analysis-body">
            <div class="status-box" :class="comparisonResult.matchClass">
              <strong>{{ comparisonResult.matchTitle }}</strong>
              <p>{{ comparisonResult.matchSummary }}</p>
            </div>

            <div class="diff-table">
              <h4>🔍 Veld-voor-Veld Verschillen:</h4>
              <ul>
                <li v-for="(diff, idx) in comparisonResult.differences" :key="idx">
                  <strong>{{ diff.field }}:</strong>
                  <div class="diff-details">
                    <span class="diff-a">A: {{ diff.valA }}</span> ➔ 
                    <span class="diff-b">B: {{ diff.valB }}</span>
                  </div>
                </li>
              </ul>
            </div>

            <div class="reliability-score">
              <span>Betrouwbaarheidsscore:</span>
              <div class="score-bar">
                <div class="score-fill" :style="{ width: comparisonResult.score + '%' }"></div>
              </div>
              <span class="score-num">{{ comparisonResult.score }}%</span>
            </div>
          </div>
        </div>

        <div class="source-panel panel-b">
          <div class="panel-header">
            <span class="src-tag">BRON B</span>
            <h3>{{ sourceB.title }}</h3>
            <span class="type-badge">{{ sourceB.type }}</span>
          </div>
          <div class="panel-body">
            <div class="field-item">
              <label>📆 Datum / Tijdstip:</label>
              <div class="field-value">{{ sourceB.date }}</div>
            </div>
            <div class="field-item">
              <label>🏛️ Instantie / Auteur:</label>
              <div class="field-value">{{ sourceB.author }}</div>
            </div>
            <div class="field-item">
              <label>👥 Betrokken Personen:</label>
              <div class="field-value">{{ sourceB.people }}</div>
            </div>
            <div class="field-item">
              <label>📍 Locatie & Kadaster:</label>
              <div class="field-value">{{ sourceB.location }}</div>
            </div>
            <div class="field-item">
              <label>⚖️ Juridische Status / Woo-Spoor:</label>
              <div class="field-value woo-tag">{{ sourceB.wooCase }}</div>
            </div>
            <div class="field-item">
              <label>📝 Inhoud & Citaten:</label>
              <div class="field-value text-quote">{{ sourceB.content }}</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';

const currentMode = ref('trees');
const activeBranchKey = ref('schot');

const familyBranches = {
  schot: {
    icon: '🦪',
    title: 'Tak Schot (Rederij & Oesters)',
    grampsId: 'I0103',
    primaryPerson: 'Benjamin Willem Schot (1840–1935)',
    lifespan: '26 september 1840 – 17 november 1935 (95 jr)',
    location: 'Kruittoren 23 (Tholen) | Bol van Lodijke',
    role: 'Pachter Oesterperceel No. 369 (12,5 ha) & Reder van de Thoolse vloot hoogaarzen.',
    fleet: ['TH 2 Eben Haëzer (1902/1918)', 'TH 12 Niets zonder Gods zegen (1906)', 'TH 90 Vijf Gebroeders (1917)'],
    members: [
      { id: 'I0104', name: 'Maria Mathea Bolier', relation: '1e Echtgenote (1863)', details: '1840–1909 | Moeder van 13 kinderen.' },
      { id: 'I0105', name: 'Dina Pieternella Kegge', relation: '2e Echtgenote (1915)', details: '1868–1944 | Oesterkoopvrouw & Maatschap Schot & Kegge (Contr\'Escarpe).' },
      { id: 'I0106', name: 'Jan Schot B.W.zn.', relation: 'Zoon (1863)', details: 'Bouwaanvraag Oud-Vossemeersepoort 1901.' },
      { id: 'I0107', name: 'Cornelia Adriana Schot', relation: 'Dochter (1867)', details: 'Gehuwd met Jacob Bout | Tak Reimerswaalse Erfgenamen.' },
      { id: 'I0108', name: 'Kees, Jacob & Willem Schot', relation: 'Zonen (Flauwers)', details: 'Expansie Oesterpacht Flauwers Zierikzee 1912 (Firma W.K. Schot).' }
    ]
  },
  bout: {
    icon: '⚓',
    title: 'Tak Bout & Reimerswaal',
    grampsId: 'I0120',
    primaryPerson: 'Willem Bout (W. Bout, *1966)',
    lifespan: 'Geboren 1966 te Scherpenisse / Tholen',
    location: 'Scherpenisse / Platteweg E108',
    role: 'Mede-erfgenaam bij plaatsvervulling van C.M. Guiljam (1921–2021) in de nalatenschap van H.G. Quaak (1933–2024).',
    members: [
      { id: 'I0121', name: 'C.M. Guiljam', relation: 'Moeder', details: '1921–2021 | Dochter van Pieter Bout x Lijdia de Laater.' },
      { id: 'I0122', name: 'Mw. M.J.M.M. Goijarts-Bout', relation: 'Zuster', details: 'Beneficiair erfgenaam & Woo-verzoeker Visserijrechten Reimerswaal.' },
      { id: 'I0123', name: 'Pieter Bout', relation: 'Grootvader', details: '1884–1931 x Lijdia de Laater (1887–1956).' },
      { id: 'I0124', name: 'Jacob Bout', relation: 'Overgrootvader', details: '1856–1945 x Cornelia Adriana Schot (geb. 1867).' }
    ]
  },
  kerpel: {
    icon: '🐟',
    title: 'Tak Kerpel / Carper (1543–1869)',
    grampsId: 'I0130',
    primaryPerson: 'Cornelis Janszn de Karper (ca. 1543)',
    lifespan: '16e - 17e Eeuw te Reimerswaal & Tholen',
    location: 'Reimerswaal (Venusdam) ➔ Tholen (1630)',
    role: 'Schippers en veermannen tussen Reimerswaal, Tholen en Zuid-Beveland.',
    members: [
      { id: 'I0131', name: 'Job Cornelissen Carper', relation: 'Stamvader Tholen', details: 'Overleden 1629 te Reimerswaal | Schipper.' },
      { id: 'I0132', name: 'Huijbrecht Jobsen Carper', relation: 'Schippersgilde', details: 'Vissersgilde Tholen 1632 | Meestoof nering.' },
      { id: 'I0133', name: 'Maria Kerpel', relation: 'Laatste Tak (1796–1869)', details: 'Gehuwd met Jan Marinus Schot (Grootouders van B.W. Schot).' }
    ]
  },
  quaak: {
    icon: '🏛️',
    title: 'Tak Regenten, Quaak & Guiljam',
    grampsId: 'I0140',
    primaryPerson: 'Hendrik Gerard Quaak (1933–2024)',
    lifespan: '1933 – 2024 te Scherpenisse / Tholen',
    location: 'Scherpenisse / Tholen',
    role: 'Erflater nalatenschap landbouw- en visserijpercelen Tholen.',
    members: [
      { id: 'I0141', name: 'Adriaen van Vrijberghe', relation: 'Rekenmeester (1684)', details: 'Rekenmeester van Zeeland & Heer van Lodijke.' },
      { id: 'I0142', name: 'Francoise Dellafaille de Leverghem', relation: 'Grondeigenaar', details: '53 hectare Polder Schakerloo (Hofstede De Gortzak).' },
      { id: 'I0143', name: 'Elisabeth Machelina Sels-van der Wulp', relation: 'Mede-erfgenaam', details: 'Tak Sels-Guiljam.' }
    ]
  }
};

const activeBranch = computed(() => familyBranches[activeBranchKey.value]);

const sourcesCatalog = [
  {
    id: 'src-369-pacht',
    icon: '📕',
    category: 'PACHTVEILING 1892',
    type: 'Officieel Archiefstuk (Bestuur Visserijen)',
    title: 'Veilingcatalogus 203 Percelen Middelburg (1892)',
    date: '22–24 november 1892',
    author: 'Bestuur der Visserijen op de Zeeuwsche Stromen',
    people: 'B.W. Schot (Koper Perceel 369), J. Zuurdeeg',
    location: 'Bol van Lodijke | Perceel No. 369 (12,5 ha)',
    wooCase: 'Spoor D: Zaak 1456324',
    content: 'Openbare verpachting van perceel 369 voor 18 jaar op de Bol van Lodijke voor oestercultuur op -2.10m NAP.'
  },
  {
    id: 'src-concessie-369',
    icon: '⚙️',
    category: 'CONCESSIEREGISTER',
    type: 'Pachtovereenkomst (Gemeente Tholen)',
    title: 'Concessieakte Perceel 369 B.W. Schot (1892–1915)',
    date: '1 december 1892',
    author: 'Notaris Knook & Schot Tholen',
    people: 'Benjamin Willem Schot, Maria Mathea Bolier',
    location: 'Tholen / Bol van Lodijke (RD X:68120 Y:388050)',
    wooCase: 'Spoor D: Zaak 1456324 / Dossier-Zuurdeeg',
    content: 'Toewijzing van 12,5 ha oesterbank aan B.W. Schot. Exploitatiereductie bij stormschade ingevolge art. 14.'
  },
  {
    id: 'src-brp-2017',
    icon: '📊',
    category: 'BRP AUDITLOG 2017',
    type: 'Systeembevraging (GBA-V / Makelaarsuite)',
    title: 'BRP Auditlog GBA-V Bevraging 11-01-2017',
    date: '11 januari 2017 om 10:43:12 UTC',
    author: 'Gemeente Tholen / FG J.H. Theunisse',
    people: 'Verzoeker / Mw. M.J.M.M. Goijarts-Bout',
    location: 'Makelaarsuite Tholen / BRP Server',
    wooCase: 'Spoor C: BRP Auditlogs / FG Zaak 1463739',
    content: 'Registratie van persoonsbevraging in BRP. Tijdstempel verschilt 5 minuten met centrale GBA-V log.'
  },
  {
    id: 'src-brp-2024',
    icon: '⚖️',
    category: 'MAKELAARSUITE LOG 2024',
    type: 'Systeembevraging (Discrepantie)',
    title: 'Makelaarsuite Auditlog 11-03-2024 (5-Minuten Gap)',
    date: '11 maart 2024 om 10:48:15 UTC',
    author: 'Functionaris Gegevensbescherming Tholen',
    people: 'Verzoeker & Erfgenamen Bout',
    location: 'Makelaarsuite Brandmuur / BRP',
    wooCase: 'Spoor C: BRP Auditlogs Firewall',
    content: 'Anomalie in tijdsstempel logboeken. Discrepantie van 5 minuten vastgesteld tussen Makelaarsuite en landelijke GBA-V.'
  },
  {
    id: 'src-uitspraak-zwb',
    icon: '🏛️',
    category: 'RECHTERLIJKE UITSPRAAK',
    type: 'Rechtbank Uitspraak (Awb Art. 8:55)',
    title: 'Uitspraak Rechtbank ZWB (ECLI:NL:RBZWB:2025:6823)',
    date: '9 oktober 2025',
    author: 'Rechtbank Zeeland-West-Brabant (Bestuursrechter)',
    people: 'Eiser Mw. M.J.M.M. Goijarts-Bout vs. College B&W Tholen',
    location: 'Rechtbank Breda / Gemeente Tholen',
    wooCase: 'Spoor B: Zaak BRE 24/5455 WOO',
    content: 'Beroep niet tijdig beslissen gegrond verklaard. Gemeente Tholen opgedragen alsnog te beslissen op Woo-hoofdzaak 1456324.'
  }
];

const selectedSourceAId = ref('src-369-pacht');
const selectedSourceBId = ref('src-concessie-369');

const sourceA = computed(() => sourcesCatalog.find(s => s.id === selectedSourceAId.value) || sourcesCatalog[0]);
const sourceB = computed(() => sourcesCatalog.find(s => s.id === selectedSourceBId.value) || sourcesCatalog[1]);

function swapSources() {
  const temp = selectedSourceAId.value;
  selectedSourceAId.value = selectedSourceBId.value;
  selectedSourceBId.value = temp;
}

const comparisonResult = computed(() => {
  const a = sourceA.value;
  const b = sourceB.value;

  const differences = [];
  let score = 100;

  if (a.date !== b.date) {
    differences.push({ field: 'Datum & Tijdstempel', valA: a.date, valB: b.date });
    score -= 20;
  }
  if (a.author !== b.author) {
    differences.push({ field: 'Instantie / Auteur', valA: a.author, valB: b.author });
    score -= 15;
  }
  if (a.location !== b.location) {
    differences.push({ field: 'Locatie & Coördinaten', valA: a.location, valB: b.location });
    score -= 15;
  }

  let matchTitle = '✅ Hoge Overeenstemming & Synchronisatie';
  let matchSummary = 'Beide bronnen bevestigen dezelfde historische en juridische feiten zonder tegenstrijdigheden.';
  let matchClass = 'match-high';

  if (score < 80 && score >= 50) {
    matchTitle = '⚠️ Lichte Afwijking / Tijdsverschil';
    matchSummary = 'Er zijn chronologische of instantie-verschillen geconstateerd tussen de twee archiefstukken.';
    matchClass = 'match-medium';
  } else if (score < 50) {
    matchTitle = '🚨 Ernstige Discrepantie / Conflicterende Data';
    matchSummary = 'Let op: Er is sprake van een duidelijke systeem- of datumanomalie (bijv. BRP 5-minuten loggap).';
    matchClass = 'match-low';
  }

  return {
    matchTitle,
    matchSummary,
    matchClass,
    differences,
    score: Math.max(score, 10)
  };
});

function downloadBranchGedcom(branchKey) {
  const branch = familyBranches[branchKey];
  const content = `0 HEAD
1 SOUR GRAMPS_WEB_CORE
2 VERS 5.1.5
1 GEDC
2 VERS 5.5.1
1 CHAR UTF-8
0 @${branch.grampsId}@ INDI
1 NAME ${branch.primaryPerson}
1 NOTE ${branch.role}
0 TLR`;

  const blob = new Blob([content], { type: 'text/plain;charset=utf-8' });
  const link = document.createElement('a');
  link.href = URL.createObjectURL(blob);
  link.download = `stamboom_${branchKey}_gedcom551.ged`;
  link.click();
}
</script>

<style scoped>
.gramps-comparator-container { padding: 1.25rem; background: #1e1e2e; color: #cdd6f4; min-height: 100%; display: flex; flex-direction: column; }
.module-header { border-bottom: 1px solid #313244; padding-bottom: 1rem; margin-bottom: 1.25rem; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 1rem; }
.module-header h2 { margin: 0; color: #f38ba8; font-size: 1.4rem; }
.subtitle { margin: 0.25rem 0 0 0; color: #a6adc8; font-size: 0.88rem; }

.mode-switch-bar { display: flex; gap: 0.5rem; }
.btn-mode { background: #313244; color: #cdd6f4; border: 1px solid #45475a; padding: 0.5rem 1rem; border-radius: 8px; font-weight: bold; font-size: 0.85rem; cursor: pointer; transition: all 0.2s; }
.btn-mode.active { background: #89b4fa; color: #11111b; border-color: #89b4fa; }

.branch-selector-bar { display: flex; gap: 0.5rem; flex-wrap: wrap; margin-bottom: 1.25rem; }
.btn-branch { background: #181825; color: #cdd6f4; border: 1px solid #313244; padding: 0.45rem 0.85rem; border-radius: 6px; font-weight: bold; font-size: 0.85rem; cursor: pointer; }
.btn-branch.active { background: #a6e3a1; color: #11111b; }

.branch-content-grid { display: grid; grid-template-columns: 360px 1fr; gap: 1.25rem; }
.main-person-card { background: #181825; border: 1px solid #89b4fa; border-radius: 12px; padding: 1.25rem; position: relative; }
.card-badge { position: absolute; top: 1rem; right: 1rem; background: #89b4fa; color: #11111b; font-weight: bold; font-size: 0.75rem; padding: 0.15rem 0.5rem; border-radius: 4px; }
.main-person-card h3 { margin: 0 0 0.5rem 0; color: #89b4fa; font-size: 1.25rem; }
.lifespan, .location { margin: 0.25rem 0; font-size: 0.88rem; color: #bac2de; }
.info-box { background: #1e1e2e; padding: 0.75rem; border-radius: 8px; margin-top: 0.85rem; font-size: 0.85rem; }
.info-box h4 { margin: 0 0 0.3rem 0; color: #f9e2af; font-size: 0.8rem; text-transform: uppercase; }
.info-box ul { margin: 0; padding-left: 1.1rem; }
.btn-action { width: 100%; margin-top: 1rem; background: #a6e3a1; color: #11111b; border: none; padding: 0.6rem; border-radius: 8px; font-weight: bold; cursor: pointer; }

.relations-panel { background: #181825; border: 1px solid #313244; border-radius: 12px; padding: 1.25rem; }
.relations-panel h3 { margin: 0 0 1rem 0; color: #cba6f7; font-size: 1.1rem; }
.members-list { display: flex; flex-direction: column; gap: 0.75rem; }
.member-card { background: #1e1e2e; border: 1px solid #313244; border-radius: 8px; padding: 0.75rem; }
.member-header { display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.3rem; }
.member-id { font-size: 0.7rem; background: #313244; color: #f5e0dc; padding: 0.1rem 0.35rem; border-radius: 3px; font-family: monospace; }
.member-relation { margin-left: auto; font-size: 0.75rem; color: #a6e3a1; font-weight: bold; }
.member-details { margin: 0; font-size: 0.85rem; color: #bac2de; }
.member-note { margin-top: 0.4rem; font-size: 0.8rem; color: #f9e2af; background: #181825; padding: 0.4rem; border-radius: 4px; }

.comparator-controls { display: flex; align-items: center; gap: 1rem; background: #181825; padding: 0.85rem 1.25rem; border-radius: 10px; border: 1px solid #313244; margin-bottom: 1.25rem; }
.selector-group { flex: 1; display: flex; flex-direction: column; gap: 0.3rem; }
.selector-group label { font-size: 0.78rem; font-weight: bold; color: #f9e2af; }
.select-source { background: #1e1e2e; color: #a6e3a1; border: 1px solid #313244; padding: 0.5rem; border-radius: 6px; font-size: 0.88rem; outline: none; }
.swap-icon { font-size: 1.4rem; cursor: pointer; padding: 0.5rem; background: #313244; border-radius: 50%; user-select: none; }

.comparison-matrix-grid { display: grid; grid-template-columns: 1fr 300px 1fr; gap: 1rem; }
.source-panel { background: #181825; border: 1px solid #313244; border-radius: 10px; padding: 1rem; }
.panel-a { border-color: #89b4fa; }
.panel-b { border-color: #f38ba8; }
.panel-header { border-bottom: 1px solid #313244; padding-bottom: 0.6rem; margin-bottom: 0.85rem; }
.src-tag { font-size: 0.7rem; font-weight: bold; background: #313244; color: #f5e0dc; padding: 0.1rem 0.4rem; border-radius: 4px; }
.panel-header h3 { margin: 0.3rem 0; font-size: 1.05rem; color: #89b4fa; }
.type-badge { font-size: 0.75rem; color: #a6adc8; }

.field-item { margin-bottom: 0.75rem; }
.field-item label { display: block; font-size: 0.72rem; font-weight: bold; color: #6c7086; text-transform: uppercase; margin-bottom: 0.15rem; }
.field-value { font-size: 0.85rem; color: #cdd6f4; }
.text-quote { background: #11111b; padding: 0.6rem; border-radius: 6px; font-family: serif; line-height: 1.4; border-left: 3px solid #89b4fa; }

.analysis-panel { background: #181825; border: 1px solid #fab387; border-radius: 10px; padding: 1rem; display: flex; flex-direction: column; }
.analysis-header { font-weight: bold; color: #fab387; font-size: 0.9rem; border-bottom: 1px solid #313244; padding-bottom: 0.5rem; margin-bottom: 0.85rem; }
.status-box { padding: 0.75rem; border-radius: 8px; font-size: 0.82rem; margin-bottom: 1rem; }
.match-high { background: rgba(166, 227, 161, 0.15); border: 1px solid #a6e3a1; color: #a6e3a1; }
.match-medium { background: rgba(249, 226, 175, 0.15); border: 1px solid #f9e2af; color: #f9e2af; }
.match-low { background: rgba(243, 139, 168, 0.15); border: 1px solid #f38ba8; color: #f38ba8; }

.diff-table h4 { margin: 0 0 0.4rem 0; font-size: 0.8rem; color: #bac2de; }
.diff-table ul { margin: 0; padding-left: 1rem; font-size: 0.8rem; color: #cdd6f4; }
.diff-details { margin-top: 0.15rem; font-family: monospace; font-size: 0.75rem; }
.diff-a { color: #89b4fa; }
.diff-b { color: #f38ba8; }

.reliability-score { margin-top: auto; padding-top: 0.85rem; border-top: 1px dashed #313244; display: flex; align-items: center; gap: 0.5rem; font-size: 0.8rem; }
.score-bar { flex: 1; height: 8px; background: #313244; border-radius: 4px; overflow: hidden; }
.score-fill { height: 100%; background: #a6e3a1; transition: width 0.3s; }
.score-num { font-weight: bold; color: #a6e3a1; }
</style>
