#!/usr/bin/env python3
"""
TrustMonitor HAL Indicator Devices
==================================

HAL implementations for indicator devices including RGB LEDs.
Provides standardized indicator interface with color control and status management.

Features:
- RGB LED control with PWM
- Multiple LED support
- Status-based color management
- Blink and animation effects
- Hardware abstraction for LED operations
"""

from typing import Dict, Any, Optional, List
import time
import logging
from datetime import datetime
from enum import Enum

try:
    import RPi.GPIO as GPIO
    GPIO_AVAILABLE = True
except ImportError:
    GPIO_AVAILABLE = False
    print("WARNING: RPi.GPIO not available, LED will run in simulation mode")

from hal_core import IHALIndicator, DeviceStatus, DeviceType, HALError, DeviceOperationError

class LEDColor(Enum):
    """Standard LED colors"""
    RED = 'red'
    GREEN = 'green'
    BLUE = 'blue'
    YELLOW = 'yellow'
    CYAN = 'cyan'
    MAGENTA = 'magenta'
    WHITE = 'white'
    OFF = 'off'

class LEDState(Enum):
    """LED state enumeration"""
    OFF = 'off'
    ON = 'on'
    BLINKING = 'blinking'
    BREATHING = 'breathing'
    ERROR = 'error'

class RGBLEDIndicator(IHALIndicator):
    """HAL implementation for RGB LED indicator"""
    
    def __init__(self, device_id: str = "rgb_led"):
        super().__init__(device_id, DeviceType.INDICATOR)
        self.pins = {}
        self.pwm_objects = {}
        self.current_color = LEDColor.OFF
        self.current_state = LEDState.OFF
        self.brightness = 100
        self.pwm_frequencies = {
            'red': 2000,
            'green': 1999,
            'blue': 5000
        }
        
    def initialize(self, config: Dict[str, Any] = None) -> bool:
        """Initialize RGB LED"""
        try:
            # Set configuration
            if config:
                self.set_config(config)
                
            # Get configuration values
            self.pins = self.get_config('pins') or {
                'red': 27,
                'green': 22,
                'blue': 5
            }
            self.pwm_frequencies = self.get_config('frequencies') or self.pwm_frequencies
            self.brightness = self.get_config('brightness') or 100
            
            self.logger.info(f"Initializing RGB LED with pins: {self.pins}")
            
            if not GPIO_AVAILABLE:
                self.logger.warning("RPi.GPIO not available, enabling simulation mode")
                self.status = DeviceStatus.READY
                return True
                
            # Setup GPIO
            GPIO.setmode(GPIO.BCM)
            GPIO.setwarnings(False)
            
            # Initialize pins and PWM
            for color, pin in self.pins.items():
                GPIO.setup(pin, GPIO.OUT)
                GPIO.output(pin, GPIO.LOW)
                
                # Create PWM object
                frequency = self.pwm_frequencies.get(color, 1000)
                pwm = GPIO.PWM(pin, frequency)
                pwm.start(0)  # Start with 0% duty cycle
                self.pwm_objects[color] = pwm
                
            self.status = DeviceStatus.READY
            self.logger.info("RGB LED initialized successfully")
            return True
            
        except Exception as e:
            self.set_error(e)
            self.logger.error(f"RGB LED initialization failed: {e}")
            return False
            
    def cleanup(self) -> bool:
        """Clean up LED resources"""
        try:
            if not GPIO_AVAILABLE:
                self.status = DeviceStatus.UNINITIALIZED
                return True
                
            # Stop all PWM
            for pwm in self.pwm_objects.values():
                try:
                    pwm.stop()
                except:
                    pass
                    
            # Clean up GPIO
            for pin in self.pins.values():
                try:
                    GPIO.setup(pin, GPIO.OUT)
                    GPIO.output(pin, GPIO.LOW)
                except:
                    pass
                    
            GPIO.cleanup()
            self.pwm_objects.clear()
            self.current_color = LEDColor.OFF
            self.current_state = LEDState.OFF
            self.status = DeviceStatus.UNINITIALIZED
            
            self.logger.info("RGB LED cleanup completed")
            return True
            
        except Exception as e:
            self.logger.error(f"RGB LED cleanup failed: {e}")
            return False
            
    def self_test(self) -> bool:
        """Perform LED self-test"""
        try:
            if self.status != DeviceStatus.READY:
                return False
                
            # Test each color
            colors = [LEDColor.RED, LEDColor.GREEN, LEDColor.BLUE]
            for color in colors:
                if not self.set_color(color, test_mode=True):
                    return False
                time.sleep(0.5)
                
            # Turn off
            return self.clear()
            
        except Exception as e:
            self.logger.error(f"RGB LED self-test failed: {e}")
            return False
            
    def get_status(self) -> DeviceStatus:
        """Get current device status"""
        return self.status
        
    def set_state(self, state: str, **kwargs) -> bool:
        """Set LED state"""
        try:
            if self.status != DeviceStatus.READY:
                raise DeviceOperationError(f"Device not ready (status: {self.status})")
                
            state_enum = LEDState(state.lower())
            
            if state_enum == LEDState.OFF:
                return self.clear()
            elif state_enum == LEDState.ON:
                color = kwargs.get('color', LEDColor.GREEN.value)
                return self.set_color(LEDColor(color))
            elif state_enum == LEDState.BLINKING:
                color = kwargs.get('color', LEDColor.GREEN.value)
                times = kwargs.get('times', 3)
                speed = kwargs.get('speed', 0.5)
                return self.blink_color(LEDColor(color), times, speed)
            elif state_enum == LEDState.BREATHING:
                color = kwargs.get('color', LEDColor.GREEN.value)
                speed = kwargs.get('speed', 1.0)
                return self.breath_color(LEDColor(color), speed)
            else:
                raise ValueError(f"Unsupported state: {state}")
                
        except Exception as e:
            self.logger.error(f"Failed to set LED state {state}: {e}")
            return False
            
    def get_state(self) -> str:
        """Get current LED state"""
        return self.current_state.value
        
    def clear(self) -> bool:
        """Turn off LED"""
        try:
            if self.status != DeviceStatus.READY:
                return False
                
            if not GPIO_AVAILABLE:
                self.current_color = LEDColor.OFF
                self.current_state = LEDState.OFF
                self.logger.debug("Simulation mode: LED cleared")
                return True
                
            # Set all PWM duty cycles to 0
            for pwm in self.pwm_objects.values():
                pwm.ChangeDutyCycle(0)
                
            self.current_color = LEDColor.OFF
            self.current_state = LEDState.OFF
            self.logger.debug("LED cleared")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to clear LED: {e}")
            return False
            
    def set_color(self, color: LEDColor, brightness: int = None, test_mode: bool = False) -> bool:
        """Set LED to specific color"""
        try:
            if self.status != DeviceStatus.READY:
                return False
                
            if brightness is None:
                brightness = self.brightness
                
            if not GPIO_AVAILABLE:
                self.current_color = color
                self.current_state = LEDState.ON if color != LEDColor.OFF else LEDState.OFF
                if not test_mode:
                    self.logger.debug(f"Simulation mode: LED color set to {color.value}")
                return True
                
            # Clear all colors first
            for pwm in self.pwm_objects.values():
                pwm.ChangeDutyCycle(0)
                
            # Set specific color
            if color == LEDColor.OFF:
                duty_cycles = {'red': 0, 'green': 0, 'blue': 0}
            elif color == LEDColor.RED:
                duty_cycles = {'red': brightness, 'green': 0, 'blue': 0}
            elif color == LEDColor.GREEN:
                duty_cycles = {'red': 0, 'green': brightness, 'blue': 0}
            elif color == LEDColor.BLUE:
                duty_cycles = {'red': 0, 'green': 0, 'blue': brightness}
            elif color == LEDColor.YELLOW:
                duty_cycles = {'red': brightness, 'green': brightness, 'blue': 0}
            elif color == LEDColor.CYAN:
                duty_cycles = {'red': 0, 'green': brightness, 'blue': brightness}
            elif color == LEDColor.MAGENTA:
                duty_cycles = {'red': brightness, 'green': 0, 'blue': brightness}
            elif color == LEDColor.WHITE:
                duty_cycles = {'red': brightness, 'green': brightness, 'blue': brightness}
            else:
                raise ValueError(f"Unsupported color: {color}")
                
            # Apply duty cycles
            for color_name, duty_cycle in duty_cycles.items():
                if color_name in self.pwm_objects:
                    self.pwm_objects[color_name].ChangeDutyCycle(duty_cycle)
                    
            self.current_color = color
            self.current_state = LEDState.ON if color != LEDColor.OFF else LEDState.OFF
            
            if not test_mode:
                self.logger.debug(f"LED color set to {color.value} (brightness: {brightness}%)")
                
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to set LED color {color}: {e}")
            return False
            
    def blink_color(self, color: LEDColor, times: int = 3, speed: float = 0.5) -> bool:
        """Blink LED color"""
        try:
            if self.status != DeviceStatus.READY:
                return False
                
            self.logger.debug(f"Blinking {color.value} {times} times at {speed}s intervals")
            
            for i in range(times):
                if not self.set_color(color):
                    return False
                time.sleep(speed)
                if not self.clear():
                    return False
                if i < times - 1:  # Don't sleep after last blink
                    time.sleep(speed)
                    
            self.current_state = LEDState.BLINKING
            self.logger.debug(f"LED blinking completed: {color.value} x{times}")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to blink LED {color}: {e}")
            return False
            
    def breath_color(self, color: LEDColor, speed: float = 1.0) -> bool:
        """Breathing effect for LED color"""
        try:
            if self.status != DeviceStatus.READY:
                return False
                
            self.logger.debug(f"Breathing {color.value} at {speed}s intervals")
            
            steps = 20
            for i in range(steps * 2):
                if i < steps:
                    brightness = int((i + 1) * (100 / steps))
                else:
                    brightness = int((steps * 2 - i) * (100 / steps))
                    
                if not self.set_color(color, brightness):
                    return False
                time.sleep(speed / (steps * 2))
                
            self.clear()
            self.current_state = LEDState.BREATHING
            self.logger.debug(f"LED breathing completed: {color.value}")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to breath LED {color}: {e}")
            return False
            
    def get_current_color(self) -> LEDColor:
        """Get current LED color"""
        return self.current_color

