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
    """感測器配置管理"""
    
    def __init__(self):
        self.load_config()
    
    def load_config(self):
        """載入配置 (優先使用環境變數)"""
        # 監控間隔 (秒)
        self.monitor_interval = int(os.getenv('SENSOR_MONITOR_INTERVAL', '60'))
        
        # 溫濕度閾值
        self.temp_warning = float(os.getenv('TEMP_WARNING', '30.0'))
        self.temp_error = float(os.getenv('TEMP_ERROR', '35.0'))
        self.humidity_warning = float(os.getenv('HUMIDITY_WARNING', '70.0'))
        self.humidity_error = float(os.getenv('HUMIDITY_ERROR', '80.0'))
        
        # 感測器重試設定
        self.sensor_max_retries = int(os.getenv('SENSOR_MAX_RETRIES', '3'))
        self.sensor_retry_delay = float(os.getenv('SENSOR_RETRY_DELAY', '1.0'))
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 配置載入完成")
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 監控間隔: {self.monitor_interval} 秒")
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 溫度警告: {self.temp_warning}°C, 錯誤: {self.temp_error}°C")
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 濕度警告: {self.humidity_warning}%, 錯誤: {self.humidity_error}%")
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 感測器重試: 最大 {self.sensor_max_retries} 次, 間隔 {self.sensor_retry_delay} 秒")

class SensorMonitor:
    """TrustMonitor 感測器監控器"""
    
    def __init__(self):
        """初始化感測器監控器"""
        self.config = SensorConfig()
        self.led_controller = LEDController()
        self.sensor_reader = SensorReader()
        self.current_status = None
        
    def initialize(self):
        """初始化硬體"""
        try:
            # 初始化 LED 控制器
            self.led_controller.setup_gpio()
            
            # 初始化感測器
            self.sensor_reader.initialize_sensor()
            
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 感測器監控器初始化完成")
            
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: 感測器監控器初始化失敗 - {e}")
            raise
    
    def determine_status(self, temperature: float, humidity: float) -> str:
        """根據溫濕度決定 LED 狀態"""
        # 檢查錯誤閾值
        if temperature >= self.config.temp_error or humidity >= self.config.humidity_error:
            return 'red'
        
        # 檢查警告閾值
        if temperature >= self.config.temp_warning or humidity >= self.config.humidity_warning:
            return 'blue'
        
        # 正常狀態
        return 'green'
    
    def update_led_status(self, status: str):
        """更新 LED 狀態"""
        if status != self.current_status:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 狀態變更: {self.current_status} -> {status}")
            
            # 先關閉所有 LED
            self.led_controller.turn_off_all()
            
            # 等待一下確保關閉
            time.sleep(0.5)
            
            # 設定新狀態
            self.led_controller.set_pure_color(status)
            
            self.current_status = status
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] LED {status} 設定成功")
    
    def read_sensors(self) -> Optional[Tuple[float, float]]:
        """讀取溫濕度"""
        try:
            # 讀取溫度
            temperature = self.sensor_reader.read_sensor_with_retry(
                'temperature', 
                self.config.sensor_max_retries, 
                self.config.sensor_retry_delay
            )
            
            if temperature is None:
                return None
            
            # 等待一下再讀取濕度
            time.sleep(2)
            
            # 讀取濕度
            humidity = self.sensor_reader.read_sensor_with_retry(
                'humidity', 
                self.config.sensor_max_retries, 
                self.config.sensor_retry_delay
            )
            
            if humidity is None:
                return None
            
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 感測器讀取成功: 溫度 {temperature:.1f}°C, 濕度 {humidity:.1f}%")
            return temperature, humidity
            
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: 感測器讀取失敗 - {e}")
            return None
    
    def run_once(self):
        """執行一次監控"""
        try:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 開始感測器讀取 (最大重試 {self.config.sensor_max_retries} 次)")
            
            # 讀取感測器
            result = self.read_sensors()
            
            if result is not None:
                temperature, humidity = result
                
                # 決定狀態
                status = self.determine_status(temperature, humidity)
                
                # 更新 LED 狀態
                self.update_led_status(status)
                
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 溫度: {temperature:.1f}°C, 濕度: {humidity:.1f}%, 狀態: {status}")
            else:
                # 感測器失敗，開啟紅色 LED
                self.update_led_status('red')
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 感測器讀取失敗，狀態: {self.current_status}")
            
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: 監控執行失敗 - {e}")
    
    def run_continuous(self):
        """持續監控"""
        try:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 開始持續監控，間隔: {self.config.monitor_interval} 秒")
            
            while True:
                self.run_once()
                time.sleep(self.config.monitor_interval)
                
        except KeyboardInterrupt:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 使用者中斷監控")
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: 持續監控失敗 - {e}")
        finally:
            self.cleanup()
    
    def cleanup(self):
        """清理資源"""
        try:
            if hasattr(self.led_controller, 'cleanup_gpio'):
                self.led_controller.cleanup_gpio()
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 感測器監控器清理完成")
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] WARNING: 清理失敗 - {e}")

def print_usage():
    """顯示使用說明"""
    print("TrustMonitor 感測器監控服務")
    print("=" * 50)
    print("用法: sensor_monitor.py [options]")
    print()
    print("選項:")
    print("  --help, -h     顯示此說明")
    print("  --test, -t     執行一次測試")
    print()
    print("環境變數:")
    print("  SENSOR_MONITOR_INTERVAL  監控間隔 (秒，預設 60)")
    print("  TEMP_WARNING           溫度警告閾值 (°C，預設 30.0)")
    print("  TEMP_ERROR             溫度錯誤閾值 (°C，預設 35.0)")
    print("  HUMIDITY_WARNING       濕度警告閾值 (%，預設 70.0)")
    print("  HUMIDITY_ERROR         濕度錯誤閾值 (%，預設 80.0)")
    print("  SENSOR_MAX_RETRIES     感測器最大重試次數 (預設 3)")
    print("  SENSOR_RETRY_DELAY     感測器重試間隔 (秒，預設 1.0)")
    print()
    sys.exit(0)

def main():
    """主程式"""
    # 檢查參數
    if len(sys.argv) > 1 and sys.argv[1] in ['--help', '-h']:
        print_usage()
    
    # 建立感測器監控器
    monitor = SensorMonitor()
    
    try:
        # 初始化硬體
        monitor.initialize()
        
        # 執行一次測試
        if len(sys.argv) > 1 and sys.argv[1] in ['--test', '-t']:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 執行一次測試...")
            monitor.run_once()
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 測試完成")
        else:
            # 持續監控
            monitor.run_continuous()
            
    except KeyboardInterrupt:
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 使用者中斷操作")
    except Exception as e:
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: 主程式失敗 - {e}")
        sys.exit(1)
    finally:
        monitor.cleanup()

if __name__ == '__main__':
    main()
