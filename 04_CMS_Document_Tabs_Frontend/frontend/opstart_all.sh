#!/usr/bin/env bash
# ==============================================================================
# OPTIE 1: 1-CLICK MASTER OPSTARTSCRIPT (opstart_all.sh)
# Ruimt poortconflicten op (:8082 en :5173) met fuser, start Axum & Vue 3
# op de achtergrond en rapporteert de live status in de terminal.
# ==============================================================================

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}======================================================================${NC}"
echo -e "${CYAN}  LODIJKE 1-CLICK MASTER LAUNCHER (:8082 AXUM & :5173 VUE 3 GIS)      ${NC}"
echo -e "${CYAN}======================================================================${NC}"

# 1. Poortconflicten opschonen met fuser
echo -e "\n${YELLOW}[1/4] Controleren en vrijmaken van poorten 8082 en 5173...${NC}"
for PORT in 8082 5173; do
    if command -v fuser >/dev/null 2>&1; then
        if fuser "${PORT}/tcp" >/dev/null 2>&1; then
            echo -e "  -> Poort :${PORT} bezet. Proces wordt beëindigd via fuser..."
            fuser -k "${PORT}/tcp" >/dev/null 2>&1 || true
            sleep 1
        else
            echo -e "  -> Poort :${PORT} is vrij."
        fi
    else
        # Fallback naar lsof als fuser niet geïnstalleerd is
        PID=$(lsof -t -i:${PORT} 2>/dev/null || true)
        if [ -n "$PID" ]; then
            echo -e "  -> Poort :${PORT} bezet (PID $PID). Proces wordt beëindigd..."
            kill -9 $PID 2>/dev/null || true
        fi
    fi
done

# 2. Start Rust Axum GraphQL Backend (:8082)
echo -e "\n${YELLOW}[2/4] Opstarten Rust Axum GraphQL API op poort :8082...${NC}"
cd backend
nohup cargo run --release > ../axum_8082.log 2>&1 &
AXUM_PID=$!
cd ..
echo -e "  -> Axum gestart op achtergrond (PID: ${AXUM_PID}, Log: axum_8082.log)"

# 3. Start Vue 3 Vite Frontend (:5173)
echo -e "\n${YELLOW}[3/4] Opstarten Vue 3 Leaflet GIS Frontend op poort :5173...${NC}"
cd frontend
if [ ! -d "node_modules" ]; then
    echo -e "  -> Eerste keer opstarten: npm packages installeren..."
    npm install --silent
fi
nohup npm run dev > ../vue_5173.log 2>&1 &
VUE_PID=$!
cd ..
echo -e "  -> Vue 3 gestart op achtergrond (PID: ${VUE_PID}, Log: vue_5173.log)"

# 4. Health & Status Check
echo -e "\n${YELLOW}[4/4] Wachten op initialisatie en poortbinding...${NC}"
for i in {1..15}; do
    AXUM_UP=$(ss -tulpn 2>/dev/null | grep -c ":8082 " || true)
    VUE_UP=$(ss -tulpn 2>/dev/null | grep -c ":5173 " || true)
    if [ "$AXUM_UP" -ge 1 ] && [ "$VUE_UP" -ge 1 ]; then
        break
    fi
    sleep 1
done

echo -e "\n${GREEN}======================================================================${NC}"
echo -e "${GREEN}  STATUS RAPPORTAGE LODIJKE STACK                                     ${NC}"
echo -e "${GREEN}======================================================================${NC}"
if ss -tulpn 2>/dev/null | grep -q ":8082 "; then
    echo -e "  [OK] Rust Axum GraphQL API : ${GREEN}ONLINE${NC} -> http://localhost:8082/graphql (PID: $AXUM_PID)"
else
    echo -e "  [..] Rust Axum GraphQL API : ${YELLOW}COMPILEREN OP ACHTERGROND${NC} (bekijk: tail -f axum_8082.log)"
fi

if ss -tulpn 2>/dev/null | grep -q ":5173 "; then
    echo -e "  [OK] Vue 3 GIS Frontend    : ${GREEN}ONLINE${NC} -> http://localhost:5173         (PID: $VUE_PID)"
else
    echo -e "  [..] Vue 3 GIS Frontend    : ${YELLOW}OPSTARTEN${NC} (bekijk: tail -f vue_5173.log)"
fi
echo -e "${GREEN}======================================================================${NC}"
echo -e "Stoppen van beide servers? Gebruik: ${CYAN}fuser -k 8082/tcp 5173/tcp${NC}"
