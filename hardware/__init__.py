#!/usr/bin/env python3
"""
TrustMonitor Hardware Module
============================

Unified entry point for hardware-related modules.
Now includes HAL (Hardware Abstraction Layer) for better hardware management.

Usage:
    # Legacy interface (backward compatible)
    from hardware import LEDController, SensorReader, SensorMonitor
    
    # New HAL interface (recommended)
    from hardware import get_hal, initialize_hardware
    from hardware import LEDColor, DeviceStatus
"""

# Legacy components (backward compatibility)
from .led_controller import LEDController
from .sensor_reader import SensorReader
from .sensor_monitor import SensorMonitor

# HAL components (new interface)
from .hal_core import (
    IHALDevice, IHALSensor, IHALIndicator,
    DeviceStatus, DeviceType,
    HALError, DeviceNotInitializedError, 
    DeviceOperationError, DeviceConfigError,
    HALManager, get_hal_manager, initialize_hal, cleanup_hal
)

from .hal_sensors import (
    DHT11Sensor, SensorManager, create_dht11_sensor
)

from .hal_indicators import (
    RGBLEDIndicator, IndicatorManager, LEDColor, LEDState, create_rgb_led
)

from .hal_interface import (
    TrustMonitorHAL, get_hal, initialize_hardware, cleanup_hardware,
    read_sensor_values, set_led_color, blink_led_color, 
    turn_off_led, get_device_statuses
)

# Version information
__version__ = '2.2.6'
__hal_version__ = '2.2.6'

__all__ = [
    # Legacy components
    'LEDController', 'SensorReader', 'SensorMonitor',
    
    # HAL core
    'IHALDevice', 'IHALSensor', 'IHALIndicator',
    'DeviceStatus', 'DeviceType',
    'HALError', 'DeviceNotInitializedError', 
    'DeviceOperationError', 'DeviceConfigError',
    'HALManager', 'get_hal_manager', 'initialize_hal', 'cleanup_hal',
    
    # HAL sensors
    'DHT11Sensor', 'SensorManager', 'create_dht11_sensor',
    
    # HAL indicators
    'RGBLEDIndicator', 'IndicatorManager', 'LEDColor', 'LEDState', 'create_rgb_led',
    
    # HAL interface
    'TrustMonitorHAL', 'get_hal', 'initialize_hardware', 'cleanup_hardware',
    
    # Backward compatibility functions
    'read_sensor_values', 'set_led_color', 'blink_led_color', 
    'turn_off_led', 'get_device_statuses'
]

def get_hardware_info():
    """Get hardware module information"""
    return {
        'version': __version__,
        'hal_version': __hal_version__,
        'legacy_components': ['LEDController', 'SensorReader', 'SensorMonitor'],
        'hal_components': ['DHT11Sensor', 'RGBLEDIndicator', 'HALManager'],
        'interfaces': ['legacy', 'hal']
    }