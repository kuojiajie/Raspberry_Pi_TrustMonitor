# Backup Management System

## 📋 Overview

TrustMonitor v2.2.4 introduces a unified backup management system that automatically handles backup file organization, cleanup, and retention policies. This system prevents disk space issues while maintaining important security and demo backups.

## 🏗️ Architecture

### Directory Structure
```
backup/
├── security/              # Security-related backups
│   ├── 20260225_003645/  # Timestamped complete backup
│   │   ├── manifest.sha256
│   │   ├── manifest.sha256.sig
│   │   └── keys/
│   └── *.backup_*        # Legacy backup files
└── attack_demo/           # Attack/defense demo backups
    ├── attack_demo_20260225_003357/
    └── attack_demo_20260225_003047/
```

### Backup Categories

#### 🔒 Security Backups (`backup/security/`)
- **Purpose**: Backup critical security files (manifests, signatures, keys)
- **Retention**: 7 days (configurable)
- **Limit**: Maximum 10 backup items (configurable)
- **Contents**: Complete security state including RSA keys

#### 🎭 Demo Backups (`backup/attack_demo/`)
- **Purpose**: Backup system state before attack demonstrations
- **Retention**: 3 days (configurable)  
- **Limit**: Maximum 5 backup directories (configurable)
- **Contents**: System files (no sensitive keys)

## 🛠️ Usage

### Basic Operations

#### Initialize Backup System
```bash
# Initialize and consolidate existing backups
bash lib/backup_manager.sh init
```

#### Manual Cleanup
```bash
# Clean old backup files
bash lib/backup_manager.sh cleanup
```

#### View Statistics
```bash
# Show backup usage and statistics
bash lib/backup_manager.sh stats
```

#### Create Manual Backup
```bash
# Create security backup
bash lib/backup_manager.sh create
```

#### Help Information
```bash
# Show all available commands
bash lib/backup_manager.sh help
```

### Plugin Integration

#### Automatic Cleanup
```bash
# Run as monitoring plugin
bash scripts/backup_cleanup.sh
```

#### Environment Configuration
```bash
# Configure retention settings
export SECURITY_BACKUP_RETENTION=7      # Days to keep security backups
export DEMO_BACKUP_RETENTION=3           # Days to keep demo backups
export MAX_SECURITY_BACKUPS=10            # Max security backup items
export MAX_DEMO_BACKUPS=5               # Max demo backup directories
export BACKUP_CLEANUP_DISK_THRESHOLD=90   # Disk usage % to force cleanup

bash scripts/backup_cleanup.sh
```

## ⚙️ Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SECURITY_BACKUP_RETENTION` | 7 | Days to keep security backups |
| `DEMO_BACKUP_RETENTION` | 3 | Days to keep demo backups |
| `MAX_SECURITY_BACKUPS` | 10 | Maximum security backup items |
| `MAX_DEMO_BACKUPS` | 5 | Maximum demo backup directories |
| `BACKUP_CLEANUP_DISK_THRESHOLD` | 90 | Disk usage % to trigger forced cleanup |

### Integration Points

#### Signature Tool Integration
```bash
# Automatic backup when creating new signatures
bash tools/sign_manifest.sh sign
# Creates backup in backup/security/YYYYMMDD_HHMMSS/
```

#### Attack Demo Integration  
```bash
# Automatic backup before attack demonstrations
bash tools/attack.sh malicious_code
# Creates backup in backup/attack_demo/YYYYMMDD_HHMMSS/
# Also creates security backup
```

## 📊 Monitoring

### Backup Statistics Output
```
=== Backup Statistics ===
Security backup directory: /path/to/backup/security
Demo backup directory: /path/to/backup/attack_demo

Security backups: 3 directories, 22 files, 128K
Demo backups: 0 directories, 4.0K

Retention settings:
  Security files: Keep 7 days, max 10 directories/files
  Demo backups: Keep 3 days, max 5 directories
```

### Cleanup Process
1. **Time-based cleanup**: Remove files older than retention period
2. **Count-based cleanup**: Remove oldest items if exceeding limits
3. **Disk space check**: Force cleanup if usage exceeds threshold
4. **Statistics reporting**: Show cleanup results and current state

## 🔧 Maintenance

### Regular Maintenance Tasks

#### Daily Cleanup (Recommended)
```bash
# Add to cron for daily execution
0 2 * * * /path/to/trustmonitor/scripts/backup_cleanup.sh
```

#### Weekly Status Check
```bash
# Check backup system status
bash lib/backup_manager.sh stats
```

#### Manual Cleanup (When Needed)
```bash
# Force cleanup with custom settings
MAX_SECURITY_BACKUPS=5 bash lib/backup_manager.sh cleanup
```

### Troubleshooting

#### Common Issues

**Issue**: Backup directory permissions
```bash
# Fix permissions
chmod 755 backup/
chmod 755 backup/security/
chmod 755 backup/attack_demo/
```

**Issue**: Disk space full
```bash
# Force cleanup with low threshold
BACKUP_CLEANUP_DISK_THRESHOLD=50 bash scripts/backup_cleanup.sh
```

**Issue**: Missing backup directories
```bash
# Reinitialize backup system
bash lib/backup_manager.sh init
```

## 🚀 Advanced Usage

### Custom Retention Policies
```bash
# Keep only 3 days of security backups
SECURITY_BACKUP_RETENTION=3 MAX_SECURITY_BACKUPS=5 bash lib/backup_manager.sh cleanup
```

### Backup Migration
```bash
# Move existing backups to new system
bash lib/backup_manager.sh init
# Automatically detects and consolidates old backup files
```

### Integration with Monitoring
```bash
# Add to health monitor plugins directory
# Plugin automatically runs during monitoring cycles
cp scripts/backup_cleanup.sh daemon/plugins/
```

## 📚 Related Documentation

- [Attack/Defense Demo](security/attack-defense-demo.md) - Security testing and backup creation
- [Return Code System](return-codes.md) - Error handling and status codes
- [Main README](../README.md) - System overview and setup

---

*Backup management system introduced in v2.2.4 for automated backup lifecycle management.*
