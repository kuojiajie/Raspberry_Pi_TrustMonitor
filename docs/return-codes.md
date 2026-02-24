# TrustMonitor Return Code System

## 📋 Overview

TrustMonitor uses a unified return code system to provide consistent error handling and status reporting across all components.

## 🔢 Return Code Constants

### Core System Codes
| Code | Constant | Description |
|-------|-----------|-------------|
| 0 | `RC_OK` | Operation successful |
| 1 | `RC_WARN` | Warning condition |
| 2 | `RC_ERROR` | Error condition |
| 3 | `RC_PLUGIN_ERROR` | Plugin system error |

### ROT Security Codes
| Code | Constant | Description |
|-------|-----------|-------------|
| 4 | `RC_INTEGRITY_FAILED` | File integrity verification failed |
| 5 | `RC_SIGNATURE_FAILED` | Digital signature verification failed |
| 6 | `RC_BOOT_FAILED` | Secure boot sequence failed |

### Hardware Codes
| Code | Constant | Description |
|-------|-----------|-------------|
| 7 | `RC_SENSOR_ERROR` | Sensor hardware error |
| 8 | `RC_LED_ERROR` | LED hardware error |

### Network Codes
| Code | Constant | Description |
|-------|-----------|-------------|
| 9 | `RC_NETWORK_FAILED` | Network connectivity failed |

### Configuration Codes
| Code | Constant | Description |
|-------|-----------|-------------|
| 10 | `RC_CONFIG_ERROR` | Configuration error |
| 11 | `RC_DEPENDENCY_ERROR` | Missing dependencies |

## 🛠️ Usage Examples

### In Scripts
```bash
# Load return codes
source "$BASE_DIR/lib/return_codes.sh"

# Use in functions
if check_condition; then
    return $RC_OK
else
    return $RC_ERROR
fi
```

### Enhanced Logging
```bash
# Log with return code
log_error_with_rc "Operation failed" $RC_ERROR

# Get description
description=$(get_return_code_description $RC_ERROR)  # Returns "ERROR"
```

### Status Checking
```bash
# Check return codes
if is_success_code $rc; then
    echo "Operation succeeded"
elif is_warning_code $rc; then
    echo "Operation had warnings"
elif is_critical_error $rc; then
    echo "Critical error - immediate attention required"
fi
```

## 📊 Return Code Categories

### Success (0)
- Normal operation completed successfully
- All checks passed
- No issues detected

### Warning (1)
- Non-critical issues detected
- System continues to operate
- Attention may be needed

### Error (2-3)
- Standard errors that need attention
- Component failures
- Plugin system issues

### Critical Errors (4-6)
- Security-related failures
- Integrity compromises
- Boot sequence failures

### Hardware/Network Errors (7-9)
- Sensor malfunctions
- LED control issues
- Network connectivity problems

### Configuration Errors (10-11)
- Missing or invalid configuration
- Dependency issues
- Environment problems

## 🔧 Implementation Details

### File Location
- **Main Library**: `lib/return_codes.sh`
- **Loaded by**: All monitoring scripts and plugins

### Loading Mechanism
```bash
# Conditional loading prevents redefinition
if [[ -z "${RC_OK:-}" ]]; then
    readonly RC_OK=0
    readonly RC_WARN=1
    # ... other constants
fi
```

### Utility Functions
- `get_return_code_description()` - Get human-readable description
- `is_success_code()` - Check if return code indicates success
- `is_warning_code()` - Check if return code indicates warning
- `is_error_code()` - Check if return code indicates error
- `is_critical_error()` - Check if return code indicates critical error

## 🐛 Debugging with Return Codes

### Common Patterns
```bash
# Check specific error type
case $rc in
    $RC_OK) echo "Success" ;;
    $RC_WARN) echo "Warning detected" ;;
    $RC_ERROR) echo "Error occurred" ;;
    $RC_INTEGRITY_FAILED) echo "Security integrity compromised" ;;
    *) echo "Unknown error: $rc" ;;
esac
```

### Logging Integration
```bash
# Enhanced logging with return codes
log_with_rc "INFO" "Operation completed" $RC_OK
log_with_rc "ERROR" "Operation failed" $RC_ERROR
```

## 📈 Benefits

1. **Consistency**: All components use same error codes
2. **Debugging**: Easier to identify issue types
3. **Monitoring**: Better integration with monitoring systems
4. **Automation**: Scriptable error handling
5. **Documentation**: Clear error categorization

---

*For implementation details, see `lib/return_codes.sh`*
