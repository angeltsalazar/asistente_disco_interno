#!/bin/bash
# Script maestro para gestión de aplicaciones en discos externos
# CONFIGURADO PARA: MacMini (sufijo _macmini en todos los directorios)
# Para usar en Mac Studio o Mac Pro, cambiar sufijo en scripts individuales
# Autor: Script generado para gestión completa del sistema
# Fecha: $(date)

# Configuración de colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Rutas de scripts
SCRIPT_DIR="$HOME/Documents/scripts"
SAFE_MOVE_SCRIPT="$SCRIPT_DIR/safe_move_apps.sh"
RESTORE_SCRIPT="$SCRIPT_DIR/restore_apps_from_external.sh"
MONITOR_SCRIPT="$SCRIPT_DIR/monitor_external_apps.sh"
DISK_MANAGER_SCRIPT="$SCRIPT_DIR/disk_manager.sh"
CLEANUP_SCRIPT="$SCRIPT_DIR/clean_system_caches.sh"
USER_DATA_SCRIPT="$SCRIPT_DIR/manage_user_data.sh"
# Script legacy (menos seguro)
MOVE_SCRIPT="$SCRIPT_DIR/move_apps_to_external.sh"

# Función para mostrar banner
show_banner() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                              ║${NC}"
    echo -e "${CYAN}║         ${YELLOW}GESTOR DE APLICACIONES EN DISCOS EXTERNOS${CYAN}         ║${NC}"
    echo -e "${CYAN}║                                                              ║${NC}"
    echo -e "${CYAN}║  ${BLUE}Optimiza el espacio de tu disco interno moviendo apps${CYAN}      ║${NC}"
    echo -e "${CYAN}║  ${BLUE}grandes a discos externos con enlaces simbólicos${CYAN}          ║${NC}"
    echo -e "${CYAN}║                                                              ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${BLUE}Fecha: $(date)${NC}"
    echo -e "${BLUE}Usuario: $(whoami)${NC}"
    echo
}

