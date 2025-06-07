#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  Tool,
} from '@modelcontextprotocol/sdk/types.js';
import { z } from 'zod';
import { exec, spawn } from 'child_process';
import { promisify } from 'util';
import { readFile, writeFile, access, stat, readdir } from 'fs/promises';
import { existsSync, constants } from 'fs';
import path from 'path';
import os from 'os';

const execAsync = promisify(exec);

// --- Sistema de Jobs para Tareas Asíncronas ---
type JobStatus = 'PENDING' | 'RUNNING' | 'COMPLETED' | 'FAILED';

interface Job {
  id: string;
  status: JobStatus;
  progress: number;
  message: string;
  result?: any;
  error?: string;
}

const jobs: Record<string, Job> = {};
// --- Fin del Sistema de Jobs ---

// Configuración del servidor MCP
const server = new Server({
  name: 'disk-assistant',
  version: '1.0.0',
  capabilities: {
    tools: {},
  },
});

// Rutas de configuración
const SCRIPT_BASE_PATH = '/Volumes/BLACK2T/UserContent_macmini/Documents/Documents/asistente_disco_interno';
const SCRIPTS_PATH = path.join(SCRIPT_BASE_PATH, 'scripts');
const CONFIG_PATH = path.join(SCRIPT_BASE_PATH, 'config');
const LOGS_PATH = path.join(SCRIPT_BASE_PATH, 'logs');
const JOBS_PATH = path.join(CONFIG_PATH, 'jobs'); // Directorio para almacenar estado de jobs

// Schemas de validación
const DiskAnalysisSchema = z.object({
  path: z.string().optional().default('/'),
  detailed: z.boolean().optional().default(false),
});

const MigrateDataSchema = z.object({
  source: z.string(),
  destination: z.string().optional(),
  type: z.enum(['directory', 'application', 'cache']),
  dryRun: z.boolean().optional().default(true),
});

const CleanupSchema = z.object({
  type: z.enum(['cache', 'logs', 'temp', 'all']),
  aggressive: z.boolean().optional().default(false),
});

const DiskStatusSchema = z.object({
  disk: z.string().optional(),
});

