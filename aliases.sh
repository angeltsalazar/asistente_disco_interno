#!/bin/bash

# Aliases para el Asistente de Disco Interno
alias asistente-disco='cd /Volumes/BLACK2T/UserContent_macmini/Documents/Documents/asistente_disco_interno'
alias disco-scripts='cd /Volumes/BLACK2T/UserContent_macmini/Documents/Documents/asistente_disco_interno/scripts'
alias disco-logs='cd /Volumes/BLACK2T/UserContent_macmini/Documents/Documents/asistente_disco_interno/logs'
alias disco-docs='cd /Volumes/BLACK2T/UserContent_macmini/Documents/Documents/asistente_disco_interno/docs'

# Comandos rápidos
alias disco-estado='bash /Volumes/BLACK2T/UserContent_macmini/Documents/Documents/asistente_disco_interno/scripts/display_friendly_status.sh'
alias disco-resumen='bash /Volumes/BLACK2T/UserContent_macmini/Documents/Documents/asistente_disco_interno/scripts/display_compact_status.sh'
alias disco-estado-raw='cat /Volumes/BLACK2T/UserContent_macmini/Documents/Documents/asistente_disco_interno/config/migration_state.json | jq .'
alias disco-menu='bash /Volumes/BLACK2T/UserContent_macmini/Documents/Documents/asistente_disco_interno/scripts/app_manager_master.sh'
alias disco-diagnostics='bash /Volumes/BLACK2T/UserContent_macmini/Documents/Documents/asistente_disco_interno/scripts/damage_assessment.sh'
alias disco-mount='bash /Volumes/BLACK2T/UserContent_macmini/Documents/Documents/asistente_disco_interno/scripts/mount_guide.sh'
alias disco-permissions='bash /Volumes/BLACK2T/UserContent_macmini/Documents/Documents/asistente_disco_interno/scripts/permission_diagnostics.sh'
alias disco-cleanup='bash /Volumes/BLACK2T/UserContent_macmini/Documents/Documents/asistente_disco_interno/scripts/clean_system_caches.sh'

# Comando de ayuda
alias disco-help='bash /Volumes/BLACK2T/UserContent_macmini/Documents/Documents/asistente_disco_interno/scripts/show_commands_menu.sh'
alias disco-comandos='bash /Volumes/BLACK2T/UserContent_macmini/Documents/Documents/asistente_disco_interno/scripts/show_commands_menu.sh'
alias disco-lista='bash /Volumes/BLACK2T/UserContent_macmini/Documents/Documents/asistente_disco_interno/scripts/show_commands_simple.sh'

echo "Aliases del Asistente de Disco Interno cargados."
echo "Comandos disponibles:"
echo "  asistente-disco  - Ir al directorio principal"
echo "  disco-scripts    - Ir a los scripts"
echo "  disco-logs       - Ver logs"
echo "  disco-docs       - Ver documentación"
echo "  disco-estado     - Ver estado del sistema (formato completo)"
echo "  disco-resumen    - Ver resumen rápido del sistema"
echo "  disco-estado-raw - Ver estado del sistema (JSON crudo)"
echo "  disco-menu       - Abrir menú principal"
echo "  disco-diagnostics- Ejecutar diagnósticos"
echo "  disco-mount      - Guía de montaje"
echo "  disco-permissions- Diagnóstico de permisos"
echo "  disco-cleanup    - Limpieza del sistema"
echo "  disco-help       - ❓ Ver menú completo de comandos"
echo "  disco-comandos   - 📋 Ver menú completo de comandos"
echo "  disco-lista      - 📝 Ver lista rápida de comandos"
