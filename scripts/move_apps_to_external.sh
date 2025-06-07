#!/bin/bash
# Script para mover aplicaciones de /Applications a disco externo
# CONFIGURADO PARA: MacMini (sufijo _macmini en directorios)
# Para usar en Mac Studio o Mac Pro, cambiar sufijo en configuración de rutas
# Autor: Script generado para gestión de espacio en disco
# Fecha: $(date)

set -e  # Salir si hay algún error

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
LOG_FILE="$HOME/Documents/scripts/move_apps_macmini.log"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para logging
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo -e "$1"
}

# Verificar que los discos externos están montados
check_disks() {
    log_message "${BLUE}Verificando discos externos...${NC}"
    
    echo -e "${BLUE}✅ Discos detectados:${NC}"
    echo -e "${BLUE}   BLACK2T: $BLACK2T_MOUNT${NC}"
    echo -e "${BLUE}   8TbSeries: $SERIES8TB_MOUNT${NC}"
    
    log_message "${GREEN}✅ Ambos discos externos están montados${NC}"
}

# Crear directorios necesarios
setup_directories() {
    log_message "${BLUE}Creando directorios...${NC}"
    
    mkdir -p "$EXTERNAL_APPS"
    mkdir -p "$BACKUP_APPS"
    
    log_message "${GREEN}✅ Directorios creados${NC}"
}

# Crear backup de la aplicación
backup_app() {
    local app_name="$1"
    log_message "${BLUE}Creando backup de $app_name...${NC}"
    
    if [ ! -d "$BACKUP_APPS/$app_name" ]; then
        sudo rsync -av "$LOCAL_APPS/$app_name" "$BACKUP_APPS/" 2>/dev/null
        if [ $? -eq 0 ]; then
            log_message "${GREEN}✅ Backup de $app_name creado${NC}"
        else
            log_message "${RED}❌ Error creando backup de $app_name${NC}"
            return 1
        fi
    else
        log_message "${YELLOW}⚠️  Backup de $app_name ya existe${NC}"
    fi
}

# Mover aplicación y crear enlace simbólico
move_app() {
    local app_name="$1"
    
    if [ ! -d "$LOCAL_APPS/$app_name" ]; then
        log_message "${YELLOW}⚠️  $app_name no encontrada en $LOCAL_APPS${NC}"
        return 1
    fi
    
    # Verificar si ya está movida
    if [ -L "$LOCAL_APPS/$app_name" ]; then
        log_message "${YELLOW}⚠️  $app_name ya es un enlace simbólico${NC}"
        return 0
    fi
    
    log_message "${BLUE}Procesando $app_name...${NC}"
    
    # Crear backup
    if ! backup_app "$app_name"; then
        return 1
    fi
    
    # Mover la aplicación
    log_message "${BLUE}Moviendo $app_name al disco externo...${NC}"
    sudo mv "$LOCAL_APPS/$app_name" "$EXTERNAL_APPS/"
    
    if [ $? -eq 0 ]; then
        # Crear enlace simbólico
        sudo ln -s "$EXTERNAL_APPS/$app_name" "$LOCAL_APPS/$app_name"
        
        if [ $? -eq 0 ]; then
            log_message "${GREEN}✅ $app_name movida y enlazada exitosamente${NC}"
            
            # Verificar que el enlace funciona
            if [ -d "$LOCAL_APPS/$app_name" ]; then
                log_message "${GREEN}✅ Enlace simbólico verificado${NC}"
            else
                log_message "${RED}❌ Error: Enlace simbólico no funciona${NC}"
            fi
        else
            log_message "${RED}❌ Error creando enlace simbólico para $app_name${NC}"
            # Intentar restaurar
            sudo mv "$EXTERNAL_APPS/$app_name" "$LOCAL_APPS/"
            return 1
        fi
    else
        log_message "${RED}❌ Error moviendo $app_name${NC}"
        return 1
    fi
}

# Lista de aplicaciones recomendadas para mover (aplicaciones grandes/poco críticas)
RECOMMENDED_APPS=(
    "Adobe Creative Cloud"
    "Adobe Photoshop 2024"
    "Adobe Illustrator 2024"
    "Adobe Premiere Pro 2024"
    "Adobe After Effects 2024"
    "Final Cut Pro"
    "Logic Pro"
    "Xcode"
    "Unity"
    "Blender"
    "Steam"
    "Epic Games Launcher"
    "Microsoft Office"
    "VirtualBox"
    "VMware Fusion"
    "Parallels Desktop"
    "DaVinci Resolve"
    "OmniGraffle 7"
    "Sketch"
    "Figma"
)

# Función principal
main() {
    log_message "${BLUE}=== Iniciando proceso de movimiento de aplicaciones ===${NC}"
    log_message "${BLUE}Disco destino: $EXTERNAL_APPS${NC}"
    log_message "${BLUE}Disco backup: $BACKUP_APPS${NC}"
    
    check_disks
    setup_directories
    
    echo -e "${YELLOW}Aplicaciones recomendadas para mover:${NC}"
    for i in "${!RECOMMENDED_APPS[@]}"; do
        echo "$((i+1)). ${RECOMMENDED_APPS[$i]}"
    done
    
    echo -e "\n${YELLOW}¿Qué quieres hacer?${NC}"
    echo "1. Mover aplicaciones de la lista recomendada"
    echo "2. Mover una aplicación específica"
    echo "3. Ver aplicaciones actuales"
    echo "4. Salir"
    
    read -p "Selecciona una opción (1-4): " choice
    
    case $choice in
        1)
            echo -e "\n${BLUE}Aplicaciones disponibles para mover:${NC}"
            available_apps=()
            for app in "${RECOMMENDED_APPS[@]}"; do
                if [ -d "$LOCAL_APPS/$app.app" ] && [ ! -L "$LOCAL_APPS/$app.app" ]; then
                    available_apps+=("$app.app")
                    echo "- $app.app"
                fi
            done
            
            if [ ${#available_apps[@]} -eq 0 ]; then
                log_message "${YELLOW}No hay aplicaciones recomendadas disponibles para mover${NC}"
                exit 0
            fi
            
            read -p "¿Mover todas las aplicaciones listadas? (y/N): " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                for app in "${available_apps[@]}"; do
                    move_app "$app"
                done
            fi
            ;;
        2)
            read -p "Nombre de la aplicación (sin .app): " app_name
            move_app "$app_name.app"
            ;;
        3)
            echo -e "\n${BLUE}Aplicaciones en /Applications:${NC}"
            ls -la "$LOCAL_APPS" | grep "^d" | awk '{print $9}' | grep -v "^\.$\|^\.\.$"
            ;;
        4)
            log_message "${BLUE}Saliendo...${NC}"
            exit 0
            ;;
        *)
            log_message "${RED}Opción inválida${NC}"
            exit 1
            ;;
    esac
    
    log_message "${GREEN}=== Proceso completado ===${NC}"
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
