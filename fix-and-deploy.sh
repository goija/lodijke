#!/usr/bin/env bash
set -euo pipefail

echo "==> 1. Git identiteit instellen..."
git config user.email "goija@protonmail.com" || true
git config user.name "goija" || true

echo "==> 2. Mappenstructuur controleren..."
mkdir -p "04_CMS_Document_Tabs_Frontend/frontend/public"
mkdir -p "04_CMS_Document_Tabs_Frontend/frontend/src"

echo "==> 3. Cargo.toml repareren in Axum API..."
if [ -d "03_Axum_Rust_&_GraphQL_API" ]; then
cat << 'CARGO' > "03_Axum_Rust_&_GraphQL_API/Cargo.toml"
[package]
name = "lodijke_backend"
version = "0.1.0"
edition = "2021"

[dependencies]
axum = { version = "0.7", features = ["macros", "json"] }
tokio = { version = "1.0", features = ["full"] }
async-graphql = { version = "7.0", features = ["chrono"] }
async-graphql-axum = "7.0"
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
chrono = { version = "0.4", features = ["serde"] }
reqwest = { version = "0.11", features = ["json"] }
solid-pod-rs = "0.5.0-alpha.17"
CARGO
fi

echo "==> 4. Vercel configuratie en package.json aanmaken..."
cat << 'VERCEL' > vercel.json
{
  "version": 2,
  "name": "lodijke-master-platform",
  "cleanUrls": true,
  "routes": [
    { "src": "/(.*)", "dest": "/index.html" }
  ]
}
VERCEL

cat << 'PKG' > 04_CMS_Document_Tabs_Frontend/frontend/package.json
{
  "name": "lodijke-cms-frontend",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "vue": "^3.4.0",
    "pinia": "^2.1.0"
  },
  "devDependencies": {
    "@vitejs/plugin-vue": "^5.0.0",
    "vite": "^5.0.0"
  }
}
PKG

echo "==> 5. Volledige index.html genereren met Zeeuws Meekrap Rood thema..."
cat << 'INDEX' > index.html
<!DOCTYPE html>
<html lang="nl">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Lodijke Master Platform | Zeeuws Visserij Dossier & Archiefbeheer</title>
  <style>
    :root {
      --primary: #8B1E1E;
      --primary-hover: #661010;
      --bg-dark: #3A0808;
      --accent-white: #FFFFFF;
      --off-white: #F9F8F6;
      --card-bg: #FFFFFF;
      --border-color: #E2D7D5;
      --text-color: #2C2221;
    }

    body {
      background-color: var(--off-white);
      color: var(--text-color);
      font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      margin: 0;
      padding: 0;
    }

    header.master-nav {
      background-color: var(--primary);
      color: var(--accent-white);
      padding: 1rem 2rem;
      position: sticky;
      top: 0;
      z-index: 1000;
      box-shadow: 0 4px 12px rgba(0,0,0,0.15);
    }

    .nav-container {
      max-width: 1400px;
      margin: 0 auto;
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 1rem;
    }

    .brand-title {
      font-size: 1.4rem;
      font-weight: 800;
      color: var(--accent-white);
      text-decoration: none;
    }

    .visserij-home-btn {
      background-color: var(--accent-white);
      color: var(--primary);
      font-weight: 800;
      padding: 0.6rem 1.4rem;
      border-radius: 8px;
      text-decoration: none;
      display: inline-flex;
      align-items: center;
      gap: 0.5rem;
      transition: all 0.2s ease-in-out;
    }

    .visserij-home-btn:hover {
      background-color: var(--off-white);
      color: var(--primary-hover);
      transform: translateY(-2px);
    }

    .hero-banner {
      background: linear-gradient(135deg, var(--primary) 0%, var(--bg-dark) 100%);
      color: var(--accent-white);
      padding: 3.5rem 2rem;
      text-align: center;
    }

    .hero-banner h1 {
      font-size: 2.5rem;
      font-weight: 900;
      margin-bottom: 0.8rem;
    }

    .container-wide {
      max-width: 1400px;
      margin: 2rem auto;
      padding: 0 1.5rem;
    }

    .module-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(360px, 1fr));
      gap: 1.5rem;
      margin-top: 1.5rem;
    }

    .card-module {
      background: var(--card-bg);
      border: 1px solid var(--border-color);
      border-top: 4px solid var(--primary);
      border-radius: 10px;
      padding: 1.5rem;
      box-shadow: 0 4px 10px rgba(0,0,0,0.05);
    }

    .card-module h3 {
      color: var(--primary);
      margin-top: 0;
    }

    .map-container {
      background-color: #1a2634;
      border-radius: 12px;
      padding: 2rem;
      color: var(--accent-white);
      position: relative;
      min-height: 320px;
      border: 2px solid var(--primary);
    }

    .perceel-pin {
      position: absolute;
      top: 50%;
      left: 55%;
      transform: translate(-50%, -50%);
    }

    .pulse-core {
      width: 18px;
      height: 18px;
      background-color: var(--primary);
      border: 3px solid #FFFFFF;
      border-radius: 50%;
    }

    .pulse-wave {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      width: 20px;
      height: 20px;
      border: 2px solid var(--primary);
      border-radius: 50%;
      animation: pulse-wave-anim 2s infinite ease-out;
    }

    @keyframes pulse-wave-anim {
      0% { width: 20px; height: 20px; opacity: 1; }
      100% { width: 80px; height: 80px; opacity: 0; }
    }

    footer {
      background-color: var(--bg-dark);
      color: var(--accent-white);
      padding: 2rem;
      text-align: center;
      margin-top: 3rem;
    }
  </style>
