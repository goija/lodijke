<template>
  <div class="lodijke-interface" :class="{ 'sidebar-collapsed': sidebarCollapsed }">
    
    <!-- 1. MENU PANEL (Sidebar Navigation Index) -->
    <aside class="menu-panel">
      <div class="brand-header">
        <div class="logo-icon">🏛️</div>
        <div class="brand-text" v-if="!sidebarCollapsed">
          <h2>Lodijke Platform</h2>
          <span class="version-tag">{{ latestCommitBadge }}</span>
        </div>
        <button class="btn-toggle-sidebar" @click="sidebarCollapsed = !sidebarCollapsed" :title="sidebarCollapsed ? 'Menu uitklappen' : 'Menu inklappen'">
          {{ sidebarCollapsed ? '▶' : '◀' }}
        </button>
      </div>

      <nav class="nav-menu">
        <div class="menu-section-title" v-if="!sidebarCollapsed">PLATFORM MODULES (INDEX)</div>
        
        <button 
          v-for="item in menuItems" 
          :key="item.id"
          :class="['menu-btn', { active: activePrimaryModule === item.id }]"
          @click="selectModule(item.id)"
          :title="item.label"
        >
          <span class="menu-icon">{{ item.icon }}</span>
          <span class="menu-label" v-if="!sidebarCollapsed">{{ item.label }}</span>
          <span class="module-badge" v-if="!sidebarCollapsed && item.code">{{ item.code }}</span>
        </button>
      </nav>

      <!-- VERSIEBEHEER & HTML5 HISTORIE STATUS IN SIDEBAR -->
      <div class="sidebar-status" v-if="!sidebarCollapsed">
        <div class="status-item">
          <span class="dot live"></span>
          <span>Axum Rust API: <code>:8082</code></span>
        </div>
        <div class="status-item">
          <span class="dot live"></span>
          <span>Laatste update: <code>{{ latestCommitDate }}</code></span>
        </div>
        <div class="status-item history-pill" @click="openModuleInViewport('versiebeheer')">
          <span>🕒 Wijzigingen: <strong>{{ latestCommitMsg }}</strong></span>
        </div>
      </div>
    </aside>

    <!-- 2. MAIN WORKSPACE -->
    <main class="workspace-panel">
      <header class="viewport-control-bar">
        <div class="active-module-info">
          <h3>{{ getModuleTitle(activePrimaryModule) }}</h3>
          <span class="breadcrumb">
            Lodijke / {{ getModuleCategory(activePrimaryModule) }} /
            <code>HTML5 State #{{ sessionHistory.length }}</code>
          </span>
        </div>

        <!-- HTML5 HISTORY API NAVIGATIE KNOPPEN -->
        <div class="history-nav-group">
          <button class="btn-hist-nav" @click="triggerBrowserBack" title="Vorige Viewport Status (HTML5 History back)">
            ◀ Vorige
          </button>
          <button class="btn-hist-nav" @click="triggerBrowserForward" title="Volgende Viewport Status (HTML5 History forward)">
            Volgende ▶
          </button>
          <button class="btn-hist-nav badge-btn" @click="openModuleInViewport('versiebeheer')" title="Bekijk alle Git commits en wijzigingsdatums">
            🕒 Changelog ({{ commitCount }})
          </button>
        </div>

        <div class="viewport-layout-selector">
          <span class="selector-label">Layout:</span>
          <button :class="['btn-layout', { active: layoutMode === 'single' }]" @click="setLayout('single')">🔲 Enkel</button>
          <button :class="['btn-layout', { active: layoutMode === 'split-h' }]" @click="setLayout('split-h')">⬛⬛ Split H</button>
          <button :class="['btn-layout', { active: layoutMode === 'split-v' }]" @click="setLayout('split-v')">🔲/🔲 Split V</button>
          <button :class="['btn-layout', { active: layoutMode === 'grid' }]" @click="setLayout('grid')">🔲🔲 Quad Grid</button>
        </div>

        <div class="external-quick-links">
          <button type="button" @click="openModuleInViewport('graphql')" class="btn-quick-link api-btn">
            ⚡ GraphQL Studio
          </button>
          <a href="https://lodijke.vercel.app/" target="_blank" rel="noopener" class="btn-quick-link vercel-btn">
            🌐 Live Vercel
          </a>
        </div>
      </header>

      <!-- 3. DYNAMICALLY DRAGGABLE & SWAPPABLE VIEWPORTS MATRIX -->
      <div :class="['viewports-matrix', `layout-${layoutMode}`]">
        <section 
          v-for="(vp, index) in activeViewports" 
          :key="vp.id"
          :class="['viewport-panel', `vp-${vp.id}`, { 'is-dragover': dragOverVp === vp.id, 'is-dragging': draggedVpId === vp.id }]"
          @dragover.prevent="onDragOver(vp.id)"
          @dragleave="onDragLeave(vp.id)"
          @drop="onDrop(vp.id)"
        >
          <!-- DRAGGABLE HEADER BAR -->
          <div 
            class="vp-header" 
            draggable="true" 
            @dragstart="onDragStart($event, vp.id)"
            @dragend="onDragEnd"
          >
            <span class="drag-handle" title="Versleep deze viewport">⋮⋮</span>
            <span class="vp-tag">VIEWPORT {{ vp.id }}</span>
            
            <select v-model="vp.module" @change="onViewportModuleChange(vp)" class="vp-module-select">
              <option v-for="m in menuItems" :key="m.id" :value="m.id">{{ m.icon }} [{{ m.code }}] {{ m.label }}</option>
            </select>

            <div class="vp-actions">
              <button class="btn-vp-action" @click="swapWithNext(index)" title="Wissel met volgende viewport">⇄ Wissel</button>
              <button class="btn-vp-action" @click="maximizeViewport(vp.module)" title="Maximizeer deze module">🔍 Max</button>
            </div>
          </div>

          <!-- VIEWPORT BODY -->
          <div class="vp-body">
            <component
              :is="getComponent(vp.module)"
              :session-history="sessionHistory"
              @restore-state="restoreFromHistoryEntry"
            />
          </div>
        </section>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue';

