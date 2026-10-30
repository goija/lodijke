<template>
  <div class="version-module">
    <div class="version-header">
      <div>
        <span class="badge-tag">MODULE M-14 // VERSIEBEHEER & HTML5 HISTORY API</span>
        <h4>Development Changelog & Live Browser Historie</h4>
        <p class="sub-info">
          Laatste synchronisatie: <strong>{{ versionData.buildTimestamp }}</strong> —
          Actieve Release: <strong>{{ versionData.version }}</strong>
        </p>
      </div>
      <div class="tab-toggle">
        <button :class="{ active: activeTab === 'git' }" @click="activeTab = 'git'">
          📦 Git Commits & Wijzigingen ({{ versionData.commits.length }})
        </button>
        <button :class="{ active: activeTab === 'html5' }" @click="activeTab = 'html5'">
          🧭 HTML5 History API Stack ({{ sessionHistory.length }})
        </button>
      </div>
    </div>

    <!-- 1. GIT COMMITS & DATUM VAN WIJZIGINGEN -->
    <div v-if="activeTab === 'git'" class="commit-timeline">
      <article v-for="c in versionData.commits" :key="c.fullHash" class="commit-card">
        <div class="commit-top">
          <span class="commit-hash" :title="c.fullHash">#{{ c.shortHash }}</span>
          <span class="commit-date">📅 {{ formatDatum(c.date) }}</span>
          <span class="commit-author">👤 {{ c.author }}</span>
        </div>
        <div class="commit-msg">{{ c.message }}</div>
        <details v-if="c.changes && c.changes.length" class="commit-files">
          <summary>Gewijzigde bestanden & statistieken ({{ c.changes.length }} regels)</summary>
          <ul>
            <li v-for="(line, i) in c.changes" :key="i"><code>{{ line }}</code></li>
          </ul>
        </details>
      </article>
    </div>

    <!-- 2. HTML5 HISTORY API STATE LOG -->
    <div v-else class="history-stack">
      <div class="history-controls">
        <button class="btn-hist" @click="goBack">◀ Browser Terug (history.back)</button>
        <button class="btn-hist" @click="goForward">Browser Vooruit (history.forward) ▶</button>
      </div>

      <div
        v-for="(entry, idx) in sessionHistory"
        :key="entry.timestamp + '-' + idx"
        class="history-item"
        :class="{ current: idx === 0 }"
        @click="$emit('restore-state', entry)"
      >
        <div class="hist-top">
          <span class="hist-badge">{{ entry.action }}</span>
          <span class="hist-time">🕒 {{ entry.dateFormatted }}</span>
        </div>
        <div class="hist-desc">{{ entry.summary }}</div>
        <div class="hist-url"><code>{{ entry.url }}</code></div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import versionData from '../generated_version_history.json';

defineProps({
  sessionHistory: {
    type: Array,
    default: () => []
  }
});

defineEmits(['restore-state']);

const activeTab = ref('git');

function formatDatum(isoStr) {
  if (!isoStr) return '';
  return isoStr.replace(' +0100', '').replace(' +0200', '');
}

function goBack() {
  window.history.back();
}

function goForward() {
  window.history.forward();
}
</script>

<style scoped>
.version-module {
  padding: 1rem;
  background: #ffffff;
  color: #1e293b;
  height: 100%;
  overflow-y: auto;
}
.version-header {
  display: flex;
  flex-wrap: wrap;
  justify-content: space-between;
  align-items: flex-start;
  gap: 0.75rem;
  padding-bottom: 0.85rem;
  margin-bottom: 1rem;
  border-bottom: 2px solid #fed7d7;
}
.badge-tag {
  font-size: 0.68rem;
  font-weight: 800;
  color: #a31c1c;
  letter-spacing: 0.05em;
}
.version-header h4 {
  margin: 0.2rem 0;
  color: #a31c1c;
  font-size: 1.05rem;
}
.sub-info {
  margin: 0;
  font-size: 0.78rem;
  color: #64748b;
}
.tab-toggle {
  display: flex;
  gap: 0.4rem;
  flex-wrap: wrap;
}
.tab-toggle button {
  background: #fff5f5;
  color: #a31c1c;
  border: 1px solid #feb2b2;
  padding: 0.4rem 0.75rem;
  border-radius: 6px;
  font-size: 0.78rem;
  font-weight: 700;
  cursor: pointer;
}
.tab-toggle button.active {
  background: #a31c1c;
  color: #ffffff;
  border-color: #a31c1c;
}
.commit-timeline, .history-stack {
  display: flex;
  flex-direction: column;
  gap: 0.65rem;
}
.commit-card, .history-item {
  border: 1px solid #e2e8f0;
  border-left: 4px solid #a31c1c;
  border-radius: 6px;
  padding: 0.75rem;
  background: #f8fafc;
}
.history-item {
  cursor: pointer;
  transition: background 0.15s;
}
.history-item:hover {
  background: #fff5f5;
}
.history-item.current {
  border-left-color: #2f855a;
  background: #f0fff4;
}
.commit-top, .hist-top {
  display: flex;
  flex-wrap: wrap;
  gap: 0.6rem;
  align-items: center;
  font-size: 0.75rem;
  color: #475569;
  margin-bottom: 0.35rem;
}
.commit-hash, .hist-badge {
  background: #a31c1c;
  color: #ffffff;
  font-weight: 800;
  padding: 0.1rem 0.45rem;
  border-radius: 4px;
  font-family: monospace;
}
.commit-msg, .hist-desc {
  font-weight: 700;
  font-size: 0.9rem;
  color: #0f172a;
}
.commit-files {
  margin-top: 0.45rem;
  font-size: 0.76rem;
  color: #475569;
}
.commit-files summary {
  cursor: pointer;
  font-weight: 700;
  color: #a31c1c;
}
.commit-files ul {
  margin: 0.35rem 0 0;
  padding-left: 1.1rem;
}
.history-controls {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 0.4rem;
}
.btn-hist {
  background: #ffffff;
  color: #a31c1c;
  border: 1px solid #feb2b2;
  padding: 0.35rem 0.7rem;
  border-radius: 6px;
  font-size: 0.78rem;
  font-weight: 700;
  cursor: pointer;
}
.btn-hist:hover {
  background: #a31c1c;
  color: #ffffff;
}
.hist-url {
  margin-top: 0.25rem;
  font-size: 0.72rem;
  color: #64748b;
}
</style>
