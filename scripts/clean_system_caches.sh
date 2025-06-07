#!/bin/bash
# Script para limpiar caches y archivos temporales de manera segura
# CONFIGURADO PARA: MacMini (sufijo _macmini en logs)
# Para usar en Mac Studio o Mac Pro, cambiar sufijo en configuración de logs
# Esta es la primera línea de defensa para liberar espacio sin riesgos
# Autor: Script de limpieza segura del sistema
# Fecha: $(date)

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_FILE="$HOME/Documents/scripts/system_cleanup_macmini.log"

# Función para logging
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo -e "$1"
}

# Función para mostrar tamaño antes/después
show_size_comparison() {
    local path="$1"
    local description="$2"
    
    if [ -d "$path" ]; then
        local size_before=$(du -sh "$path" 2>/dev/null | cut -f1)
        echo -e "${BLUE}$description: $size_before${NC}"
    else
        echo -e "${YELLOW}$description: No existe${NC}"
    fi
}

# Función para limpiar directorio de manera segura
safe_clean_directory() {
    local path="$1"
    local description="$2"
    local size_before=""
    local size_after=""
    
    if [ -d "$path" ]; then
        size_before=$(du -sb "$path" 2>/dev/null | cut -f1)
        size_before=${size_before:-0}
        
        echo -e "${BLUE}Limpiando $description...${NC}"
        
        # Limpiar archivos de más de 7 días para ser conservadores
        find "$path" -type f -mtime +7 -delete 2>/dev/null || true
        
        size_after=$(du -sb "$path" 2>/dev/null | cut -f1)
        size_after=${size_after:-0}
        
        local space_freed=$((size_before - size_after))
        if [ $space_freed -gt 0 ]; then
            local space_freed_mb=$((space_freed / 1024 / 1024))
            log_message "${GREEN}✅ $description: Liberados ${space_freed_mb}MB${NC}"
        else
            log_message "${YELLOW}⚠️  $description: Sin archivos antiguos para limpiar${NC}"
        fi
    else
        log_message "${YELLOW}⚠️  $description: Directorio no existe${NC}"
    fi
}

# Análisis inicial del sistema
analyze_system_usage() {
    log_message "${CYAN}=== ANÁLISIS DEL SISTEMA ===${NC}"
    
    echo -e "${BLUE}Uso actual del disco:${NC}"
    df -h / | tail -1 | awk '{printf "  Disco interno: %s usado de %s (%s)\n", $3, $2, $5}'
    
    echo -e "\n${BLUE}Análisis de directorios que consumen espacio:${NC}"
    
    # Caches de usuario
    show_size_comparison "$HOME/Library/Caches" "Caches de usuario"
    
    # Application Support
    show_size_comparison "$HOME/Library/Application Support" "Datos de aplicaciones"
    
    # Logs
    show_size_comparison "$HOME/Library/Logs" "Logs de usuario"
    show_size_comparison "/var/log" "Logs del sistema"
    
    # Descargas
    show_size_comparison "$HOME/Downloads" "Descargas"
    
    # Papelera
    show_size_comparison "$HOME/.Trash" "Papelera"
    
    # Archivos temporales
    show_size_comparison "/tmp" "Archivos temporales"
    show_size_comparison "/private/var/tmp" "Archivos temporales del sistema"
    
    # Xcode (si existe)
    show_size_comparison "$HOME/Library/Developer/Xcode/DerivedData" "Datos derivados de Xcode"
    show_size_comparison "$HOME/Library/Developer/Xcode/Archives" "Archivos de Xcode"
    
    # Docker (si existe)
    show_size_comparison "$HOME/Library/Containers/com.docker.docker" "Datos de Docker"
    
    # Simuladores iOS
    show_size_comparison "$HOME/Library/Developer/CoreSimulator" "Simuladores iOS"
    
    # Homebrew
    show_size_comparison "/usr/local/Homebrew/Library/Caches" "Cache de Homebrew"
    show_size_comparison "/opt/homebrew/Library/Caches" "Cache de Homebrew (M1)"
    
    echo
}

