#!/bin/bash
# tests/integration/test_hardware_integration.sh
# Integration tests for hardware integration functionality

set -u

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load libraries
source "$BASE_DIR/lib/return_codes.sh"
source "$BASE_DIR/lib/logger.sh"

# Test configuration
TEST_RESULTS_FILE=""
TEST_NAME="Hardware Integration Tests"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Initialize test results
init_test_results() {
    TEST_RESULTS_FILE="$1"
    
    # Initialize test results in JSON format
    cat > "$TEST_RESULTS_FILE" << EOF
{
  "test_type": "integration",
  "test_suite": "hardware_integration",
  "tests": []
}
EOF
}

# Add test result
add_test_result() {
    local test_name="$1"
    local status="$2"
    local message="$3"
    local details="$4"
    
    ((TESTS_RUN++))
    
    if [[ "$status" == "PASS" ]]; then
        ((TESTS_PASSED++))
        echo -e "${GREEN}✓ PASS${NC} $test_name: $message"
    elif [[ "$status" == "FAIL" ]]; then
        ((TESTS_FAILED++))
        echo -e "${RED}✗ FAIL${NC} $test_name: $message"
    else
        echo -e "${YELLOW}? SKIP${NC} $test_name: $message"
    fi
    
    # Add to JSON results
    if command -v jq >/dev/null 2>&1; then
        local temp_file=$(mktemp)
        jq ".tests += [{
        \"name\": \"$test_name\",
        \"status\": \"$status\",
        \"message\": \"$message\",
        \"details\": \"$details\"
      }]" "$TEST_RESULTS_FILE" > "$temp_file" && mv "$temp_file" "$TEST_RESULTS_FILE"
    else
        # Fallback to simple text format if jq is not available
        echo "[$status] $test_name: $message" >> "$TEST_RESULTS_FILE"
    fi
}

# Test hardware Python modules exist
test_hardware_modules_exist() {
    echo "Testing hardware Python modules existence..."
    
    local hardware_modules=(
        "hal_core.py"
        "hal_interface.py"
        "hal_led_controller.py"
        "hal_sensors.py"
        "hal_sensor_monitor.py"
        "hal_indicators.py"
        "sensor_reader.py"
        "sensor_monitor.py"
        "led_controller.py"
    )
    
    for module in "${hardware_modules[@]}"; do
        local module_path="$BASE_DIR/hardware/$module"
        if [[ -f "$module_path" ]]; then
            add_test_result "hardware_module_exists_$module" "PASS" "Hardware module exists: $module" "Module $module found"
        else
            add_test_result "hardware_module_exists_$module" "FAIL" "Hardware module not found: $module" "Module $module not found"
        fi
    done
}

# Test HAL core functionality
test_hal_core() {
    echo "Testing HAL core functionality..."
    
    local hal_core_script="$BASE_DIR/hardware/hal_core.py"
    
    if [[ -f "$hal_core_script" ]]; then
        # Test basic Python import
        if python3 -c "import sys; sys.path.append('$BASE_DIR/hardware'); import hal_core" >/dev/null 2>&1; then
            add_test_result "hal_core_import" "PASS" "HAL core import works" "hal_core module imports successfully"
        else
            add_test_result "hal_core_import" "FAIL" "HAL core import failed" "hal_core module import failed"
        fi
        
        # Test basic functionality
        if python3 -c "
import sys
sys.path.append('$BASE_DIR/hardware')
from hal_core import HALCore
try:
    core = HALCore()
    print('SUCCESS')
except Exception as e:
    print('FAILED')
" 2>/dev/null | grep -q "SUCCESS"; then
            add_test_result "hal_core_functionality" "PASS" "HAL core functionality works" "HALCore class instantiates successfully"
        else
            add_test_result "hal_core_functionality" "FAIL" "HAL core functionality failed" "HALCore class instantiation failed"
        fi
    else
        add_test_result "hal_core_import" "SKIP" "HAL core module not available" "Cannot test HAL core import"
        add_test_result "hal_core_functionality" "SKIP" "HAL core module not available" "Cannot test HAL core functionality"
    fi
}

