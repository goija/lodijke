<template>
  <div class="lodijke-interface" :class="{ 'sidebar-collapsed': sidebarCollapsed }">
    
    <!-- 1. MENU PANEL (Sidebar Navigation Index) -->
    <aside class="menu-panel">
      <div class="brand-header">
        <div class="logo-icon">🏛️</div>
        <div class="brand-text" v-if="!sidebarCollapsed">
          <h2>Lodijke Platform</h2>
          <span class="version-tag">v3.0 Master Core</span>
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

      <div class="sidebar-status" v-if="!sidebarCollapsed">
        <div class="status-item">
          <span class="dot live"></span>
          <span>Axum Rust API: <code>:8082</code></span>
        </div>
        <div class="status-item">
          <span class="dot live"></span>
          <span>Solid POD Vault: <code>Active</code></span>
        </div>
      </div>
    </aside>

    <!-- 2. MAIN WORKSPACE -->
    <main class="workspace-panel">
      <header class="viewport-control-bar">
        <div class="active-module-info">
          <h3>{{ getModuleTitle(activePrimaryModule) }}</h3>
          <span class="breadcrumb">Lodijke / {{ getModuleCategory(activePrimaryModule) }}</span>
        </div>

        <div class="viewport-layout-selector">
          <span class="selector-label">Layout:</span>
          <button :class="['btn-layout', { active: layoutMode === 'single' }]" @click="layoutMode = 'single'">🔲 Enkel</button>
          <button :class="['btn-layout', { active: layoutMode === 'split-h' }]" @click="layoutMode = 'split-h'">⬛⬛ Split H</button>
          <button :class="['btn-layout', { active: layoutMode === 'split-v' }]" @click="layoutMode = 'split-v'">🔲/🔲 Split V</button>
          <button :class="['btn-layout', { active: layoutMode === 'grid' }]" @click="layoutMode = 'grid'">🔲🔲 Quad</button>
        </div>

        <div class="external-quick-links">
          <a href="http://127.0.0.1:8082" target="_blank" class="btn-quick-link api-btn">⚡ GraphQL Studio</a>
          <a href="https://lodijke.vercel.app/" target="_blank" class="btn-quick-link vercel-btn">🌐 Live Vercel</a>
        </div>
      </header>

      <!-- 3. CONTENT PANELS / VIEWPORT MATRIX -->
      <div :class="['viewports-matrix', `layout-${layoutMode}`]">
        
        <!-- VIEWPORT 1 -->
        <section class="viewport-panel vp-1">
          <div class="vp-header">
            <span class="vp-tag">VIEWPORT 1</span>
            <select v-model="activePrimaryModule" class="vp-module-select">
              <option v-for="m in menuItems" :key="m.id" :value="m.id">{{ m.icon }} [{{ m.code }}] {{ m.label }}</option>
            </select>
          </div>
          <div class="vp-body">
            <component :is="getComponent(activePrimaryModule)" />
          </div>
        </section>

        <!-- VIEWPORT 2 -->
        <section class="viewport-panel vp-2" v-if="layoutMode !== 'single'">
          <div class="vp-header">
            <span class="vp-tag">VIEWPORT 2</span>
            <select v-model="activeSecondaryModule" class="vp-module-select">
              <option v-for="m in menuItems" :key="m.id" :value="m.id">{{ m.icon }} [{{ m.code }}] {{ m.label }}</option>
            </select>
          </div>
          <div class="vp-body">
            <component :is="getComponent(activeSecondaryModule)" />
          </div>
        </section>

        <!-- VIEWPORT 3 -->
        <section class="viewport-panel vp-3" v-if="layoutMode === 'grid'">
          <div class="vp-header">
            <span class="vp-tag">VIEWPORT 3</span>
            <select v-model="activeTertiaryModule" class="vp-module-select">
              <option v-for="m in menuItems" :key="m.id" :value="m.id">{{ m.icon }} [{{ m.code }}] {{ m.label }}</option>
            </select>
          </div>
          <div class="vp-body">
            <component :is="getComponent(activeTertiaryModule)" />
          </div>
        </section>

        <!-- VIEWPORT 4 -->
        <section class="viewport-panel vp-4" v-if="layoutMode === 'grid'">
          <div class="vp-header">
            <span class="vp-tag">VIEWPORT 4</span>
            <select v-model="activeQuaternaryModule" class="vp-module-select">
              <option v-for="m in menuItems" :key="m.id" :value="m.id">{{ m.icon }} [{{ m.code }}] {{ m.label }}</option>
            </select>
          </div>
          <div class="vp-body">
            <component :is="getComponent(activeQuaternaryModule)" />
          </div>
        </section>

      </div>
    </main>
  </div>
</template>

<script setup>
import { ref } from 'vue';

import Tab00Home from './Tab00Home.vue';
import Tab01Genealogie from './Tab01Genealogie.vue';
import Tab04Kaarten from './Tab04Kaarten.vue';
import TabMappenbomen from './TabMappenbomen.vue';
import Tab12PdfModule from './Tab12PdfModule.vue';

const sidebarCollapsed = ref(false);
const layoutMode = ref('split-h');

const activePrimaryModule = ref('genealogie');
const activeSecondaryModule = ref('pdf');
const activeTertiaryModule = ref('kaarten');
const activeQuaternaryModule = ref('mappenbomen');

