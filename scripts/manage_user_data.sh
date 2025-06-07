#!/bin/bash
# Script para mover datos de usuario grandes a disco externo de manera segura
# CONFIGURADO PARA: MacMini (sufijo _macmini en directorios)
# Para usar en Mac Studio o Mac Pro, cambiar sufijo en configuración de rutas
# Enfocado en Documents, Downloads, y otros directorios de usuario
# Autor: Script de gestión segura de datos de usuario
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
EXTERNAL_USER_DATA="${BLACK2T_MOUNT}/UserData_$(whoami)_macmini"
BACKUP_USER_DATA="${SERIES8TB_MOUNT}/UserData_$(whoami)_backup_macmini"
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

# Analizar uso de disco en directorios de usuario
analyze_user_data() {
    log_message "${CYAN}=== ANÁLISIS DE DATOS DE USUARIO ===${NC}"
    
    echo -e "${BLUE}Directorios que consumen más espacio:${NC}"
    
    # Analizar directorio home completo
    echo -e "\n${YELLOW}Top 10 directorios más grandes:${NC}"
    du -sh "$HOME"/* 2>/dev/null | sort -hr | head -10 | while read size dir; do
        dir_name=$(basename "$dir")
        if is_safe_to_move "$dir"; then
            echo -e "${GREEN}  ✓ $size - $dir_name (seguro para mover)${NC}"
        else
            echo -e "${RED}  🚫 $size - $dir_name (crítico - NO mover)${NC}"
        fi
    done
    
    # Analizar subdirectorios específicos
    echo -e "\n${YELLOW}Análisis detallado:${NC}"
    
    # Downloads
    if [ -d "$HOME/Downloads" ]; then
        local downloads_size=$(du -sh "$HOME/Downloads" 2>/dev/null | cut -f1)
        local downloads_count=$(find "$HOME/Downloads" -type f | wc -l)
        echo -e "${BLUE}  Downloads: $downloads_size ($downloads_count archivos)${NC}"
    fi
    
    # Documents
    if [ -d "$HOME/Documents" ]; then
        local docs_size=$(du -sh "$HOME/Documents" 2>/dev/null | cut -f1)
        echo -e "${BLUE}  Documents: $docs_size${NC}"
        
        # Subdirectorios grandes en Documents
        du -sh "$HOME/Documents"/* 2>/dev/null | sort -hr | head -5 | while read size dir; do
            echo -e "${BLUE}    $(basename "$dir"): $size${NC}"
        done
    fi
    
    # Multimedia
    for media_dir in "Movies" "Music" "Pictures"; do
        if [ -d "$HOME/$media_dir" ]; then
            local media_size=$(du -sh "$HOME/$media_dir" 2>/dev/null | cut -f1)
            echo -e "${BLUE}  $media_dir: $media_size${NC}"
        fi
    done
    
    # Library específicos
    local large_library_dirs=(
        "Library/Application Support/Adobe"
        "Library/Application Support/Steam"
        "Library/Application Support/Unity"
        "Library/Application Support/Docker"
        "Library/Developer"
    )
    
    echo -e "\n${YELLOW}Datos de aplicaciones grandes:${NC}"
    for lib_dir in "${large_library_dirs[@]}"; do
        if [ -d "$HOME/$lib_dir" ]; then
            local lib_size=$(du -sh "$HOME/$lib_dir" 2>/dev/null | cut -f1)
            echo -e "${BLUE}  $lib_dir: $lib_size${NC}"
        fi
    done
}

# Crear estructura en disco externo
setup_external_structure() {
    log_message "${BLUE}Creando estructura en disco externo...${NC}"
    
    mkdir -p "$EXTERNAL_USER_DATA"
    mkdir -p "$BACKUP_USER_DATA"
    
    # Crear subdirectorios principales
    mkdir -p "$EXTERNAL_USER_DATA/Downloads"
    mkdir -p "$EXTERNAL_USER_DATA/Documents"
    mkdir -p "$EXTERNAL_USER_DATA/Media/Movies"
    mkdir -p "$EXTERNAL_USER_DATA/Media/Music"
    mkdir -p "$EXTERNAL_USER_DATA/Media/Pictures"
    mkdir -p "$EXTERNAL_USER_DATA/ApplicationData"
    
    log_message "${GREEN}✅ Estructura creada en disco externo${NC}"
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
    
    # Crear backup
    log_message "${BLUE}Creando backup...${NC}"
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
    echo
    echo -e "${BLUE}ℹ️  INFORMACIÓN IMPORTANTE:${NC}"
    echo -e "${CYAN}   • Este script NO mueve bibliotecas protegidas automáticamente${NC}"
    echo -e "${CYAN}   • Solo crea carpetas de destino y te da instrucciones${NC}"
    echo -e "${CYAN}   • TÚ usarás las apps nativas (Photos.app, Music.app) para migrar${NC}"
    echo -e "${CYAN}   • Es la forma MÁS SEGURA de migrar bibliotecas grandes${NC}"
    echo
    
    # Fotos - Detección inteligente de biblioteca protegida
    if [ -d "$HOME/Pictures/Photos Library.photoslibrary" ]; then
        local photos_size=$(du -sh "$HOME/Pictures/Photos Library.photoslibrary" 2>/dev/null | cut -f1)
        echo -e "${BLUE}📸 Biblioteca de Fotos detectada: $photos_size${NC}"
        echo
        echo -e "${YELLOW}⚠️  ADVERTENCIA: Photos Library está protegida por macOS${NC}"
        echo -e "${CYAN}📋 INSTRUCCIONES para migrar Photos Library de forma SEGURA:${NC}"
        echo
        echo -e "   1. ${GREEN}Abre Photos.app${NC}"
        echo -e "   2. ${GREEN}Ve a Photos > Preferencias > General${NC}"
        echo -e "   3. ${GREEN}Haz clic en 'Cambiar...' junto a Ubicación de biblioteca${NC}"
        echo -e "   4. ${GREEN}Selecciona: ${BLACK2T_MOUNT}/UserContent_macmini/Media/Pictures/${NC}"
        echo -e "   5. ${GREEN}Photos.app moverá la biblioteca automáticamente${NC}"
        echo
        echo -e "${RED}❌ NO recomendamos migración manual (puede corromper la biblioteca)${NC}"
        echo
        
        read -p "¿Crear carpeta de destino para que Photos.app pueda mover la biblioteca? (Y/n): " confirm
        if [[ ! $confirm =~ ^[Nn]$ ]]; then
            mkdir -p "${BLACK2T_MOUNT}/UserContent_macmini/Media/Pictures"
            echo -e "${GREEN}✅ Carpeta de destino creada en: ${BLACK2T_MOUNT}/UserContent_macmini/Media/Pictures${NC}"
            echo
            echo -e "${BLUE}📋 PRÓXIMOS PASOS:${NC}"
            echo -e "${CYAN}   1. Abre Photos.app${NC}"
            echo -e "${CYAN}   2. Photos > Preferencias > General${NC}"
            echo -e "${CYAN}   3. Cambiar ubicación → Selecciona la carpeta creada${NC}"
            echo -e "${CYAN}   4. Photos.app moverá todo automáticamente${NC}"
        else
            echo -e "${YELLOW}⚠️  Sin carpeta de destino, deberás crearla manualmente${NC}"
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
    
    # Biblioteca de Music/iTunes - Detección inteligente
    if [ -d "$HOME/Music/Music" ] || [ -d "$HOME/Music/iTunes" ]; then
        echo
        echo -e "${BLUE}🎵 Biblioteca de Music/iTunes detectada${NC}"
        echo -e "${YELLOW}⚠️  ADVERTENCIA: Las bibliotecas de Music/iTunes están protegidas${NC}"
        echo -e "${CYAN}📋 INSTRUCCIONES para migrar biblioteca de Music de forma SEGURA:${NC}"
        echo
        echo -e "   1. ${GREEN}Abre Music.app (o iTunes)${NC}"
        echo -e "   2. ${GREEN}Ve a Music > Preferencias > Archivos${NC}"
        echo -e "   3. ${GREEN}Haz clic en 'Cambiar...' junto a Ubicación de carpeta Music${NC}"
        echo -e "   4. ${GREEN}Selecciona: ${BLACK2T_MOUNT}/UserContent_macmini/Media/Music/${NC}"
        echo -e "   5. ${GREEN}Permite que Music.app mueva la biblioteca${NC}"
        echo
        echo -e "${RED}❌ NO recomendamos migración manual de bibliotecas de Music/iTunes${NC}"
        echo
        
        read -p "¿Crear carpeta de destino para que Music.app pueda mover la biblioteca? (Y/n): " confirm
        if [[ ! $confirm =~ ^[Nn]$ ]]; then
            mkdir -p "${BLACK2T_MOUNT}/UserContent_macmini/Media/Music"
            echo -e "${GREEN}✅ Carpeta de destino creada${NC}"
            echo
            echo -e "${BLUE}📋 PRÓXIMOS PASOS:${NC}"
            echo -e "${CYAN}   1. Abre Music.app${NC}"
            echo -e "${CYAN}   2. Music > Preferencias > Archivos${NC}"
            echo -e "${CYAN}   3. Cambiar ubicación → Selecciona la carpeta creada${NC}"
            echo -e "${CYAN}   4. Music.app moverá la biblioteca automáticamente${NC}"
        else
            echo -e "${YELLOW}⚠️  Sin carpeta de destino, deberás crearla manualmente${NC}"
        fi
    fi
    
    # Movies - Verificar si está protegido
    if [ -d "$HOME/Movies" ] && [ "$(ls -A "$HOME/Movies" 2>/dev/null)" ]; then
        local movies_size=$(du -sh "$HOME/Movies" 2>/dev/null | cut -f1)
        echo -e "${BLUE}🎬 Directorio Movies: $movies_size${NC}"
        
        # Verificar si está protegido por SIP (System Integrity Protection)
        if ! rm -rf "$HOME/Movies/.test_write" 2>/dev/null; then
            echo -e "${YELLOW}⚠️  ADVERTENCIA: Movies está protegido por macOS${NC}"
            echo -e "${CYAN}📋 RECOMENDACIÓN: Usa opciones nativas de macOS para mover contenido${NC}"
            echo -e "${GREEN}💡 O mueve archivos individuales manualmente al disco externo${NC}"
            
            read -p "¿Crear carpeta de destino para que puedas mover archivos tú mismo? (Y/n): " confirm
            if [[ ! $confirm =~ ^[Nn]$ ]]; then
                mkdir -p "${BLACK2T_MOUNT}/UserContent_macmini/Media/Movies"
                echo -e "${GREEN}✅ Carpeta de destino creada${NC}"
                echo -e "${CYAN}💡 Ahora puedes mover tus películas manualmente a esa carpeta${NC}"
            fi
        else
            read -p "¿Mover directorio Movies? (y/N): " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                move_user_directory "$HOME/Movies" "Media/Movies"
            fi
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
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # Verificar discos
    if [ ! -d "/Volumes/BLACK2T" ] || [ ! -d "/Volumes/8TbSeries" ]; then
        log_message "${RED}❌ Discos externos no disponibles${NC}"
        exit 1
    fi
    
    setup_external_structure
    
    echo -e "${YELLOW}¿Qué quieres hacer?${NC}"
    echo "1. 📊 Analizar uso de datos de usuario"
    echo "2. 📥 Gestionar Downloads de manera inteligente"
    echo "3. 🎵 Mover bibliotecas de medios (Fotos, Música, Videos)"
    echo -e "   ${BLUE}ℹ️  Solo crea carpetas y da instrucciones (NO migra automáticamente)${NC}"
    echo "4. 📁 Mover directorio específico"
    echo "5. 🔍 Ver directorios ya movidos"
    echo "6. 📋 Generar reporte de uso de disco"
    echo "7. 🚪 Salir"
    
    read -p "Selecciona una opción (1-7): " choice
    
    case $choice in
        1) analyze_user_data ;;
        2) move_downloads_smart ;;
        3) move_media_libraries ;;
        4)
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
        5)
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
        6)
            local report_file="$HOME/Documents/scripts/user_data_report_$(date +%Y%m%d_%H%M%S).txt"
            {
                echo "=== REPORTE DE DATOS DE USUARIO ==="
                echo "Fecha: $(date)"
                echo "Usuario: $(whoami)"
                echo
                echo "=== USO ACTUAL DEL DISCO ==="
                df -h /
                echo
                echo "=== DIRECTORIOS PRINCIPALES ==="
                du -sh "$HOME"/* 2>/dev/null | sort -hr
            } > "$report_file"
            log_message "${GREEN}✅ Reporte generado: $report_file${NC}"
            ;;
        7)
            log_message "${BLUE}Saliendo de la gestión de datos de usuario...${NC}"
            exit 0
            ;;
        *)
            log_message "${RED}❌ Opción inválida${NC}"
            exit 1
            ;;
    esac
    
    echo
    read -p "Presiona Enter para continuar..." -r
    main
}

# Ejecutar función principal
main "$@"
