#!/usr/bin/env bash
set -euo pipefail

# Werk direct in de huidige map (~/lodijke)
BASE_DIR="$(pwd)"

# 1. Als er een submap 'lodijke_master_platform' bestaat, verplaatsen we alles naar ~/lodijke
if [ -d "lodijke_master_platform" ]; then
    echo "Bestaande mappen verplaatsen naar ~/lodijke root..."
    cp -rn lodijke_master_platform/* . 2>/dev/null || true
    rm -rf lodijke_master_platform
fi

echo "Opbouwen direct in root: ${BASE_DIR}..."

# 01. Solid POD Vault Structure
mkdir -p "${BASE_DIR}/01_Solid_POD_Vault/profile"
mkdir -p "${BASE_DIR}/01_Solid_POD_Vault/public/photoalbum/uploads"
mkdir -p "${BASE_DIR}/01_Solid_POD_Vault/public/percelen"
mkdir -p "${BASE_DIR}/01_Solid_POD_Vault/public/cms"
mkdir -p "${BASE_DIR}/01_Solid_POD_Vault/private/genealogie"
mkdir -p "${BASE_DIR}/01_Solid_POD_Vault/private/woo_dossiers/bestuurlijke_correspondentie"
mkdir -p "${BASE_DIR}/01_Solid_POD_Vault/inbox"
mkdir -p "${BASE_DIR}/01_Solid_POD_Vault/settings"

touch "${BASE_DIR}/01_Solid_POD_Vault/profile/card#me"
touch "${BASE_DIR}/01_Solid_POD_Vault/public/photoalbum/photos.json"
touch "${BASE_DIR}/01_Solid_POD_Vault/public/percelen/geojson_parcels.json"
touch "${BASE_DIR}/01_Solid_POD_Vault/public/cms/cms_records.json"
touch "${BASE_DIR}/01_Solid_POD_Vault/private/genealogie/kwartierstaat_locked.json"
touch "${BASE_DIR}/01_Solid_POD_Vault/private/woo_dossiers/brp_auditlogs_firewall.json"
touch "${BASE_DIR}/01_Solid_POD_Vault/settings/prefs.ttl"

# 02. GRAMPS Genealogy Core
mkdir -p "${BASE_DIR}/02_GRAMPS_Genealogy_Core/db/gramps_cache"
mkdir -p "${BASE_DIR}/02_GRAMPS_Genealogy_Core/exports"
mkdir -p "${BASE_DIR}/02_GRAMPS_Genealogy_Core/profiles"

touch "${BASE_DIR}/02_GRAMPS_Genealogy_Core/exports/stamboom_schot_bout.ged"
touch "${BASE_DIR}/02_GRAMPS_Genealogy_Core/exports/kwartierstaat_I0103.json"
touch "${BASE_DIR}/02_GRAMPS_Genealogy_Core/profiles/I0103_Benjamin_Willem_Schot.json"
touch "${BASE_DIR}/02_GRAMPS_Genealogy_Core/profiles/I0104_Maria_Mathea_Bolier.json"
touch "${BASE_DIR}/02_GRAMPS_Genealogy_Core/profiles/I0105_Dina_Pieternella_Kegge.json"
touch "${BASE_DIR}/02_GRAMPS_Genealogy_Core/profiles/I0106_Jacob_Bout_x_Cornelia_Schot.json"

# 03. Axum Rust & Async-GraphQL Backend
mkdir -p "${BASE_DIR}/03_Axum_Rust_&_GraphQL_API/src"
mkdir -p "${BASE_DIR}/03_Axum_Rust_&_GraphQL_API/data"

touch "${BASE_DIR}/03_Axum_Rust_&_GraphQL_API/src/main.rs"
touch "${BASE_DIR}/03_Axum_Rust_&_GraphQL_API/src/graphql.rs"
touch "${BASE_DIR}/03_Axum_Rust_&_GraphQL_API/src/avored.rs"
touch "${BASE_DIR}/03_Axum_Rust_&_GraphQL_API/src/gramps.rs"
touch "${BASE_DIR}/03_Axum_Rust_&_GraphQL_API/src/gramps_api.rs"
touch "${BASE_DIR}/03_Axum_Rust_&_GraphQL_API/src/git_sync.rs"
touch "${BASE_DIR}/03_Axum_Rust_&_GraphQL_API/data/avored_collections.json"
touch "${BASE_DIR}/03_Axum_Rust_&_GraphQL_API/data/cms_records.json"
touch "${BASE_DIR}/03_Axum_Rust_&_GraphQL_API/data/geojson_parcels.json"
touch "${BASE_DIR}/03_Axum_Rust_&_GraphQL_API/data/git_sync_log.json"

# 04. CMS Document Tabs Frontend (Vue 3)
mkdir -p "${BASE_DIR}/04_CMS_Document_Tabs_Frontend/frontend/src/store"
mkdir -p "${BASE_DIR}/04_CMS_Document_Tabs_Frontend/frontend/src/composables"
mkdir -p "${BASE_DIR}/04_CMS_Document_Tabs_Frontend/frontend/src/components/tabs"

touch "${BASE_DIR}/04_CMS_Document_Tabs_Frontend/frontend/src/store/archiveStore.js"
touch "${BASE_DIR}/04_CMS_Document_Tabs_Frontend/frontend/src/composables/useViewports.js"
touch "${BASE_DIR}/04_CMS_Document_Tabs_Frontend/frontend/src/components/tabs/Tab01Genealogie.vue"
touch "${BASE_DIR}/04_CMS_Document_Tabs_Frontend/frontend/src/components/tabs/Tab02Fotos.vue"
touch "${BASE_DIR}/04_CMS_Document_Tabs_Frontend/frontend/src/components/tabs/Tab03Documenten.vue"
touch "${BASE_DIR}/04_CMS_Document_Tabs_Frontend/frontend/src/components/tabs/Tab04Kaarten.vue"
touch "${BASE_DIR}/04_CMS_Document_Tabs_Frontend/frontend/src/components/tabs/Tab05Plattegronden.vue"
touch "${BASE_DIR}/04_CMS_Document_Tabs_Frontend/frontend/src/components/tabs/Tab06Archeologie.vue"
touch "${BASE_DIR}/04_CMS_Document_Tabs_Frontend/frontend/src/components/tabs/Tab07Geologie.vue"
touch "${BASE_DIR}/04_CMS_Document_Tabs_Frontend/frontend/src/components/tabs/Tab08Kadaster.vue"
touch "${BASE_DIR}/04_CMS_Document_Tabs_Frontend/frontend/src/components/tabs/Tab09Woo.vue"
touch "${BASE_DIR}/04_CMS_Document_Tabs_Frontend/frontend/src/components/tabs/Tab10EigenTabs.vue"
touch "${BASE_DIR}/04_CMS_Document_Tabs_Frontend/frontend/src/components/tabs/Tab11RustCms.vue"

# 05. Temporal Index & Source Restructuring Engine
mkdir -p "${BASE_DIR}/05_Tijdmodule_&_Bron_Herstructurering/timeline_engine"
mkdir -p "${BASE_DIR}/05_Tijdmodule_&_Bron_Herstructurering/source_restructuring/raw_passages"
mkdir -p "${BASE_DIR}/05_Tijdmodule_&_Bron_Herstructurering/source_restructuring/RDF_parsers"
mkdir -p "${BASE_DIR}/05_Tijdmodule_&_Bron_Herstructurering/source_restructuring/audit_trails"

touch "${BASE_DIR}/05_Tijdmodule_&_Bron_Herstructurering/timeline_engine/master_chronology_1301_2026.json"
touch "${BASE_DIR}/05_Tijdmodule_&_Bron_Herstructurering/timeline_engine/temporal_index.rs"
touch "${BASE_DIR}/05_Tijdmodule_&_Bron_Herstructurering/timeline_engine/deadlines_awb_woo.json"
touch "${BASE_DIR}/05_Tijdmodule_&_Bron_Herstructurering/source_restructuring/audit_trails/brp_discrepancy_1043_1048.json"
touch "${BASE_DIR}/05_Tijdmodule_&_Bron_Herstructurering/source_restructuring/audit_trails/postnl_time_stamps.json"
touch "${BASE_DIR}/05_Tijdmodule_&_Bron_Herstructurering/source_restructuring/auto_git_pipeline.sh"

chmod +x "${BASE_DIR}/05_Tijdmodule_&_Bron_Herstructurering/source_restructuring/auto_git_pipeline.sh"

# Git setup op main in ~/lodijke
git init
git config advice.defaultBranchName false 2>/dev/null || true
git branch -M main
git add .
git commit -m "feat: complete Lodijke Master Platform architecture in main" || true

echo "=============================================================================="
echo "Lodijke mappenstructuur succesvol aangemaakt direct in: ${BASE_DIR}"
echo "Git branch staat nu ingesteld op: main"
echo "=============================================================================="
