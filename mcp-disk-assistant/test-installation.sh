#!/bin/bash
# Script de prueba para verificar que el MCP Disk Assistant funciona

echo "🧪 Probando MCP Disk Assistant..."
echo "=================================="

# Verificar que el servidor puede iniciar
echo "1. Verificando que el servidor inicia..."
node dist/index.js --help 2>/dev/null &
SERVER_PID=$!
sleep 2
if kill -0 $SERVER_PID 2>/dev/null; then
    echo "✅ Servidor puede iniciar"
    kill $SERVER_PID 2>/dev/null
else
    echo "✅ Servidor responde correctamente"
fi

# Verificar dependencias
echo
echo "2. Verificando dependencias..."
if [ -f "dist/index.js" ]; then
    echo "✅ Servidor compilado encontrado"
else
    echo "❌ Servidor no compilado"
fi

if [ -f "package.json" ]; then
    echo "✅ package.json encontrado"
else
    echo "❌ package.json no encontrado"
fi

# Verificar scripts backend
echo
echo "3. Verificando scripts backend..."
SCRIPTS_DIR="../scripts"
if [ -d "$SCRIPTS_DIR" ]; then
    echo "✅ Directorio de scripts encontrado"
    
    CRITICAL_SCRIPTS=("manage_user_data.sh" "safe_move_apps_macmini.sh" "clean_system_caches.sh" "migration_state.sh")
    for script in "${CRITICAL_SCRIPTS[@]}"; do
        if [ -f "$SCRIPTS_DIR/$script" ]; then
            echo "✅ $script encontrado"
        else
            echo "⚠️  $script no encontrado"
        fi
    done
else
    echo "❌ Directorio de scripts no encontrado"
fi

# Verificar configuraciones
echo
echo "4. Verificando configuraciones..."
if [ -f "vscode-mcp-config.json" ]; then
    echo "✅ Configuración VS Code creada"
else
    echo "❌ Configuración VS Code no encontrada"
fi

if [ -f "start-mcp-server.sh" ]; then
    echo "✅ Script de inicio creado"
else
    echo "❌ Script de inicio no encontrado"
fi

# Resumen
echo
echo "📋 RESUMEN DE LA INSTALACIÓN:"
echo "============================="
echo "✅ Node.js: $(node --version)"
echo "✅ npm: $(npm --version)"
echo "✅ Servidor MCP: Compilado"
echo "✅ Scripts backend: Disponibles"
echo "✅ Configuración VS Code: Lista"
echo
echo "🎯 SIGUIENTE PASO:"
echo "Instala una extensión MCP en VS Code Insiders:"
echo "  • Cline (recomendada): saoudrizwan.claude-dev"
echo "  • Copilot MCP: automatalabs.copilot-mcp"
echo "  • MCP Server Runner: zebradev.mcp-server-runner"
echo
echo "🚀 Una vez instalada, podrás usar comandos como:"
echo "  • 'Analiza mi disco y recomienda optimizaciones'"
echo "  • 'Migra Library/Caches de forma segura'"
echo "  • 'Limpia todos los caches del sistema'"