class IndicatorManager:
    """Manager for indicator devices"""
    
    def __init__(self):
        self.indicators: Dict[str, IHALIndicator] = {}
        self.logger = logging.getLogger('TrustMonitor.HAL.IndicatorManager')
        
    def register_indicator(self, indicator: IHALIndicator) -> bool:
        """Register an indicator"""
        try:
            self.indicators[indicator.device_id] = indicator
            self.logger.info(f"Indicator {indicator.device_id} registered")
            return True
        except Exception as e:
            self.logger.error(f"Failed to register indicator: {e}")
            return False
            
    def get_indicator(self, indicator_id: str) -> Optional[IHALIndicator]:
        """Get indicator by ID"""
        return self.indicators.get(indicator_id)
        
    def clear_all_indicators(self) -> bool:
        """Clear all indicators"""
        success = True
        for indicator in self.indicators.values():
            try:
                if not indicator.clear():
                    success = False
            except Exception as e:
                self.logger.error(f"Failed to clear indicator: {e}")
                success = False
        return success
        
    def get_indicator_status(self, indicator_id: str) -> Optional[DeviceStatus]:
        """Get indicator status"""
        indicator = self.get_indicator(indicator_id)
        return indicator.get_status() if indicator else None

# Global indicator manager
indicator_manager = IndicatorManager()

def create_rgb_led(device_id: str = "rgb_led", config: Dict[str, Any] = None) -> RGBLEDIndicator:
    """Create and configure RGB LED indicator"""
    led = RGBLEDIndicator(device_id)
    if config:
        led.set_config(config)
    return led
