#!/usr/bin/env bash
# ==============================================================================
# OPTIE 4: WIJZIGINGEN VASTLEGGEN & PUSHEN NAAR GITHUB / VERCEL
# Bouwt lokaal een verificatie van de Vue 3 app en pusht naar GitHub zodat
# https://lodijke.vercel.app/ automatisch wordt bijgewerkt.
# ==============================================================================

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

COMMIT_MSG="${1:-feat(gis+graphql): Perceel 369, Kasteel Lodijke (-3.20m NAP), Molenplaat 150ha & GRAMPS I0103}"

echo -e "${CYAN}=== [1/3] Productie-build verifiëren voor Vercel ===${NC}"
cd frontend
npm run build
cd ..

echo -e "${CYAN}=== [2/3] Git staging & commit ===${NC}"
git add -A
git status --short

if git diff --cached --quiet; then
    echo -e "${YELLOW}Geen nieuwe wijzigingen om te committen.${NC}"
else
    git commit -m "$COMMIT_MSG"
fi

echo -e "${CYAN}=== [3/3] Pushen naar GitHub (triggert https://lodijke.vercel.app/) ===${NC}"
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
git push origin "$BRANCH"

echo -e "\n${GREEN}✔ Succesvol gepusht naar origin/${BRANCH}! Vercel bouwt nu automatisch de nieuwe release op https://lodijke.vercel.app/${NC}"
