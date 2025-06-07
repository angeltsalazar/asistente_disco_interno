#!/bin/bash
# Script para reparar archivo JSON corrupto

CONFIG_FILE="config/migration_state.json"

echo "🔧 Reparando archivo JSON corrupto..."

# Crear un nuevo archivo JSON limpio
cat > "$CONFIG_FILE" << 'EOF'
{
  "version": "1.0",
  "machine": "Angels-Mac-mini",
  "last_updated": "2025-06-06T15:15:00.000000",
  "external_disk": "/Volumes/BLACK2T",
  "migration_base": "/Volumes/BLACK2T/UserContent_macmini",
  "directories": {
    "Documents": {
      "status": "migrated",
      "original_path": "/Users/angelsalazar/Documents",
      "target_path": "/Volumes/BLACK2T/UserContent_macmini/Documents",
      "backup_path": "/Volumes/BLACK2T/UserContent_macmini/backups/Documents_2025-06-06",
      "last_migration": "2025-06-06T10:13:38.829116",
      "size_before": "1GB",
      "size_after": "1GB",
      "checksum": "",
      "auto_update": true
    },
    "Downloads": {
      "status": "migrated",
      "original_path": "/Users/angelsalazar/Downloads",
      "target_path": "/Volumes/BLACK2T/UserContent_macmini/Downloads",
      "backup_path": "/Volumes/BLACK2T/UserContent_macmini/backups/Downloads_2025-06-06",
      "last_migration": "2025-06-06T15:10:05.000000",
      "size_before": "1.9G",
      "size_after": "1.9G",
      "checksum": "",
      "auto_update": true
    },
    "Pictures": {
      "status": "not_migrated",
      "original_path": "/Users/angelsalazar/Pictures",
      "target_path": "",
      "backup_path": "",
      "last_migration": "",
      "size_before": "",
      "size_after": "",
      "checksum": "",
      "auto_update": true
    },
    "Movies": {
      "status": "not_migrated",
      "original_path": "/Users/angelsalazar/Movies",
      "target_path": "",
      "backup_path": "",
      "last_migration": "",
      "size_before": "",
      "size_after": "",
      "checksum": "",
      "auto_update": false
    },
    "Music": {
      "status": "not_migrated",
      "original_path": "/Users/angelsalazar/Music",
      "target_path": "",
      "backup_path": "",
      "last_migration": "",
      "size_before": "",
      "size_after": "",
      "checksum": "",
      "auto_update": false
    },
    "Desktop": {
      "status": "not_migrated",
      "original_path": "/Users/angelsalazar/Desktop",
      "target_path": "",
      "backup_path": "",
      "last_migration": "",
      "size_before": "",
      "size_after": "",
      "checksum": "",
      "auto_update": true
    },
    "Library": {
      "status": "not_migrated",
      "original_path": "/Users/angelsalazar/Library",
      "target_path": "",
      "backup_path": "",
      "last_migration": "",
      "size_before": "",
      "size_after": "",
      "checksum": "",
      "auto_update": false
    },
    "Applications": {
      "status": "not_migrated",
      "original_path": "/Applications",
      "target_path": "",
      "backup_path": "",
      "last_migration": "",
      "size_before": "",
      "size_after": "",
      "checksum": "",
      "auto_update": false
    },
    "ApplicationSupport": {
      "status": "not_migrated",
      "original_path": "/Users/angelsalazar/Library/Application Support",
      "target_path": "",
      "backup_path": "",
      "last_migration": "",
      "size_before": "",
      "size_after": "",
      "checksum": "",
      "auto_update": false
    }
  }
}
EOF

echo "✅ Archivo JSON reparado exitosamente"

# Validar JSON
if python3 -c "import json; json.load(open('$CONFIG_FILE'))" 2>/dev/null; then
    echo "✅ JSON válido"
else
    echo "❌ JSON todavía inválido"
fi
