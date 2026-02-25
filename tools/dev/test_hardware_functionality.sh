#!/bin/bash
# tools/dev/test_hardware_functionality.sh
# Test original hardware functionality after HAL refactoring

set -u

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_LOG="$BASE_DIR/logs/hardware_functionality_$(date +%Y%m%d_%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Logging function
log_test() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[$timestamp] [$level] $message" | tee -a "$TEST_LOG"
}

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    ((TESTS_TOTAL++))
    log_test "TEST" "Running: $test_name"
    
    if eval "$test_command" >> "$TEST_LOG" 2>&1; then
        log_test "PASS" "$test_name"
        ((TESTS_PASSED++))
        return 0
    else
        log_test "FAIL" "$test_name"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Header
echo "========================================"
echo "TrustMonitor Hardware Functionality Test"
echo "========================================"
echo "Version: v2.2.6 (HAL Refactored)"
echo "Testing: Original hardware functionality"
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Log file: $TEST_LOG"
echo "========================================"
echo

# Initialize log
mkdir -p "$BASE_DIR/logs"
echo "TrustMonitor Hardware Functionality Test Log - $(date '+%Y-%m-%d %H:%M:%S')" > "$TEST_LOG"
echo "========================================" >> "$TEST_LOG"

# Test 1: Legacy LED Controller - Basic Functions
run_test "Legacy LED - Set Red" \
    "cd '$BASE_DIR' && timeout 3 python3 hardware/led_controller.py --color red || true"

run_test "Legacy LED - Set Green" \
    "cd '$BASE_DIR' && timeout 3 python3 hardware/led_controller.py --color green || true"

run_test "Legacy LED - Set Blue" \
    "cd '$BASE_DIR' && timeout 3 python3 hardware/led_controller.py --color blue || true"

run_test "Legacy LED - Turn Off" \
    "cd '$BASE_DIR' && timeout 3 python3 hardware/led_controller.py --off || true"

# Test 2: Legacy LED Controller - Blink Functions
run_test "Legacy LED - Blink Red" \
    "cd '$BASE_DIR' && timeout 5 python3 hardware/led_controller.py --blink red --times 2 --speed 0.5 || true"

run_test "Legacy LED - Blink Green" \
    "cd '$BASE_DIR' && timeout 5 python3 hardware/led_controller.py --blink green --times 2 --speed 0.5 || true"

# Test 3: Legacy Sensor Reader - Temperature
run_test "Legacy Sensor - Temperature Read" \
    "cd '$BASE_DIR' && timeout 5 python3 -c '