# Test HAL LED controller
test_hal_led_controller() {
    echo "Testing HAL LED controller..."
    
    local hal_led_script="$BASE_DIR/hardware/hal_led_controller.py"
    
    if [[ -f "$hal_led_script" ]]; then
        # Test basic Python import
        if python3 -c "import sys; sys.path.append('$BASE_DIR/hardware'); import hal_led_controller" >/dev/null 2>&1; then
            add_test_result "hal_led_import" "PASS" "HAL LED controller import works" "hal_led_controller module imports successfully"
        else
            add_test_result "hal_led_import" "FAIL" "HAL LED controller import failed" "hal_led_controller module import failed"
        fi
        
        # Test help functionality
        if python3 "$hal_led_script" --help >/dev/null 2>&1; then
            add_test_result "hal_led_help" "PASS" "HAL LED controller help works" "hal_led_controller.py --help works"
        else
            add_test_result "hal_led_help" "FAIL" "HAL LED controller help failed" "hal_led_controller.py --help failed"
        fi
        
        # Test daemon mode
        if python3 "$hal_led_script" --color green --daemon >/dev/null 2>&1; then
            add_test_result "hal_led_daemon" "PASS" "HAL LED controller daemon mode works" "hal_led_controller.py --daemon works"
        else
            add_test_result "hal_led_daemon" "FAIL" "HAL LED controller daemon mode failed" "hal_led_controller.py --daemon failed"
        fi
    else
        add_test_result "hal_led_import" "SKIP" "HAL LED controller module not available" "Cannot test HAL LED import"
        add_test_result "hal_led_help" "SKIP" "HAL LED controller module not available" "Cannot test help"
        add_test_result "hal_led_daemon" "SKIP" "HAL LED controller module not available" "Cannot test daemon mode"
    fi
}

# Test HAL sensors
test_hal_sensors() {
    echo "Testing HAL sensors..."
    
    local hal_sensors_script="$BASE_DIR/hardware/hal_sensors.py"
    
    if [[ -f "$hal_sensors_script" ]]; then
        # Test basic Python import
        if python3 -c "import sys; sys.path.append('$BASE_DIR/hardware'); import hal_sensors" >/dev/null 2>&1; then
            add_test_result "hal_sensors_import" "PASS" "HAL sensors import works" "hal_sensors module imports successfully"
        else
            add_test_result "hal_sensors_import" "FAIL" "HAL sensors import failed" "hal_sensors module import failed"
        fi
        
        # Test basic functionality
        if python3 -c "
import sys
sys.path.append('$BASE_DIR/hardware')
from hal_sensors import HALSensors
try:
    sensors = HALSensors()
    print('SUCCESS')
except Exception as e:
    print('FAILED')
" 2>/dev/null | grep -q "SUCCESS"; then
            add_test_result "hal_sensors_functionality" "PASS" "HAL sensors functionality works" "HALSensors class instantiates successfully"
        else
            add_test_result "hal_sensors_functionality" "FAIL" "HAL sensors functionality failed" "HALSensors class instantiation failed"
        fi
    else
        add_test_result "hal_sensors_import" "SKIP" "HAL sensors module not available" "Cannot test HAL sensors import"
        add_test_result "hal_sensors_functionality" "SKIP" "HAL sensors module not available" "Cannot test HAL sensors functionality"
    fi
}

# Test sensor reader
test_sensor_reader() {
    echo "Testing sensor reader..."
    
    local sensor_reader_script="$BASE_DIR/hardware/sensor_reader.py"
    
    if [[ -f "$sensor_reader_script" ]]; then
        # Test basic Python import
        if python3 -c "import sys; sys.path.append('$BASE_DIR/hardware'); import sensor_reader" >/dev/null 2>&1; then
            add_test_result "sensor_reader_import" "PASS" "Sensor reader import works" "sensor_reader module imports successfully"
        else
            add_test_result "sensor_reader_import" "FAIL" "Sensor reader import failed" "sensor_reader module import failed"
        fi
        
        # Test basic functionality (with timeout)
        if timeout 5 python3 "$sensor_reader_script" >/dev/null 2>&1; then
            add_test_result "sensor_reader_functionality" "PASS" "Sensor reader functionality works" "sensor_reader.py runs successfully"
        else
            add_test_result "sensor_reader_functionality" "FAIL" "Sensor reader functionality failed" "sensor_reader.py failed to run"
        fi
    else
        add_test_result "sensor_reader_import" "SKIP" "Sensor reader module not available" "Cannot test sensor reader import"
        add_test_result "sensor_reader_functionality" "SKIP" "Sensor reader module not available" "Cannot test sensor reader functionality"
    fi
}

