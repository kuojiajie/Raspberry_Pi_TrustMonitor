# Hardware Abstraction Layer (HAL) Documentation

## 📋 Overview

The Hardware Abstraction Layer (HAL) is a unified interface system introduced in v2.2.6 that provides standardized APIs for hardware components while maintaining full backward compatibility with existing code.

## 🏗️ Architecture

### Core Components

#### 1. HAL Core (`hardware/hal_core.py`)
- **IHALDevice**: Abstract base class for all hardware devices
- **IHALSensor**: Abstract base class for sensor devices
- **IHALIndicator**: Abstract base class for indicator devices
- **HALManager**: Central device management system

#### 2. HAL Components
- **DHT11 Sensor** (`hardware/hal_sensors.py`): Temperature and humidity sensor implementation
- **RGB LED** (`hardware/hal_indicators.py`): LED indicator implementation
- **HAL Interface** (`hardware/hal_interface.py`): Main integration layer

#### 3. HAL Refactored Modules
- **HAL Sensor Monitor** (`hardware/hal_sensor_monitor.py`): Refactored sensor monitoring
- **HAL LED Controller** (`hardware/hal_led_controller.py`): Refactored LED control

## 🔧 Usage

### Basic HAL Usage

```python
from hardware.hal_interface import get_hal

# Initialize HAL
hal = get_hal()
config = {
    'dht11_sensor': {'pin': 'D17', 'max_retries': 3},
    'rgb_led': {'pins': {'red': 27, 'green': 22, 'blue': 5}}
}

# Initialize devices
if hal.initialize(config):
    # Read sensor values
    values = hal.get_sensor_values('dht11_sensor')
    print(f"Temperature: {values['temperature']}°C")
    print(f"Humidity: {values['humidity']}%")
    
    # Control LED
    hal.set_indicator_state('rgb_led', 'on', color='green')
    
    # Cleanup
    hal.cleanup()
```

### Legacy Compatibility

All existing code continues to work without changes:

```python
# Legacy code still works
from hardware.led_controller import LEDController
from hardware.sensor_reader import SensorReader

led = LEDController()
sensor = SensorReader()
```

## 📊 Device Management

### Device Lifecycle
1. **Registration**: Devices are registered with HAL Manager
2. **Initialization**: Devices are initialized with configuration
3. **Operation**: Devices perform their functions
4. **Cleanup**: Resources are properly released

### Configuration
```python
config = {
    'dht11_sensor': {
        'pin': 'D17',
        'max_retries': 3,
        'retry_delay': 2.0,
        'min_read_interval': 2.0
    },
    'rgb_led': {
        'pins': {
            'red': 27,
            'green': 22,
            'blue': 5
        },
        'pwm_frequency': 1000
    }
}
```

## 🧪 Testing

### HAL Core Tests
```bash
# Test HAL core functionality
bash tools/dev/test_hal_core.sh

# Test hardware functionality after HAL refactor
bash tools/dev/test_hardware_functionality.sh

# Test system hardware integration
bash tools/dev/test_system_hardware_integration.sh
```

### Individual Component Tests
```bash
# Test HAL LED controller
python3 hardware/hal_led_controller.py --color green
python3 hardware/hal_led_controller.py --blink red --times 3

# Test HAL sensor monitor
python3 hardware/hal_sensor_monitor.py --test
python3 hardware/hal_sensor_monitor.py --status
```

## 🔄 Backward Compatibility

### Legacy Module Support
- All existing hardware modules continue to work
- Legacy and HAL systems can coexist
- Gradual migration path available

### Migration Path
1. **Phase 1**: Use HAL alongside legacy modules
2. **Phase 2**: Gradually replace legacy calls with HAL calls
3. **Phase 3**: Remove legacy modules (optional)

## 🛡️ Error Handling

### Retry Logic
- Automatic retry for sensor operations
- Configurable retry attempts and delays
- Graceful degradation on hardware failure

### Simulation Mode
- Fallback simulation when hardware unavailable
- Consistent API behavior in all environments
- Development and testing support

## 📈 Performance

### Optimizations
- Centralized device management
- Efficient resource cleanup
- Reduced hardware access overhead
- Improved error recovery

### Monitoring
- Device status tracking
- Performance metrics collection
- Health monitoring integration

## 🔍 Debugging

### Logging
HAL provides comprehensive logging:
```bash
# View HAL logs
tail -f logs/hal_core_test_*.log
tail -f logs/system_hardware_integration_*.log
```

### Device Status
```python
# Check device status
status = hal.get_device_status()
print(f"Device statuses: {status}")

# Run self-tests
results = hal.run_self_tests()
print(f"Self-test results: {results}")
```

## 🚀 Future Enhancements

### Planned Features
- Additional sensor types (pressure, light, motion)
- Network device abstraction
- Advanced power management
- Device hot-swapping support

### Extensibility
- Plugin architecture for new devices
- Custom device implementations
- Third-party hardware support

---

## 📚 Related Documentation

- [Testing Guide](testing.md) - Comprehensive testing procedures
- [Return Code System](return-codes.md) - Error handling reference
- [Main README](../README.md) - Project overview and setup

---

*Last updated: v2.2.6 - HAL Refactoring*
