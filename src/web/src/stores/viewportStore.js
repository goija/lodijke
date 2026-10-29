import { reactive } from 'vue';

let zTop = 950, seq = 0;
const MIN_W = 260, MIN_H = 160;
export const viewports = reactive([]);
let bounds = { left: 0, top: 0, width: window.innerWidth, height: window.innerHeight };

export function bindWorkspace(rect) { bounds = rect; }
export function getBounds() { return bounds; }

export function openViewport({ topic, title, x, y, w = 760, h = 520, singleton = true }) {
  if (singleton) { const found = viewports.find(v => v.topic === topic); if (found) { found.minimized = false; focusViewport(found.id); return found; } }
  seq++;
  const cascade = (viewports.length % 7) * 26;
  const vp = reactive({ id: `vp-${seq}`, topic, title: title || topic, x: Math.round(x ?? 108 + cascade), y: Math.round(y ?? 68 + cascade), w, h, z: ++zTop, minimized: false, maximized: false, restore: null });
  viewports.push(vp);
  return vp;
}

export function closeViewport(id) { const i = viewports.findIndex(v => v.id === id); if (i !== -1) viewports.splice(i, 1); }
export function closeAll() { viewports.splice(0, viewports.length); }
export function focusViewport(id) { const vp = viewports.find(v => v.id === id); if (vp) vp.z = ++zTop; }

export function toggleMaximize(id) {
  const vp = viewports.find(v => v.id === id); if (!vp) return;
  const b = getBounds();
  if (vp.maximized) { if (vp.restore) Object.assign(vp, vp.restore); vp.maximized = false; vp.restore = null; }
  else { vp.restore = { x: vp.x, y: vp.y, w: vp.w, h: vp.h }; vp.x = b.left; vp.y = b.top; vp.w = b.width; vp.h = b.height; vp.maximized = true; }
}

export function toggleMinimize(id) {
  const vp = viewports.find(v => v.id === id); if (!vp) return;
  if (vp.minimized) { vp.minimized = false; } else { vp.minimized = true; }
}

export function tile(mode = 'grid') {
  const list = viewports.filter(v => !v.minimized); if (!list.length) return;
  const b = getBounds(), pad = 10;
  list.forEach(v => { v.maximized = false; v.restore = null; });
  
  if (mode === 'cascade') { list.forEach((v, i) => { v.x = b.left + 24 + i * 30; v.y = b.top + 18 + i * 28; v.w = Math.min(820, b.width - 80); v.h = Math.min(560, b.height - 70); }); return; }
  
  const cols = mode === 'columns' ? Math.min(2, list.length) : Math.ceil(Math.sqrt(list.length));
  const rows = Math.ceil(list.length / cols);
  const cw = (b.width - pad * (cols + 1)) / cols, ch = (b.height - pad * (rows + 1)) / rows;
  list.forEach((v, i) => { const c = i % cols, row = Math.floor(i / cols); v.x = b.left + pad + c * (cw + pad); v.y = b.top + pad + row * (ch + pad); v.w = cw; v.h = ch; });
}
