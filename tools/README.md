# TrustMonitor Tools

This directory contains tools for managing and testing the TrustMonitor system.

## 📁 Directory Structure

### `tools/user/` - User Tools
Essential tools for end users and system administrators:

- **`gen_hash.sh`** - Generate SHA256 hash manifest for integrity verification
- **`gen_keypair.sh`** - Generate RSA key pairs for digital signatures
- **`sign_manifest.sh`** - Sign the manifest file with private key
- **`restore.sh`** - Restore system from backup after attacks
- **`demo.sh`** - Complete system demonstration and testing

### `tools/security/` - Security Tools
- **`attack.sh`** - Attack/defense demonstration script for testing security mechanisms

### `tools/dev/` - Development Tools
- **`quick_test.sh`** - Basic system health check for quick verification

## 🚀 Quick Start

### For Users:
```bash
# Quick health check
bash tools/dev/quick_test.sh

# Complete system demo
bash tools/user/demo.sh
```

### For Security Testing:
```bash
# Run attack simulation
bash tools/security/attack.sh --list
bash tools/security/attack.sh malicious_code

# Restore after attack
bash tools/user/restore.sh --auto
```

### For System Maintenance:
```bash
# Generate new hash manifest
bash tools/user/gen_hash.sh generate

# Sign the manifest
bash tools/user/sign_manifest.sh sign
```

## 📋 Tool Descriptions

### User Tools (`tools/user/`)

#### `gen_hash.sh`
- **Purpose**: Generate SHA256 hashes for all project files
- **Usage**: `bash tools/user/gen_hash.sh generate`
- **Output**: `data/manifest.sha256`

#### `gen_keypair.sh`
- **Purpose**: Generate RSA public/private key pairs
- **Usage**: `bash tools/user/gen_keypair.sh`
- **Output**: `data/keys/public_key.pem`, `data/keys/private_key.pem`

#### `sign_manifest.sh`
- **Purpose**: Sign the hash manifest with private key
- **Usage**: `bash tools/user/sign_manifest.sh sign`
- **Output**: `data/manifest.sha256.sig`

#### `restore.sh`
- **Purpose**: Restore system from backup after security incidents
- **Usage**: `bash tools/user/restore.sh --auto`
- **Features**: Auto-restore, clean artifacts, regenerate security files

#### `demo.sh`
- **Purpose**: Complete system demonstration
- **Usage**: `bash tools/user/demo.sh`
- **Features**: Full system testing, security demonstrations

### Security Tools (`tools/security/`)

#### `attack.sh`
- **Purpose**: Simulate security attacks to test defenses
- **Attack Types**: malicious_code, config_tamper, core_module, signature_forgery
- **Usage**: `bash tools/security/attack.sh --list` to see available attacks

### Development Tools (`tools/dev/`)

#### `quick_test.sh`
- **Purpose**: Basic system health verification
- **Usage**: `bash tools/dev/quick_test.sh`
- **Checks**: Dependencies, configuration, security files, service status

## 🔧 Maintenance Notes

- **Security files** (manifest, signatures) should be regenerated after any system changes
- **Backups** are automatically created during security demonstrations
- **Service management** requires sudo privileges for restart operations
- **Hardware tests** require proper GPIO permissions and connected hardware

## 📚 Additional Information

For more detailed documentation, see:
- Main project README: `../README.md`
- Documentation: `../docs/`
- Configuration: `../config/health-monitor.env`
