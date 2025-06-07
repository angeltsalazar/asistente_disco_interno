#!/bin/bash
# Script para limpiar y corregir puntos de montaje SMB
# Asegura consistencia entre máquinas diferentes
# Autor: Script de corrección de montajes
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

# Función para limpiar directorio vacío si es seguro
clean_empty_mount_point() {
    local dir_path="$1"
    local disk_name="$2"
    
    if [ -d "$dir_path" ]; then
        # Verificar si está vacío (solo . y .. y tal vez .DS_Store)
        local file_count=$(find "$dir_path" -mindepth 1 -not -name ".DS_Store" | wc -l)
        
        if [ "$file_count" -eq 0 ]; then
            log_message "${YELLOW}Limpiando directorio vacío: $dir_path${NC}"
            sudo rmdir "$dir_path" 2>/dev/null || {
                log_message "${RED}No se pudo eliminar $dir_path - puede estar en uso${NC}"
                return 1
            }
            log_message "${GREEN}✅ Directorio vacío eliminado: $dir_path${NC}"
            return 0
        else
            log_message "${BLUE}Directorio $dir_path tiene contenido ($file_count archivos)${NC}"
            return 1
        fi
    fi
    return 0
}

# Función para desmontar y limpiar punto de montaje
fix_mount_point() {
    local disk_name="$1"
    local expected_path="/Volumes/$disk_name"
    local current_mount=""
    
    log_message "${CYAN}=== Corrigiendo punto de montaje para $disk_name ===${NC}"
    
    # Encontrar donde está montado actualmente
    current_mount=$(mount | grep -i "/$disk_name on" | awk '{print $3}' | head -1)
    
    if [ -n "$current_mount" ]; then
        log_message "${BLUE}Disco $disk_name actualmente montado en: $current_mount${NC}"
        
        # Si está montado en el lugar correcto, no hacer nada
        if [ "$current_mount" = "$expected_path" ]; then
            log_message "${GREEN}✅ $disk_name ya está montado correctamente en $expected_path${NC}"
            return 0
        fi
        
        # Desmontar del lugar incorrecto
        log_message "${YELLOW}Desmontando $disk_name de $current_mount...${NC}"
        sudo umount "$current_mount" || {
            log_message "${RED}❌ Error desmontando $current_mount${NC}"
            return 1
        }
        
        # Limpiar el directorio del montaje incorrecto si está vacío
        clean_empty_mount_point "$current_mount" "$disk_name"
    fi
    
    # Limpiar el directorio de destino si está vacío
    clean_empty_mount_point "$expected_path" "$disk_name"
    
    # Crear directorio de montaje si no existe
    if [ ! -d "$expected_path" ]; then
        log_message "${BLUE}Creando directorio de montaje: $expected_path${NC}"
        sudo mkdir -p "$expected_path"
    fi
    
    # Remontar en el lugar correcto
    log_message "${BLUE}Remontando $disk_name en $expected_path...${NC}"
    
    # Buscar la URL SMB desde el montaje anterior
    local smb_url=$(mount | grep -i "$disk_name" | head -1 | awk '{print $1}' | sed 's|^//|smb://|')
    
    if [ -z "$smb_url" ]; then
        # Intentar detectar desde descubrimiento de red
        local mac_studio_ip=$(arp -a | grep -i "mac.studio" | awk '{print $2}' | tr -d '()')
        if [ -z "$mac_studio_ip" ]; then
            mac_studio_ip="192.168.1.100"  # IP por defecto
        fi
        smb_url="smb://$mac_studio_ip/$disk_name"
    fi
    
    log_message "${BLUE}Intentando montar: $smb_url${NC}"
    
    # Montar usando mount_smbfs
    sudo mount_smbfs "$smb_url" "$expected_path" 2>/dev/null || {
        log_message "${RED}❌ Error montando $smb_url en $expected_path${NC}"
        log_message "${YELLOW}Intenta montar manualmente desde Finder primero${NC}"
        return 1
    }
    
    log_message "${GREEN}✅ $disk_name montado correctamente en $expected_path${NC}"
    return 0
}

# Función principal
main() {
    log_message "${CYAN}=== INICIANDO CORRECCIÓN DE PUNTOS DE MONTAJE ===${NC}"
    
    echo -e "${YELLOW}Este script corregirá los puntos de montaje SMB para que sean consistentes${NC}"
    echo -e "${YELLOW}¿Deseas continuar? (y/N): ${NC}"
    read -r response
    
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log_message "${BLUE}Operación cancelada por el usuario${NC}"
        exit 0
    fi
    
    # Mostrar estado actual
    log_message "${BLUE}Estado actual de montajes:${NC}"
    mount | grep -E "(BLACK2T|8TbSeries)" || log_message "${YELLOW}No hay discos montados${NC}"
    
    echo -e "\n${BLUE}Directorios en /Volumes:${NC}"
    ls -la /Volumes/ | grep -E "(BLACK2T|8TbSeries)" || log_message "${YELLOW}No hay directorios relacionados${NC}"
    
    # Corregir cada disco
    echo -e "\n${CYAN}Corrigiendo BLACK2T...${NC}"
    fix_mount_point "BLACK2T"
    
    echo -e "\n${CYAN}Corrigiendo 8TbSeries...${NC}"
    fix_mount_point "8TbSeries"
    
    # Verificar resultado final
    echo -e "\n${CYAN}=== ESTADO FINAL ===${NC}"
    log_message "${BLUE}Montajes después de la corrección:${NC}"
    mount | grep -E "(BLACK2T|8TbSeries)" || log_message "${YELLOW}No hay discos montados${NC}"
    
    echo -e "\n${BLUE}Directorios finales en /Volumes:${NC}"
    ls -la /Volumes/ | grep -E "(BLACK2T|8TbSeries)" || log_message "${YELLOW}No hay directorios relacionados${NC}"
    
    log_message "${GREEN}✅ Corrección de puntos de montaje completada${NC}"
}

# Ejecutar si es llamado directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
