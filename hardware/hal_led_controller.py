#!/usr/bin/env python3
"""
TrustMonitor HAL LED Controller (Refactored)
============================================

Refactored LED controller using the new HAL architecture.
This module provides backward compatibility while using HAL internally.

Features:
- HAL-based LED control
- Backward compatibility with original interface
- Command line interface
- Error handling and logging
"""

import argparse
import sys
import os
from datetime import datetime
import logging

# Add current directory to path for imports
current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.insert(0, current_dir)

from hal_interface import get_hal, initialize_hardware, cleanup_hardware
from hal_indicators import LEDColor

class HALLedController:
    """HAL-based LED controller with backward compatibility"""
    
    def __init__(self):
        """Initialize HAL LED controller"""
        self.hal = get_hal()
        self.initialized = False
        self.logger = logging.getLogger('TrustMonitor.HAL.LedController')
        
    def initialize(self, config: dict = None):
        """Initialize LED controller"""
        try:
            # Default LED configuration
            default_config = {
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
            
            # Merge with provided config
            if config:
                default_config.update(config)
                
            # Initialize HAL
            if not self.hal.initialize(default_config):
                raise RuntimeError("Failed to initialize HAL")
                
            self.initialized = True
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] HAL LED controller initialized successfully")
            
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: HAL LED controller initialization failed - {e}")
            raise
    
    def set_pure_color(self, color: str):
        """Set pure color - backward compatibility"""
        try:
            if not self.initialized:
                raise RuntimeError("LED controller not initialized")
            
            success = self.hal.set_indicator_state('rgb_led', 'on', color=color)
            
            if success:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Setting {color} LED")
            else:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: Failed to set {color} LED")
                
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: {e}")
    
    def turn_off_all(self):
        """Turn off all LEDs - backward compatibility"""
        try:
            if not self.initialized:
                return
            
            success = self.hal.clear_all_indicators()
            
            if success:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] All LEDs turned off")
            else:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] WARNING: Failed to turn off LEDs")
                
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: {e}")
    
    def blink_color(self, color: str, times: int = 5, speed: float = 0.5):
        """Blink specified color - backward compatibility"""
        try:
            if not self.initialized:
                raise RuntimeError("LED controller not initialized")
            
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Starting {color} LED blinking - {times} times, {speed}s interval")
            
            success = self.hal.set_indicator_state('rgb_led', 'blinking', 
                                                 color=color, times=times, speed=speed)
            
            if success:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {color} LED blinking completed")
            else:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: Failed to blink {color} LED")
                
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: {e}")
    
    def cleanup(self):
        """Clean up resources"""
        try:
            if self.hal:
                self.hal.cleanup()
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] HAL LED controller cleanup completed")
        except Exception as e:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] WARNING: Cleanup failed - {e}")

def main():
    """Main program - Command line interface with backward compatibility"""
    parser = argparse.ArgumentParser(description='TrustMonitor HAL LED Controller')
    parser.add_argument('--color', choices=['red', 'green', 'blue'], help='Set LED color')
    parser.add_argument('--off', action='store_true', help='Turn off all LEDs')
    parser.add_argument('--blink', choices=['red', 'green', 'blue'], help='Blink specified color')
    parser.add_argument('--times', type=int, default=3, help='Blink times')
    parser.add_argument('--speed', type=float, default=0.5, help='Blink interval (seconds)')
    
    args = parser.parse_args()
    
    controller = HALLedController()
    
    try:
        controller.initialize()
        
        if args.color:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Setting {args.color} LED - press Ctrl+C to stop")
            controller.set_pure_color(args.color)
            
            # Wait for user interrupt
            try:
                while True:
                    import time
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
            controller.cleanup()
        elif args.off:
            controller.cleanup()
        # Don't cleanup for color and blink modes - let user control

if __name__ == '__main__':
    main()
