<template>
  <div class="pdf-module-container">
    <!-- Header Toolbar -->
    <header class="pdf-header">
      <div class="header-title">
        <h2>📕 PDF Dossiers - Lezen, Markeren & Bewerken</h2>
        <span class="pdf-badge">{{ activePdf ? activePdf.title : 'Geen PDF geladen' }}</span>
      </div>

      <div class="pdf-toolbar-actions">
        <!-- PDF Selectie Dropdown -->
        <select v-model="selectedPdfId" @change="loadPdf" class="select-pdf">
          <option v-for="pdf in pdfCatalog" :key="pdf.id" :value="pdf.id">
            📄 [{{ pdf.category }}] {{ pdf.title }}
          </option>
        </select>

        <!-- Editor Modus Toggle -->
        <button 
          :class="['btn-mode-toggle', { active: isEditMode }]" 
          @click="isEditMode = !isEditMode"
        >
          {{ isEditMode ? '✏️ Bewerken Actief' : '📖 Leesmodus' }}
        </button>

        <button class="btn-save-pdf" @click="savePdfAnnotations" :disabled="!activePdf">
          💾 Wijzigingen Opslaan
        </button>
      </div>
    </header>

    <!-- WORKSPACE: DOCUMENT VIEWER + EDITOR PANEL -->
    <div class="pdf-workspace">
      
      <!-- LEFT: PDF ANNOTATION & EDITING TOOLBAR (In edit mode) -->
      <aside class="pdf-edit-sidebar" v-if="isEditMode">
        <h3>🎨 Bewerkingstools</h3>

        <div class="tool-section">
          <label>Tekst & Markering:</label>
          <div class="tool-buttons">
            <button 
              :class="['btn-tool', { active: activeTool === 'highlight' }]" 
              @click="activeTool = 'highlight'" 
              title="Gele Markeerstift"
            >
              🖍️ Markeren
            </button>
            <button 
              :class="['btn-tool', { active: activeTool === 'text' }]" 
              @click="activeTool = 'text'" 
              title="Tekst Overlay Toevoegen"
            >
              🔤 Tekstvak
            </button>
            <button 
              :class="['btn-tool', { active: activeTool === 'note' }]" 
              @click="activeTool = 'note'" 
              title="Plaknotitie / Opmerking"
            >
              📌 Notitie
            </button>
          </div>
        </div>

        <div class="tool-section">
          <label>Stempels & Status:</label>
          <div class="stamp-buttons">
            <button class="btn-stamp stamp-confidential" @click="addStamp('VERTROUWELIJK')">
              🔒 VERTROUWELIJK
            </button>
            <button class="btn-stamp stamp-approved" @click="addStamp('WOO-VRIJGEGEVEN')">
              ✅ WOO-VRIJGEGEVEN
            </button>
          </div>
        </div>

        <div class="tool-section">
          <label>Pagina Manipulatie:</label>
          <div class="page-manip-buttons">
            <button class="btn-tool" @click="rotatePdf(90)" title="90° Rechtsom Roteren">
              🔄 90° Roteren
            </button>
            <button class="btn-tool" @click="splitPdf" title="Pagina's Opsplitsen">
              ✂️ Opsplitsen
            </button>
          </div>
        </div>

        <!-- Annotation List -->
        <div class="annotations-list">
          <h4>📝 Geplaatste Aantekeningen ({{ annotations.length }}):</h4>
          <ul>
            <li v-for="(ann, idx) in annotations" :key="idx" class="ann-item">
              <span>{{ ann.type }} - p.{{ ann.page }}</span>
              <button class="btn-del-ann" @click="removeAnnotation(idx)">✕</button>
            </li>
          </ul>
        </div>
      </aside>

      <!-- CENTER: PDF CANVAS / DOCUMENT VIEWER -->
      <main class="pdf-viewer-canvas">
        <div class="canvas-top-bar" v-if="activePdf">
          <div class="page-nav">
            <button @click="currentPage = Math.max(1, currentPage - 1)" :disabled="currentPage <= 1">◀ Vorige</button>
            <span>Pagina {{ currentPage }} van {{ activePdf.totalPages }}</span>
            <button @click="currentPage = Math.min(activePdf.totalPages, currentPage + 1)" :disabled="currentPage >= activePdf.totalPages">Volgende ▶</button>
          </div>

          <div class="zoom-box">
            <button @click="pdfZoom += 0.15">🔍 +</button>
            <span>{{ Math.round(pdfZoom * 100) }}%</span>
            <button @click="pdfZoom = Math.max(0.5, pdfZoom - 0.15)">🔍 -</button>
          </div>
        </div>

        <!-- Simulated PDF Document Display -->
        <div class="pdf-document-paper" :style="{ transform: `scale(${pdfZoom}) rotate(${pdfRotation}deg)` }">
          <div class="paper-header">
            <span class="doc-watermark">{{ activePdf ? activePdf.category : 'DOCUMENT' }}</span>
            <h3>{{ activePdf ? activePdf.title : 'Geen document geladen' }}</h3>
            <span class="doc-date">{{ activePdf ? activePdf.date : '' }}</span>
          </div>

          <div class="paper-content">
            <p class="pdf-text-paragraph" v-for="(para, i) in activePdfPages" :key="i">
              {{ para }}
            </p>

            <!-- Rendered Stempels & Annotations Overlay -->
            <div 
              v-for="(ann, idx) in currentPageAnnotations" 
              :key="idx" 
              :class="['annotation-overlay', ann.typeClass]"
              :style="{ top: ann.y + 'px', left: ann.x + 'px' }"
            >
              {{ ann.text }}
            </div>
          </div>

          <div class="paper-footer">
            <span>Pagina {{ currentPage }} - Archiefdossier Reimerswaal / Lodijke Master Core</span>
          </div>
        </div>
      </main>

    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';

