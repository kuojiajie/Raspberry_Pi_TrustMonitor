# Testing Guide

## 🧪 TrustMonitor Testing Suite

This document describes the comprehensive testing tools available for TrustMonitor validation and development.

## 📋 Available Test Scripts

### v2.2.5 Feature Tests

#### SIGTERM Graceful Shutdown Test
```bash
# Test graceful shutdown functionality
bash tools/dev/test_sigterm.sh
```

**What it tests:**
- SIGTERM signal handling
- Child process cleanup
- Hardware resource cleanup (GPIO, LED)
- State file preservation
- Multiple signal scenarios

**Expected Output:**
- All 3 test scenarios should pass
- Hardware cleanup messages in logs
- Shutdown timestamps created

#### Network Monitor Format Test
```bash
# Test network monitor output format consistency
bash tools/dev/test_network_format.sh
```

**What it tests:**
- Standalone network monitor formats
- Integration with health monitor
- Format consistency across all monitoring scripts
- Performance impact assessment

**Expected Output:**
- All 4 test categories should pass
- Network output format matches other monitors
- Execution time < 10 seconds

## 🔧 Integration Testing

### Health Monitor Integration
```bash
# Test full health monitor with timeout
timeout 30 bash daemon/health_monitor.sh
```

### Service Integration
```bash
# Test systemd service configuration
sudo systemctl status health-monitor.service  # If installed
sudo journalctl -u health-monitor.service -f  # View logs
```

## 📊 Format Consistency Standards

All monitoring scripts should follow this output format:

```
# Line 1: Status Summary
[COMPONENT] STATUS (metrics)

# Line 2: Detailed Information  
[Component] [metric]: [value], status code: [code]
```

**Examples:**
```bash
CPU OK (load1=0.81)
CPU load: 0.81 status code: 0

Network WARN (latency=250ms loss=5%)
Network latency: 250ms, packet loss: 5%, status code: 1
```

## 🎯 Test Categories

### 1. Unit Tests
- Individual script functionality
- Return code validation
- Output format verification

### 2. Integration Tests  
- Plugin system loading
- Health monitor orchestration
- Hardware interaction

### 3. Security Tests
- Integrity verification
- Digital signature validation
- Attack/defense scenarios

### 4. Performance Tests
- Execution time measurement
- Resource utilization
- Memory leak detection

## 🐛 Troubleshooting

### Common Issues

**Test fails with integrity check error:**
```bash
# Regenerate hashes and signatures
bash tools/gen_hash.sh generate
bash tools/sign_manifest.sh sign
```

**Hardware tests fail:**
```bash
# Check GPIO access
python3 -c "import RPi.GPIO; print('GPIO OK')"
```

**Service integration issues:**
```bash
# Check systemd configuration
sudo systemctl daemon-reload
sudo systemctl status health-monitor.service
```

## 📝 Test Results Interpretation

### Return Codes
- `0` - Success (✅)
- `1` - Warning (⚠️)  
- `2` - Error (❌)
- `3+` - Critical/System Error

### Test Log Locations
- Unit tests: `logs/*_test.log`
- Integration tests: `logs/health_monitor_test.log`
- Format tests: `logs/*_format_test.log`

## 🚀 Continuous Testing

For development, run tests after making changes:

```bash
# Quick validation
bash tools/dev/test_sigterm.sh
bash tools/dev/test_network_format.sh

# Full validation  
bash tools/user/demo.sh quick
```

This ensures all v2.2.5 features continue working correctly after modifications.
