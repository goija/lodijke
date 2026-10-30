<template>
  <div class="gql-ide-module">
    <div class="gql-ide-topbar">
      <div class="status-pill" :class="{ online: isOnline }">
        <span class="dot"></span>
        <span>{{ statusText }}</span>
        <small v-if="latency !== null">({{ latency }} ms)</small>
      </div>

      <div class="preset-group">
        <button class="btn-gql" @click="loadPreset('typename')">⚡ Ping API</button>
        <button class="btn-gql" @click="loadPreset('cms')">📜 CMS Records</button>
        <button class="btn-gql" @click="loadPreset('parcels')">📍 GeoJSON Percelen</button>
        <button class="btn-gql" @click="loadPreset('schema')">📚 Introspectie</button>
        <button class="btn-gql run" @click="executeGraphQL" :disabled="loading">
          {{ loading ? 'Bezig...' : '▶ Run Query' }}
        </button>
      </div>
    </div>

    <div class="gql-ide-split">
      <!-- Query & Variables Pane -->
      <div class="gql-pane">
        <div class="pane-label">
          <span>GRAPHQL QUERY EDITOR (POST <code>/api/graphql</code>)</span>
          <span class="shortcut-hint">Ctrl + Enter</span>
        </div>
        <textarea
          v-model="query"
          class="gql-textarea query-box"
          spellcheck="false"
          @keydown.ctrl.enter.prevent="executeGraphQL"
          @keydown.meta.enter.prevent="executeGraphQL"
        ></textarea>

        <div class="pane-label vars-label">
          <span>VARIABLES (JSON)</span>
        </div>
        <textarea
          v-model="variables"
          class="gql-textarea vars-box"
          spellcheck="false"
        ></textarea>
      </div>

      <!-- JSON Output Pane -->
      <div class="gql-pane">
        <div class="pane-label">
          <span>GRAPHQL RESPONSE (AXUM :8082 / VERCEL)</span>
          <button class="btn-copy" @click="copyOutput">{{ copyText }}</button>
        </div>
        <pre v-if="errorMsg" class="gql-output error">{{ errorMsg }}</pre>
        <pre v-else class="gql-output">{{ formattedResponse }}</pre>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';

const isOnline = ref(false);
const loading = ref(false);
const latency = ref(null);
const statusText = ref('Verbinden met /api/graphql...');
const errorMsg = ref('');
const responseData = ref({});
const copyText = ref('Kopieer JSON');

const PRESETS = {
  typename: {
    query: `query PingAxumEngine {\n  __typename\n}`,
    vars: `{}`
  },
  cms: {
    query: `query HaalCmsRecordsOp {\n  __typename\n  cmsRecords {\n    id\n    titel\n    categorie\n    datum\n  }\n}`,
    vars: `{}`
  },
  parcels: {
    query: `query HaalGeoParcelsOp {\n  __typename\n  geojsonParcels {\n    id\n    naam\n    oppervlakteM2\n  }\n}`,
    vars: `{}`
  },
  schema: {
    query: `query SchemaOverzicht {\n  __schema {\n    queryType { name }\n    mutationType { name }\n    types {\n      name\n      kind\n      fields {\n        name\n        description\n      }\n    }\n  }\n}`,
    vars: `{}`
  }
};

const query = ref(PRESETS.schema.query);
const variables = ref(PRESETS.schema.vars);

const formattedResponse = computed(() => JSON.stringify(responseData.value, null, 2));

function loadPreset(key) {
  if (!PRESETS[key]) return;
  query.value = PRESETS[key].query;
  variables.value = PRESETS[key].vars;
  executeGraphQL();
}

async function copyOutput() {
  try {
    await navigator.clipboard.writeText(formattedResponse.value);
    copyText.value = '✓ Gekopieerd';
    setTimeout(() => { copyText.value = 'Kopieer JSON'; }, 1500);
  } catch (_) {}
}

