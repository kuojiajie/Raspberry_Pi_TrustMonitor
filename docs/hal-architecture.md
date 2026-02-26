# TrustMonitor HAL System Architecture

## 🏗️ Hardware Abstraction Layer (HAL) Overview

The TrustMonitor HAL (Hardware Abstraction Layer) is a modern hardware interface system introduced in v2.2.6 that provides unified access to all hardware components while maintaining backward compatibility with existing legacy systems.

## 📋 HAL System Components

### Core Modules

#### `hardware/hal_core.py`
- **Purpose**: Core HAL infrastructure and base classes
- **Key Classes**: `IHALDevice`, `IHALSensor`, `IHALIndicator`, `DeviceStatus`, `DeviceType`
- **Features**: Device lifecycle management, error handling, configuration management

#### `hardware/hal_interface.py`
- **Purpose**: Main HAL interface and entry point
- **Key Functions**: `get_hal()`, `initialize_hardware()`, `cleanup_hardware()`
- **Features**: Unified hardware access, device registration, system initialization

#### `hardware/hal_sensors.py`
- **Purpose**: HAL sensor implementations
- **Key Classes**: `DHT11Sensor`, `SensorConfig`
- **Features**: DHT11 temperature/humidity sensor with retry logic

#### `hardware/hal_indicators.py`
- **Purpose**: HAL indicator implementations
- **Key Classes**: `RGBLED`, `LEDColor`, `LEDState`
- **Features**: RGB LED control with PWM, status-based color management

#### `hardware/hal_sensor_monitor.py`
- **Purpose**: HAL-based sensor monitoring service
- **Key Classes**: `HALSensorMonitor`
- **Features**: Unified sensor monitoring, configuration management, status determination

#### `hardware/hal_led_controller.py`
- **Purpose**: HAL-based LED control service
- **Key Classes**: `HALLEDController`
- **Features**: LED color control, status management, hardware abstraction

## 🔄 HAL vs Legacy System Integration

### System Selection Logic
The system automatically selects between HAL and Legacy systems based on availability:

```bash
# Priority: HAL (v2.2.6+) → Legacy → Skip functionality
if [[ -f "$HARDWARE_DIR/hal_*.py" ]]; then
    # Use HAL system
else
    # Fallback to Legacy system
fi
```

### HAL Advantages
- **Unified Interface**: Consistent API across all hardware components
- **Better Error Handling**: Comprehensive error recovery and reporting
- **Self-Test Capabilities**: Automatic hardware validation
- **Device Management**: Centralized device lifecycle management
- **Configuration Management**: Unified configuration system

### Legacy System Limitations
- **Fragmented Interface**: Different APIs for different components
- **Basic Error Handling**: Limited error recovery mechanisms
- **No Self-Tests**: No automatic hardware validation
- **Manual Device Management**: Each component manages its own hardware
- **Configuration Scattered**: Configuration spread across multiple files

## 🔧 HAL System Initialization

### Initialization Sequence
1. **HAL Manager Creation**: Create central HAL manager instance
2. **Device Registration**: Register all available devices (sensors, indicators)
3. **Device Initialization**: Initialize each device with configuration
4. **Self-Test Execution**: Run device self-tests to verify functionality
5. **Status Reporting**: Report device status and any issues

### Configuration Management
```python
# Example HAL configuration
hal_config = {
    'dht11_sensor': {
        'pin': 'D17',
        'max_retries': 3,
        'retry_delay': 2.0
    },
    'rgb_led': {
        'pins': {
            'red': 27,
            'green': 22,
            'blue': 5
        },
        'frequencies': {
            'red': 2000,
            'green': 1999,
            'blue': 5000
        }
    }
}
```

## 🚨 Known Issues and Solutions

### PWM/GPIO Conflicts
**Problem**: HAL and Legacy systems both use the same GPIO pins (27, 22, 5) for RGB LED control, causing PWM conflicts.

**Solution**: 
- Use GPIO cleanup before testing: `./tools/dev/cleanup_gpio.sh`
- Tests include automatic cleanup (v2.2.7+)
- Only one system should be active at a time

### Device Initialization Failures
**Problem**: HAL devices may fail initialization due to hardware issues or configuration problems.

**Solution**:
- Check environment: `./tools/dev/check_hal_env.sh`
- Verify GPIO permissions: `groups $USER` should include `gpio`
- Run hardware tests: `./tools/dev/test_hardware_functionality.sh`

### Simulation Mode
**Problem**: On systems without actual hardware, HAL runs in simulation mode.

**Solution**:
- Simulation mode is automatic and normal
- All functionality works in simulation mode
- Use for development and testing on non-Pi systems

## 📚 Development Guidelines

### Adding New HAL Devices
1. **Create Device Class**: Inherit from appropriate base class (`IHALSensor`, `IHALIndicator`)
2. **Implement Required Methods**: `initialize()`, `cleanup()`, `get_status()`, `self_test()`
3. **Add to HAL Manager**: Register device in HAL manager
4. **Add Configuration**: Update configuration schema
5. **Add Tests**: Create comprehensive tests for new device

### HAL Device Best Practices
- **Error Handling**: Use proper exception handling and logging
- **Resource Management**: Ensure proper cleanup in `cleanup()` method
- **Self-Tests**: Implement meaningful self-tests that verify functionality
- **Configuration**: Support flexible configuration with sensible defaults
- **Logging**: Use structured logging with appropriate levels

## 🔄 Migration Path

### From Legacy to HAL
1. **Identify Legacy Code**: Find code using `hardware/led_controller.py` or `hardware/sensor_monitor.py`
2. **Replace with HAL**: Use `hardware/hal_*` equivalents
3. **Update Configuration**: Use HAL configuration format
4. **Test Thoroughly**: Use HAL test suite to verify functionality
5. **Remove Dependencies**: Remove dependencies on legacy modules

### Backward Compatibility
- Legacy modules remain available and marked as DEPRECATED
- System automatically falls back to legacy if HAL is unavailable
- No breaking changes for existing code
- Gradual migration path available

## 📊 HAL System Statistics

### Test Coverage
- **HAL Core Tests**: 15/15 tests passing
- **HAL Refactor Tests**: 15/15 tests passing
- **Hardware Functionality Tests**: 23/23 tests passing
- **System Integration Tests**: 6/6 tests passing

### Performance
- **Initialization Time**: ~2-3 seconds (including self-tests)
- **Memory Usage**: Minimal overhead compared to legacy system
- **Response Time**: Comparable to legacy system
- **Error Recovery**: Significantly improved over legacy system

## 🔮 Future HAL Development

### Planned Enhancements
- **Additional Sensors**: Support for more sensor types (pressure, light, etc.)
- **Network Devices**: HAL abstraction for network interfaces
- **Storage Devices**: HAL abstraction for storage monitoring
- **Power Management**: HAL abstraction for power consumption monitoring

### Architecture Improvements
- **Plugin System**: Dynamic device loading
- **Hot-Swap Support**: Add/remove devices without restart
- **Remote HAL**: Network-accessible HAL interfaces
- **Configuration Validation**: Schema-based configuration validation

---

*This document provides a comprehensive overview of the TrustMonitor HAL system. For implementation details, see the individual module documentation and code comments.*
