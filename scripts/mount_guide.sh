#!/bin/bash
# Guía paso a paso para corregir puntos de montaje manualmente
# Sin requerir sudo ni scripts complejos
# Autor: Guía de corrección manual
# Fecha: $(date)

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=== GUÍA PARA CORREGIR PUNTOS DE MONTAJE MANUALMENTE ===${NC}"
echo -e "${BLUE}Fecha: $(date)${NC}"
echo

# Verificar estado actual
echo -e "${YELLOW}1. ESTADO ACTUAL:${NC}"
echo -e "${BLUE}Discos actualmente montados:${NC}"
mount | grep -E "(BLACK2T|8TbSeries)" | while read line; do
    echo "   $line"
done
echo

echo -e "${BLUE}Directorios en /Volumes:${NC}"
ls -la /Volumes/ | grep -E "(BLACK2T|8TbSeries)" | while read line; do
    echo "   $line"
done
echo

echo -e "${YELLOW}2. PASOS PARA CORREGIR (MÉTODO SIMPLE):${NC}"
echo
echo -e "${BLUE}Opción A - Desde Finder (MÁS FÁCIL):${NC}"
echo "1. Abre Finder"
echo "2. En la barra lateral, busca los discos BLACK2T-1 y 8TbSeries-1"
echo "3. Haz clic en el botón 'Expulsar' (⏏️) junto a cada disco"
echo "4. Ve a 'Ir' -> 'Conectar al servidor' (⌘K)"
echo "5. Escribe: smb://Angel's Mac Studio._smb._tcp.local/"
echo "6. Selecciona los discos BLACK2T y 8TbSeries"
echo "7. Ahora deberían montarse como /Volumes/BLACK2T y /Volumes/8TbSeries"
echo

echo -e "${BLUE}Opción B - Desde Terminal (SI SABES LA CONTRASEÑA):${NC}"
echo "1. Desmontar los discos actuales:"
echo "   diskutil unmount '/Volumes/BLACK2T-1'"
echo "   diskutil unmount '/Volumes/8TbSeries-1'"
echo "2. Remover directorios vacíos (si existen):"
echo "   sudo rmdir /Volumes/BLACK2T"
echo "   sudo rmdir /Volumes/8TbSeries"
echo "3. Reconectar desde Finder como en Opción A"
echo

echo -e "${YELLOW}3. VERIFICAR CORRECCIÓN:${NC}"
echo "Después de reconectar, ejecuta este comando para verificar:"
echo "   mount | grep -E '(BLACK2T|8TbSeries)'"
echo "Deberías ver algo como:"
echo "   //...Mac Studio.../BLACK2T on /Volumes/BLACK2T"
echo "   //...Mac Studio.../8TbSeries on /Volumes/8TbSeries"
echo

echo -e "${YELLOW}4. PROBLEMA COMÚN - DIRECTORIOS VACÍOS:${NC}"
echo "Si ves directorios vacíos en /Volumes que impiden el montaje correcto:"
echo "Verifica si están vacíos:"
echo "   ls -la /Volumes/BLACK2T"
echo "   ls -la /Volumes/8TbSeries"
echo "Si están vacíos, puedes removerlos:"
echo "   sudo rmdir /Volumes/BLACK2T"
echo "   sudo rmdir /Volumes/8TbSeries"
echo

echo -e "${GREEN}5. PREVENCIÓN FUTURA:${NC}"
echo "Para evitar este problema en el futuro:"
echo "- Siempre expulsa los discos correctamente desde Finder"
echo "- No desconectes la red Thunderbolt abruptamente"
echo "- Usa 'Conectar al servidor' en lugar de navegar por la red"
echo

echo -e "${CYAN}¿Quieres intentar el desmontaje automático? (y/n)${NC}"
read -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Intentando desmontar BLACK2T-1...${NC}"
    diskutil unmount '/Volumes/BLACK2T-1' && echo -e "${GREEN}✅ BLACK2T-1 desmontado${NC}" || echo -e "${RED}❌ Error desmontando BLACK2T-1${NC}"
    
    echo -e "${BLUE}Intentando desmontar 8TbSeries-1...${NC}"
    diskutil unmount '/Volumes/8TbSeries-1' && echo -e "${GREEN}✅ 8TbSeries-1 desmontado${NC}" || echo -e "${RED}❌ Error desmontando 8TbSeries-1${NC}"
    
    echo -e "${YELLOW}Ahora reconecta desde Finder usando 'Conectar al servidor'${NC}"
    echo -e "${BLUE}Abriendo ventana de conexión...${NC}"
    open "smb://Angel's Mac Studio._smb._tcp.local/"
fi
