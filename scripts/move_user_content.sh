#!/bin/bash
# Script integral para mover contenido no crítico del usuario al SSD externo
# Incluye: Documents, Downloads, Pictures, Movies, Music, Caches, Development tools
# Autor: Sistema de gestión de contenido
# Fecha: $(date)

# Configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/machine_config.sh" 2>/dev/null || {
    echo "❌ Error: No se pudo cargar machine_config.sh"
    exit 1
}

# Cargar sistema de estado
source "$SCRIPT_DIR/migration_state.sh" 2>/dev/null || {
    echo "❌ Error: No se pudo cargar migration_state.sh"
    exit 1
}

# Configuración del disco externo
EXTERNAL_DISK_MOUNT="/Volumes/BLACK2T"
USER_CONTENT_BASE="$EXTERNAL_DISK_MOUNT/UserContent_${MACHINE_SUFFIX}"
LOG_FILE="$HOME/Documents/scripts/move_user_content_${MACHINE_SUFFIX}.log"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Función para logging
log_message() {
    local message="$1"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    
    # Mostrar en terminal con colores
    echo -e "$timestamp - $message"
    
    # Guardar en log sin códigos de color
    local clean_message=$(echo -e "$message" | sed 's/\x1b\[[0-9;]*m//g')
    echo "$timestamp - $clean_message" >> "$LOG_FILE"
}

# Función para detectar el punto de montaje real
find_real_mount_point() {
    local disk_name="$1"
    local base_path="/Volumes/$disk_name"
    
    # Verificar montaje sin sufijo
    if [ -d "$base_path" ] && [ "$(ls -A "$base_path" 2>/dev/null)" ]; then
        echo "$base_path"
        return 0
    fi
    
    # Buscar con sufijos
    for suffix in "-1" "-2" "-3"; do
        local path_with_suffix="${base_path}${suffix}"
        if [ -d "$path_with_suffix" ] && [ "$(ls -A "$path_with_suffix" 2>/dev/null)" ]; then
            echo "$path_with_suffix"
            return 0
        fi
    done
    
    return 1
}

# Verificar disco externo
check_external_disk() {
    log_message "${BLUE}🔍 Verificando disco externo...${NC}"
    
    local real_mount=$(find_real_mount_point "BLACK2T")
    if [ -z "$real_mount" ]; then
        log_message "${RED}❌ Disco BLACK2T no encontrado o no montado${NC}"
        return 1
    fi
    
    EXTERNAL_DISK_MOUNT="$real_mount"
    USER_CONTENT_BASE="$EXTERNAL_DISK_MOUNT/UserContent_${MACHINE_SUFFIX}"
    
    log_message "${GREEN}✅ Disco encontrado en: $EXTERNAL_DISK_MOUNT${NC}"
    return 0
}

# Crear backup antes de mover
create_backup() {
    local source_dir="$1"
    local backup_dir="$USER_CONTENT_BASE/backups/$(date +%Y%m%d_%H%M%S)"
    
    if [ -d "$source_dir" ] && [ "$(ls -A "$source_dir" 2>/dev/null)" ]; then
        log_message "${BLUE}📦 Creando backup de $(basename "$source_dir")...${NC}"
        mkdir -p "$backup_dir"
        if rsync -av --progress "$source_dir/" "$backup_dir/$(basename "$source_dir")_backup/" 2>/dev/null; then
            log_message "${GREEN}✅ Backup creado en: $backup_dir${NC}"
            echo "$backup_dir/$(basename "$source_dir")_backup"
        else
            log_message "${YELLOW}⚠️  Error creando backup${NC}"
            echo ""
        fi
    else
        echo ""
    fi
}

