<template>
  <div class="lodijke-interface" :class="{ 'sidebar-collapsed': sidebarCollapsed }">
    
    <!-- 1. MENU PANEL (Sidebar Navigation Index) -->
    <aside class="menu-panel">
      <div class="brand-header">
        <div class="logo-icon">🏛️</div>
        <div class="brand-text" v-if="!sidebarCollapsed">
          <h2>Lodijke Platform</h2>
          <span class="version-tag">v3.1 Meekrab Rood & Wit</span>
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
          <span>Thoolse Meekrab Streekthema</span>
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

.lodijke-interface { 
  display: flex; 
  height: 100vh; 
  width: 100vw; 
  background: #f8fafc; 
  color: #1e293b; 
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; 
  overflow: hidden; 
}


.menu-panel { 
  width: 260px; 
  background: #ffffff; 
  border-right: 1px solid #e2e8f0; 
  display: flex; 
  flex-direction: column; 
  flex-shrink: 0; 
  z-index: 10; 
  transition: width 0.2s ease; 
  box-shadow: 2px 0 8px rgba(0, 0, 0, 0.03);
}
.sidebar-collapsed .menu-panel { width: 64px; }

.brand-header { 
  padding: 1.1rem 1rem; 
  display: flex; 
  align-items: center; 
  gap: 0.75rem; 
  border-bottom: 2px solid #a31c1c; 
  background: #fff5f5;
}
.logo-icon { font-size: 1.5rem; }
.brand-text { flex: 1; overflow: hidden; }
.brand-text h2 { margin: 0; font-size: 1.1rem; color: #a31c1c; font-weight: 800; letter-spacing: -0.02em; }
.version-tag { font-size: 0.7rem; color: #718096; font-weight: 600; }
.btn-toggle-sidebar { 
  background: #ffffff; 
  color: #a31c1c; 
  border: 1px solid #fed7d7; 
  padding: 0.35rem 0.6rem; 
  border-radius: 6px; 
  cursor: pointer; 
  font-weight: bold;
  transition: all 0.2s;
}
.btn-toggle-sidebar:hover { background: #a31c1c; color: #ffffff; }

.nav-menu { flex: 1; padding: 0.85rem 0.65rem; overflow-y: auto; }
.menu-section-title { 
  font-size: 0.68rem; 
  font-weight: 800; 
  color: #a31c1c; 
  margin: 0.6rem 0.5rem 0.35rem; 
  letter-spacing: 0.05em;
  text-transform: uppercase;
}

.menu-btn { 
  width: 100%; 
  display: flex; 
  align-items: center; 
  gap: 0.75rem; 
  background: transparent; 
  border: 1px solid transparent; 
  color: #334155; 
  padding: 0.7rem 0.85rem; 
  border-radius: 8px; 
  cursor: pointer; 
  font-size: 0.9rem; 
  font-weight: 600;
  margin-bottom: 0.3rem; 
  transition: all 0.15s ease;
}
.menu-btn:hover { background: #fff5f5; color: #a31c1c; border-color: #feb2b2; }
.menu-btn.active { 
  background: #a31c1c; 
  color: #ffffff; 
  font-weight: 700; 
  box-shadow: 0 2px 6px rgba(163, 28, 28, 0.25);
}
.menu-btn.active .module-badge { background: rgba(255, 255, 255, 0.25); color: #ffffff; }

.menu-icon { font-size: 1.15rem; }
.menu-label { flex: 1; text-align: left; }
.module-badge { font-size: 0.65rem; background: #edf2f7; color: #4a5568; padding: 0.15rem 0.4rem; border-radius: 4px; font-weight: 700; }

.sidebar-status { padding: 0.85rem; border-top: 1px solid #e2e8f0; font-size: 0.75rem; background: #faf5f5; }
.status-item { display: flex; align-items: center; gap: 0.5rem; color: #4a5568; font-weight: 600; margin-bottom: 0.2rem; }
.dot { width: 8px; height: 8px; border-radius: 50%; }
.dot.live { background: #38a169; }


.workspace-panel { flex: 1; display: flex; flex-direction: column; min-width: 0; height: 100vh; background: #f8fafc; }
.viewport-control-bar { 
  background: #ffffff; 
  padding: 0.75rem 1.25rem; 
  border-bottom: 1px solid #e2e8f0; 
  display: flex; 
  justify-content: space-between; 
  align-items: center; 
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02);
}
.active-module-info h3 { margin: 0; color: #a31c1c; font-size: 1.15rem; font-weight: 800; }
.breadcrumb { font-size: 0.78rem; color: #64748b; font-weight: 500; }

.viewport-layout-selector { display: flex; align-items: center; gap: 0.4rem; background: #f1f5f9; padding: 0.25rem 0.5rem; border-radius: 8px; border: 1px solid #e2e8f0; }
.selector-label { font-size: 0.75rem; color: #64748b; font-weight: 700; }
.btn-layout { background: transparent; border: none; color: #475569; padding: 0.35rem 0.65rem; border-radius: 6px; font-size: 0.8rem; font-weight: 700; cursor: pointer; transition: all 0.15s; }
.btn-layout:hover { background: #e2e8f0; }
.btn-layout.active { background: #a31c1c; color: #ffffff; }

.external-quick-links { display: flex; gap: 0.5rem; }
.btn-quick-link { padding: 0.4rem 0.8rem; border-radius: 6px; text-decoration: none; font-size: 0.8rem; font-weight: 700; transition: transform 0.15s; }
.btn-quick-link:hover { transform: translateY(-1px); }
.api-btn { background: #a31c1c; color: #ffffff; }
.vercel-btn { background: #2b6cb0; color: #ffffff; }


.viewports-matrix { flex: 1; display: grid; gap: 6px; background: #e2e8f0; padding: 6px; overflow: hidden; min-height: 0; }
.layout-single { grid-template-columns: 1fr; grid-template-rows: 1fr; }
.layout-split-h { grid-template-columns: 1fr 1fr; grid-template-rows: 1fr; }
.layout-split-v { grid-template-columns: 1fr; grid-template-rows: 1fr 1fr; }
.layout-grid { grid-template-columns: 1fr 1fr; grid-template-rows: 1fr 1fr; }

.viewport-panel { background: #ffffff; border-radius: 8px; border: 1px solid #cbd5e1; display: flex; flex-direction: column; min-height: 0; overflow: hidden; box-shadow: 0 2px 4px rgba(0,0,0,0.02); }
.vp-header { background: #fff5f5; padding: 0.45rem 0.85rem; border-bottom: 1px solid #fed7d7; display: flex; align-items: center; gap: 0.6rem; }
.vp-tag { font-size: 0.68rem; font-weight: 800; background: #a31c1c; color: #ffffff; padding: 0.15rem 0.45rem; border-radius: 4px; }
.vp-module-select { background: #ffffff; color: #801b1b; border: 1px solid #feb2b2; padding: 0.25rem 0.5rem; border-radius: 6px; font-size: 0.82rem; font-weight: 700; outline: none; }
.vp-body { flex: 1; overflow-y: auto; min-height: 0; background: #ffffff; }
</style>
