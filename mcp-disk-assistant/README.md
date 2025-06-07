# MCP Disk Assistant

Un servidor MCP (Model Context Protocol) inteligente para gestión avanzada de discos en macOS.

## 🎯 Características

- **Análisis Inteligente**: Analiza uso de disco y recomienda optimizaciones
- **Migración Segura**: Migra datos de usuario con validaciones de seguridad  
- **Limpieza Automática**: Limpia caches, logs y archivos temporales
- **Gestión de Apps**: Mueve aplicaciones de terceros a discos externos
- **Estado en Tiempo Real**: Monitorea migraciones y estado del sistema
- **Recomendaciones IA**: Sugerencias personalizadas basadas en análisis

## 🚀 Instalación

### 1. Instalar dependencias

```bash
cd mcp-disk-assistant
npm install
```

### 2. Compilar el proyecto

```bash
npm run build
```

### 3. Configurar en Cursor/Claude

Agregar al archivo de configuración MCP (`~/Library/Application Support/Claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "disk-assistant": {
      "command": "node",
      "args": ["/ruta/completa/a/mcp-disk-assistant/dist/index.js"],
      "cwd": "/Volumes/BLACK2T/UserContent_macmini/Documents/Documents/asistente_disco_interno"
    }
  }
}
```

## 🛠️ Herramientas Disponibles

### 📊 Análisis
- `analyze_disk_usage` - Analiza uso de disco con recomendaciones
- `get_recommendations` - Recomendaciones personalizadas por prioridad

### 🔄 Migración  
- `migrate_user_data` - Migra directorios de usuario de forma segura
- `safe_move_applications` - Mueve aplicaciones de terceros
- `restore_applications` - Restaura aplicaciones al disco interno

### 🧹 Limpieza
- `cleanup_system` - Limpia caches, logs y archivos temporales  

### 📋 Monitoreo
- `check_disk_status` - Estado de discos y enlaces simbólicos
- `get_migration_status` - Estado de migraciones realizadas

## 💬 Ejemplo de Uso en Chat

Una vez instalado, puedes usar el asistente directamente en chat:

```
Usuario: "Analiza mi disco y dime qué puedo migrar para liberar espacio"

Asistente: [Ejecuta analyze_disk_usage y get_recommendations]

Usuario: "Migra mi carpeta Downloads al disco externo pero hazlo seguro"

Asistente: [Ejecuta migrate_user_data con dryRun: true primero, luego real]

Usuario: "Limpia todos los caches del sistema"

Asistente: [Ejecuta cleanup_system con type: 'cache']
```

## 🔧 Configuración Avanzada

### Variables de Entorno

- `DISK_ASSISTANT_BASE_PATH` - Ruta base de scripts (por defecto: detección automática)
- `DISK_ASSISTANT_LOG_LEVEL` - Nivel de logging (info|debug|error)

### Archivos de Configuración

- `config/migration_state.json` - Estado de migraciones
- `logs/*.log` - Logs de operaciones
- `scripts/*.sh` - Scripts de backend

## 🛡️ Seguridad

- **Validación estricta** de todas las rutas y operaciones
- **Dry-run por defecto** en operaciones de riesgo
- **Backup automático** antes de migraciones
- **Rollback** disponible para todas las operaciones
- **Detección de apps críticas** para prevenir daños

## 🚀 Desarrollo

```bash
# Modo desarrollo con hot reload
npm run dev

# Tests
npm test

# Build para producción  
npm run build
```

## 📝 Logs y Debugging

Los logs se almacenan en:
- `logs/mcp-disk-assistant.log` - Log principal
- `logs/migrations.log` - Log de migraciones  
- `logs/errors.log` - Errores y warnings

## 🤝 Integración con Scripts Existentes

Este MCP server actúa como un wrapper inteligente sobre tus scripts existentes:

- `app_manager_master.sh` - Menú principal
- `manage_user_data.sh` - Gestión de datos  
- `safe_move_apps_macmini.sh` - Movimiento de apps
- `clean_system_caches.sh` - Limpieza sistema
- `migration_state.sh` - Estado de migración

## 📦 Distribución

Una vez configurado, el asistente estará disponible como herramienta nativa en cualquier chat de Cursor/Claude, proporcionando acceso inteligente a todas las funcionalidades de gestión de disco.
