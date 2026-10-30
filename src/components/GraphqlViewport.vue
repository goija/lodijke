<template>
  <section class="gql-viewport" aria-label="GraphQL IDE Viewport">
    <!-- Topbalk van de GraphQL IDE Viewport -->
    <div class="gql-toolbar">
      <div class="gql-status" :class="{ ok: connected }">
        <span class="pulse-dot"></span>
        <span class="status-text">{{ statusLabel }}</span>
        <span class="latency-pill" v-if="latencyMs !== null">{{ latencyMs }} ms</span>
      </div>

      <div class="gql-actions">
        <button class="btn-preset" @click="applyPreset('archief')" title="Alle oorkondes en RD-coördinaten">
          📜 Archief
        </button>
        <button class="btn-preset" @click="applyPreset('shoelace')" title="Shoelace Planimeter RD">
          📐 Shoelace
        </button>
        <button class="btn-preset" @click="applyPreset('mutatie')" title="Nieuw record toevoegen">
          ➕ Mutatie
        </button>
        <button class="btn-preset" :class="{ active: showSchema }" @click="toggleSchema">
          📚 Schema
        </button>
        <button class="btn-run" @click="runGraphQL" :disabled="busy">
          {{ busy ? '⏳ Bezig...' : '▶ Run (Ctrl+Enter)' }}
        </button>
      </div>
    </div>

    <!-- Responsive Multi-Pane Grid binnen de Viewport (Geen Iframe) -->
    <div class="gql-workbench" :class="{ 'with-schema': showSchema }">
      <!-- Paneel 1: Query & Variabelen Editor -->
      <div class="gql-pane editor-column">
        <div class="sub-header">
          <span>GraphQL Query Editor (`POST /graphql`)</span>
          <button class="btn-mini" @click="prettifyQuery">Format</button>
        </div>
        <textarea
          v-model="queryInput"
          class="code-area query-area"
          spellcheck="false"
          autocapitalize="off"
          autocomplete="off"
          @keydown.ctrl.enter.prevent="runGraphQL"
          @keydown.meta.enter.prevent="runGraphQL"
        ></textarea>

        <div class="sub-header vars-header" @click="varsOpen = !varsOpen">
          <span>Query Variables (JSON)</span>
          <span>{{ varsOpen ? '▾' : '▸' }}</span>
        </div>
        <textarea
          v-if="varsOpen"
          v-model="variablesInput"
          class="code-area vars-area"
          spellcheck="false"
          placeholder='{ "coords": [[68450, 387210], [68550, 387210], [68550, 387310]] }'
        ></textarea>
      </div>

      <!-- Paneel 2: Live JSON Resultaat -->
      <div class="gql-pane response-column">
        <div class="sub-header">
          <span>Response Payload</span>
          <button class="btn-mini" @click="copyResponse">{{ copyLabel }}</button>
        </div>
        <pre v-if="errorText" class="output-area error-state">{{ errorText }}</pre>
        <pre v-else class="output-area">{{ formattedOutput }}</pre>
      </div>

      <!-- Paneel 3: Live Schema Introspection Explorer -->
      <aside v-if="showSchema" class="gql-pane schema-column">
        <div class="sub-header">
          <span>Schema Introspectie</span>
          <button class="btn-mini" @click="fetchSchema">↻</button>
        </div>
        <div class="schema-list">
          <div v-for="t in schemaTypes" :key="t.name" class="schema-type-card">
            <div class="type-title">{{ t.name }}</div>
            <div v-for="f in t.fields" :key="f.name" class="field-item">
              <code class="field-sig">{{ f.name }}: <span class="type-ref">{{ f.type?.name || 'Scalar' }}</span></code>
              <p v-if="f.description" class="field-desc">{{ f.description }}</p>
            </div>
          </div>
        </div>
      </aside>
    </div>
  </section>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';

const emit = defineEmits(['records-updated', 'shoelace-calculated']);

const ENDPOINT = '/graphql';
const connected = ref(false);
const busy = ref(false);
const latencyMs = ref(null);
const statusLabel = ref('Verbinden met /graphql...');
const errorText = ref('');
const responseData = ref({});
const showSchema = ref(false);
const varsOpen = ref(true);
const copyLabel = ref('Kopieer');
const schemaTypes = ref([]);

