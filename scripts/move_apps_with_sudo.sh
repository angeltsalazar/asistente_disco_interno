#!/bin/bash
# Script para mover aplicaciones con manejo automático de permisos
# Maneja aplicaciones protegidas por SIP y casos especiales
# Autor: Script optimizado para aplicaciones del sistema
# Fecha: $(date)

# Función para detectar punto de montaje real
find_real_mount_point() {
    local disk_name="$1"
    
    # Buscar punto de montaje con o sin sufijo
    for suffix in "" "-1" "-2" "-3"; do
        local mount_path="/Volumes/${disk_name}${suffix}"
        if [ -d "$mount_path" ] && [ "$(ls -A "$mount_path" 2>/dev/null)" ]; then
            echo "$mount_path"
            return 0
        fi
    done
    
    return 1
}

# Configuración
EXTERNAL_DISK_NAME="BLACK2T"
EXTERNAL_APPS_FOLDER="Applications_safe_macmini"
EXTERNAL_DISK_MOUNT=$(find_real_mount_point "$EXTERNAL_DISK_NAME")
EXTERNAL_APPS_DIR="$EXTERNAL_DISK_MOUNT/${EXTERNAL_APPS_FOLDER}"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Función para verificar si una app necesita sudo
needs_sudo_permission() {
    local app_path="$1"
    
    # Verificar si tiene archivos protegidos
    if find "$app_path" -type f -name "*.framework" -o -name "*.app" 2>/dev/null | grep -q "ProApps\|System"; then
        return 0  # Necesita sudo
    fi
    
    # Verificar si tiene permisos especiales
    if ! rm -rf "/tmp/test_permissions_$$" 2>/dev/null; then
        return 0  # Necesita sudo
    fi
    
    return 1  # No necesita sudo
}

# Función para mover aplicación con rsync optimizado
move_app_optimized() {
    local app_name="$1"
    local source_path="/Applications/$app_name"
    local dest_path="$EXTERNAL_APPS_DIR/$app_name"
    local use_sudo="$2"
    
    echo -e "${CYAN}=== Moviendo $app_name ===${NC}"
    
    # Verificar que existe
    if [ ! -d "$source_path" ]; then
        echo -e "${RED}❌ $app_name no encontrada en /Applications${NC}"
        return 1
    fi
    
    # Obtener tamaño
    local size=$(du -sh "$source_path" | cut -f1)
    echo -e "${BLUE}📱 Aplicación: $app_name${NC}"
    echo -e "${BLUE}📏 Tamaño: $size${NC}"
    echo -e "${BLUE}🎯 Destino: $dest_path${NC}"
    
    # Crear directorio destino si no existe
    mkdir -p "$EXTERNAL_APPS_DIR"
    
    echo -e "${YELLOW}🚀 Iniciando copia optimizada con rsync...${NC}"
    local start_time=$(date +%s)
    
    # Usar rsync con optimizaciones para SMB
    local rsync_cmd="rsync -av --progress --inplace --no-perms --no-owner --no-group --exclude '.DS_Store' --exclude '.Trashes'"
    
    if [ "$use_sudo" = "true" ]; then
        if sudo $rsync_cmd "$source_path/" "$dest_path/"; then
            echo -e "${GREEN}✅ Copia completada exitosamente${NC}"
        else
            echo -e "${RED}❌ Error en la copia${NC}"
            return 1
        fi
    else
        if $rsync_cmd "$source_path/" "$dest_path/"; then
            echo -e "${GREEN}✅ Copia completada exitosamente${NC}"
        else
            echo -e "${RED}❌ Error en la copia${NC}"
            return 1
        fi
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    echo -e "${GREEN}⏱️  Tiempo: ${duration}s${NC}"
    
    # Eliminar original
    echo -e "${YELLOW}🗑️  Eliminando original...${NC}"
    if [ "$use_sudo" = "true" ]; then
        if sudo rm -rf "$source_path"; then
            echo -e "${GREEN}✅ Original eliminado${NC}"
        else
            echo -e "${RED}❌ Error eliminando original${NC}"
            return 1
        fi
    else
        if rm -rf "$source_path"; then
            echo -e "${GREEN}✅ Original eliminado${NC}"
        else
            echo -e "${RED}❌ Error eliminando original${NC}"
            return 1
        fi
    fi
    
    # Crear enlace simbólico
    echo -e "${YELLOW}🔗 Creando enlace simbólico...${NC}"
    if sudo ln -sf "$dest_path" "$source_path"; then
        echo -e "${GREEN}✅ Enlace simbólico creado${NC}"
    else
        echo -e "${RED}❌ Error creando enlace simbólico${NC}"
        return 1
    fi
    
    # Verificar funcionamiento
    if [ -e "$source_path/Contents/Info.plist" ]; then
        echo -e "${GREEN}✅ $app_name movida exitosamente y funcionando${NC}"
        return 0
    else
        echo -e "${RED}❌ Error: enlace no funciona correctamente${NC}"
        return 1
    fi
}

# Función principal
main() {
    echo -e "${CYAN}=== MOVIMIENTO OPTIMIZADO DE APLICACIONES ===${NC}"
    echo -e "${BLUE}Con manejo automático de permisos y rsync${NC}"
    echo
    
    # Verificar disco externo
    if [ ! -d "$EXTERNAL_DISK_MOUNT" ]; then
        echo -e "${RED}❌ Disco externo no montado: $EXTERNAL_DISK_NAME${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Disco externo: $EXTERNAL_DISK_MOUNT${NC}"
    echo -e "${GREEN}✅ Directorio apps: $EXTERNAL_APPS_DIR${NC}"
    echo
    
    # Lista de aplicaciones candidatas (no críticas)
    local apps_to_move=(
        "GarageBand.app"
        "Pieces OS.app"
        "calibre.app"
        "Keynote.app"
        "Pages.app"
        "Numbers.app"
        "Pieces.app"
        "HelpWire Client.app"
    )
    
    echo -e "${YELLOW}Aplicaciones candidatas para mover:${NC}"
    for app in "${apps_to_move[@]}"; do
        if [ -d "/Applications/$app" ]; then
            local size=$(du -sh "/Applications/$app" | cut -f1)
            echo -e "${BLUE}  - $app ($size)${NC}"
        fi
    done
    echo
    
    echo -e "${YELLOW}¿Continuar con el movimiento? (y/n):${NC}"
    read -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Operación cancelada${NC}"
        exit 0
    fi
    
    # Mover cada aplicación
    local moved_count=0
    for app in "${apps_to_move[@]}"; do
        if [ -d "/Applications/$app" ]; then
            echo
            # Detectar si necesita sudo
            local use_sudo="false"
            if needs_sudo_permission "/Applications/$app"; then
                use_sudo="true"
                echo -e "${YELLOW}⚠️  $app requiere permisos administrativos${NC}"
            fi
            
            if move_app_optimized "$app" "$use_sudo"; then
                ((moved_count++))
            fi
        fi
    done
    
    echo
    echo -e "${CYAN}=== RESUMEN ===${NC}"
    echo -e "${GREEN}✅ Aplicaciones movidas: $moved_count${NC}"
    echo -e "${BLUE}Los enlaces simbólicos permiten usar las apps normalmente${NC}"
    echo -e "${BLUE}Las apps están ahora en: $EXTERNAL_APPS_DIR${NC}"
}

# Ejecutar si se llama directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
