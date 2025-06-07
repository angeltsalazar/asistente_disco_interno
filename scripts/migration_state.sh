#!/bin/bash
# Sistema de estado para migración de contenido
# Rastrea qué directorios han sido migrados y su estado
# Autor: Sistema de gestión de estado
# Fecha: $(date)

# Archivo de estado principal
STATE_FILE="$HOME/Documents/scripts/migration_state.json"
LOCK_FILE="$HOME/Documents/scripts/migration.lock"

# Función para crear archivo de estado inicial
create_initial_state() {
    cat > "$STATE_FILE" << EOF
{
  "version": "1.0",
  "machine": "$(hostname -s)",
  "last_updated": "$(date -Iseconds)",
  "external_disk": "/Volumes/BLACK2T",
  "migration_base": "/Volumes/BLACK2T/UserContent_macmini",
  "directories": {
    "Documents": {
      "status": "not_migrated",
      "original_path": "$HOME/Documents",
      "target_path": "",
      "backup_path": "",
      "last_migration": "",
      "size_before": "",
      "size_after": "",
      "checksum": "",
      "auto_update": true
    },
    "Downloads": {
      "status": "not_migrated",
      "original_path": "$HOME/Downloads",
      "target_path": "",
      "backup_path": "",
      "last_migration": "",
      "size_before": "",
      "size_after": "",
      "checksum": "",
      "auto_update": true
    },
    "Pictures": {
      "status": "not_migrated",
      "original_path": "$HOME/Pictures",
      "target_path": "",
      "backup_path": "",
      "last_migration": "",
      "size_before": "",
      "size_after": "",
      "checksum": "",
      "auto_update": true
    },
    "Movies": {
      "status": "not_migrated",
      "original_path": "$HOME/Movies",
      "target_path": "",
      "backup_path": "",
      "last_migration": "",
      "size_before": "",
      "size_after": "",
      "checksum": "",
      "auto_update": false
    },
    "Music": {
      "status": "not_migrated",
      "original_path": "$HOME/Music",
      "target_path": "",
      "backup_path": "",
      "last_migration": "",
      "size_before": "",
      "size_after": "",
      "checksum": "",
      "auto_update": false
    },
    "LibraryCaches": {
      "status": "not_migrated",
      "original_path": "$HOME/Library/Caches",
      "target_path": "",
      "backup_path": "",
      "last_migration": "",
      "size_before": "",
      "size_after": "",
      "checksum": "",
      "auto_update": true
    },
    "DotCache": {
      "status": "not_migrated",
      "original_path": "$HOME/.cache",
      "target_path": "",
      "backup_path": "",
      "last_migration": "",
      "size_before": "",
      "size_after": "",
      "checksum": "",
      "auto_update": true
    },
    "DotLocal": {
      "status": "not_migrated",
      "original_path": "$HOME/.local",
      "target_path": "",
      "backup_path": "",
      "last_migration": "",
      "size_before": "",
      "size_after": "",
      "checksum": "",
      "auto_update": true
    },
    "ApplicationSupport": {
      "status": "not_migrated",
      "original_path": "$HOME/Library/Application Support",
      "target_path": "",
      "backup_path": "",
      "last_migration": "",
      "size_before": "",
      "size_after": "",
      "checksum": "",
      "auto_update": false
    }
  }
}
EOF
}

# Función para leer estado de un directorio
get_directory_status() {
    local dir_name="$1"
    
    if [ ! -f "$STATE_FILE" ]; then
        echo "not_migrated"
        return
    fi
    
    python3 -c "
import json
try:
    with open('$STATE_FILE', 'r') as f:
        data = json.load(f)
    if '$dir_name' in data['directories']:
        print(data['directories']['$dir_name']['status'])
    else:
        print('not_migrated')
except:
    print('not_migrated')
"
}

