#!/bin/bash
# Script de gestión de datos de usuario - VERSIÓN SOLO BLACK2T
# Usa solo BLACK2T cuando 8TbSeries no tiene permisos de escritura
# Autor: Script modificado para solucionar problema de permisos
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

# Validar que BLACK2T esté montado y sea escribible
if [ -z "$BLACK2T_MOUNT" ]; then
    echo -e "\033[0;31m❌ Error: Disco BLACK2T no está montado correctamente\033[0m"
    exit 1
fi

if [ ! -w "$BLACK2T_MOUNT" ]; then
    echo -e "\033[0;31m❌ Error: No tienes permisos de escritura en BLACK2T\033[0m"
    exit 1
fi

# Configuración de rutas - TODO EN BLACK2T
EXTERNAL_USER_DATA="${BLACK2T_MOUNT}/UserData_$(whoami)_macmini"
BACKUP_USER_DATA="${BLACK2T_MOUNT}/UserData_$(whoami)_backup_macmini"  # ¡CAMBIO PRINCIPAL!
LOG_FILE="$HOME/Documents/scripts/user_data_move_macmini.log"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Directorios de usuario seguros para mover
USER_DIRECTORIES=(
    "Downloads"
    "Documents/Adobe"
    "Documents/Unity Projects"
    "Documents/Xcode Projects" 
    "Documents/Virtual Machines"
    "Movies"
    "Music/Logic"
    "Music/GarageBand"
    "Pictures/Photos Library.photoslibrary"
    "Library/Application Support/Steam"
    "Library/Application Support/Adobe"
    "Library/Application Support/Unity"
    "Library/Containers/com.docker.docker"
)

# Directorios CRÍTICOS que NUNCA se deben mover
CRITICAL_USER_DIRS=(
    "Library/Keychains"
    "Library/Preferences"
    "Library/LaunchAgents"
    "Library/Services"
    ".ssh"
    ".gnupg"
    "Desktop"
    "Applications" # Aplicaciones del usuario
)

# Función para logging
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo -e "$1"
}

# Verificar que es seguro mover un directorio
is_safe_to_move() {
    local dir_path="$1"
    local dir_name=$(basename "$dir_path")
    
    # Verificar contra lista de críticos
    for critical_dir in "${CRITICAL_USER_DIRS[@]}"; do
        if [[ "$dir_path" == *"$critical_dir"* ]]; then
            return 1  # No es seguro
        fi
    done
    
    # Verificar que no sea un directorio de sistema
    if [[ "$dir_path" == *.localized ]] || [[ "$dir_path" == .* ]]; then
        return 1  # No es seguro
    fi
    
    return 0  # Es seguro
}

# Crear estructura en disco externo
setup_external_structure() {
    log_message "${BLUE}Creando estructura en BLACK2T (modo solo-BLACK2T)...${NC}"
    
    mkdir -p "$EXTERNAL_USER_DATA"
    mkdir -p "$BACKUP_USER_DATA"
    
    # Crear subdirectorios principales
    mkdir -p "$EXTERNAL_USER_DATA/Downloads"
    mkdir -p "$EXTERNAL_USER_DATA/Documents"
    mkdir -p "$EXTERNAL_USER_DATA/Media/Movies"
    mkdir -p "$EXTERNAL_USER_DATA/Media/Music"
    mkdir -p "$EXTERNAL_USER_DATA/Media/Pictures"
    mkdir -p "$EXTERNAL_USER_DATA/ApplicationData"
    
    log_message "${GREEN}✅ Estructura creada en BLACK2T${NC}"
    log_message "${YELLOW}⚠️  NOTA: Usando BLACK2T para datos Y backups (8TbSeries no escribible)${NC}"
}

