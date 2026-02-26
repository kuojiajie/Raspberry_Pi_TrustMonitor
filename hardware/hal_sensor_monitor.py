#!/usr/bin/env python3
"""
TrustMonitor HAL Sensor Monitor (Refactored)
=============================================

Refactored sensor monitoring service using the new HAL architecture.
This module replaces the old sensor_monitor.py with HAL-based implementation.

Features:
- HAL-based sensor and indicator management
- Unified configuration management
- Professional error handling and logging
- Backward compatibility with existing interfaces
- Environment variable support
"""

import time
import sys
import os
from datetime import datetime
from typing import Optional, Dict, Any
import logging

# Add current directory to path for imports
current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.insert(0, current_dir)

from hal_interface import get_hal, initialize_hardware, cleanup_hardware
from hal_indicators import LEDColor

class SensorConfig:
    """Sensor configuration management"""
    
    def __init__(self):
        self.load_config()
    
    def load_config(self):
        """Load configuration with environment variable priority"""
        # Monitoring interval (seconds)
        self.monitor_interval = int(os.getenv('SENSOR_MONITOR_INTERVAL', '60'))
        
        # Temperature and humidity thresholds
        self.temp_warning = float(os.getenv('TEMP_WARNING', '40.0'))
        self.temp_error = float(os.getenv('TEMP_ERROR', '45.0'))
        self.humidity_warning = float(os.getenv('HUMIDITY_WARNING', '70.0'))
        self.humidity_error = float(os.getenv('HUMIDITY_ERROR', '80.0'))
        
        # Sensor retry configuration
        self.sensor_max_retries = int(os.getenv('SENSOR_MAX_RETRIES', '3'))
        self.sensor_retry_delay = float(os.getenv('SENSOR_RETRY_DELAY', '1.0'))
        
        # HAL configuration
        self.hal_config = {
            'dht11_sensor': {
                'pin': os.getenv('DHT_PIN', 'D17'),
                'max_retries': self.sensor_max_retries,
                'retry_delay': self.sensor_retry_delay,
                'min_read_interval': 2.0
            },
            'rgb_led': {
                'pins': {
                    'red': int(os.getenv('LED_RED_PIN', '27')),
                    'green': int(os.getenv('LED_GREEN_PIN', '22')),
                    'blue': int(os.getenv('LED_BLUE_PIN', '5'))
                },
                'frequencies': {
                    'red': 2000,
                    'green': 1999,
                    'blue': 5000
                },
                'brightness': int(os.getenv('LED_BRIGHTNESS', '100'))
            }
        }
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Configuration loaded successfully")
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Monitoring interval: {self.monitor_interval} seconds")
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Temperature thresholds: warning {self.temp_warning}°C, error {self.temp_error}°C")
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Humidity thresholds: warning {self.humidity_warning}%, error {self.humidity_error}%")