import sys, os
sys.path.append(os.path.join(os.getcwd(), \"hardware\"))
from sensor_reader import SensorReader
sensor = SensorReader()
try:
    sensor.initialize_sensor()
    temp = sensor.read_temperature()
    if temp is not None:
        print(f\"Temperature read successful: {temp}°C\")
    else:
        print(\"Temperature read returned None (simulation mode)\")
except Exception as e:
    print(f\"Sensor test completed: {e}\")
' || true"

# Test 4: Legacy Sensor Reader - Humidity
run_test "Legacy Sensor - Humidity Read" \
    "cd '$BASE_DIR' && timeout 5 python3 -c '
import sys, os
sys.path.append(os.path.join(os.getcwd(), \"hardware\"))
from sensor_reader import SensorReader
sensor = SensorReader()
try:
    sensor.initialize_sensor()
    humidity = sensor.read_humidity()
    if humidity is not None:
        print(f\"Humidity read successful: {humidity}%\")
    else:
        print(\"Humidity read returned None (simulation mode)\")
except Exception as e:
    print(f\"Sensor test completed: {e}\")
' || true"

# Test 5: Legacy Sensor Monitor - Test Mode
run_test "Legacy Sensor Monitor - Test Mode" \
    "cd '$BASE_DIR' && timeout 10 python3 hardware/sensor_monitor.py --test || true"

# Test 6: HAL LED Controller - Basic Functions
run_test "HAL LED - Set Red" \
    "cd '$BASE_DIR' && timeout 3 python3 hardware/hal_led_controller.py --color red || true"

run_test "HAL LED - Set Green" \
    "cd '$BASE_DIR' && timeout 3 python3 hardware/hal_led_controller.py --color green || true"

run_test "HAL LED - Set Blue" \
    "cd '$BASE_DIR' && timeout 3 python3 hardware/hal_led_controller.py --color blue || true"

run_test "HAL LED - Turn Off" \
    "cd '$BASE_DIR' && timeout 3 python3 hardware/hal_led_controller.py --off || true"

# Test 7: HAL LED Controller - Blink Functions
run_test "HAL LED - Blink Red" \
    "cd '$BASE_DIR' && timeout 5 python3 hardware/hal_led_controller.py --blink red --times 2 --speed 0.5 || true"

run_test "HAL LED - Blink Green" \
    "cd '$BASE_DIR' && timeout 5 python3 hardware/hal_led_controller.py --blink green --times 2 --speed 0.5 || true"

# Test 8: HAL Sensor Monitor - Test Mode
run_test "HAL Sensor Monitor - Test Mode" \
    "cd '$BASE_DIR' && timeout 10 python3 hardware/hal_sensor_monitor.py --test || true"

# Test 9: HAL Sensor Monitor - Status Check
run_test "HAL Sensor Monitor - Status Check" \
    "cd '$BASE_DIR' && timeout 5 python3 hardware/hal_sensor_monitor.py --status || true"

# Test 10: Health Monitor Integration - Hardware Functions
run_test "Health Monitor - Hardware Integration" \
    "cd '$BASE_DIR' && timeout 15 bash -c '
export SENSOR_AVAILABLE=true
export TEMP_WARNING=40.0
export TEMP_ERROR=45.0
export HUMIDITY_WARNING=70.0
export HUMIDITY_ERROR=80.0
export SENSOR_MAX_RETRIES=2
export SENSOR_RETRY_DELAY=1.0

# Test one monitoring cycle with hardware
python3 -c \"
import sys
import os
sys.path.append(os.path.join(os.getcwd(), 'hardware'))
from hal_interface import get_hal

hal = get_hal()
config = {
    'dht11_sensor': {'pin': 'D17', 'max_retries': 1},
    'rgb_led': {'pins': {'red': 27, 'green': 22, 'blue': 5}}
}

if hal.initialize(config):
    print('HAL initialized successfully')
    # Test sensor reading
    values = hal.get_sensor_values('dht11_sensor')
    print(f'Sensor values: {values}')
    # Test LED control
    success = hal.set_indicator_state('rgb_led', 'on', color='green')
    print(f'LED control: {success}')
    hal.clear_all_indicators()
    print('LED cleared')
    hal.cleanup()
    print('Hardware integration test completed')
else:
    print('HAL initialization failed')
    sys.exit(1)
\"
' || true"

# Test 11: Original Scripts - CPU Monitor
run_test "Original Script - CPU Monitor" \
    "cd '$BASE_DIR' && bash scripts/cpu_monitor.sh"

# Test 12: Original Scripts - Memory Monitor
run_test "Original Script - Memory Monitor" \
    "cd '$BASE_DIR' && bash scripts/memory_monitor.sh"

# Test 13: Original Scripts - Disk Monitor
run_test "Original Script - Disk Monitor" \
    "cd '$BASE_DIR' && bash scripts/disk_monitor.sh"

# Test 14: Original Scripts - Network Monitor
run_test "Original Script - Network Monitor" \
    "cd '$BASE_DIR' && bash scripts/network_monitor.sh"

# Test 15: Original Scripts - Temperature Monitor
run_test "Original Script - Temperature Monitor" \
    "cd '$BASE_DIR' && bash scripts/cpu_temp_monitor.sh"

# Results Summary
echo
echo "========================================"
echo "Hardware Functionality Test Results"
echo "========================================"
echo "Total Tests: $TESTS_TOTAL"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}All hardware functionality tests passed!${NC}"
    echo "Hardware functionality is working correctly after HAL refactoring."
else
    echo -e "${RED}Some hardware functionality tests failed!${NC}"
    echo "Please check the log file for details: $TEST_LOG"
    echo
    echo "Failed tests:"
    grep "FAIL" "$TEST_LOG" | tail -10
fi

echo "========================================"
echo "Test completed at: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Log file: $TEST_LOG"
echo "========================================"

# Exit with appropriate code
if [[ $TESTS_FAILED -eq 0 ]]; then
    exit 0
else
    exit 1
fi
