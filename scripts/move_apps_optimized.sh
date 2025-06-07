#!/bin/bash
# Script optimizado para mover aplicaciones a discos remotos SMB
# Usa rsync para transferencias mucho más rápidas
# Fecha: $(date)

# Configuración
MACHINE_SUFFIX="_macmini"
EXTERNAL_MOUNT=""
BACKUP_DIR=""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Función para encontrar punto de montaje real
find_real_mount_point() {
    local disk_name="$1"
    
    # Verificar montajes posibles
    for suffix in "" "-1" "-2" "-3"; do
        local mount_path="/Volumes/${disk_name}${suffix}"
        if [ -d "$mount_path" ] && [ "$(ls -A "$mount_path" 2>/dev/null)" ]; then
            echo "$mount_path"
            return 0
        fi
    done
    
    return 1
}

# Función para detectar discos y configurar rutas
setup_paths() {
    echo -e "${CYAN}🔍 Detectando discos externos...${NC}"
    
    # Buscar BLACK2T
    if EXTERNAL_MOUNT=$(find_real_mount_point "BLACK2T"); then
        echo -e "${GREEN}✅ BLACK2T encontrado en: $EXTERNAL_MOUNT${NC}"
        BACKUP_DIR="$EXTERNAL_MOUNT/Applications_safe$MACHINE_SUFFIX"
        return 0
    # Buscar 8TbSeries como alternativa
    elif EXTERNAL_MOUNT=$(find_real_mount_point "8TbSeries"); then
        echo -e "${GREEN}✅ 8TbSeries encontrado en: $EXTERNAL_MOUNT${NC}"
        BACKUP_DIR="$EXTERNAL_MOUNT/Applications_safe$MACHINE_SUFFIX"
        return 0
    else
        echo -e "${RED}❌ No se encontraron discos externos montados${NC}"
        return 1
    fi
}

# Función optimizada para mover apps con rsync
move_app_optimized() {
    local app_name="$1"
    local source_path="/Applications/$app_name"
    local dest_path="$BACKUP_DIR/$app_name"
    
    echo -e "${CYAN}🚀 Moviendo $app_name con rsync optimizado...${NC}"
    
    # Verificar que la app existe
    if [ ! -d "$source_path" ]; then
        echo -e "${RED}❌ $app_name no existe en /Applications${NC}"
        return 1
    fi
    
    # Crear directorio de destino si no existe
    mkdir -p "$BACKUP_DIR"
    
    # Rsync optimizado para SMB remoto
    echo -e "${BLUE}📦 Iniciando transferencia optimizada...${NC}"
    echo -e "${YELLOW}   Esto será MUCHO más rápido que cp...${NC}"
    
    # Usar rsync con opciones optimizadas para SMB
    if rsync -av \
        --progress \
        --partial \
        --inplace \
        --no-perms \
        --no-owner \
        --no-group \
        --no-times \
        --size-only \
        "$source_path/" \
        "$dest_path/"; then
        
        echo -e "${GREEN}✅ Transferencia completada${NC}"
        
        # Verificar que se copió correctamente
        if [ -d "$dest_path" ] && [ -f "$dest_path/Contents/Info.plist" ]; then
            echo -e "${BLUE}🗑️  Removiendo original...${NC}"
            rm -rf "$source_path"
            
            echo -e "${BLUE}🔗 Creando enlace simbólico...${NC}"
            ln -sf "$dest_path" "$source_path"
            
            if [ -L "$source_path" ]; then
                echo -e "${GREEN}✅ $app_name movida exitosamente${NC}"
                
                # Mostrar estadísticas
                local app_size=$(du -sh "$dest_path" 2>/dev/null | cut -f1)
                echo -e "${BLUE}   Tamaño: $app_size${NC}"
                echo -e "${BLUE}   Enlace: $source_path -> $dest_path${NC}"
                
                return 0
            else
                echo -e "${RED}❌ Error creando enlace simbólico${NC}"
                return 1
            fi
        else
            echo -e "${RED}❌ Transferencia incompleta${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Error en transferencia con rsync${NC}"
        return 1
    fi
}

# Función para mostrar velocidad de red
test_network_speed() {
    echo -e "${CYAN}🌐 Probando velocidad de red Thunderbolt...${NC}"
    
    if ping -c 1 192.168.100.1 >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Conexión Thunderbolt activa${NC}"
        
        # Test de velocidad simple
        local test_file="/tmp/speed_test_$$"
        dd if=/dev/zero of="$test_file" bs=1M count=100 2>/dev/null
        
        echo -e "${BLUE}⏱️  Probando velocidad de escritura...${NC}"
        local start_time=$(date +%s)
        cp "$test_file" "$EXTERNAL_MOUNT/" 2>/dev/null
        local end_time=$(date +%s)
        
        rm -f "$test_file" "$EXTERNAL_MOUNT/speed_test_$$"
        
        local duration=$((end_time - start_time))
        if [ $duration -gt 0 ]; then
            local speed=$((100 / duration))
            echo -e "${BLUE}   Velocidad estimada: ~${speed}MB/s${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Conexión directa (no Thunderbolt)${NC}"
    fi
}

# Función principal
main() {
    echo -e "${CYAN}╔═══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║       MOVIMIENTO OPTIMIZADO DE APPS      ║${NC}"
    echo -e "${CYAN}║         (rsync para SMB remoto)           ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════╝${NC}"
    echo
    
    # Configurar rutas
    if ! setup_paths; then
        echo -e "${RED}❌ No se pueden configurar las rutas${NC}"
        exit 1
    fi
    
    # Test de velocidad
    test_network_speed
    echo
    
    # Verificar si se proporcionó una app específica
    if [ -n "$1" ]; then
        move_app_optimized "$1"
        exit $?
    fi
    
    # Mostrar apps disponibles
    echo -e "${BLUE}📱 Aplicaciones disponibles para mover:${NC}"
    echo
    
    local apps=($(ls -1 /Applications | grep "\.app$" | head -10))
    for i in "${!apps[@]}"; do
        local app="${apps[i]}"
        local size=$(du -sh "/Applications/$app" 2>/dev/null | cut -f1)
        printf "${BLUE}%2d. ${NC}%-30s ${YELLOW}%s${NC}\n" $((i+1)) "$app" "$size"
    done
    
    echo
    echo -e "${YELLOW}Ingresa el número de la app a mover (1-${#apps[@]}) o 'q' para salir:${NC}"
    read -r choice
    
    if [[ "$choice" == "q" ]]; then
        echo -e "${BLUE}Saliendo...${NC}"
        exit 0
    fi
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#apps[@]}" ]; then
        local selected_app="${apps[$((choice-1))]}"
        echo
        move_app_optimized "$selected_app"
    else
        echo -e "${RED}❌ Selección inválida${NC}"
        exit 1
    fi
}

# Ejecutar si no se está sourcing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
