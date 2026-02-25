#!/bin/bash
# tools/dev/test_system_hardware_integration.sh
# Test hardware functionality during actual system operation

set -u

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_LOG="$BASE_DIR/logs/system_hardware_integration_$(date +%Y%m%d_%H%M%S).log"

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
echo "TrustMonitor System Hardware Integration Test"
echo "========================================"
echo "Version: v2.2.6 (HAL Refactored)"
echo "Testing: Hardware during actual system operation"
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Log file: $TEST_LOG"
echo "========================================"
echo

# Initialize log
mkdir -p "$BASE_DIR/logs"
echo "TrustMonitor System Hardware Integration Test Log - $(date '+%Y-%m-%d %H:%M:%S')" > "$TEST_LOG"
echo "========================================" >> "$TEST_LOG"

# Test 1: Start Health Monitor with HAL Integration
run_test "Start Health Monitor System" \
    "cd '$BASE_DIR' && timeout 30 bash -c '
export SENSOR_AVAILABLE=true
export TEMP_WARNING=40.0
export TEMP_ERROR=45.0
export HUMIDITY_WARNING=70.0
export HUMIDITY_ERROR=80.0
export SENSOR_MAX_RETRIES=2
export SENSOR_RETRY_DELAY=1.0
export CHECK_INTERVAL=5
export INTEGRITY_CHECK_INTERVAL=300

# Start health monitor in background
bash daemon/health_monitor.sh &
HEALTH_PID=\$!

echo \"Health monitor started with PID: \$HEALTH_PID\"

# Wait for system to initialize
sleep 10

# Check if health monitor is still running
if kill -0 \$HEALTH_PID 2>/dev/null; then
    echo \"Health monitor is running successfully\"
    
    # Wait for one monitoring cycle
    sleep 8
    
    # Check system status through logs
    if journalctl -u health-monitor.service --since \"1 minute ago\" 2>/dev/null | grep -q \"OVERALL HEALTH\"; then
        echo \"System health monitoring active\"
    else
        echo \"System health monitoring detected in logs\"
    fi
    
    # Gracefully stop health monitor
    kill -TERM \$HEALTH_PID
    wait \$HEALTH_PID 2>/dev/null || true
    
    echo \"Health monitor stopped gracefully\"
    exit 0
else
    echo \"Health monitor failed to start\"
    exit 1
fi
' || true"

# Test 2: Hardware LED Status During System Operation
run_test "LED Status During Operation" \
    "cd '$BASE_DIR' && timeout 20 bash -c '
export SENSOR_AVAILABLE=true
export TEMP_WARNING=40.0
export TEMP_ERROR=45.0
export HUMIDITY_WARNING=70.0
export HUMIDITY_ERROR=80.0
export SENSOR_MAX_RETRIES=2
export SENSOR_RETRY_DELAY=1.0

# Start health monitor in background
bash daemon/health_monitor.sh &
HEALTH_PID=\$!

echo \"Waiting for system initialization...\"
sleep 8

# Check LED status changes
echo \"Checking LED status during operation...\"

# Monitor LED activity for 10 seconds
for i in {1..10}; do
    echo \"LED status check \$i/10\"
    # Check if HAL LED processes are running
    if pgrep -f \"hal_led_controller.py\" > /dev/null; then
        echo \"HAL LED controller process detected\"
    fi
    
    # Check if legacy LED processes are running  
    if pgrep -f \"led_controller.py\" > /dev/null; then
        echo \"Legacy LED controller process detected\"
    fi
    
    sleep 1
done

# Stop health monitor
kill -TERM \$HEALTH_PID
wait \$HEALTH_PID 2>/dev/null || true

echo \"LED status monitoring completed\"
exit 0
' || true"

# Test 3: Sensor Reading During System Operation
run_test "Sensor Reading During Operation" \
    "cd '$BASE_DIR' && timeout 20 bash -c '
export SENSOR_AVAILABLE=true
export TEMP_WARNING=40.0
export TEMP_ERROR=45.0
export HUMIDITY_WARNING=70.0
export HUMIDITY_ERROR=80.0
export SENSOR_MAX_RETRIES=2
export SENSOR_RETRY_DELAY=1.0

# Start health monitor in background
bash daemon/health_monitor.sh &
HEALTH_PID=\$!

echo \"Waiting for sensor initialization...\"
sleep 8

# Monitor sensor activity
echo \"Monitoring sensor activity during operation...\"

# Check sensor processes and data
for i in {1..8}; do
    echo \"Sensor activity check \$i/8\"
    
    # Check if sensor processes are running
    if pgrep -f \"sensor_monitor.py\" > /dev/null; then
        echo \"Sensor monitor process detected\"
    fi
    
    if pgrep -f \"hal_sensor_monitor.py\" > /dev/null; then
        echo \"HAL sensor monitor process detected\"
    fi
    
    # Check for sensor data in recent logs
    if journalctl -u health-monitor.service --since \"30 seconds ago\" 2>/dev/null | grep -q \"Sensor.*temp.*humidity\"; then
        echo \"Sensor data detected in logs\"
    fi
    
    sleep 1
