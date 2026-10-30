#!/usr/bin/env bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

PROJECT_ROOT="$HOME/lodijke"
BACKEND_DIR="$PROJECT_ROOT/03_Axum_Rust_&_GraphQL_API"

echo "=============================================================================="
echo "LODIJKEE MASTER PLATFORM - DEPLOYMENT SCRIPT"
echo "=============================================================================="

log_info "Controleer projectmap $PROJECT_ROOT..."
mkdir -p "$PROJECT_ROOT"
cd "$PROJECT_ROOT"

log_info "Aanmaken en valideren van lokale databasebestanden..."
mkdir -p "$BACKEND_DIR/data"
[ -f "$BACKEND_DIR/data/cms_records.json" ] || echo '[]' > "$BACKEND_DIR/data/cms_records.json"
[ -f "$BACKEND_DIR/data/geojson_parcels.json" ] || echo '[]' > "$BACKEND_DIR/data/geojson_parcels.json"
[ -f "$BACKEND_DIR/data/git_sync_log.json" ] || echo '[]' > "$BACKEND_DIR/data/git_sync_log.json"

log_info "Axum Rust GraphQL backend compileren op poort 8082..."
if [ -d "$BACKEND_DIR" ]; then
    cd "$BACKEND_DIR"
    if command -v cargo &> /dev/null; then
        cargo build --release
        log_success "Axum Rust release binary gecompileerd."
    fi
fi

log_info "Systemd service instellen..."
if command -v systemctl &> /dev/null; then
    sudo bash -c "cat << 'SERVICE_EOF' > /etc/systemd/system/lodijke-backend.service
[Unit]
Description=Lodijke Axum Rust GraphQL & CMS Backend
After=network.target

[Service]
Type=simple
User=$(whoami)
WorkingDirectory=$BACKEND_DIR
ExecStart=$BACKEND_DIR/target/release/axum_backend
Restart=always
RestartSec=3s
Environment=PORT=8082

[Install]
WantedBy=multi-user.target
SERVICE_EOF"

    sudo systemctl daemon-reload
    sudo systemctl enable --now lodijke-backend
    log_success "Systemd service geactiveerd op poort 8082."
fi

cd "$PROJECT_ROOT"
log_info "Git remotes configureren en synchroniseren..."
if [ -d ".git" ]; then
    git remote remove origin 2>/dev/null || true
    git remote add origin "git@github.com:goija/lodijke.git"

    git remote remove live-repo 2>/dev/null || true
    git remote add live-repo "git@github.com:goija/visserij-dossier-live.git"

    git add -A
    git commit -m "feat: Systemd service (8082), GraphQL CMS mutaties & Dual Repo Sync" || true

    log_info "Pushen naar github.com/goija/lodijke..."
    git push -u origin main --force || true

    log_info "Pushen naar github.com/goija/visserij-dossier-live..."
    git push -u live-repo main --force || true

    log_success "Git synchronisatie voltooid."
fi

echo "=============================================================================="
log_success "DEPLOYMENT SCRIPT VOLTOOID!"
echo "=============================================================================="
