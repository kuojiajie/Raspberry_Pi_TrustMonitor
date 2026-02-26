#!/bin/bash

# ==============================================================================
# TrustMonitor GPIO Cleanup Utility
# ==============================================================================
# This script cleans up GPIO and PWM states to prevent conflicts
# Usage: ./cleanup_gpio.sh [--force]
# ==============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

FORCE_CLEANUP="${1:-false}"

echo "=== TrustMonitor GPIO Cleanup ==="
echo

# Check for running processes using GPIO
echo "Checking for GPIO processes..."
if pgrep -f "led_controller\|hal_led" >/dev/null 2>&1; then
    echo -e "${YELLOW}Found processes using GPIO:${NC}"
    pgrep -f "led_controller\|hal_led" | while read pid; do
        echo "  PID $pid: $(ps -p $pid -o comm=)"
        if [[ "$FORCE_CLEANUP" == "true" ]]; then
            echo "  Killing PID $pid..."
            kill "$pid" 2>/dev/null || true
            sleep 1
            kill -9 "$pid" 2>/dev/null || true
        fi
    done
else
    echo -e "${GREEN}No GPIO processes found${NC}"
fi

echo

# Check GPIO device usage
echo "Checking GPIO device usage..."
if lsof /dev/gpio* 2>/dev/null | grep -q .; then
    echo -e "${YELLOW}GPIO devices in use:${NC}"
    lsof /dev/gpio* 2>/dev/null
    if [[ "$FORCE_CLEANUP" == "true" ]]; then
        echo "Force cleanup not available for device files"
        echo "Please stop the processes manually"
    fi
else
    echo -e "${GREEN}No GPIO devices in use${NC}"
fi

echo

# Python GPIO cleanup
echo "Performing Python GPIO cleanup..."
python3 -c "
import RPi.GPIO as GPIO
try:
    GPIO.cleanup()
    print('GPIO cleanup: SUCCESS')
except Exception as e:
    print(f'GPIO cleanup: ERROR - {e}')
" 2>/dev/null || echo -e "${YELLOW}Python GPIO cleanup failed${NC}"

echo

# Check for PWM cleanup
echo "Checking for PWM objects..."
python3 -c "
import RPi.GPIO as GPIO
try:
    # Try to detect and cleanup any remaining PWM objects
    GPIO.setmode(GPIO.BCM)
    GPIO.setwarnings(False)
    
    # Common RGB LED pins
    pins = [27, 22, 5]
    for pin in pins:
        try:
            GPIO.setup(pin, GPIO.OUT)
            GPIO.output(pin, GPIO.LOW)
            print(f'Pin {pin}: Reset to LOW')
        except:
            print(f'Pin {pin}: Already in use or error')
    
    GPIO.cleanup()
    print('PWM cleanup: SUCCESS')
except Exception as e:
    print(f'PWM cleanup: ERROR - {e}')
" 2>/dev/null || echo -e "${YELLOW}PWM cleanup failed${NC}"

echo

# Final status check
echo "=== Final Status ==="
echo "GPIO processes: $(pgrep -f 'led_controller\|hal_led' | wc -l)"
echo "GPIO device usage: $(lsof /dev/gpio* 2>/dev/null | wc -l)"

if [[ $(pgrep -f 'led_controller\|hal_led' | wc -l) -eq 0 ]] && [[ $(lsof /dev/gpio* 2>/dev/null | wc -l) -eq 0 ]]; then
    echo -e "${GREEN}✓ GPIO cleanup successful${NC}"
    echo "System is ready for testing"
else
    echo -e "${YELLOW}⚠ Some GPIO resources still in use${NC}"
    echo "Run with --force to terminate processes"
fi

echo
echo "=== Usage Tips ==="
echo "1. Use this script before running HAL tests"
echo "2. Use this script after failed tests to clean up"
echo "3. Run with --force if processes are stuck"
echo "4. Only one LED controller should be active at a time"