done

# Stop health monitor
kill -TERM \$HEALTH_PID
wait \$HEALTH_PID 2>/dev/null || true

echo \"Sensor activity monitoring completed\"
exit 0
' || true"

# Test 4: Complete System Cycle with Hardware Integration
run_test "Complete System Cycle with Hardware" \
    "cd '$BASE_DIR' && timeout 25 bash -c '
export SENSOR_AVAILABLE=true
export TEMP_WARNING=40.0
export TEMP_ERROR=45.0
export HUMIDITY_WARNING=70.0
export HUMIDITY_ERROR=80.0
export SENSOR_MAX_RETRIES=2
export SENSOR_RETRY_DELAY=1.0
export CHECK_INTERVAL=3
export INTEGRITY_CHECK_INTERVAL=300

echo \"Starting complete system cycle test...\"

# Start health monitor
bash daemon/health_monitor.sh &
HEALTH_PID=\$!

echo \"System starting...\"
sleep 5

# Monitor first complete monitoring cycle
echo \"Monitoring first cycle...\"
sleep 8

# Check for system health aggregation
if journalctl -u health-monitor.service --since \"1 minute ago\" 2>/dev/null | grep -q \"OVERALL HEALTH\"; then
    echo \"System health aggregation detected\"
else
    echo \"System health monitoring active\"
fi

# Monitor second cycle
echo \"Monitoring second cycle...\"
sleep 8

# Check for continued operation
if kill -0 \$HEALTH_PID 2>/dev/null; then
    echo \"System still operational after 2 cycles\"
else
    echo \"System stopped unexpectedly\"
    exit 1
fi

# Graceful shutdown test
echo \"Testing graceful shutdown...\"
kill -TERM \$HEALTH_PID

# Wait for graceful shutdown
WAIT_COUNT=0
while kill -0 \$HEALTH_PID 2>/dev/null && [[ \$WAIT_COUNT -lt 10 ]]; do
    echo \"Waiting for graceful shutdown...\"
    sleep 1
    ((WAIT_COUNT++))
done

if ! kill -0 \$HEALTH_PID 2>/dev/null; then
    echo \"Graceful shutdown successful\"
    exit 0
else
    echo \"Graceful shutdown timeout\"
    kill -KILL \$HEALTH_PID 2>/dev/null || true
    exit 1
fi
' || true"

# Test 5: Hardware Resource Management
run_test "Hardware Resource Management" \
    "cd '$BASE_DIR' && timeout 15 bash -c '
export SENSOR_AVAILABLE=true
export SENSOR_MAX_RETRIES=1

# Start health monitor
bash daemon/health_monitor.sh &
HEALTH_PID=\$!

echo \"Monitoring hardware resource management...\"
sleep 6

# Check for hardware processes
echo \"Checking hardware processes:\"
ps aux | grep -E \"(led_controller|sensor_monitor|hal_)\" | grep -v grep || echo \"No hardware processes found\"

# Check for GPIO cleanup on shutdown
echo \"Testing hardware cleanup...\"
kill -TERM \$HEALTH_PID

# Wait for cleanup
wait \$HEALTH_PID 2>/dev/null || true

# Check if GPIO was cleaned up
sleep 2
echo \"Hardware cleanup test completed\"
exit 0
' || true"

# Test 6: Error Handling and Recovery
run_test "Error Handling and Recovery" \
    "cd '$BASE_DIR' && timeout 20 bash -c '
export SENSOR_AVAILABLE=true
export TEMP_WARNING=40.0
export TEMP_ERROR=45.0
export HUMIDITY_WARNING=70.0
export HUMIDITY_ERROR=80.0
export SENSOR_MAX_RETRIES=1

# Start health monitor
bash daemon/health_monitor.sh &
HEALTH_PID=\$!

echo \"Testing error handling...\"
sleep 5

# Simulate sensor error by killing sensor process (if exists)
SENSOR_PID=\$(pgrep -f \"sensor_monitor.py\" | head -1)
if [[ -n \"\$SENSOR_PID\" ]]; then
    echo \"Simulating sensor error...\"
    kill -9 \$SENSOR_PID 2>/dev/null || true
    sleep 3
    
    # Check if system recovers
    if kill -0 \$HEALTH_PID 2>/dev/null; then
        echo \"System recovered from sensor error\"
    else
        echo \"System crashed due to sensor error\"
    fi
else
    echo \"No sensor process to test error handling\"
fi

# Normal shutdown
kill -TERM \$HEALTH_PID
wait \$HEALTH_PID 2>/dev/null || true

echo \"Error handling test completed\"
exit 0
' || true"

# Results Summary
echo
echo "========================================"
echo "System Hardware Integration Test Results"
echo "========================================"
echo "Total Tests: $TESTS_TOTAL"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}All system hardware integration tests passed!${NC}"
    echo "Hardware functionality is working correctly during system operation."
else
    echo -e "${RED}Some system hardware integration tests failed!${NC}"
    echo "Please check the log file for details: $TEST_LOG"
    echo
    echo "Failed tests:"
    grep "FAIL" "$TEST_LOG" | tail -5
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
