# Configuration Validation Guide

## Overview

TrustMonitor v3.1.5+ includes a comprehensive configuration validation system that ensures all configuration parameters are properly formatted, within valid ranges, and logically consistent.

## 🔧 Validation Tool

### Location
```
tools/config/validate_config.sh
```

### Usage

#### Basic Validation
```bash
# Validate default configuration file
bash tools/config/validate_config.sh

# Validate specific configuration file
bash tools/config/validate_config.sh /path/to/custom.env
```

#### Specific Section Validation
```bash
# Validate only DHT11 pin configuration
bash tools/config/validate_config.sh --dht11-only

# Validate only temperature thresholds
bash tools/config/validate_config.sh --temp-only

# Validate only LED pin configuration
bash tools/config/validate_config.sh --led-only

# Validate only network configuration
bash tools/config/validate_config.sh --network-only

# Validate only security configuration
bash tools/config/validate_config.sh --security-only

# Validate only system thresholds (v3.1.5+)
bash tools/config/validate_config.sh --system-only

# Validate only path configuration (v3.1.5+)
bash tools/config/validate_config.sh --paths-only

# Validate only logging configuration (v3.1.5+)
bash tools/config/validate_config.sh --logging-only

# Validate only watchdog configuration (v3.1.5+)
bash tools/config/validate_config.sh --watchdog-only

# Validate only SEL configuration (v3.1.5+)
bash tools/config/validate_config.sh --sel-only
```

#### Advanced Options
```bash
# Verbose output
bash tools/config/validate_config.sh -v

# Quiet mode (errors only)
bash tools/config/validate_config.sh -q

# Show help
bash tools/config/validate_config.sh --help
```

## 📊 Validation Checks

### 1. DHT11 Pin Validation (`validate_dht11_pin`)
- **Format**: Numeric GPIO pin number
- **Range**: 0-27 for Raspberry Pi
- **Recommended**: 4, 17, 18, 22, 23, 24, 25, 27
- **Example**: `DHT11_PIN=17`

**Validates:**
- Pin is defined and numeric
- Pin is within valid GPIO range
- Pin is suitable for DHT11 sensors

### 2. Temperature Thresholds Validation (`validate_temperature_thresholds`)
- **Format**: Numeric temperature values in Celsius
- **Range**: 0-85°C for Raspberry Pi safety
- **Logic**: Warning < Error thresholds
- **Example**: `CPU_TEMP_WARN=65.0`, `CPU_TEMP_ERROR=75.0`

**Validates:**
- CPU temperature thresholds are defined and numeric
- Warning threshold is less than error threshold
- Values are within safe operating ranges
- Sensor temperature thresholds (if defined)

### 3. LED Pin Validation (`validate_led_pins`)
- **Format**: Numeric GPIO pin numbers
- **Range**: 0-27 for Raspberry Pi
- **Requirements**: All three pins must be unique
- **Example**: `LED_RED_PIN=27`, `LED_GREEN_PIN=22`, `LED_BLUE_PIN=5`

**Validates:**
- All LED pins are defined and numeric
- Pins are within valid GPIO range
- No pin conflicts between colors
- Pins are suitable for PWM/control

### 4. Network Configuration Validation (`validate_network_config`)
- **Format**: IP address or hostname for PING_TARGET
- **Range**: Timeout 1-30 seconds
- **Example**: `PING_TARGET=8.8.8.8`, `NETWORK_TIMEOUT=5`

**Validates:**
- PING_TARGET is valid IP address or hostname
- NETWORK_TIMEOUT is numeric and reasonable
- Network quality thresholds (if defined)
- Packet loss percentages are valid

### 5. Security Configuration Validation (`validate_security_config`)
- **Format**: Standard security parameters
- **RSA Key Size**: 1024-8192 bits (recommended: 2048+)
- **Hash Algorithm**: sha256, sha384, sha512 (sha1 deprecated)
- **Example**: `RSA_KEY_SIZE=2048`, `HASH_ALGORITHM=sha256`

**Validates:**
- RSA key size is appropriate and secure
- Hash algorithm is supported and secure
- Monitoring intervals are reasonable
- Security parameters follow best practices

### 6. System Thresholds Validation (`validate_system_thresholds`) - v3.1.5+
- **Format**: Numeric values for CPU, memory, disk thresholds
- **CPU Load**: Numeric values (e.g., 1.50, 3.00)
- **Memory**: Percentages (1-100%)
- **Disk**: Percentages (1-100%)
- **Example**: `CPU_LOAD_WARN=1.50`, `MEM_AVAIL_WARN_PCT=15`, `DISK_USED_WARN_PCT=80`

**Validates:**
- All system thresholds are defined and numeric
- Logical relationships (warning < error for usage, warning > error for availability)
- Values are within reasonable ranges
- Proper percentage ranges for memory and disk

### 7. Path Configuration Validation (`validate_paths`) - v3.1.5+
- **Format**: Absolute paths
- **Required**: PROJECT_ROOT, DATA_DIR, KEYS_DIR
- **Permissions**: Read/write access checks
- **Example**: `PROJECT_ROOT=/home/user/project`, `DATA_DIR=/home/user/project/data`