</head>
<body id="home">

  <header class="master-nav">
    <div class="nav-container">
      <a href="#home" class="brand-title">🏛️ Lodijke Master Platform</a>
      <a href="#home" class="visserij-home-btn" onclick="window.scrollTo({top: 0, behavior: 'smooth'}); return false;">
        🎣 Visserij Dossier (Home)
      </a>
    </div>
  </header>

  <section class="hero-banner">
    <h1>Zeeuws Visserij Dossier & Lodijke Archiefbeheer</h1>
    <p>Geharmoniseerde Systeemarchitectuur op basis van W3C Solid POD, GRAMPS Web, Axum Rust API & Vue 3 CMS.</p>
  </section>

  <div class="container-wide">
    <section>
      <h2 style="color: var(--primary);">📍 Geodetische Kaartweergave & Perceel No. 369</h2>
      <div class="map-container">
        <div class="perceel-pin">
          <div class="pulse-core"></div>
          <div class="pulse-wave"></div>
        </div>
        <div style="position: absolute; bottom: 15px; left: 20px; font-size: 0.9rem;">
          Oesterperceel No. 369 (12,5 ha) | Bol van Lodijke | Reder B.W. Schot (1840–1935)<br>
          Coördinaten: RD X=68120 Y=388050 (-2,10m NAP)
        </div>
      </div>
    </section>

    <section style="margin-top: 2rem;">
      <h2 style="color: var(--primary);">⚙️ De Overkoepelende Platform Modules</h2>
      <div class="module-grid">
        <article class="card-module">
          <h3>01. Solid POD Vault</h3>
          <p>W3C Solid POD datakluis voor openbare media, GeoJSON percelen en AVG-zone.</p>
        </article>
        <article class="card-module">
          <h3>02. GRAMPS Genealogy Core</h3>
          <p>Gramps Web API, SQLite/BSD database & Stamvader B.W. Schot (I0103).</p>
        </article>
        <article class="card-module">
          <h3>03. Axum Rust & GraphQL API</h3>
          <p>Rust backend met Async-GraphQL en solid-pod-rs crate op poort 8082.</p>
        </article>
        <article class="card-module">
          <h3>04. CMS Document Tabs Frontend</h3>
          <p>Vue 3 CMS met 11 gelaagde document-tabbladen (Doc A, Doc B, Doc C).</p>
        </article>
        <article class="card-module">
          <h3>05. Tijdmodule & Herstructurering</h3>
          <p>Chronologische motor (1301–2026), Awb/Woo termijnen & BRP-auditlogs.</p>
        </article>
        <article class="card-module">
          <h3>06. Geopark Schelde Delta</h3>
          <p>Slag bij Lodijke (1301), Kasteel ARC-LOD-01 (-3,20m NAP) & UNESCO dossier.</p>
        </article>
      </div>
    </section>
  </div>

  <footer>
    <p>Lodijke Master Platform &copy; 2026 | Live op <a href="https://lodijke.vercel.app/" style="color:#FF9999;">lodijke.vercel.app</a> | GitHub <a href="https://github.com/goija/lodijke" style="color:#FF9999;">goija/lodijke</a></p>
  </footer>

</body>
</html>
INDEX

cp index.html 04_CMS_Document_Tabs_Frontend/frontend/public/index.html 2>/dev/null || true

echo "==> 6. Git commit en push naar main..."
git init
git config advice.defaultBranchName false 2>/dev/null || true
git branch -M main

git remote remove origin 2>/dev/null || true
git remote add origin https://github.com/goija/lodijke.git

git add .
git commit -m "fix: clean build index.html, vercel routing and cargo solid-pod-rs"

git push -u origin main --force

echo "==> 7. Uitrollen naar Vercel..."
npx vercel --prod --force --yes

echo "=============================================================================="
echo "SUCCES: Project opgeschoond, ingediend op GitHub main & uitgerold op Vercel!"
echo "=============================================================================="