# Función para verificar scripts
check_scripts() {
    local missing_scripts=()
    
    if [ ! -f "$SAFE_MOVE_SCRIPT" ]; then
        missing_scripts+=("safe_move_apps.sh")
    fi
    
    if [ ! -f "$RESTORE_SCRIPT" ]; then
        missing_scripts+=("restore_apps_from_external.sh")
    fi
    
    if [ ! -f "$MONITOR_SCRIPT" ]; then
        missing_scripts+=("monitor_external_apps.sh")
    fi
    
    if [ ! -f "$DISK_MANAGER_SCRIPT" ]; then
        missing_scripts+=("disk_manager.sh")
    fi
    
    if [ ! -f "$CLEANUP_SCRIPT" ]; then
        missing_scripts+=("clean_system_caches.sh")
    fi
    
    if [ ! -f "$USER_DATA_SCRIPT" ]; then
        missing_scripts+=("manage_user_data.sh")
    fi
    
    if [ ${#missing_scripts[@]} -gt 0 ]; then
        echo -e "${RED}❌ Scripts faltantes:${NC}"
        for script in "${missing_scripts[@]}"; do
            echo -e "${RED}   - $script${NC}"
        done
        echo
        echo -e "${YELLOW}Por favor, asegúrate de tener todos los scripts en $SCRIPT_DIR${NC}"
        exit 1
    fi
    
    # Hacer ejecutables todos los scripts
    chmod +x "$SAFE_MOVE_SCRIPT" "$RESTORE_SCRIPT" "$MONITOR_SCRIPT" "$DISK_MANAGER_SCRIPT" "$CLEANUP_SCRIPT" "$USER_DATA_SCRIPT"
    [ -f "$MOVE_SCRIPT" ] && chmod +x "$MOVE_SCRIPT"
}

# Función para mostrar estado rápido
show_quick_status() {
    echo -e "${CYAN}=== ESTADO RÁPIDO ===${NC}"
    
    # Verificar discos
    if [ -d "/Volumes/BLACK2T" ]; then
        echo -e "${GREEN}✅ BLACK2T: Montado${NC}"
    else
        echo -e "${RED}❌ BLACK2T: No montado${NC}"
    fi
    
    if [ -d "/Volumes/8TbSeries" ]; then
        echo -e "${GREEN}✅ 8TbSeries: Montado${NC}"
    else
        echo -e "${RED}❌ 8TbSeries: No montado${NC}"
    fi
    
    # Contar enlaces simbólicos
    local symlinks=$(find "/Applications" -maxdepth 1 -name "*.app" -type l 2>/dev/null | wc -l)
    echo -e "${BLUE}🔗 Enlaces simbólicos: $symlinks${NC}"
    
    # Mostrar espacio en disco interno
    local disk_usage=$(df -h / | tail -1 | awk '{print $5}')
    echo -e "${BLUE}💾 Disco interno usado: $disk_usage${NC}"
    
    echo
}

# Función para mostrar ayuda
show_help() {
    echo -e "${CYAN}=== AYUDA Y MEJORES PRÁCTICAS ===${NC}"
    echo
    echo -e "${YELLOW}🛡️  MÉTODOS SEGUROS RECOMENDADOS (en orden de prioridad):${NC}"
    echo
    echo -e "${GREEN}1. LIMPIEZA DE SISTEMA (SIN RIESGO):${NC}"
    echo -e "${BLUE}   • Limpiar caches de aplicaciones${NC}"
    echo -e "${BLUE}   • Eliminar logs antiguos${NC}"
    echo -e "${BLUE}   • Limpiar archivos temporales${NC}"
    echo -e "${BLUE}   • Vaciar papelera${NC}"
    echo -e "${BLUE}   💡 Puede liberar 5-20GB sin ningún riesgo${NC}"
    echo
    echo -e "${GREEN}2. GESTIÓN DE DATOS DE USUARIO:${NC}"
    echo -e "${BLUE}   • Mover Downloads a disco externo${NC}"
    echo -e "${BLUE}   • Mover bibliotecas de medios (Fotos, Música, Videos)${NC}"
    echo -e "${BLUE}   • Mover proyectos grandes (Unity, Xcode, Adobe)${NC}"
    echo -e "${BLUE}   💡 Puede liberar 20-100GB+ de manera segura${NC}"
    echo
    echo -e "${GREEN}3. APLICACIONES DE TERCEROS (SOLO SEGURAS):${NC}"
    echo -e "${BLUE}   • Solo aplicaciones NO críticas del sistema${NC}"
    echo -e "${BLUE}   • Análisis automático de seguridad${NC}"
    echo -e "${BLUE}   • Backup automático antes de mover${NC}"
    echo -e "${BLUE}   • Verificación de funcionalidad${NC}"
    echo
    echo -e "${RED}⚠️  APLICACIONES QUE NUNCA DEBES MOVER:${NC}"
    echo -e "${RED}   🚫 Safari, Mail, Calendar, Messages${NC}"
    echo -e "${RED}   🚫 System Preferences, App Store${NC}"
    echo -e "${RED}   🚫 Disk Utility, Activity Monitor${NC}"
    echo -e "${RED}   🚫 Terminal, Console, Keychain Access${NC}"
    echo -e "${RED}   🚫 Cualquier aplicación firmada por Apple${NC}"
    echo
    echo -e "${YELLOW}✅ APLICACIONES SEGURAS PARA MOVER:${NC}"
    echo -e "${GREEN}   ✓ Adobe Creative Cloud y apps${NC}"
    echo -e "${GREEN}   ✓ Microsoft Office${NC}"
    echo -e "${GREEN}   ✓ Xcode (si no la usas frecuentemente)${NC}"
    echo -e "${GREEN}   ✓ Steam, Discord, Slack${NC}"
    echo -e "${GREEN}   ✓ VirtualBox, VMware, Parallels${NC}"
    echo -e "${GREEN}   ✓ Unity, Blender, DaVinci Resolve${NC}"
    echo
    echo -e "${YELLOW}🔧 CONFIGURACIÓN ACTUAL (MacMini):${NC}"
    echo -e "${BLUE}• Disco principal: BLACK2T (/Volumes/BLACK2T/*_macmini)${NC}"
    echo -e "${BLUE}• Disco backup: 8TbSeries (/Volumes/8TbSeries/*_macmini)${NC}"
    echo -e "${BLUE}• Aplicaciones: /Applications (enlaces simbólicos)${NC}"
    echo -e "${BLUE}• Datos usuario: En subdirectorios organizados por máquina${NC}"
    echo
    echo -e "${YELLOW}📋 FLUJO RECOMENDADO:${NC}"
    echo -e "${BLUE}1. Limpieza de sistema (opción 1) - SIN RIESGO${NC}"
    echo -e "${BLUE}2. Gestión de datos de usuario (opción 2)${NC}"
    echo -e "${BLUE}3. Solo entonces considerar mover aplicaciones${NC}"
    echo -e "${BLUE}4. Siempre verificar funcionamiento después${NC}"
    echo -e "${BLUE}5. Monitorear regularmente el sistema${NC}"
    echo
    echo -e "${CYAN}💡 BENEFICIOS DE ESTE ENFOQUE:${NC}"
    echo -e "${GREEN}   ✅ Máxima seguridad del sistema${NC}"
    echo -e "${GREEN}   ✅ Libera espacio significativo${NC}"
    echo -e "${GREEN}   ✅ Mantiene funcionalidad completa${NC}"
    echo -e "${GREEN}   ✅ Backup automático de todo${NC}"
    echo -e "${GREEN}   ✅ Fácil reversión si es necesario${NC}"
    echo
}

# Función para crear backup completo
create_full_backup() {
    echo -e "${YELLOW}=== CREANDO BACKUP COMPLETO ===${NC}"
    echo -e "${RED}⚠️  ADVERTENCIA: Esto puede tomar mucho tiempo${NC}"
    echo
    
    read -p "¿Continuar con el backup completo? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        return
    fi
    
    if [ ! -d "/Volumes/8TbSeries" ]; then
        echo -e "${RED}❌ Disco de backup no disponible${NC}"
        return
    fi
    
    echo -e "${BLUE}Iniciando backup completo para MacMini...${NC}"
    sudo rsync -av --progress /Applications/ /Volumes/8TbSeries/Applications_macmini_full_backup_$(date +%Y%m%d)/
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Backup completo creado exitosamente${NC}"
    else
        echo -e "${RED}❌ Error en el backup${NC}"
    fi
}

# Función principal del menú
main_menu() {
    while true; do
        clear
        show_banner
        show_quick_status
        
        echo -e "${YELLOW}=== MENÚ PRINCIPAL ===${NC}"
        echo
        echo -e "${GREEN}�️  MÉTODOS SEGUROS (RECOMENDADO):${NC}"
        echo "  1. 🧹 Limpiar caches y archivos temporales (SIN RIESGO)"
        echo "  2. 📁 Migración integral de contenido de usuario"
        echo "  3. � Gestionar datos de usuario (Downloads, Documents, Media)"
        echo "  4. �🚀 Mover aplicaciones de terceros (SOLO SEGURAS)"
        echo
        echo -e "${GREEN}📱 GESTIÓN DE APLICACIONES:${NC}"
        echo "  5. 🔄 Restaurar aplicaciones al disco interno"
        echo "  6. 📊 Monitor de aplicaciones y estado del sistema"
        echo
        echo -e "${GREEN}💾 GESTIÓN DE DISCOS:${NC}"
        echo "  7. 🔌 Gestor de discos externos"
        echo "  8. 🔍 Verificar estado de discos"
        echo
        echo -e "${GREEN}🛠️  UTILIDADES:${NC}"
        echo "  9. � Ver estado detallado de migración"
        echo " 10. �💾 Crear backup completo de /Applications"
        echo " 11. 📋 Ver logs del sistema"
        echo " 12. ❓ Ayuda y mejores prácticas"
        echo
        echo -e "${GREEN}⚙️  CONFIGURACIÓN:${NC}"
        echo " 13. 🔧 Verificar y reparar scripts"
        echo " 14. ⚠️  Movimiento legacy (MENOS SEGURO)"
        echo " 15. 🚪 Salir"
        echo
        
        read -p "Selecciona una opción (1-15): " choice
        
        case $choice in
            1)
                clear
                echo -e "${BLUE}Ejecutando limpieza segura del sistema...${NC}"
                if [ -f "$CLEANUP_SCRIPT" ]; then
                    bash "$CLEANUP_SCRIPT"
                else
                    echo -e "${RED}❌ Script de limpieza no encontrado${NC}"
                fi
                ;;
            2)
                clear
                echo -e "${BLUE}Ejecutando migración integral de contenido de usuario...${NC}"
                if [ -f "$SCRIPT_DIR/move_user_content.sh" ]; then
                    bash "$SCRIPT_DIR/move_user_content.sh"
                else
                    echo -e "${RED}❌ Script de migración de contenido no encontrado${NC}"
                fi
                echo
                read -p "Presiona Enter para continuar..."
                ;;
            3)
                clear
                echo -e "${BLUE}Ejecutando gestor de datos de usuario...${NC}"
                if [ -f "$USER_DATA_SCRIPT" ]; then
                    bash "$USER_DATA_SCRIPT"
                else
                    echo -e "${RED}❌ Script de gestión de datos no encontrado${NC}"
                fi
                echo
                read -p "Presiona Enter para continuar..."
                ;;
            4)
                clear
                echo -e "${BLUE}Ejecutando movimiento seguro de aplicaciones...${NC}"
                if [ -f "$SAFE_MOVE_SCRIPT" ]; then
                    bash "$SAFE_MOVE_SCRIPT"
                else
                    echo -e "${RED}❌ Script seguro no encontrado${NC}"
                fi
                echo
                read -p "Presiona Enter para continuar..."
                ;;
            5)
                clear
                echo -e "${BLUE}Ejecutando script de restauración...${NC}"
                if [ -f "$RESTORE_SCRIPT" ]; then
                    bash "$RESTORE_SCRIPT"
                else
                    echo -e "${RED}❌ Script no encontrado${NC}"
                fi
                ;;
            6)
                clear
                echo -e "${BLUE}Ejecutando gestor de discos...${NC}"
                if [ -f "$DISK_MANAGER_SCRIPT" ]; then
                    bash "$DISK_MANAGER_SCRIPT"
                else
                    echo -e "${RED}❌ Script no encontrado${NC}"
                fi
                ;;
            7)
                clear
                echo -e "${BLUE}Ejecutando gestor de discos externos...${NC}"
                if [ -f "$SCRIPT_DIR/disk_manager.sh" ]; then
                    bash "$SCRIPT_DIR/disk_manager.sh"
                else
                    echo -e "${RED}❌ Script de gestor de discos no encontrado${NC}"
                fi
                ;;
            8)
                clear
                echo -e "${BLUE}Verificando estado de discos...${NC}"
                df -h | grep -E "(Filesystem|BLACK2T|8TbSeries|/$)"
                echo
                diskutil list | grep -E "(BLACK2T|8TbSeries)"
                ;;
            9)
                clear
                echo -e "${BLUE}Mostrando estado detallado de migración...${NC}"
                if [ -f "$SCRIPT_DIR/migration_state.sh" ]; then
                    source "$SCRIPT_DIR/migration_state.sh"
                    show_migration_status
                    echo
                    read -p "Presiona Enter para continuar..." 
                else
                    echo -e "${RED}❌ Sistema de estado no encontrado${NC}"
                    read -p "Presiona Enter para continuar..."
                fi
                ;;
            10)
                clear
                create_full_backup
                ;;
            11)
                clear
                echo -e "${BLUE}Logs disponibles:${NC}"
                ls -la "$HOME/Documents/scripts"/*.log 2>/dev/null || echo "No hay logs disponibles"
                echo
                read -p "¿Ver algún log específico? (safe_move_apps.log/system_cleanup.log/user_data_move.log): " log_choice
                if [ -f "$HOME/Documents/scripts/$log_choice" ]; then
                    tail -20 "$HOME/Documents/scripts/$log_choice"
                fi
                ;;
            12)
                clear
                show_help
                ;;
            13)
                clear
                echo -e "${BLUE}Verificando scripts...${NC}"
                check_scripts
                echo -e "${GREEN}✅ Todos los scripts están correctos${NC}"
                ;;
            14)
                clear
                echo -e "${YELLOW}⚠️  ADVERTENCIA: El movimiento legacy es menos seguro${NC}"
                echo -e "${RED}Puede mover aplicaciones críticas del sistema${NC}"
                read -p "¿Estás seguro de que quieres continuar? (y/N): " confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    if [ -f "$MOVE_SCRIPT" ]; then
                        bash "$MOVE_SCRIPT"
                    else
                        echo -e "${RED}❌ Script legacy no encontrado${NC}"
                    fi
                fi
                ;;
            15)
                clear
                echo -e "${GREEN}¡Gracias por usar el Gestor de Aplicaciones!${NC}"
                echo -e "${BLUE}Recuerda seguir las mejores prácticas de seguridad${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Opción inválida${NC}"
                sleep 1
                ;;
        esac
        
        echo
        read -p "Presiona Enter para continuar..." -r
    done
}

# Verificar scripts al inicio
check_scripts

# Ejecutar menú principal
main_menu
