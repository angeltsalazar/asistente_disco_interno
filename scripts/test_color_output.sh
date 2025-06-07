#!/bin/bash
# Script de prueba para verificar que los colores se muestran correctamente

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_FILE="/tmp/test_colors.log"

# Función para logging corregida
log_message() {
    local message="$1"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    
    # Mostrar en terminal con colores
    echo -e "$timestamp - $message"
    
    # Guardar en log sin códigos de color
    local clean_message=$(echo -e "$message" | sed 's/\x1b\[[0-9;]*m//g')
    echo "$timestamp - $clean_message" >> "$LOG_FILE"
}

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    PRUEBA DE COLORES                        ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

echo -e "${BLUE}📊 TESTEO DE COLORES:${NC}"
log_message "${RED}❌ Este texto debería verse en ROJO${NC}"
log_message "${GREEN}✅ Este texto debería verse en VERDE${NC}"
log_message "${YELLOW}⚠️ Este texto debería verse en AMARILLO${NC}"
log_message "${BLUE}🔵 Este texto debería verse en AZUL${NC}"
log_message "${CYAN}🔷 Este texto debería verse en CIAN${NC}"

echo
echo -e "${GREEN}✅ Prueba completada. Revisa que los colores se vean correctamente.${NC}"
echo -e "${BLUE}📄 Log guardado en: $LOG_FILE${NC}"
echo -e "${CYAN}Para ver el log sin colores: cat $LOG_FILE${NC}"
