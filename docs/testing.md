# Testing Guide

## 🧪 TrustMonitor Development Testing Suite

This document describes the comprehensive testing tools available for TrustMonitor validation and development.

## 📋 Quick Test Commands

### System Health Tests
```bash
# Test complete system integration
bash tools/dev/test_system_integration.sh

# Test hardware functionality
bash tools/dev/test_system_hardware_integration.sh

# Test HAL system (v2.2.6+)
bash tools/dev/test_hal_core.sh
```

### Feature-Specific Tests
```bash
# Test graceful shutdown (SIGTERM)
bash tools/dev/test_sigterm.sh

# Test network monitor format
bash tools/dev/test_network_format.sh

# Test system crash recovery
bash tools/dev/crash_test.sh
```

## 🔧 Development Testing Workflow

### Before Making Changes
```bash
# 1. Run baseline tests
bash tools/dev/test_system_integration.sh
bash tools/dev/test_system_hardware_integration.sh

# 2. Verify system integrity
bash scripts/integrity_check.sh

# 3. Test security features
bash tools/security/attack.sh --list
```

### After Making Changes
```bash
# 1. Update system integrity
bash tools/user/gen_hash.sh generate
bash tools/user/sign_manifest.sh sign

# 2. Run integration tests
bash tools/dev/test_system_integration.sh

# 3. Verify service functionality
sudo systemctl restart health-monitor.service
sudo systemctl status health-monitor.service
```

## 📊 Test Categories

### Integration Tests
- **System Integration**: Full health monitor workflow
- **Hardware Integration**: Sensor and LED functionality
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