class HALSensorMonitor:
    """HAL-based sensor monitoring service"""
    
    def __init__(self):
        """Initialize HAL sensor monitor"""
        self.config = SensorConfig()
        self.hal = get_hal()
        self.current_status = None
        self.logger = logging.getLogger('TrustMonitor.HAL.SensorMonitor')
        
    def initialize(self):
        """
        Initialize HAL and hardware components
        
        This method performs the complete initialization sequence:
        1. Initialize HAL system with device configuration
        2. Run device self-tests to verify hardware functionality
        3. Report initialization status and any issues
        
        Raises:
            RuntimeError: If HAL initialization fails
            Exception: For other initialization errors
        """
        try:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Initializing HAL sensor monitor...")
            
            # Step 1: Initialize HAL with device configuration
            # This registers all devices (DHT11 sensor, RGB LED) and sets up GPIO/PWM
            if not self.hal.initialize(self.config.hal_config):
                raise RuntimeError("Failed to initialize HAL")
            
            # Step 2: Run device self-tests
            # This verifies that each device can communicate and respond correctly
            test_results = self.hal.run_self_tests()
            failed_tests = [device for device, result in test_results.items() if not result]
            
            if failed_tests:
                self.logger.warning(f"Some devices failed self-test: {failed_tests}")
                # Note: We continue initialization even with some failures
                # This allows partial functionality (e.g., LED works even if sensor fails)
            else:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] All devices passed self-test")
                
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] HAL sensor monitor initialization completed")
            
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: HAL sensor monitor initialization failed - {e}")
            raise
    def determine_status(self, temperature: float, humidity: float) -> str:
        """Determine LED status based on temperature and humidity"""
        # Check error thresholds
        if temperature >= self.config.temp_error or humidity >= self.config.humidity_error:
            return 'red'
        
        # Check warning thresholds
        if temperature >= self.config.temp_warning or humidity >= self.config.humidity_warning:
            return 'blue'
        
        # Normal status
        return 'green'
    
    def update_led_status(self, status: str):
        """Update LED status using HAL"""
        if status != self.current_status:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Status changed: {self.current_status} -> {status}")
            
            # Clear all indicators first
            self.hal.clear_all_indicators()
            
            # Wait to ensure LEDs are off
            time.sleep(0.5)
            
            # Set new status
            success = self.hal.set_indicator_state('rgb_led', 'on', color=status)
            
            if success:
                self.current_status = status
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] LED {status} set successfully")
            else:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] WARNING: Failed to set LED {status}")
    
    def read_sensors(self) -> Optional[Dict[str, float]]:
        """Read temperature and humidity using HAL"""
        try:
            # Read sensor values through HAL
            sensor_values = self.hal.get_sensor_values('dht11_sensor')
            
            if 'dht11_sensor' in sensor_values:
                values = sensor_values['dht11_sensor']
                temperature = values.get('temperature')
                humidity = values.get('humidity')
                
                if temperature is not None and humidity is not None:
                    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Sensor read successful: temperature {temperature:.1f}°C, humidity {humidity:.1f}%")
                    return {'temperature': temperature, 'humidity': humidity}
                else:
                    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] WARNING: Sensor returned None values")
                    return None
            else:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] WARNING: No sensor data available")
                return None
                
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: Sensor read failed - {e}")
            return None
    
    def run_once(self):
        """Execute one monitoring cycle"""
        try:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Starting HAL sensor reading...")
            
            # Read sensors
            result = self.read_sensors()
            
            if result is not None:
                temperature = result['temperature']
                humidity = result['humidity']
                
                # Determine status
                status = self.determine_status(temperature, humidity)
                
                # Update LED status
                self.update_led_status(status)
                
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Temperature: {temperature:.1f}°C, Humidity: {humidity:.1f}%, Status: {status}")
            else:
                # Sensor failed, turn on red LED
                self.update_led_status('red')
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Sensor read failed, status: {self.current_status}")
            
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: Monitoring execution failed - {e}")
    
    def run_continuous(self):
        """Continuous monitoring"""
        try:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Starting continuous HAL monitoring, interval: {self.config.monitor_interval} seconds")
            
            while True:
                self.run_once()
                time.sleep(self.config.monitor_interval)
                
        except KeyboardInterrupt:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] User interrupted monitoring")
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: Continuous monitoring failed - {e}")
        finally:
            self.cleanup()
    
    def cleanup(self):
        """Clean up resources"""
        try:
            if self.hal:
                self.hal.cleanup()
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] HAL sensor monitor cleanup completed")
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] WARNING: Cleanup failed - {e}")
    
    def get_device_status(self) -> Dict[str, Any]:
        """Get device status information"""
        try:
            return self.hal.get_device_status()
        except Exception as e:
            self.logger.error(f"Failed to get device status: {e}")
            return {}

def print_usage():
    """Display usage instructions"""
    print("TrustMonitor HAL Sensor Monitoring Service")
    print("=" * 50)
    print("Usage: hal_sensor_monitor.py [options]")
    print()
    print("Options:")
    print("  --help, -h     Display this help")
    print("  --test, -t     Execute one test")
    print("  --status       Show device status")
    print()
    print("Environment Variables:")
    print("  SENSOR_MONITOR_INTERVAL  Monitoring interval (seconds, default 60)")
    print("  TEMP_WARNING           Temperature warning threshold (°C, default 40.0)")
    print("  TEMP_ERROR             Temperature error threshold (°C, default 45.0)")
    print("  HUMIDITY_WARNING       Humidity warning threshold (%), default 70.0)")
    print("  HUMIDITY_ERROR         Humidity error threshold (%), default 80.0)")
    print("  DHT_PIN                DHT sensor pin (default D17)")
    print("  LED_RED_PIN            Red LED pin (default 27)")
    print("  LED_GREEN_PIN          Green LED pin (default 22)")
    print("  LED_BLUE_PIN           Blue LED pin (default 5)")
    print("  LED_BRIGHTNESS         LED brightness (default 100)")
    print()
    sys.exit(0)

def main():
    """Main program"""
    # Check parameters
    if len(sys.argv) > 1 and sys.argv[1] in ['--help', '-h']:
        print_usage()
    
    # Create HAL sensor monitor
    monitor = HALSensorMonitor()
    
    try:
        # Initialize hardware
        monitor.initialize()
        
        # Show device status
        if len(sys.argv) > 1 and sys.argv[1] == '--status':
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Device Status:")
            status = monitor.get_device_status()
            for device_id, device_status in status.items():
                print(f"  {device_id}: {device_status.value}")
            sys.exit(0)
        
        # Execute one test
        if len(sys.argv) > 1 and sys.argv[1] in ['--test', '-t']:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Executing one HAL test...")
            monitor.run_once()
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Test completed")
        else:
            # Continuous monitoring
            monitor.run_continuous()
            
    except KeyboardInterrupt:
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] User interrupted monitoring")
    except Exception as e:
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: {e}")
        sys.exit(1)
    finally:
        monitor.cleanup()

if __name__ == '__main__':
    main()
