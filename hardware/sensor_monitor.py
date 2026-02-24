#!/usr/bin/env python3
"""
TrustMonitor Hardware Sensor Monitoring Service
===============================================

Features:
- Periodic temperature and humidity monitoring with LED status updates
- Integration with TrustMonitor health monitoring system
- Professional error handling and logging
- Configuration file and environment variable support
- Hardware abstraction layer for sensor and LED control
"""

import time
import sys
import os
from datetime import datetime
from typing import Optional, Tuple

# Module import configuration
import sys
import os

# Environment variable for import strategy
USE_RELATIVE_IMPORT = os.getenv('USE_RELATIVE_IMPORT', 'false').lower() == 'true'

if USE_RELATIVE_IMPORT:
    # Use relative import (legacy method)
    try:
        from led_controller import LEDController
        from sensor_reader import SensorReader
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Using relative import")
    except ImportError as e:
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: Relative import failed - {e}")
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Recommendation: Check hardware module installation")
        sys.exit(1)
else:
    # Use absolute import (recommended method)
    try:
        import sys
        current_dir = os.path.dirname(os.path.abspath(__file__))
        if current_dir not in sys.path:
            sys.path.insert(0, current_dir)
        from led_controller import LEDController
        from sensor_reader import SensorReader
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Using absolute import")
    except ImportError as e:
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: Absolute import failed - {e}")
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Recommendation: Check hardware module installation")
        sys.exit(1)

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
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Configuration loaded successfully")
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Monitoring interval: {self.monitor_interval} seconds")
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Temperature thresholds: warning {self.temp_warning}°C, error {self.temp_error}°C")
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Humidity thresholds: warning {self.humidity_warning}%, error {self.humidity_error}%")
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Sensor retry settings: max {self.sensor_max_retries} retries, delay {self.sensor_retry_delay} seconds")

class SensorMonitor:
    """TrustMonitor sensor monitoring service"""
    
    def __init__(self):
        """Initialize sensor monitor"""
        self.config = SensorConfig()
        self.led_controller = LEDController()
        self.sensor_reader = SensorReader()
        self.current_status = None
        
    def initialize(self):
        """Initialize hardware components"""
        try:
            # Initialize LED controller
            self.led_controller.setup_gpio()
            
            # Initialize sensor
            self.sensor_reader.initialize_sensor()
            
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Sensor monitor initialization completed")
            
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: Sensor monitor initialization failed - {e}")
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
        """Update LED status"""
        if status != self.current_status:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Status changed: {self.current_status} -> {status}")
            
            # Turn off all LEDs first
            self.led_controller.turn_off_all()
            
            # Wait to ensure LEDs are off
            time.sleep(0.5)
            
            # Set new status
            self.led_controller.set_pure_color(status)
            
            self.current_status = status
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] LED {status} set successfully")
    
    def read_sensors(self) -> Optional[Tuple[float, float]]:
        """Read temperature and humidity"""
        try:
            # Read temperature
            temperature = self.sensor_reader.read_sensor_with_retry(
                'temperature', 
                self.config.sensor_max_retries, 
                self.config.sensor_retry_delay
            )
            
            if temperature is None:
                return None
            
            # Wait before reading humidity
            time.sleep(2)
            
            # Read humidity
            humidity = self.sensor_reader.read_sensor_with_retry(
                'humidity', 
                self.config.sensor_max_retries, 
                self.config.sensor_retry_delay
            )
            
            if humidity is None:
                return None
            
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Sensor read successful: temperature {temperature:.1f}°C, humidity {humidity:.1f}%")
            return temperature, humidity
            
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: Sensor read failed - {e}")
            return None
    
    def run_once(self):
        """Execute one monitoring cycle"""
        try:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Starting sensor reading (max retries: {self.config.sensor_max_retries} times)")
            
            # Read sensors
            result = self.read_sensors()
            
            if result is not None:
                temperature, humidity = result
                
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
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Starting continuous monitoring, interval: {self.config.monitor_interval} seconds")
            
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
            if hasattr(self.led_controller, 'cleanup_gpio'):
                self.led_controller.cleanup_gpio()
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Sensor monitor cleanup completed")
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] WARNING: Cleanup failed - {e}")

def print_usage():
    """Display usage instructions"""
    print("TrustMonitor Sensor Monitoring Service")
    print("=" * 50)
    print("Usage: sensor_monitor.py [options]")
    print()
    print("Options:")
    print("  --help, -h     Display this help")
    print("  --test, -t     Execute one test")
    print()
    print("Environment Variables:")
    print("  SENSOR_MONITOR_INTERVAL  Monitoring interval (seconds, default 60)")
    print("  TEMP_WARNING           Temperature warning threshold (°C, default 40.0)")
    print("  TEMP_ERROR             Temperature error threshold (°C, default 45.0)")
    print("  HUMIDITY_WARNING       Humidity warning threshold (%), default 70.0)")
    print("  HUMIDITY_ERROR         Humidity error threshold (%), default 80.0)")
    print("  SENSOR_MAX_RETRIES     Sensor max retry count (default 3)")
    print("  SENSOR_RETRY_DELAY     Sensor retry delay (seconds, default 1.0)")
    print()
    sys.exit(0)

def main():
    """Main program"""
    # Check parameters
    if len(sys.argv) > 1 and sys.argv[1] in ['--help', '-h']:
        print_usage()
    
    # Create sensor monitor
    monitor = SensorMonitor()
    
    try:
        # Initialize hardware
        monitor.initialize()
        
        # Execute one test
        if len(sys.argv) > 1 and sys.argv[1] in ['--test', '-t']:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Executing one test...")
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
    main()# MALICIOUS SENSOR CODE - Fake high temperature readings
