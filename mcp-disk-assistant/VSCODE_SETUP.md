# 🆚 MCP Disk Assistant para VS Code Insiders

## ✅ Instalación Completada

Tu **MCP Disk Assistant** está listo para funcionar con VS Code Insiders. A diferencia de Claude Desktop, VS Code necesita extensiones específicas para conectar con servidores MCP.

## 🔧 Configuración Realizada

### ✅ Archivos Creados:
- **Servidor MCP compilado:** `dist/index.js`
- **Configuración VS Code:** `~/.vscode-insiders/User/settings.json`
- **Config MCP específico:** `vscode-mcp-config.json`
- **Script de inicio directo:** `start-mcp-server.sh`

## 📋 Próximos Pasos Obligatorios

### 1. **Instalar Extensión MCP** (OBLIGATORIO)

Abre VS Code Insiders e instala **una** de estas extensiones:

#### 🏆 **Opción 1: Cline (RECOMENDADA)**
- **ID:** `saoudrizwan.claude-dev`
- **Más popular:** 1.6M+ instalaciones
- **Características:** Chat IA integrado, soporte MCP nativo

#### 🤖 **Opción 2: Copilot MCP**
- **ID:** `automatalabs.copilot-mcp`
- **Especializada:** Específica para gestionar servidores MCP
- **Características:** Gestión avanzada de múltiples MCP servers

#### 🔧 **Opción 3: MCP Server Runner**
- **ID:** `zebradev.mcp-server-runner`
- **Minimalista:** Para gestionar MCP servers localmente

### 2. **Configuración de la Extensión**

Una vez instalada la extensión, sigue estos pasos:

#### Para **Cline:**
1. Abre la paleta de comandos (`Cmd+Shift+P`)
2. Busca "Cline: Configure MCP Servers"
3. Usa esta configuración:
```json
{
  "disk-assistant": {
    "command": "node",
    "args": ["/ruta/completa/a/mcp-disk-assistant/dist/index.js"],
    "cwd": "/Volumes/BLACK2T/UserContent_macmini/Documents/Documents/asistente_disco_interno"
  }
}
```

#### Para **Copilot MCP:**
1. Ve a Settings (`Cmd+,`)
2. Busca "copilot-mcp"
3. Agrega el servidor desde la configuración creada

#### Para **MCP Server Runner:**
1. Abre la paleta de comandos
2. Busca "MCP: Add Server"
3. Usa el archivo `vscode-mcp-config.json` creado

## 🚀 Usar el Asistente

### **Método 1: A través de Extensión (Recomendado)**

Una vez configurada la extensión:

1. **Abre el panel de chat** de la extensión
2. **Habla naturalmente:**
   - *"Analiza mi disco y recomienda optimizaciones"*
   - *"Migra Library/Caches de forma segura"*
   - *"Limpia todos los caches del sistema"*
   - *"Muestra el estado de mis migraciones"*

### **Método 2: Servidor Manual**

Si prefieres usar el servidor directamente:

```bash
# Iniciar servidor
./start-mcp-server.sh

# O manualmente
node dist/index.js
```

## 🛠️ Herramientas Disponibles

Una vez conectado, tendrás acceso a:

| Herramienta | Función |
|-------------|---------|
| `analyze_disk_usage` | Análisis inteligente de disco |
| `migrate_user_data` | Migración segura de directorios |
| `cleanup_system` | Limpieza de caches y logs |
| `check_disk_status` | Estado de discos externos |
| `get_migration_status` | Estado de migraciones |
| `safe_move_applications` | Gestión de aplicaciones |
| `get_recommendations` | Recomendaciones IA |

## 🔍 Verificar Instalación

### **Probar Servidor MCP:**
```bash
cd /Volumes/BLACK2T/UserContent_macmini/Documents/Documents/asistente_disco_interno/mcp-disk-assistant
node dist/index.js
```

### **Verificar Configuración VS Code:**
```bash
cat ~/.vscode-insiders/User/settings.json | grep -A 10 "disk-assistant"
```

## 🎯 Ejemplo de Flujo Completo

1. **Abrir VS Code Insiders**
2. **Instalar extensión Cline**
3. **Abrir panel de chat de Cline**
4. **Escribir:** *"Analiza mi disco y dime qué puedo migrar"*
5. **El asistente ejecutará automáticamente las herramientas necesarias**
6. **Seguir las recomendaciones interactivamente**

## 🆚 Diferencias vs Claude Desktop

| Aspecto | Claude Desktop | VS Code |
|---------|----------------|---------|
| **Configuración** | Archivo único | Extensión + configuración |
| **Activación** | Automática | Manual (por extensión) |
| **Interface** | Chat dedicado | Panel integrado |
| **Ventajas** | Más simple | Integrado en IDE |

## 🔧 Solución de Problemas

### **Servidor no responde:**
```bash
# Verificar Node.js
node --version

# Reinstalar dependencias
npm install && npm run build
```

### **Extensión no detecta servidor:**
1. Verificar configuración en settings.json
2. Reiniciar VS Code completamente
3. Verificar que el servidor inicia manualmente

### **Logs de debugging:**
```bash
# Ver logs del servidor
node dist/index.js 2>&1 | tee mcp-debug.log
```

---

## 🎊 ¡Tu Asistente Está Listo!

Con esta configuración tienes toda la potencia de tu sistema de gestión de discos integrada directamente en VS Code Insiders. **¡Solo falta instalar la extensión y empezar a chatear con tu disco!** 🚀
