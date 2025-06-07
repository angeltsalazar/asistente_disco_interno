#!/bin/bash
# Script para corregir puntos de montaje sin usar sudo
# Usa diskutil y mount_smbfs que no requieren sudo para SMB
# Autor: Script de corrección de montaje
# Fecha: $(date)

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Función para logging
log_message() {
    local message="$1"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    
    # Mostrar en terminal con colores
    echo -e "$timestamp - $message"
    
    # Guardar en log sin códigos de color
    local clean_message=$(echo -e "$message" | sed 's/\x1b\[[0-9;]*m//g')
    echo "$timestamp - $clean_message" >> "$HOME/Documents/scripts/fix_mount_points.log"
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

# Función para verificar si un directorio está vacío
is_directory_empty() {
    local dir="$1"
    if [ -d "$dir" ]; then
        local file_count=$(ls -A "$dir" 2>/dev/null | wc -l)
        [ "$file_count" -eq 0 ]
    else
        return 1
    fi
}

# Función para corregir montaje SMB sin sudo
fix_smb_mount() {
    local disk_name="$1"
    local current_mount=$(find_real_mount_point "$disk_name")
    local desired_mount="/Volumes/$disk_name"
    
    log_message "${CYAN}=== Corrigiendo punto de montaje para $disk_name ===${NC}"
    
    if [ -z "$current_mount" ]; then
        log_message "${RED}❌ Disco $disk_name no está montado${NC}"
        return 1
    fi
    
    log_message "${BLUE}Disco $disk_name actualmente montado en: $current_mount${NC}"
    
    # Si ya está montado con el nombre correcto, no hacer nada
    if [ "$current_mount" = "$desired_mount" ]; then
        log_message "${GREEN}✅ $disk_name ya está montado correctamente${NC}"
        return 0
    fi
    
    # Verificar si el directorio deseado existe y está vacío
    if [ -d "$desired_mount" ]; then
        if is_directory_empty "$desired_mount"; then
            log_message "${YELLOW}⚠️  Directorio $desired_mount existe pero está vacío${NC}"
            log_message "${BLUE}Intentando remover directorio vacío...${NC}"
            
            # Intentar remover sin sudo primero
            if rmdir "$desired_mount" 2>/dev/null; then
                log_message "${GREEN}✅ Directorio vacío removido exitosamente${NC}"
            else
                log_message "${YELLOW}⚠️  No se pudo remover el directorio vacío sin permisos administrativos${NC}"
                log_message "${BLUE}Puedes intentar manualmente: sudo rmdir '$desired_mount'${NC}"
            fi
        else
            log_message "${RED}❌ Directorio $desired_mount no está vacío${NC}"
            return 1
        fi
    fi
    
    # Obtener la información del montaje SMB actual
    local smb_source=$(mount | grep "on $current_mount" | awk '{print $1}' | head -1)
    
    if [ -z "$smb_source" ]; then
        log_message "${RED}❌ No se pudo obtener la fuente SMB${NC}"
        return 1
    fi
    
    log_message "${BLUE}Fuente SMB: $smb_source${NC}"
    
    # Intentar desmontar usando diskutil (no requiere sudo para SMB)
    log_message "${YELLOW}Desmontando $disk_name de $current_mount...${NC}"
    
    if diskutil unmount "$current_mount" 2>/dev/null; then
        log_message "${GREEN}✅ Desmontaje exitoso${NC}"
        
        # Esperar un momento
        sleep 2
        
        # Reconectar desde Finder (abrir la ubicación de red)
        log_message "${BLUE}Reconectando desde Finder...${NC}"
        open "smb://Angel's Mac Studio._smb._tcp.local/"
        
        log_message "${BLUE}Por favor, vuelve a conectar el disco $disk_name desde Finder${NC}"
        log_message "${BLUE}Esto debería montarlo con el nombre correcto${NC}"
        
    else
        log_message "${RED}❌ Error desmontando $current_mount${NC}"
        log_message "${BLUE}Puedes intentar manualmente desde Finder: Expulsar el disco y reconectar${NC}"
        return 1
    fi
    
    return 0
}

# Función principal
main() {
    log_message "${CYAN}=== CORRECCIÓN DE PUNTOS DE MONTAJE (SIN SUDO) ===${NC}"
    log_message "${BLUE}Fecha: $(date)${NC}"
    
    echo -e "${YELLOW}Este script corrige los puntos de montaje SMB sin requerir sudo${NC}"
    echo -e "${YELLOW}Los discos se desmontarán y deberás reconectarlos desde Finder${NC}"
    echo
    
    # Verificar BLACK2T
    local black2t_mount=$(find_real_mount_point "BLACK2T")
    if [ -n "$black2t_mount" ] && [ "$black2t_mount" != "/Volumes/BLACK2T" ]; then
        echo -e "${YELLOW}BLACK2T está montado en: $black2t_mount${NC}"
        read -p "¿Corregir BLACK2T? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            fix_smb_mount "BLACK2T"
        fi
    fi
    
    echo
    
    # Verificar 8TbSeries
    local series8tb_mount=$(find_real_mount_point "8TbSeries")
    if [ -n "$series8tb_mount" ] && [ "$series8tb_mount" != "/Volumes/8TbSeries" ]; then
        echo -e "${YELLOW}8TbSeries está montado en: $series8tb_mount${NC}"
        read -p "¿Corregir 8TbSeries? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            fix_smb_mount "8TbSeries"
        fi
    fi
    
    echo
    log_message "${BLUE}Proceso completado${NC}"
    log_message "${YELLOW}Recuerda reconectar los discos desde Finder si fueron desmontados${NC}"
}

# Ejecutar función principal
main "$@"
