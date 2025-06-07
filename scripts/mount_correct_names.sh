#!/bin/bash
# Script para montar discos BLACK2T y 8TbSeries con nombres correctos (sin sufijo -1)
# Usa IP directa del Mac Studio: 192.168.100.1
# Autor: Script de montaje optimizado
# Fecha: $(date)

# Configuración
MAC_STUDIO_IP="192.168.100.1"
DISKS=("BLACK2T" "8TbSeries")

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
    echo "$timestamp - $clean_message" >> "$HOME/Documents/scripts/mount_correct_names.log"
}

# Función para verificar conectividad
check_connectivity() {
    log_message "${BLUE}Verificando conectividad con Mac Studio ($MAC_STUDIO_IP)...${NC}"
    
    if ping -c 1 -W 3000 "$MAC_STUDIO_IP" >/dev/null 2>&1; then
        log_message "${GREEN}✅ Mac Studio accesible${NC}"
        return 0
    else
        log_message "${RED}❌ Mac Studio no accesible en $MAC_STUDIO_IP${NC}"
        return 1
    fi
}

# Función para desmontar todas las versiones de un disco
unmount_all_versions() {
    local disk_name="$1"
    
    log_message "${BLUE}Desmontando todas las versiones de $disk_name...${NC}"
    
    # Desmontar versiones con sufijo
    for suffix in "" "-1" "-2" "-3"; do
        local mount_path="/Volumes/${disk_name}${suffix}"
        if mount | grep -q " on $mount_path "; then
            log_message "${YELLOW}Desmontando $mount_path...${NC}"
            diskutil unmount "$mount_path" 2>/dev/null && log_message "${GREEN}✅ $mount_path desmontado${NC}"
        fi
    done
}

# Función para limpiar directorios vacíos
clean_empty_dirs() {
    local disk_name="$1"
    
    log_message "${BLUE}Limpiando directorios vacíos para $disk_name...${NC}"
    
    for suffix in "" "-1" "-2" "-3"; do
        local dir_path="/Volumes/${disk_name}${suffix}"
        if [ -d "$dir_path" ] && [ -z "$(ls -A "$dir_path" 2>/dev/null)" ]; then
            log_message "${YELLOW}Removiendo directorio vacío: $dir_path${NC}"
            
            # Intentar sin sudo primero
            if rmdir "$dir_path" 2>/dev/null; then
                log_message "${GREEN}✅ $dir_path removido${NC}"
            else
                # Mostrar comando para ejecutar manualmente
                echo -e "${YELLOW}⚠️  Requiere permisos administrativos${NC}"
                echo -e "${BLUE}Ejecuta manualmente: sudo rmdir '$dir_path'${NC}"
            fi
        fi
    done
}

# Función para montar con nombre correcto
mount_with_correct_name() {
    local disk_name="$1"
    local mount_point="/Volumes/$disk_name"
    
    log_message "${CYAN}=== Montando $disk_name con nombre correcto ===${NC}"
    
    # 1. Desmontar todas las versiones
    unmount_all_versions "$disk_name"
    
    # Esperar un momento
    sleep 2
    
    # 2. Limpiar directorios vacíos
    clean_empty_dirs "$disk_name"
    
    # 3. Intentar montaje usando osascript (método más confiable)
    log_message "${BLUE}Conectando a smb://$MAC_STUDIO_IP/$disk_name${NC}"
    
    if /usr/bin/osascript -e "mount volume \"smb://$MAC_STUDIO_IP/$disk_name\"" 2>/dev/null; then
        log_message "${GREEN}✅ $disk_name montado exitosamente${NC}"
        
        # Verificar que se montó con el nombre correcto
        if [ -d "$mount_point" ] && [ "$(ls -A "$mount_point" 2>/dev/null)" ]; then
            log_message "${GREEN}✅ $disk_name montado correctamente en $mount_point${NC}"
            
            # Mostrar información del disco
            local disk_info=$(df -h "$mount_point" | tail -1)
            local used=$(echo "$disk_info" | awk '{print $3}')
            local available=$(echo "$disk_info" | awk '{print $4}')
            local percent=$(echo "$disk_info" | awk '{print $5}')
            
            echo -e "${BLUE}   Espacio: $used usado, $available disponible ($percent usado)${NC}"
            return 0
        else
            log_message "${YELLOW}⚠️  $disk_name montado pero posiblemente con sufijo${NC}"
            # Buscar donde se montó realmente
            local actual_mount=$(mount | grep "/$disk_name on" | awk '{print $3}' | head -1)
            if [ -n "$actual_mount" ]; then
                log_message "${BLUE}Montado en: $actual_mount${NC}"
            fi
            return 1
        fi
    else
        log_message "${RED}❌ Error montando $disk_name${NC}"
        return 1
    fi
}

