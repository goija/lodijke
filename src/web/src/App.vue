<template>
  <div class="app-shell">
    <aside class="rail">
      <div v-for="item in NAV" :key="item.id" class="nav-btn" :class="{ active: activeGroup === item.id }" @click="toggleGroup(item.id)">
        <span class="icon">{{ item.icon }}</span>
        <span class="label">{{ item.label }}</span>
      </div>
      <button class="clear-btn" @click="closeAll">✕</button>
    </aside>
    
    <transition name="slide">
      <aside v-if="activeGroup" class="slide-panel">
        <div v-for="grp in NAV" :key="grp.id" v-if="grp.id === activeGroup">
          <h3>{{ grp.label }}</h3>
          <div v-for="sub in grp.subs" :key="sub.id" class="sub-tab" @click="openTopic(sub.id, sub.label)">{{ sub.label }}</div>
        </div>
      </aside>
    </transition>

    <main class="workspace">
      <div class="workspace-toolbar">
        <button @click="tile('grid')">Raster</button>
        <button @click="tile('columns')">Kolommen</button>
        <button @click="tile('cascade')">Trap</button>
        <button @click="closeAll">Alles sluiten</button>
      </div>
      <teleport to="body">
        <ViewportFrame v-for="vp in viewports" :key="vp.id" :vp="vp" @close="closeViewport(vp.id)" @minimize="toggleMinimize(vp.id)" @maximize="toggleMaximize(vp.id)" @focus="focusViewport(vp.id)">
          <PanelHost :topic="vp.topic" />
        </ViewportFrame>
      </teleport>
    </main>

    <footer class="app-footer">
      <div class="footer-links">
        <a v-for="link in FOOTER" :key="link.id" href="#" @click.prevent="openFooter(link.id)">{{ link.label }}</a>
      </div>
      <div class="footer-status">
        <span v-if="cmsOk" class="status-dot online"></span> CMS
        <span v-if="grampsOk" class="status-dot online"></span> Gramps
        <span class="version">v7.0.0</span>
      </div>
    </footer>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { NAVIGATION as NAV, FOOTER_LINKS as FOOTER } from './config/navigation';
import { viewports, openViewport, closeViewport, closeAll, focusViewport, toggleMaximize, toggleMinimize, tile, bindWorkspace } from './stores/viewportStore';
import ViewportFrame from './components/workspace/ViewportFrame.vue';
import PanelHost from './components/workspace/PanelHost.vue';

const activeGroup = ref(null);
const cmsOk = ref(false);
const grampsOk = ref(false);

const toggleGroup = (id) => { activeGroup.value = activeGroup.value === id ? null : id; };
const openTopic = (topic, title) => { openViewport({ topic, title }); activeGroup.value = null; };
const openFooter = (topic) => { openViewport({ topic, title: topic.toUpperCase() }); };

onMounted(async () => {
  const ws = document.querySelector('.workspace');
  if (ws) bindWorkspace(ws.getBoundingClientRect());
  
  try {
    const r1 = await fetch('/api/status'); cmsOk.value = r1.ok;
    const r2 = await fetch('/api/gramps/status'); grampsOk.value = r2.ok;
  } catch (e) {}
});
</script>

<style scoped>
.app-shell { display: flex; flex-direction: column; height: 100vh; background: #f9f7f2; color: #18181b; font-family: sans-serif; }
.rail { width: 76px; background: #1f3346; display: flex; flex-direction: column; align-items: center; padding-top: 1rem; }
.nav-btn { width: 100%; padding: 0.75rem; cursor: pointer; display: flex; flex-direction: column; align-items: center; color: #f9f7f2; border-radius: 6px; margin-bottom: 0.5rem; transition: background 0.2s; }
.nav-btn:hover { background: rgba(255,255,255,0.1); }
.nav-btn.active { background: #8b2229; }
.nav-btn .icon { font-size: 1.5rem; margin-bottom: 0.25rem; }
.nav-btn .label { font-size: 0.7rem; }
.clear-btn { margin-top: auto; margin-bottom: 1rem; padding: 0.5rem 1rem; background: #8b2229; color: white; border: none; border-radius: 4px; cursor: pointer; }
.slide-panel { width: 240px; background: white; border-left: 1px solid #e0d8c8; padding: 1rem; overflow-y: auto; }
.slide-enter-active, .slide-leave-active { transition: all 0.3s ease; }
.slide-enter-from, .slide-leave-to { transform: translateX(-100%); opacity: 0; }
.slide-panel h3 { margin: 0 0 1rem; font-size: 1rem; color: #1f3346; }
.sub-tab { padding: 0.5rem; cursor: pointer; border-radius: 4px; margin-bottom: 0.25rem; }
.sub-tab:hover { background: #f0ebe0; }
.workspace { flex: 1; position: relative; overflow: hidden; }
.workspace-toolbar { padding: 0.5rem; background: #e0d8c8; display: flex; gap: 0.5rem; }
.workspace-toolbar button { padding: 0.25rem 0.75rem; border: 1px solid #1f3346; background: white; cursor: pointer; border-radius: 4px; }
.app-footer { background: #1f3346; color: white; padding: 0.75rem; display: flex; justify-content: space-between; font-size: 0.8rem; }
.footer-links a { color: #f9f7f2; text-decoration: none; margin-right: 1rem; }
.footer-links a:hover { text-decoration: underline; }
.status-dot { display: inline-block; width: 8px; height: 8px; border-radius: 50%; margin-right: 0.25rem; }
.status-dot.online { background: #22c55e; }
.version { margin-left: 1rem; opacity: 0.7; }
</style>
