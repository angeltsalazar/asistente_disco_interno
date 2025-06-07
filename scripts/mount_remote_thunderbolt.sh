#!/bin/bash
# Script para montar discos externos compartidos via red Thunderbolt desde Mac Studio
# CONFIGURADO PARA: MacMini (acceso remoto a discos en Mac Studio)
# Autor: Script para gestión de discos remotos
# Fecha: $(date)

# Configuración de red Thunderbolt
THUNDERBOLT_BRIDGE_IP="192.168.100.1"  # IP de la Mac Studio
MAC_STUDIO_NAME="Mac-Studio"
THUNDERBOLT_NETWORK="192.168.100.0/24"

# Configuración de discos remotos
REMOTE_BLACK2T_SHARE="BLACK2T"
REMOTE_8TB_SHARE="8TbSeries"

# Puntos de montaje locales
LOCAL_MOUNT_BASE="/Volumes"
BLACK2T_MOUNT="$LOCAL_MOUNT_BASE/BLACK2T"
SERIES8TB_MOUNT="$LOCAL_MOUNT_BASE/8TbSeries"

# Logs
LOG_FILE="$HOME/Documents/scripts/remote_disk_mount_macmini.log"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

# Función para detectar IP de Mac Studio
detect_mac_studio_ip() {
    log_message "${BLUE}🔍 Detectando Mac Studio en red Thunderbolt...${NC}"
    
    # Probar IPs comunes en la red Thunderbolt
    local test_ips=("192.168.100.1" "192.168.100.3" "192.168.100.4")
    
    for ip in "${test_ips[@]}"; do
        if ping -c 1 -W 1000 "$ip" >/dev/null 2>&1; then
            log_message "${GREEN}✅ Mac Studio encontrada en: $ip${NC}"
            THUNDERBOLT_BRIDGE_IP="$ip"
            return 0
        fi
    done
    
    # Escanear toda la red si no se encuentra
    log_message "${YELLOW}⚠️  Escaneando red Thunderbolt completa...${NC}"
    for i in {1..10}; do
        local ip="192.168.100.$i"
        if ping -c 1 -W 500 "$ip" >/dev/null 2>&1; then
            log_message "${GREEN}✅ Dispositivo encontrado en: $ip${NC}"
            # Intentar verificar si es Mac Studio
            local hostname=$(dig +short -x "$ip" 2>/dev/null || echo "unknown")
            if [[ "$hostname" == *"studio"* ]] || [[ "$hostname" == *"Studio"* ]]; then
                THUNDERBOLT_BRIDGE_IP="$ip"
                return 0
            fi
        fi
    done
    
    log_message "${RED}❌ No se pudo detectar la Mac Studio automáticamente${NC}"
    return 1
}

# Función para verificar conectividad Thunderbolt
check_thunderbolt_connection() {
    log_message "${BLUE}🔌 Verificando conexión Thunderbolt...${NC}"
    
    # Verificar interfaz bridge
    if ! ifconfig bridge0 >/dev/null 2>&1; then
        log_message "${RED}❌ Interfaz Thunderbolt no encontrada${NC}"
        return 1
    fi
    
    local bridge_ip=$(ifconfig bridge0 | grep 'inet ' | awk '{print $2}')
    log_message "${GREEN}✅ Interfaz Thunderbolt activa: $bridge_ip${NC}"
    
    # Detectar Mac Studio
    if ! detect_mac_studio_ip; then
        return 1
    fi
    
    return 0
}

# Función para montar disco remoto via SMB/AFP
mount_remote_disk() {
    local share_name="$1"
    local mount_point="$2"
    local protocol="${3:-smb}"  # smb por defecto, afp como alternativa
    
    log_message "${BLUE}📁 Montando $share_name en $mount_point...${NC}"
    
    # Crear punto de montaje si no existe
    if [ ! -d "$mount_point" ]; then
        sudo mkdir -p "$mount_point"
    fi
    
    # Verificar si ya está montado
    if mount | grep -q "$mount_point"; then
        log_message "${YELLOW}⚠️  $share_name ya está montado${NC}"
        return 0
    fi
    
    # Intentar montaje
    local mount_url="${protocol}://${THUNDERBOLT_BRIDGE_IP}/${share_name}"
    
    log_message "${BLUE}Conectando a: $mount_url${NC}"
    
    # Montar sin credenciales (guest/público) primero
    if mount_smbfs -o nobrowse,guest "$mount_url" "$mount_point" 2>/dev/null; then
        log_message "${GREEN}✅ $share_name montado exitosamente (guest)${NC}"
        return 0
    fi
    
    # Intentar con usuario actual si guest falla
    if mount_smbfs -o nobrowse "$mount_url" "$mount_point" 2>/dev/null; then
        log_message "${GREEN}✅ $share_name montado exitosamente (usuario)${NC}"
        return 0
    fi
    
    # Si SMB falla, intentar AFP
    if [ "$protocol" = "smb" ]; then
        log_message "${YELLOW}🔄 SMB falló, intentando AFP...${NC}"
        mount_remote_disk "$share_name" "$mount_point" "afp"
        return $?
    fi
    
    log_message "${RED}❌ No se pudo montar $share_name${NC}"
    return 1
}

