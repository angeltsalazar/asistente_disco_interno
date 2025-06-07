#!/bin/bash
# Script para verificar y montar discos externos automáticamente
# Autor: Script generado para gestión de discos
# Fecha: $(date)

# Configuración de discos
BLACK2T_DISK="BLACK2T"
SERIES8TB_DISK="8TbSeries"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
CYAN='\033[0;36m'

# Función para logging
log_message() {
    local message="$1"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    
    # Mostrar en terminal con colores
    echo -e "$timestamp - $message"
    
    # Guardar en log sin códigos de color
    local clean_message=$(echo -e "$message" | sed 's/\x1b\[[0-9;]*m//g')
    echo "$timestamp - $clean_message" >> "$HOME/Documents/scripts/disk_mount.log"
}

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

# Función para verificar si un disco está montado
is_disk_mounted() {
    local disk_name="$1"
    local mount_point=$(find_real_mount_point "$disk_name")
    if [ -n "$mount_point" ]; then
        return 0  # Montado
    else
        return 1  # No montado
    fi
}

# Función para obtener información del disco
get_disk_info() {
    local disk_name="$1"
    diskutil list | grep -i "$disk_name" | head -1
}

# Función para montar disco por nombre
mount_disk_by_name() {
    local disk_name="$1"
    
    log_message "${BLUE}Intentando montar $disk_name...${NC}"
    
    # Buscar el identificador del disco
    local disk_identifier=$(diskutil list | grep -i "$disk_name" | awk '{print $NF}' | head -1)
    
    if [ -z "$disk_identifier" ]; then
        log_message "${RED}❌ No se encontró el disco $disk_name${NC}"
        return 1
    fi
    
    log_message "${BLUE}Identificador encontrado: $disk_identifier${NC}"
    
    # Intentar montar
    diskutil mount "$disk_identifier" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_message "${GREEN}✅ $disk_name montado exitosamente${NC}"
        return 0
    else
        log_message "${RED}❌ Error montando $disk_name${NC}"
        return 1
    fi
}

# Función para verificar salud del disco
check_disk_health() {
    local disk_name="$1"
    local volume_path=$(find_real_mount_point "$disk_name")
    
    if [ -n "$volume_path" ] && [ -d "$volume_path" ]; then
        # Verificar si es escribible
        if [ -w "$volume_path" ]; then
            log_message "${GREEN}✅ $disk_name: Montado en $volume_path y escribible${NC}"
            
            # Mostrar espacio disponible
            local disk_info=$(df -h "$volume_path" | tail -1)
            local used=$(echo "$disk_info" | awk '{print $3}')
            local available=$(echo "$disk_info" | awk '{print $4}')
            local percent=$(echo "$disk_info" | awk '{print $5}')
            
            echo -e "${BLUE}   Espacio: $used usado, $available disponible ($percent usado)${NC}"
            
            # Verificar directorios de aplicaciones
            if [ "$disk_name" = "$BLACK2T_DISK" ]; then
                if [ -d "$volume_path/Applications_macmini" ]; then
                    local app_count=$(find "$volume_path/Applications_macmini" -maxdepth 1 -name "*.app" -type d 2>/dev/null | wc -l)
                    echo -e "${BLUE}   Aplicaciones: $app_count${NC}"
                fi
            elif [ "$disk_name" = "$SERIES8TB_DISK" ]; then
                if [ -d "$volume_path/Applications_macmini" ]; then
                    local backup_count=$(find "$volume_path/Applications_macmini" -maxdepth 1 -name "*.app" -type d 2>/dev/null | wc -l)
                    echo -e "${BLUE}   Backups: $backup_count${NC}"
                fi
            fi
            
        else
            log_message "${YELLOW}⚠️  $disk_name: Montado en $volume_path pero no escribible${NC}"
        fi
    else
        log_message "${RED}❌ $disk_name: No montado${NC}"
        return 1
    fi
}

# Función para verificar aplicaciones que dependen de discos externos
check_dependent_apps() {
    log_message "${BLUE}Verificando aplicaciones dependientes...${NC}"
    
    local broken_links=0
    
    find "/Applications" -maxdepth 1 -name "*.app" -type l 2>/dev/null | while read symlink; do
        local target=$(readlink "$symlink" 2>/dev/null)
        local app_name=$(basename "$symlink")
        
        if [[ "$target" == *"/Volumes/"* ]]; then
            if [ ! -d "$target" ]; then
                echo -e "${RED}❌ $app_name -> $target (NO DISPONIBLE)${NC}"
                ((broken_links++))
            else
                echo -e "${GREEN}✅ $app_name -> OK${NC}"
            fi
        fi
    done
    
    if [ $broken_links -gt 0 ]; then
        log_message "${YELLOW}⚠️  Se encontraron $broken_links aplicaciones no disponibles${NC}"
    fi
}

# Función para montar todos los discos
mount_all_disks() {
    log_message "${BLUE}=== Montando todos los discos externos ===${NC}"
    
    # Montar BLACK2T
    if ! is_disk_mounted "$BLACK2T_DISK"; then
        mount_disk_by_name "$BLACK2T_DISK"
    else
        log_message "${GREEN}✅ $BLACK2T_DISK ya está montado${NC}"
    fi
    
    # Montar 8TbSeries
    if ! is_disk_mounted "$SERIES8TB_DISK"; then
        mount_disk_by_name "$SERIES8TB_DISK"
    else
        log_message "${GREEN}✅ $SERIES8TB_DISK ya está montado${NC}"
    fi
}

