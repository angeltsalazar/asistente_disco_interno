# 🚀 Guía Completa: Uso del Asistente de Disco MCP en VS Code Insiders

## ✅ Estado de la Instalación

Su servidor MCP Disk Assistant está **completamente configurado y funcionando**. Todas las herramientas de análisis, migración y limpieza de disco están listas para usar.

## 🎯 Siguiente Paso: Instalar Extensión MCP

### Opción 1: Cline (Recomendada) ⭐

1. **Abra VS Code Insiders**
2. **Vaya a Extensions** (Ctrl+Shift+X)
3. **Busque**: `Cline` o `saoudrizwan.claude-dev`
4. **Instale** la extensión Cline
5. **Reinicie** VS Code Insiders

### Opción 2: Copilot MCP

- Busque: `Copilot MCP` o `automatalabs.copilot-mcp`

## ⚙️ Configuración Post-Instalación

### Para Cline:

1. **Ejecute el configurador automático**:
   ```bash
   cd mcp-disk-assistant
   ./setup-cline.sh
   ```

2. **O configure manualmente** en VS Code settings.json:
   ```json
   {
     "cline.mcpServers": {
       "disk-assistant": {
         "command": "node",
         "args": ["/Volumes/BLACK2T/UserContent_macmini/Documents/Documents/asistente_disco_interno/mcp-disk-assistant/dist/index.js"],
         "cwd": "/Volumes/BLACK2T/UserContent_macmini/Documents/Documents/asistente_disco_interno"
       }
     }
   }
   ```

## 🎮 Cómo Usar el Asistente

### 1. Abrir el Chat

- **Cline**: Ctrl+Shift+P → "Cline: Open Chat"
- **Copilot MCP**: Panel de chat integrado

### 2. Comandos Disponibles

#### 📊 Análisis de Disco
```
Analiza el uso de disco en mi Mac y dame recomendaciones
```

#### 🔄 Migración de Datos
```
Migra Library/Caches de forma segura al disco externo
Migra mis datos de usuario al SSD externo
```

#### 🧹 Limpieza del Sistema
```
Limpia todos los caches del sistema
Limpia caches de navegadores y aplicaciones
```

#### 📱 Gestión de Aplicaciones
```
Mueve aplicaciones no críticas al disco externo
Restaura aplicaciones desde el disco externo
```

#### 📈 Monitoreo
```
Verifica el estado de los discos
Muestra el progreso de la migración actual
```

## 🛠️ Herramientas MCP Disponibles

| Herramienta | Función |
|-------------|---------|
| `analyze_disk_usage` | Análisis completo del uso de disco |
| `migrate_user_data` | Migración segura de datos de usuario |
| `cleanup_system` | Limpieza de caches y archivos temporales |
| `check_disk_status` | Estado de todos los discos montados |
| `get_migration_status` | Progreso de migraciones activas |
| `safe_move_applications` | Mover apps al disco externo |
| `restore_applications` | Restaurar apps desde disco externo |
| `get_recommendations` | Recomendaciones personalizadas |

## ✨ Ejemplos de Conversación

### Ejemplo 1: Análisis Inicial
```
Usuario: "Mi Mac se está quedando sin espacio. ¿Puedes ayudarme?"

Asistente MCP:
- Analiza automáticamente el uso de disco
- Identifica carpetas que consumen más espacio
- Recomienda qué migrar primero
- Muestra opciones seguras de limpieza
```

### Ejemplo 2: Migración Paso a Paso
```
Usuario: "Quiero migrar mi biblioteca de fotos al SSD externo"

Asistente MCP:
- Verifica el espacio disponible en el SSD
- Calcula el tiempo estimado de migración
- Ejecuta la migración con progreso en tiempo real
- Verifica la integridad después de la migración
```

## 🔧 Resolución de Problemas

### Si el servidor MCP no responde:

1. **Verificar estado**:
   ```bash
   cd mcp-disk-assistant
   ./test-installation.sh
   ```

2. **Reiniciar servidor**:
   ```bash
   ./start-mcp-server.sh
   ```

### Si la extensión no detecta el servidor:

1. **Verificar configuración** en VS Code settings.json
2. **Reiniciar** VS Code Insiders
3. **Comprobar logs** en Output → Cline/MCP

## 📞 Comandos de Prueba

Una vez configurado, pruebe estos comandos en el chat:

```
¿Qué herramientas de disco tienes disponibles?
```

```
Analiza mi disco y recomienda optimizaciones
```

```
Muéstrame el estado actual de mis discos
```

## 🎉 ¡Listo para Usar!

Su asistente de disco MCP está completamente configurado. Ahora puede:

- ✅ Gestionar discos conversacionalmente
- ✅ Migrar datos de forma segura
- ✅ Limpiar el sistema inteligentemente
- ✅ Monitorear espacio en tiempo real
- ✅ Recibir recomendaciones personalizadas

¡Disfrute de su nuevo asistente inteligente de gestión de disco!
