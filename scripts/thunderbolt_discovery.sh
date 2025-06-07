#!/bin/bash
# Script para descubrir y diagnosticar discos compartidos en red Thunderbolt
# CONFIGURADO PARA: MacMini (descubrimiento de recursos en Mac Studio)
# Autor: Script de descubrimiento de recursos de red
# Fecha: $(date)

# Configuración
MAC_STUDIO_IP="192.168.100.1"
LOG_FILE="$HOME/Documents/scripts/thunderbolt_discovery_macmini.log"

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

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║            DESCUBRIMIENTO DE RECURSOS THUNDERBOLT            ║${NC}"
echo -e "${CYAN}║                     Mac Studio Discovery                     ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

log_message "${BLUE}🔍 Iniciando descubrimiento de recursos...${NC}"

# 1. Verificar conectividad básica
log_message "${BLUE}📡 1. Verificando conectividad básica...${NC}"
if ping -c 3 "$MAC_STUDIO_IP" >/dev/null 2>&1; then
    log_message "${GREEN}✅ Mac Studio responde en $MAC_STUDIO_IP${NC}"
else
    log_message "${RED}❌ Mac Studio no responde${NC}"
    exit 1
fi

# 2. Escanear puertos comunes
log_message "${BLUE}🔌 2. Escaneando puertos de servicios de archivos...${NC}"
ports=(22 139 445 548 2049)  # SSH, NetBIOS, SMB, AFP, NFS
for port in "${ports[@]}"; do
    if nc -z -w 2 "$MAC_STUDIO_IP" "$port" 2>/dev/null; then
        case $port in
            22) log_message "${GREEN}✅ SSH disponible (puerto 22)${NC}" ;;
            139) log_message "${GREEN}✅ NetBIOS disponible (puerto 139)${NC}" ;;
            445) log_message "${GREEN}✅ SMB disponible (puerto 445)${NC}" ;;
            548) log_message "${GREEN}✅ AFP disponible (puerto 548)${NC}" ;;
            2049) log_message "${GREEN}✅ NFS disponible (puerto 2049)${NC}" ;;
        esac
    else
        case $port in
            22) log_message "${RED}❌ SSH no disponible${NC}" ;;
            139) log_message "${RED}❌ NetBIOS no disponible${NC}" ;;
            445) log_message "${RED}❌ SMB no disponible${NC}" ;;
            548) log_message "${RED}❌ AFP no disponible${NC}" ;;
            2049) log_message "${RED}❌ NFS no disponible${NC}" ;;
        esac
    fi
done

echo

# 3. Descubrimiento Bonjour/mDNS
log_message "${BLUE}📺 3. Descubriendo servicios Bonjour...${NC}"
if command -v dns-sd >/dev/null 2>&1; then
    log_message "${YELLOW}Buscando servicios AFP...${NC}"
    timeout 5 dns-sd -B _afpovertcp._tcp local. 2>/dev/null | head -5 || log_message "${RED}❌ No se encontraron servicios AFP${NC}"
    
    log_message "${YELLOW}Buscando servicios SMB...${NC}"
    timeout 5 dns-sd -B _smb._tcp local. 2>/dev/null | head -5 || log_message "${RED}❌ No se encontraron servicios SMB${NC}"
else
    log_message "${YELLOW}⚠️  dns-sd no disponible${NC}"
fi

echo

# 4. Intentar métodos alternativos de descubrimiento
log_message "${BLUE}🕵️  4. Métodos alternativos de descubrimiento...${NC}"

# Método A: Usar Finder para descubrir
log_message "${YELLOW}Método A: Verificando servicios en red local...${NC}"
if command -v dscacheutil >/dev/null 2>&1; then
    dscacheutil -q host -a name "Mac-Studio.local" 2>/dev/null && log_message "${GREEN}✅ Mac Studio encontrada via Bonjour${NC}"
fi

# Método B: ARP scan de la red
log_message "${YELLOW}Método B: Información ARP...${NC}"
arp -a | grep "192.168.100" && log_message "${GREEN}✅ Dispositivos en red Thunderbolt encontrados${NC}" || log_message "${RED}❌ No hay información ARP${NC}"

echo

# 5. Sugerencias basadas en hallazgos
log_message "${CYAN}💡 5. SUGERENCIAS PARA CONFIGURACIÓN:${NC}"

if nc -z -w 2 "$MAC_STUDIO_IP" 22 2>/dev/null; then
    log_message "${GREEN}✅ SSH disponible - Puedes ejecutar comandos remotos${NC}"
    echo
    log_message "${BLUE}📋 Comandos sugeridos para ejecutar en Mac Studio via SSH:${NC}"
    echo "   ssh usuario@$MAC_STUDIO_IP 'diskutil list'"
    echo "   ssh usuario@$MAC_STUDIO_IP 'sharing -l'"
    echo "   ssh usuario@$MAC_STUDIO_IP 'ls -la /Volumes/'"
fi

if nc -z -w 2 "$MAC_STUDIO_IP" 445 2>/dev/null; then
    log_message "${GREEN}✅ SMB disponible${NC}"
    echo
    log_message "${BLUE}📋 Comandos para probar SMB:${NC}"
    echo "   smbutil view //$MAC_STUDIO_IP"
    echo "   smbutil view //usuario@$MAC_STUDIO_IP"
fi

if nc -z -w 2 "$MAC_STUDIO_IP" 548 2>/dev/null; then
    log_message "${GREEN}✅ AFP disponible${NC}"
    echo
    log_message "${BLUE}📋 Comandos para probar AFP:${NC}"
    echo "   mount_afp afp://$MAC_STUDIO_IP/VolumeName /Volumes/MountPoint"
fi

echo
log_message "${YELLOW}🔧 MÉTODOS ALTERNATIVOS:${NC}"
echo "1. ${BLUE}Compartir vía 'Compartir Archivos' en Mac Studio${NC}"
echo "2. ${BLUE}Habilitar 'Acceso remoto' (SSH) en Mac Studio${NC}"
echo "3. ${BLUE}Configurar NFS exports en Mac Studio${NC}"
echo "4. ${BLUE}Usar enlaces simbólicos en red compartida${NC}"

echo
log_message "${CYAN}📝 PRÓXIMOS PASOS RECOMENDADOS:${NC}"
echo "1. ${YELLOW}Verifica la configuración de 'Compartir' en Mac Studio${NC}"
echo "2. ${YELLOW}Habilita 'Compartir Archivos' para los volúmenes BLACK2T y 8TbSeries${NC}"
echo "3. ${YELLOW}Anota los nombres exactos de los recursos compartidos${NC}"
echo "4. ${YELLOW}Ejecuta este script nuevamente para verificar${NC}"

echo
log_message "${GREEN}✅ Descubrimiento completado. Logs guardados en: $LOG_FILE${NC}"
