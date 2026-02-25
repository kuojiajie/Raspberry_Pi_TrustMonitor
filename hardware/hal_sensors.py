#!/usr/bin/env python3
"""
TrustMonitor HAL Sensor Devices
================================

HAL implementations for sensor devices including DHT11 temperature/humidity sensor.
Provides standardized sensor interface with error handling and retry logic.

Features:
- DHT11 temperature/humidity sensor
- Retry mechanism for reliable readings
- Error handling and status reporting
- Configuration management
"""

from typing import Dict, Any, Optional, Tuple
import time
import logging
from datetime import datetime

try:
    import board
    import adafruit_dht
    DHT_AVAILABLE = True
except ImportError:
    DHT_AVAILABLE = False
    print("WARNING: DHT libraries not available, sensor will run in simulation mode")

from hal_core import IHALSensor, DeviceStatus, DeviceType, HALError, DeviceOperationError

class DHT11Sensor(IHALSensor):
    """HAL implementation for DHT11 temperature/humidity sensor"""
    
    def __init__(self, device_id: str = "dht11_sensor"):
        super().__init__(device_id, DeviceType.SENSOR)
        self.dht = None
        self.pin = None
        self.max_retries = 3
        self.retry_delay = 2.0
        self.last_reading_time = 0
        self.min_read_interval = 2.0  # Minimum time between readings
        
    def initialize(self, config: Dict[str, Any] = None) -> bool:
        """Initialize DHT11 sensor"""
        try:
            # Set configuration
            if config:
                self.set_config(config)
                
            # Get configuration values
            self.max_retries = self.get_config('max_retries') or 3
            self.retry_delay = self.get_config('retry_delay') or 2.0
            self.min_read_interval = self.get_config('min_read_interval') or 2.0
            pin_config = self.get_config('pin') or 'D17'
            
            self.logger.info(f"Initializing DHT11 sensor on pin {pin_config}")
            
            if not DHT_AVAILABLE:
                self.logger.warning("DHT libraries not available, enabling simulation mode")
                self.status = DeviceStatus.READY
                return True
                
            # Initialize sensor
            pin_obj = getattr(board, pin_config)
            self.dht = adafruit_dht.DHT11(pin_obj, use_pulseio=False)
            self.pin = pin_config
            
            # Perform initial test read
            if self._test_sensor():
                self.status = DeviceStatus.READY
                self.logger.info("DHT11 sensor initialized successfully")
                return True
            else:
                self.status = DeviceStatus.ERROR
                self.logger.error("DHT11 sensor initialization failed - test read failed")
                return False
                
        except Exception as e:
            self.set_error(e)
            self.logger.error(f"DHT11 sensor initialization failed: {e}")
            return False
            
    def cleanup(self) -> bool:
        """Clean up sensor resources"""
        try:
            if self.dht:
                # DHT library doesn't have explicit cleanup, but we can reset reference
                self.dht = None
                
            self.status = DeviceStatus.UNINITIALIZED
            self.logger.info("DHT11 sensor cleanup completed")
            return True
            
        except Exception as e:
            self.logger.error(f"DHT11 sensor cleanup failed: {e}")
            return False
            
    def self_test(self) -> bool:
        """Perform sensor self-test"""
        try:
            if self.status != DeviceStatus.READY:
                return False
                
            # Try to read values
            temp, humidity = self._read_raw_values()
            return temp is not None and humidity is not None
            
        except Exception as e:
            self.logger.error(f"DHT11 self-test failed: {e}")
            return False
            
    def get_status(self) -> DeviceStatus:
        """Get current device status"""
        return self.status
        
    def read_value(self, sensor_type: str) -> Optional[float]:
        """Read specific sensor value"""
        try:
            if self.status != DeviceStatus.READY:
                raise DeviceOperationError(f"Device not ready (status: {self.status})")
                
            if sensor_type not in ['temperature', 'humidity']:
                raise ValueError(f"Invalid sensor type: {sensor_type}")
                
            values = self.read_values()
            return values.get(sensor_type)
            
        except Exception as e:
            self.logger.error(f"Failed to read {sensor_type}: {e}")
            return None
            
    def read_values(self) -> Dict[str, float]:
        """Read all sensor values"""
        try:
            if self.status != DeviceStatus.READY:
                raise DeviceOperationError(f"Device not ready (status: {self.status})")
                
            # Check minimum read interval
            current_time = time.time()
            if current_time - self.last_reading_time < self.min_read_interval:
                self.logger.debug("Skipping read - minimum interval not reached")
                return {}
                
            temp, humidity = self._read_with_retry()
            
            if temp is not None and humidity is not None:
                self.last_reading_time = current_time
                return {
                    'temperature': temp,
                    'humidity': humidity
                }
            else:
                return {}
                
        except Exception as e:
            self.logger.error(f"Failed to read sensor values: {e}")
            return {}
            
    def get_unit(self, sensor_type: str) -> str:
        """Get sensor unit"""
        units = {
            'temperature': '°C',
            'humidity': '%'
        }
        return units.get(sensor_type, '')
        
    def _test_sensor(self) -> bool:
        """Test sensor functionality"""
        try:
            temp, humidity = self._read_raw_values()
            return temp is not None and humidity is not None
            
        except Exception:
            return False
            
    def _read_with_retry(self) -> Tuple[Optional[float], Optional[float]]:
        """Read sensor values with retry mechanism"""
        for attempt in range(self.max_retries):
            try:
                temp, humidity = self._read_raw_values()
                
                if temp is not None and humidity is not None:
                    self.logger.debug(f"Sensor read successful on attempt {attempt + 1}")
                    return temp, humidity
                    
            except Exception as e:
                self.logger.debug(f"Sensor read attempt {attempt + 1} failed: {e}")
                
            if attempt < self.max_retries - 1:
                self.logger.debug(f"Waiting {self.retry_delay}s before retry...")
                time.sleep(self.retry_delay)
                
        self.logger.warning(f"Sensor read failed after {self.max_retries} attempts")
        return None, None
        
    def _read_raw_values(self) -> Tuple[Optional[float], Optional[float]]:
        """Read raw sensor values without retry"""
        if not DHT_AVAILABLE:
            # Simulation mode for testing
            import random
            temp = round(random.uniform(20.0, 35.0), 1)
            humidity = round(random.uniform(40.0, 70.0), 1)
            self.logger.debug(f"Simulation mode: temp={temp}°C, humidity={humidity}%")
            return temp, humidity
            
        try:
            temperature = self.dht.temperature
            humidity = self.dht.humidity
            
            if temperature is not None and humidity is not None:
                self.logger.debug(f"Raw sensor read: temp={temperature}°C, humidity={humidity}%")
                return temperature, humidity
            else:
                self.logger.debug("Sensor returned None values")
                return None, None
                
        except RuntimeError as e:
            self.logger.debug(f"Sensor runtime error: {e}")
            return None, None
        except Exception as e:
            self.logger.error(f"Unexpected sensor error: {e}")
            return None, None

