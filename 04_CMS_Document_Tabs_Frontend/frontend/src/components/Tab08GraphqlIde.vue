<template>
  <div class="gql-viewport">
    <div class="gql-bar">
      <span class="gql-badge" :class="{ ok: online }">
        ● {{ online ? 'Axum GraphQL :8082 Verbonden' : 'GraphQL Fallback Actief' }}
      </span>
      <div class="gql-btns">
        <button @click="setPreset('typename')">⚡ Ping</button>
        <button @click="setPreset('git')">🕒 Git Log Query</button>
        <button @click="setPreset('schema')">📚 Schema</button>
        <button class="run-btn" @click="runQuery">▶ Run</button>
      </div>
    </div>
    <div class="gql-grid">
      <textarea v-model="query" class="gql-in" spellcheck="false"></textarea>
      <pre class="gql-out">{{ output }}</pre>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';

const online = ref(false);
const query = ref(`query LodijkeStatus {\n  __typename\n}`);
const output = ref('// Klik op Run om de GraphQL query uit te voeren...');

const PRESETS = {
  typename: `query PingAxum {\n  __typename\n}`,
  git: `query VersiebeheerLog {\n  __typename\n}`,
  schema: `query Introspectie {\n  __schema {\n    queryType { name }\n    types { name kind }\n  }\n}`
};

function setPreset(k) {
  query.value = PRESETS[k];
  runQuery();
}

async function runQuery() {
  try {
    const res = await fetch('/api/graphql', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ query: query.value })
    });
    const json = await res.json();
    online.value = res.ok && !json.errors;
    output.value = JSON.stringify(json, null, 2);
  } catch (e) {
    online.value = false;
    output.value = JSON.stringify({ error: e.message, endpoint: '/api/graphql' }, null, 2);
  }
}

onMounted(runQuery);
</script>

<style scoped>
.gql-viewport { display: flex; flex-direction: column; height: 100%; background: #fff; }
.gql-bar { display: flex; justify-content: space-between; align-items: center; padding: 0.45rem 0.75rem; background: #fff5f5; border-bottom: 1px solid #fed7d7; flex-wrap: wrap; gap: 0.4rem; }
.gql-badge { font-size: 0.76rem; font-weight: 800; color: #c53030; }
.gql-badge.ok { color: #2f855a; }
.gql-btns { display: flex; gap: 0.35rem; }
.gql-btns button { background: #fff; color: #a31c1c; border: 1px solid #feb2b2; border-radius: 4px; padding: 0.25rem 0.55rem; font-size: 0.75rem; font-weight: 700; cursor: pointer; }
.gql-btns .run-btn { background: #a31c1c; color: #fff; border-color: #a31c1c; }
.gql-grid { flex: 1; display: grid; grid-template-columns: 1fr 1fr; min-height: 0; }
.gql-in { background: #0f172a; color: #38bdf8; border: none; padding: 0.75rem; font-family: monospace; font-size: 0.85rem; resize: none; outline: none; }
.gql-out { margin: 0; background: #090d16; color: #86efac; padding: 0.75rem; font-family: monospace; font-size: 0.8rem; overflow: auto; }
@media (max-width: 800px) { .gql-grid { grid-template-columns: 1fr; } }
</style>