# Función para verificar estado de todos los discos
check_all_disks() {
    log_message "${BLUE}=== Estado de discos externos ===${NC}"
    
    check_disk_health "$BLACK2T_DISK"
    echo
    check_disk_health "$SERIES8TB_DISK"
    echo
    check_dependent_apps
}

# Función para diagnóstico completo de discos
comprehensive_disk_diagnosis() {
    log_message "${CYAN}=== DIAGNÓSTICO COMPLETO DE DISCOS ===${NC}"
    echo
    
    # Verificar todos los discos detectados
    log_message "${BLUE}📋 Todos los discos detectados:${NC}"
    diskutil list
    echo
    
    # Verificar discos externos específicamente
    log_message "${BLUE}🔍 Buscando discos externos:${NC}"
    diskutil list external
    echo
    
    # Verificar conexiones Thunderbolt/USB
    log_message "${BLUE}⚡ Conexiones Thunderbolt activas:${NC}"
    system_profiler SPThunderboltDataType | grep -A 5 "Device connected\|Device Name"
    echo
    
    # Verificar dispositivos USB
    log_message "${BLUE}🔌 Dispositivos USB conectados:${NC}"
    system_profiler SPUSBDataType | grep -A 3 -B 1 "Product ID\|Mass Storage"
    echo
    
    # Verificar volúmenes montados
    log_message "${BLUE}💾 Volúmenes actualmente montados:${NC}"
    df -h | grep "/Volumes"
    ls -la /Volumes/
    echo
    
    # Buscar discos por nombres alternativos
    log_message "${BLUE}🔎 Buscando discos con nombres similares:${NC}"
    diskutil list | grep -i -E "(black|8tb|series|external|backup)" || echo "No se encontraron discos con nombres similares"
    echo
    
    # Verificar estado de AutoFS (automontaje)
    log_message "${BLUE}🤖 Estado del automontaje:${NC}"
    sudo automount -cv 2>/dev/null || echo "AutoFS no disponible"
    echo
}

# Función para crear script de automontaje
create_automount_script() {
    local automount_script="$HOME/Documents/scripts/automount_disks.sh"
    
    cat > "$automount_script" << 'EOF'
#!/bin/bash
# Script de automontaje - se ejecuta automáticamente

# Función para montar disco si no está montado
mount_if_needed() {
    local disk_name="$1"
    if [ ! -d "/Volumes/$disk_name" ]; then
        echo "$(date): Montando $disk_name..."
        diskutil list | grep -i "$disk_name" | awk '{print $NF}' | head -1 | xargs diskutil mount
    fi
}

# Montar discos necesarios
mount_if_needed "BLACK2T"
mount_if_needed "8TbSeries"

# Log del resultado
if [ -d "/Volumes/BLACK2T" ] && [ -d "/Volumes/8TbSeries" ]; then
    echo "$(date): Todos los discos montados correctamente" >> "$HOME/Documents/scripts/automount.log"
else
    echo "$(date): Error: No todos los discos pudieron montarse" >> "$HOME/Documents/scripts/automount.log"
fi
EOF
    
    chmod +x "$automount_script"
    log_message "${GREEN}✅ Script de automontaje creado: $automount_script${NC}"
}

# Función para configurar automontaje en el inicio
setup_automount() {
    log_message "${BLUE}Configurando automontaje en el inicio del sistema...${NC}"
    
    # Crear LaunchAgent
    local plist_file="$HOME/Library/LaunchAgents/com.user.automount.plist"
    
    cat > "$plist_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.automount</string>
    <key>ProgramArguments</key>
    <array>
        <string>$HOME/Documents/scripts/automount_disks.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StartInterval</key>
    <integer>300</integer>
</dict>
</plist>
EOF
    
    # Cargar el LaunchAgent
    launchctl load "$plist_file" 2>/dev/null
    
    log_message "${GREEN}✅ Automontaje configurado${NC}"
    log_message "${BLUE}Los discos se verificarán cada 5 minutos${NC}"
}

# Función principal
main() {
    clear
    echo -e "${BLUE}=== GESTOR DE DISCOS EXTERNOS ===${NC}"
    echo -e "${BLUE}Fecha: $(date)${NC}"
    echo
    
    echo -e "${YELLOW}¿Qué quieres hacer?${NC}"
    echo "1. Verificar estado de todos los discos"
    echo "2. Montar todos los discos"
    echo "3. Montar solo BLACK2T"
    echo "4. Montar solo 8TbSeries"
    echo "5. Verificar aplicaciones dependientes"
    echo "6. Crear script de automontaje"
    echo "7. Configurar automontaje en inicio"
    echo "8. Ver logs de montaje"
    echo "9. 🔍 Diagnóstico completo de hardware"
    echo "10. Salir"
    
    read -p "Selecciona una opción (1-10): " choice
    
    case $choice in
        1) check_all_disks ;;
        2) mount_all_disks ;;
        3) mount_disk_by_name "$BLACK2T_DISK" ;;
        4) mount_disk_by_name "$SERIES8TB_DISK" ;;
        5) check_dependent_apps ;;
        6) create_automount_script ;;
        7) 
            create_automount_script
            setup_automount
            ;;
        8) 
            if [ -f "$HOME/Documents/scripts/disk_mount.log" ]; then
                tail -20 "$HOME/Documents/scripts/disk_mount.log"
            else
                echo "No hay logs disponibles"
            fi
            ;;
        9) comprehensive_disk_diagnosis ;;
        10) 
            log_message "${BLUE}Saliendo del gestor de discos...${NC}"
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
