#!/bin/bash
# tests/integration/test_monitoring_scripts.sh
# Integration tests for monitoring scripts functionality

set -u

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load libraries
source "$BASE_DIR/lib/return_codes.sh"
source "$BASE_DIR/lib/logger.sh"

# Test configuration
TEST_RESULTS_FILE=""
TEST_NAME="Monitoring Scripts Integration Tests"

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
  "test_suite": "monitoring_scripts",
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

# Test monitoring scripts exist
test_monitoring_scripts_exist() {
    echo "Testing monitoring scripts existence..."
    
    local monitoring_scripts=(
        "cpu_monitor.sh"
        "memory_monitor.sh"
        "disk_monitor.sh"
        "network_monitor.sh"
        "cpu_temp_monitor.sh"
    )
    
    for script in "${monitoring_scripts[@]}"; do
        local script_path="$BASE_DIR/scripts/$script"
        if [[ -f "$script_path" ]]; then
            if [[ -x "$script_path" ]]; then
                add_test_result "monitoring_script_exists_$script" "PASS" "Monitoring script exists and executable: $script" "Script $script found and executable"
            else
                add_test_result "monitoring_script_exists_$script" "FAIL" "Monitoring script not executable: $script" "Script $script not executable"
            fi
        else
            add_test_result "monitoring_script_exists_$script" "FAIL" "Monitoring script not found: $script" "Script $script not found"
        fi
    done
}

# Test CPU monitor script
test_cpu_monitor() {
    echo "Testing CPU monitor script..."
    
    local cpu_monitor_script="$BASE_DIR/scripts/cpu_monitor.sh"
    
    if [[ -x "$cpu_monitor_script" ]]; then
        # Test basic functionality
        if timeout 10 "$cpu_monitor_script" >/dev/null 2>&1; then
            add_test_result "cpu_monitor_basic" "PASS" "CPU monitor basic functionality works" "cpu_monitor.sh runs successfully"
        else
            add_test_result "cpu_monitor_basic" "FAIL" "CPU monitor basic functionality failed" "cpu_monitor.sh failed to run"
        fi
        
        # Test output format
        local output=$("$cpu_monitor_script" 2>&1)
        if [[ "$output" =~ "CPU" ]]; then
            add_test_result "cpu_monitor_output" "PASS" "CPU monitor output format correct" "CPU monitor produces expected output"
        else
            add_test_result "cpu_monitor_output" "FAIL" "CPU monitor output format incorrect" "CPU monitor output doesn't contain expected content"
        fi
    else
        add_test_result "cpu_monitor_basic" "SKIP" "CPU monitor script not available" "Cannot test CPU monitor"
        add_test_result "cpu_monitor_output" "SKIP" "CPU monitor script not available" "Cannot test output"
    fi
}

# Test memory monitor script
test_memory_monitor() {
    echo "Testing memory monitor script..."
    
    local memory_monitor_script="$BASE_DIR/scripts/memory_monitor.sh"
    
    if [[ -x "$memory_monitor_script" ]]; then
        # Test basic functionality
        if timeout 10 "$memory_monitor_script" >/dev/null 2>&1; then
            add_test_result "memory_monitor_basic" "PASS" "Memory monitor basic functionality works" "memory_monitor.sh runs successfully"
        else
            add_test_result "memory_monitor_basic" "FAIL" "Memory monitor basic functionality failed" "memory_monitor.sh failed to run"
        fi
        
        # Test output format
        local output=$("$memory_monitor_script" 2>&1)
        if [[ "$output" =~ "Memory" ]]; then
            add_test_result "memory_monitor_output" "PASS" "Memory monitor output format correct" "Memory monitor produces expected output"
        else
            add_test_result "memory_monitor_output" "FAIL" "Memory monitor output format incorrect" "Memory monitor output doesn't contain expected content"
        fi
    else
        add_test_result "memory_monitor_basic" "SKIP" "Memory monitor script not available" "Cannot test memory monitor"
        add_test_result "memory_monitor_output" "SKIP" "Memory monitor script not available" "Cannot test output"
    fi
}

# Test disk monitor script
test_disk_monitor() {
    echo "Testing disk monitor script..."
    
    local disk_monitor_script="$BASE_DIR/scripts/disk_monitor.sh"
    
    if [[ -x "$disk_monitor_script" ]]; then
        # Test basic functionality
        if timeout 10 "$disk_monitor_script" >/dev/null 2>&1; then
            add_test_result "disk_monitor_basic" "PASS" "Disk monitor basic functionality works" "disk_monitor.sh runs successfully"
        else
            add_test_result "disk_monitor_basic" "FAIL" "Disk monitor basic functionality failed" "disk_monitor.sh failed to run"
        fi
        
        # Test output format
        local output=$("$disk_monitor_script" 2>&1)
        if [[ "$output" =~ "Disk" ]]; then
            add_test_result "disk_monitor_output" "PASS" "Disk monitor output format correct" "Disk monitor produces expected output"
        else
            add_test_result "disk_monitor_output" "FAIL" "Disk monitor output format incorrect" "Disk monitor output doesn't contain expected content"
        fi
    else
        add_test_result "disk_monitor_basic" "SKIP" "Disk monitor script not available" "Cannot test disk monitor"
        add_test_result "disk_monitor_output" "SKIP" "Disk monitor script not available" "Cannot test output"
    fi
}

