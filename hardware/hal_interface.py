#!/usr/bin/env python3
"""
TrustMonitor Hardware Abstraction Layer (HAL) Interface
========================================================

Main HAL interface module that provides unified access to all hardware components.
This module serves as the primary entry point for hardware operations.

Features:
- Unified hardware interface
- Device registration and management
- Configuration management
- Error handling and logging
- Backward compatibility with existing code
"""

import logging
import sys
import os
from typing import Dict, Any, Optional, List, Tuple
from datetime import datetime

# Add current directory to path for imports
current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.insert(0, current_dir)

from hal_core import (
    get_hal_manager, initialize_hal, cleanup_hal,
    IHALDevice, IHALSensor, IHALIndicator,
    DeviceStatus, DeviceType, HALError
)
from hal_sensors import create_dht11_sensor, DHT11Sensor
from hal_indicators import create_rgb_led, RGBLEDIndicator, LEDColor, LEDState

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger('TrustMonitor.HAL')

class TrustMonitorHAL:
    """Main TrustMonitor HAL interface"""
    
    def __init__(self):
        self.hal_manager = get_hal_manager()
        self.initialized = False
        self.devices = {}
        self.logger = logger
        
    def initialize(self, config: Dict[str, Any] = None) -> bool:
        """Initialize HAL system with devices"""
        try:
            self.logger.info("Initializing TrustMonitor HAL...")
            
            # Default configuration
            default_config = {
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
                    'frequencies': {
                        'red': 2000,
                        'green': 1999,
                        'blue': 5000
                    },
                    'brightness': 100
                }
            }
            
            # Merge with provided config
            if config:
                for device_id, device_config in config.items():
                    if device_id in default_config:
                        default_config[device_id].update(device_config)
                    else:
                        default_config[device_id] = device_config
                        
            # Create and register devices
            self._register_default_devices(default_config)
            
            # Initialize all devices
            success = self.hal_manager.initialize_all(default_config)
            
            if success:
                self.initialized = True
                self.logger.info("TrustMonitor HAL initialized successfully")
            else:
                self.logger.error("TrustMonitor HAL initialization failed")
                
            return success
            
        except Exception as e:
            self.logger.error(f"HAL initialization error: {e}")
            return False
            
    def _register_default_devices(self, config: Dict[str, Any]) -> None:
        """Register default devices"""
        try:
            # Register DHT11 sensor
            if 'dht11_sensor' in config:
                dht11 = create_dht11_sensor('dht11_sensor')
                dht11.set_config(config['dht11_sensor'])
                self.hal_manager.register_device(dht11)
                self.devices['dht11_sensor'] = dht11
                
            # Register RGB LED
            if 'rgb_led' in config:
                rgb_led = create_rgb_led('rgb_led')
                rgb_led.set_config(config['rgb_led'])
                self.hal_manager.register_device(rgb_led)
                self.devices['rgb_led'] = rgb_led
                
        except Exception as e:
            self.logger.error(f"Failed to register default devices: {e}")
            
    def cleanup(self) -> bool:
        """Cleanup HAL system"""
        try:
            success = self.hal_manager.cleanup_all()
            self.initialized = False
            self.devices.clear()
            return success
        except Exception as e:
            self.logger.error(f"HAL cleanup error: {e}")
            return False
            
    def get_sensor_values(self, sensor_id: str = None) -> Dict[str, Dict[str, float]]:
        """Get sensor values"""
        try:
            if not self.initialized:
                self.logger.error("HAL not initialized")
                return {}
                
            if sensor_id:
                device = self.hal_manager.get_device(sensor_id)
                if device and isinstance(device, IHALSensor):
                    values = device.read_values()
                    return {sensor_id: values} if values else {}
                else:
                    self.logger.warning(f"Sensor {sensor_id} not found or not a sensor")
                    return {}
            else:
                # Get all sensor values
                results = {}
                for device_id, device in self.devices.items():
                    if isinstance(device, IHALSensor):
                        values = device.read_values()
                        if values:
                            results[device_id] = values
                return results
                
        except Exception as e:
            self.logger.error(f"Failed to get sensor values: {e}")
            return {}
            
    def set_indicator_state(self, indicator_id: str, state: str, **kwargs) -> bool:
        """Set indicator state"""
        try:
            if not self.initialized:
                self.logger.error("HAL not initialized")
                return False
                
            device = self.hal_manager.get_device(indicator_id)
            if device and isinstance(device, IHALIndicator):
                return device.set_state(state, **kwargs)
            else:
                self.logger.warning(f"Indicator {indicator_id} not found or not an indicator")
                return False
                
        except Exception as e:
            self.logger.error(f"Failed to set indicator state: {e}")
            return False
            
    def clear_all_indicators(self) -> bool:
        """Clear all indicators"""
        try:
            if not self.initialized:
                self.logger.error("HAL not initialized")
                return False
                
            success = True
            for device_id, device in self.devices.items():
                if isinstance(device, IHALIndicator):
                    if not device.clear():
                        success = False
                        
            return success
            
        except Exception as e:
            self.logger.error(f"Failed to clear indicators: {e}")
            return False
            
    def get_device_status(self, device_id: str = None) -> Dict[str, DeviceStatus]:
        """Get device status"""
        try:
            if not self.initialized:
                self.logger.error("HAL not initialized")
                return {}
                
            if device_id:
                device = self.hal_manager.get_device(device_id)
                if device:
                    return {device_id: device.get_status()}
                else:
                    return {}
            else:
                return self.hal_manager.get_all_status()
                
        except Exception as e:
            self.logger.error(f"Failed to get device status: {e}")
            return {}
            
    def run_self_tests(self) -> Dict[str, bool]:
        """Run self-tests on all devices"""
        try:
            if not self.initialized:
                self.logger.error("HAL not initialized")
                return {}
                
            return self.hal_manager.run_self_tests()
            
        except Exception as e:
            self.logger.error(f"Failed to run self-tests: {e}")
            return {}
            
    def list_devices(self) -> Dict[str, Dict[str, Any]]:
        """List all devices"""
        try:
            return self.hal_manager.list_devices()
        except Exception as e:
            self.logger.error(f"Failed to list devices: {e}")
            return {}

