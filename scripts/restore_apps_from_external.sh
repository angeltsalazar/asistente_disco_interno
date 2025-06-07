#!/bin/bash
# Script para restaurar aplicaciones desde disco externo a /Applications
# CONFIGURADO PARA: MacMini (sufijo _macmini en directorios)
# Para usar en Mac Studio o Mac Pro, cambiar sufijo en configuración de rutas
# Autor: Script generado para gestión de aplicaciones
# Fecha: $(date)

set -e

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

# Validar que los discos estén montados
if [ -z "$BLACK2T_MOUNT" ]; then
    echo -e "${RED}❌ Error: Disco BLACK2T no está montado correctamente${NC}"
    exit 1
fi

if [ -z "$SERIES8TB_MOUNT" ]; then
    echo -e "${RED}❌ Error: Disco 8TbSeries no está montado correctamente${NC}"
    exit 1
fi

# Configuración de rutas
EXTERNAL_APPS="${BLACK2T_MOUNT}/Applications_macmini"
BACKUP_APPS="${SERIES8TB_MOUNT}/Applications_macmini"
LOCAL_APPS="/Applications"
LOG_FILE="$HOME/Documents/scripts/restore_apps_macmini.log"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Función para logging
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo -e "$1"
}

# Restaurar aplicación desde backup
restore_app() {
    local app_name="$1"
    
    log_message "${BLUE}Restaurando $app_name...${NC}"
    
    # Verificar que existe el backup
    if [ ! -d "$BACKUP_APPS/$app_name" ]; then
        log_message "${RED}❌ No se encontró backup de $app_name${NC}"
        return 1
    fi
    
    # Eliminar enlace simbólico si existe
    if [ -L "$LOCAL_APPS/$app_name" ]; then
        sudo rm "$LOCAL_APPS/$app_name"
        log_message "${BLUE}Enlace simbólico eliminado${NC}"
    fi
    
    # Eliminar aplicación del disco externo si existe
    if [ -d "$EXTERNAL_APPS/$app_name" ]; then
        sudo rm -rf "$EXTERNAL_APPS/$app_name"
        log_message "${BLUE}Aplicación eliminada del disco externo${NC}"
    fi
    
    # Restaurar desde backup
    sudo cp -R "$BACKUP_APPS/$app_name" "$LOCAL_APPS/"
    
    if [ $? -eq 0 ]; then
        log_message "${GREEN}✅ $app_name restaurada exitosamente${NC}"
    else
        log_message "${RED}❌ Error restaurando $app_name${NC}"
        return 1
    fi
}

# Listar aplicaciones movidas
list_moved_apps() {
    log_message "${BLUE}Aplicaciones movidas al disco externo:${NC}"
    
    if [ -d "$EXTERNAL_APPS" ]; then
        for app in "$EXTERNAL_APPS"/*.app; do
            if [ -d "$app" ]; then
                app_name=$(basename "$app")
                echo "- $app_name"
            fi
        done
    else
        log_message "${YELLOW}No se encontró el directorio de aplicaciones externas${NC}"
    fi
}

# Verificar estado de aplicaciones
check_app_status() {
    log_message "${BLUE}Verificando estado de aplicaciones...${NC}"
    
    echo -e "${BLUE}Enlaces simbólicos en /Applications:${NC}"
    find "$LOCAL_APPS" -type l -name "*.app" | while read link; do
        app_name=$(basename "$link")
        target=$(readlink "$link")
        if [ -d "$target" ]; then
            echo -e "${GREEN}✅ $app_name -> $target${NC}"
        else
            echo -e "${RED}❌ $app_name -> $target (ROTO)${NC}"
        fi
    done
}

# Función principal
main() {
    log_message "${BLUE}=== Script de restauración de aplicaciones ===${NC}"
    
    echo -e "${YELLOW}¿Qué quieres hacer?${NC}"
    echo "1. Listar aplicaciones movidas"
    echo "2. Verificar estado de enlaces simbólicos"
    echo "3. Restaurar una aplicación específica"
    echo "4. Restaurar todas las aplicaciones"
    echo "5. Salir"
    
    read -p "Selecciona una opción (1-5): " choice
    
    case $choice in
        1)
            list_moved_apps
            ;;
        2)
            check_app_status
            ;;
        3)
            read -p "Nombre de la aplicación a restaurar (con .app): " app_name
            restore_app "$app_name"
            ;;
        4)
            echo -e "${RED}⚠️  ADVERTENCIA: Esto restaurará TODAS las aplicaciones${NC}"
            read -p "¿Estás seguro? (y/N): " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                if [ -d "$EXTERNAL_APPS" ]; then
                    for app in "$EXTERNAL_APPS"/*.app; do
                        if [ -d "$app" ]; then
                            app_name=$(basename "$app")
                            restore_app "$app_name"
                        fi
                    done
                fi
            fi
            ;;
        5)
            log_message "${BLUE}Saliendo...${NC}"
            exit 0
            ;;
        *)
            log_message "${RED}Opción inválida${NC}"
            exit 1
            ;;
    esac
}

# Verificar permisos de administrador
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Este script requiere permisos de administrador${NC}"
    echo "Ejecutando con sudo..."
    sudo "$0" "$@"
    exit $?
fi

# Ejecutar función principal
main "$@"