# Limpiar caches de usuario (seguro)
clean_user_caches() {
    log_message "${CYAN}=== LIMPIANDO CACHES DE USUARIO ===${NC}"
    
    # Caches principales de aplicaciones
    safe_clean_directory "$HOME/Library/Caches/com.apple.Safari" "Safari Cache"
    safe_clean_directory "$HOME/Library/Caches/com.google.Chrome" "Chrome Cache"
    safe_clean_directory "$HOME/Library/Caches/com.mozilla.firefox" "Firefox Cache"
    safe_clean_directory "$HOME/Library/Caches/com.spotify.client" "Spotify Cache"
    safe_clean_directory "$HOME/Library/Caches/com.adobe.Creative-Cloud" "Adobe CC Cache"
    
    # Limpiar caches generales (conservadoramente)
    if [ -d "$HOME/Library/Caches" ]; then
        log_message "${BLUE}Limpiando caches generales...${NC}"
        find "$HOME/Library/Caches" -name "*.cache" -mtime +7 -delete 2>/dev/null || true
        find "$HOME/Library/Caches" -name "*.tmp" -mtime +3 -delete 2>/dev/null || true
    fi
}

# Limpiar logs antiguos
clean_old_logs() {
    log_message "${CYAN}=== LIMPIANDO LOGS ANTIGUOS ===${NC}"
    
    # Logs de usuario
    safe_clean_directory "$HOME/Library/Logs" "Logs de usuario"
    
    # Limpiar logs del sistema (requiere sudo)
    if [ "$EUID" -eq 0 ]; then
        safe_clean_directory "/var/log" "Logs del sistema"
    else
        log_message "${YELLOW}⚠️  Para limpiar logs del sistema, ejecutar con sudo${NC}"
    fi
}