const PRESETS = {
  archief: {
    query: `query LodijkeArchief {
  status
  records {
    id
    titel
    datering
    locatie
    rdX
    rdY
    oppervlakteM2
  }
}`,
    vars: `{}`
  },
  shoelace: {
    query: `query PlanimeterBerekening($coords: [[Float!]!]!) {
  status
  shoelaceOppervlakte(coords: $coords)
}`,
    vars: JSON.stringify({
      coords: [
        [68450.0, 387210.0],
        [68580.0, 387210.0],
        [68580.0, 387340.0],
        [68450.0, 387340.0]
      ]
    }, null, 2)
  },
  mutatie: {
    query: `mutation NieuwArchiefstuk($id: String!, $titel: String!, $datering: String!, $locatie: String!, $rdX: Float!, $rdY: Float!, $oppervlakteM2: Float!) {
  addRecord(
    id: $id
    titel: $titel
    datering: $datering
    locatie: $locatie
    rdX: $rdX
    rdY: $rdY
    oppervlakteM2: $oppervlakteM2
  ) {
    id
    titel
    datering
    locatie
    rdX
    rdY
    oppervlakteM2
  }
}`,
    vars: JSON.stringify({
      id: "LOD-1532-04",
      titel: "Dijkgraafrekening Oosterschelde",
      datering: "1532-04-12",
      locatie: "Lodijke",
      rdX: 68910.0,
      rdY: 387105.0,
      oppervlakteM2: 18450.0
    }, null, 2)
  }
};

const queryInput = ref(PRESETS.archief.query);
const variablesInput = ref(PRESETS.archief.vars);

const formattedOutput = computed(() => JSON.stringify(responseData.value, null, 2));

function applyPreset(name) {
  const p = PRESETS[name];
  if (!p) return;
  queryInput.value = p.query;
  variablesInput.value = p.vars;
  runGraphQL();
}

function prettifyQuery() {
  queryInput.value = queryInput.value
    .replace(/\s+\n/g, '\n')
    .trim();
}

async function copyResponse() {
  try {
    await navigator.clipboard.writeText(formattedOutput.value);
    copyLabel.value = '✓ Gekopieerd';
    setTimeout(() => { copyLabel.value = 'Kopieer'; }, 1500);
  } catch (_) {}
}

async function runGraphQL() {
  busy.value = true;
  errorText.value = '';
  const t0 = performance.now();

  let parsedVars = {};
  if (variablesInput.value.trim()) {
    try {
      parsedVars = JSON.parse(variablesInput.value);
    } catch (e) {
      busy.value = false;
      errorText.value = `Ongeldige JSON in Query Variables:\n${e.message}`;
      return;
    }
  }

  try {
    const res = await fetch(ENDPOINT, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify({
        query: queryInput.value,
        variables: parsedVars
      })
    });

    latencyMs.value = Math.round(performance.now() - t0);

    if (!res.ok) {
      throw new Error(`HTTP ${res.status} (${res.statusText})`);
    }

    const payload = await res.json();
    responseData.value = payload;
    connected.value = !payload.errors;

    if (payload.data?.status) {
      statusLabel.value = payload.data.status;
    } else {
      statusLabel.value = `GraphQL Verbonden (${window.location.host})`;
    }

    if (payload.data?.records) {
      emit('records-updated', payload.data.records);
    }
    if (typeof payload.data?.shoelaceOppervlakte === 'number') {
      emit('shoelace-calculated', payload.data.shoelaceOppervlakte);
    }
  } catch (err) {
    connected.value = false;
    statusLabel.value = 'GraphQL Offline';
    errorText.value = `Kan geen verbinding maken met ${ENDPOINT}:\n${err.message}`;
  } finally {
    busy.value = false;
  }
}

async function fetchSchema() {
  try {
    const res = await fetch(ENDPOINT, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        query: `query IntrospectionQuery { __schema { types { name kind fields { name description type { name } } } } }`
      })
    });
    const json = await res.json();
    const rawTypes = json?.data?.__schema?.types || [];
    schemaTypes.value = rawTypes.filter(
      t => t.fields && t.fields.length > 0 && !t.name.startsWith('__')
    );
  } catch (_) {}
}

function toggleSchema() {
  showSchema.value = !showSchema.value;
  if (showSchema.value && schemaTypes.value.length === 0) {
    fetchSchema();
  }
}

onMounted(() => {
  runGraphQL();
  fetchSchema();
});
</script>

