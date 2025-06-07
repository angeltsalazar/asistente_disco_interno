#!/bin/bash

# Script para mostrar información del sistema de forma amigable
# Colores para mejor presentación
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Símbolos
CHECK="✓"
CROSS="✗"
ARROW="→"
BULLET="•"
STAR="★"

# Función para mostrar títulos con estilo
show_title() {
    echo -e "\n${BLUE}╔$(printf '═%.0s' {1..60})╗${NC}"
    echo -e "${BLUE}║${WHITE}$(printf '%*s' $((30+${#1}/2)) "$1")$(printf '%*s' $((30-${#1}/2)) "")${BLUE}║${NC}"
    echo -e "${BLUE}╚$(printf '═%.0s' {1..60})╝${NC}\n"
}

# Función para mostrar secciones
show_section() {
    echo -e "${CYAN}┌─ $1 $(printf '─%.0s' {1..40})${NC}"
}

# Función para formatear el estado de migración
format_migration_status() {
    local status=$1
    case $status in
        "migrated")
            echo -e "${GREEN}${CHECK} Migrado${NC}"
            ;;
        "not_migrated")
            echo -e "${YELLOW}${BULLET} Pendiente${NC}"
            ;;
        "in_progress")
            echo -e "${BLUE}${ARROW} En proceso${NC}"
            ;;
        *)
            echo -e "${GRAY}${CROSS} Desconocido${NC}"
            ;;
    esac
}

# Función para mostrar información del disco con barras de progreso
show_disk_info() {
    local disk_path=$1
    local disk_name=$2
    
    if [[ -d "$disk_path" ]]; then
        local disk_info=$(df -h "$disk_path" | tail -1)
        local used=$(echo $disk_info | awk '{print $3}')
        local total=$(echo $disk_info | awk '{print $2}')
        local percent=$(echo $disk_info | awk '{print $5}' | sed 's/%//')
        
        # Crear barra de progreso
        local bar_length=30
        local filled=$((percent * bar_length / 100))
        local empty=$((bar_length - filled))
        
        # Color de la barra según el porcentaje
        local bar_color=$GREEN
        if [[ $percent -gt 80 ]]; then
            bar_color=$RED
        elif [[ $percent -gt 60 ]]; then
            bar_color=$YELLOW
        fi
        
        echo -e "  ${GREEN}${CHECK}${NC} ${WHITE}$disk_name${NC}"
        echo -e "    Espacio: ${CYAN}$used${NC} / ${CYAN}$total${NC} (${WHITE}$percent%${NC})"
        echo -e "    ${bar_color}[$(printf '█%.0s' $(seq 1 $filled))$(printf '░%.0s' $(seq 1 $empty))]${NC}"
    else
        echo -e "  ${RED}${CROSS}${NC} ${WHITE}$disk_name${NC} - ${RED}No montado${NC}"
    fi
}

# Función para mostrar resumen de migración
show_migration_summary() {
    local json_file="config/migration_state.json"
    
    if [[ ! -f "$json_file" ]]; then
        echo -e "${RED}${CROSS} No se encontró el archivo de estado${NC}"
        return
    fi
    
    # Contar estados
    local migrated_count=$(jq '.directories | to_entries | map(select(.value.status == "migrated")) | length' "$json_file" 2>/dev/null || echo "0")
    local total_count=$(jq '.directories | length' "$json_file" 2>/dev/null || echo "0")
    local pending_count=$((total_count - migrated_count))
    
    echo -e "  ${GREEN}${CHECK} Migrados:${NC} ${WHITE}$migrated_count${NC}"
    echo -e "  ${YELLOW}${BULLET} Pendientes:${NC} ${WHITE}$pending_count${NC}"
    echo -e "  ${BLUE}${STAR} Total:${NC} ${WHITE}$total_count${NC}"
    
    # Mostrar progreso general
    if [[ $total_count -gt 0 ]]; then
        local progress=$((migrated_count * 100 / total_count))
        local bar_length=20
        local filled=$((progress * bar_length / 100))
        local empty=$((bar_length - filled))
        
        echo -e "  Progreso: ${GREEN}[$(printf '█%.0s' $(seq 1 $filled))$(printf '░%.0s' $(seq 1 $empty))]${NC} ${WHITE}$progress%${NC}"
    fi
}

