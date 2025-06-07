#!/bin/bash
# Demo completa del sistema de migración automatizado
# Demuestra todas las funcionalidades integradas

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/machine_config.sh"
source "$SCRIPT_DIR/migration_state.sh"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                              ║${NC}"
echo -e "${CYAN}║    DEMO COMPLETA DEL SISTEMA DE MIGRACIÓN AUTOMATIZADO      ║${NC}"
echo -e "${CYAN}║                                                              ║${NC}"
echo -e "${CYAN}║   Sistema inteligente con estado, sincronización y backup   ║${NC}"
echo -e "${CYAN}║                                                              ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

echo -e "${BLUE}✨ CARACTERÍSTICAS PRINCIPALES:${NC}"
echo -e "  🔄 ${GREEN}Estado automatizado${NC} - Sabe qué está migrado"
echo -e "  🔍 ${GREEN}Detección inteligente${NC} - Detecta cambios automáticamente"  
echo -e "  🔗 ${GREEN}Verificación de enlaces${NC} - Corrige enlaces rotos"
echo -e "  📊 ${GREEN}Seguimiento completo${NC} - Historial de todas las migraciones"
echo -e "  ⚡ ${GREEN}Sincronización automática${NC} - Mantiene actualizado"
echo -e "  💾 ${GREEN}Backups automáticos${NC} - Protege tus datos"
echo

echo -e "${YELLOW}=== ESTADO ACTUAL DEL SISTEMA ===${NC}"
if [ -f "$STATE_FILE" ]; then
    show_migration_status
else
    echo -e "${BLUE}Sistema de estado no inicializado. Inicializando...${NC}"
    create_initial_state
    echo -e "${GREEN}✅ Sistema inicializado${NC}"
fi

echo

echo -e "${YELLOW}=== EJEMPLOS DE USO ===${NC}"

echo -e "${PURPLE}1. Verificar estado de un directorio específico:${NC}"
echo -e "${BLUE}   get_directory_status 'Documents'${NC}"
echo -e "   Resultado: $(get_directory_status 'Documents')"
echo

echo -e "${PURPLE}2. Verificar si necesita actualización:${NC}"
echo -e "${BLUE}   check_needs_update 'Documents'${NC}"
if check_needs_update 'Documents'; then
    echo -e "   Resultado: ${YELLOW}Necesita actualización${NC}"
else
    echo -e "   Resultado: ${GREEN}Actualizado${NC}"
fi
echo

echo -e "${PURPLE}3. Flujo de trabajo automatizado en move_user_content.sh:${NC}"
echo -e "${BLUE}   • Al ejecutar migración, automáticamente:${NC}"
echo -e "     1. Verifica estado actual"
echo -e "     2. Detecta si ya está migrado"
echo -e "     3. Sincroniza si hay cambios"
echo -e "     4. Actualiza registro de estado"
echo -e "     5. Verifica integridad de enlaces"
echo

echo -e "${YELLOW}=== ARCHIVOS DEL SISTEMA ===${NC}"
echo -e "${BLUE}📁 Archivo de estado:${NC} $STATE_FILE"
if [ -f "$STATE_FILE" ]; then
    echo -e "   ${GREEN}✅ Existe${NC} ($(ls -lh "$STATE_FILE" | awk '{print $5}'))"
    echo -e "   ${BLUE}Última actualización:${NC} $(python3 -c "
import json
try:
    with open('$STATE_FILE', 'r') as f:
        data = json.load(f)
    print(data['last_updated'])
except:
    print('Desconocido')
")"
else
    echo -e "   ${RED}❌ No existe${NC}"
fi

echo
echo -e "${BLUE}📁 Archivos de log:${NC}"
for log in "$HOME/Documents/scripts"/*.log; do
    if [ -f "$log" ]; then
        echo -e "   ${GREEN}✅ $(basename "$log")${NC} ($(ls -lh "$log" | awk '{print $5}'))"
    fi
done

echo
echo -e "${YELLOW}=== COMANDOS ÚTILES ===${NC}"
echo -e "${PURPLE}Ver estado completo:${NC}"
echo -e "  ${BLUE}source migration_state.sh && show_migration_status${NC}"
echo
echo -e "${PURPLE}Ejecutar migración con estado:${NC}"
echo -e "  ${BLUE}./move_user_content.sh${NC}"
echo
echo -e "${PURPLE}Menú principal:${NC}"
echo -e "  ${BLUE}./app_manager_master.sh${NC}"
echo -e "  ${BLUE}(Opción 9: Ver estado detallado de migración)${NC}"

echo
echo -e "${GREEN}🎉 El sistema está listo para usar con todas las funcionalidades automatizadas${NC}"
echo -e "${BLUE}💡 Tip: Todas las migraciones ahora incluyen seguimiento automático de estado${NC}"
