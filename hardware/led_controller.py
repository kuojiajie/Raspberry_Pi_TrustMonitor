#!/usr/bin/env python3
"""
TrustMonitor Hardware LED Control Module
========================================

Features:
- RGB LED status indicator control
- Support for red, green, blue pure color output
- LED on/off and blinking functionality
- Manufacturer-standard PWM control logic
- Hardware abstraction for LED operations
"""

import RPi.GPIO as GPIO
import time
import sys
import os
from datetime import datetime

# Ensure current directory is in Python path
current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.insert(0, current_dir)

# RGB LED pin definitions (BCM numbering)
RGB_PINS = {
    'red': 27,    # BCM 27 - Red LED (error status)
    'green': 22,  # BCM 22 - Green LED (normal status)
    'blue': 5     # BCM 5 - Blue LED (information status)
}

# PWM frequency configuration (manufacturer specifications)
PWM_FREQUENCIES = {
    'red': 2000,    # 2KHz - Red LED frequency
    'green': 1999,  # 1.999KHz - Green LED frequency
    'blue': 5000    # 5KHz - Blue LED frequency
}

# Global PWM objects
pins = {}
p_R = None
p_G = None
p_B = None

class LEDController:
    """TrustMonitor Hardware LED Controller"""
    
    def __init__(self):
        """Initialize LED controller"""
        self.initialized = False
        self.current_color = None
        
    def setup_gpio(self):
        """設定 GPIO 和 PWM"""
        global pins, p_R, p_G, p_B
        
        try:
            pins = {'pin_R': RGB_PINS['red'], 'pin_G': RGB_PINS['green'], 'pin_B': RGB_PINS['blue']}
            GPIO.setmode(GPIO.BCM)
            GPIO.setwarnings(False)
            
            # 設定 GPIO 腳位
            for i in pins:
                GPIO.setup(pins[i], GPIO.OUT)
                GPIO.output(pins[i], GPIO.LOW)
            
            # 初始化 PWM (根據廠商規格)
            p_R = GPIO.PWM(pins['pin_R'], PWM_FREQUENCIES['red'])
            p_G = GPIO.PWM(pins['pin_G'], PWM_FREQUENCIES['green'])
            p_B = GPIO.PWM(pins['pin_B'], PWM_FREQUENCIES['blue'])
            
            # 初始化占空比為 0 (LED 關閉)
            p_R.start(0)
            p_G.start(0)
            p_B.start(0)
            
            self.initialized = True
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] LED 控制器初始化成功")
            
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: LED 初始化失敗 - {e}")
            raise
    
    def cleanup_gpio(self):
        """清理 GPIO 資源"""
        global p_R, p_G, p_B
        
        try:
            if p_R:
                p_R.stop()
            if p_G:
                p_G.stop()
            if p_B:
                p_B.stop()
            
            GPIO.setmode(GPIO.BCM)
            for i in pins:
                GPIO.setup(pins[i], GPIO.OUT)
                GPIO.output(pins[i], GPIO.LOW)
            
            GPIO.cleanup()
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] LED 資源清理完成")
            
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] WARNING: LED 資源清理失敗 - {e}")
    
    def set_pure_color(self, color):
        """設定純色 - 同時關閉其他顏色"""
        global p_R, p_G, p_B
        
        if not self.initialized:
            raise RuntimeError("LED 控制器未初始化")
        
        # 關閉所有 LED
        p_R.ChangeDutyCycle(0)
        p_G.ChangeDutyCycle(0)
        p_B.ChangeDutyCycle(0)
        
        # 設定指定顏色 (0=關閉, 100=最亮)
        if color == 'red':
            p_R.ChangeDutyCycle(100)  # 紅色最亮
            self.current_color = 'red'
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 設定紅色: 紅色=100(最亮), 綠色=0(關閉), 藍色=0(關閉)")
            
        elif color == 'green':
            p_G.ChangeDutyCycle(100)  # 綠色最亮
            self.current_color = 'green'
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 設定綠色: 紅色=0(關閉), 綠色=100(最亮), 藍色=0(關閉)")
            
        elif color == 'blue':
            p_B.ChangeDutyCycle(100)  # 藍色最亮
            self.current_color = 'blue'
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 設定藍色: 紅色=0(關閉), 綠色=0(關閉), 藍色=100(最亮)")
        
        time.sleep(0.1)  # 等待顏色穩定
    
    def turn_off_all(self):
        """關閉所有 LED"""
        global p_R, p_G, p_B
        
        if not self.initialized:
            return
        
        p_R.ChangeDutyCycle(0)
        p_G.ChangeDutyCycle(0)
        p_B.ChangeDutyCycle(0)
        
        self.current_color = None
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 所有 LED 已關閉")
    
    def blink_color(self, color, times=5, speed=0.5):
        """閃爍指定顏色"""
        if not self.initialized:
            raise RuntimeError("LED 控制器未初始化")
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 開始 {color} LED 閃爍 - {times} 次, 每次間隔 {speed} 秒")
        
        for i in range(times):
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 第 {i+1}/{times} 次閃爍")
            self.set_pure_color(color)
            time.sleep(speed)
            self.turn_off_all()
            time.sleep(speed)
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {color} LED 閃爍完成")
