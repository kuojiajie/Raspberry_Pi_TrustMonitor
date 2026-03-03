# Configuration Validation Tools

## 📋 Overview

This directory contains configuration validation tools for TrustMonitor, ensuring that configuration files are properly formatted and contain valid values before system startup.

## 🔧 Available Tools

### validate_config.sh
Comprehensive configuration validation tool that checks all aspects of the TrustMonitor configuration.

#### Usage
```bash
# Validate default configuration
./tools/config/validate_config.sh

# Validate specific configuration file
./tools/config/validate_config.sh /path/to/custom.env

# Validate specific sections
./tools/config/validate_config.sh --dht11-only
./tools/config/validate_config.sh --temp-only
./tools/config/validate_config.sh --led-only
./tools/config/validate_config.sh --network-only
./tools/config/validate_config.sh --security-only
./tools/config/validate_config.sh --system-only
./tools/config/validate_config.sh --paths-only
./tools/config/validate_config.sh --logging-only
./tools/config/validate_config.sh --watchdog-only
./tools/config/validate_config.sh --sel-only

# With options
./tools/config/validate_config.sh -v                    # Verbose output
./tools/config/validate_config.sh -q                    # Quiet mode
./tools/config/validate_config.sh --help                 # Show help
```

#### Validation Checks

##### 1. DHT11 Pin Validation (`validate_dht11_pin()`)
- **Format**: Numeric GPIO pin number
- **Range**: 0-27 for Raspberry Pi
- **Recommended**: 4, 17, 18, 22, 23, 24, 25, 27
- **Example**: `DHT11_PIN=17`

**Validates:**
- Pin is defined and numeric
- Pin is within valid GPIO range
- Pin is suitable for DHT11 sensors

##### 2. Temperature Thresholds Validation (`validate_temperature_thresholds()`)
- **Format**: Numeric temperature values in Celsius
- **Range**: 0-85°C for Raspberry Pi safety
- **Logic**: Warning < Error thresholds
- **Example**: `CPU_TEMP_WARN=65.0`, `CPU_TEMP_ERROR=75.0`

**Validates:**
- CPU temperature thresholds are defined and numeric
- Warning threshold is less than error threshold
- Values are within safe operating ranges
- Sensor temperature thresholds (if defined)

##### 3. LED Pin Validation (`validate_led_pins()`)
- **Format**: Numeric GPIO pin numbers
- **Range**: 0-27 for Raspberry Pi
- **Requirements**: All three pins must be unique
- **Example**: `LED_RED_PIN=27`, `LED_GREEN_PIN=22`, `LED_BLUE_PIN=5`

**Validates:**
- All LED pins are defined and numeric
- Pins are within valid GPIO range
- No pin conflicts between colors
- Pins are suitable for PWM/control

##### 4. Network Configuration Validation (`validate_network_config()`)
- **Format**: IP address or hostname for PING_TARGET
- **Range**: Timeout 1-30 seconds
- **Example**: `PING_TARGET=8.8.8.8`, `NETWORK_TIMEOUT=5`

**Validates:**
- PING_TARGET is valid IP address or hostname
- NETWORK_TIMEOUT is numeric and reasonable
- Network quality thresholds (if defined)
- Packet loss percentages are valid

##### 5. Security Configuration Validation (`validate_security_config()`)
- **Format**: Standard security parameters
- **RSA Key Size**: 1024-8192 bits (recommended: 2048+)
- **Hash Algorithm**: sha256, sha384, sha512 (sha1 deprecated)
- **Example**: `RSA_KEY_SIZE=2048`, `HASH_ALGORITHM=sha256`

**Validates:**
- RSA key size is appropriate and secure
- Hash algorithm is supported and secure
- Monitoring intervals are reasonable
- Security parameters follow best practices

##### 6. System Thresholds Validation (`validate_system_thresholds()`)
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

##### 7. Path Configuration Validation (`validate_paths()`)
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

##### 8. Logging Configuration Validation (`validate_logging_config()`)
- **Format**: Standard logging parameters
- **LOG_LEVEL**: DEBUG, INFO, WARN, ERROR
- **LOG_FORMAT**: Must contain %LEVEL% and %MESSAGE%
- **Example**: `LOG_LEVEL=INFO`, `LOG_FORMAT="[%Y-%m-%d %H:%M:%S] [%LEVEL%] %MESSAGE%"`

**Validates:**
- Log level is valid
- Log format contains required placeholders
- Format string is reasonable length
- Optional placeholders are properly formatted

