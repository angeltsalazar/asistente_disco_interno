#!/bin/bash
# Script seguro para mover aplicaciones - Siguiendo mejores prácticas
# Solo mueve aplicaciones de terceros, NUNCA aplicaciones del sistema
# CONFIGURADO PARA: MacMini (sufijo _macmini en directorios)
# Para usar en Mac Studio o Mac Pro, cambiar sufijo en configuración de rutas
# Autor: Script refactorizado con enfoque en seguridad
# Fecha: $(date)

set -e  # Salir si hay algún error

# Función para encontrar el punto de montaje real de un disco
find_real_mount_point() {
    local disk_name="$1"
    local prefer_canonical="$2"  # Si es "true", prefiere /Volumes/DISK_NAME sobre /Volumes/DISK_NAME-1
    
    # Primero buscar el punto de montaje canónico preferido
    if [ "$prefer_canonical" = "true" ] && [ -d "/Volumes/$disk_name" ]; then
        # Verificar si tiene contenido real
        local file_count=$(find "/Volumes/$disk_name" -mindepth 1 -not -name ".DS_Store" 2>/dev/null | wc -l)
        if [ "$file_count" -gt 0 ]; then
            echo "/Volumes/$disk_name"
            return 0
        fi
    fi
    
    # Buscar en mount por SMB primero
    local smb_mount=$(mount | grep -i "/$disk_name on" | awk '{print $3}' | head -1)
    if [ -n "$smb_mount" ] && [ -d "$smb_mount" ]; then
        echo "$smb_mount"
        return 0
    fi
    
    # Buscar variaciones del nombre (-1, -2, etc.) con contenido
    for suffix in "" "-1" "-2" "-3"; do
        local path="/Volumes/${disk_name}${suffix}"
        if [ -d "$path" ]; then
            local file_count=$(find "$path" -mindepth 1 -not -name ".DS_Store" 2>/dev/null | wc -l)
            if [ "$file_count" -gt 0 ]; then
                echo "$path"
                return 0
            fi
        fi
    done
    
    return 1
}

# Función para verificar y advertir sobre montajes no canónicos
check_canonical_mounts() {
    local disk_name="$1"
    local current_mount="$2"
    local canonical_mount="/Volumes/$disk_name"
    
    if [ "$current_mount" != "$canonical_mount" ]; then
        echo -e "${YELLOW}⚠️  ADVERTENCIA: $disk_name montado en $current_mount (no canónico)${NC}"
        echo -e "${YELLOW}   Para consistencia entre máquinas, debería estar en $canonical_mount${NC}"
        echo -e "${YELLOW}   Ejecuta ./fix_mount_points.sh para corregir${NC}"
    fi
}

# Detectar puntos de montaje reales
BLACK2T_MOUNT=$(find_real_mount_point "BLACK2T" "true")
SERIES8TB_MOUNT=$(find_real_mount_point "8TbSeries" "true")

# Validar que los discos estén montados
if [ -z "$BLACK2T_MOUNT" ]; then
    echo -e "${RED}❌ Error: Disco BLACK2T no está montado correctamente${NC}"
    exit 1
fi

if [ -z "$SERIES8TB_MOUNT" ]; then
    echo -e "${RED}❌ Error: Disco 8TbSeries no está montado correctamente${NC}"
    exit 1
fi

echo -e "${BLUE}✅ Discos detectados:${NC}"
echo -e "${BLUE}   BLACK2T: $BLACK2T_MOUNT${NC}"
echo -e "${BLUE}   8TbSeries: $SERIES8TB_MOUNT${NC}"

# Verificar si los montajes son canónicos
check_canonical_mounts "BLACK2T" "$BLACK2T_MOUNT"
check_canonical_mounts "8TbSeries" "$SERIES8TB_MOUNT"