const selectedPdfId = ref('pdf-bre-24-5455');
const isEditMode = ref(false);
const activeTool = ref('highlight');
const currentPage = ref(1);
const pdfZoom = ref(1.0);
const pdfRotation = ref(0);
const annotations = ref([]);

const pdfCatalog = [
  {
    id: 'pdf-bre-24-5455',
    category: 'WOO-UITSPRAAK',
    title: 'Uitspraak Rechtbank ZWB 09-10-2025 (BRE 24/5455 WOO)',
    date: '09-10-2025',
    totalPages: 4,
    pages: [
      "RECHTBANK ZEELAND-WEST-BRABANT - ZITTINGSHOUDING BREDA. Uitspraak in het geding tussen Mw. M.J.M.M. Goijarts-Bout (Eiser) en het College van B&W van de Gemeente Tholen (Verweerder).",
      "PROCESVERLOOP: Eiser heeft op 13 januari 2026 hernieuwd verzoek ingediend ingevolge de Wet open overheid (Woo) inzake visserijpachtrechten Molenplaat en Dossier-Zuurdeeg.",
      "OVERWEGINGEN: Verweerder heeft de wettelijke beslistermijn overschreden. Het beroep wegens niet tijdig beslissen is gegrond. Verweerder dient binnen 2 weken alsnog te beslissen.",
      "BESLISSING: Verklaart het beroep gegrond. Draagt verweerder op het besluit bekend te maken. Veroordeelt verweerder in de proceskosten."
    ]
  },
  {
    id: 'pdf-pacht-369',
    category: 'CONCESSIE 1892',
    title: 'Pachtcontract 12,5 ha Perceel 369 B.W. Schot',
    date: '22-11-1892',
    totalPages: 3,
    pages: [
      "BESTUUR DER VISSERIJEN OP DE SCHELDE EN ZEEUWSCHE STROMEN. Concessieakte No. 369 op de Bol van Lodijke (oppervlakte 12,5 hectare).",
      "Pachter: Benjamin Willem Schot, oesterkweker en reder te Tholen (Kruittoren 23). Jaarlijkse pachtsom: fl. 450,00 te voldoen in twee gelijke termijnen.",
      "Gekoppelde vloot hoogaarzen: TH 2 'Eben Haëzer', TH 12 'Niets zonder Gods zegen' en TH 90 'Vijf Gebroeders'."
    ]
  },
  {
    id: 'pdf-brp-auditlog',
    category: 'AVG AUDITLOG',
    title: 'BRP Makelaarsuite Auditlog Discrepantie (11-03-2024)',
    date: '11-03-2024',
    totalPages: 2,
    pages: [
      "GBA-V / MAKELAARSUITE AUDITLOG - GEMEENTE THOLEN. Tijdstempel bevraging: 10:48:15 UTC. Bevraging persoonsgegevens verzoeker.",
      "ANOMALIEANALYSE: Tijdsverschil van 5 minuten vastgesteld ten opzichte van landelijke GBA-V centrale log. BRP-firewall rapportage ingediend bij FG."
    ]
  }
];

