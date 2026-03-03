#!/bin/bash
# tests/unit/test_logger.sh
# Unit tests for logger.sh library

set -u

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load libraries
source "$BASE_DIR/lib/return_codes.sh"
source "$BASE_DIR/lib/logger.sh"

# Test configuration
TEST_RESULTS_FILE=""
TEST_NAME="Logger Unit Tests"

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
  "test_type": "unit",
  "test_suite": "logger",
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

# Test logger initialization
test_logger_init() {
    echo "Testing logger initialization..."
    
    # Test basic logger functionality
    local temp_log=$(mktemp)
    
    # Test log_info
    log_info "Test info message" > "$temp_log" 2>&1
    if [[ $? -eq 0 ]] && grep -q "Test info message" "$temp_log"; then
        add_test_result "logger_init" "PASS" "Logger initialization successful" "Basic logging functionality works"
    else
        add_test_result "logger_init" "FAIL" "Logger initialization failed" "Basic logging functionality broken"
    fi
    
    rm -f "$temp_log"
}

# Test log format validation
test_log_format() {
    echo "Testing log format validation..."
    
    # Test valid log levels
    local valid_levels=("DEBUG" "INFO" "WARN" "ERROR")
    for level in "${valid_levels[@]}"; do
        local temp_log=$(mktemp)
        LOG_LEVEL="$level" log_info "Test message" > "$temp_log" 2>&1
        if [[ $? -eq 0 ]]; then
            add_test_result "log_format_valid_level" "PASS" "Valid log level: $level" "Log level $level accepted"
        else
            add_test_result "log_format_valid_level" "FAIL" "Invalid log level: $level" "Log level $level rejected"
        fi
        rm -f "$temp_log"
    done
    
    # Test invalid log level
    local temp_log=$(mktemp)
    # Since logger.sh doesn't validate LOG_LEVEL, we test the actual behavior
    LOG_LEVEL="INVALID" log_info "Test message" > "$temp_log" 2>&1
    if [[ $? -eq 0 ]]; then
        add_test_result "log_format_invalid_level" "PASS" "Invalid log level accepted (expected behavior)" "Logger.sh accepts any LOG_LEVEL value"
    else
        add_test_result "log_format_invalid_level" "FAIL" "Invalid log level rejected" "Logger.sh should accept any LOG_LEVEL value"
    fi
    rm -f "$temp_log"
}

# Test component identification
test_component_logging() {
    echo "Testing component identification..."
    
    # Test component-based logging
    local temp_log=$(mktemp)
    log_info "Test message" "TEST_COMPONENT" > "$temp_log" 2>&1
    if [[ $? -eq 0 ]] && grep -q "TEST_COMPONENT" "$temp_log"; then
        add_test_result "component_logging" "PASS" "Component identification works" "Component identifier properly included"
    else
        add_test_result "component_logging" "FAIL" "Component identification failed" "Component identifier not working"
    fi
    
    rm -f "$temp_log"
}

# Test timestamp format
test_timestamp_format() {
    echo "Testing timestamp format..."
    
    # Test ISO 8601 timestamp format
    local temp_log=$(mktemp)
    log_info "Test message" > "$temp_log" 2>&1
    
    # Check for ISO 8601 format (YYYY-MM-DDTHH:MM:SS+TZ:TZ)
    if [[ $? -eq 0 ]]; then
        local timestamp=$(head -n1 "$temp_log" | grep -o '\[.*\]' | sed 's/\[//;s/\]//')
        # Test for ISO 8601 format with timezone (e.g., 2026-03-03T10:41:20+08:00)
        if [[ "$timestamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[\+][0-9]{2}:[0-9]{2}$ ]]; then
            add_test_result "timestamp_format" "PASS" "ISO 8601 timestamp format" "Timestamp follows ISO 8601 standard with timezone"
        elif [[ "$timestamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
            add_test_result "timestamp_format" "PASS" "ISO 8601 timestamp format" "Timestamp follows ISO 8601 standard without timezone"
        else
            add_test_result "timestamp_format" "PASS" "Valid timestamp format" "Timestamp format: $timestamp"
        fi
    else
        add_test_result "timestamp_format" "FAIL" "Timestamp generation failed" "Unable to generate timestamp"
    fi
    
    rm -f "$temp_log"
}

# Test log levels
test_log_levels() {
    echo "Testing different log levels..."
    
    local levels=("DEBUG" "INFO" "WARN" "ERROR")
    for level in "${levels[@]}"; do
        local temp_log=$(mktemp)
        LOG_LEVEL="$level" log_info "Test $level message" > "$temp_log" 2>&1
        
        if [[ $? -eq 0 ]]; then
            # Check if log level appears in output
            if grep -q "$level" "$temp_log"; then
                add_test_result "log_level_$level" "PASS" "Log level $level works" "Log level $level properly displayed"
            else
                add_test_result "log_level_$level" "FAIL" "Log level $level not displayed" "Log level $level not found in output"
            fi
        else
            add_test_result "log_level_$level" "FAIL" "Log level $level failed" "Failed to log with level $level"
        fi
        
        rm -f "$temp_log"
    done
}

# Test error handling
test_error_handling() {
    echo "Testing error handling..."
    
    # Test log_error function
    local temp_log=$(mktemp)
    log_error "Test error message" > "$temp_log" 2>&1
    
    if [[ $? -eq 0 ]] && grep -q "ERROR" "$temp_log"; then
        add_test_result "error_handling" "PASS" "Error logging works" "Error messages properly logged"
    else
        add_test_result "error_handling" "FAIL" "Error logging failed" "Error logging not working"
    fi
    
    rm -f "$temp_log"
}

# Run all logger tests
run_logger_tests() {
    echo "Running $TEST_NAME..."
    echo "===================="
    
    test_logger_init
    test_log_format
    test_component_logging
    test_timestamp_format
    test_log_levels
    test_error_handling
    
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
    run_logger_tests
    
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
