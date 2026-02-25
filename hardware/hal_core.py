#!/usr/bin/env python3
"""
TrustMonitor Hardware Abstraction Layer (HAL)
==============================================

Provides unified hardware abstraction interface for all hardware components.
This layer separates hardware-specific implementation from business logic.

Features:
- Unified hardware interface
- Device lifecycle management
- Error handling and recovery
- Resource cleanup and management
- Configuration management
"""

from abc import ABC, abstractmethod
from typing import Dict, Any, Optional, Tuple
from enum import Enum
import logging
import time
from datetime import datetime

# Configure HAL logging
hal_logger = logging.getLogger('TrustMonitor.HAL')
hal_logger.setLevel(logging.INFO)

class DeviceStatus(Enum):
    """Device status enumeration"""
    UNINITIALIZED = 'uninitialized'
    INITIALIZED = 'initialized'
    READY = 'ready'
    ERROR = 'error'
    DISABLED = 'disabled'

class DeviceType(Enum):
    """Device type enumeration"""
    SENSOR = 'sensor'
    ACTUATOR = 'actuator'
    INDICATOR = 'indicator'
    COMMUNICATION = 'communication'

class HALError(Exception):
    """Base HAL exception"""
    pass

class DeviceNotInitializedError(HALError):
    """Device not initialized exception"""
    pass

class DeviceOperationError(HALError):
    """Device operation exception"""
    pass

class DeviceConfigError(HALError):
    """Device configuration exception"""
    pass

class IHALDevice(ABC):
    """Base interface for all HAL devices"""
    
    def __init__(self, device_id: str, device_type: DeviceType):
        self.device_id = device_id
        self.device_type = device_type
        self.status = DeviceStatus.UNINITIALIZED
        self.config = {}
        self.last_error = None
        self.logger = logging.getLogger(f'TrustMonitor.HAL.{device_id}')
        
    @abstractmethod
    def initialize(self, config: Dict[str, Any] = None) -> bool:
        """Initialize device with configuration"""
        pass
        
    @abstractmethod
    def cleanup(self) -> bool:
        """Clean up device resources"""
        pass
        
    @abstractmethod
    def self_test(self) -> bool:
        """Perform device self-test"""
        pass
        
    @abstractmethod
    def get_status(self) -> DeviceStatus:
        """Get current device status"""
        pass
        
    def set_config(self, config: Dict[str, Any]) -> None:
        """Set device configuration"""
        self.config.update(config)
        
    def get_config(self, key: str = None) -> Any:
        """Get device configuration"""
        if key:
            return self.config.get(key)
        return self.config.copy()
        
    def set_error(self, error: Exception) -> None:
        """Set device error state"""
        self.last_error = error
        self.status = DeviceStatus.ERROR
        self.logger.error(f"Device {self.device_id} error: {error}")

class IHALSensor(IHALDevice):
    """Interface for sensor devices"""
    
    @abstractmethod
    def read_value(self, sensor_type: str) -> Optional[float]:
        """Read sensor value"""
        pass
        
    @abstractmethod
    def read_values(self) -> Dict[str, float]:
        """Read all sensor values"""
        pass
        
    @abstractmethod
    def get_unit(self, sensor_type: str) -> str:
        """Get sensor unit"""
        pass

class IHALIndicator(IHALDevice):
    """Interface for indicator devices (LEDs, displays)"""
    
    @abstractmethod
    def set_state(self, state: str, **kwargs) -> bool:
        """Set indicator state"""
        pass
        
    @abstractmethod
    def get_state(self) -> str:
        """Get current indicator state"""
        pass
        
    @abstractmethod
    def clear(self) -> bool:
        """Clear indicator"""
        pass