**Validates:**
- All paths are absolute and exist
- Proper read/write permissions
- Automatic creation of missing directories
- Security checks for KEYS_DIR permissions
- Path relationships (DATA_DIR/KEYS_DIR within PROJECT_ROOT)

### 8. Logging Configuration Validation (`validate_logging_config`) - v3.1.5+
- **Format**: Standard logging parameters
- **LOG_LEVEL**: DEBUG, INFO, WARN, ERROR
- **LOG_FORMAT**: Must contain %LEVEL% and %MESSAGE%
- **Example**: `LOG_LEVEL=INFO`, `LOG_FORMAT="[%Y-%m-%d %H:%M:%S] [%LEVEL%] [%COMPONENT%] %MESSAGE%"`

**Validates:**
- Log level is valid
- Log format contains required placeholders
- Format string is reasonable length
- Optional placeholders are properly formatted

### 9. Watchdog Configuration Validation (`validate_watchdog_config`) - v3.1.5+
- **Format**: Time intervals and service names
- **Intervals**: Numeric seconds
- **Services**: systemd service names (.service suffix)
- **Example**: `WATCHDOG_INTERVAL=300`, `WATCHDOG_SERVICES=health-monitor.service`

**Validates:**
- All intervals are numeric and reasonable
- Logical relationships (timeout > interval)
- Retry counts and delays are appropriate
- Service names are properly formatted
- System thresholds are within valid ranges

### 10. SEL Configuration Validation (`validate_sel_config`) - v3.1.5+
- **Format**: Numeric values and boolean flags
- **Entries**: Maximum log entries (100-100000)
- **Retention**: Days (7-365)
- **Booleans**: true/false values
- **Example**: `SEL_MAX_ENTRIES=1000`, `SEL_LOG_CRITICAL_EVENTS=true`

**Validates:**
- Entry counts and retention periods are reasonable
- Boolean values are properly formatted
- Logical relationships between entries and retention
- Estimated daily entry rates are acceptable

## 📋 Exit Codes

| Code | Meaning | Description |
|-------|---------|-------------|
| 0 | Success | Configuration is valid |
| 1 | Error | Configuration has errors |
| 2 | Warning | Configuration is valid but has warnings |
| 3 | File Error | Configuration file not found |
| 4 | Argument Error | Invalid command line arguments |

## 🔍 Common Issues

### Configuration File Not Found
```bash
# Error: Configuration file not found: /path/to/config.env
# Solution: Check file path and ensure file exists
ls -la /path/to/config.env
```

### Invalid Parameter Values
```bash
# Error: CPU_TEMP_WARN must be numeric, got: abc
# Solution: Check parameter format in configuration file
grep CPU_TEMP_WARN config/health-monitor.env
```

### Logical Relationship Errors
```bash
# Error: CPU_TEMP_WARN (70.0) must be less than CPU_TEMP_ERROR (65.0)
# Solution: Ensure warning threshold is less than error threshold
```

### Permission Issues
```bash
# Error: KEYS_DIR is not writable: /path/to/keys
# Solution: Check directory permissions
ls -la /path/to/keys
chmod 755 /path/to/keys
```

## 📝 Best Practices

### Configuration Management
1. **Use Version Control**: Track configuration changes
2. **Backup Before Changes**: Always backup working configuration
3. **Test Validation**: Run validation after configuration changes
4. **Document Changes**: Note why configuration was modified

### Validation Workflow
1. **Initial Validation**: Validate configuration before deployment
2. **Section Validation**: Validate specific sections during development
3. **Full Validation**: Run complete validation before production
4. **Regular Checks**: Schedule periodic validation

### Security Considerations
1. **Sensitive Data**: Never commit sensitive configuration to version control
2. **File Permissions**: Ensure appropriate file permissions
3. **Access Control**: Limit access to configuration files
4. **Audit Trail**: Maintain audit trail of configuration changes

## 🔗 Integration Examples

### Pre-commit Hook
```bash
#!/bin/sh
# .git/hooks/pre-commit
echo "Validating configuration..."
if ! bash tools/config/validate_config.sh; then
    echo "Configuration validation failed"
    exit 1
fi
echo "Configuration validation passed"
```

### CI/CD Pipeline
```yaml
# Example GitHub Actions
- name: Validate Configuration
  run: |
    bash tools/config/validate_config.sh
    bash tools/config/validate_config.sh --system-only
    bash tools/config/validate_config.sh --paths-only
```

### Service Integration
```bash
# Example service script
start() {
    # Validate configuration before starting
    if ! bash tools/config/validate_config.sh; then
        echo "Configuration validation failed"
        exit 1
    fi
    
    # Start service
    exec daemon/health_monitor.sh
}
```

## 📚 Additional Resources

- [Configuration File Reference](../config/health-monitor.env.example)
- [Troubleshooting Guide](../README.md#-troubleshooting)
- [Security Guide](security-guide.md)
- [User Guide](user-guide.md)
- [HAL System Documentation](hal-system.md)

---

*This guide covers the configuration validation system introduced in TrustMonitor v3.1.5+. For more information about other features, see the main documentation.*