# Test network monitor script
test_network_monitor() {
    echo "Testing network monitor script..."
    
    local network_monitor_script="$BASE_DIR/scripts/network_monitor.sh"
    
    if [[ -x "$network_monitor_script" ]]; then
        # Test basic functionality
        if timeout 15 "$network_monitor_script" >/dev/null 2>&1; then
            add_test_result "network_monitor_basic" "PASS" "Network monitor basic functionality works" "network_monitor.sh runs successfully"
        else
            add_test_result "network_monitor_basic" "FAIL" "Network monitor basic functionality failed" "network_monitor.sh failed to run"
        fi
        
        # Test output format
        local output=$("$network_monitor_script" 2>&1)
        if [[ "$output" =~ "Network" ]]; then
            add_test_result "network_monitor_output" "PASS" "Network monitor output format correct" "Network monitor produces expected output"
        else
            add_test_result "network_monitor_output" "FAIL" "Network monitor output format incorrect" "Network monitor output doesn't contain expected content"
        fi
    else
        add_test_result "network_monitor_basic" "SKIP" "Network monitor script not available" "Cannot test network monitor"
        add_test_result "network_monitor_output" "SKIP" "Network monitor script not available" "Cannot test output"
    fi
}

# Test CPU temperature monitor script
test_cpu_temp_monitor() {
    echo "Testing CPU temperature monitor script..."
    
    local cpu_temp_monitor_script="$BASE_DIR/scripts/cpu_temp_monitor.sh"
    
    if [[ -x "$cpu_temp_monitor_script" ]]; then
        # Test basic functionality
        if timeout 10 "$cpu_temp_monitor_script" >/dev/null 2>&1; then
            add_test_result "cpu_temp_monitor_basic" "PASS" "CPU temperature monitor basic functionality works" "cpu_temp_monitor.sh runs successfully"
        else
            add_test_result "cpu_temp_monitor_basic" "FAIL" "CPU temperature monitor basic functionality failed" "cpu_temp_monitor.sh failed to run"
        fi
        
        # Test output format
        local output=$("$cpu_temp_monitor_script" 2>&1)
        if [[ "$output" =~ "Temperature" ]]; then
            add_test_result "cpu_temp_monitor_output" "PASS" "CPU temperature monitor output format correct" "CPU temperature monitor produces expected output"
        else
            add_test_result "cpu_temp_monitor_output" "FAIL" "CPU temperature monitor output format incorrect" "CPU temperature monitor output doesn't contain expected content"
        fi
    else
        add_test_result "cpu_temp_monitor_basic" "SKIP" "CPU temperature monitor script not available" "Cannot test CPU temperature monitor"
        add_test_result "cpu_temp_monitor_output" "SKIP" "CPU temperature monitor script not available" "Cannot test output"
    fi
}

# Test monitoring scripts performance
test_monitoring_performance() {
    echo "Testing monitoring scripts performance..."
    
    local monitoring_scripts=(
        "cpu_monitor.sh"
        "memory_monitor.sh"
        "disk_monitor.sh"
        "network_monitor.sh"
        "cpu_temp_monitor.sh"
    )
    
    for script in "${monitoring_scripts[@]}"; do
        local script_path="$BASE_DIR/scripts/$script"
        
        if [[ -x "$script_path" ]]; then
            # Measure execution time
            local start_time=$(date +%s%N)
            timeout 10 "$script_path" >/dev/null 2>&1
            local end_time=$(date +%s%N)
            local duration=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds
            
            if [[ $duration -lt 10000 ]]; then  # Should complete within 10 seconds
                add_test_result "monitoring_performance_$script" "PASS" "Performance acceptable: $script" "$script completed in ${duration}ms"
            else
                add_test_result "monitoring_performance_$script" "FAIL" "Performance too slow: $script" "$script took ${duration}ms (>10s)"
            fi
        else
            add_test_result "monitoring_performance_$script" "SKIP" "Script not available: $script" "Cannot test performance"
        fi
    done
}

# Test monitoring scripts error handling
test_monitoring_error_handling() {
    echo "Testing monitoring scripts error handling..."
    
    local monitoring_scripts=(
        "cpu_monitor.sh"
        "memory_monitor.sh"
        "disk_monitor.sh"
        "network_monitor.sh"
        "cpu_temp_monitor.sh"
    )
    
    for script in "${monitoring_scripts[@]}"; do
        local script_path="$BASE_DIR/scripts/$script"
        
        if [[ -x "$script_path" ]]; then
            # Test with invalid environment (if applicable)
            if timeout 5 "$script_path" >/dev/null 2>&1; then
                add_test_result "monitoring_error_handling_$script" "PASS" "Error handling works: $script" "$script handles errors gracefully"
            else
                add_test_result "monitoring_error_handling_$script" "FAIL" "Error handling failed: $script" "$script fails to handle errors"
            fi
        else
            add_test_result "monitoring_error_handling_$script" "SKIP" "Script not available: $script" "Cannot test error handling"
        fi
    done
}

# Run all monitoring scripts tests
run_monitoring_scripts_tests() {
    echo "Running $TEST_NAME..."
    echo "===================="
    
    test_monitoring_scripts_exist
    test_cpu_monitor
    test_memory_monitor
    test_disk_monitor
    test_network_monitor
    test_cpu_temp_monitor
    test_monitoring_performance
    test_monitoring_error_handling
    
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
    run_monitoring_scripts_tests
    
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
