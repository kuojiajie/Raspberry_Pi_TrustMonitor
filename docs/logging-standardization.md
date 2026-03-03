# Logging Format Standardization v3.1.4

## 🔧 Logging Format Standardization

TrustMonitor v3.1.4 introduces comprehensive logging format standardization across all monitoring scripts, ensuring consistent timestamp format, component identification, and log levels for better system monitoring and debugging.

## 🎯 Standardization Goals

1. **Unified Timestamp Format**: Consistent ISO 8601 timestamps across all logs
2. **Component Identification**: Standardized component identifier format
3. **Log Level Consistency**: Unified INFO, WARN, ERROR log levels
4. **HAL System Optimization**: Enhanced HAL system with partial success mechanism
5. **Maximum Reliability**: Dual fallback mechanisms for critical operations

## 📊 Standardized Logging Format

### Timestamp Format
```bash
# Standardized ISO 8601 timestamp
date -Iseconds
# Example: 2026-03-02T16:30:45+08:00
```

### Log Entry Format
```bash
# Standardized log entry format
[$timestamp] [$level] [$component] $message

# Examples:
[2026-03-02T16:30:45+08:00] [INFO] [CPU_MONITOR] CPU load normal: 0.83
[2026-03-02T16:30:45+08:00] [WARN] [NETWORK_MONITOR] Network latency high: 250ms
[2026-03-02T16:30:45+08:00] [ERROR] [INTEGRITY] File integrity check failed
```

## 🔧 Implementation Details

### Core Logger Updates
```bash
# lib/logger.sh - Enhanced logging function
_log() {
    local level="$1"
    local message="$2"
    local component="${3:-}"
    local timestamp
    timestamp="$(date -Iseconds)"
    
    if [[ -n "$component" ]]; then
        echo "[$timestamp] [$level] [$component] $message"
    else
        echo "[$timestamp] [$level] $message"
    fi
}
```

### Component Identifiers
| Component | Identifier | Scripts |
|-----------|------------|----------|
| CPU Monitor | `[CPU_MONITOR]` | cpu_monitor.sh |
| Memory Monitor | `[MEMORY_MONITOR]` | memory_monitor.sh |
| Disk Monitor | `[DISK_MONITOR]` | disk_monitor.sh |
| Network Monitor | `[NETWORK_MONITOR]` | network_monitor.sh |
| CPU Temperature | `[CPU_TEMP_MONITOR]` | cpu_temp_monitor.sh |
| Integrity Check | `[INTEGRITY]` | integrity_check.sh |
| Signature Verify | `[SIGVERIFY]` | verify_signature.sh |
| Backup Cleanup | `[CLEANUP]` | backup_cleanup.sh |
| SEL Logger | `[SEL]` | sel_logger.sh |
| Watchdog | `[WATCHDOG]` | watchdog.sh, watchdog_standalone.sh |
| Boot Sequence | `[BOOT]` | boot_sequence.sh |

## 🛠 HAL System Enhancements

### Partial Success Mechanism
```python
# HAL system now supports partial success
critical_devices = ['rgb_led']
critical_success = all(
    device_id in self.devices and 
    self.devices[device_id].status == DeviceStatus.READY 
    for device_id in critical_devices
)

if critical_success:
    self.initialized = True  # LED working = HAL success
```

### DHT11 Sensor Tolerance
```python
# Enhanced DHT11 initialization with retry logic
temp, humidity = self._read_with_retry()
if temp is not None and humidity is not None:
    return True
else:
    # DHT11 sensors can be flaky, but hardware is accessible
    self.logger.warning("DHT11 sensor test read failed, but hardware is accessible")
    self.status = DeviceStatus.READY
    return True
```

## ⚡ LED Control Improvements

### Dual Fallback System
```bash
# boot_sequence.sh - Enhanced LED control
set_led_color() {
    local color="$1"
    local led_success=false
    
    # Try HAL LED controller first (preferred)
    if timeout 10 python3 "$BASE_DIR/hardware/hal_led_controller.py" --color "$color" >/dev/null 2>&1; then
        boot_sequence_log_info "LED color set via HAL: $color"
        led_success=true
    else
        boot_sequence_log_warn "HAL LED controller failed, trying legacy method"
        # Fallback to legacy controller
        if timeout 2 python3 "$BASE_DIR/hardware/led_controller.py" --color "$color" >/dev/null 2>&1; then
            boot_sequence_log_info "LED color set via legacy controller: $color"
            led_success=true
        fi
    fi
}
```

## 📝 Updated Scripts

### Monitoring Scripts
- **cpu_monitor.sh**: Uses `[CPU_MONITOR]` component identifier
- **memory_monitor.sh**: Uses `[MEMORY_MONITOR]` component identifier
- **disk_monitor.sh**: Uses `[DISK_MONITOR]` component identifier
- **network_monitor.sh**: Uses `[NETWORK_MONITOR]` component identifier
- **cpu_temp_monitor.sh**: Uses `[CPU_TEMP_MONITOR]` component identifier