import Tab00Home from './Tab00Home.vue';
import Tab01Genealogie from './Tab01Genealogie.vue';
import Tab04Kaarten from './Tab04Kaarten.vue';
import TabMappenbomen from './TabMappenbomen.vue';
import Tab12PdfModule from './Tab12PdfModule.vue';
import Tab08GraphqlIde from './Tab08GraphqlIde.vue';
import Tab14Versiebeheer from './Tab14Versiebeheer.vue';
import versionData from '../generated_version_history.json';

const sidebarCollapsed = ref(false);
const layoutMode = ref('split-h');

const draggedVpId = ref(null);
const dragOverVp = ref(null);
const isRestoringPopState = ref(false);

const viewports = ref([
  { id: 1, module: 'genealogie' },
  { id: 2, module: 'versiebeheer' },
  { id: 3, module: 'kaarten' },
  { id: 4, module: 'graphql' }
]);

const sessionHistory = ref([]);

const commits = versionData?.commits || [];
const commitCount = computed(() => commits.length);
const latestCommitBadge = computed(() => {
  const c = commits[0];
  return c ? `v6.1 (#${c.shortHash})` : 'v6.1 HTML5 History';
});
const latestCommitDate = computed(() => {
  const c = commits[0];
  return c ? c.date.slice(0, 16) : 'Vandaag';
});
const latestCommitMsg = computed(() => {
  const c = commits[0];
  return c ? c.message : 'Versleepbare Viewports & History API';
});

const activePrimaryModule = computed({
  get: () => viewports.value[0]?.module || 'genealogie',
  set: (val) => { if (viewports.value[0]) viewports.value[0].module = val; }
});

