# Testing Guide

## 🧪 TrustMonitor Development Testing Suite

This document describes the comprehensive testing tools available for TrustMonitor validation and development.

## � Quick Start (v2.2.7+)

### Recommended Daily Testing
```bash
# Quick test suite (recommended for daily development)
./tools/dev/quick_test.sh

# Comprehensive test suite
./tools/dev/run_all_tests.sh

# Environment validation
./tools/dev/check_hal_env.sh
```

### GPIO/PWM Management
```bash
# Clean up GPIO states (use before/after tests)
./tools/dev/cleanup_gpio.sh

# Force cleanup if processes are stuck
./tools/dev/cleanup_gpio.sh --force
```

## 📋 Test Categories

### 🎯 Core System Tests
```bash
# HAL core functionality (15 tests)
./tools/dev/test_hal_core.sh

# HAL refactoring validation (15 tests)
./tools/dev/test_hal_refactor.sh

# System integration (20 tests)
./tools/dev/test_system_integration.sh
```

### 🔧 Hardware Tests
```bash
# Hardware functionality (23 tests)
./tools/dev/test_hardware_functionality.sh

# System hardware integration (6 tests)
./tools/dev/test_system_hardware_integration.sh
```

### ⚙️ Feature-Specific Tests
```bash
# Test graceful shutdown (SIGTERM)
./tools/dev/test_sigterm.sh

# Test network monitor format
./tools/dev/test_network_format.sh

# Test system crash recovery
./tools/dev/crash_test.sh
```
```

## 🔧 Development Testing Workflow (v2.2.7+)

### Before Making Changes
```bash
# 1. Clean up GPIO states
./tools/dev/cleanup_gpio.sh

# 2. Run baseline tests
./tools/dev/quick_test.sh

# 3. Verify environment
./tools/dev/check_hal_env.sh

# 4. Verify system integrity
bash scripts/integrity_check.sh

# 5. Test security features
bash tools/security/attack.sh --list
```

### After Making Changes
```bash
# 1. Clean up GPIO states
./tools/dev/cleanup_gpio.sh

# 2. Update system integrity
bash tools/user/gen_hash.sh generate
bash tools/user/sign_manifest.sh sign

# 3. Run comprehensive tests
./tools/dev/run_all_tests.sh

# 4. Verify service functionality
sudo systemctl restart health-monitor.service
sudo systemctl status health-monitor.service
```

## 📊 Test Coverage

### Core System Tests
- **HAL Core**: 15 tests covering HAL initialization, device management, and self-tests
- **HAL Refactoring**: 15 tests covering HAL/Legacy compatibility and integration
- **System Integration**: 20 tests covering complete system workflow

### Hardware Tests
- **Hardware Functionality**: 23 tests covering sensors, LEDs, and GPIO operations
- **System Hardware Integration**: 6 tests covering hardware-software integration

### Security Tests
- **Attack/Defense Demo**: 5 attack scenarios with detection and recovery
- **Integrity Verification**: SHA256 hash and RSA signature validation

## 🚨 Known Issues & Solutions

### PWM/GPIO Conflicts
**Problem**: Intermittent test failures due to PWM/GPIO conflicts between HAL and Legacy systems.

**Solution**:
```bash
# Always clean up before testing
./tools/dev/cleanup_gpio.sh

# Tests include automatic cleanup (v2.2.7+)
./tools/dev/quick_test.sh
```

### HAL vs Legacy Systems
**Problem**: Uncertainty about which hardware system is being used.

**Solution**:
- HAL system is preferred (v2.2.6+)
- Legacy system marked as DEPRECATED
- System automatically falls back to Legacy if HAL fails

### Test Timeouts
**Problem**: Tests sometimes timeout due to hardware initialization delays.

**Solution**:
```bash
# Use timeout-aware test runner
./tools/dev/run_all_tests.sh --quick

# Individual tests include timeout handling
timeout 60 ./tools/dev/test_hal_core.sh
```
- **HAL Integration**: Hardware abstraction layer testing

### Feature Tests
- **Graceful Shutdown**: SIGTERM handling and cleanup
- **Network Format**: Output consistency validation
- **Crash Recovery**: System resilience testing

### Security Tests
- **Attack Scenarios**: 5 different attack simulations
- **Integrity Verification**: Hash and signature validation
- **Recovery Testing**: Backup and restore procedures

## 🚨 Expected Results

### Successful Test Output
```
✅ All integration tests passed
✅ Hardware functionality verified
✅ Security features operational
✅ System integrity confirmed
```

### Common Issues
- **GPIO Permission**: Ensure user is in gpio group
- **Hardware Not Found**: Check wiring and connections
- **Service Failures**: Verify configuration and dependencies

## 📈 Performance Benchmarks

### Expected Performance
- **Health Check Cycle**: < 30 seconds
- **Hardware Response**: < 5 seconds
- **Network Tests**: < 10 seconds
- **Integrity Checks**: < 60 seconds

### Monitoring During Tests
```bash
# Monitor system resources
htop
iostat -x 1

# Monitor service logs
sudo journalctl -u health-monitor.service -f
```

---

*For user-facing testing and security demonstrations, see the main [README.md](../README.md).*
