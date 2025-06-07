#!/bin/bash
# SOLUCIONADOR MAESTRO DE PROBLEMAS DE PERMISOS
# Integra todas las soluciones disponibles para mover datos de usuario

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAC_STUDIO_IP="192.168.100.1"
MAC_STUDIO_USER="angelsalazar"

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║           SOLUCIONADOR MAESTRO - PROBLEMAS PERMISOS          ║${NC}"
echo -e "${CYAN}║              Datos de Usuario Mac Mini → Externos           ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

# Función para verificar estado de discos
check_disk_status() {
    echo -e "${BLUE}🔍 Verificando estado actual de discos...${NC}"
    echo
    
    # Verificar BLACK2T
    if [ -d "/Volumes/BLACK2T" ]; then
        if touch "/Volumes/BLACK2T/test_write" 2>/dev/null; then
            rm -f "/Volumes/BLACK2T/test_write"
            echo -e "${GREEN}✅ BLACK2T: Montado y escribible${NC}"
            BLACK2T_STATUS="OK"
        else
            echo -e "${YELLOW}⚠️  BLACK2T: Montado pero solo lectura${NC}"
            BLACK2T_STATUS="READ_ONLY"
        fi
    else
        echo -e "${RED}❌ BLACK2T: No montado${NC}"
        BLACK2T_STATUS="NOT_MOUNTED"
    fi
    
    # Verificar 8TbSeries
    if [ -d "/Volumes/8TbSeries" ]; then
        if touch "/Volumes/8TbSeries/test_write" 2>/dev/null; then
            rm -f "/Volumes/8TbSeries/test_write"
            echo -e "${GREEN}✅ 8TbSeries: Montado y escribible${NC}"
            TBSERIES_STATUS="OK"
        else
            echo -e "${YELLOW}⚠️  8TbSeries: Montado pero solo lectura${NC}"
            TBSERIES_STATUS="READ_ONLY"
        fi
    else
        echo -e "${RED}❌ 8TbSeries: No montado${NC}"
        TBSERIES_STATUS="NOT_MOUNTED"
    fi
    
    echo
}

# Función para verificar SSH
check_ssh_status() {
    echo -e "${BLUE}🔍 Verificando SSH a Mac Studio...${NC}"
    
    if ssh -o ConnectTimeout=3 -o BatchMode=yes "${MAC_STUDIO_USER}@${MAC_STUDIO_IP}" "echo 'test'" 2>/dev/null; then
        echo -e "${GREEN}✅ SSH: Disponible y funcionando${NC}"
        SSH_STATUS="OK"
    else
        echo -e "${YELLOW}⚠️  SSH: No disponible${NC}"
        SSH_STATUS="NOT_AVAILABLE"
    fi
    echo
}

# Menú principal
show_main_menu() {
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║                    SOLUCIONES DISPONIBLES                   ║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # Opción SSH/RSYNC (Recomendada)
    if [ "$SSH_STATUS" = "OK" ]; then
        echo -e "${GREEN}1) 🚀 RSYNC/SSH (RECOMENDADO) - SSH Listo${NC}"
        echo -e "   Transferencia directa, evita problemas SMB"
    else
        echo -e "${YELLOW}1) 🔧 RSYNC/SSH (Configurar SSH primero)${NC}"
        echo -e "   Mejor opción, pero necesita habilitar SSH"
    fi
    echo
    
    # Opciones SMB según estado de discos
    if [ "$BLACK2T_STATUS" = "OK" ] && [ "$TBSERIES_STATUS" = "OK" ]; then
        echo -e "${GREEN}2) 📁 SMB - Ambos discos escribibles${NC}"
        echo -e "   Usar BLACK2T y 8TbSeries normalmente"
    elif [ "$BLACK2T_STATUS" = "OK" ] && [ "$TBSERIES_STATUS" != "OK" ]; then
        echo -e "${YELLOW}2) 📁 SMB - Solo BLACK2T escribible${NC}"
        echo -e "   Usar solo BLACK2T temporalmente"
    else
        echo -e "${RED}2) 📁 SMB - Problemas de permisos${NC}"
        echo -e "   Necesita reparar permisos de discos"
    fi
    echo
    
    # Opciones de reparación
    echo -e "${BLUE}3) 🔧 Reparar permisos 8TbSeries${NC}"
    echo -e "   Intentar reconectar 8TbSeries con permisos"
    echo
    echo -e "${BLUE}4) 👤 Configurar usuarios Mac Studio${NC}"
    echo -e "   Crear usuario espejo o ajustar compartir archivos"
    echo
    echo -e "${BLUE}5) 🔍 Diagnóstico completo${NC}"
    echo -e "   Ver estado detallado de todo el sistema"
    echo
    echo -e "${RED}0) 🚪 Salir${NC}"
    echo
}