async function executeGraphQL() {
  loading.value = true;
  errorMsg.value = '';
  const start = performance.now();

  let parsedVars = {};
  if (variables.value.trim()) {
    try {
      parsedVars = JSON.parse(variables.value);
    } catch (e) {
      loading.value = false;
      errorMsg.value = `JSON syntaxfout in Variables:\n${e.message}`;
      return;
    }
  }

  try {
    const res = await fetch('/api/graphql', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify({
        query: query.value,
        variables: parsedVars
      })
    });

    latency.value = Math.round(performance.now() - start);

    if (!res.ok) {
      throw new Error(`HTTP ${res.status}: ${res.statusText}`);
    }

    const json = await res.json();
    responseData.value = json;
    isOnline.value = !json.errors;
    statusText.value = isOnline.value
      ? 'Axum GraphQL Engine Online'
      : 'GraphQL Waarschuwing (zie output)';
  } catch (err) {
    isOnline.value = false;
    statusText.value = 'GraphQL API Offline';
    errorMsg.value = `Kan /api/graphql niet bereiken:\n${err.message}\n\nControleer of Axum draait op poort 8082.`;
  } finally {
    loading.value = false;
  }
}

onMounted(() => {
  executeGraphQL();
});
</script>

<style scoped>
.gql-ide-module {
  display: flex;
  flex-direction: column;
  height: 100%;
  width: 100%;
  background: #ffffff;
  color: #1e293b;
}
.gql-ide-topbar {
  display: flex;
  flex-wrap: wrap;
  justify-content: space-between;
  align-items: center;
  gap: 0.5rem;
  padding: 0.6rem 0.85rem;
  background: #fff5f5;
  border-bottom: 1px solid #fed7d7;
}
.status-pill {
  display: flex;
  align-items: center;
  gap: 0.45rem;
  font-size: 0.8rem;
  font-weight: 700;
  color: #c53030;
}
.status-pill.online {
  color: #2f855a;
}
.status-pill .dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: currentColor;
}
.preset-group {
  display: flex;
  flex-wrap: wrap;
  gap: 0.35rem;
}
.btn-gql {
  background: #ffffff;
  color: #801b1b;
  border: 1px solid #feb2b2;
  padding: 0.35rem 0.65rem;
  border-radius: 6px;
  font-size: 0.78rem;
  font-weight: 700;
  cursor: pointer;
  min-height: 34px;
}
.btn-gql:hover {
  background: #fff5f5;
}
.btn-gql.run {
  background: #a31c1c;
  color: #ffffff;
  border-color: #a31c1c;
}
.gql-ide-split {
  flex: 1;
  display: grid;
  grid-template-columns: 1fr 1fr;
  min-height: 0;
  overflow: hidden;
}
.gql-pane {
  display: flex;
  flex-direction: column;
  min-height: 0;
  border-right: 1px solid #e2e8f0;
}
.pane-label {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.4rem 0.75rem;
  background: #f8fafc;
  border-bottom: 1px solid #e2e8f0;
  font-size: 0.7rem;
  font-weight: 800;
  color: #64748b;
}
.vars-label {
  border-top: 1px solid #e2e8f0;
}
.shortcut-hint {
  font-size: 0.68rem;
  color: #94a3b8;
}
.btn-copy {
  background: #ffffff;
  border: 1px solid #cbd5e1;
  border-radius: 4px;
  padding: 0.15rem 0.45rem;
  font-size: 0.68rem;
  font-weight: 700;
  cursor: pointer;
}
.gql-textarea {
  width: 100%;
  border: none;
  padding: 0.75rem;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  font-size: 15px;
  line-height: 1.45;
  resize: none;
  outline: none;
  background: #0f172a;
  color: #f8fafc;
}
.query-box {
  flex: 1;
  min-height: 140px;
}
.vars-box {
  height: 95px;
  background: #1e293b;
  color: #fde047;
}
.gql-output {
  flex: 1;
  margin: 0;
  padding: 0.75rem;
  background: #090d16;
  color: #86efac;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  font-size: 0.82rem;
  line-height: 1.45;
  overflow: auto;
}
.gql-output.error {
  color: #fca5a5;
}

@media (max-width: 860px) {
  .gql-ide-split {
    grid-template-columns: 1fr;
    overflow-y: auto;
  }
  .gql-pane {
    min-height: 240px;
    border-right: none;
    border-bottom: 1px solid #e2e8f0;
  }
}
</style>
