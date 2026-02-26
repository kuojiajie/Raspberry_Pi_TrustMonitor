#!/usr/bin/env python3
"""
TrustMonitor Hardware LED Control Module
========================================

DEPRECATED: Use hardware/hal_led_controller.py instead
This legacy module is maintained for backward compatibility only.
New development should use the HAL (Hardware Abstraction Layer) system.

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
        """Setup GPIO and PWM"""
        global pins, p_R, p_G, p_B
        
        try:
            pins = {'pin_R': RGB_PINS['red'], 'pin_G': RGB_PINS['green'], 'pin_B': RGB_PINS['blue']}
            GPIO.setmode(GPIO.BCM)
            GPIO.setwarnings(False)
            
            # Setup GPIO pins
            for i in pins:
                GPIO.setup(pins[i], GPIO.OUT)
                GPIO.output(pins[i], GPIO.LOW)
            
            # Initialize PWM (manufacturer specifications)
            p_R = GPIO.PWM(pins['pin_R'], PWM_FREQUENCIES['red'])
            p_G = GPIO.PWM(pins['pin_G'], PWM_FREQUENCIES['green'])
            p_B = GPIO.PWM(pins['pin_B'], PWM_FREQUENCIES['blue'])
            
            # Initialize duty cycle to 0 (LED off)
            p_R.start(0)
            p_G.start(0)
            p_B.start(0)
            
            self.initialized = True
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] LED controller initialization successful")
            
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: LED initialization failed - {e}")
            raise
    
    def cleanup_gpio(self):
        """Clean up GPIO resources"""
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
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] LED resource cleanup completed")
            
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] WARNING: LED resource cleanup failed - {e}")
    
    def set_pure_color(self, color):
        """Set pure color - turn off other colors simultaneously"""
        global p_R, p_G, p_B
        
        if not self.initialized:
            raise RuntimeError("LED controller not initialized")
        
        # Turn off all LEDs
        p_R.ChangeDutyCycle(0)
        p_G.ChangeDutyCycle(0)
        p_B.ChangeDutyCycle(0)
        
        # Set specified color (0=off, 100=brightest)
        if color == 'red':
            p_R.ChangeDutyCycle(100)  # Red brightest
            self.current_color = 'red'
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Setting red: red=100(brightest), green=0(off), blue=0(off)")
            
        elif color == 'green':
            p_G.ChangeDutyCycle(100)  # Green brightest
            self.current_color = 'green'
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Setting green: red=0(off), green=100(brightest), blue=0(off)")
            
        elif color == 'blue':
            p_B.ChangeDutyCycle(100)  # Blue brightest
            self.current_color = 'blue'
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Setting blue: red=0(off), green=0(off), blue=100(brightest)")
            
        else:
            raise ValueError(f"Invalid color: {color}")
    
    def turn_off_all(self):
        """Turn off all LEDs"""
        global p_R, p_G, p_B
        
        if not self.initialized:
            return
        
        # Turn off all LEDs
        p_R.ChangeDutyCycle(0)
        p_G.ChangeDutyCycle(0)
        p_B.ChangeDutyCycle(0)
        
        self.current_color = None
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] All LEDs turned off")
    
    def blink_color(self, color, times=5, speed=0.5):
        """Blink specified color"""
        if not self.initialized:
            raise RuntimeError("LED controller not initialized")
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Starting {color} LED blinking - {times} times, {speed}s interval")
        
        for i in range(times):
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Blink {i+1}/{times}")
            self.set_pure_color(color)
            time.sleep(speed)
            self.turn_off_all()
            time.sleep(speed)
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {color} LED blinking completed")

def main():
    """Main program - Command line interface"""
    import argparse
    
    parser = argparse.ArgumentParser(description='TrustMonitor LED Controller')
    parser.add_argument('--color', choices=['red', 'green', 'blue'], help='Set LED color')
    parser.add_argument('--off', action='store_true', help='Turn off all LEDs')
    parser.add_argument('--blink', choices=['red', 'green', 'blue'], help='Blink specified color')
    parser.add_argument('--times', type=int, default=3, help='Blink times')
    parser.add_argument('--speed', type=float, default=0.5, help='Blink interval (seconds)')
    
    args = parser.parse_args()
    
    controller = LEDController()
    
    try:
        controller.setup_gpio()
        
        if args.color:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Setting {args.color} LED - press Ctrl+C to stop")
            controller.set_pure_color(args.color)
            
            # Wait for user interrupt
            try:
                while True:
                    time.sleep(1)
            except KeyboardInterrupt:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] User interrupted, turning off LED")
                controller.turn_off_all()
                
        elif args.blink:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Starting {args.blink} LED blinking")
            controller.blink_color(args.blink, args.times, args.speed)
            
        elif args.off:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Turning off all LEDs")
            controller.turn_off_all()
        else:
            parser.print_help()
            
    except KeyboardInterrupt:
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] User interrupted operation")
    except Exception as e:
        print(f"ERROR: {e}")
    finally:
        # Only cleanup on error or interrupt
        if 'args' not in locals():
            controller.cleanup_gpio()
        elif args.off:
            controller.cleanup_gpio()
        # Don't cleanup for color and blink modes - let user control

if __name__ == '__main__':
    main()