const menuItems = [
  { id: 'home', label: 'Platform Home', icon: '🏛️', code: 'M-00', comp: Tab00Home, category: 'Overzicht' },
  { id: 'genealogie', label: 'GRAMPS Genealogie Core', icon: '🌳', code: 'M-02', comp: Tab01Genealogie, category: 'Stamboom' },
  { id: 'pdf', label: 'PDF Reader & Editor', icon: '📕', code: 'M-12', comp: Tab12PdfModule, category: 'Documenten' },
  { id: 'kaarten', label: 'GIS & Leaflet Kaarten', icon: '📍', code: 'M-06', comp: Tab04Kaarten, category: 'Geodata' },
  { id: 'mappenbomen', label: 'Master Mappenbomen', icon: '📂', code: 'M-10', comp: TabMappenbomen, category: 'Structuur' },
];

function selectModule(id) { activePrimaryModule.value = id; }
function getComponent(id) { const item = menuItems.find(m => m.id === id); return item ? item.comp : Tab00Home; }
function getModuleTitle(id) { const item = menuItems.find(m => m.id === id); return item ? item.label : 'Lodijke Module'; }
function getModuleCategory(id) { const item = menuItems.find(m => m.id === id); return item ? item.category : 'Platform'; }
</script>

<style scoped>
.lodijke-interface { display: flex; height: 100vh; width: 100vw; background: #1e1e2e; color: #cdd6f4; font-family: system-ui, sans-serif; overflow: hidden; }
.menu-panel { width: 260px; background: #181825; border-right: 1px solid #313244; display: flex; flex-direction: column; flex-shrink: 0; z-index: 10; transition: width 0.2s; }
.sidebar-collapsed .menu-panel { width: 64px; }
.brand-header { padding: 1rem; display: flex; align-items: center; gap: 0.75rem; border-bottom: 1px solid #313244; }
.logo-icon { font-size: 1.5rem; }
.brand-text { flex: 1; overflow: hidden; }
.brand-text h2 { margin: 0; font-size: 1.05rem; color: #f38ba8; }
.version-tag { font-size: 0.7rem; color: #a6adc8; }
.btn-toggle-sidebar { background: #313244; color: #cdd6f4; border: none; padding: 0.35rem 0.6rem; border-radius: 6px; cursor: pointer; }

.nav-menu { flex: 1; padding: 0.75rem; overflow-y: auto; }
.menu-section-title { font-size: 0.68rem; font-weight: bold; color: #6c7086; margin: 0.5rem 0.5rem 0.25rem; }
.menu-btn { width: 100%; display: flex; align-items: center; gap: 0.75rem; background: transparent; border: none; color: #bac2de; padding: 0.65rem 0.75rem; border-radius: 8px; cursor: pointer; font-size: 0.9rem; margin-bottom: 0.2rem; }
.menu-btn:hover { background: #313244; }
.menu-btn.active { background: #89b4fa; color: #11111b; font-weight: bold; }
.menu-icon { font-size: 1.1rem; }
.menu-label { flex: 1; text-align: left; }
.module-badge { font-size: 0.65rem; background: rgba(0,0,0,0.25); padding: 0.15rem 0.4rem; border-radius: 4px; }

.sidebar-status { padding: 0.85rem; border-top: 1px solid #313244; font-size: 0.75rem; background: #11111b; }
.status-item { display: flex; align-items: center; gap: 0.5rem; color: #a6adc8; margin-bottom: 0.2rem; }
.dot { width: 8px; height: 8px; border-radius: 50%; }
.dot.live { background: #a6e3a1; }

.workspace-panel { flex: 1; display: flex; flex-direction: column; min-width: 0; height: 100vh; }
.viewport-control-bar { background: #181825; padding: 0.75rem 1.25rem; border-bottom: 1px solid #313244; display: flex; justify-content: space-between; align-items: center; }
.active-module-info h3 { margin: 0; color: #89b4fa; font-size: 1.1rem; }
.breadcrumb { font-size: 0.78rem; color: #a6adc8; }

.viewport-layout-selector { display: flex; align-items: center; gap: 0.4rem; background: #11111b; padding: 0.25rem 0.5rem; border-radius: 8px; }
.selector-label { font-size: 0.75rem; color: #6c7086; }
.btn-layout { background: transparent; border: none; color: #a6adc8; padding: 0.35rem 0.65rem; border-radius: 6px; font-size: 0.8rem; font-weight: bold; cursor: pointer; }
.btn-layout.active { background: #313244; color: #a6e3a1; }

.external-quick-links { display: flex; gap: 0.5rem; }
.btn-quick-link { padding: 0.4rem 0.75rem; border-radius: 6px; text-decoration: none; font-size: 0.8rem; font-weight: bold; }
.api-btn { background: #a6e3a1; color: #11111b; }
.vercel-btn { background: #f38ba8; color: #11111b; }

.viewports-matrix { flex: 1; display: grid; gap: 2px; background: #313244; overflow: hidden; min-height: 0; }
.layout-single { grid-template-columns: 1fr; grid-template-rows: 1fr; }
.layout-split-h { grid-template-columns: 1fr 1fr; grid-template-rows: 1fr; }
.layout-split-v { grid-template-columns: 1fr; grid-template-rows: 1fr 1fr; }
.layout-grid { grid-template-columns: 1fr 1fr; grid-template-rows: 1fr 1fr; }

.viewport-panel { background: #1e1e2e; display: flex; flex-direction: column; min-height: 0; overflow: hidden; }
.vp-header { background: #181825; padding: 0.4rem 0.8rem; border-bottom: 1px solid #313244; display: flex; align-items: center; gap: 0.6rem; }
.vp-tag { font-size: 0.68rem; font-weight: bold; background: #313244; color: #f5e0dc; padding: 0.15rem 0.4rem; border-radius: 4px; }
.vp-module-select { background: #1e1e2e; color: #a6e3a1; border: 1px solid #313244; padding: 0.25rem 0.5rem; border-radius: 4px; font-size: 0.82rem; font-weight: bold; outline: none; }
.vp-body { flex: 1; overflow-y: auto; min-height: 0; }
</style>