# Mover directorio de usuario de manera segura
move_user_directory() {
    local source_path="$1"
    local relative_path="$2"  # Ruta relativa desde HOME
    
    if [ ! -d "$source_path" ]; then
        log_message "${YELLOW}⚠️  $source_path no existe${NC}"
        return 1
    fi
    
    # Verificar seguridad
    if ! is_safe_to_move "$source_path"; then
        log_message "${RED}🚫 $source_path es crítico - NO MOVER${NC}"
        return 1
    fi
    
    local dir_size=$(du -sh "$source_path" 2>/dev/null | cut -f1)
    log_message "${BLUE}Moviendo $relative_path ($dir_size)...${NC}"
    
    # Crear backup en BLACK2T
    log_message "${BLUE}Creando backup en BLACK2T...${NC}"
    rsync -av "$source_path/" "$BACKUP_USER_DATA/$relative_path/" 2>/dev/null
    
    if [ $? -ne 0 ]; then
        log_message "${RED}❌ Error creando backup${NC}"
        return 1
    fi
    
    # Mover al disco externo
    local target_path="$EXTERNAL_USER_DATA/$relative_path"
    mkdir -p "$(dirname "$target_path")"
    
    mv "$source_path" "$target_path"
    
    if [ $? -eq 0 ]; then
        # Crear enlace simbólico
        ln -s "$target_path" "$source_path"
        
        if [ $? -eq 0 ]; then
            log_message "${GREEN}✅ $relative_path movido y enlazado exitosamente${NC}"
        else
            log_message "${RED}❌ Error creando enlace simbólico${NC}"
            # Restaurar
            mv "$target_path" "$source_path"
            return 1
        fi
    else
        log_message "${RED}❌ Error moviendo $relative_path${NC}"
        return 1
    fi
}

# Mover Downloads de manera inteligente
move_downloads_smart() {
    log_message "${CYAN}=== MOVIMIENTO INTELIGENTE DE DOWNLOADS ===${NC}"
    
    if [ ! -d "$HOME/Downloads" ]; then
        log_message "${YELLOW}⚠️  Directorio Downloads no existe${NC}"
        return
    fi
    
    local downloads_size=$(du -sh "$HOME/Downloads" 2>/dev/null | cut -f1)
    local file_count=$(find "$HOME/Downloads" -type f | wc -l)
    
    echo -e "${BLUE}Downloads actual: $downloads_size ($file_count archivos)${NC}"
    
    # Analizar tipos de archivos
    echo -e "\n${YELLOW}Tipos de archivos en Downloads:${NC}"
    find "$HOME/Downloads" -type f -name "*.*" | sed 's/.*\.//' | sort | uniq -c | sort -nr | head -10
    
    echo -e "\n${YELLOW}Archivos más grandes:${NC}"
    find "$HOME/Downloads" -type f -exec du -sh {} \; 2>/dev/null | sort -hr | head -10
    
    read -p "¿Mover todo el directorio Downloads? (y/N): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        move_user_directory "$HOME/Downloads" "Downloads"
    else
        # Ofrecer limpieza selectiva
        echo -e "\n${BLUE}Opciones de limpieza selectiva:${NC}"
        echo "1. Eliminar archivos de más de 30 días"
        echo "2. Mover solo archivos grandes (>100MB)"
        echo "3. Cancelar"
        
        read -p "Selecciona opción: " clean_option
        case $clean_option in
            1)
                find "$HOME/Downloads" -type f -mtime +30 -delete 2>/dev/null
                log_message "${GREEN}✅ Archivos antiguos eliminados${NC}"
                ;;
            2)
                mkdir -p "$EXTERNAL_USER_DATA/Downloads/LargeFiles"
                find "$HOME/Downloads" -type f -size +100M -exec mv {} "$EXTERNAL_USER_DATA/Downloads/LargeFiles/" \;
                log_message "${GREEN}✅ Archivos grandes movidos${NC}"
                ;;
            3)
                log_message "${BLUE}Operación cancelada${NC}"
                ;;
        esac
    fi
}

# Gestionar bibliotecas de medios
move_media_libraries() {
    log_message "${CYAN}=== GESTIÓN DE BIBLIOTECAS DE MEDIOS ===${NC}"
    
    # Fotos
    if [ -d "$HOME/Pictures/Photos Library.photoslibrary" ]; then
        local photos_size=$(du -sh "$HOME/Pictures/Photos Library.photoslibrary" 2>/dev/null | cut -f1)
        echo -e "${BLUE}Biblioteca de Fotos: $photos_size${NC}"
        
        read -p "¿Mover biblioteca de Fotos? (y/N): " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            move_user_directory "$HOME/Pictures/Photos Library.photoslibrary" "Media/Pictures/Photos Library.photoslibrary"
        fi
    fi
    
    # Música de Logic Pro
    if [ -d "$HOME/Music/Logic" ]; then
        local logic_size=$(du -sh "$HOME/Music/Logic" 2>/dev/null | cut -f1)
        echo -e "${BLUE}Proyectos de Logic Pro: $logic_size${NC}"
        
        read -p "¿Mover proyectos de Logic Pro? (y/N): " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            move_user_directory "$HOME/Music/Logic" "Media/Music/Logic"
        fi
    fi
    
    # Movies
    if [ -d "$HOME/Movies" ] && [ "$(ls -A "$HOME/Movies")" ]; then
        local movies_size=$(du -sh "$HOME/Movies" 2>/dev/null | cut -f1)
        echo -e "${BLUE}Películas: $movies_size${NC}"
        
        read -p "¿Mover directorio Movies? (y/N): " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            move_user_directory "$HOME/Movies" "Media/Movies"
        fi
    fi
}

