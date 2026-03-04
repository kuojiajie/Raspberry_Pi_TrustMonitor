# Developer Guide

## 🛠 Developer Guide

This document provides technical details and tool usage instructions for developers.

## 🔧 Tools Overview

TrustMonitor provides a complete toolset, divided into three main categories:

### `tools/user/` - User Tools
Basic system management and security tools:
- **`gen_hash.sh`** - Generate SHA256 hash list for integrity verification
- **`gen_keypair.sh`** - Generate RSA key pairs for digital signatures
- **`sign_manifest.sh`** - Sign hash list using private key
- **`restore.sh`** - Restore system from backup after security events
- **`demo.sh`** - Complete system demonstration and testing

### `tools/demo/security/` - Security Tools
- **`attack.sh`** - Attack/defense demonstration script for testing security mechanisms
- **Attack Types**: malicious_code, config_tamper, core_module, signature_forgery
- **Usage**: `bash tools/demo/security/attack.sh --list` to view available attacks

### `tools/dev/` - Development Tools
- **`quick_test.sh`** - Basic system health check for quick verification

## 🔧 Configuration Validation System

TrustMonitor includes a comprehensive configuration validation system.

### Usage
```bash
# Validate default configuration file
bash tools/config/validate_config.sh

# Validate specific configuration file
bash tools/config/validate_config.sh /path/to/custom.env

# Validate specific sections
bash tools/config/validate_config.sh --system-only
bash tools/config/validate_config.sh --paths-only
bash tools/config/validate_config.sh --logging-only
```

### Validation Options
- `--dht11-only` - Validate DHT11 sensor configuration only
- `--temp-only` - Validate temperature thresholds only
- `--led-only` - Validate LED pin configuration only
- `--network-only` - Validate network configuration only
- `--security-only` - Validate security configuration only
- `--system-only` - Validate system thresholds only
- `--paths-only` - Validate path configuration only
- `--logging-only` - Validate logging configuration only
- `--watchdog-only` - Validate watchdog configuration only
- `--sel-only` - Validate SEL configuration only

## 🧪 Testing Framework

TrustMonitor provides comprehensive test coverage to ensure system reliability.

### Running Tests
```bash
# Run complete test suite
bash tests/test_runner.sh

# Run specific test types
bash tests/test_runner.sh unit
bash tests/test_runner.sh integration
bash tests/test_runner.sh security
```

### Test Coverage Scope
- **Unit Tests**: Component functionality testing
- **Integration Tests**: Component collaboration testing
- **Security Tests**: Security feature testing
- **Hardware Tests**: Hardware integration testing

### Troubleshooting
```bash
# Check system integrity
bash scripts/integrity_check.sh

# If integrity check fails, update manifest
bash tools/user/gen_hash.sh generate
bash tools/user/sign_manifest.sh sign

# Re-run tests
bash tests/test_runner.sh
```

## 📊 Return Code System

Uses standardized return codes:
```bash
RC_OK=0              # Operation successful
RC_WARN=1            # Warning condition
RC_ERROR=2           # Error condition
RC_INTEGRITY_FAILED=4    # Integrity verification failed
RC_SIGNATURE_FAILED=5    # Signature verification failed
```

## 🔌 HAL System

Hardware abstraction layer provides unified hardware access interface.

### Key Files
- `hardware/hal_core.py` - Core HAL system
- `hardware/hal_interface.py` - Main hardware interface
- `hardware/hal_sensors.py` - Sensor management
- `hardware/hal_indicators.py` - LED control

### Configuration
```bash
USE_HAL=true                         # Enable HAL (default)
DHT11_PIN=17                         # Sensor pin (GPIO 17)
LED_RED_PIN=27                        # LED pins
LED_GREEN_PIN=22
LED_BLUE_PIN=5
```

## 🚀 Quick Tool Reference

### User Tools
```bash
# Quick system health check
bash tools/dev/quick_test.sh

# Complete system demonstration
bash tools/user/demo.sh

# Run complete test suite
bash tests/test_runner.sh

# Security demonstration
bash tools/demo/security/attack.sh --list
bash tools/demo/security/attack.sh malicious_code

# System recovery
bash tools/demo/user/restore.sh --auto
```

### Developer Tools
```bash
# Configuration validation
bash tools/config/validate_config.sh

# Generate security keys
bash tools/user/gen_keypair.sh generate

# Update system integrity
bash tools/user/gen_hash.sh generate
bash tools/user/sign_manifest.sh sign

# Verify system integrity
bash scripts/integrity_check.sh
```

---

*This document is suitable for developer reference. Users should refer to the user guide and security guide.*
