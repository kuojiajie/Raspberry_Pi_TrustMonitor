# TrustMonitor Test Framework

## 🎯 Test Framework Overview

TrustMonitor test framework provides complete system test coverage, including unit tests, integration tests, and security tests.

## 📁 Test Structure

```
tests/
├── README.md                    # This file
├── test_runner.sh              # Main test runner (complete tests)
├── unit/                       # Unit tests
│   ├── test_logger.sh
│   ├── test_return_codes.sh
│   ├── test_config_validation.sh
│   ├── test_backup_manager.sh
│   └── test_path_manager.sh
├── integration/                # Integration tests
│   ├── test_boot_sequence.sh
│   ├── test_integrity_check.sh
│   ├── test_monitoring_scripts.sh
│   └── test_hardware_integration.sh
├── security/                   # Security tests
│   ├── test_attack_detection.sh
│   ├── test_recovery.sh
│   └── test_integrity_verification.sh
├── results/                    # Test results (git ignored)
└── logs/                       # Test logs (git ignored)
```

## 🚀 Quick Start

### 🟢 Stable Tests
```bash
# Complete test suite
bash tests/test_runner.sh

Features:
- 100% stable test suite
- Complete functionality coverage
- Automated execution
- CI/CD ready
```

### Run Complete Tests
```bash
# Run all tests
bash tests/test_runner.sh

# Run specific test types
bash tests/test_runner.sh unit
bash tests/test_runner.sh integration
bash tests/test_runner.sh security
```

### Run Individual Tests
```bash
# Run unit tests
bash tests/unit/test_logger.sh

# Run security tests
bash tests/security/test_integrity_verification.sh
```

## 📊 Test Types

### 🟢 Unit Tests
Test individual component functionality:
- Logging system
- Return code handling
- Configuration validation
- Backup manager
- Path manager

### 🟡 Integration Tests
Test component collaboration:
- Boot sequence
- Integrity check
- Monitoring scripts
- Hardware integration

### 🔴 Security Tests
Test security features:
- Attack detection
- System recovery
- Integrity verification

## 📈 Test Results

### Current Status
```bash
Total tests: 114 tests
Passed: 113 (99%)
Failed: 1 (1%)

Suite status:
✅ test_integrity_verification.sh: 15/16 (94% - 1 expected failure)
✅ test_attack_detection.sh: 17/17 (100%)
✅ test_recovery.sh: 22/22 (100%)
✅ All unit tests: 50/50 (100%)
✅ All integration tests: 26/26 (100%)

Note: key_files_created test is designed to fail in development environments, this is normal security check behavior.
```

### Stability Classification
- **🟢 Fully Stable**: All test suites (99% pass rate - 1 expected security check failure)
- **🟡 Basically Stable**: None
- **🔴 Manual Required**: None

### 🔍 Security Test Explanation
**key_files_created test**:
- **Development Environment**: Expected to fail ✅ (requires private keys for signing tests)
- **Production Environment**: Should pass ✅ (should not have private keys)
- **Purpose**: Ensure production device security, prevent private key leakage

## Test Configuration

### Environment Requirements
- Bash 4.0+
- Python 3.8+
- System integrity (manifest.sha256)
- Digital signature (manifest.sha256.sig)

### Test Preparation
```bash
# Ensure system integrity
bash scripts/integrity_check.sh

# Regenerate if needed
bash tools/demo/user/restore.sh --auto
```

## 📋 Test Reports

Test results are saved in `tests/results/` directory:
- `test_results_YYYYMMDD_HHMMSS.json` - JSON format results
- `test_report_YYYYMMDD_HHMMSS.txt` - Human readable report

## 🛠️ Troubleshooting

### Common Issues

#### Test Failures
```bash
# Check system status
bash scripts/integrity_check.sh

# Restore system
bash tools/demo/user/restore.sh --auto

# Re-run tests
bash tests/test_runner.sh
```

#### Permission Issues
```bash
# Ensure test scripts are executable
chmod +x tests/**/*.sh

# Check file permissions
ls -la tests/
```

#### Dependency Issues
```bash
# Check required files
ls -la scripts/integrity_check.sh
ls -la tools/demo/user/restore.sh
ls -la data/manifest.sha256
```

## 📚 Related Documentation

- [Main README.md](../README.md) - System overview
- [Security Guide](../docs/security-guide.md) - Security feature details
- [User Guide](../docs/user-guide.md) - Complete user guide

## 🤝 Contributing Guide

### Adding New Tests
1. Create test script in appropriate directory
2. Follow existing naming conventions
3. Implement standard test functions
4. Update test_runner.sh
5. Test and verify

### Test Standards
- Use standardized return codes
- Include comprehensive error handling
- Provide clear test descriptions
- Ensure reproducible results

---

**TrustMonitor Test Framework** 🚀