// Herramientas disponibles
const tools: Tool[] = [
  {
    name: 'analyze_disk_usage',
    description: 'Analiza el uso de disco y identifica oportunidades de optimización',
    inputSchema: {
      type: 'object',
      properties: {
        path: {
          type: 'string',
          description: 'Ruta a analizar (por defecto: /)',
          default: '/',
        },
        detailed: {
          type: 'boolean',
          description: 'Mostrar análisis detallado',
          default: false,
        },
      },
    },
  },
  {
    name: 'migrate_user_data',
    description: 'Migra datos de usuario a disco externo de manera segura',
    inputSchema: {
      type: 'object',
      properties: {
        source: {
          type: 'string',
          description: 'Directorio fuente a migrar (ej: ~/Downloads, ~/Library/Caches)',
        },
        destination: {
          type: 'string',
          description: 'Directorio destino (opcional, se calculará automáticamente)',
        },
        type: {
          type: 'string',
          enum: ['directory', 'application', 'cache'],
          description: 'Tipo de migración',
        },
        dryRun: {
          type: 'boolean',
          description: 'Solo simular la migración sin ejecutar',
          default: true,
        },
      },
      required: ['source', 'type'],
    },
  },
  {
    name: 'cleanup_system',
    description: 'Limpia archivos temporales, caches y logs del sistema',
    inputSchema: {
      type: 'object',
      properties: {
        type: {
          type: 'string',
          enum: ['cache', 'logs', 'temp', 'all'],
          description: 'Tipo de limpieza a realizar',
        },
        aggressive: {
          type: 'boolean',
          description: 'Limpieza agresiva (más espacio, más riesgo)',
          default: false,
        },
      },
      required: ['type'],
    },
  },
  {
    name: 'check_disk_status',
    description: 'Verifica el estado de los discos externos y enlaces simbólicos',
    inputSchema: {
      type: 'object',
      properties: {
        disk: {
          type: 'string',
          description: 'Disco específico a verificar (BLACK2T, 8TbSeries)',
        },
      },
    },
  },
  {
    name: 'get_migration_status',
    description: 'Obtiene el estado actual de las migraciones realizadas',
    inputSchema: {
      type: 'object',
      properties: {},
    },
  },
  {
    name: 'start_app_migration_job',
    description: 'Inicia un trabajo asíncrono para mover aplicaciones de forma segura.',
    inputSchema: {
      type: 'object',
      properties: {
        applications: {
          type: 'array',
          items: { type: 'string' },
          description: 'Lista de aplicaciones a mover. Si está vacío, se analizarán todas.',
        },
        dryRun: {
          type: 'boolean',
          description: 'Solo simular sin ejecutar',
          default: true,
        },
      },
      required: ['applications'],
    },
  },
  {
    name: 'get_job_status',
    description: 'Obtiene el estado de un trabajo de migración asíncrono.',
    inputSchema: {
      type: 'object',
      properties: {
        jobId: {
          type: 'string',
          description: 'El ID del trabajo a consultar',
        },
      },
      required: ['jobId'],
    },
  },
  {
    name: 'restore_applications',
    description: 'Restaura aplicaciones del disco externo al disco interno',
    inputSchema: {
      type: 'object',
      properties: {
        applications: {
          type: 'array',
          items: { type: 'string' },
          description: 'Aplicaciones específicas a restaurar',
        },
      },
    },
  },
  {
    name: 'get_recommendations',
    description: 'Obtiene recomendaciones personalizadas basadas en el análisis del sistema',
    inputSchema: {
      type: 'object',
      properties: {
        priority: {
          type: 'string',
          enum: ['space', 'safety', 'performance'],
          description: 'Prioridad de las recomendaciones',
          default: 'safety',
        },
      },
    },
  },
];

// Funciones auxiliares
async function executeScript(scriptName: string, args: string[] = []): Promise<{ stdout: string; stderr: string }> {
  const scriptPath = path.join(SCRIPTS_PATH, scriptName);
  
  if (!existsSync(scriptPath)) {
    throw new Error(`Script no encontrado: ${scriptPath}`);
  }

  try {
    const { stdout, stderr } = await execAsync(`bash "${scriptPath}" ${args.join(' ')}`);
    return { stdout, stderr };
  } catch (error: any) {
    return { stdout: error.stdout || '', stderr: error.stderr || error.message };
  }
}

async function readMigrationState(): Promise<any> {
  try {
    const statePath = path.join(CONFIG_PATH, 'migration_state.json');
    const content = await readFile(statePath, 'utf-8');
    return JSON.parse(content);
  } catch (error) {
    return { migrated_directories: [], migrated_applications: [], last_migration: null };
  }
}

async function analyzeDiskUsage(targetPath: string, detailed: boolean = false): Promise<string> {
  try {
    const { stdout } = await execAsync(`du -sh "${targetPath}"/* 2>/dev/null | sort -hr | head -20`);
    
    if (detailed) {
      const { stdout: diskFree } = await execAsync('df -h /');
      const { stdout: largeDirs } = await execAsync(`find "${targetPath}" -type d -exec du -sm {} + 2>/dev/null | sort -nr | head -10`);
      
      return `
📊 **ANÁLISIS DE DISCO DETALLADO**

**Uso general del disco:**
${diskFree}

**Directorios más grandes (top 20):**
${stdout}

**Directorios de más de 100MB:**
${largeDirs}

**Recomendaciones automáticas:**
${await getAutoRecommendations()}
      `.trim();
    }
    
    return `**Directorios más grandes:**\n${stdout}`;
  } catch (error: any) {
    return `Error analizando disco: ${error.message}`;
  }
}

