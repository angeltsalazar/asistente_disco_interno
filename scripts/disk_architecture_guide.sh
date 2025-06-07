#!/bin/bash
# GUÍA DE ARQUITECTURA DE DISCOS
# Propósito y uso correcto de cada volumen externo

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║              ARQUITECTURA DE DISCOS EXTERNOS                 ║${NC}"
echo -e "${CYAN}║               Propósito y uso correcto                       ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

echo -e "${BLUE}🗄️  DISEÑO ORIGINAL:${NC}"
echo
echo -e "${GREEN}📦 BLACK2T (2TB)${NC} - ${YELLOW}ALMACENAMIENTO PRINCIPAL${NC}"
echo -e "• Datos de usuario en uso activo"
echo -e "• Transferencias rsync desde Mac Mini"
echo -e "• Estructura: /Volumes/BLACK2T/UserContent_macmini/"
echo -e "• Propósito: Datos principales y operativos"
echo
echo -e "${MAGENTA}💾 8TbSeries (8TB)${NC} - ${YELLOW}SOLO BACKUPS${NC}"
echo -e "• Respaldos automáticos de BLACK2T"
echo -e "• Copias de seguridad históricas"
echo -e "• Estructura: /Volumes/8TbSeries/UserData_*_backup_macmini/"
echo -e "• Propósito: Redundancia y recuperación"
echo

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    FLUJO DE DATOS                           ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${BLUE}📱 Mac Mini${NC} ──rsync──> ${GREEN}BLACK2T${NC} ──backup──> ${MAGENTA}8TbSeries${NC}"
echo
echo -e "${YELLOW}1. TRANSFERENCIA PRINCIPAL:${NC}"
echo -e "   Mac Mini → BLACK2T (rsync/SSH)"
echo -e "   • Downloads, Documents, Pictures, etc."
echo -e "   • Datos en uso activo"
echo -e "   • Acceso directo y rápido"
echo
echo -e "${YELLOW}2. BACKUP AUTOMÁTICO:${NC}"
echo -e "   BLACK2T → 8TbSeries (rsync local)"
echo -e "   • Copias de seguridad programadas"
echo -e "   • Versiones históricas"
echo -e "   • Solo para recuperación"
echo

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                  PROBLEMA IDENTIFICADO                      ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${RED}❌ PROBLEMA:${NC}"
echo -e "Los scripts originales intentaban escribir directamente en 8TbSeries"
echo -e "desde Mac Mini, pero este disco tiene permisos restrictivos."
echo
echo -e "${YELLOW}⚠️  CONFUSIÓN EN SCRIPTS ORIGINALES:${NC}"
echo -e "• manage_user_data.sh requería AMBOS discos escribibles"
echo -e "• No diferenciaba entre datos principales y backups"
echo -e "• Causaba errores cuando 8TbSeries era solo lectura"
echo

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                   SOLUCIÓN IMPLEMENTADA                     ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${GREEN}✅ NUEVA ARQUITECTURA:${NC}"
echo
echo -e "${BLUE}1. DATOS PRINCIPALES → BLACK2T${NC}"
echo -e "   • rsync_black2t_only.sh"
echo -e "   • Transferencia directa Mac Mini → BLACK2T"
echo -e "   • Sin dependencia de 8TbSeries"
echo
echo -e "${BLUE}2. BACKUPS → 8TbSeries (FUTURO)${NC}"
echo -e "   • Script de backup LOCAL en Mac Studio"
echo -e "   • BLACK2T → 8TbSeries (mismo sistema)"
echo -e "   • Sin problemas de permisos remotos"
echo

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    RECOMENDACIONES                          ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${GREEN}📋 MEJORES PRÁCTICAS:${NC}"
echo
echo -e "${YELLOW}1. TRANSFERENCIAS (Mac Mini → Mac Studio):${NC}"
echo -e "   • Usar solo: ${GREEN}rsync_black2t_only.sh${NC}"
echo -e "   • Destino: BLACK2T únicamente"
echo -e "   • No requerir 8TbSeries escribible"
echo
echo -e "${YELLOW}2. BACKUPS (Mac Studio local):${NC}"
echo -e "   • Script separado para BLACK2T → 8TbSeries"
echo -e "   • Ejecutar en Mac Studio (sin red)"
echo -e "   • Programar automáticamente"
echo
echo -e "${YELLOW}3. ORGANIZACIÓN:${NC}"
echo -e "   • Datos activos: ${GREEN}BLACK2T/UserContent_macmini/${NC}"
echo -e "   • Backups: ${MAGENTA}8TbSeries/UserData_backup_macmini/${NC}"
echo -e "   • Separar responsabilidades claramente"
echo

echo -e "${BLUE}💡 CONCLUSIÓN:${NC}"
echo -e "El diseño actual con rsync_black2t_only.sh es CORRECTO."
echo -e "8TbSeries debe usarse solo para backups locales en Mac Studio."