const activePdf = computed(() => pdfCatalog.find(p => p.id === selectedPdfId.value));

const activePdfPages = computed(() => {
  if (!activePdf.value) return [];
  return [activePdf.value.pages[currentPage.value - 1] || "Pagina-inhoud geladen."];
});

const currentPageAnnotations = computed(() => {
  return annotations.value.filter(a => a.pdfId === selectedPdfId.value && a.page === currentPage.value);
});

function loadPdf() {
  currentPage.value = 1;
}

function rotatePdf(deg) {
  pdfRotation.value = (pdfRotation.value + deg) % 360;
}

function splitPdf() {
  alert(`✂️ Pagina ${currentPage.value} afgesplitst als nieuw PDF-document!`);
}

function addStamp(stampText) {
  annotations.value.push({
    pdfId: selectedPdfId.value,
    page: currentPage.value,
    type: 'stamp',
    typeClass: stampText === 'VERTROUWELIJK' ? 'stamp-red' : 'stamp-green',
    text: stampText,
    x: 120,
    y: 80
  });
}

function removeAnnotation(idx) {
  annotations.value.splice(idx, 1);
}

function savePdfAnnotations() {
  alert(`💾 Aantekeningen en PDF-status voor "${activePdf.value.title}" opgeslagen!`);
}
</script>