# Global HAL instance
_hal_instance = None

def get_hal() -> TrustMonitorHAL:
    """Get global HAL instance"""
    global _hal_instance
    if _hal_instance is None:
        _hal_instance = TrustMonitorHAL()
    return _hal_instance

def initialize_hardware(config: Dict[str, Any] = None) -> bool:
    """Initialize hardware system"""
    hal = get_hal()
    return hal.initialize(config)

def cleanup_hardware() -> bool:
    """Cleanup hardware system"""
    hal = get_hal()
    return hal.cleanup()

# Backward compatibility functions
def read_sensor_values(sensor_id: str = None) -> Dict[str, Dict[str, float]]:
    """Read sensor values (backward compatibility)"""
    hal = get_hal()
    return hal.get_sensor_values(sensor_id)

def set_led_color(color: str, brightness: int = 100) -> bool:
    """Set LED color (backward compatibility)"""
    hal = get_hal()
    return hal.set_indicator_state('rgb_led', 'on', color=color, brightness=brightness)

def blink_led_color(color: str, times: int = 3, speed: float = 0.5) -> bool:
    """Blink LED color (backward compatibility)"""
    hal = get_hal()
    return hal.set_indicator_state('rgb_led', 'blinking', color=color, times=times, speed=speed)

def turn_off_led() -> bool:
    """Turn off LED (backward compatibility)"""
    hal = get_hal()
    return hal.set_indicator_state('rgb_led', 'off')

def get_device_statuses() -> Dict[str, DeviceStatus]:
    """Get all device statuses (backward compatibility)"""
    hal = get_hal()
    return hal.get_device_status()
