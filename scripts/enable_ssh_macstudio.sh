#!/bin/bash
# Script para habilitar SSH en Mac Studio y configurar la conexión
# Ejecutar en Mac Mini para verificar y guiar la configuración SSH

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

MAC_STUDIO_IP="192.168.100.1"
MAC_STUDIO_USER="angelsalazar"

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║            CONFIGURAR SSH EN MAC STUDIO (192.168.100.1)     ║${NC}"
echo -e "${CYAN}║         Para solucionar problemas SMB usando RSYNC          ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

# Verificar conectividad básica
echo -e "${BLUE}🔍 Verificando conectividad de red...${NC}"
if ping -c 1 "$MAC_STUDIO_IP" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Mac Studio ($MAC_STUDIO_IP) es accesible por red${NC}"
else
    echo -e "${RED}❌ No se puede conectar a Mac Studio ($MAC_STUDIO_IP)${NC}"
    echo -e "${YELLOW}Verifica que ambos Macs estén en la misma red${NC}"
    exit 1
fi

echo

# Verificar si SSH ya está habilitado
echo -e "${BLUE}🔍 Verificando si SSH ya está habilitado...${NC}"
if ssh -o ConnectTimeout=3 -o BatchMode=yes "${MAC_STUDIO_USER}@${MAC_STUDIO_IP}" "echo 'SSH OK'" 2>/dev/null; then
    echo -e "${GREEN}✅ SSH ya está habilitado y funcionando${NC}"
    echo -e "${GREEN}Puedes usar el script rsync_solution.sh directamente${NC}"
    exit 0
fi

echo -e "${YELLOW}⚠️  SSH no está habilitado o no está configurado${NC}"
echo

# Instrucciones para habilitar SSH
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                  INSTRUCCIONES SSH                           ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${YELLOW}En el Mac Studio (192.168.100.1), ejecuta estos pasos:${NC}"
echo
echo -e "${BLUE}OPCIÓN 1: Habilitar SSH desde Terminal${NC}"
echo -e "1. Abre Terminal en Mac Studio"
echo -e "2. Ejecuta: ${GREEN}sudo systemsetup -setremotelogin on${NC}"
echo -e "3. Confirma el password cuando se solicite"
echo
echo -e "${BLUE}OPCIÓN 2: Habilitar SSH desde Preferencias del Sistema${NC}"
echo -e "1. Ve a: Apple menu > Preferencias del Sistema"
echo -e "2. Clic en 'Compartir' (Sharing)"
echo -e "3. Marca la casilla 'Inicio de sesión remoto' (Remote Login)"
echo -e "4. Asegúrate de que el usuario 'angel' tenga acceso"
echo
echo -e "${BLUE}OPCIÓN 3: Un comando rápido (si tienes acceso físico)${NC}"
echo -e "Ejecuta en Mac Studio: ${GREEN}sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist${NC}"
echo

# Crear script de verificación automática
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║            SCRIPT DE VERIFICACIÓN AUTOMÁTICA                ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${BLUE}Creando script de verificación automática...${NC}"

cat > "$HOME/check_ssh_ready.sh" << 'EOF'
#!/bin/bash
# Verificación automática de SSH cada 10 segundos

MAC_STUDIO_IP="192.168.100.1"
MAC_STUDIO_USER="angel"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Verificando SSH cada 10 segundos...${NC}"
echo -e "${YELLOW}Presiona Ctrl+C para salir${NC}"
echo

while true; do
    if ssh -o ConnectTimeout=3 -o BatchMode=yes "${MAC_STUDIO_USER}@${MAC_STUDIO_IP}" "echo 'SSH OK'" 2>/dev/null; then
        echo -e "${GREEN}✅ ¡SSH HABILITADO Y FUNCIONANDO!${NC}"
        echo -e "${GREEN}Ahora puedes usar: rsync_solution.sh${NC}"
        break
    else
        echo -e "${YELLOW}⏳ SSH aún no está disponible... verificando de nuevo en 10s${NC}"
        sleep 10
    fi
done
EOF

chmod +x "$HOME/check_ssh_ready.sh"
echo -e "${GREEN}✅ Script creado: $HOME/check_ssh_ready.sh${NC}"

echo
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    PRÓXIMOS PASOS                           ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${YELLOW}1. Habilita SSH en Mac Studio usando una de las opciones arriba${NC}"
echo -e "${YELLOW}2. Ejecuta este comando para verificar automáticamente:${NC}"
echo -e "   ${GREEN}$HOME/check_ssh_ready.sh${NC}"
echo -e "${YELLOW}3. Una vez que SSH esté listo, usa:${NC}"
echo -e "   ${GREEN}./rsync_solution.sh${NC}"
echo

# Configurar llaves SSH si no existen
if [ ! -f "$HOME/.ssh/id_rsa" ]; then
    echo -e "${BLUE}🔑 Generando llaves SSH para facilitar la conexión...${NC}"
    ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/id_rsa" -N "" -q
    echo -e "${GREEN}✅ Llaves SSH generadas${NC}"
    
    echo -e "${YELLOW}Para evitar passwords, después de habilitar SSH ejecuta:${NC}"
    echo -e "${GREEN}ssh-copy-id ${MAC_STUDIO_USER}@${MAC_STUDIO_IP}${NC}"
fi

echo
echo -e "${CYAN}¿Quieres ejecutar la verificación automática ahora? (y/n)${NC}"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    exec "$HOME/check_ssh_ready.sh"
fi
