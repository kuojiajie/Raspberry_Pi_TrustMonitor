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
            raise RuntimeError("感測器未初始化")
        
        try:
            temperature = self.dht.temperature
            if temperature is not None:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 溫度讀取成功: {temperature:.1f}°C")
                return temperature
            else:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: 溫度讀取失敗 - 感測器返回 None")
                return None
                
        except RuntimeError as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: 溫度讀取失敗 - {e}")
            return None
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: 溫度感測器錯誤 - {e}")
            return None
    
    def read_humidity(self):
        """讀取濕度"""
        if not self.initialized:
            raise RuntimeError("感測器未初始化")
        
        try:
            humidity = self.dht.humidity
            if humidity is not None:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 濕度讀取成功: {humidity:.1f}%")
                return humidity
            else:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: 濕度讀取失敗 - 感測器返回 None")
                return None
                
        except RuntimeError as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: 濕度讀取失敗 - {e}")
            return None
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: 濕度感測器錯誤 - {e}")
            return None
    
    def read_sensor_with_retry(self, sensor_type, max_retries=3, retry_delay=2):
        """讀取感測器數值 (含重試機制)"""
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 開始讀取 {sensor_type} (最大重試 {max_retries} 次)")
        
        for attempt in range(max_retries):
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 第 {attempt + 1}/{max_retries} 次嘗試")
            
            if sensor_type == "temperature":
                value = self.read_temperature()
            elif sensor_type == "humidity":
                value = self.read_humidity()
            else:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: 不支援的感測器類型 - {sensor_type}")
                return None
            
            if value is not None:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {sensor_type} 讀取成功")
                return value
            
            if attempt < max_retries - 1:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 等待 {retry_delay} 秒後重試...")
                time.sleep(retry_delay)
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: {sensor_type} 讀取失敗 - 已達最大重試次數")
        return None
