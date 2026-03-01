# Backup Management

## 📋 Overview

TrustMonitor automatically creates backups to protect your system and provide recovery options.

## 🗂️ Backup Types

### Security Backups
- **Purpose**: Protect system integrity files
- **When Created**: After security changes or attacks
- **Location**: `backup/security/`
- **Contents**: Manifest files, signatures, keys

### Demo Backups  
- **Purpose**: Save system state during attack demos
- **When Created**: During security demonstrations
- **Location**: `backup/attack_demo/`
- **Contents**: Modified files for recovery

## 🛠️ Backup Commands

### Automatic Recovery
```bash
# Restore from latest backup
bash tools/user/restore.sh --auto

# Regenerate security files only
bash tools/user/restore.sh --regen
```

### Manual Recovery
```bash
# List available backups
bash tools/user/restore.sh --list

# Restore from specific backup
bash tools/user/restore.sh --backup 20260301_233015
```

## 📊 Backup Retention

- **Security Backups**: Keep 7 days, max 10 directories
- **Demo Backups**: Keep 3 days, max 5 directories
- **Automatic Cleanup**: Old backups removed automatically

## 🔧 Configuration

Backup settings in `config/health-monitor.env`:

```bash
# Security backup retention
BACKUP_RETENTION_DAYS=7
BACKUP_MAX_DIRS=10

# Demo backup retention  
DEMO_BACKUP_RETENTION_DAYS=3
DEMO_BACKUP_MAX_DIRS=5
```

## 🚨 Important Notes

- **Security Backups** contain sensitive keys - keep them secure
- **Demo Backups** are for testing only
- **Automatic Cleanup** prevents disk space issues
- **Manual Backup** can be done by copying `data/` directory

## 📚 Additional Information

For detailed security demonstrations, see:
- **[Attack/Defense Demo](attack-defense-demo.md)** - Complete attack scenarios
- **[Security Guide](security-guide.md)** - Security features and protection

---

*Backups protect your system and provide easy recovery options.*
