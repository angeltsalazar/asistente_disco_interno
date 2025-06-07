#!/bin/bash
# Script para verificar si Screen Sharing está usando Thunderbolt Bridge
# Autor: Sistema de verificación de conexiones
# Fecha: $(date)

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                              ║${NC}"
echo -e "${CYAN}║         VERIFICADOR DE CONEXIÓN THUNDERBOLT BRIDGE          ║${NC}"
echo -e "${CYAN}║                                                              ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

# Función para verificar interfaces de red
check_network_interfaces() {
    echo -e "${BLUE}🔍 Verificando interfaces de red activas...${NC}"
    echo
    
    # Mostrar todas las interfaces activas
    echo -e "${YELLOW}Interfaces de red activas:${NC}"
    ifconfig | grep -E "^[a-z]|inet " | grep -v "127.0.0.1" | grep -v "::1"
    echo
    
    # Verificar específicamente Thunderbolt Bridge
    echo -e "${BLUE}🔗 Verificando Thunderbolt Bridge...${NC}"
    
    # Buscar interfaces bridge
    bridge_interfaces=$(ifconfig | grep -E "^bridge[0-9]")
    if [ -n "$bridge_interfaces" ]; then
        echo -e "${GREEN}✅ Thunderbolt Bridge detectado:${NC}"
        echo "$bridge_interfaces"
        
        # Mostrar detalles del bridge
        for bridge in $(echo "$bridge_interfaces" | cut -d: -f1); do
            echo -e "${CYAN}Detalles de $bridge:${NC}"
            ifconfig "$bridge" | grep -E "inet|status"
        done
    else
        echo -e "${YELLOW}⚠️  No se detectó Thunderbolt Bridge activo${NC}"
    fi
    echo
}

# Función para verificar conexiones de Screen Sharing
check_screen_sharing_connections() {
    echo -e "${BLUE}📺 Verificando conexiones de Screen Sharing...${NC}"
    echo
    
    # Verificar procesos de Screen Sharing
    echo -e "${YELLOW}Procesos de Screen Sharing activos:${NC}"
    ps aux | grep -i "screen.*shar\|vnc\|remote" | grep -v grep
    echo
    
    # Verificar conexiones de red activas
    echo -e "${YELLOW}Conexiones de red activas (puertos VNC/Screen Sharing):${NC}"
    netstat -an | grep -E ":5900|:5901|:5902|:3283"
    echo
    
    # Verificar servicios de compartición
    echo -e "${YELLOW}Estado de servicios de compartición:${NC}"
    launchctl list | grep -E "com.apple.*remote|com.apple.*sharing|com.apple.*vnc"
    echo
}

# Función para verificar dispositivos Thunderbolt
check_thunderbolt_devices() {
    echo -e "${BLUE}⚡ Verificando dispositivos Thunderbolt...${NC}"
    echo
    
    # Usar system_profiler para obtener info de Thunderbolt
    echo -e "${YELLOW}Dispositivos Thunderbolt conectados:${NC}"
    system_profiler SPThunderboltDataType 2>/dev/null | grep -E "Device Name|Status|Speed"
    echo
    
    # Verificar en IORegistry
    echo -e "${YELLOW}Verificación en IORegistry:${NC}"
    ioreg -l | grep -i thunderbolt | head -5
    echo
}

# Función para verificar la ruta de conexión específica
check_connection_route() {
    echo -e "${BLUE}🛣️  Verificando ruta de conexión...${NC}"
    echo
    
    # Mostrar tabla de rutas
    echo -e "${YELLOW}Tabla de rutas de red:${NC}"
    netstat -rn | grep -E "default|bridge|169.254"
    echo
    
    # Verificar direcciones IP de bridge
    echo -e "${YELLOW}Direcciones IP de interfaces bridge:${NC}"
    ifconfig | grep -A 3 "^bridge" | grep inet
    echo
    
    # Verificar ARP para dispositivos en el bridge
    echo -e "${YELLOW}Dispositivos en red local (ARP):${NC}"
    arp -a | grep -E "169.254|bridge"
    echo
}

# Función para mostrar recomendaciones
show_recommendations() {
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}INTERPRETACIÓN DE RESULTADOS:${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${GREEN}✅ USANDO THUNDERBOLT BRIDGE si ves:${NC}"
    echo "   • Interfaces bridge0, bridge1, etc. activas"
    echo "   • Direcciones IP en rango 169.254.x.x"
    echo "   • Dispositivos Thunderbolt en system_profiler"
    echo "   • Conexiones directas sin pasar por router WiFi"
    echo
    echo -e "${YELLOW}⚠️  USANDO WiFi/ETHERNET si ves:${NC}"
    echo "   • Solo interfaces en0 (WiFi) o en1 (Ethernet)"
    echo "   • Direcciones IP en rangos como 192.168.x.x o 10.x.x.x"
    echo "   • Rutas que pasan por gateway de router"
    echo
    echo -e "${BLUE}PARA FORZAR USO DE THUNDERBOLT BRIDGE:${NC}"
    echo "   1. Desconectar WiFi temporalmente"
    echo "   2. Verificar que ambas máquinas tengan Thunderbolt Bridge habilitado"
    echo "   3. En Preferencias del Sistema > Compartir > Pantalla Compartida"
    echo "   4. Asegurarse de que la conexión use la IP del bridge (169.254.x.x)"
    echo
}

# Función principal
main() {
    check_network_interfaces
    check_thunderbolt_devices
    check_screen_sharing_connections
    check_connection_route
    show_recommendations
    
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}Verificación completada. Revisa los resultados arriba.${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
}

# Ejecutar función principal
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
