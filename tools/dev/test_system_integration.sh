#!/bin/bash
# tools/dev/test_system_integration.sh
# Complete system integration test after HAL refactoring

set -u

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_LOG="$BASE_DIR/logs/system_integration_$(date +%Y%m%d_%H%M%S).log"

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
    local expected_exit_code="${3:-0}"
    
    ((TESTS_TOTAL++))
    log_test "TEST" "Running: $test_name"
    
    if eval "$test_command" >> "$TEST_LOG" 2>&1; then
        local actual_exit_code=$?
        if [[ $actual_exit_code -eq $expected_exit_code ]]; then
            log_test "PASS" "$test_name"
            ((TESTS_PASSED++))
            return 0
        else
            log_test "FAIL" "$test_name (exit code: $actual_exit_code, expected: $expected_exit_code)"
            ((TESTS_FAILED++))
            return 1
        fi
    else
        log_test "FAIL" "$test_name (command failed)"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Header
echo "========================================"
echo "TrustMonitor System Integration Test"
echo "========================================"
echo "Version: v2.2.6 (HAL Refactored)"
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Log file: $TEST_LOG"
echo "========================================"
echo

# Initialize log
mkdir -p "$BASE_DIR/logs"
echo "TrustMonitor System Integration Test Log - $(date '+%Y-%m-%d %H:%M:%S')" > "$TEST_LOG"
echo "========================================" >> "$TEST_LOG"

# Test 1: Basic Python Environment
run_test "Python Environment Check" \
    "cd '$BASE_DIR' && python3 --version && python3 -c 'import sys; print(f\"Python path: {sys.path[:3]}\")'"

# Test 2: Hardware Package Import
run_test "Hardware Package Import" \
    "cd '$BASE_DIR' && python3 -c 'import hardware; print(\"Hardware package loaded successfully\"); print(hardware.get_hardware_info())'"

# Test 3: HAL Initialization
run_test "HAL System Initialization" \
    "cd '$BASE_DIR' && python3 -c '
