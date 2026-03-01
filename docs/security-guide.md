# Security Guide

## 🛡️ TrustMonitor Security Features

TrustMonitor provides comprehensive security protection through integrity verification, digital signatures, and attack detection.

## 🔒 Security Components

### Integrity Verification
- **SHA256 Hashes**: All system files are hashed
- **Automatic Detection**: Changes are immediately detected
- **Tamper Protection**: Modified files are blocked

### Digital Signatures
- **RSA Signatures**: Manifest files are cryptographically signed
- **Key Management**: Public/private key pairs for verification
- **Authenticity**: Ensures files haven't been tampered with

### Attack Detection
- **Real-time Monitoring**: Continuous security checks
- **Automatic Response**: System halts if compromised
- **Recovery Options**: One-click system restoration

## 🚀 Quick Security Setup

### First Time Setup
```bash
# Generate security keys (one-time)
bash tools/user/gen_keypair.sh

# Create initial security files
bash tools/user/gen_hash.sh generate
bash tools/user/sign_manifest.sh sign
```

### Daily Security Checks
```bash
# Verify system integrity
bash scripts/integrity_check.sh

# Quick security check
bash tools/dev/quick_test.sh
```

## 🎯 Security Testing

### Attack Simulation
```bash
# See available attack scenarios
bash tools/security/attack.sh --list

# Run specific attack
bash tools/security/attack.sh malicious_code

# System will detect and halt
```

### Recovery After Attack
```bash
# Automatic recovery
bash tools/user/restore.sh --auto

# Verify recovery
bash scripts/integrity_check.sh
```

## � Additional Information

For detailed attack scenarios, see:
- **[Attack/Defense Demo](attack-defense-demo.md)** - Complete attack scenarios and demonstrations
- **[Backup Management](backup-management.md)** - Backup and recovery procedures

## �📁 Security Files

### Important Files
- `data/manifest.sha256` - System file hashes
- `data/manifest.sha256.sig` - Digital signature
- `data/keys/public_key.pem` - Public verification key
- `data/keys/private_key.pem` - Private signing key (PROTECT!)

### Backup Locations
- `backup/security/` - Security backups
- `backup/attack_demo/` - Attack demo backups

## 🔧 Security Configuration

### Environment Variables
```bash
# Security settings in config/health-monitor.env
INTEGRITY_CHECK_INTERVAL=3600      # Check frequency (seconds)
BACKUP_RETENTION_DAYS=7           # Backup retention
```

### Key Protection
- **Private Key**: Never share or expose
- **Backups**: Store securely
- **Permissions**: Restrict access to keys directory

## 🚨 Security Incidents

### If System is Compromised
1. **System Halts**: TrustMonitor stops automatically
2. **Alerts Logged**: Security events recorded
3. **Recovery Available**: Use restore tools

### Recovery Steps
```bash
# Check system status
bash tools/user/restore.sh --status

# Automatic recovery
bash tools/user/restore.sh --auto

# Verify recovery
bash scripts/integrity_check.sh
```

## 📋 Security Best Practices

### Regular Maintenance
- **Weekly**: Run integrity checks
- **Monthly**: Review security logs
- **Quarterly**: Update security keys

### Key Management
- **Backup Keys**: Store securely offline
- **Rotate Keys**: Update periodically
- **Limit Access**: Only authorized users

### Monitoring
- **Logs**: Review security events
- **Alerts**: Monitor system integrity
- **Backups**: Verify backup integrity

## 🔍 Security Logging

### SEL Events
```bash
# View security events
bash scripts/sel_logger.sh query

# Generate security report
bash scripts/sel_logger.sh report
```

### System Logs
```bash
# Security-related logs
sudo journalctl -u health-monitor.service | grep -i security
sudo journalctl -u health-monitor.service | grep -i integrity
```

## 🛡️ Advanced Security

### Custom Attack Scenarios
```bash
# Multiple attacks
bash tools/security/attack.sh multiple

# Configuration tampering
bash tools/security/attack.sh config_tamper

# Signature forgery
bash tools/security/attack.sh signature_forgery
```

### Security Hardening
```bash
# Check system security
bash tools/user/restore.sh --status

# Update security files
bash tools/user/restore.sh --regen
```

---

*TrustMonitor security protects your system automatically while providing transparency and control.*