<style scoped>
.pdf-module-container { display: flex; flex-direction: column; height: 100%; background: #1e1e2e; color: #cdd6f4; }
.pdf-header { background: #181825; padding: 0.85rem 1.25rem; border-bottom: 1px solid #313244; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 1rem; }
.pdf-header h2 { margin: 0; color: #f38ba8; font-size: 1.25rem; }
.pdf-badge { background: #89b4fa; color: #11111b; font-weight: bold; font-size: 0.75rem; padding: 0.15rem 0.5rem; border-radius: 4px; }

.pdf-toolbar-actions { display: flex; align-items: center; gap: 0.6rem; }
.select-pdf { background: #1e1e2e; color: #a6e3a1; border: 1px solid #313244; padding: 0.45rem; border-radius: 6px; font-size: 0.85rem; outline: none; }
.btn-mode-toggle { background: #313244; color: #cdd6f4; border: 1px solid #45475a; padding: 0.45rem 0.85rem; border-radius: 6px; font-weight: bold; font-size: 0.82rem; cursor: pointer; }
.btn-mode-toggle.active { background: #f9e2af; color: #11111b; border-color: #f9e2af; }
.btn-save-pdf { background: #a6e3a1; color: #11111b; border: none; padding: 0.45rem 0.85rem; border-radius: 6px; font-weight: bold; font-size: 0.82rem; cursor: pointer; }

.pdf-workspace { flex: 1; display: flex; overflow: hidden; position: relative; min-height: 0; }

.pdf-edit-sidebar { width: 260px; background: #181825; border-right: 1px solid #313244; padding: 1rem; display: flex; flex-direction: column; overflow-y: auto; flex-shrink: 0; }
.pdf-edit-sidebar h3 { margin: 0 0 1rem 0; color: #f9e2af; font-size: 1rem; border-bottom: 1px solid #313244; padding-bottom: 0.5rem; }
.tool-section { margin-bottom: 1.25rem; }
.tool-section label { display: block; font-size: 0.75rem; font-weight: bold; color: #a6adc8; margin-bottom: 0.4rem; text-transform: uppercase; }
.tool-buttons, .stamp-buttons, .page-manip-buttons { display: flex; flex-direction: column; gap: 0.4rem; }
.btn-tool { background: #313244; color: #cdd6f4; border: 1px solid #45475a; padding: 0.4rem; border-radius: 6px; font-size: 0.8rem; font-weight: bold; cursor: pointer; text-align: left; }
.btn-tool.active { background: #89b4fa; color: #11111b; }
.btn-stamp { padding: 0.45rem; border-radius: 6px; font-weight: bold; font-size: 0.78rem; cursor: pointer; border: none; }
.stamp-confidential { background: #f38ba8; color: #11111b; }
.stamp-approved { background: #a6e3a1; color: #11111b; }

.annotations-list { margin-top: auto; border-top: 1px solid #313244; padding-top: 0.85rem; }
.annotations-list h4 { margin: 0 0 0.5rem 0; font-size: 0.8rem; color: #bac2de; }
.annotations-list ul { margin: 0; padding: 0; list-style: none; }
.ann-item { display: flex; justify-content: space-between; align-items: center; font-size: 0.78rem; background: #1e1e2e; padding: 0.3rem 0.5rem; border-radius: 4px; margin-bottom: 0.3rem; }
.btn-del-ann { background: transparent; border: none; color: #f38ba8; cursor: pointer; }

.pdf-viewer-canvas { flex: 1; display: flex; flex-direction: column; background: #11111b; overflow: auto; padding: 1.25rem; align-items: center; }
.canvas-top-bar { display: flex; justify-content: space-between; align-items: center; width: 100%; max-width: 700px; background: #181825; padding: 0.5rem 1rem; border-radius: 8px; border: 1px solid #313244; margin-bottom: 1.25rem; font-size: 0.85rem; }
.page-nav, .zoom-box { display: flex; align-items: center; gap: 0.5rem; }
.canvas-top-bar button { background: #313244; color: #cdd6f4; border: none; padding: 0.25rem 0.6rem; border-radius: 4px; cursor: pointer; }

.pdf-document-paper { background: #ffffff; color: #11111b; width: 100%; max-width: 680px; min-height: 780px; padding: 2.5rem; box-shadow: 0 8px 32px rgba(0,0,0,0.6); border-radius: 4px; position: relative; transition: transform 0.2s ease; display: flex; flex-direction: column; }
.paper-header { border-bottom: 2px solid #11111b; padding-bottom: 0.85rem; margin-bottom: 1.5rem; display: flex; flex-direction: column; }
.doc-watermark { font-size: 0.72rem; font-weight: bold; background: #11111b; color: #ffffff; padding: 0.15rem 0.4rem; border-radius: 3px; align-self: flex-start; margin-bottom: 0.4rem; }
.paper-header h3 { margin: 0; font-size: 1.2rem; color: #11111b; }
.doc-date { font-size: 0.8rem; color: #555; margin-top: 0.2rem; }

.paper-content { flex: 1; position: relative; font-family: "Georgia", serif; line-height: 1.7; font-size: 0.98rem; }
.pdf-text-paragraph { margin-bottom: 1rem; text-align: justify; }

.paper-footer { border-top: 1px solid #ccc; padding-top: 0.85rem; margin-top: 2rem; font-size: 0.75rem; color: #777; text-align: center; }

.annotation-overlay { position: absolute; font-weight: bold; padding: 0.35rem 0.75rem; border-radius: 4px; pointer-events: none; z-index: 10; font-family: sans-serif; font-size: 0.85rem; }
.stamp-red { background: rgba(243, 139, 168, 0.85); color: #000; border: 2px solid #f38ba8; transform: rotate(-12deg); }
.stamp-green { background: rgba(166, 227, 161, 0.85); color: #000; border: 2px solid #a6e3a1; transform: rotate(5deg); }
</style>
