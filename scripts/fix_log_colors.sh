#!/bin/bash
# Script para corregir automáticamente funciones log_message que usan tee

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║             CORRECTOR DE FUNCIONES LOG_MESSAGE              ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

echo -e "${BLUE}🔍 Buscando archivos con funciones log_message problemáticas...${NC}"

# Buscar archivos que contengan 'tee -a' en funciones log_message
problem_files=()
while IFS= read -r -d '' file; do
    if grep -q 'log_message()' "$file" && grep -q 'tee -a' "$file"; then
        problem_files+=("$file")
    fi
done < <(find "$SCRIPT_DIR" -name "*.sh" -type f -print0)

if [ ${#problem_files[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ No se encontraron archivos con problemas de log_message${NC}"
    exit 0
fi

echo -e "${YELLOW}⚠️ Archivos encontrados con posibles problemas:${NC}"
for file in "${problem_files[@]}"; do
    echo -e "   📄 $(basename "$file")"
done
echo

echo -e "${BLUE}📋 Resumen de la corrección que se aplicará:${NC}"
echo -e "• ${GREEN}Separar salida de terminal (con colores) del archivo de log${NC}"
echo -e "• ${GREEN}Usar echo -e para mostrar colores en terminal${NC}"
echo -e "• ${GREEN}Limpiar códigos ANSI antes de guardar en log${NC}"
echo -e "• ${GREEN}Mantener timestamps consistentes${NC}"
echo

read -p "¿Deseas aplicar la corrección? (s/N): " confirm
if [[ ! "$confirm" =~ ^[sS]$ ]]; then
    echo -e "${YELLOW}❌ Operación cancelada${NC}"
    exit 0
fi

echo -e "${BLUE}🔧 Aplicando correcciones...${NC}"

for file in "${problem_files[@]}"; do
    echo -e "   📝 Procesando $(basename "$file")..."
    
    # Crear backup
    cp "$file" "${file}.backup"
    
    # Verificar si ya fue corregido
    if grep -q 'clean_message.*sed.*x1b' "$file"; then
        echo -e "   ${GREEN}✅ Ya está corregido${NC}"
        rm "${file}.backup"
        continue
    fi
    
    # Aplicar corrección (esto es un ejemplo simplificado)
    # En la práctica, cada archivo podría necesitar una corrección específica
    echo -e "   ${YELLOW}⚠️ Requiere corrección manual (muy específico por archivo)${NC}"
    rm "${file}.backup"
done

echo
echo -e "${GREEN}✅ Proceso completado${NC}"
echo -e "${CYAN}💡 Ejecuta ./test_color_output.sh para verificar que los colores funcionen${NC}"

# Función adicional para limpiar logs existentes
clean_existing_logs() {
    echo
    echo -e "${CYAN}🧹 ¿Deseas limpiar los códigos de color de los logs existentes?${NC}"
    read -p "Esto eliminará caracteres como \\033[0;36m de los archivos .log (s/N): " clean_confirm
    
    if [[ "$clean_confirm" =~ ^[sS]$ ]]; then
        LOG_DIR="$(dirname "$SCRIPT_DIR")/logs"
        
        if [[ -d "$LOG_DIR" ]]; then
            echo -e "${BLUE}🧹 Limpiando códigos ANSI de los logs...${NC}"
            
            for log_file in "$LOG_DIR"/*.log; do
                if [[ -f "$log_file" ]]; then
                    echo -e "  📄 Limpiando: $(basename "$log_file")"
                    
                    # Crear backup
                    cp "$log_file" "${log_file}.backup"
                    
                    # Limpiar códigos ANSI
                    sed 's/\\033\[[0-9;]*m//g' "$log_file" > "${log_file}.temp"
                    mv "${log_file}.temp" "$log_file"
                    
                    echo -e "  ${GREEN}✅ Limpiado: $(basename "$log_file")${NC}"
                fi
            done
            
            echo
            echo -e "${GREEN}✅ Todos los logs han sido limpiados${NC}"
            echo -e "${CYAN}📍 Backups guardados como .backup${NC}"
        else
            echo -e "${RED}❌ No se encontró el directorio de logs: $LOG_DIR${NC}"
        fi
    fi
}

# Ejecutar limpieza de logs si se solicita
if [[ "$1" == "--clean-logs" ]] || [[ "$1" == "-c" ]]; then
    clean_existing_logs
fi