# Función principal
main() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                              ║${NC}"
    echo -e "${CYAN}║        ${YELLOW}GESTIÓN SEGURA DE DATOS DE USUARIO${CYAN}                ║${NC}"
    echo -e "${CYAN}║                                                              ║${NC}"
    echo -e "${CYAN}║  ${GREEN}Mueve datos grandes manteniendo funcionalidad${CYAN}           ║${NC}"
    echo -e "${CYAN}║                                                              ║${NC}"
    echo -e "${CYAN}║  ${YELLOW}MODO: SOLO BLACK2T (8TbSeries no escribible)${CYAN}           ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # Verificar discos
    if [ ! -d "$BLACK2T_MOUNT" ]; then
        log_message "${RED}❌ Disco BLACK2T no disponible${NC}"
        exit 1
    fi
    
    log_message "${GREEN}✅ BLACK2T disponible: $BLACK2T_MOUNT${NC}"
    log_message "${YELLOW}⚠️  8TbSeries: No disponible para escritura - usando BLACK2T para backups${NC}"
    
    setup_external_structure
    
    echo -e "${YELLOW}¿Qué quieres hacer?${NC}"
    echo "1. 📥 Gestionar Downloads de manera inteligente"
    echo "2. 🎵 Mover bibliotecas de medios (Fotos, Música, Videos)"
    echo "3. 📁 Mover directorio específico"
    echo "4. 🔍 Ver directorios ya movidos"
    echo "5. 📋 Generar reporte de uso de disco"
    echo "6. 🚪 Salir"
    
    read -p "Selecciona una opción (1-6): " choice
    
    case $choice in
        1) move_downloads_smart ;;
        2) move_media_libraries ;;
        3)
            echo -e "${YELLOW}Directorios disponibles en $HOME:${NC}"
            ls -la "$HOME" | grep "^d" | awk '{print $9}' | grep -v "^\.$\|^\.\.$"
            echo
            read -p "Nombre del directorio a mover: " dir_name
            if [ -d "$HOME/$dir_name" ]; then
                move_user_directory "$HOME/$dir_name" "$dir_name"
            else
                log_message "${RED}❌ Directorio no encontrado${NC}"
            fi
            ;;
        4)
            log_message "${BLUE}Directorios movidos al disco externo:${NC}"
            if [ -d "$EXTERNAL_USER_DATA" ]; then
                find "$EXTERNAL_USER_DATA" -maxdepth 2 -type d | while read dir; do
                    local size=$(du -sh "$dir" 2>/dev/null | cut -f1)
                    echo -e "${GREEN}  ✓ $(basename "$dir"): $size${NC}"
                done
            else
                log_message "${YELLOW}No hay directorios movidos${NC}"
            fi
            ;;
        5)
            local report_file="$HOME/Documents/scripts/user_data_report_$(date +%Y%m%d_%H%M%S).txt"
            {
                echo "=== REPORTE DE DATOS DE USUARIO ==="
                echo "Fecha: $(date)"
                echo "Usuario: $(whoami)"
                echo "Modo: SOLO BLACK2T"
                echo
                echo "=== USO ACTUAL DEL DISCO ==="
                df -h /
                echo
                echo "=== DIRECTORIOS PRINCIPALES ==="
                du -sh "$HOME"/* 2>/dev/null | sort -hr
            } > "$report_file"
            log_message "${GREEN}✅ Reporte generado: $report_file${NC}"
            ;;
        6)
            log_message "${BLUE}Saliendo de la gestión de datos de usuario...${NC}"
            exit 0
            ;;
        *)
            log_message "${RED}❌ Opción inválida${NC}"
            exit 1
            ;;
    esac
    
    echo
    echo -e "${BLUE}Presiona Enter para continuar...${NC}"
    read -r
}

# Ejecutar función principal
main