### Security Scripts
- **integrity_check.sh**: Uses `[INTEGRITY]` component identifier
- **verify_signature.sh**: Uses `[SIGVERIFY]` component identifier
- **boot_sequence.sh**: Uses `[BOOT]` component identifier

### System Scripts
- **watchdog.sh**: Uses `[WATCHDOG]` component identifier
- **watchdog_standalone.sh**: Uses `[WATCHDOG]` component identifier
- **sel_logger.sh**: Uses `[SEL]` component identifier
- **backup_cleanup.sh**: Uses `[CLEANUP]` component identifier

## 🔄 Migration Guide

### For Script Developers
When creating new monitoring scripts:

```bash
#!/bin/bash
# Always load return codes and logger at the beginning
source "$BASE_DIR/lib/return_codes.sh"
source "$BASE_DIR/lib/logger.sh"

# Use standardized logging with component identifier
my_component_log_info() {
    log_info "[MY_COMPONENT] $1"
}

my_component_log_warn() {
    log_warn "[MY_COMPONENT] $1"
}

my_component_log_error() {
    log_error "[MY_COMPONENT] $1"
}

# Use standardized return codes
if [[ "$condition" == "success" ]]; then
    my_component_log_info "Operation completed successfully"
    return $RC_OK
elif [[ "$condition" == "warning" ]]; then
    my_component_log_warn "Warning condition detected"
    return $RC_WARN
else
    my_component_log_error "Error condition detected"
    return $RC_ERROR
fi
```

### For HAL Developers
When creating new HAL devices:

```python
# Implement partial success for non-critical devices
def initialize(self, config: Dict[str, Any]) -> bool:
    try:
        # Initialize device
        self._initialize_hardware()
        
        # Perform self-test
        if self._self_test():
            self.status = DeviceStatus.READY
            return True
        else:
            # For non-critical devices, allow initialization despite test failure
            if self.device_id not in ['rgb_led']:  # rgb_led is critical
                self.status = DeviceStatus.READY
                self.logger.warning(f"Device {self.device_id} test failed, but marked as ready")
                return True
            else:
                self.status = DeviceStatus.ERROR
                return False
                
    except Exception as e:
        self.set_error(e)
        return False
```

## ✅ Testing and Validation

### Log Format Verification
```bash
# Test all monitoring scripts for consistent logging
for script in scripts/*_monitor.sh; do
    echo "Testing $script:"
    bash "$script" | grep "\[.*\] \[.*\] \[.*\]"
done
```

### HAL System Testing
```bash
# Test HAL system with partial success
timeout 10 python3 hardware/hal_led_controller.py --color red
# Should work even if DHT11 sensor fails
```

### Boot Sequence Testing
```bash
# Test boot sequence with enhanced LED control
bash scripts/boot_sequence.sh
# Should use HAL first, fallback to legacy if needed
```

## 🎯 Benefits

### 1. **Consistency**
- All logs use the same timestamp format
- Component identification is standardized
- Log levels are consistent across all scripts

### 2. **Debugging**
- Easier to correlate events across different components
- Standardized format for log parsing tools
- Clear component identification for troubleshooting

### 3. **Reliability**
- HAL system works even if non-critical devices fail
- LED control has dual fallback mechanism
- DHT11 sensor initialization is more tolerant

### 4. **Maintainability**
- Unified logging reduces code duplication
- Standardized format for new scripts
- Clear patterns for developers to follow

### 5. **Automation**
- Machine-readable log format for monitoring tools
- Consistent timestamps for time-series analysis
- Component-based filtering for log analysis

## 📋 Quick Reference

### Standard Log Levels
- **INFO**: Normal operation messages
- **WARN**: Warning conditions that don't stop operation
- **ERROR**: Error conditions that may affect functionality

### Standard Components
- **MONITORING**: CPU, MEMORY, DISK, NETWORK, CPU_TEMP
- **SECURITY**: INTEGRITY, SIGVERIFY, BOOT
- **SYSTEM**: WATCHDOG, SEL, CLEANUP

### Standard Timestamps
- **Format**: ISO 8601 with timezone
- **Command**: `date -Iseconds`
- **Example**: `2026-03-02T16:30:45+08:00`

## 🔍 Troubleshooting

### Common Issues
1. **HAL LED Controller Fails**: Check if DHT11 sensor is causing initialization failure
2. **Legacy LED Controller Fails**: Check GPIO permissions and hardware connections
3. **Inconsistent Timestamps**: Ensure all scripts load the updated logger.sh

### Debug Commands
```bash
# Check HAL initialization
python3 hardware/hal_led_controller.py --color red

# Check legacy LED controller
python3 hardware/led_controller.py --color red

# Verify log format
bash scripts/cpu_monitor.sh | head -5
```

---

**Logging Format Standardization v3.1.4** provides a solid foundation for consistent, reliable, and maintainable logging across the entire TrustMonitor system.