# Función principal
main() {
    log_message "${CYAN}=== MONTAJE CON NOMBRES CORRECTOS ===${NC}"
    log_message "${BLUE}Fecha: $(date)${NC}"
    log_message "${BLUE}Mac Studio IP: $MAC_STUDIO_IP${NC}"
    
    # Verificar conectividad
    if ! check_connectivity; then
        echo -e "${RED}❌ No se puede conectar al Mac Studio${NC}"
        echo -e "${BLUE}Verifica que:${NC}"
        echo -e "${BLUE}1. Mac Studio esté encendido${NC}"
        echo -e "${BLUE}2. Red Thunderbolt esté conectada${NC}"
        echo -e "${BLUE}3. IP sea correcta: $MAC_STUDIO_IP${NC}"
        exit 1
    fi
    
    echo
    echo -e "${YELLOW}Este script intentará montar los discos con nombres correctos:${NC}"
    for disk in "${DISKS[@]}"; do
        echo -e "${BLUE}  - $disk -> /Volumes/$disk${NC}"
    done
    echo
    echo -e "${YELLOW}NOTA: Puede requerir permisos administrativos para remover directorios vacíos${NC}"
    echo -e "${YELLOW}¿Continuar? (y/n):${NC}"
    read -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_message "${BLUE}Operación cancelada por el usuario${NC}"
        exit 0
    fi
    
    # Montar cada disco
    local success_count=0
    for disk in "${DISKS[@]}"; do
        echo
        if mount_with_correct_name "$disk"; then
            ((success_count++))
        fi
    done
    
    echo
    log_message "${CYAN}=== RESUMEN ===${NC}"
    log_message "${BLUE}Discos montados con nombres correctos: $success_count/${#DISKS[@]}${NC}"
    
    if [ "$success_count" -eq "${#DISKS[@]}" ]; then
        log_message "${GREEN}✅ Todos los discos montados correctamente${NC}"
        
        # Limpiar enlaces simbólicos anteriores del escritorio (evita duplicación)
        for disk in "${DISKS[@]}"; do
            [ -L ~/Desktop/"$disk" ] && rm ~/Desktop/"$disk"
        done
        log_message "${BLUE}✅ Enlaces simbólicos del escritorio limpiados (evita duplicación)${NC}"
        
        echo
        echo -e "${GREEN}🎉 ¡Éxito! Los discos ahora están montados con nombres correctos${NC}"
        echo -e "${BLUE}Puedes acceder a ellos desde Finder -> Ubicaciones o /Volumes/BLACK2T /Volumes/8TbSeries${NC}"
        
    else
        log_message "${YELLOW}⚠️  Algunos discos no se montaron correctamente${NC}"
        echo -e "${BLUE}Para directorios vacíos que no se pudieron remover, ejecuta:${NC}"
        echo -e "${BLUE}sudo rmdir /Volumes/BLACK2T /Volumes/8TbSeries${NC}"
        echo -e "${BLUE}Luego ejecuta este script nuevamente${NC}"
    fi
}

# Ejecutar función principal si no se está sourcing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
