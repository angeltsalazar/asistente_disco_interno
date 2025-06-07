#!/bin/bash
# Script de monitoreo para aplicaciones en discos externos
# CONFIGURADO PARA: MacMини (sufijo _macmini en directorios)
# Para usar en Mac Studio o Mac Pro, cambiar sufijo en configuración de rutas
# Autor: Script generado para monitoreo de sistema
# Fecha: $(date)

# Función para encontrar el punto de montaje real de un disco
find_real_mount_point() {
    local disk_name="$1"
    
    # Buscar en mount por SMB primero
    local smb_mount=$(mount | grep -i "/$disk_name on" | awk '{print $3}' | head -1)
    if [ -n "$smb_mount" ] && [ -d "$smb_mount" ]; then
        echo "$smb_mount"
        return 0
    fi
    
    # Buscar variaciones del nombre (-1, -2, etc.)
    for suffix in "" "-1" "-2" "-3"; do
        local path="/Volumes/${disk_name}${suffix}"
        if [ -d "$path" ] && [ "$(ls -A "$path" 2>/dev/null)" ]; then
            echo "$path"
            return 0
        fi
    done
    
    return 1
}

# Detectar puntos de montaje reales
BLACK2T_MOUNT=$(find_real_mount_point "BLACK2T")
SERIES8TB_MOUNT=$(find_real_mount_point "8TbSeries")

# Configuración de rutas
EXTERNAL_APPS="${BLACK2T_MOUNT}/Applications_macmini"
BACKUP_APPS="${SERIES8TB_MOUNT}/Applications_macmini"
LOCAL_APPS="/Applications"
LOG_FILE="$HOME/Documents/scripts/monitor_apps_macmini.log"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Función para mostrar uso de disco
show_disk_usage() {
    echo -e "${CYAN}=== ESTADO DE DISCOS ===${NC}"
    echo -e "${BLUE}Disco interno:${NC}"
    df -h / | tail -1 | awk '{printf "  Usado: %s/%s (%s)\n", $3, $2, $5}'
    
    echo -e "${BLUE}Disco BLACK2T:${NC}"
    if [ -n "$BLACK2T_MOUNT" ] && [ -d "$BLACK2T_MOUNT" ]; then
        echo -e "  Montado en: $BLACK2T_MOUNT"
        df -h "$BLACK2T_MOUNT" | tail -1 | awk '{printf "  Usado: %s/%s (%s)\n", $3, $2, $5}'
    else
        echo -e "${RED}  ❌ No montado${NC}"
    fi
    
    echo -e "${BLUE}Disco 8TbSeries:${NC}"
    if [ -n "$SERIES8TB_MOUNT" ] && [ -d "$SERIES8TB_MOUNT" ]; then
        echo -e "  Montado en: $SERIES8TB_MOUNT"
        df -h "$SERIES8TB_MOUNT" | tail -1 | awk '{printf "  Usado: %s/%s (%s)\n", $3, $2, $5}'
    else
        echo -e "${RED}  ❌ No montado${NC}"
    fi
    echo
}

# Función para contar aplicaciones
count_applications() {
    echo -e "${CYAN}=== CONTEO DE APLICACIONES ===${NC}"
    
    local local_apps=$(find "$LOCAL_APPS" -maxdepth 1 -name "*.app" -type d | wc -l)
    local local_links=$(find "$LOCAL_APPS" -maxdepth 1 -name "*.app" -type l | wc -l)
    local external_apps=0
    local backup_apps=0
    
    if [ -d "$EXTERNAL_APPS" ]; then
        external_apps=$(find "$EXTERNAL_APPS" -maxdepth 1 -name "*.app" -type d | wc -l)
    fi
    
    if [ -d "$BACKUP_APPS" ]; then
        backup_apps=$(find "$BACKUP_APPS" -maxdepth 1 -name "*.app" -type d | wc -l)
    fi
    
    echo -e "${BLUE}Aplicaciones en /Applications:${NC} $local_apps (${local_links} enlaces simbólicos)"
    echo -e "${BLUE}Aplicaciones en disco externo:${NC} $external_apps"
    echo -e "${BLUE}Aplicaciones en backup:${NC} $backup_apps"
    echo
}

# Función para verificar salud de enlaces simbólicos
check_symlink_health() {
    echo -e "${CYAN}=== SALUD DE ENLACES SIMBÓLICOS ===${NC}"
    
    local broken_count=0
    local working_count=0
    
    find "$LOCAL_APPS" -maxdepth 1 -name "*.app" -type l | while read symlink; do
        target=$(readlink "$symlink")
        app_name=$(basename "$symlink")
        
        if [ -d "$target" ]; then
            echo -e "${GREEN}✅ $app_name${NC}"
            ((working_count++))
        else
            echo -e "${RED}❌ $app_name -> $target (ROTO)${NC}"
            ((broken_count++))
        fi
    done
    
    echo
}