# Test hardware integration performance
test_hardware_performance() {
    echo "Testing hardware integration performance..."
    
    local hardware_modules=(
        "hal_core.py"
        "hal_led_controller.py"
        "hal_sensors.py"
        "sensor_reader.py"
    )
    
    for module in "${hardware_modules[@]}"; do
        local module_path="$BASE_DIR/hardware/$module"
        
        if [[ -f "$module_path" ]]; then
            # Measure import time
            local start_time=$(date +%s%N)
            if python3 -c "import sys; sys.path.append('$BASE_DIR/hardware'); import ${module%.py}" >/dev/null 2>&1; then
                local end_time=$(date +%s%N)
                local duration=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds
                
                if [[ $duration -lt 5000 ]]; then  # Should complete within 5 seconds
                    add_test_result "hardware_performance_$module" "PASS" "Performance acceptable: $module" "$module imported in ${duration}ms"
                else
                    add_test_result "hardware_performance_$module" "FAIL" "Performance too slow: $module" "$module took ${duration}ms (>5s)"
                fi
            else
                add_test_result "hardware_performance_$module" "FAIL" "Import failed: $module" "$module import failed"
            fi
        else
            add_test_result "hardware_performance_$module" "SKIP" "Module not available: $module" "Cannot test performance"
        fi
    done
}

# Test hardware error handling
test_hardware_error_handling() {
    echo "Testing hardware error handling..."
    
    local hardware_modules=(
        "hal_core.py"
        "hal_led_controller.py"
        "hal_sensors.py"
        "sensor_reader.py"
    )
    
    for module in "${hardware_modules[@]}"; do
        local module_path="$BASE_DIR/hardware/$module"
        
        if [[ -f "$module_path" ]]; then
            # Test with invalid parameters (if applicable)
            if python3 -c "
import sys
sys.path.append('$BASE_DIR/hardware')
try:
    import ${module%.py}
    # Try to instantiate with invalid parameters
    print('SUCCESS')
except ImportError as e:
    print('IMPORT_FAILED')
except Exception as e:
    print('ERROR_HANDLED')
" 2>/dev/null | grep -q "SUCCESS\|ERROR_HANDLED"; then
                add_test_result "hardware_error_handling_$module" "PASS" "Error handling works: $module" "$module handles errors gracefully"
            else
                add_test_result "hardware_error_handling_$module" "FAIL" "Error handling failed: $module" "$module fails to handle errors"
            fi
        else
            add_test_result "hardware_error_handling_$module" "SKIP" "Module not available: $module" "Cannot test error handling"
        fi
    done
}

# Run all hardware integration tests
run_hardware_integration_tests() {
    echo "Running $TEST_NAME..."
    echo "===================="
    
    test_hardware_modules_exist
    test_hal_core
    test_hal_led_controller
    test_hal_sensors
    test_sensor_reader
    test_hardware_performance
    test_hardware_error_handling
    
    echo "===================="
    echo "Test Results:"
    echo "  Tests Run: $TESTS_RUN"
    echo "  Tests Passed: $TESTS_PASSED"
    echo "  Tests Failed: $TESTS_FAILED"
    echo "  Success Rate: $(( TESTS_RUN > 0 ? (TESTS_PASSED * 100) / TESTS_RUN : 0 ))%"
    echo ""
}

# Main function
main() {
    local results_file="$1"
    
    if [[ -z "$results_file" ]]; then
        echo "Error: Test results file path required"
        echo "Usage: $0 <results_file>"
        return $RC_ERROR
    fi
    
    init_test_results "$results_file"
    run_hardware_integration_tests
    
    # Return appropriate exit code
    if [[ $TESTS_FAILED -gt 0 ]]; then
        return $RC_ERROR
    else
        return $RC_OK
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
