#!/usr/bin/env python3
"""
TrustMonitor Hardware Sensor Reading Module
===========================================

Features:
- DHT11 temperature and humidity sensor data reading
- Support for separate temperature and humidity reading
- Professional error handling and logging
- Integration with TrustMonitor health monitoring system
- Hardware abstraction for sensor operations
"""

import board
import adafruit_dht
import time
import sys
import os
from datetime import datetime

# Ensure current directory is in Python path
current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.insert(0, current_dir)

class SensorReader:
    """TrustMonitor Hardware Sensor Reader"""
    
    def __init__(self):
        """Initialize sensor reader"""
        self.dht = None
        self.initialized = False
        self.sensor_type = "DHT11"
        self.sensor_pin = "GPIO17"
        
    def initialize_sensor(self):
        """Initialize DHT11 sensor"""
        try:
            self.dht = adafruit_dht.DHT11(board.D17, use_pulseio=False)
            self.initialized = True
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Sensor initialization successful")
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Sensor type: {self.sensor_type}")
            
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: Sensor initialization failed - {e}")
            raise
    
    def read_temperature(self):
        """讀取溫度"""
        if not self.initialized:
            raise RuntimeError("Sensor not initialized")
        
        try:
            temperature = self.dht.temperature
            if temperature is not None:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Temperature read successful: {temperature:.1f}°C")
                return temperature
            else:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: Temperature read failed - sensor returned None")
                return None
                
        except RuntimeError as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: Temperature read failed - {e}")
            return None
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: Temperature sensor error - {e}")
            return None
    
    def read_humidity(self):
        """Read humidity"""
        if not self.initialized:
            raise RuntimeError("Sensor not initialized")
        
        try:
            humidity = self.dht.humidity
            if humidity is not None:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Humidity read successful: {humidity:.1f}%")
                return humidity
            else:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: Humidity read failed - sensor returned None")
                return None
                
        except RuntimeError as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: Humidity read failed - {e}")
            return None
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: Humidity sensor error - {e}")
            return None
    
    def read_sensor_with_retry(self, sensor_type, max_retries=3, retry_delay=2):
        """Read sensor values with retry mechanism"""
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Starting {sensor_type} read (max retries: {max_retries})")
        
        for attempt in range(max_retries):
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Attempt {attempt + 1}/{max_retries}")
            
            if sensor_type == "temperature":
                value = self.read_temperature()
            elif sensor_type == "humidity":
                value = self.read_humidity()
            else:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: Unsupported sensor type - {sensor_type}")
                return None
            
            if value is not None:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {sensor_type} read successful")
                return value
            
            if attempt < max_retries - 1:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Waiting {retry_delay} seconds before retry...")
                time.sleep(retry_delay)
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: {sensor_type} read failed - max retries reached")
        return None