<template>
  <div class="lodijke-interface" :class="{ 'sidebar-collapsed': sidebarCollapsed, 'mobile-menu-open': mobileMenuOpen }">
    
    <!-- Mobiele Achtergrond Overlay -->
    <div class="mobile-backdrop" v-if="mobileMenuOpen" @click="mobileMenuOpen = false"></div>

    <!-- 1. MENU PANEL (Sidebar Navigation Index) -->
    <aside class="menu-panel">
      <div class="brand-header">
        <div class="logo-icon">🏛️</div>
        <div class="brand-text" v-if="!sidebarCollapsed">
          <h2>Lodijke Platform</h2>
          <span class="version-tag">v3.1 Meekrab Rood & Wit</span>
        </div>
        <button class="btn-toggle-sidebar" @click="toggleSidebar" :title="sidebarCollapsed ? 'Menu uitklappen' : 'Menu inklappen'">
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
          <button class="btn-mobile-hamburger" @click="mobileMenuOpen = !mobileMenuOpen" aria-label="Menu">
            ☰
          </button>
          <div>
            <h3>{{ getModuleTitle(activePrimaryModule) }}</h3>
            <span class="breadcrumb">Lodijke / {{ getModuleCategory(activePrimaryModule) }}</span>
          </div>
        </div>

        <div class="viewport-layout-selector">
          <span class="selector-label">Layout:</span>
          <button :class="['btn-layout', { active: layoutMode === 'single' }]" @click="layoutMode = 'single'">🔲 Enkel</button>
          <button :class="['btn-layout', { active: layoutMode === 'split-h' }]" @click="layoutMode = 'split-h'">⬛⬛ Split H</button>
          <button :class="['btn-layout', { active: layoutMode === 'split-v' }]" @click="layoutMode = 'split-v'">🔲/🔲 Split V</button>
          <button :class="['btn-layout', { active: layoutMode === 'grid' }]" @click="layoutMode = 'grid'">🔲🔲 Quad</button>
        </div>

        <div class="external-quick-links">
          <button type="button" @click="openGraphqlInViewport" class="btn-quick-link api-btn">
            ⚡ GraphQL Studio
          </button>
          <a href="https://lodijke.vercel.app/" target="_blank" rel="noopener" class="btn-quick-link vercel-btn">
            🌐 Live Vercel
          </a>
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
import { ref, onMounted } from 'vue';

import Tab00Home from './Tab00Home.vue';
import Tab01Genealogie from './Tab01Genealogie.vue';
import Tab04Kaarten from './Tab04Kaarten.vue';
import TabMappenbomen from './TabMappenbomen.vue';
import Tab12PdfModule from './Tab12PdfModule.vue';
import Tab08GraphqlIde from './Tab08GraphqlIde.vue';

const sidebarCollapsed = ref(false);
const mobileMenuOpen = ref(false);
const layoutMode = ref(window.innerWidth < 900 ? 'single' : 'split-h');

const activePrimaryModule = ref('genealogie');
const activeSecondaryModule = ref('graphql');
const activeTertiaryModule = ref('kaarten');
const activeQuaternaryModule = ref('mappenbomen');

const menuItems = [
  { id: 'home', label: 'Platform Home', icon: '🏛️', code: 'M-00', comp: Tab00Home, category: 'Overzicht' },
  { id: 'genealogie', label: 'GRAMPS Genealogie Core', icon: '🌳', code: 'M-02', comp: Tab01Genealogie, category: 'Stamboom' },
  { id: 'kaarten', label: 'GIS & Leaflet Kaarten', icon: '📍', code: 'M-06', comp: Tab04Kaarten, category: 'Geodata' },
  { id: 'graphql', label: 'GraphQL Studio IDE', icon: '⚡', code: 'M-08', comp: Tab08GraphqlIde, category: 'Axum API' },
  { id: 'mappenbomen', label: 'Master Mappenbomen', icon: '📂', code: 'M-10', comp: TabMappenbomen, category: 'Structuur' },
  { id: 'pdf', label: 'PDF Reader & Editor', icon: '📕', code: 'M-12', comp: Tab12PdfModule, category: 'Documenten' },
];

function selectModule(id) {
  activePrimaryModule.value = id;
  mobileMenuOpen.value = false;
}

function toggleSidebar() {
  if (window.innerWidth < 900) {
    mobileMenuOpen.value = !mobileMenuOpen.value;
  } else {
    sidebarCollapsed.value = !sidebarCollapsed.value;
  }
}

function openGraphqlInViewport() {
  if (layoutMode.value === 'single') {
    activePrimaryModule.value = 'graphql';
  } else {
    activeSecondaryModule.value = 'graphql';
  }
}

function getComponent(id) {
  const item = menuItems.find(m => m.id === id);
  return item ? item.comp : Tab00Home;
}
function getModuleTitle(id) {
  const item = menuItems.find(m => m.id === id);
  return item ? item.label : 'Lodijke Module';
}
function getModuleCategory(id) {
  const item = menuItems.find(m => m.id === id);
  return item ? item.category : 'Platform';
}

onMounted(() => {
  window.addEventListener('resize', () => {
    if (window.innerWidth >= 900) {
      mobileMenuOpen.value = false;
    }
  });
});
</script>

<style scoped>
/* ==========================================================================
   LODIJKE PLATFORM THEMA: FRIS WIT MET ZEEUWS MEEKRAB ROOD (#A31C1C)
   ========================================================================== */