# Mover directorio con enlace simbólico
move_directory_safe() {
    local source_dir="$1"
    local target_subdir="$2"
    local create_backup="$3"
    local dir_name=$(basename "$source_dir")
    
    log_message "${CYAN}=== Procesando: $dir_name ===${NC}"
    
    # Verificar estado actual
    local current_status=$(get_directory_status "$dir_name")
    if [ "$current_status" = "migrated" ]; then
        # Verificar si necesita actualización
        if check_needs_update "$dir_name"; then
            log_message "${YELLOW}🔄 $dir_name requiere sincronización${NC}"
            sync_directory "$dir_name"
            return $?
        else
            log_message "${GREEN}✅ $dir_name ya está migrado y actualizado${NC}"
            return 0
        fi
    fi
    
    # Verificar que el directorio existe y no es vacío
    if [ ! -d "$source_dir" ]; then
        log_message "${YELLOW}⚠️  $source_dir no existe, saltando...${NC}"
        update_directory_status "$dir_name" "not_migrated" "" ""
        return 0
    fi
    
    if [ -L "$source_dir" ]; then
        log_message "${BLUE}🔗 $dir_name ya es un enlace simbólico${NC}"
        # Actualizar estado si no estaba registrado
        local target_path=$(readlink "$source_dir")
        update_directory_status "$dir_name" "migrated" "$target_path" ""
        return 0
    fi
    
    # Verificar tamaño antes de migrar
    local size_before=$(du -sh "$source_dir" 2>/dev/null | cut -f1)
    log_message "${BLUE}📊 Tamaño de $dir_name: $size_before${NC}"
    
    # Marcar como en progreso
    update_directory_status "$dir_name" "in_progress" "" ""
    
    # Crear backup si se solicita
    local backup_path=""
    if [ "$create_backup" = "true" ]; then
        backup_path=$(create_backup "$source_dir")
    fi
    
    # Crear directorio destino
    local target_dir="$USER_CONTENT_BASE/$target_subdir/$dir_name"
    mkdir -p "$(dirname "$target_dir")"
    
    log_message "${BLUE}📁 Moviendo $dir_name al disco externo...${NC}"
    
    # Mover usando rsync para mejor rendimiento
    if rsync -av --progress --remove-source-files "$source_dir/" "$target_dir/"; then
        # Limpiar directorios vacíos residuales
        find "$source_dir" -type d -empty -delete 2>/dev/null
        
        # Crear enlace simbólico
        log_message "${BLUE}🔗 Creando enlace simbólico...${NC}"
        if ln -sf "$target_dir" "$source_dir"; then
            log_message "${GREEN}✅ $dir_name movido y enlazado exitosamente${NC}"
            
            # Verificar que el enlace funciona
            if [ -d "$source_dir" ] && [ "$(ls -A "$source_dir" 2>/dev/null)" ]; then
                log_message "${GREEN}✅ Enlace simbólico verificado correctamente${NC}"
                
                # Actualizar estado a migrado
                local size_after=$(du -sh "$target_dir" 2>/dev/null | cut -f1)
                update_directory_status "$dir_name" "migrated" "$target_dir" "$backup_path" "$size_before" "$size_after"
                
                return 0
            else
                log_message "${RED}❌ Error: Enlace simbólico no funciona correctamente${NC}"
                update_directory_status "$dir_name" "error" "$target_dir" "$backup_path"
                return 1
            fi
        else
            log_message "${RED}❌ Error creando enlace simbólico${NC}"
            update_directory_status "$dir_name" "error" "$target_dir" "$backup_path"
            return 1
        fi
    else
        log_message "${RED}❌ Error moviendo $dir_name${NC}"
        update_directory_status "$dir_name" "error" "" "$backup_path"
        return 1
    fi
}