# Función para desmontar disco remoto
unmount_remote_disk() {
    local mount_point="$1"
    
    if mount | grep -q "$mount_point"; then
        log_message "${BLUE}📤 Desmontando $mount_point...${NC}"
        if umount "$mount_point" 2>/dev/null; then
            log_message "${GREEN}✅ Desmontado exitosamente${NC}"
        else
            sudo umount -f "$mount_point" 2>/dev/null
            log_message "${YELLOW}⚠️  Desmontaje forzado realizado${NC}"
        fi
    else
        log_message "${YELLOW}⚠️  $mount_point no está montado${NC}"
    fi
}

# Función para verificar estado de discos remotos
check_remote_disks_status() {
    log_message "${CYAN}=== ESTADO DE DISCOS REMOTOS ===${NC}"
    
    # Verificar BLACK2T
    if [ -d "$BLACK2T_MOUNT" ] && mount | grep -q "$BLACK2T_MOUNT"; then
        local usage=$(df -h "$BLACK2T_MOUNT" | tail -1 | awk '{print $3 "/" $2 " (" $5 " usado)"}')
        log_message "${GREEN}✅ BLACK2T: Montado - $usage${NC}"
    else
        log_message "${RED}❌ BLACK2T: No montado${NC}"
    fi
    
    # Verificar 8TbSeries
    if [ -d "$SERIES8TB_MOUNT" ] && mount | grep -q "$SERIES8TB_MOUNT"; then
        local usage=$(df -h "$SERIES8TB_MOUNT" | tail -1 | awk '{print $3 "/" $2 " (" $5 " usado)"}')
        log_message "${GREEN}✅ 8TbSeries: Montado - $usage${NC}"
    else
        log_message "${RED}❌ 8TbSeries: No montado${NC}"
    fi
    
    echo
    log_message "${BLUE}📊 Todos los volúmenes montados:${NC}"
    df -h | grep "/Volumes"
}

# Función para montar todos los discos remotos
mount_all_remote_disks() {
    log_message "${CYAN}=== MONTANDO TODOS LOS DISCOS REMOTOS ===${NC}"
    
    # Verificar conexión Thunderbolt
    if ! check_thunderbolt_connection; then
        log_message "${RED}❌ No se puede continuar sin conexión Thunderbolt${NC}"
        return 1
    fi
    
    # Montar BLACK2T
    mount_remote_disk "$REMOTE_BLACK2T_SHARE" "$BLACK2T_MOUNT"
    
    # Montar 8TbSeries
    mount_remote_disk "$REMOTE_8TB_SHARE" "$SERIES8TB_MOUNT"
    
    echo
    check_remote_disks_status
}

# Función para desmontar todos los discos remotos
unmount_all_remote_disks() {
    log_message "${CYAN}=== DESMONTANDO TODOS LOS DISCOS REMOTOS ===${NC}"
    
    unmount_remote_disk "$BLACK2T_MOUNT"
    unmount_remote_disk "$SERIES8TB_MOUNT"
    
    echo
    check_remote_disks_status
}

# Función principal del menú
main() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              GESTOR DE DISCOS REMOTOS THUNDERBOLT            ║${NC}"
    echo -e "${CYAN}║                    Mac Studio → Mac Mini                     ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${YELLOW}🛠️  OPCIONES DISPONIBLES:${NC}"
    echo "1. 📊 Verificar estado de discos remotos"
    echo "2. 🔌 Montar todos los discos remotos"
    echo "3. 📁 Montar solo BLACK2T"
    echo "4. 💾 Montar solo 8TbSeries"
    echo "5. 📤 Desmontar todos los discos"
    echo "6. 🔍 Diagnóstico de red Thunderbolt"
    echo "7. ⚙️  Configurar montaje automático"
    echo "8. 📋 Ver logs de montaje"
    echo "9. 🚪 Salir"
    echo
    
    read -p "Selecciona una opción (1-9): " choice
    
    case $choice in
        1) check_remote_disks_status ;;
        2) mount_all_remote_disks ;;
        3) 
            check_thunderbolt_connection && mount_remote_disk "$REMOTE_BLACK2T_SHARE" "$BLACK2T_MOUNT"
            ;;
        4) 
            check_thunderbolt_connection && mount_remote_disk "$REMOTE_8TB_SHARE" "$SERIES8TB_MOUNT"
            ;;
        5) unmount_all_remote_disks ;;
        6) 
            check_thunderbolt_connection
            log_message "${BLUE}📋 Información de red Thunderbolt:${NC}"
            ifconfig bridge0
            arp -a | grep "192.168.100"
            ;;
        7)
            echo -e "${YELLOW}⚠️  Función de montaje automático en desarrollo${NC}"
            echo "Por ahora, ejecuta este script manualmente al inicio"
            ;;
        8)
            if [ -f "$LOG_FILE" ]; then
                tail -20 "$LOG_FILE"
            else
                echo "No hay logs disponibles"
            fi
            ;;
        9)
            log_message "${BLUE}Saliendo del gestor de discos remotos...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Opción inválida${NC}"
            exit 1
            ;;
    esac
    
    echo
    read -p "Presiona Enter para continuar..." -r
    main
}

# Ejecutar si se llama directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