##### 9. Watchdog Configuration Validation (`validate_watchdog_config()`)
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

##### 10. SEL Configuration Validation (`validate_sel_config()`)
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

## 📊 Exit Codes

| Code | Meaning | Description |
|-------|---------|-------------|
| 0 | Success | Configuration is valid |
| 1 | Error | Configuration has errors |
| 2 | Warning | Configuration is valid but has warnings |
| 3 | File Error | Configuration file not found |
| 4 | Argument Error | Invalid command line arguments |

## 🎯 Integration Examples

### Pre-startup Validation
```bash
#!/bin/bash
# Add to boot sequence before starting services

if ! ./tools/config/validate_config.sh -q; then
    echo "Configuration validation failed - aborting startup"
    exit 1
fi

echo "Configuration validated - starting services"
./daemon/health_monitor.sh
```

### Configuration Change Validation
```bash
#!/bin/bash
# Validate before applying configuration changes

NEW_CONFIG="/tmp/new_config.env"

# First validate the new configuration
if ./tools/config/validate_config.sh "$NEW_CONFIG"; then
    echo "New configuration is valid - applying changes"
    cp "$NEW_CONFIG" "$BASE_DIR/config/health-monitor.env"
else
    echo "New configuration has errors - not applying"
    exit 1
fi
```

### Continuous Monitoring
```bash
#!/bin/bash
# Periodic configuration validation

CONFIG_FILE="$BASE_DIR/config/health-monitor.env"
LAST_VALIDATION="$BASE_DIR/data/.last_config_validation"

# Check if config file was modified
if [[ "$CONFIG_FILE" -nt "$LAST_VALIDATION" ]]; then
    echo "Configuration file modified - validating..."
    
    if ./tools/config/validate_config.sh "$CONFIG_FILE"; then
        touch "$LAST_VALIDATION"
        echo "Configuration validation passed"
    else
        echo "Configuration validation failed - check logs"
        # Send alert or take corrective action
    fi
fi
```

## 🔧 Configuration File Format

The validation tool expects configuration files in the following format:

```bash
# Comments start with #
VARIABLE=value
ANOTHER_VARIABLE="quoted value with spaces"

# Sections can be organized with comments
# ==============================================================================
# 🌡️ SENSOR MONITORING (DHT11)
# ==============================================================================
TEMP_WARNING=40.0
TEMP_ERROR=45.0
```

## 🚨 Common Validation Issues

### DHT11 Pin Issues
- **Error**: "DHT11_PIN must be between 0-27"
- **Solution**: Use a valid GPIO pin number
- **Recommended**: GPIO 17, 4, 18, 22, 23, 24, 25, or 27

### Temperature Threshold Issues
- **Error**: "CPU_TEMP_WARN must be less than CPU_TEMP_ERROR"
- **Solution**: Ensure warning threshold is lower than error threshold
- **Example**: `CPU_TEMP_WARN=65.0`, `CPU_TEMP_ERROR=75.0`

### LED Pin Conflicts
- **Error**: "LED pins must be unique"
- **Solution**: Use different GPIO pins for each LED color
- **Example**: `LED_RED_PIN=27`, `LED_GREEN_PIN=22`, `LED_BLUE_PIN=5`

### Network Configuration Issues
- **Error**: "PING_TARGET is not a valid IP address"
- **Solution**: Use valid IP address or hostname
- **Example**: `PING_TARGET=8.8.8.8` or `PING_TARGET=google.com`

## 📚 Additional Information

For detailed configuration options, see:
- **[Main Configuration](../../config/health-monitor.env)** - Complete configuration file with comments
- **[Hardware Configuration](../../docs/hardware-guide.md)** - Hardware-specific configuration
- **[Security Configuration](../../docs/security-guide.md)** - Security-related configuration

## 🔍 Troubleshooting

### Validation Fails with No Errors
- **Issue**: Configuration file has syntax errors
- **Solution**: Check for missing quotes, special characters
- **Command**: `bash -n config/health-monitor.env` to check syntax

### Permission Errors
- **Issue**: Cannot read configuration file
- **Solution**: Check file permissions
- **Command**: `chmod 644 config/health-monitor.env`

### Missing Variables
- **Issue**: Required variables not defined
- **Solution**: Copy from template and customize
- **Command**: `cp config/health-monitor.env.template config/health-monitor.env`

---

*Configuration validation ensures system reliability and prevents startup failures.*