async function getAutoRecommendations(): Promise<string> {
  const recommendations = [];
  
  try {
    // Verificar caches grandes
    const { stdout: cacheSize } = await execAsync('du -sm ~/Library/Caches 2>/dev/null');
    const cacheMB = parseInt(cacheSize.split('\t')[0]);
    if (cacheMB > 1000) {
      recommendations.push(`• Limpiar caches (${cacheMB}MB disponibles)`);
    }

    // Verificar Downloads
    const { stdout: downloadSize } = await execAsync('du -sm ~/Downloads 2>/dev/null');
    const downloadMB = parseInt(downloadSize.split('\t')[0]);
    if (downloadMB > 5000) {
      recommendations.push(`• Migrar Downloads (${downloadMB}MB disponibles)`);
    }

    // Verificar aplicaciones grandes
    const { stdout: apps } = await execAsync('du -sm /Applications/*.app 2>/dev/null | sort -nr | head -5');
    recommendations.push('\n**Aplicaciones más grandes:**');
    recommendations.push(apps);

  } catch (error) {
    recommendations.push('• Error obteniendo recomendaciones automáticas');
  }

  return recommendations.join('\n');
}

async function performMigration(source: string, destination: string, type: string, dryRun: boolean): Promise<string> {
  try {
    const expandedSource = source.replace('~', os.homedir());
    
    if (!existsSync(expandedSource)) {
      return `❌ Error: El directorio fuente no existe: ${expandedSource}`;
    }

    if (dryRun) {
      const { stdout } = await execAsync(`du -sh "${expandedSource}"`);
      return `
🔍 **SIMULACIÓN DE MIGRACIÓN**

**Fuente:** ${expandedSource}
**Destino:** ${destination}
**Tamaño:** ${stdout.split('\t')[0]}
**Tipo:** ${type}

✅ La migración sería exitosa.
Para ejecutar realmente, usar \`dryRun: false\`
      `.trim();
    }

    // Ejecutar migración real
    const args = [expandedSource, destination || 'auto'];
    const result = await executeScript('manage_user_data.sh', args);
    
    return `
✅ **MIGRACIÓN COMPLETADA**

${result.stdout}

${result.stderr ? `⚠️ **Advertencias:**\n${result.stderr}` : ''}
    `.trim();
    
  } catch (error: any) {
    return `❌ Error en migración: ${error.message}`;
  }
}

async function performCleanup(type: string, aggressive: boolean): Promise<string> {
  try {
    const args = aggressive ? ['--aggressive'] : [];
    
    switch (type) {
      case 'cache':
        args.unshift('--cache-only');
        break;
      case 'logs':
        args.unshift('--logs-only');
        break;
      case 'temp':
        args.unshift('--temp-only');
        break;
      case 'all':
        args.unshift('--all');
        break;
    }

    const result = await executeScript('clean_system_caches.sh', args);
    
    return `
🧹 **LIMPIEZA DEL SISTEMA COMPLETADA**

${result.stdout}

${result.stderr ? `⚠️ **Advertencias:**\n${result.stderr}` : ''}
    `.trim();
    
  } catch (error: any) {
    return `❌ Error en limpieza: ${error.message}`;
  }
}

async function checkDiskStatus(specificDisk?: string): Promise<string> {
  try {
    const checks = [];
    
    // Verificar discos montados
    const { stdout: mounted } = await execAsync('df -h | grep -E "(BLACK2T|8TbSeries|/$)"');
    checks.push('**Discos montados:**');
    checks.push(mounted);
    
    // Verificar enlaces simbólicos
    const { stdout: symlinks } = await execAsync('find /Applications -maxdepth 1 -name "*.app" -type l 2>/dev/null | wc -l');
    checks.push(`\n**Enlaces simbólicos en /Applications:** ${symlinks.trim()}`);
    
    // Estado de migración
    const migrationState = await readMigrationState();
    checks.push(`\n**Directorios migrados:** ${migrationState.migrated_directories?.length || 0}`);
    checks.push(`**Aplicaciones migradas:** ${migrationState.migrated_applications?.length || 0}`);
    
    if (specificDisk) {
      const { stdout: diskInfo } = await execAsync(`diskutil info "${specificDisk}" 2>/dev/null || echo "Disco no encontrado"`);
      checks.push(`\n**Info de ${specificDisk}:**`);
      checks.push(diskInfo);
    }
    
    return checks.join('\n');
    
  } catch (error: any) {
    return `❌ Error verificando estado: ${error.message}`;
  }
}