class HALManager:
    """Hardware Abstraction Layer Manager"""
    
    def __init__(self):
        self.devices: Dict[str, IHALDevice] = {}
        self.logger = logging.getLogger('TrustMonitor.HAL.Manager')
        self.initialized = False
        
    def register_device(self, device: IHALDevice) -> bool:
        """Register a device with HAL"""
        try:
            if device.device_id in self.devices:
                self.logger.warning(f"Device {device.device_id} already registered, replacing")
                
            self.devices[device.device_id] = device
            self.logger.info(f"Device {device.device_id} registered successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to register device {device.device_id}: {e}")
            return False
            
    def unregister_device(self, device_id: str) -> bool:
        """Unregister a device from HAL"""
        try:
            if device_id in self.devices:
                device = self.devices[device_id]
                device.cleanup()
                del self.devices[device_id]
                self.logger.info(f"Device {device_id} unregistered successfully")
                return True
            else:
                self.logger.warning(f"Device {device_id} not found for unregistration")
                return False
                
        except Exception as e:
            self.logger.error(f"Failed to unregister device {device_id}: {e}")
            return False
            
    def get_device(self, device_id: str) -> Optional[IHALDevice]:
        """Get device by ID"""
        return self.devices.get(device_id)
        
    def initialize_all(self, global_config: Dict[str, Any] = None) -> bool:
        """Initialize all registered devices"""
        try:
            self.logger.info("Initializing all HAL devices...")
            
            success_count = 0
            total_count = len(self.devices)
            
            for device_id, device in self.devices.items():
                try:
                    device_config = global_config.get(device_id, {}) if global_config else {}
                    if device.initialize(device_config):
                        success_count += 1
                        self.logger.info(f"Device {device_id} initialized successfully")
                    else:
                        self.logger.error(f"Device {device_id} initialization failed")
                        
                except Exception as e:
                    self.logger.error(f"Device {device_id} initialization error: {e}")
                    device.set_error(e)
                    
            self.initialized = success_count == total_count
            self.logger.info(f"HAL initialization complete: {success_count}/{total_count} devices ready")
            
            return self.initialized
            
        except Exception as e:
            self.logger.error(f"HAL initialization failed: {e}")
            return False
            
    def cleanup_all(self) -> bool:
        """Clean up all registered devices"""
        try:
            self.logger.info("Cleaning up all HAL devices...")
            
            success_count = 0
            total_count = len(self.devices)
            
            for device_id, device in self.devices.items():
                try:
                    if device.cleanup():
                        success_count += 1
                        self.logger.info(f"Device {device_id} cleanup successful")
                    else:
                        self.logger.warning(f"Device {device_id} cleanup failed")
                        
                except Exception as e:
                    self.logger.error(f"Device {device_id} cleanup error: {e}")
                    
            self.initialized = False
            self.logger.info(f"HAL cleanup complete: {success_count}/{total_count} devices cleaned up")
            
            return True
            
        except Exception as e:
            self.logger.error(f"HAL cleanup failed: {e}")
            return False
            
    def get_device_status(self, device_id: str) -> Optional[DeviceStatus]:
        """Get device status"""
        device = self.get_device(device_id)
        return device.get_status() if device else None
        
    def get_all_status(self) -> Dict[str, DeviceStatus]:
        """Get all device statuses"""
        return {device_id: device.get_status() for device_id, device in self.devices.items()}
        
    def run_self_tests(self) -> Dict[str, bool]:
        """Run self-tests on all devices"""
        results = {}
        
        for device_id, device in self.devices.items():
            try:
                results[device_id] = device.self_test()
                if results[device_id]:
                    self.logger.info(f"Device {device_id} self-test passed")
                else:
                    self.logger.warning(f"Device {device_id} self-test failed")
                    
            except Exception as e:
                self.logger.error(f"Device {device_id} self-test error: {e}")
                results[device_id] = False
                
        return results
        
    def list_devices(self) -> Dict[str, Dict[str, Any]]:
        """List all registered devices with their info"""
        device_info = {}
        
        for device_id, device in self.devices.items():
            device_info[device_id] = {
                'type': device.device_type.value,
                'status': device.status.value,
                'config': device.get_config(),
                'last_error': str(device.last_error) if device.last_error else None
            }
            
        return device_info

# Global HAL Manager instance
hal_manager = HALManager()

def get_hal_manager() -> HALManager:
    """Get global HAL manager instance"""
    return hal_manager

def initialize_hal(global_config: Dict[str, Any] = None) -> bool:
    """Initialize HAL system"""
    return hal_manager.initialize_all(global_config)

def cleanup_hal() -> bool:
    """Cleanup HAL system"""
    return hal_manager.cleanup_all()