# Función para mostrar espacio ahorrado
show_space_saved() {
    echo -e "${CYAN}=== ESPACIO AHORRADO ===${NC}"
    
    if [ -d "$EXTERNAL_APPS" ]; then
        local space_moved=$(du -sh "$EXTERNAL_APPS" 2>/dev/null | cut -f1)
        echo -e "${GREEN}Espacio movido al disco externo: $space_moved${NC}"
    else
        echo -e "${YELLOW}No hay aplicaciones en disco externo${NC}"
    fi
    
    if [ -d "$BACKUP_APPS" ]; then
        local backup_space=$(du -sh "$BACKUP_APPS" 2>/dev/null | cut -f1)
        echo -e "${BLUE}Espacio usado en backups: $backup_space${NC}"
    fi
    echo
}

# Función para verificar conectividad de discos
check_disk_connectivity() {
    echo -e "${CYAN}=== CONECTIVIDAD DE DISCOS ===${NC}"
    
    # Verificar BLACK2T
    if [ -d "/Volumes/BLACK2T" ]; then
        if [ -w "/Volumes/BLACK2T" ]; then
            echo -e "${GREEN}✅ BLACK2T: Montado y escribible${NC}"
        else
            echo -e "${YELLOW}⚠️  BLACK2T: Montado pero no escribible${NC}"
        fi
    else
        echo -e "${RED}❌ BLACK2T: No montado${NC}"
    fi
    
    # Verificar 8TbSeries
    if [ -d "/Volumes/8TbSeries" ]; then
        if [ -w "/Volumes/8TbSeries" ]; then
            echo -e "${GREEN}✅ 8TbSeries: Montado y escribible${NC}"
        else
            echo -e "${YELLOW}⚠️  8TbSeries: Montado pero no escribible${NC}"
        fi
    else
        echo -e "${RED}❌ 8TbSeries: No montado${NC}"
    fi
    echo
}

# Función para listar aplicaciones grandes en /Applications
list_large_apps() {
    echo -e "${CYAN}=== APLICACIONES GRANDES EN /APPLICATIONS ===${NC}"
    echo -e "${BLUE}(Candidatas para mover)${NC}"
    
    find "$LOCAL_APPS" -maxdepth 1 -name "*.app" -type d -exec du -sh {} \; 2>/dev/null | \
    sort -hr | head -10 | while read size app; do
        app_name=$(basename "$app")
        # Verificar si no es un enlace simbólico
        if [ ! -L "$LOCAL_APPS/$app_name" ]; then
            echo -e "${YELLOW}  $size - $app_name${NC}"
        fi
    done
    echo
}

# Función para generar reporte completo
generate_report() {
    local report_file="$HOME/Documents/scripts/app_status_report_$(date +%Y%m%d_%H%M%S).txt"
    
    echo "Generando reporte completo..."
    {
        echo "=== REPORTE DE ESTADO DE APLICACIONES ==="
        echo "Fecha: $(date)"
        echo
        show_disk_usage
        count_applications
        check_symlink_health
        show_space_saved
        check_disk_connectivity
        list_large_apps
    } > "$report_file"
    
    echo -e "${GREEN}✅ Reporte guardado en: $report_file${NC}"
}

# Función principal
main() {
    clear
    echo -e "${BLUE}=== MONITOR DE APLICACIONES EXTERNAS ===${NC}"
    echo -e "${BLUE}Fecha: $(date)${NC}"
    echo
    
    echo -e "${YELLOW}¿Qué información quieres ver?${NC}"
    echo "1. Estado de discos"
    echo "2. Conteo de aplicaciones"
    echo "3. Salud de enlaces simbólicos"
    echo "4. Espacio ahorrado"
    echo "5. Aplicaciones grandes (candidatas a mover)"
    echo "6. Reporte completo en pantalla"
    echo "7. Generar reporte en archivo"
    echo "8. Monitoreo continuo"
    echo "9. Salir"
    
    read -p "Selecciona una opción (1-9): " choice
    
    case $choice in
        1) show_disk_usage ;;
        2) count_applications ;;
        3) check_symlink_health ;;
        4) show_space_saved ;;
        5) list_large_apps ;;
        6) 
            show_disk_usage
            count_applications
            check_symlink_health
            show_space_saved
            check_disk_connectivity
            list_large_apps
            ;;
        7) generate_report ;;
        8)
            echo -e "${BLUE}Monitoreo continuo activado. Presiona Ctrl+C para salir.${NC}"
            while true; do
                clear
                echo -e "${BLUE}=== MONITOREO CONTINUO - $(date) ===${NC}"
                check_disk_connectivity
                check_symlink_health
                sleep 30
            done
            ;;
        9) 
            echo -e "${BLUE}Saliendo del monitor...${NC}"
            exit 0
            ;;
        *) 
            echo -e "${RED}Opción inválida${NC}"
            exit 1
            ;;
    esac
    
    echo
    read -p "Presiona Enter para continuar..." -r
    main
}

# Ejecutar función principal
main "$@"