# Función para sincronizar un directorio migrado
sync_directory() {
    local dir_name="$1"
    
    log_message "${CYAN}🔄 Sincronizando: $dir_name${NC}"
    
    # Obtener información del estado
    local status_info=$(python3 -c "
import json
try:
    with open('$STATE_FILE', 'r') as f:
        data = json.load(f)
    dir_info = data['directories']['$dir_name']
    print(f\"{dir_info['original_path']}|{dir_info['target_path']}\")
except:
    print('|')
")
    
    local original_path=$(echo "$status_info" | cut -d'|' -f1)
    local target_path=$(echo "$status_info" | cut -d'|' -f2)
    
    if [ -z "$target_path" ] || [ ! -d "$target_path" ]; then
        log_message "${RED}❌ Error: No se encontró el directorio destino${NC}"
        return 1
    fi
    
    # Si el original es un enlace simbólico, sincronizar desde el destino
    if [ -L "$original_path" ]; then
        log_message "${BLUE}🔗 Directorio ya está enlazado, verificando integridad...${NC}"
        
        # Verificar que el enlace apunta al lugar correcto
        local current_target=$(readlink "$original_path")
        if [ "$current_target" != "$target_path" ]; then
            log_message "${YELLOW}⚠️  Corrigiendo enlace simbólico...${NC}"
            rm "$original_path"
            ln -sf "$target_path" "$original_path"
        fi
        
        log_message "${GREEN}✅ Sincronización verificada${NC}"
        update_directory_status "$dir_name" "migrated" "$target_path" ""
        return 0
    fi
    
    # Si hay cambios en el directorio original, sincronizar al destino
    if [ -d "$original_path" ] && [ ! -L "$original_path" ]; then
        log_message "${BLUE}📁 Sincronizando cambios al disco externo...${NC}"
        
        if rsync -av --update --progress "$original_path/" "$target_path/"; then
            log_message "${GREEN}✅ Cambios sincronizados exitosamente${NC}"
            
            # Ahora mover el contenido y crear enlace si es necesario
            if [ "$(ls -A "$original_path" 2>/dev/null)" ]; then
                rm -rf "$original_path"
                ln -sf "$target_path" "$original_path"
                log_message "${GREEN}✅ Enlace simbólico restaurado${NC}"
            fi
            
            update_directory_status "$dir_name" "migrated" "$target_path" ""
            return 0
        else
            log_message "${RED}❌ Error sincronizando cambios${NC}"
            return 1
        fi
    fi
    
    return 0
}

# Mostrar espacio ahorrado
show_space_saved() {
    log_message "${CYAN}=== RESUMEN DE ESPACIO ===${NC}"
    
    # Calcular espacio en disco interno
    local internal_used=$(df -h / | tail -1 | awk '{print $3}')
    local internal_available=$(df -h / | tail -1 | awk '{print $4}')
    local internal_percent=$(df -h / | tail -1 | awk '{print $5}')
    
    echo -e "${BLUE}💾 Disco interno:${NC}"
    echo -e "   Usado: $internal_used | Disponible: $internal_available | Uso: $internal_percent"
    
    # Mostrar contenido movido
    if [ -d "$USER_CONTENT_BASE" ]; then
        local external_used=$(du -sh "$USER_CONTENT_BASE" 2>/dev/null | cut -f1)
        echo -e "${GREEN}💿 Contenido en disco externo: $external_used${NC}"
    fi
    
    # Contar enlaces simbólicos creados
    local symlink_count=0
    for dir in ~/Documents ~/Downloads ~/Pictures ~/Movies ~/Music; do
        [ -L "$dir" ] && ((symlink_count++))
    done
    echo -e "${PURPLE}🔗 Enlaces simbólicos activos: $symlink_count${NC}"
}

# Menú principal
show_menu() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                              ║${NC}"
    echo -e "${CYAN}║        MIGRACIÓN DE CONTENIDO DE USUARIO AL SSD EXTERNO     ║${NC}"
    echo -e "${CYAN}║                                                              ║${NC}"
    echo -e "${CYAN}║  Mueve directorios grandes del usuario al disco externo     ║${NC}"
    echo -e "${CYAN}║  manteniendo enlaces simbólicos para acceso transparente    ║${NC}"
    echo -e "${CYAN}║                                                              ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    log_message "${BLUE}Usuario: $(whoami) | Máquina: $MACHINE_SUFFIX${NC}"
    log_message "${BLUE}Disco externo: $EXTERNAL_DISK_MOUNT${NC}"
    echo
    
    echo -e "${YELLOW}=== DIRECTORIOS PRINCIPALES ===${NC}"
    echo -e "${BLUE} 1. 📁 Documents (documentos del usuario)${NC}"
    echo -e "${BLUE} 2. 📥 Downloads (descargas)${NC}"
    echo -e "${BLUE} 3. 🖼️  Pictures (imágenes)${NC}"
    echo -e "${BLUE} 4. 🎬 Movies (videos)${NC}"
    echo -e "${BLUE} 5. 🎵 Music (música)${NC}"
    echo
    
    echo -e "${YELLOW}=== DIRECTORIOS DE DESARROLLO ===${NC}"
    echo -e "${BLUE} 6. 🧹 Caches (~/Library/Caches + ~/.cache)${NC}"
    echo -e "${BLUE} 7. 🛠️  Development tools (.local, .npm, .cargo, etc.)${NC}"
    echo -e "${BLUE} 8. 📱 Application Support (datos de apps)${NC}"
    echo
    
    echo -e "${YELLOW}=== OPCIONES MASIVAS ===${NC}"
    echo -e "${BLUE} 9. 🚀 Mover todos los directorios principales (1-5)${NC}"
    echo -e "${BLUE}10. 🧰 Mover todo el contenido de desarrollo (6-8)${NC}"
    echo -e "${BLUE}11. 🌟 Migración completa (todo)${NC}"
    echo
    
    echo -e "${YELLOW}=== UTILIDADES ===${NC}"
    echo -e "${BLUE}12. 📊 Ver espacio y estado actual${NC}"
    echo -e "${BLUE}13. � Ver estado de migración detallado${NC}"
    echo -e "${BLUE}14. �🔄 Restaurar directorio específico${NC}"
    echo -e "${BLUE}15. 📋 Ver logs de migración${NC}"
    echo -e "${BLUE}16. 🚪 Salir${NC}"
    echo
}

# Función principal
main() {
    log_message "${CYAN}=== INICIO DE MIGRACIÓN DE CONTENIDO DE USUARIO ===${NC}"
    
    # Inicializar sistema de estado si no existe
    if [ ! -f "$STATE_FILE" ]; then
        log_message "${BLUE}🔧 Inicializando sistema de estado...${NC}"
        create_initial_state
    fi
    
    # Verificaciones previas
    if ! check_external_disk; then
        echo -e "${RED}❌ No se puede continuar sin disco externo${NC}"
        exit 1
    fi
    
    # Crear estructura base
    mkdir -p "$USER_CONTENT_BASE"/{Documents,Downloads,Pictures,Movies,Music,Development,AppSupport,backups}
    
    while true; do
        show_menu
        echo -e "${YELLOW}Selecciona una opción (1-16):${NC}"
        read -r choice
        
        case $choice in
            1)
                move_directory_safe "$HOME/Documents" "Documents" true
                ;;
            2)
                move_directory_safe "$HOME/Downloads" "Downloads" true
                ;;
            3)
                move_directory_safe "$HOME/Pictures" "Pictures" true
                ;;
            4)
                move_directory_safe "$HOME/Movies" "Movies" true
                ;;
            5)
                move_directory_safe "$HOME/Music" "Music" true
                ;;
            6)
                echo -e "${BLUE}🧹 Moviendo caches...${NC}"
                move_directory_safe "$HOME/Library/Caches" "Development" false
                move_directory_safe "$HOME/.cache" "Development" false
                ;;
            7)
                echo -e "${BLUE}🛠️  Moviendo herramientas de desarrollo...${NC}"
                move_directory_safe "$HOME/.local" "Development" false
                move_directory_safe "$HOME/.npm" "Development" false
                move_directory_safe "$HOME/.cargo" "Development" false
                move_directory_safe "$HOME/.ollama" "Development" false
                ;;
            8)
                move_directory_safe "$HOME/Library/Application Support" "AppSupport" false
                ;;
            9)
                echo -e "${BLUE}🚀 Migrando todos los directorios principales...${NC}"
                move_directory_safe "$HOME/Documents" "Documents" true
                move_directory_safe "$HOME/Downloads" "Downloads" true
                move_directory_safe "$HOME/Pictures" "Pictures" true
                move_directory_safe "$HOME/Movies" "Movies" true
                move_directory_safe "$HOME/Music" "Music" true
                ;;
            10)
                echo -e "${BLUE}🧰 Migrando contenido de desarrollo...${NC}"
                move_directory_safe "$HOME/Library/Caches" "Development" false
                move_directory_safe "$HOME/.cache" "Development" false
                move_directory_safe "$HOME/.local" "Development" false
                move_directory_safe "$HOME/.npm" "Development" false
                move_directory_safe "$HOME/.cargo" "Development" false
                move_directory_safe "$HOME/.ollama" "Development" false
                move_directory_safe "$HOME/Library/Application Support" "AppSupport" false
                ;;
            11)
                echo -e "${BLUE}🌟 Iniciando migración completa...${NC}"
                echo -e "${YELLOW}⚠️  Esto moverá TODOS los directorios. ¿Continuar? (y/N):${NC}"
                read -r confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    # Directorios principales
                    move_directory_safe "$HOME/Documents" "Documents" true
                    move_directory_safe "$HOME/Downloads" "Downloads" true
                    move_directory_safe "$HOME/Pictures" "Pictures" true
                    move_directory_safe "$HOME/Movies" "Movies" true
                    move_directory_safe "$HOME/Music" "Music" true
                    
                    # Desarrollo
                    move_directory_safe "$HOME/Library/Caches" "Development" false
                    move_directory_safe "$HOME/.cache" "Development" false
                    move_directory_safe "$HOME/.local" "Development" false
                    move_directory_safe "$HOME/.npm" "Development" false
                    move_directory_safe "$HOME/.cargo" "Development" false
                    move_directory_safe "$HOME/.ollama" "Development" false
                    move_directory_safe "$HOME/Library/Application Support" "AppSupport" false
                    
                    echo -e "${GREEN}🎉 Migración completa finalizada${NC}"
                else
                    echo -e "${BLUE}Migración cancelada${NC}"
                fi
                ;;
            12)
                show_space_saved
                ;;
            13)
                show_migration_status
                ;;
            14)
                echo -e "${BLUE}🔄 Funcionalidad de restauración (próximamente)${NC}"
                ;;
            15)
                echo -e "${BLUE}📋 Últimas 20 líneas del log:${NC}"
                tail -20 "$LOG_FILE" 2>/dev/null || echo "No hay logs disponibles"
                ;;
            16)
                log_message "${BLUE}🚪 Saliendo del migrador de contenido...${NC}"
                echo -e "${GREEN}¡Gracias por usar el migrador de contenido!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Opción inválida. Selecciona 1-16.${NC}"
                ;;
        esac
        
        echo
        echo -e "${BLUE}Presiona Enter para continuar...${NC}"
        read -r
        clear
    done
}

# Ejecutar si no se está sourcing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
