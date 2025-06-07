#!/bin/bash

# Script de inicio rápido para el Asistente de Disco Interno
clear
echo "=== Asistente de Disco Interno - Inicio Rápido ==="
echo
echo "Ubicación: $(pwd)"
echo "Fecha: $(date)"
echo

# Cargar aliases
source aliases.sh
echo

# Mostrar estado compacto del sistema
bash scripts/display_compact_status.sh

# Menú rápido
echo "Opciones rápidas:"
echo "1) Abrir menú principal (disco-menu)"
echo "2) Ejecutar diagnósticos (disco-diagnostics)"
echo "3) Ver estado del sistema (disco-estado)"
echo "4) Guía de montaje (disco-mount)"
echo "5) Limpiar sistema (disco-cleanup)"
echo "6) Salir"
echo

read -p "Selecciona una opción (1-6): " opcion

case $opcion in
    1) bash scripts/app_manager_master.sh ;;
    2) bash scripts/damage_assessment.sh ;;
    3) bash scripts/display_friendly_status.sh ;;
    4) bash scripts/mount_guide.sh ;;
    5) bash scripts/clean_system_caches.sh ;;
    6) echo "¡Hasta luego!" ;;
    *) echo "Opción no válida" ;;
esac