# Configuración de rutas
EXTERNAL_SAFE_APPS="${BLACK2T_MOUNT}/Applications_safe_macmini"
BACKUP_SAFE_APPS="${SERIES8TB_MOUNT}/Applications_safe_backup_macmini"
LOCAL_APPS="/Applications"
USER_APPS="$HOME/Applications"
LOG_FILE="$HOME/Documents/scripts/safe_move_apps_macmini.log"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# APLICACIONES CRÍTICAS DEL SISTEMA - NUNCA MOVER
CRITICAL_SYSTEM_APPS=(
    "Safari.app"
    "Mail.app"
    "Calendar.app"
    "Contacts.app"
    "Messages.app"
    "FaceTime.app"
    "Photos.app"
    "Music.app"
    "TV.app"
    "Podcasts.app"
    "News.app"
    "Stocks.app"
    "Voice Memos.app"
    "Notes.app"
    "Reminders.app"
    "Maps.app"
    "Find My.app"
    "QuickTime Player.app"
    "Preview.app"
    "TextEdit.app"
    "Font Book.app"
    "Digital Color Meter.app"
    "Grapher.app"
    "Calculator.app"
    "Chess.app"
    "Stickies.app"
    "Image Capture.app"
    "DVD Player.app"
    "Photo Booth.app"
    "Time Machine.app"
    "Migration Assistant.app"
    "Boot Camp Assistant.app"
    "Activity Monitor.app"
    "Airport Utility.app"
    "Audio MIDI Setup.app"
    "Bluetooth Screen Sharing.app"
    "Console.app"
    "Digital Color Meter.app"
    "Disk Utility.app"
    "Grapher.app"
    "Keychain Access.app"
    "Network Utility.app"
    "Script Editor.app"
    "System Information.app"
    "Terminal.app"
    "VoiceOver Utility.app"
    "Wireless Diagnostics.app"
    "System Preferences.app"
    "App Store.app"
    "Automator.app"
    "Launchpad.app"
    "Mission Control.app"
    "Siri.app"
    "Spotlight.app"
)

# APLICACIONES SEGURAS PARA MOVER (terceros)
SAFE_TO_MOVE_APPS=(
    "Adobe Creative Cloud"
    "Adobe Photoshop 2024"
    "Adobe Illustrator 2024"
    "Adobe Premiere Pro 2024"
    "Adobe After Effects 2024"
    "Adobe InDesign 2024"
    "Adobe Lightroom"
    "Final Cut Pro"
    "Logic Pro"
    "Motion"
    "Compressor"
    "MainStage"
    "Xcode"
    "Unity"
    "Unity Hub"
    "Blender"
    "Cinema 4D"
    "Maya"
    "3ds Max"
    "Steam"
    "Epic Games Launcher"
    "Discord"
    "Slack"
    "Microsoft Word"
    "Microsoft Excel"
    "Microsoft PowerPoint"
    "Microsoft Outlook"
    "Microsoft Teams"
    "VirtualBox"
    "VMware Fusion"
    "Parallels Desktop"
    "Docker"
    "DaVinci Resolve"
    "OmniGraffle 7"
    "Sketch"
    "Figma"
    "Notion"
    "Spotify"
    "Zoom"
    "Google Chrome"
    "Firefox"
    "Brave Browser"
    "Visual Studio Code"
    "Sublime Text"
    "IntelliJ IDEA"
    "PyCharm"
    "WebStorm"
    "DataGrip"
    "TablePlus"
    "Postman"
    "Insomnia"
    "GitHub Desktop"
    "Sourcetree"
    "Finder" # NO - Esta es crítica del sistema
)

# Función para logging
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo -e "$1"
}

# Verificar si una aplicación es crítica del sistema
is_critical_system_app() {
    local app_name="$1"
    for critical_app in "${CRITICAL_SYSTEM_APPS[@]}"; do
        if [[ "$app_name" == "$critical_app" ]]; then
            return 0  # Es crítica
        fi
    done
    return 1  # No es crítica
}

