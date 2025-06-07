#!/bin/bash

# Script para mostrar resumen compacto del estado del sistema
# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m'

# Símbolos
CHECK="✓"
BULLET="•"
STAR="★"

echo -e "${BLUE}┌─────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│${WHITE}                   RESUMEN DEL SISTEMA                      ${BLUE}│${NC}"
echo -e "${BLUE}└─────────────────────────────────────────────────────────────┘${NC}"

# Estado de discos en línea compacta
echo -e "\n${CYAN}Discos:${NC}"
if [[ -d "/Volumes/BLACK2T" ]]; then
    BLACK2T_INFO=$(df -h /Volumes/BLACK2T | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')
    echo -e "  ${GREEN}${CHECK} BLACK2T:${NC} ${WHITE}$BLACK2T_INFO${NC}"
else
    echo -e "  ${RED}✗ BLACK2T: No montado${NC}"
fi

INTERNAL_INFO=$(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')
echo -e "  ${GREEN}${CHECK} Interno:${NC} ${WHITE}$INTERNAL_INFO${NC}"

# Resumen de migración
echo -e "\n${CYAN}Migración:${NC}"
if [[ -f "config/migration_state.json" ]]; then
    if command -v jq >/dev/null 2>&1; then
        MIGRATED=$(jq '.directories | to_entries | map(select(.value.status == "migrated")) | length' config/migration_state.json 2>/dev/null || echo "0")
        TOTAL=$(jq '.directories | length' config/migration_state.json 2>/dev/null || echo "0")
        PENDING=$((TOTAL - MIGRATED))
        PROGRESS=$((MIGRATED * 100 / TOTAL))
        
        echo -e "  ${GREEN}${CHECK} Completado:${NC} ${WHITE}$MIGRATED${NC} ${GRAY}|${NC} ${YELLOW}${BULLET} Pendiente:${NC} ${WHITE}$PENDING${NC} ${GRAY}|${NC} ${BLUE}${STAR} Progreso:${NC} ${WHITE}$PROGRESS%${NC}"
    else
        echo -e "  ${GRAY}Estado disponible (requiere jq para procesar)${NC}"
    fi
else
    echo -e "  ${GRAY}Sin información de estado${NC}"
fi

# Última actualización
if [[ -f "config/migration_state.json" ]] && command -v jq >/dev/null 2>&1; then
    LAST_UPDATE=$(jq -r '.last_updated // ""' config/migration_state.json 2>/dev/null)
    if [[ -n "$LAST_UPDATE" && "$LAST_UPDATE" != "null" ]]; then
        FORMATTED_DATE=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${LAST_UPDATE%.*}" "+%d/%m/%Y %H:%M" 2>/dev/null || echo "$LAST_UPDATE")
        echo -e "\n${CYAN}Última actualización:${NC} ${GRAY}$FORMATTED_DATE${NC}"
    fi
fi

echo -e "\n${BLUE}─────────────────────────────────────────────────────────────${NC}"
echo -e "${GRAY}Para ver detalles completos usa: ${WHITE}disco-estado${NC}"
echo -e "${BLUE}─────────────────────────────────────────────────────────────${NC}\n"