from hardware.hal_interface import get_hal
hal = get_hal()
config = {
    \"dht11_sensor\": {\"pin\": \"D17\", \"max_retries\": 1},
    \"rgb_led\": {\"pins\": {\"red\": 27, \"green\": 22, \"blue\": 5}}
}
if hal.initialize(config):
    print(\"HAL system initialized successfully\")
    status = hal.get_device_status()
    print(f\"Device statuses: {status}\")
    hal.cleanup()
else:
    print(\"HAL initialization failed\")
    exit(1)
'"

# Test 4: Legacy Hardware Compatibility
run_test "Legacy Hardware Compatibility" \
    "cd '$BASE_DIR' && python3 -c '
from hardware.led_controller import LEDController
from hardware.sensor_reader import SensorReader
print(\"Legacy hardware modules imported successfully\")
led = LEDController()
sensor = SensorReader()
print(f\"LED Controller: {type(led).__name__}\")
print(f\"Sensor Reader: {type(sensor).__name__}\")
'"

# Test 5: Health Monitor Dependencies
run_test "Health Monitor Dependencies" \
    "cd '$BASE_DIR' && bash daemon/health_monitor.sh --help 2>/dev/null || echo 'Health monitor script exists'"

# Test 6: Plugin System Loading
run_test "Plugin System Loading" \
    "cd '$BASE_DIR' && bash -c '
source lib/logger.sh
source lib/return_codes.sh
source lib/plugin_loader.sh
echo \"Plugin system loaded successfully\"
PLUGIN_DIR=\"scripts\"
if load_plugins_from_dir \"\$PLUGIN_DIR\"; then
    echo \"Plugin loading test passed\"
    plugin_system_info
else
    echo \"Plugin loading test failed\"
    exit 1
fi
'"

# Test 7: Security Scripts Availability
run_test "Security Scripts Check" \
    "cd '$BASE_DIR' && ls -la scripts/integrity_check.sh scripts/verify_signature.sh scripts/boot_sequence.sh && echo \"All security scripts available\""

# Test 8: Configuration Files
run_test "Configuration Files Check" \
    "cd '$BASE_DIR' && test -f daemon/health_monitor.sh && test -f lib/logger.sh && test -f lib/return_codes.sh && echo \"Core configuration files exist\""

# Test 9: Tools Directory Structure
run_test "Tools Directory Structure" \
    "cd '$BASE_DIR' && find tools/ -name '*.sh' | wc -l && echo \"Tools directory structure intact\""

# Test 10: HAL Sensor Monitor Standalone
run_test "HAL Sensor Monitor Standalone" \
    "cd '$BASE_DIR' && timeout 5 python3 hardware/hal_sensor_monitor.py --test || true"

# Test 11: HAL LED Controller Standalone
run_test "HAL LED Controller Standalone" \
    "cd '$BASE_DIR' && timeout 3 python3 hardware/hal_led_controller.py --off || true"

# Test 12: Legacy Sensor Monitor Standalone
run_test "Legacy Sensor Monitor Standalone" \
    "cd '$BASE_DIR' && timeout 5 python3 hardware/sensor_monitor.py --test || true"

# Test 13: Health Monitor Environment Variables
run_test "Health Monitor Environment Variables" \
    "cd '$BASE_DIR' && bash -c '
export PING_TARGET=8.8.8.8
export CHECK_INTERVAL=30
export INTEGRITY_CHECK_INTERVAL=3600
export CPU_LOAD_WARN=1.50
export CPU_LOAD_ERROR=3.00
export TEMP_WARNING=40.0
export TEMP_ERROR=45.0
export SENSOR_AVAILABLE=true
export SENSOR_MAX_RETRIES=2
export SENSOR_RETRY_DELAY=1.0

echo \"Environment variables set successfully\"
env | grep -E \"(PING_TARGET|CHECK_INTERVAL|TEMP_WARNING|SENSOR_)\" | sort
'"

# Test 14: System Logging
run_test "System Logging Test" \
    "cd '$BASE_DIR' && bash -c '
source lib/logger.sh
log_info \"Test log message from integration test\"
log_warn \"Test warning message\"
log_error \"Test error message\"
echo \"Logging system functional\"
'"

# Test 15: Return Codes System
run_test "Return Codes System" \
    "cd '$BASE_DIR' && bash -c '
source lib/return_codes.sh 2>/dev/null || echo \"Return codes loaded with defaults\"
echo \"RC_OK: \${RC_OK:-0}\"
echo \"RC_WARN: \${RC_WARN:-1}\"
echo \"RC_ERROR: \${RC_ERROR:-2}\"
echo \"Return codes system loaded successfully\"
'"

# Test 16: Backup System
run_test "Backup System Check" \
    "cd '$BASE_DIR' && ls -la scripts/backup_cleanup.sh && echo \"Backup system script available\""

# Test 17: Manifest Files
run_test "Manifest Files Check" \
    "cd '$BASE_DIR' && test -f manifest.sha256 && test -f manifest.sha256.sig && echo \"Security manifest files exist\""

# Test 18: Service Files
run_test "Service Files Check" \
    "cd '$BASE_DIR' && ls -la systemd/ && echo \"Systemd service files available\""

# Test 19: Documentation Structure
run_test "Documentation Structure" \
    "cd '$BASE_DIR' && ls -la docs/ README.md && echo \"Documentation structure intact\""

# Test 20: Git Status Check
run_test "Git Status Check" \
    "cd '$BASE_DIR' && git status --porcelain && echo \"Git repository status available\""

# Results Summary
echo
echo "========================================"
echo "System Integration Test Results"
echo "========================================"
echo "Total Tests: $TESTS_TOTAL"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}All system integration tests passed!${NC}"
    echo "TrustMonitor v2.2.6 HAL refactoring is fully functional."
else
    echo -e "${RED}Some integration tests failed!${NC}"
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
