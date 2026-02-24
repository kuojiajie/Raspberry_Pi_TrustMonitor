# TrustMonitor Tools

This directory contains utility scripts organized by purpose.

## 📁 Directory Structure

### 👥 [user/](user/) - User-facing Tools
Tools intended for end users and system administrators:

- **demo.sh** - Complete attack/defense demonstration
- **gen_hash.sh** - Generate SHA256 hash manifest
- **gen_keypair.sh** - Generate RSA key pairs for digital signatures
- **sign_manifest.sh** - Create digital signatures for manifest files
- **restore.sh** - System recovery from backup

### 🧪 [dev/](dev/) - Development Testing Tools
Tools intended for developers to validate system functionality:

- **test_sigterm.sh** - Test SIGTERM graceful shutdown functionality
- **test_network_format.sh** - Test network monitor format consistency
- **crash_test.sh** - Test system crash recovery

### 🔒 [security/](security/) - Security Testing Tools
Tools for security validation and testing:

- **attack.sh** - Simulate security attacks for testing defenses

## 🚀 Quick Start

### For Users
```bash
# Run security demonstration
bash tools/user/demo.sh quick

# Generate system hashes
bash tools/user/gen_hash.sh generate

# Restore from backup
bash tools/user/restore.sh --auto
```

### For Developers
```bash
# Test v2.2.5 features
bash tools/dev/test_sigterm.sh
bash tools/dev/test_network_format.sh

# Validate system integrity
bash tools/dev/test_sigterm.sh && bash tools/dev/test_network_format.sh
```

### For Security Testing
```bash
# View available attack scenarios
bash tools/security/attack.sh --list

# Run specific attack simulation
bash tools/security/attack.sh malicious_code
```

## 📖 Documentation

- **[Testing Guide](../docs/testing.md)** - Comprehensive testing procedures
- **[Main README](../README.md)** - Full system documentation
- **[Security Demo](../docs/security/attack-defense-demo.md)** - Attack/defense scenarios

## ⚠️ Important Notes

- **User tools** are safe for production use
- **Development tools** are for testing and validation only
- **Security tools** should be used carefully in controlled environments
- Always backup system before running security tests

## 🔧 Permissions

All scripts have appropriate execute permissions:
```bash
# Make all tools executable
chmod +x tools/*/*.sh
```
