#!/bin/bash
# Script de prueba para el sistema de migración integrado
# Prueba las funciones de estado y sincronización

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/migration_state.sh"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=== PRUEBA DEL SISTEMA DE MIGRACIÓN INTEGRADO ===${NC}"
echo

# Función de prueba
test_function() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "${BLUE}🧪 Probando: $test_name${NC}"
    
    if eval "$test_command"; then
        echo -e "${GREEN}✅ $test_name: EXITOSO${NC}"
    else
        echo -e "${RED}❌ $test_name: FALLIDO${NC}"
    fi
    echo
}

# Pruebas del sistema
echo -e "${YELLOW}=== PRUEBAS DE SISTEMA DE ESTADO ===${NC}"

# 1. Inicialización
test_function "Inicialización del estado" "create_initial_state"

# 2. Lectura de estado
test_function "Lectura de estado Documents" "get_directory_status Documents"

# 3. Actualización de estado
test_function "Actualización de estado Documents" "update_directory_status Documents migrated /test/path /test/backup 1GB 1GB"

# 4. Verificación de necesidad de actualización
test_function "Verificación de actualización Documents" "check_needs_update Documents"

# 5. Mostrar estado
echo -e "${YELLOW}=== ESTADO ACTUAL ===${NC}"
show_migration_status

echo -e "${CYAN}=== PRUEBAS COMPLETADAS ===${NC}"
echo -e "${BLUE}Estado del archivo: $STATE_FILE${NC}"
if [ -f "$STATE_FILE" ]; then
    echo -e "${GREEN}✅ Archivo de estado existe${NC}"
    echo -e "${BLUE}Tamaño: $(ls -lh "$STATE_FILE" | awk '{print $5}')${NC}"
else
    echo -e "${RED}❌ Archivo de estado no existe${NC}"
fi