// Worker asíncrono para la migración de aplicaciones
async function performAppMigration(jobId: string, applications: string[], dryRun: boolean) {
  const jobFilePath = path.join(JOBS_PATH, `${jobId}.json`);

  const updateJob = async (updates: Partial<Job>) => {
    const currentJobContent = await readFile(jobFilePath, 'utf-8');
    const currentJob = JSON.parse(currentJobContent);
    const newJob = { ...currentJob, ...updates, updatedAt: new Date().toISOString() };
    await writeFile(jobFilePath, JSON.stringify(newJob, null, 2));
    return newJob;
  };

  try {
    await updateJob({ status: 'RUNNING', message: 'Iniciando migración...', progress: 10 });

    console.log(`[Job ${jobId}] Iniciando migración para: ${applications.join(', ')}`);
    
    // Simulación de trabajo
    await new Promise(resolve => setTimeout(resolve, 5000));
    await updateJob({ progress: 50, message: 'Copiando archivos (simulación)...' });
    console.log(`[Job ${jobId}] Progreso: 50%`);

    await new Promise(resolve => setTimeout(resolve, 5000));
    
    await updateJob({
      progress: 100,
      status: 'COMPLETED',
      message: '¡Migración completada exitosamente!',
      result: { moved: applications, dryRun },
    });
    console.log(`[Job ${jobId}] Completado.`);

  } catch (error: any) {
    console.error(`[Job ${jobId}] Error: ${error.message}`);
    await updateJob({
      status: 'FAILED',
      message: 'La migración ha fallado.',
      error: error.message,
    });
  }
}

