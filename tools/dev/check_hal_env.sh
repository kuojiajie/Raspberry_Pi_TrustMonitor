#!/bin/bash

# ==============================================================================
# TrustMonitor HAL Environment Check
# ==============================================================================
# This script checks the Python environment and HAL dependencies
# Usage: ./check_hal_env.sh
# ==============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== TrustMonitor HAL Environment Check ==="
echo

# Check Python version
echo -n "Python version: "
if python3 --version 2>/dev/null; then
    echo -e " ${GREEN}✓${NC}"
else
    echo -e " ${RED}✗${NC}"
    exit 1
fi

# Check Python path
echo -n "Python path: "
if python3 -c "import sys; print('OK')" 2>/dev/null; then
    echo -e " ${GREEN}✓${NC}"
else
    echo -e " ${RED}✗${NC}"
    exit 1
fi

# Check RPi.GPIO
echo -n "RPi.GPIO: "
if python3 -c "import RPi.GPIO as GPIO; print('v' + GPIO.VERSION)" 2>/dev/null; then
    echo -e " ${GREEN}✓${NC}"
else
    echo -e " ${RED}✗${NC}"
    echo "  Install: sudo apt-get install python3-rpi.gpio"
    exit 1
fi

# Check hardware package
echo -n "Hardware package: "
if python3 -c "import hardware; print('OK')" 2>/dev/null; then
    echo -e " ${GREEN}✓${NC}"
else
    echo -e " ${RED}✗${NC}"
    echo "  Check: hardware/__init__.py and PYTHONPATH"
    exit 1
fi

# Check HAL interface
echo -n "HAL interface: "
if python3 -c "import hardware.hal_interface; print('OK')" 2>/dev/null; then
    echo -e " ${GREEN}✓${NC}"
else
    echo -e " ${RED}✗${NC}"
    echo "  Check: hardware/hal_interface.py"
    exit 1
fi

# Check HAL sensors
echo -n "HAL sensors: "
if python3 -c "import hardware.hal_sensors; print('OK')" 2>/dev/null; then
    echo -e " ${GREEN}✓${NC}"
else
    echo -e " ${RED}✗${NC}"
    echo "  Check: hardware/hal_sensors.py"
    exit 1
fi

# Check HAL indicators
echo -n "HAL indicators: "
if python3 -c "import hardware.hal_indicators; print('OK')" 2>/dev/null; then
    echo -e " ${GREEN}✓${NC}"
else
    echo -e " ${RED}✗${NC}"
    echo "  Check: hardware/hal_indicators.py"
    exit 1
fi

# Check GPIO devices
echo -n "GPIO devices: "
if ls /dev/gpio* /dev/gpiomem >/dev/null 2>&1; then
    echo -e " ${GREEN}✓${NC}"
else
    echo -e " ${YELLOW}⚠${NC} (simulation mode)"
fi

# Check GPIO permissions
echo -n "GPIO permissions: "
if groups | grep -q gpio; then
    echo -e " ${GREEN}✓${NC}"
else
    echo -e " ${YELLOW}⚠${NC} (user not in gpio group)"
fi

# Check for conflicting processes
echo -n "GPIO conflicts: "
if lsof /dev/gpio* 2>/dev/null | grep -q .; then
    echo -e " ${YELLOW}⚠${NC} (processes using GPIO)"
    lsof /dev/gpio* 2>/dev/null
else
    echo -e " ${GREEN}✓${NC}"
fi

echo
echo "=== HAL Initialization Test ==="

# Test HAL initialization
echo -n "HAL initialization: "
if python3 -c "
import hardware.hal_interface
from hardware.hal_interface import get_hal
hal = get_hal()
config = {
    'dht11_sensor': {'pin': 'D17', 'max_retries': 1},
    'rgb_led': {'pins': {'red': 27, 'green': 22, 'blue': 5}}
}
if hal.initialize(config):
    print('OK')
    hal.cleanup()
else:
    print('FAILED')
    exit(1)
" 2>/dev/null; then
    echo -e " ${GREEN}✓${NC}"
else
    echo -e " ${RED}✗${NC}"
    echo "  HAL initialization failed"
    exit 1
fi

echo
echo "=== Environment Summary ==="
echo "All HAL dependencies are properly installed and configured."
echo "The HAL system should work correctly."
echo
echo "If tests still fail, the issue might be:"
echo "1. Timing issues during concurrent test execution"
echo "2. GPIO device state conflicts"
echo "3. Hardware-specific issues (sensor/LED connectivity)"