const menuItems = [
  { id: 'home', label: 'Platform Home', icon: '🏛️', code: 'M-00', comp: Tab00Home, category: 'Overzicht' },
  { id: 'genealogie', label: 'GRAMPS Genealogie Core', icon: '🌳', code: 'M-02', comp: Tab01Genealogie, category: 'Stamboom' },
  { id: 'kaarten', label: 'GIS & Leaflet Kaarten', icon: '📍', code: 'M-06', comp: Tab04Kaarten, category: 'Geodata' },
  { id: 'graphql', label: 'GraphQL Studio IDE', icon: '⚡', code: 'M-08', comp: Tab08GraphqlIde, category: 'Axum API' },
  { id: 'mappenbomen', label: 'Master Mappenbomen', icon: '📂', code: 'M-10', comp: TabMappenbomen, category: 'Structuur' },
  { id: 'pdf', label: 'PDF Reader & Editor', icon: '📕', code: 'M-12', comp: Tab12PdfModule, category: 'Documenten' },
  { id: 'versiebeheer', label: 'Versiebeheer & Historie', icon: '🕒', code: 'M-14', comp: Tab14Versiebeheer, category: 'HTML5 History & Git' },
];

const activeViewports = computed(() => {
  if (layoutMode.value === 'single') return viewports.value.slice(0, 1);
  if (layoutMode.value === 'split-h' || layoutMode.value === 'split-v') return viewports.value.slice(0, 2);
  return viewports.value;
});

/**
 * HTML5 History API: Sla elke layout- en viewport-wijziging op met pushState/replaceState
 */
function pushHtml5HistoryState(actionLabel, summaryText, replace = false) {
  if (isRestoringPopState.value) return;

  const vpModules = viewports.value.map(v => v.module);
  const now = new Date();
  const dateFormatted = now.toLocaleString('nl-NL', {
    year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit', second: '2-digit'
  });

  const url = new URL(window.location.href);
  url.searchParams.set('layout', layoutMode.value);
  url.searchParams.set('vp', vpModules.join(','));

  const statePayload = {
    action: actionLabel,
    summary: summaryText,
    layout: layoutMode.value,
    modules: [...vpModules],
    timestamp: now.getTime(),
    dateFormatted,
    url: url.pathname + url.search
  };

  if (replace) {
    window.history.replaceState(statePayload, '', url.toString());
  } else {
    window.history.pushState(statePayload, '', url.toString());
  }

  sessionHistory.value.unshift(statePayload);
}

function handlePopState(event) {
  isRestoringPopState.value = true;
  if (event.state && event.state.modules) {
    layoutMode.value = event.state.layout || 'split-h';
    event.state.modules.forEach((mod, idx) => {
      if (viewports.value[idx]) viewports.value[idx].module = mod;
    });
  } else {
    hydrateFromUrlParams();
  }
  setTimeout(() => { isRestoringPopState.value = false; }, 50);
}

function hydrateFromUrlParams() {
  const params = new URLSearchParams(window.location.search);
  const urlLayout = params.get('layout');
  const urlVp = params.get('vp');

  if (urlLayout && ['single', 'split-h', 'split-v', 'grid'].includes(urlLayout)) {
    layoutMode.value = urlLayout;
  }
  if (urlVp) {
    const parts = urlVp.split(',');
    parts.forEach((mod, idx) => {
      if (viewports.value[idx] && menuItems.some(m => m.id === mod)) {
        viewports.value[idx].module = mod;
      }
    });
  }
}

function restoreFromHistoryEntry(entry) {
  if (!entry || !entry.modules) return;
  layoutMode.value = entry.layout;
  entry.modules.forEach((mod, idx) => {
    if (viewports.value[idx]) viewports.value[idx].module = mod;
  });
  pushHtml5HistoryState('HERSTEL', `Teruggezet naar status van ${entry.dateFormatted}`);
}

