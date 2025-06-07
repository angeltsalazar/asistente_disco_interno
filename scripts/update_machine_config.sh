#!/bin/bash
# Script para actualizar sufijos de máquina en todos los scripts
# Este script facilita el cambio entre Mac Mini, Mac Studio, y Mac Pro

SCRIPT_DIR="$HOME/Documents/scripts"
source "$SCRIPT_DIR/machine_config.sh"

# Lista de scripts que necesitan actualización
SCRIPTS_TO_UPDATE=(
    "safe_move_apps.sh"
    "move_apps_to_external.sh"
    "restore_apps_from_external.sh"
    "monitor_external_apps.sh"
    "manage_user_data.sh"
    "clean_system_caches.sh"
)

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

update_scripts() {
    local new_suffix="$1"
    local old_suffix="$2"
    
    echo -e "${BLUE}Actualizando scripts de '$old_suffix' a '$new_suffix'...${NC}"
    echo
    
    for script in "${SCRIPTS_TO_UPDATE[@]}"; do
        local script_path="$SCRIPT_DIR/$script"
        
        if [ -f "$script_path" ]; then
            echo -e "${YELLOW}Actualizando $script...${NC}"
            
            # Crear backup
            cp "$script_path" "$script_path.backup_$(date +%Y%m%d_%H%M%S)"
            
            # Actualizar sufijos en rutas
            sed -i '' "s/_${old_suffix}\"/_${new_suffix}\"/g" "$script_path"
            sed -i '' "s/_${old_suffix}\.log/_${new_suffix}.log/g" "$script_path"
            sed -i '' "s/_${old_suffix}_backup/_${new_suffix}_backup/g" "$script_path"
            sed -i '' "s/_${old_suffix}\)/_${new_suffix})/g" "$script_path"
            
            # Actualizar comentarios
            sed -i '' "s/CONFIGURADO PARA: Mac[^(]*(sufijo _${old_suffix}/CONFIGURADO PARA: ${MACHINE_NAME} (sufijo _${new_suffix}/g" "$script_path"
            
            echo -e "${GREEN}  ✅ $script actualizado${NC}"
        else
            echo -e "${RED}  ❌ $script no encontrado${NC}"
        fi
    done
    
    echo
    echo -e "${GREEN}✅ Actualización completada${NC}"
    echo -e "${YELLOW}📁 Nuevas rutas configuradas:${NC}"
    echo -e "${BLUE}  • Aplicaciones: /Volumes/BLACK2T/Applications_${new_suffix}${NC}"
    echo -e "${BLUE}  • Backup: /Volumes/8TbSeries/Applications_${new_suffix}${NC}"
    echo -e "${BLUE}  • Datos usuario: /Volumes/BLACK2T/UserData_\$(whoami)_${new_suffix}${NC}"
}

# Función principal
main() {
    echo -e "${BLUE}=== ACTUALIZADOR DE CONFIGURACIÓN DE MÁQUINA ===${NC}"
    echo
    show_current_config
    echo
    
    echo "Configuraciones disponibles:"
    echo "1. Mac Mini (macmini)"
    echo "2. Mac Studio (macstudio)"
    echo "3. Mac Pro (macpro)"
    echo "4. Personalizado"
    echo "5. Cancelar"
    echo
    
    read -p "Selecciona la nueva configuración (1-5): " choice
    
    local new_suffix=""
    local new_name=""
    
    case $choice in
        1)
            new_suffix="macmini"
            new_name="Mac Mini"
            ;;
        2)
            new_suffix="macstudio"
            new_name="Mac Studio"
            ;;
        3)
            new_suffix="macpro"
            new_name="Mac Pro"
            ;;
        4)
            read -p "Ingresa el nuevo sufijo: " new_suffix
            read -p "Ingresa el nombre de la máquina: " new_name
            ;;
        5)
            echo "Operación cancelada"
            exit 0
            ;;
        *)
            echo -e "${RED}Opción inválida${NC}"
            exit 1
            ;;
    esac
    
    if [ "$new_suffix" == "$MACHINE_SUFFIX" ]; then
        echo -e "${YELLOW}Ya estás usando la configuración '$new_suffix'${NC}"
        exit 0
    fi
    
    echo
    echo -e "${YELLOW}⚠️  ADVERTENCIA:${NC}"
    echo -e "${RED}Esta operación modificará todos los scripts para usar el sufijo '$new_suffix'${NC}"
    echo -e "${RED}Se crearán backups de todos los archivos modificados${NC}"
    echo
    
    read -p "¿Continuar? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "Operación cancelada"
        exit 0
    fi
    
    # Actualizar configuración
    sed -i '' "s/MACHINE_SUFFIX=\".*\"/MACHINE_SUFFIX=\"$new_suffix\"/" "$SCRIPT_DIR/machine_config.sh"
    sed -i '' "s/MACHINE_NAME=\".*\"/MACHINE_NAME=\"$new_name\"/" "$SCRIPT_DIR/machine_config.sh"
    
    # Actualizar scripts
    update_scripts "$new_suffix" "$MACHINE_SUFFIX"
    
    echo
    echo -e "${GREEN}🎉 ¡Configuración actualizada exitosamente!${NC}"
    echo -e "${BLUE}Ahora el sistema está configurado para: $new_name${NC}"
    echo
    echo -e "${YELLOW}📝 Próximos pasos recomendados:${NC}"
    echo -e "${BLUE}1. Verificar que los discos externos estén montados${NC}"
    echo -e "${BLUE}2. Ejecutar el script maestro para verificar configuración${NC}"
    echo -e "${BLUE}3. Crear los directorios en los discos externos si es necesario${NC}"
}

# Ejecutar si se llama directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