class SensorManager:
    """Manager for sensor devices"""
    
    def __init__(self):
        self.sensors: Dict[str, IHALSensor] = {}
        self.logger = logging.getLogger('TrustMonitor.HAL.SensorManager')
        
    def register_sensor(self, sensor: IHALSensor) -> bool:
        """Register a sensor"""
        try:
            self.sensors[sensor.device_id] = sensor
            self.logger.info(f"Sensor {sensor.device_id} registered")
            return True
        except Exception as e:
            self.logger.error(f"Failed to register sensor: {e}")
            return False
            
    def get_sensor(self, sensor_id: str) -> Optional[IHALSensor]:
        """Get sensor by ID"""
        return self.sensors.get(sensor_id)
        
    def read_all_sensors(self) -> Dict[str, Dict[str, float]]:
        """Read all registered sensors"""
        results = {}
        
        for sensor_id, sensor in self.sensors.items():
            try:
                values = sensor.read_values()
                if values:
                    results[sensor_id] = values
            except Exception as e:
                self.logger.error(f"Failed to read sensor {sensor_id}: {e}")
                
        return results
        
    def get_sensor_status(self, sensor_id: str) -> Optional[DeviceStatus]:
        """Get sensor status"""
        sensor = self.get_sensor(sensor_id)
        return sensor.get_status() if sensor else None

# Global sensor manager
sensor_manager = SensorManager()

def create_dht11_sensor(device_id: str = "dht11_sensor", config: Dict[str, Any] = None) -> DHT11Sensor:
    """Create and configure DHT11 sensor"""
    sensor = DHT11Sensor(device_id)
    if config:
        sensor.set_config(config)
    return sensor