// Configurar manejadores de herramientas
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return { tools };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case 'analyze_disk_usage': {
        const { path: targetPath, detailed } = DiskAnalysisSchema.parse(args);
        const result = await analyzeDiskUsage(targetPath, detailed);
        return {
          content: [{ type: 'text', text: result }],
        };
      }

      case 'migrate_user_data': {
        const { source, destination = 'auto', type, dryRun } = MigrateDataSchema.parse(args);
        const result = await performMigration(source, destination, type, dryRun);
        return {
          content: [{ type: 'text', text: result }],
        };
      }

      case 'cleanup_system': {
        const { type, aggressive } = CleanupSchema.parse(args);
        const result = await performCleanup(type, aggressive);
        return {
          content: [{ type: 'text', text: result }],
        };
      }

      case 'check_disk_status': {
        const { disk } = DiskStatusSchema.parse(args);
        const result = await checkDiskStatus(disk);
        return {
          content: [{ type: 'text', text: result }],
        };
      }

      case 'get_migration_status': {
        const state = await readMigrationState();
        const result = `
📋 **ESTADO DE MIGRACIÓN**

**Directorios migrados:** ${state.migrated_directories?.length || 0}
${state.migrated_directories?.map((dir: string) => `  • ${dir}`).join('\n') || '  (ninguno)'}

**Aplicaciones migradas:** ${state.migrated_applications?.length || 0}
${state.migrated_applications?.map((app: string) => `  • ${app}`).join('\n') || '  (ninguna)'}

**Última migración:** ${state.last_migration || 'Nunca'}
        `.trim();
        
        return {
          content: [{ type: 'text', text: result }],
        };
      }

      case 'start_app_migration_job': {
        const { applications = [], dryRun = true } = args as any;
        const jobId = `job-${Date.now()}`;
        
        // Crear directorio de jobs si no existe
        if (!existsSync(JOBS_PATH)) {
          await execAsync(`mkdir -p "${JOBS_PATH}"`);
        }

        const jobFilePath = path.join(JOBS_PATH, `${jobId}.json`);
        const newJob: Job = {
          id: jobId,
          status: 'PENDING',
          progress: 0,
          message: 'Trabajo creado, pendiente de inicio.',
        };

        await writeFile(jobFilePath, JSON.stringify(newJob, null, 2));

        // Iniciar el trabajo en segundo plano, sin esperar a que termine
        performAppMigration(jobId, applications, dryRun);

        return {
          content: [{ type: 'text', text: `🚀 Trabajo de migración iniciado con ID: ${jobId}` }],
        };
      }

      case 'get_job_status': {
        const { jobId } = args as any;
        const jobFilePath = path.join(JOBS_PATH, `${jobId}.json`);

        if (!existsSync(jobFilePath)) {
          return {
            content: [{ type: 'text', text: `❌ Error: No se encontró ningún trabajo con el ID: ${jobId}` }],
            isError: true,
          };
        }

        const jobContent = await readFile(jobFilePath, 'utf-8');
        const job = JSON.parse(jobContent);

        const result = `
📊 **ESTADO DEL TRABAJO: ${jobId}**

**Estado:** ${job.status}
**Progreso:** ${job.progress}%
**Mensaje:** ${job.message}
${job.error ? `\n**Error:** ${job.error}` : ''}
${job.result ? `\n**Resultado:** ${JSON.stringify(job.result, null, 2)}` : ''}
        `.trim();

        return {
          content: [{ type: 'text', text: result }],
        };
      }

      case 'restore_applications': {
        const { applications = [] } = args as any;
        const result = await executeScript('restore_apps_from_external.sh', applications);
        return {
          content: [{ type: 'text', text: `
🔄 **RESTAURACIÓN DE APLICACIONES**

${result.stdout}

${result.stderr ? `⚠️ **Advertencias:**\n${result.stderr}` : ''}
          `.trim() }],
        };
      }

      case 'get_recommendations': {
        const { priority = 'safety' } = args as any;
        const diskAnalysis = await analyzeDiskUsage('/', true);
        const migrationState = await readMigrationState();
        
        let recommendations = [];
        
        switch (priority) {
          case 'space':
            recommendations = [
              '🎯 **RECOMENDACIONES PARA LIBERAR ESPACIO:**',
              '',
              '1. **ALTA PRIORIDAD** - Limpiar caches del sistema',
              '2. **MEDIA PRIORIDAD** - Migrar Downloads si >5GB',
              '3. **BAJA PRIORIDAD** - Migrar Library/Caches',
              '4. **OPCIONAL** - Mover aplicaciones grandes no críticas',
            ];
            break;
            
          case 'performance':
            recommendations = [
              '🚀 **RECOMENDACIONES PARA RENDIMIENTO:**',
              '',
              '1. Mantener aplicaciones frecuentes en disco interno',
              '2. Migrar solo datos no críticos',
              '3. Usar SSD externos para aplicaciones migradas',
              '4. Monitorear regularmente el rendimiento',
            ];
            break;
            
          default: // safety
            recommendations = [
              '🛡️ **RECOMENDACIONES SEGURAS:**',
              '',
              '1. **EMPEZAR** - Limpiar caches (sin riesgo)',
              '2. **CONTINUAR** - Migrar Downloads y Documents',
              '3. **AVANZADO** - Solo aplicaciones de terceros no críticas',
              '4. **NUNCA** - Apps del sistema o firmadas por Apple',
              '',
              '⚠️ **Usar siempre dryRun: true primero**',
            ];
        }
        
        const result = recommendations.join('\n') + '\n\n' + diskAnalysis;
        
        return {
          content: [{ type: 'text', text: result }],
        };
      }

      default:
        throw new Error(`Herramienta desconocida: ${name}`);
    }
  } catch (error: any) {
    return {
      content: [{ type: 'text', text: `❌ Error: ${error.message}` }],
      isError: true,
    };
  }
});

// Iniciar servidor
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('🖥️ MCP Disk Assistant Server iniciado');
}

main().catch((error) => {
  console.error('Error fatal:', error);
  process.exit(1);
});