.lodijke-interface { 
  display: flex; 
  height: 100dvh; 
  width: 100vw; 
  background: #f8fafc; 
  color: #1e293b; 
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; 
  overflow: hidden; 
  position: relative;
}

/* SIDEBAR NAVIGATION PANEL */
.menu-panel { 
  width: 260px; 
  background: #ffffff; 
  border-right: 1px solid #e2e8f0; 
  display: flex; 
  flex-direction: column; 
  flex-shrink: 0; 
  z-index: 30; 
  transition: width 0.2s ease, transform 0.25s ease; 
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

/* WORKSPACE PANEL */
.workspace-panel { flex: 1; display: flex; flex-direction: column; min-width: 0; height: 100dvh; background: #f8fafc; }
.viewport-control-bar { 
  background: #ffffff; 
  padding: 0.65rem 1.1rem; 
  border-bottom: 1px solid #e2e8f0; 
  display: flex; 
  flex-wrap: wrap;
  gap: 0.6rem;
  justify-content: space-between; 
  align-items: center; 
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02);
}
.active-module-info { display: flex; align-items: center; gap: 0.65rem; }
.active-module-info h3 { margin: 0; color: #a31c1c; font-size: 1.1rem; font-weight: 800; }
.breadcrumb { font-size: 0.76rem; color: #64748b; font-weight: 500; }

.btn-mobile-hamburger {
  display: none;
  background: #fff5f5;
  color: #a31c1c;
  border: 1px solid #feb2b2;
  border-radius: 6px;
  padding: 0.4rem 0.65rem;
  font-size: 1.1rem;
  font-weight: bold;
  cursor: pointer;
}

.viewport-layout-selector { display: flex; align-items: center; gap: 0.35rem; background: #f1f5f9; padding: 0.25rem 0.5rem; border-radius: 8px; border: 1px solid #e2e8f0; flex-wrap: wrap; }
.selector-label { font-size: 0.75rem; color: #64748b; font-weight: 700; }
.btn-layout { background: transparent; border: none; color: #475569; padding: 0.35rem 0.6rem; border-radius: 6px; font-size: 0.78rem; font-weight: 700; cursor: pointer; transition: all 0.15s; }
.btn-layout:hover { background: #e2e8f0; }
.btn-layout.active { background: #a31c1c; color: #ffffff; }

.external-quick-links { display: flex; gap: 0.45rem; }
.btn-quick-link { padding: 0.4rem 0.75rem; border-radius: 6px; border: none; text-decoration: none; font-size: 0.78rem; font-weight: 700; cursor: pointer; transition: transform 0.15s; }
.btn-quick-link:hover { transform: translateY(-1px); }
.api-btn { background: #a31c1c; color: #ffffff; }
.vercel-btn { background: #2b6cb0; color: #ffffff; }

/* VIEWPORTS MATRIX GRID */
.viewports-matrix { flex: 1; display: grid; gap: 6px; background: #e2e8f0; padding: 6px; overflow: hidden; min-height: 0; }
.layout-single { grid-template-columns: 1fr; grid-template-rows: 1fr; }
.layout-split-h { grid-template-columns: 1fr 1fr; grid-template-rows: 1fr; }
.layout-split-v { grid-template-columns: 1fr; grid-template-rows: 1fr 1fr; }
.layout-grid { grid-template-columns: 1fr 1fr; grid-template-rows: 1fr 1fr; }

.viewport-panel { background: #ffffff; border-radius: 8px; border: 1px solid #cbd5e1; display: flex; flex-direction: column; min-height: 0; overflow: hidden; box-shadow: 0 2px 4px rgba(0,0,0,0.02); }
.vp-header { background: #fff5f5; padding: 0.45rem 0.85rem; border-bottom: 1px solid #fed7d7; display: flex; align-items: center; gap: 0.6rem; }
.vp-tag { font-size: 0.68rem; font-weight: 800; background: #a31c1c; color: #ffffff; padding: 0.15rem 0.45rem; border-radius: 4px; flex-shrink: 0; }
.vp-module-select { flex: 1; min-width: 0; background: #ffffff; color: #801b1b; border: 1px solid #feb2b2; padding: 0.25rem 0.5rem; border-radius: 6px; font-size: 0.82rem; font-weight: 700; outline: none; }
.vp-body { flex: 1; overflow-y: auto; min-height: 0; background: #ffffff; }

.mobile-backdrop {
  display: none;
}

/* ==========================================================================
   MOBILE & TABLET RESPONSIVE VIEWPORTS (< 900px)
   ========================================================================== */
@media (max-width: 900px) {
  .btn-mobile-hamburger {
    display: inline-flex;
  }
  .menu-panel {
    position: fixed;
    top: 0;
    left: 0;
    bottom: 0;
    width: 270px !important;
    transform: translateX(-100%);
  }
  .mobile-menu-open .menu-panel {
    transform: translateX(0);
  }
  .mobile-backdrop {
    display: block;
    position: fixed;
    inset: 0;
    background: rgba(15, 23, 42, 0.45);
    z-index: 20;
  }
  .layout-split-h,
  .layout-grid {
    grid-template-columns: 1fr;
    grid-template-rows: auto;
    overflow-y: auto;
  }
  .viewport-panel {
    min-height: 360px;
  }
}
</style>