function triggerBrowserBack() { window.history.back(); }
function triggerBrowserForward() { window.history.forward(); }

function setLayout(mode) {
  layoutMode.value = mode;
  pushHtml5HistoryState('LAYOUT', `Layout gewijzigd naar ${mode.toUpperCase()}`);
}

function selectModule(id) {
  if (viewports.value[0]) {
    viewports.value[0].module = id;
    pushHtml5HistoryState('MODULE', `Viewport 1 gezet op ${getModuleTitle(id)}`);
  }
}

function openModuleInViewport(id) {
  if (layoutMode.value === 'single') {
    viewports.value[0].module = id;
  } else {
    viewports.value[1].module = id;
  }
  pushHtml5HistoryState('QUICK-OPEN', `Module ${getModuleTitle(id)} geopend in actieve viewport`);
}

function onViewportModuleChange(vp) {
  pushHtml5HistoryState('VIEWPORT', `Viewport ${vp.id} gewisseld naar ${getModuleTitle(vp.module)}`);
}

function getComponent(id) { const item = menuItems.find(m => m.id === id); return item ? item.comp : Tab00Home; }
function getModuleTitle(id) { const item = menuItems.find(m => m.id === id); return item ? item.label : 'Lodijke Module'; }
function getModuleCategory(id) { const item = menuItems.find(m => m.id === id); return item ? item.category : 'Platform'; }

function swapWithNext(idx) {
  const nextIdx = (idx + 1) % activeViewports.value.length;
  const temp = activeViewports.value[idx].module;
  activeViewports.value[idx].module = activeViewports.value[nextIdx].module;
  activeViewports.value[nextIdx].module = temp;
  pushHtml5HistoryState('SWAP', `Viewport ${idx + 1} gewisseld met Viewport ${nextIdx + 1}`);
}

function maximizeViewport(modId) {
  if (viewports.value[0]) viewports.value[0].module = modId;
  layoutMode.value = 'single';
  pushHtml5HistoryState('MAXIMIZE', `${getModuleTitle(modId)} gemaximaliseerd`);
}

function onDragStart(event, vpId) {
  draggedVpId.value = vpId;
  if (event.dataTransfer) {
    event.dataTransfer.effectAllowed = 'move';
    event.dataTransfer.setData('text/plain', String(vpId));
  }
}

function onDragOver(vpId) {
  if (draggedVpId.value && draggedVpId.value !== vpId) {
    dragOverVp.value = vpId;
  }
}

function onDragLeave(vpId) {
  if (dragOverVp.value === vpId) {
    dragOverVp.value = null;
  }
}

function onDrop(targetVpId) {
  const sourceVpId = draggedVpId.value;
  dragOverVp.value = null;
  draggedVpId.value = null;

  if (sourceVpId && targetVpId && sourceVpId !== targetVpId) {
    const srcVp = viewports.value.find(v => v.id === sourceVpId);
    const targetVp = viewports.value.find(v => v.id === targetVpId);
    if (srcVp && targetVp) {
      const tempModule = srcVp.module;
      srcVp.module = targetVp.module;
      targetVp.module = tempModule;
      pushHtml5HistoryState('DRAG-DROP', `Viewport ${sourceVpId} versleept naar Viewport ${targetVpId}`);
    }
  }
}

function onDragEnd() {
  draggedVpId.value = null;
  dragOverVp.value = null;
}

onMounted(() => {
  hydrateFromUrlParams();
  pushHtml5HistoryState('INIT', 'Startconfiguratie geladen via HTML5 History API', true);
  window.addEventListener('popstate', handlePopState);
});

onBeforeUnmount(() => {
  window.removeEventListener('popstate', handlePopState);
});
</script>

