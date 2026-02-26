# TrustMonitor Documentation

## 📚 Available Documentation

### 🔒 Security Documentation
- **[Attack/Defense Demo](security/attack-defense-demo.md)** - Complete security demonstration with 5 attack scenarios

### 🔧 System Documentation
- **[HAL System](hal-system.md)** - Hardware Abstraction Layer architecture and usage
- **[HAL Architecture](hal-architecture.md)** - Complete HAL system architecture and design patterns
- **[Backup Management](backup-management.md)** - Unified backup system with automatic cleanup and retention policies
- **[Testing Guide](testing.md)** - Comprehensive testing suite and validation procedures

### 📋 Reference Documentation
- **[Return Codes](../lib/return_codes.sh)** - Unified return code constants and error handling (see file header documentation)

### 🛠️ Development Tools (v2.2.7+)
- **[Developer Tools Guide](#developer-tools-guide)** - Complete development and testing toolkit

## 🎯 Quick Links

- **Quick Start**: See main [README.md](../README.md) for 5-minute setup
- **Security Demo**: [Attack/Defense Demo](security/attack-defense-demo.md) for comprehensive security testing
- **HAL System**: [HAL System](hal-system.md) for hardware abstraction layer documentation
- **Backup Management**: [Backup Management](backup-management.md) for backup system configuration
- **Testing Guide**: [Testing Guide](testing.md) for development and validation procedures
- **Return Codes**: [Return Codes](../lib/return_codes.sh) for error handling reference

## 🛠️ Developer Tools Guide

### Quick Testing
```bash
# Run all core tests (recommended for daily development)
./tools/dev/quick_test.sh

# Run comprehensive test suite with detailed output
./tools/dev/run_all_tests.sh --verbose

# Run only essential tests (faster)
./tools/dev/run_all_tests.sh --quick
```

### Environment Validation
```bash
# Check Python environment and HAL dependencies
./tools/dev/check_hal_env.sh

# Clean up GPIO/PWM states (useful after test failures)
./tools/dev/cleanup_gpio.sh

# Force cleanup if processes are stuck
./tools/dev/cleanup_gpio.sh --force
```

### Individual Test Suites
```bash
# HAL system tests
./tools/dev/test_hal_core.sh          # HAL core functionality
./tools/dev/test_hal_refactor.sh      # HAL refactoring validation

# System integration tests
./tools/dev/test_system_integration.sh
./tools/dev/test_system_hardware_integration.sh

# Hardware functionality tests
./tools/dev/test_hardware_functionality.sh
```

### Known Issues & Solutions

#### PWM/GPIO Conflicts
If tests fail intermittently, use GPIO cleanup:
```bash
./tools/dev/cleanup_gpio.sh
./tools/dev/quick_test.sh
```

#### HAL vs Legacy Systems
- **HAL System**: Modern hardware interface (preferred)
- **Legacy System**: Original controllers (marked DEPRECATED)
- **Automatic Fallback**: System uses HAL when available

## 📖 Getting Started

1. **New Users**: Start with the main [README.md](../README.md) for basic setup
2. **HAL Development**: See [HAL System](hal-system.md) for hardware abstraction layer usage
3. **Security Testing**: Follow the [Attack/Defense Demo](security/attack-defense-demo.md) for security validation
4. **Backup Management**: See [Backup Management](backup-management.md) for backup system configuration
5. **Development**: Use the [Developer Tools Guide](#developer-tools-guide) for testing and validation

## 📋 Documentation Structure

```
docs/
├── README.md                    # This file - documentation index
├── hal-system.md               # HAL system documentation
├── hal-architecture.md         # Complete HAL architecture and design patterns
├── backup-management.md         # Backup system guide
├── testing.md                   # Testing procedures and validation
└── security/
    └── attack-defense-demo.md   # Security demonstration guide
```
5. **Development**: See [Return Codes](../lib/return_codes.sh) for understanding error handling
6. **Testing**: Use the [Testing Guide](testing.md) for development and validation procedures

---

*Documentation focused on user needs and practical usage.*
