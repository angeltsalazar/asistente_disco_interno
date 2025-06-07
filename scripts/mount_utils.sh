#!/bin/bash
# Función de utilidad para manejo consistente de puntos de montaje
# Se puede incluir en otros scripts para asegurar consistencia
# Autor: Utilidad de montaje
# Fecha: $(date)

# Función mejorada para encontrar punto de montaje real
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

# Función para obtener el nombre canónico de un disco
get_canonical_mount_path() {
    local disk_name="$1"
    echo "/Volumes/$disk_name"
}

# Función para verificar si un punto de montaje es canónico
is_canonical_mount() {
    local current_path="$1"
    local disk_name="$2"
    local canonical_path="/Volumes/$disk_name"
    
    [ "$current_path" = "$canonical_path" ]
}

# Función para sugerir corrección de montaje
suggest_mount_fix() {
    local disk_name="$1"
    local current_mount=$(find_real_mount_point "$disk_name")
    local canonical_mount="/Volumes/$disk_name"
    
    if [ -n "$current_mount" ] && [ "$current_mount" != "$canonical_mount" ]; then
        echo "SUGERENCIA: $disk_name está montado en $current_mount"
        echo "Para consistencia entre máquinas, debería estar en $canonical_mount"
        echo "Ejecuta: ./fix_mount_points.sh"
        return 1
    fi
    return 0
}

# Función para obtener información de montaje
get_mount_info() {
    local disk_name="$1"
    local mount_point=$(find_real_mount_point "$disk_name")
    
    if [ -n "$mount_point" ]; then
        echo "Disco: $disk_name"
        echo "Montado en: $mount_point"
        echo "Canónico: $(is_canonical_mount "$mount_point" "$disk_name" && echo "Sí" || echo "No")"
        
        # Mostrar información del sistema de archivos
        local fs_info=$(mount | grep "$mount_point" | head -1)
        echo "Tipo: $(echo "$fs_info" | awk '{print $5}')"
        
        # Mostrar espacio
        df -h "$mount_point" | tail -1 | awk '{printf "Espacio: %s usado de %s (%s)\n", $3, $2, $5}'
        
        return 0
    else
        echo "Disco $disk_name no está montado"
        return 1
    fi
}