<style scoped>
.lodijke-interface { display: flex; height: 100dvh; width: 100vw; background: #f8fafc; color: #1e293b; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; overflow: hidden; }
.menu-panel { width: 260px; background: #ffffff; border-right: 1px solid #e2e8f0; display: flex; flex-direction: column; flex-shrink: 0; z-index: 10; transition: width 0.2s ease; box-shadow: 2px 0 8px rgba(0, 0, 0, 0.03); }
.sidebar-collapsed .menu-panel { width: 64px; }
.brand-header { padding: 1.1rem 1rem; display: flex; align-items: center; gap: 0.75rem; border-bottom: 2px solid #a31c1c; background: #fff5f5; }
.logo-icon { font-size: 1.5rem; }
.brand-text { flex: 1; overflow: hidden; }
.brand-text h2 { margin: 0; font-size: 1.1rem; color: #a31c1c; font-weight: 800; letter-spacing: -0.02em; }
.version-tag { font-size: 0.7rem; color: #718096; font-weight: 700; }
.btn-toggle-sidebar { background: #ffffff; color: #a31c1c; border: 1px solid #fed7d7; padding: 0.35rem 0.6rem; border-radius: 6px; cursor: pointer; font-weight: bold; transition: all 0.2s; }
.btn-toggle-sidebar:hover { background: #a31c1c; color: #ffffff; }
.nav-menu { flex: 1; padding: 0.85rem 0.65rem; overflow-y: auto; }
.menu-section-title { font-size: 0.68rem; font-weight: 800; color: #a31c1c; margin: 0.6rem 0.5rem 0.35rem; letter-spacing: 0.05em; text-transform: uppercase; }
.menu-btn { width: 100%; display: flex; align-items: center; gap: 0.75rem; background: transparent; border: 1px solid transparent; color: #334155; padding: 0.7rem 0.85rem; border-radius: 8px; cursor: pointer; font-size: 0.9rem; font-weight: 600; margin-bottom: 0.3rem; transition: all 0.15s ease; }
.menu-btn:hover { background: #fff5f5; color: #a31c1c; border-color: #feb2b2; }
.menu-btn.active { background: #a31c1c; color: #ffffff; font-weight: 700; box-shadow: 0 2px 6px rgba(163, 28, 28, 0.25); }
.menu-btn.active .module-badge { background: rgba(255, 255, 255, 0.25); color: #ffffff; }
.menu-icon { font-size: 1.15rem; }
.menu-label { flex: 1; text-align: left; }
.module-badge { font-size: 0.65rem; background: #edf2f7; color: #4a5568; padding: 0.15rem 0.4rem; border-radius: 4px; font-weight: 700; }
.sidebar-status { padding: 0.85rem; border-top: 1px solid #e2e8f0; font-size: 0.75rem; background: #faf5f5; }
.status-item { display: flex; align-items: center; gap: 0.5rem; color: #4a5568; font-weight: 600; margin-bottom: 0.3rem; }
.history-pill { cursor: pointer; color: #a31c1c; background: #fff5f5; border: 1px solid #feb2b2; padding: 0.3rem 0.5rem; border-radius: 6px; margin-top: 0.35rem; }
.dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
.dot.live { background: #38a169; }
.workspace-panel { flex: 1; display: flex; flex-direction: column; min-width: 0; height: 100dvh; background: #f8fafc; }
.viewport-control-bar { background: #ffffff; padding: 0.65rem 1.1rem; border-bottom: 1px solid #e2e8f0; display: flex; justify-content: space-between; align-items: center; box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02); flex-wrap: wrap; gap: 0.5rem; }
.active-module-info h3 { margin: 0; color: #a31c1c; font-size: 1.1rem; font-weight: 800; }
.breadcrumb { font-size: 0.75rem; color: #64748b; font-weight: 500; }
.history-nav-group { display: flex; align-items: center; gap: 0.35rem; }
.btn-hist-nav { background: #fff5f5; color: #a31c1c; border: 1px solid #feb2b2; padding: 0.35rem 0.65rem; border-radius: 6px; font-size: 0.76rem; font-weight: 700; cursor: pointer; }
.btn-hist-nav:hover { background: #a31c1c; color: #ffffff; }
.btn-hist-nav.badge-btn { background: #fefcbf; color: #975a16; border-color: #f6e05e; }
.viewport-layout-selector { display: flex; align-items: center; gap: 0.35rem; background: #f1f5f9; padding: 0.25rem 0.5rem; border-radius: 8px; border: 1px solid #e2e8f0; }
.selector-label { font-size: 0.75rem; color: #64748b; font-weight: 700; }
.btn-layout { background: transparent; border: none; color: #475569; padding: 0.35rem 0.6rem; border-radius: 6px; font-size: 0.78rem; font-weight: 700; cursor: pointer; transition: all 0.15s; }
.btn-layout:hover { background: #e2e8f0; }
.btn-layout.active { background: #a31c1c; color: #ffffff; }
.external-quick-links { display: flex; gap: 0.45rem; }
.btn-quick-link { padding: 0.4rem 0.75rem; border-radius: 6px; border: none; text-decoration: none; font-size: 0.78rem; font-weight: 700; cursor: pointer; transition: transform 0.15s; }
.btn-quick-link:hover { transform: translateY(-1px); }
.api-btn { background: #a31c1c; color: #ffffff; }
.vercel-btn { background: #2b6cb0; color: #ffffff; }
.viewports-matrix { flex: 1; display: grid; gap: 8px; background: #e2e8f0; padding: 8px; overflow: hidden; min-height: 0; }
.layout-single { grid-template-columns: 1fr; grid-template-rows: 1fr; }
.layout-split-h { grid-template-columns: 1fr 1fr; grid-template-rows: 1fr; }
.layout-split-v { grid-template-columns: 1fr; grid-template-rows: 1fr 1fr; }
.layout-grid { grid-template-columns: 1fr 1fr; grid-template-rows: 1fr 1fr; }
.viewport-panel { background: #ffffff; border-radius: 8px; border: 2px solid #cbd5e1; display: flex; flex-direction: column; min-height: 0; overflow: hidden; box-shadow: 0 2px 4px rgba(0,0,0,0.02); transition: border-color 0.2s, box-shadow 0.2s, transform 0.15s; }
.viewport-panel.is-dragover { border-color: #a31c1c; box-shadow: 0 0 0 4px rgba(163, 28, 28, 0.2); transform: scale(0.995); }
.viewport-panel.is-dragging { opacity: 0.5; border-style: dashed; }
.vp-header { background: #fff5f5; padding: 0.45rem 0.85rem; border-bottom: 1px solid #fed7d7; display: flex; align-items: center; gap: 0.6rem; cursor: grab; user-select: none; }
.vp-header:active { cursor: grabbing; }
.drag-handle { font-size: 1rem; font-weight: 900; color: #a31c1c; cursor: grab; }
.vp-tag { font-size: 0.68rem; font-weight: 800; background: #a31c1c; color: #ffffff; padding: 0.15rem 0.45rem; border-radius: 4px; }
.vp-module-select { background: #ffffff; color: #801b1b; border: 1px solid #feb2b2; padding: 0.25rem 0.5rem; border-radius: 6px; font-size: 0.82rem; font-weight: 700; outline: none; }
.vp-actions { margin-left: auto; display: flex; gap: 0.35rem; }
.btn-vp-action { background: #ffffff; border: 1px solid #fed7d7; color: #a31c1c; font-weight: 700; font-size: 0.72rem; padding: 0.2rem 0.5rem; border-radius: 4px; cursor: pointer; transition: all 0.15s; }
.btn-vp-action:hover { background: #a31c1c; color: #ffffff; }
.vp-body { flex: 1; overflow-y: auto; min-height: 0; background: #ffffff; }

@media (max-width: 900px) {
  .layout-split-h, .layout-grid {
    grid-template-columns: 1fr;
    grid-template-rows: auto;
    overflow-y: auto;
  }
  .viewport-panel { min-height: 350px; }
}
</style>
