# User Guide

## 🧪 TrustMonitor User Guide

This document describes how to use TrustMonitor for system monitoring and security testing.

## 🚀 Quick Start

### User Testing
```bash
# Quick system health check (recommended for users)
bash tools/dev/quick_test.sh

# Complete system demonstration
bash tools/user/demo.sh
```

### Security Testing
```bash
# View available attack scenarios
bash tools/security/attack.sh --list

# Run specific attack simulation
bash tools/security/attack.sh malicious_code

# Restore after attack
bash tools/user/restore.sh --auto
```

## 📚 Additional Information

For detailed security testing, see:
- **[Security Guide](security-guide.md)** - Complete security features
- **[Attack/Defense Demo](attack-defense-demo.md)** - Attack scenarios and demonstrations
- **[Backup Management](backup-management.md)** - Backup and recovery procedures

### System Maintenance Testing
```bash
# Update system integrity after changes
bash tools/user/gen_hash.sh generate
bash tools/user/sign_manifest.sh sign

# Verify system integrity
bash scripts/integrity_check.sh
```

## 📋 Available Testing Tools

### 🎯 System Integration Testing
The TrustMonitor system has been validated through comprehensive testing:

#### Phase 1: Hardware Enablement Testing
- **LED Hardware Testing** - RGB LED functionality with correct pin mapping (27/22/5)
- **DHT11 Sensor Testing** - Temperature and humidity sensor integration
- **Basic Monitoring Testing** - CPU, memory, disk, network, and temperature monitoring

#### Phase 2: ROT Security Testing  
- **Integrity Verification Testing** - SHA256 hash verification for 53 system files
- **Digital Signature Testing** - RSA signature verification and validation
- **Secure Boot Sequence Testing** - Complete boot sequence with integrity checks
- **Attack Defense Testing** - Security attack simulation and automatic recovery

#### Phase 3: BMC Functionality Testing
- **Watchdog System Testing** - Service monitoring and automatic recovery
- **SEL Event Logging Testing** - System event logging and management
- **Service Integration Testing** - systemd service management and automatic startup

### 🛠️ Quick Testing Commands

For day-to-day validation, use these simplified commands:

```bash
# Quick system health check
bash tools/dev/quick_test.sh

# Complete system demonstration  
bash tools/user/demo.sh

# Security attack simulation
bash tools/security/attack.sh --list
bash tools/security/attack.sh malicious_code
```

## 🔧 System Maintenance

### After System Changes
```bash
# Regenerate security files after legitimate changes
bash tools/user/gen_hash.sh generate
bash tools/user/sign_manifest.sh sign

# Verify system integrity
bash scripts/integrity_check.sh
```

### After Security Incidents
```bash
# Automatic recovery from backup
bash tools/user/restore.sh --auto

# Or regenerate security files only
bash tools/user/restore.sh --regen
```

## 📚 Additional Information

For complete tools documentation, see:
- **[Tools Guide](../tools/README.md)** - Complete tools documentation
- **[Main README](../README.md)** - Project overview and quick start

---

*This testing guide reflects the simplified tools structure in v2.2.7+*
