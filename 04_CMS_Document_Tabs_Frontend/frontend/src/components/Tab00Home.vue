<template>
  <div class="home-container">
    <header class="home-header">
      <div class="header-titles">
        <h1>🏛️ Lodijke Master Platform</h1>
        <p class="subtitle">Zeeuws Visserij Dossier & Lodijke Archiefbeheer</p>
      </div>
      <div class="header-actions">
        <a href="http://127.0.0.1:8082" target="_blank" class="btn btn-primary">
          ⚡ GraphQL Studio (:8082)
        </a>
        <a href="https://lodijke.vercel.app/" target="_blank" class="btn btn-secondary">
          🌐 Vercel Live App
        </a>
      </div>
    </header>

    <!-- Highlight Banner: Perceel 369 -->
    <section class="highlight-card">
      <div class="card-badge">📍 Geodetische Kaartweergave & Perceel No. 369</div>
      <h2>Oesterperceel No. 369 op de Bol van Lodijke (12,5 ha)</h2>
      <p class="card-desc">
        Pachtconcessie van Reder Benjamin Willem Schot (1840–1935).
      </p>
      <div class="meta-grid">
        <div><strong>Hoogaarzen:</strong> TH 2 "Eben Haëzer", TH 12 & TH 90</div>
        <div><strong>Coördinaten RD:</strong> EPSG:28992 (X: 68120, Y: 388050)</div>
        <div><strong>Coördinaten WGS84:</strong> 51.47833°N, 4.13750°E</div>
        <div><strong>Diepte:</strong> -2.10m NAP (Bol) | -3.20m NAP (Kasteel ARC-LOD-01)</div>
      </div>
    </section>

    <!-- 9 Platform Modules Grid -->
    <h3 class="section-title">⚙️ De Overkoepelende Platform Modules</h3>
    <div class="modules-grid">
      
      <!-- Module 01 -->
      <div class="module-card">
        <div class="module-num">01</div>
        <h4>Solid POD Vault</h4>
        <p>W3C Personal Online Datastore. Beheert de openbare fotodatabase, GeoJSON percelen en een AVG-geïsoleerde private zone voor BRP-auditlogs.</p>
      </div>

      <!-- Module 02 -->
      <div class="module-card">
        <div class="module-num">02</div>
        <h4>GRAMPS Genealogy Core</h4>
        <p>Gramps Web API & SQLite database. Herbergt stamvader B.W. Schot (I0103), zijn 13 kinderen, 2e echtgenote D.P. Kegge en GEDCOM 5.5.1 exports.</p>
      </div>

      <!-- Module 03 (MET LOKAAL + VERCEL + GITHUB LINKS) -->
      <div class="module-card active-api-card">
        <div class="module-num">03</div>
        <h4>Axum Rust & GraphQL API</h4>
        <p>Hoge-performance Rust backend op poort 8082 met Async-GraphQL.</p>
        <div class="api-link-box">
          <div class="status-tag">● LIVE (Lokaal & Vercel)</div>
          <div class="link-stack">
            <a href="http://127.0.0.1:8082" target="_blank" class="api-url-link">
              <code>http://127.0.0.1:8082</code> 🔗
            </a>
            <a href="https://lodijke.vercel.app/" target="_blank" class="api-url-link vercel-color">
              <code>https://lodijke.vercel.app/</code> 🚀
            </a>
            <a href="[suspicious link removed]" target="_blank" class="api-url-link github-color">
              <code>github.com/goija/lodijke</code> 📦
            </a>
          </div>
        </div>
      </div>

      <!-- Module 04 t/m 09 -->
      <div class="module-card">
        <div class="module-num">04</div>
        <h4>CMS Document Tabs</h4>
        <p>Vue 3 Multi-viewport interface met gelaagde tabs voor dossierstukken, kaarten en notariële akten.</p>
      </div>

      <div class="module-card">
        <div class="module-num">05</div>
        <h4>Tijdmodule & Herstructurering</h4>
        <p>Chronologische tijdlijn (1301–2026), Woo-termijnbewakers en geautomatiseerde audit trails.</p>
      </div>

      <div class="module-card">
        <div class="module-num">06</div>
        <h4>GIS & Leaflet Kaartweergave</h4>
        <p>Interactieve kaartlagen met RD/WGS84 coördinatentransformatie voor percelen en verdonken steden.</p>
      </div>

      <div class="module-card">
        <div class="module-num">07</div>
        <h4>Woo-Sporen (A-F)</h4>
        <p>Juridisch zaakregister voor bestuursrechtelijke procedures bij Rechtbank ZWB en Provincie Zeeland.</p>
      </div>

      <div class="module-card">
        <div class="module-num">08</div>
        <h4>Geopark Schelde Delta</h4>
        <p>UNESCO-indieningsdossiers, geosite-registers en lithostratigrafische boorstaten.</p>
      </div>

      <div class="module-card">
        <div class="module-num">09</div>
        <h4>AvoRed Content Engine</h4>
        <p>Rust CMS gegevensverzamelingen, dynamische schema's en persistente JSON-opslag op schijf.</p>
      </div>

    </div>
  </div>