# Verificar que los discos externos están montados
check_disks() {
    log_message "${BLUE}Verificando discos externos...${NC}"
    
    if [ ! -d "/Volumes/BLACK2T" ]; then
        log_message "${RED}❌ Disco BLACK2T no montado${NC}"
        exit 1
    fi
    
    if [ ! -d "/Volumes/8TbSeries" ]; then
        log_message "${RED}❌ Disco 8TbSeries no montado${NC}"
        exit 1
    fi
    
    log_message "${GREEN}✅ Ambos discos externos están montados${NC}"
}

# Crear directorios necesarios
setup_directories() {
    log_message "${BLUE}Creando directorios seguros...${NC}"
    
    mkdir -p "$EXTERNAL_SAFE_APPS"
    mkdir -p "$BACKUP_SAFE_APPS"
    mkdir -p "$USER_APPS"  # Directorio de aplicaciones de usuario
    
    log_message "${GREEN}✅ Directorios creados${NC}"
}

# Análisis de seguridad de la aplicación
analyze_app_safety() {
    local app_name="$1"
    local app_path="$LOCAL_APPS/$app_name"
    
    # Verificar si es aplicación crítica del sistema
    if is_critical_system_app "$app_name"; then
        log_message "${RED}🚫 $app_name es una aplicación CRÍTICA del sistema - NO MOVER${NC}"
        return 1
    fi
    
    # Verificar si está firmada por Apple
    local signature=$(codesign -dv "$app_path" 2>&1 | grep "Authority=" | head -1)
    if [[ "$signature" == *"Apple"* ]] && [[ "$signature" == *"Software Update"* ]]; then
        log_message "${RED}🚫 $app_name está firmada por Apple - NO MOVER${NC}"
        return 1
    fi
    
    # Verificar si está en System Integrity Protection
    if [[ "$app_path" == *"/System/"* ]] || [[ "$app_path" == *"/usr/"* ]]; then
        log_message "${RED}🚫 $app_name está protegida por SIP - NO MOVER${NC}"
        return 1
    fi
    
    # Verificar tamaño mínimo (no mover apps muy pequeñas del sistema)
    local app_size=$(du -sm "$app_path" 2>/dev/null | cut -f1)
    if [ "$app_size" -lt 50 ]; then
        log_message "${YELLOW}⚠️  $app_name es muy pequeña ($app_size MB) - posiblemente del sistema${NC}"
        return 1
    fi
    
    log_message "${GREEN}✅ $app_name es segura para mover${NC}"
    return 0
}

# Crear backup seguro de la aplicación
backup_app_safe() {
    local app_name="$1"
    log_message "${BLUE}Creando backup seguro de $app_name...${NC}"
    
    if [ ! -d "$BACKUP_SAFE_APPS/$app_name" ]; then
        rsync -av "$LOCAL_APPS/$app_name" "$BACKUP_SAFE_APPS/" 2>/dev/null
        if [ $? -eq 0 ]; then
            log_message "${GREEN}✅ Backup seguro de $app_name creado${NC}"
        else
            log_message "${RED}❌ Error creando backup de $app_name${NC}"
            return 1
        fi
    else
        log_message "${YELLOW}⚠️  Backup de $app_name ya existe${NC}"
    fi
}