# Ejecutar soluciones
execute_solution() {
    case $1 in
        1)
            if [ "$SSH_STATUS" = "OK" ]; then
                echo -e "${GREEN}Ejecutando solución RSYNC/SSH...${NC}"
                exec "$SCRIPT_DIR/rsync_solution.sh"
            else
                echo -e "${YELLOW}Configurando SSH primero...${NC}"
                exec "$SCRIPT_DIR/enable_ssh_macstudio.sh"
            fi
            ;;
        2)
            if [ "$BLACK2T_STATUS" = "OK" ] && [ "$TBSERIES_STATUS" = "OK" ]; then
                echo -e "${GREEN}Usando ambos discos...${NC}"
                exec "$SCRIPT_DIR/manage_user_data.sh"
            elif [ "$BLACK2T_STATUS" = "OK" ]; then
                echo -e "${YELLOW}Usando solo BLACK2T...${NC}"
                exec "$SCRIPT_DIR/manage_user_data_black2t_only.sh"
            else
                echo -e "${RED}Necesitas reparar permisos primero${NC}"
                read -p "Presiona Enter para continuar..."
                return 1
            fi
            ;;
        3)
            echo -e "${BLUE}Reparando permisos 8TbSeries...${NC}"
            exec "$SCRIPT_DIR/quick_fix_8tbseries.sh"
            ;;
        4)
            echo -e "${BLUE}Configurando usuarios...${NC}"
            exec "$SCRIPT_DIR/fix_user_permissions_macstudio.sh"
            ;;
        5)
            echo -e "${BLUE}Ejecutando diagnóstico...${NC}"
            exec "$SCRIPT_DIR/fix_8tbseries_permissions.sh"
            ;;
        0)
            echo -e "${GREEN}¡Hasta luego!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Opción no válida${NC}"
            return 1
            ;;
    esac
}

# Función principal
main() {
    # Verificar estado inicial
    check_disk_status
    check_ssh_status
    
    # Mostrar recomendación
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                     RECOMENDACIÓN                           ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    
    if [ "$SSH_STATUS" = "OK" ]; then
        echo -e "${GREEN}✅ USAR RSYNC/SSH (Opción 1)${NC}"
        echo -e "SSH está disponible - esta es la mejor solución"
    elif [ "$BLACK2T_STATUS" = "OK" ] && [ "$TBSERIES_STATUS" = "READ_ONLY" ]; then
        echo -e "${YELLOW}📝 CONFIGURAR SSH O USAR BLACK2T${NC}"
        echo -e "• Opción 1: Configurar SSH (mejor a largo plazo)"
        echo -e "• Opción 2: Usar solo BLACK2T temporalmente"
    else
        echo -e "${BLUE}🔧 REPARAR PERMISOS PRIMERO${NC}"
        echo -e "Hay problemas con los discos que deben resolverse"
    fi
    echo
    
    # Bucle principal
    while true; do
        show_main_menu
        echo -e "${CYAN}Selecciona una opción (0-5): ${NC}"
        read -r choice
        echo
        
        if execute_solution "$choice"; then
            break
        fi
        echo
    done
}

# Ejecutar
main