</template>

<style scoped>
.home-container {
  padding: 1.5rem;
  color: #cdd6f4;
  background: #1e1e2e;
  min-height: 100vh;
}
.home-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 2px solid #313244;
  padding-bottom: 1rem;
  margin-bottom: 1.5rem;
  flex-wrap: wrap;
  gap: 1rem;
}
.home-header h1 {
  margin: 0;
  font-size: 1.8rem;
  color: #f38ba8;
}
.subtitle {
  margin: 0.25rem 0 0 0;
  color: #a6adc8;
}
.header-actions {
  display: flex;
  gap: 0.75rem;
}
.btn {
  padding: 0.6rem 1.1rem;
  border-radius: 8px;
  text-decoration: none;
  font-weight: bold;
  font-size: 0.9rem;
  transition: all 0.2s;
}
.btn-primary {
  background: #a6e3a1;
  color: #11111b;
}
.btn-primary:hover {
  background: #94e2d5;
}
.btn-secondary {
  background: #89b4fa;
  color: #11111b;
}
.btn-secondary:hover {
  background: #b4befe;
}
.highlight-card {
  background: #181825;
  border: 1px solid #89b4fa;
  border-radius: 12px;
  padding: 1.25rem;
  margin-bottom: 2rem;
}
.card-badge {
  display: inline-block;
  background: #89b4fa;
  color: #11111b;
  font-weight: bold;
  font-size: 0.8rem;
  padding: 0.2rem 0.6rem;
  border-radius: 6px;
  margin-bottom: 0.5rem;
}
.highlight-card h2 {
  margin: 0.25rem 0 0.5rem 0;
  color: #89b4fa;
}
.meta-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 0.75rem;
  margin-top: 1rem;
  background: #1e1e2e;
  padding: 0.75rem;
  border-radius: 8px;
  font-size: 0.9rem;
}
.section-title {
  color: #fab387;
  margin-bottom: 1rem;
}
.modules-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 1rem;
}
.module-card {
  background: #181825;
  border: 1px solid #313244;
  border-radius: 10px;
  padding: 1rem;
  position: relative;
}
.active-api-card {
  border-color: #a6e3a1;
  background: #18251e;
}
.module-num {
  font-size: 0.8rem;
  font-weight: bold;
  color: #f5e0dc;
  background: #313244;
  display: inline-block;
  padding: 0.15rem 0.5rem;
  border-radius: 4px;
  margin-bottom: 0.5rem;
}
.module-card h4 {
  margin: 0 0 0.4rem 0;
  color: #cba6f7;
}
.module-card p {
  margin: 0;
  font-size: 0.88rem;
  color: #bac2de;
  line-height: 1.4;
}
.api-link-box {
  margin-top: 0.8rem;
  padding-top: 0.6rem;
  border-top: 1px dashed #a6e3a1;
}
.status-tag {
  color: #a6e3a1;
  font-size: 0.75rem;
  font-weight: bold;
  margin-bottom: 0.4rem;
}
.link-stack {
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
}
.api-url-link {
  color: #89b4fa;
  font-size: 0.83rem;
  text-decoration: none;
  font-family: monospace;
}
.api-url-link:hover {
  text-decoration: underline;
}
.vercel-color {
  color: #f38ba8;
}
.github-color {
  color: #f9e2af;
}
</style>
