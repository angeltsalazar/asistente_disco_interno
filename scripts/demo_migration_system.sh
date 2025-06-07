#!/bin/bash
# Demo del sistema de migración con estado automatizado
# Simula un directorio de prueba y lo migra usando el sistema completo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/machine_config.sh"
source "$SCRIPT_DIR/migration_state.sh"

# Configuración para demo
TEST_DIR="$HOME/migration_demo_test"
EXTERNAL_DISK_MOUNT="/Volumes/BLACK2T"
USER_CONTENT_BASE="$EXTERNAL_DISK_MOUNT/UserContent_${MACHINE_SUFFIX}"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=== DEMO DEL SISTEMA DE MIGRACIÓN AUTOMATIZADO ===${NC}"
echo

# Limpiar demo anterior si existe
if [ -d "$TEST_DIR" ]; then
    echo -e "${YELLOW}🧹 Limpiando demo anterior...${NC}"
    rm -rf "$TEST_DIR"
fi

# Crear directorio de prueba con contenido
echo -e "${BLUE}📁 Creando directorio de prueba: $TEST_DIR${NC}"
mkdir -p "$TEST_DIR"
echo "Archivo de prueba 1" > "$TEST_DIR/test1.txt"
echo "Archivo de prueba 2" > "$TEST_DIR/test2.txt"
mkdir "$TEST_DIR/subcarpeta"
echo "Archivo en subcarpeta" > "$TEST_DIR/subcarpeta/subfile.txt"

echo -e "${GREEN}✅ Directorio de prueba creado con contenido${NC}"
ls -la "$TEST_DIR"
echo

# Inicializar sistema de estado si no existe
if [ ! -f "$STATE_FILE" ]; then
    echo -e "${BLUE}🔧 Inicializando sistema de estado...${NC}"
    create_initial_state
fi

# Verificar estado inicial
echo -e "${CYAN}=== ESTADO INICIAL ===${NC}"
echo "Estado de TestDemo: $(get_directory_status TestDemo)"
echo

# Verificar que el disco externo esté disponible
if [ ! -d "$EXTERNAL_DISK_MOUNT" ]; then
    echo -e "${RED}❌ Disco externo no disponible: $EXTERNAL_DISK_MOUNT${NC}"
    echo -e "${YELLOW}Esta demo requiere que el disco BLACK2T esté montado${NC}"
    exit 1
fi

# Crear estructura base
mkdir -p "$USER_CONTENT_BASE/TestDemo"

echo -e "${BLUE}📊 Tamaño del directorio: $(du -sh "$TEST_DIR" | cut -f1)${NC}"

# Simular migración (version simplificada de move_directory_safe)
echo -e "${CYAN}=== INICIANDO MIGRACIÓN ===${NC}"

# Marcar como en progreso
update_directory_status "TestDemo" "in_progress" "" ""
echo "Estado después de marcar en progreso: $(get_directory_status TestDemo)"

# Crear destino
TARGET_DIR="$USER_CONTENT_BASE/TestDemo/migration_demo_test"
echo -e "${BLUE}📁 Moviendo al disco externo: $TARGET_DIR${NC}"

# Mover con rsync
if rsync -av --remove-source-files "$TEST_DIR/" "$TARGET_DIR/"; then
    # Limpiar directorios vacíos residuales
    find "$TEST_DIR" -type d -empty -delete 2>/dev/null
    
    # Crear enlace simbólico
    if ln -sf "$TARGET_DIR" "$TEST_DIR"; then
        echo -e "${GREEN}✅ Migración exitosa y enlace creado${NC}"
        
        # Actualizar estado a migrado
        size_info=$(du -sh "$TARGET_DIR" | cut -f1)
        update_directory_status "TestDemo" "migrated" "$TARGET_DIR" "" "$size_info" "$size_info"
        
        echo "Estado final: $(get_directory_status TestDemo)"
    else
        echo -e "${RED}❌ Error creando enlace simbólico${NC}"
        update_directory_status "TestDemo" "error" "$TARGET_DIR" ""
    fi
else
    echo -e "${RED}❌ Error en migración${NC}"
    update_directory_status "TestDemo" "error" "" ""
fi

echo

# Verificar resultado
echo -e "${CYAN}=== VERIFICACIÓN ===${NC}"
if [ -L "$TEST_DIR" ]; then
    echo -e "${GREEN}✅ $TEST_DIR es ahora un enlace simbólico${NC}"
    echo "Apunta a: $(readlink "$TEST_DIR")"
    
    if [ -d "$TEST_DIR" ] && [ "$(ls -A "$TEST_DIR" 2>/dev/null)" ]; then
        echo -e "${GREEN}✅ Enlace funciona correctamente${NC}"
        echo "Contenido accessible:"
        ls -la "$TEST_DIR"
    else
        echo -e "${RED}❌ Enlace no funciona${NC}"
    fi
else
    echo -e "${RED}❌ $TEST_DIR no es un enlace simbólico${NC}"
fi

echo

# Mostrar estado final completo
echo -e "${CYAN}=== ESTADO FINAL DEL SISTEMA ===${NC}"
show_migration_status

echo
echo -e "${BLUE}💡 Para limpiar esta demo, puedes ejecutar:${NC}"
echo -e "${YELLOW}   rm -rf $TEST_DIR $TARGET_DIR${NC}"