# Función para mostrar detalles de directorios migrados
show_directory_details() {
    local json_file="config/migration_state.json"
    
    if [[ ! -f "$json_file" ]]; then
        return
    fi
    
    echo -e "\n${CYAN}Detalles de Directorios:${NC}"
    echo -e "${GRAY}$(printf '─%.0s' {1..50})${NC}"
    
    # Usar jq para procesar el JSON si está disponible
    if command -v jq >/dev/null 2>&1; then
        jq -r '.directories | to_entries[] | "\(.key)|\(.value.status)|\(.value.size_before)|\(.value.last_migration)"' "$json_file" 2>/dev/null | while IFS='|' read -r name status size date; do
            local status_formatted=$(format_migration_status "$status")
            local date_formatted=""
            
            if [[ -n "$date" && "$date" != "null" && "$date" != "" ]]; then
                date_formatted=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${date%.*}" "+%d/%m/%Y %H:%M" 2>/dev/null || echo "$date")
            fi
            
            echo -e "  ${WHITE}$name${NC}"
            echo -e "    Estado: $status_formatted"
            [[ -n "$size" && "$size" != "null" && "$size" != "" ]] && echo -e "    Tamaño: ${CYAN}$size${NC}"
            [[ -n "$date_formatted" ]] && echo -e "    Última migración: ${GRAY}$date_formatted${NC}"
            echo ""
        done
    else
        echo -e "  ${YELLOW}${BULLET} jq no disponible - mostrando JSON crudo${NC}"
        cat "$json_file"
    fi
}

# Función para mostrar información del sistema
show_system_info() {
    local machine=$(jq -r '.machine // "Desconocido"' config/migration_state.json 2>/dev/null || echo "Desconocido")
    local last_update=$(jq -r '.last_updated // ""' config/migration_state.json 2>/dev/null || echo "")
    local external_disk=$(jq -r '.external_disk // ""' config/migration_state.json 2>/dev/null || echo "")
    
    if [[ -n "$last_update" && "$last_update" != "null" ]]; then
        last_update=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${last_update%.*}" "+%d/%m/%Y %H:%M" 2>/dev/null || echo "$last_update")
    fi
    
    echo -e "  ${WHITE}Equipo:${NC} ${CYAN}$machine${NC}"
    echo -e "  ${WHITE}Ubicación:${NC} ${GRAY}$(pwd)${NC}"
    echo -e "  ${WHITE}Disco externo:${NC} ${CYAN}$external_disk${NC}"
    [[ -n "$last_update" ]] && echo -e "  ${WHITE}Última actualización:${NC} ${GRAY}$last_update${NC}"
    echo -e "  ${WHITE}Fecha actual:${NC} ${GRAY}$(date '+%d/%m/%Y %H:%M:%S')${NC}"
}

# Función principal
main() {
    clear
    show_title "ASISTENTE DE DISCO INTERNO"
    
    show_section "Información del Sistema"
    show_system_info
    
    echo -e "\n"
    show_section "Estado de Discos"
    show_disk_info "/Volumes/BLACK2T" "BLACK2T (Externo)"
    echo ""
    show_disk_info "/" "Disco Interno"
    
    echo -e "\n"
    show_section "Resumen de Migración"
    show_migration_summary
    
    echo -e "\n"
    show_section "Detalles Completos"
    echo -e "  ${GRAY}Presiona Enter para ver detalles de directorios...${NC}"
    read -r
    show_directory_details
    
    echo -e "\n${BLUE}╔$(printf '═%.0s' {1..60})╗${NC}"
    echo -e "${BLUE}║${WHITE}$(printf '%*s' 32 "Comandos Disponibles")$(printf '%*s' 28 "")${BLUE}║${NC}"
    echo -e "${BLUE}╚$(printf '═%.0s' {1..60})╝${NC}"
    
    echo -e "\n${CYAN}Gestión:${NC}"
    echo -e "  ${WHITE}disco-menu${NC}        - Menú principal"
    echo -e "  ${WHITE}disco-diagnostics${NC}  - Ejecutar diagnósticos"
    echo -e "  ${WHITE}disco-mount${NC}        - Guía de montaje"
    echo -e "  ${WHITE}disco-cleanup${NC}      - Limpiar sistema"
    
    echo -e "\n${CYAN}Información:${NC}"
    echo -e "  ${WHITE}disco-estado${NC}       - Ver este estado"
    echo -e "  ${WHITE}disco-logs${NC}         - Ver registros"
    echo -e "  ${WHITE}disco-docs${NC}         - Ver documentación"
    
    echo -e "\n${GRAY}Presiona Enter para continuar...${NC}"
    read -r
}

# Ejecutar función principal
main