# Función para actualizar estado de un directorio
update_directory_status() {
    local dir_name="$1"
    local status="$2"
    local target_path="$3"
    local backup_path="$4"
    local size_before="$5"
    local size_after="$6"
    
    if [ ! -f "$STATE_FILE" ]; then
        create_initial_state
    fi
    
    # Limpiar códigos de escape ANSI de las variables
    local clean_status=$(echo "$status" | sed 's/\x1b\[[0-9;]*m//g')
    local clean_target_path=$(echo "$target_path" | sed 's/\x1b\[[0-9;]*m//g')  
    local clean_backup_path=$(echo "$backup_path" | sed 's/\x1b\[[0-9;]*m//g')
    local clean_size_before=$(echo "$size_before" | sed 's/\x1b\[[0-9;]*m//g')
    local clean_size_after=$(echo "$size_after" | sed 's/\x1b\[[0-9;]*m//g')
    
    python3 -c "
import json
from datetime import datetime

with open('$STATE_FILE', 'r') as f:
    data = json.load(f)

# Crear entrada si no existe
if '$dir_name' not in data['directories']:
    data['directories']['$dir_name'] = {
        'status': 'not_migrated',
        'original_path': '',
        'target_path': '',
        'backup_path': '',
        'last_migration': '',
        'size_before': '',
        'size_after': '',
        'checksum': '',
        'auto_update': True
    }

# Actualizar valores con datos limpios
data['directories']['$dir_name']['status'] = '$clean_status'
data['directories']['$dir_name']['target_path'] = '$clean_target_path'
data['directories']['$dir_name']['backup_path'] = '$clean_backup_path'
data['directories']['$dir_name']['last_migration'] = datetime.now().isoformat()
data['directories']['$dir_name']['size_before'] = '$clean_size_before'
data['directories']['$dir_name']['size_after'] = '$clean_size_after'
data['last_updated'] = datetime.now().isoformat()

with open('$STATE_FILE', 'w') as f:
    json.dump(data, f, indent=2)
"
}

