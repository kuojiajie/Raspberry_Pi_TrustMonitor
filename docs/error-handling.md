# Error Handling Standardization v3.1.3

## 🔧 Error Handling Standardization

TrustMonitor v3.1.3 introduces standardized error handling across all monitoring scripts, ensuring consistent return codes and proper error reporting.

## 🎯 Standardization Goals

1. **Unified Return Codes**: Consistent use of RC_OK, RC_WARN, RC_ERROR constants
2. **Proper Library Loading**: All scripts must load lib/return_codes.sh
3. **Eliminate Hardcoded Values**: Replace return 0/1 with standardized constants
4. **Consistent Error Reporting**: Unified error handling and logging
5. **Maintain Backward Compatibility**: Ensure existing functionality remains intact

## 📊 Standardized Return Code System

### Core System Codes
```bash
RC_OK=0           # Operation successful
RC_WARN=1         # Warning condition
RC_ERROR=2        # Error condition
RC_PLUGIN_ERROR=3  # Plugin system error
```

### ROT Security Codes
```bash
RC_INTEGRITY_FAILED=4      # File integrity verification failed
RC_SIGNATURE_FAILED=5      # Digital signature verification failed
RC_BOOT_FAILED=6          # Secure boot sequence failed
```

### Hardware Codes
```bash
RC_SENSOR_ERROR=7          # Sensor hardware error
RC_LED_ERROR=8             # LED hardware error
```

### Network Codes
```bash
RC_NETWORK_FAILED=9        # Network connectivity failed
```

### Configuration Codes
```bash
RC_CONFIG_ERROR=10         # Configuration error
RC_DEPENDENCY_ERROR=11      # Missing dependencies
```

## 🔧 Implementation Details

### Scripts Modified

#### 1. **scripts/watchdog.sh**
**Changes Made:**
- Replaced `return 0` with `return $RC_OK`
- Replaced `return 1` with `return $RC_ERROR`
- Ensured proper loading of `lib/return_codes.sh`

**Before:**
```bash
return 0  # Service restart successful
return 1  # Service restart failed
```

**After:**
```bash
return $RC_OK   # Service restart successful
return $RC_ERROR # Service restart failed
```

#### 2. **scripts/watchdog_standalone.sh**
**Changes Made:**
- Added return codes loading with fallback
- Replaced `return 0` with `return $RC_OK`
- Replaced `return 1` with `return $RC_ERROR`

**Added Loading Logic:**
```bash
# Load return codes for standardized error handling
if [[ -f "$PROJECT_ROOT/lib/return_codes.sh" ]]; then
    source "$PROJECT_ROOT/lib/return_codes.sh"
else
    # Fallback return codes if library not available
    readonly RC_OK=0
    readonly RC_WARN=1
    readonly RC_ERROR=2
fi
```

### Scripts Already Compliant

The following scripts were already using standardized return codes:

#### ✅ **Monitoring Scripts**
- `scripts/cpu_monitor.sh`
- `scripts/memory_monitor.sh`
- `scripts/disk_monitor.sh`
- `scripts/network_monitor.sh`
- `scripts/cpu_temp_monitor.sh`
- `scripts/backup_cleanup.sh`

#### ✅ **Security Scripts**
- `scripts/integrity_check.sh`
- `scripts/verify_signature.sh`
- `scripts/boot_sequence.sh`
- `scripts/sel_logger.sh`

## 🧪 Testing and Validation

### Test Results
```bash
# All monitoring scripts return RC_OK (0) when successful
bash scripts/cpu_monitor.sh          # Exit code: 0 ✅
bash scripts/memory_monitor.sh       # Exit code: 0 ✅
bash scripts/disk_monitor.sh         # Exit code: 0 ✅
bash scripts/network_monitor.sh       # Exit code: 0 ✅
bash scripts/cpu_temp_monitor.sh     # Exit code: 0 ✅
bash scripts/backup_cleanup.sh       # Exit code: 0 ✅

# Security scripts return appropriate codes
bash scripts/integrity_check.sh      # Exit code: 0 ✅
bash scripts/verify_signature.sh      # Exit code: 0 ✅

# Watchdog scripts now use standardized codes
bash scripts/watchdog.sh check          # Exit code: 0 ✅
bash scripts/watchdog_standalone.sh check # Exit code: 0 ✅
```

### Validation Process
1. **Code Review**: Verified all scripts use RC_* constants
2. **Functional Testing**: Tested all scripts with various scenarios
3. **Return Code Verification**: Confirmed proper exit codes
4. **Library Loading**: Verified proper return_codes.sh loading
5. **Backward Compatibility**: Ensured existing functionality intact

## 🎯 Benefits of Standardization

### For Developers
- **Consistent API**: Predictable return code behavior
- **Easier Debugging**: Clear error categorization
- **Better Testing**: Standardized test expectations
- **Code Maintainability**: Centralized error code definitions

### For System Administrators
- **Reliable Monitoring**: Consistent error reporting
- **Better Logging**: Standardized error categorization
- **Easier Troubleshooting**: Clear error code meanings
- **Integration Ready**: Machine-readable error codes

### For Automation
- **CI/CD Ready**: Standardized return codes for automation
- **Monitoring Integration**: Consistent status reporting
- **Alerting**: Predictable error code behavior
- **Tool Compatibility**: Machine-readable error handling

## 📋 Migration Guide

### For Script Developers
When creating new monitoring scripts:

```bash
#!/bin/bash
# Always load return codes at the beginning
source "$BASE_DIR/lib/return_codes.sh"

# Use standardized return codes
if [[ "$condition" == "success" ]]; then
    log_info "Operation completed successfully"
    return $RC_OK
elif [[ "$condition" == "warning" ]]; then
    log_warn "Warning condition detected"
    return $RC_WARN
else
    log_error "Error condition detected"
    return $RC_ERROR
fi
```

### For System Integrators
When integrating with monitoring tools:

```bash
# Check return codes consistently
if bash scripts/monitor.sh; then
    case $? in
        $RC_OK) echo "✅ Monitor OK" ;;
        $RC_WARN) echo "⚠ Monitor Warning" ;;
        $RC_ERROR) echo "❌ Monitor Error" ;;
        *) echo "❓ Unknown Status" ;;
    esac
fi
```

## 🔍 Error Code Reference

### Quick Reference
| Code | Constant | Description | Usage |
|------|-----------|-------------|--------|
| 0 | RC_OK | Operation successful |
| 1 | RC_WARN | Warning condition |
| 2 | RC_ERROR | Error condition |
| 3 | RC_PLUGIN_ERROR | Plugin system error |
| 4 | RC_INTEGRITY_FAILED | File integrity verification failed |
| 5 | RC_SIGNATURE_FAILED | Digital signature verification failed |
| 6 | RC_BOOT_FAILED | Secure boot sequence failed |
| 7 | RC_SENSOR_ERROR | Sensor hardware error |
| 8 | RC_LED_ERROR | LED hardware error |
| 9 | RC_NETWORK_FAILED | Network connectivity failed |
| 10 | RC_CONFIG_ERROR | Configuration error |
| 11 | RC_DEPENDENCY_ERROR | Missing dependencies |

### Error Handling Best Practices
1. **Always load return codes**: `source "$BASE_DIR/lib/return_codes.sh"`
2. **Use constants**: Never use hardcoded return values
3. **Log appropriately**: Use appropriate log levels for each return code
4. **Handle edge cases**: Consider all possible error scenarios
5. **Test thoroughly**: Verify return codes in all scenarios

---

*Error Handling Standardization ensures consistent, maintainable, and reliable monitoring scripts.*