# Limpiar archivos de desarrollo
clean_development_files() {
    log_message "${CYAN}=== LIMPIANDO ARCHIVOS DE DESARROLLO ===${NC}"
    
    # Xcode
    if [ -d "$HOME/Library/Developer/Xcode/DerivedData" ]; then
        log_message "${BLUE}Limpiando datos derivados de Xcode...${NC}"
        rm -rf "$HOME/Library/Developer/Xcode/DerivedData"/* 2>/dev/null || true
        log_message "${GREEN}✅ Xcode DerivedData limpiado${NC}"
    fi
    
    # Simuladores iOS antiguos
    if command -v xcrun >/dev/null 2>&1; then
        log_message "${BLUE}Limpiando simuladores iOS no disponibles...${NC}"
        xcrun simctl delete unavailable 2>/dev/null || true
        log_message "${GREEN}✅ Simuladores iOS limpiados${NC}"
    fi
    
    # Node.js modules cache
    if [ -d "$HOME/.npm" ]; then
        log_message "${BLUE}Limpiando cache de npm...${NC}"
        npm cache clean --force 2>/dev/null || true
        log_message "${GREEN}✅ Cache de npm limpiado${NC}"
    fi
    
    # Python cache
    find "$HOME" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
    find "$HOME" -name "*.pyc" -delete 2>/dev/null || true
}

# Limpiar Homebrew
clean_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        log_message "${CYAN}=== LIMPIANDO HOMEBREW ===${NC}"
        
        log_message "${BLUE}Limpiando cache de Homebrew...${NC}"
        brew cleanup --prune=7 2>/dev/null || true
        
        log_message "${BLUE}Eliminando versiones antiguas...${NC}"
        brew autoremove 2>/dev/null || true
        
        log_message "${GREEN}✅ Homebrew limpiado${NC}"
    else
        log_message "${YELLOW}⚠️  Homebrew no instalado${NC}"
    fi
}

# Vaciar papelera
empty_trash() {
    log_message "${CYAN}=== VACIANDO PAPELERA ===${NC}"
    
    if [ -d "$HOME/.Trash" ]; then
        local trash_size=$(du -sh "$HOME/.Trash" 2>/dev/null | cut -f1)
        
        read -p "¿Vaciar papelera ($trash_size)? (y/N): " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            rm -rf "$HOME/.Trash"/* 2>/dev/null || true
            log_message "${GREEN}✅ Papelera vaciada${NC}"
        else
            log_message "${BLUE}Papelera conservada${NC}"
        fi
    else
        log_message "${YELLOW}⚠️  Papelera vacía${NC}"
    fi
}

# Limpieza completa automática
full_auto_cleanup() {
    log_message "${CYAN}=== LIMPIEZA COMPLETA AUTOMÁTICA ===${NC}"
    log_message "${YELLOW}⚠️  Esta limpieza es conservadora y segura${NC}"
    
    clean_user_caches
    clean_old_logs
    clean_development_files
    clean_homebrew
    
    log_message "${GREEN}✅ Limpieza automática completada${NC}"
}

# Generar reporte de limpieza
generate_cleanup_report() {
    local report_file="$HOME/Documents/scripts/cleanup_report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "=== REPORTE DE LIMPIEZA DEL SISTEMA ==="
        echo "Fecha: $(date)"
        echo
        echo "=== ESTADO ANTES DE LIMPIEZA ==="
        df -h /
        echo
        echo "=== DIRECTORIOS ANALIZADOS ==="
        du -sh "$HOME/Library/Caches" 2>/dev/null || echo "Caches: No accesible"
        du -sh "$HOME/Library/Logs" 2>/dev/null || echo "Logs: No accesible"
        du -sh "$HOME/Downloads" 2>/dev/null || echo "Downloads: No accesible"
        du -sh "$HOME/.Trash" 2>/dev/null || echo "Trash: No accesible"
        echo
        echo "=== RECOMENDACIONES ==="
        echo "1. Ejecutar limpieza automática regularmente"
        echo "2. Revisar descargas y eliminar archivos innecesarios"
        echo "3. Considerar mover datos grandes a disco externo"
        echo "4. Usar herramientas como DaisyDisk para análisis visual"
    } > "$report_file"
    
    log_message "${GREEN}✅ Reporte generado: $report_file${NC}"
}

# Función principal
main() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                              ║${NC}"
    echo -e "${CYAN}║            ${YELLOW}LIMPIEZA SEGURA DEL SISTEMA${CYAN}                    ║${NC}"
    echo -e "${CYAN}║                                                              ║${NC}"
    echo -e "${CYAN}║  ${GREEN}Libera espacio sin riesgos limpiando archivos temporales${CYAN}  ║${NC}"
    echo -e "${CYAN}║                                                              ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${YELLOW}¿Qué tipo de limpieza quieres realizar?${NC}"
    echo "1. 📊 Análisis del sistema (sin cambios)"
    echo "2. 🧹 Limpiar solo caches de usuario"
    echo "3. 📝 Limpiar logs antiguos"
    echo "4. 👨‍💻 Limpiar archivos de desarrollo"
    echo "5. 🍺 Limpiar Homebrew"
    echo "6. 🗑️  Vaciar papelera"
    echo "7. 🚀 Limpieza completa automática (recomendado)"
    echo "8. 📋 Generar reporte de limpieza"
    echo "9. 🚪 Salir"
    
    read -p "Selecciona una opción (1-9): " choice
    
    case $choice in
        1) analyze_system_usage ;;
        2) clean_user_caches ;;
        3) clean_old_logs ;;
        4) clean_development_files ;;
        5) clean_homebrew ;;
        6) empty_trash ;;
        7) 
            analyze_system_usage
            echo
            read -p "¿Proceder con limpieza automática? (y/N): " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                full_auto_cleanup
                echo -e "\n${BLUE}Estado después de limpieza:${NC}"
                df -h / | tail -1 | awk '{printf "  Disco interno: %s usado de %s (%s)\n", $3, $2, $5}'
            fi
            ;;
        8) generate_cleanup_report ;;
        9) 
            log_message "${BLUE}Saliendo de la limpieza del sistema...${NC}"
            exit 0
            ;;
        *) 
            echo -e "${RED}❌ Opción inválida${NC}"
            exit 1
            ;;
    esac
    
    echo
    read -p "Presiona Enter para continuar..." -r
    main
}

# Ejecutar función principal
main "$@"
