# TrustMonitor Documentation

## 📚 Available Documentation

### 🔒 Security Documentation
- **[Attack/Defense Demo](attack-defense-demo.md)** - Complete security demonstration with 5 attack scenarios

### 🔧 System Documentation
- **[HAL System](hal-system.md)** - Hardware abstraction layer overview
- **[Backup Management](backup-management.md)** - Backup system and recovery
- **[User Guide](user-guide.md)** - Complete user guide and testing
- **[Security Guide](security-guide.md)** - Security features and protection
- **[Security Hardening](security-hardening.md)** - Systemd security restrictions (v3.1.1+)

### 📝 Interface Documentation
- **[JSON Interface](json-interface.md)** - JSON output standardization (v3.1.2+)
- **[Error Handling](error-handling.md)** - Return code standardization (v3.1.3+)

### 📋 Reference Documentation
- **[Return Codes](../lib/return_codes.sh)** - Unified return code constants and error handling (see file header documentation)

### 🛠️ Tools Documentation
- **[Tools Guide](../tools/README.md)** - Complete tools documentation and usage examples

## 🎯 Quick Links

- **Quick Start**: See main [README.md](../README.md) for 5-minute setup
- **Security Demo**: [Attack/Defense Demo](attack-defense-demo.md) for comprehensive security testing
- **HAL System**: [HAL System](hal-system.md) for hardware abstraction overview
- **User Guide**: [User Guide](user-guide.md) for complete usage instructions
- **Security Guide**: [Security Guide](security-guide.md) for security features
- **Backup Management**: [Backup Management](backup-management.md) for backup system
- **Tools Guide**: [Tools Guide](../tools/README.md) for tools and utilities documentation

## 🛠️ Quick Tools Reference

### User Tools
```bash
# Quick system health check
bash tools/dev/quick_test.sh

# Complete system demonstration
bash tools/user/demo.sh

# Security testing
bash tools/security/attack.sh --list
bash tools/security/attack.sh malicious_code

# System recovery
bash tools/user/restore.sh --auto
```

### System Maintenance
```bash
# Update system integrity
bash tools/user/gen_hash.sh generate
bash tools/user/sign_manifest.sh sign

# Verify system integrity
bash scripts/integrity_check.sh
```

## 📚 Additional Resources

For more detailed information, see the main project documentation:
- **Main Project**: [../README.md](../README.md)
- **Tools Documentation**: [../tools/README.md](../tools/README.md)