# Mover aplicación de manera segura
move_app_safe() {
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
    
    log_message "${CYAN}=== Analizando $app_name ===${NC}"
    
    # Análisis de seguridad
    if ! analyze_app_safety "$app_name"; then
        log_message "${RED}❌ $app_name NO es segura para mover${NC}"
        return 1
    fi
    
    # Solicitar confirmación para aplicaciones no reconocidas
    local is_known=false
    for safe_app in "${SAFE_TO_MOVE_APPS[@]}"; do
        if [[ "$app_name" == "$safe_app.app" ]] || [[ "$app_name" == "$safe_app" ]]; then
            is_known=true
            break
        fi
    done
    
    if [ "$is_known" = false ]; then
        echo -e "${YELLOW}⚠️  $app_name no está en la lista de aplicaciones conocidas como seguras${NC}"
        read -p "¿Estás seguro de que quieres moverla? (y/N): " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            log_message "${BLUE}Movimiento de $app_name cancelado por el usuario${NC}"
            return 0
        fi
    fi
    
    log_message "${BLUE}Procesando $app_name de manera segura...${NC}"
    
    # Crear backup
    if ! backup_app_safe "$app_name"; then
        return 1
    fi
    
    # Mover la aplicación SIN sudo (más seguro)
    log_message "${BLUE}Moviendo $app_name al disco externo...${NC}"
    mv "$LOCAL_APPS/$app_name" "$EXTERNAL_SAFE_APPS/" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        # Crear enlace simbólico SIN sudo
        ln -s "$EXTERNAL_SAFE_APPS/$app_name" "$LOCAL_APPS/$app_name"
        
        if [ $? -eq 0 ]; then
            log_message "${GREEN}✅ $app_name movida y enlazada exitosamente${NC}"
            
            # Verificar que el enlace funciona
            if [ -d "$LOCAL_APPS/$app_name" ]; then
                log_message "${GREEN}✅ Enlace simbólico verificado${NC}"
                
                # Verificar que la aplicación aún funciona
                log_message "${BLUE}Verificando que la aplicación funciona...${NC}"
                if open -a "$LOCAL_APPS/$app_name" --hide --background 2>/dev/null; then
                    log_message "${GREEN}✅ Aplicación verificada y funcional${NC}"
                else
                    log_message "${YELLOW}⚠️  No se pudo verificar automáticamente la aplicación${NC}"
                fi
            else
                log_message "${RED}❌ Error: Enlace simbólico no funciona${NC}"
                # Restaurar automáticamente
                mv "$EXTERNAL_SAFE_APPS/$app_name" "$LOCAL_APPS/"
                return 1
            fi
        else
            log_message "${RED}❌ Error creando enlace simbólico para $app_name${NC}"
            # Restaurar automáticamente
            mv "$EXTERNAL_SAFE_APPS/$app_name" "$LOCAL_APPS/"
            return 1
        fi
    else
        log_message "${RED}❌ Error moviendo $app_name (probablemente requiere permisos especiales)${NC}"
        log_message "${BLUE}Sugerencia: Esta aplicación podría requerir reinstalación en lugar de movimiento${NC}"
        return 1
    fi
}

