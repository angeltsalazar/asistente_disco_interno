#!/bin/bash

# Script para mostrar el menú completo de comandos disponibles
# Creado: 06/06/2025

# Colores para mejor visualización
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Función para mostrar el header
show_header() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}          ASISTENTE DE DISCO INTERNO - COMANDOS            ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Función para mostrar comandos de navegación
show_navigation_commands() {
    echo -e "${YELLOW}┌─ Comandos de Navegación ──────────────────────────────────────${NC}"
    echo -e "${GREEN}  asistente-disco${NC}  - 📁 Ir al directorio principal del asistente"
    echo -e "${GREEN}  disco-scripts${NC}    - 📄 Ir al directorio de scripts"
    echo -e "${GREEN}  disco-logs${NC}       - 📋 Ir al directorio de logs"
    echo -e "${GREEN}  disco-docs${NC}       - 📚 Ir al directorio de documentación"
    echo ""
}

# Función para mostrar comandos de información
show_info_commands() {
    echo -e "${YELLOW}┌─ Comandos de Información ─────────────────────────────────────${NC}"
    echo -e "${BLUE}  disco-estado${NC}     - 📊 Ver estado completo del sistema"
    echo -e "${BLUE}  disco-resumen${NC}    - 📈 Ver resumen compacto del sistema"
    echo -e "${BLUE}  disco-estado-raw${NC} - 💾 Ver datos JSON sin procesar"
    echo ""
}

# Función para mostrar comandos de gestión
show_management_commands() {
    echo -e "${YELLOW}┌─ Comandos de Gestión ─────────────────────────────────────────${NC}"
    echo -e "${PURPLE}  disco-menu${NC}       - 🎯 Abrir menú principal interactivo"
    echo -e "${PURPLE}  disco-diagnostics${NC} - 🔍 Ejecutar diagnósticos del sistema"
    echo -e "${PURPLE}  disco-mount${NC}      - 💿 Guía de montaje de discos"
    echo -e "${PURPLE}  disco-permissions${NC} - 🔐 Diagnóstico de permisos"
    echo -e "${PURPLE}  disco-cleanup${NC}    - 🧹 Limpiar cachés del sistema"
    echo ""
}

# Función para mostrar comandos adicionales
show_additional_commands() {
    echo -e "${YELLOW}┌─ Comandos Adicionales ────────────────────────────────────────${NC}"
    echo -e "${WHITE}  disco-help${NC}       - ❓ Mostrar este menú de ayuda"
    echo -e "${WHITE}  disco-comandos${NC}   - 📋 Alias para mostrar este menú"
    echo ""
}

# Función para mostrar ejemplos de uso
show_examples() {
    echo -e "${YELLOW}┌─ Ejemplos de Uso ─────────────────────────────────────────────${NC}"
    echo -e "${CYAN}  # Ver estado del sistema:${NC}"
    echo -e "  ${GREEN}disco-estado${NC}"
    echo ""
    echo -e "${CYAN}  # Abrir menú principal:${NC}"
    echo -e "  ${PURPLE}disco-menu${NC}"
    echo ""
    echo -e "${CYAN}  # Navegar a scripts y ejecutar uno:${NC}"
    echo -e "  ${GREEN}disco-scripts${NC}"
    echo -e "  ./damage_assessment.sh"
    echo ""
    echo -e "${CYAN}  # Ver logs recientes:${NC}"
    echo -e "  ${GREEN}disco-logs${NC}"
    echo -e "  ls -la *.log"
    echo ""
}

# Función para mostrar footer
show_footer() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}    Para recargar aliases: source aliases.sh               ${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}    Para más ayuda: disco-menu → Opción 12 (Ayuda)         ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Función principal
main() {
    show_header
    show_navigation_commands
    show_info_commands
    show_management_commands
    show_additional_commands
    show_examples
    show_footer
    
    # Verificar si los aliases están cargados
    if ! command -v disco-estado &> /dev/null; then
        echo -e "${RED}⚠️  AVISO: Los aliases no están cargados en esta sesión.${NC}"
        echo -e "${YELLOW}   Ejecuta: ${WHITE}source aliases.sh${NC}"
        echo ""
    fi
}

# Ejecutar función principal
main