<style scoped>
.gql-viewport {
  display: flex;
  flex-direction: column;
  height: 100%;
  width: 100%;
  background: #090d16;
  color: #e2e8f0;
  overflow: hidden;
}

.gql-toolbar {
  display: flex;
  flex-wrap: wrap;
  justify-content: space-between;
  align-items: center;
  gap: 0.5rem;
  padding: 0.6rem 0.9rem;
  background: #111827;
  border-bottom: 1px solid #1f2937;
}

.gql-status {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.82rem;
  color: #f87171;
}
.gql-status.ok {
  color: #34d399;
}
.pulse-dot {
  width: 9px;
  height: 9px;
  border-radius: 50%;
  background: currentColor;
  box-shadow: 0 0 8px currentColor;
}
.latency-pill {
  background: #1e293b;
  color: #94a3b8;
  padding: 0.1rem 0.45rem;
  border-radius: 999px;
  font-size: 0.72rem;
}

.gql-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.4rem;
}

.btn-preset, .btn-run {
  min-height: 38px;
  padding: 0.35rem 0.7rem;
  border-radius: 6px;
  font-size: 0.8rem;
  font-weight: 600;
  cursor: pointer;
  border: 1px solid #334155;
  background: #1e293b;
  color: #f1f5f9;
  touch-action: manipulation;
}
.btn-preset.active {
  background: #0369a1;
  border-color: #38bdf8;
}
.btn-run {
  background: #059669;
  border-color: #10b981;
  color: #ffffff;
}
.btn-run:disabled {
  opacity: 0.6;
}

.gql-workbench {
  display: grid;
  grid-template-columns: 1fr 1fr;
  flex: 1;
  min-height: 0;
  overflow: hidden;
}
.gql-workbench.with-schema {
  grid-template-columns: 1.1fr 1.1fr 0.8fr;
}

.gql-pane {
  display: flex;
  flex-direction: column;
  min-height: 0;
  border-right: 1px solid #1f2937;
  overflow: hidden;
}

.sub-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.45rem 0.75rem;
  background: #0f172a;
  border-bottom: 1px solid #1e293b;
  font-size: 0.75rem;
  font-weight: 600;
  color: #94a3b8;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}
.vars-header {
  border-top: 1px solid #1e293b;
  cursor: pointer;
}

.btn-mini {
  background: #1e293b;
  color: #cbd5e1;
  border: 1px solid #334155;
  border-radius: 4px;
  padding: 0.15rem 0.5rem;
  font-size: 0.72rem;
  cursor: pointer;
}

.code-area {
  width: 100%;
  background: #030712;
  color: #38bdf8;
  border: none;
  padding: 0.75rem;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  font-size: 16px; /* 16px voorkomt automatisch inzoomen op iOS/Android */
  line-height: 1.45;
  resize: none;
  outline: none;
}
.query-area {
  flex: 1;
  min-height: 140px;
}
.vars-area {
  height: 120px;
  color: #eab308;
}

.output-area {
  flex: 1;
  margin: 0;
  padding: 0.75rem;
  background: #030712;
  color: #a7f3d0;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  font-size: 0.85rem;
  line-height: 1.45;
  overflow: auto;
}
.error-state {
  color: #fca5a5;
}

.schema-list {
  flex: 1;
  overflow-y: auto;
  padding: 0.75rem;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}
.schema-type-card {
  background: #111827;
  border: 1px solid #1f2937;
  border-radius: 6px;
  padding: 0.6rem;
}
.type-title {
  color: #f472b6;
  font-weight: 700;
  font-size: 0.85rem;
  margin-bottom: 0.4rem;
}
.field-item {
  padding: 0.35rem 0;
  border-top: 1px solid #1f2937;
}
.field-sig {
  font-size: 0.78rem;
  color: #38bdf8;
}
.type-ref {
  color: #fbbf24;
}
.field-desc {
  margin: 0.2rem 0 0;
  font-size: 0.74rem;
  color: #94a3b8;
}

/* Mobile-First & Tablet Responsiveness */
@media (max-width: 960px) {
  .gql-workbench,
  .gql-workbench.with-schema {
    grid-template-columns: 1fr;
    overflow-y: auto;
  }
  .gql-pane {
    border-right: none;
    border-bottom: 1px solid #1f2937;
    min-height: 260px;
  }
}
</style>