# Función para verificar si un directorio necesita actualización
needs_update() {
    local dir_name="$1"
    local original_path="$2"
    
    # Si no está migrado, no necesita actualización
    local status=$(get_directory_status "$dir_name")
    if [ "$status" != "migrated" ]; then
        return 1
    fi
    
    # Verificar si auto_update está habilitado
    local auto_update=$(python3 -c "
import json
try:
    with open('$STATE_FILE', 'r') as f:
        data = json.load(f)
    print(data['directories']['$dir_name']['auto_update'])
except:
    print('false')
")
    
    if [ "$auto_update" != "True" ]; then
        return 1
    fi
    
    # Verificar si el directorio original tiene cambios
    if [ -L "$original_path" ]; then
        # Es un enlace simbólico, verificar si el contenido ha cambiado
        local target_path=$(readlink "$original_path")
        if [ -d "$target_path" ]; then
            # Verificar timestamp de última modificación
            local last_migration=$(python3 -c "
import json
try:
    with open('$STATE_FILE', 'r') as f:
        data = json.load(f)
    print(data['directories']['$dir_name']['last_migration'])
except:
    print('')
")
            
            # Si hay archivos más nuevos que la última migración
            local newer_files=$(find "$target_path" -newer "$STATE_FILE" 2>/dev/null | head -1)
            if [ -n "$newer_files" ]; then
                return 0  # Necesita actualización
            fi
        fi
    fi
    
    return 1  # No necesita actualización
}

# Función para verificar si un directorio necesita actualización
check_needs_update() {
    local dir_name="$1"
    
    # Si no está migrado, no necesita actualización
    local status=$(get_directory_status "$dir_name")
    if [ "$status" != "migrated" ]; then
        return 1
    fi
    
    # Obtener información del directorio
    local dir_info=$(python3 -c "
import json
try:
    with open('$STATE_FILE', 'r') as f:
        data = json.load(f)
    dir_data = data['directories']['$dir_name']
    print(f\"{dir_data['original_path']}|{dir_data['target_path']}|{dir_data['auto_update']}\")
except:
    print('||')
")
    
    local original_path=$(echo "$dir_info" | cut -d'|' -f1)
    local target_path=$(echo "$dir_info" | cut -d'|' -f2)
    local auto_update=$(echo "$dir_info" | cut -d'|' -f3)
    
    # Si auto_update está deshabilitado, no necesita actualización
    if [ "$auto_update" != "true" ] && [ "$auto_update" != "True" ]; then
        return 1
    fi
    
    # Verificar si hay cambios en el directorio original (si no es enlace)
    if [ -d "$original_path" ] && [ ! -L "$original_path" ]; then
        return 0  # Hay un directorio real que no es enlace, necesita sincronización
    fi
    
    # Si es un enlace simbólico, verificar integridad
    if [ -L "$original_path" ]; then
        local current_target=$(readlink "$original_path")
        if [ "$current_target" != "$target_path" ]; then
            return 0  # El enlace apunta a un lugar incorrecto
        fi
        
        # Verificar que el destino existe
        if [ ! -d "$target_path" ]; then
            return 0  # El destino no existe
        fi
    fi
    
    return 1  # No necesita actualización
}

# Función para mostrar estado general
show_migration_status() {
    if [ ! -f "$STATE_FILE" ]; then
        echo "❌ No hay información de estado disponible"
        return
    fi
    
    echo -e "\033[0;36m=== ESTADO DE MIGRACIÓN ===\033[0m"
    echo
    
    python3 -c "
import json
from datetime import datetime

colors = {
    'migrated': '\033[0;32m✅',
    'not_migrated': '\033[0;31m❌',
    'in_progress': '\033[1;33m⚠️',
    'error': '\033[0;31m🚫',
    'needs_update': '\033[1;33m🔄'
}
reset = '\033[0m'

try:
    with open('$STATE_FILE', 'r') as f:
        data = json.load(f)
    
    print(f'Máquina: {data[\"machine\"]}')
    print(f'Última actualización: {data[\"last_updated\"]}')
    print(f'Disco externo: {data[\"external_disk\"]}')
    print()
    
    for dir_name, info in data['directories'].items():
        status = info['status']
        color = colors.get(status, '\033[0;37m❓')
        auto_update = '🔄' if info['auto_update'] else '🔒'
        
        print(f'{color} {dir_name:<18} {status:<12} {auto_update} {reset}')
        
        if status == 'migrated' and info['size_before']:
            print(f'   Tamaño antes: {info[\"size_before\"]} → después: {info[\"size_after\"]}')
        
        if info['last_migration']:
            migration_date = datetime.fromisoformat(info['last_migration'].replace('Z', '+00:00'))
            print(f'   Última migración: {migration_date.strftime(\"%Y-%m-%d %H:%M:%S\")}')
        
        print()

except Exception as e:
    print(f'Error leyendo estado: {e}')
"
    
    echo -e "\033[0;34mLeyenda:\033[0m"
    echo -e "✅ Migrado  ❌ No migrado  ⚠️ En progreso  🚫 Error"
    echo -e "🔄 Auto-actualización habilitada  🔒 Solo manual"
}

# Función para crear marcador de proceso en curso
start_migration() {
    local dir_name="$1"
    echo "$$" > "$LOCK_FILE"
    update_directory_status "$dir_name" "in_progress" "" "" "" ""
}

# Función para finalizar migración
finish_migration() {
    local dir_name="$1"
    local status="$2"
    local target_path="$3"
    local backup_path="$4"
    local size_before="$5"
    local size_after="$6"
    
    update_directory_status "$dir_name" "$status" "$target_path" "$backup_path" "$size_before" "$size_after"
    rm -f "$LOCK_FILE"
}

# Función para verificar si hay proceso en curso
is_migration_running() {
    if [ -f "$LOCK_FILE" ]; then
        local pid=$(cat "$LOCK_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0  # Hay proceso corriendo
        else
            rm -f "$LOCK_FILE"  # Limpiar lock file huérfano
        fi
    fi
    return 1  # No hay proceso corriendo
}

# Función para actualizar contenido migrado
sync_migrated_content() {
    local dir_name="$1"
    local force="$2"
    
    local status=$(get_directory_status "$dir_name")
    if [ "$status" != "migrated" ]; then
        echo "❌ $dir_name no está migrado"
        return 1
    fi
    
    if [ "$force" != "force" ] && ! needs_update "$dir_name" ""; then
        echo "✅ $dir_name está actualizado"
        return 0
    fi
    
    echo "🔄 Sincronizando $dir_name..."
    
    # Obtener rutas del estado
    local original_path=$(python3 -c "
import json
try:
    with open('$STATE_FILE', 'r') as f:
        data = json.load(f)
    print(data['directories']['$dir_name']['original_path'])
except:
    print('')
")
    
    local target_path=$(python3 -c "
import json
try:
    with open('$STATE_FILE', 'r') as f:
        data = json.load(f)
    print(data['directories']['$dir_name']['target_path'])
except:
    print('')
")
    
    if [ -L "$original_path" ] && [ -d "$target_path" ]; then
        # Sincronizar cambios
        rsync -av --delete "$(readlink "$original_path")/" "$target_path/"
        echo "✅ Sincronización completada para $dir_name"
        
        # Actualizar timestamp
        update_directory_status "$dir_name" "migrated" "$target_path" "" "" ""
    else
        echo "❌ Error: Rutas no válidas para $dir_name"
        return 1
    fi
}

# Si se llama directamente, mostrar estado
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-status}" in
        "status")
            show_migration_status
            ;;
        "init")
            create_initial_state
            echo "✅ Archivo de estado inicializado"
            ;;
        "update")
            sync_migrated_content "$2" "$3"
            ;;
        *)
            echo "Uso: $0 [status|init|update <directorio> [force]]"
            ;;
    esac
fi