# Listar aplicaciones seguras para mover
list_safe_apps() {
    log_message "${CYAN}=== APLICACIONES SEGURAS PARA MOVER ===${NC}"
    
    echo -e "${GREEN}Aplicaciones de terceros encontradas:${NC}"
    local safe_count=0
    
    for app in "$LOCAL_APPS"/*.app; do
        if [ -d "$app" ] && [ ! -L "$app" ]; then
            local app_name=$(basename "$app")
            
            # Verificar si es segura
            if ! is_critical_system_app "$app_name"; then
                local app_size=$(du -sh "$app" 2>/dev/null | cut -f1)
                echo -e "${BLUE}  ✓ $app_name ($app_size)${NC}"
                ((safe_count++))
            fi
        fi
    done
    
    echo -e "\n${GREEN}Total de aplicaciones seguras: $safe_count${NC}"
    
    echo -e "\n${RED}APLICACIONES CRÍTICAS (NO MOVER):${NC}"
    for critical_app in "${CRITICAL_SYSTEM_APPS[@]}"; do
        if [ -d "$LOCAL_APPS/$critical_app" ]; then
            echo -e "${RED}  🚫 $critical_app${NC}"
        fi
    done
}

# Función principal
main() {
    log_message "${CYAN}=== MOVIMIENTO SEGURO DE APLICACIONES ===${NC}"
    log_message "${GREEN}Siguiendo mejores prácticas de seguridad${NC}"
    log_message "${BLUE}Disco destino: $EXTERNAL_SAFE_APPS${NC}"
    log_message "${BLUE}Disco backup: $BACKUP_SAFE_APPS${NC}"
    
    check_disks
    setup_directories
    
    echo -e "\n${YELLOW}¿Qué quieres hacer?${NC}"
    echo "1. Ver aplicaciones seguras para mover"
    echo "2. Mover aplicaciones de la lista recomendada"
    echo "3. Mover una aplicación específica (con análisis de seguridad)"
    echo "4. Ver aplicaciones críticas del sistema (NO mover)"
    echo "5. Limpiar caches y archivos temporales (alternativa segura)"
    echo "6. Salir"
    
    read -p "Selecciona una opción (1-6): " choice
    
    case $choice in
        1)
            list_safe_apps
            ;;
        2)
            echo -e "\n${BLUE}Aplicaciones recomendadas disponibles para mover:${NC}"
            available_apps=()
            for app in "${SAFE_TO_MOVE_APPS[@]}"; do
                local app_file="$app.app"
                if [ -d "$LOCAL_APPS/$app_file" ] && [ ! -L "$LOCAL_APPS/$app_file" ]; then
                    available_apps+=("$app_file")
                    local app_size=$(du -sh "$LOCAL_APPS/$app_file" 2>/dev/null | cut -f1)
                    echo "  ✓ $app_file ($app_size)"
                fi
            done
            
            if [ ${#available_apps[@]} -eq 0 ]; then
                log_message "${YELLOW}No hay aplicaciones recomendadas disponibles para mover${NC}"
                exit 0
            fi
            
            echo -e "\n${YELLOW}¿Mover las aplicaciones listadas una por una? (y/N): ${NC}"
            read confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                for app in "${available_apps[@]}"; do
                    echo -e "\n${CYAN}¿Mover $app? (y/N/q para salir): ${NC}"
                    read app_confirm
                    if [[ $app_confirm =~ ^[Qq]$ ]]; then
                        break
                    elif [[ $app_confirm =~ ^[Yy]$ ]]; then
                        move_app_safe "$app"
                    fi
                done
            fi
            ;;
        3)
            read -p "Nombre de la aplicación (sin .app): " app_name
            move_app_safe "$app_name.app"
            ;;
        4)
            echo -e "\n${RED}APLICACIONES CRÍTICAS DEL SISTEMA (NUNCA MOVER):${NC}"
            for critical_app in "${CRITICAL_SYSTEM_APPS[@]}"; do
                if [ -d "$LOCAL_APPS/$critical_app" ]; then
                    echo -e "${RED}  🚫 $critical_app${NC}"
                fi
            done
            ;;
        5)
            log_message "${BLUE}Ejecutando limpieza de caches y archivos temporales...${NC}"
            # Ejecutar script de limpieza (lo crearemos después)
            bash "$HOME/Documents/scripts/clean_system_caches.sh" 2>/dev/null || {
                echo -e "${YELLOW}Script de limpieza no encontrado. Ejecutando limpieza básica...${NC}"
                du -sh ~/Library/Caches/ 2>/dev/null
                echo -e "${BLUE}Para limpiar caches: rm -rf ~/Library/Caches/*${NC}"
            }
            ;;
        6)
            log_message "${BLUE}Saliendo del movimiento seguro...${NC}"
            exit 0
            ;;
        *)
            log_message "${RED}Opción inválida${NC}"
            exit 1
            ;;
    esac
    
    log_message "${GREEN}=== Proceso completado de manera segura ===${NC}"
}

# Mostrar advertencia de seguridad
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                              ║${NC}"
echo -e "${CYAN}║         ${YELLOW}MOVIMIENTO SEGURO DE APLICACIONES${CYAN}                   ║${NC}"
echo -e "${CYAN}║                                                              ║${NC}"
echo -e "${CYAN}║  ${GREEN}✅ Solo mueve aplicaciones de terceros${CYAN}                    ║${NC}"
echo -e "${CYAN}║  ${GREEN}✅ Protege aplicaciones críticas del sistema${CYAN}              ║${NC}"
echo -e "${CYAN}║  ${GREEN}✅ Análisis de seguridad automático${CYAN}                       ║${NC}"
echo -e "${CYAN}║  ${GREEN}✅ Backup automático antes de mover${CYAN}                       ║${NC}"
echo -e "${CYAN}║                                                              ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

# Ejecutar función principal
main "$@"
