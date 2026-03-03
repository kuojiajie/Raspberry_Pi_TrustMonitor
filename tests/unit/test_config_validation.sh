#!/bin/bash
# tests/unit/test_config_validation.sh
# Unit tests for configuration validation system

set -u

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load libraries
source "$BASE_DIR/lib/return_codes.sh"
source "$BASE_DIR/lib/logger.sh"

# Test configuration
TEST_RESULTS_FILE=""
TEST_NAME="Configuration Validation Unit Tests"
TEST_CONFIG_FILE="$BASE_DIR/config/health-monitor.env.example"

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
  "test_suite": "config_validation",
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

# Test configuration validation tool exists
test_config_validation_tool_exists() {
    echo "Testing configuration validation tool existence..."
    
    local validation_tool="$BASE_DIR/tools/config/validate_config.sh"
    
    if [[ -f "$validation_tool" ]]; then
        if [[ -x "$validation_tool" ]]; then
            add_test_result "config_tool_exists" "PASS" "Configuration validation tool exists and executable" "validate_config.sh found and executable"
        else
            add_test_result "config_tool_exists" "FAIL" "Configuration validation tool not executable" "validate_config.sh not executable"
        fi
    else
        add_test_result "config_tool_exists" "FAIL" "Configuration validation tool not found" "validate_config.sh not found"
    fi
}

# Test configuration validation tool help
test_config_validation_help() {
    echo "Testing configuration validation tool help..."
    
    local validation_tool="$BASE_DIR/tools/config/validate_config.sh"
    
    if [[ -x "$validation_tool" ]]; then
        # Test help option
        if "$validation_tool" --help > /dev/null 2>&1; then
            add_test_result "config_help" "PASS" "Help option works" "validate_config.sh --help works"
        else
            add_test_result "config_help" "FAIL" "Help option failed" "validate_config.sh --help failed"
        fi
        
        # Test invalid option
        if "$validation_tool" --invalid-option > /dev/null 2>&1; then
            add_test_result "config_invalid_option" "FAIL" "Invalid option not rejected" "validate_config.sh should reject invalid options"
        else
            add_test_result "config_invalid_option" "PASS" "Invalid option properly rejected" "validate_config.sh properly rejects invalid options"
        fi
    else
        add_test_result "config_help" "SKIP" "Tool not executable" "Cannot test help functionality"
        add_test_result "config_invalid_option" "SKIP" "Tool not executable" "Cannot test invalid option handling"
    fi
}

# Test configuration validation with valid config
test_config_validation_valid_config() {
    echo "Testing configuration validation with valid config..."
    
    local validation_tool="$BASE_DIR/tools/config/validate_config.sh"
    
    if [[ -x "$validation_tool" && -f "$TEST_CONFIG_FILE" ]]; then
        # Test validation with valid config file
        if "$validation_tool" "$TEST_CONFIG_FILE" > /dev/null 2>&1; then
            add_test_result "config_valid" "PASS" "Valid configuration passes validation" "Valid config file passes validation"
        else
            add_test_result "config_valid" "FAIL" "Valid configuration fails validation" "Valid config file should pass validation"
        fi
        
        # Test validation with specific sections
        local sections=("dht11-only" "temp-only" "led-only" "network-only" "security-only" "system-only" "paths-only" "logging-only" "watchdog-only" "sel-only")
        
        for section in "${sections[@]}"; do
            if "$validation_tool" "--$section" "$TEST_CONFIG_FILE" > /dev/null 2>&1; then
                add_test_result "config_section_$section" "PASS" "Section validation works: $section" "Section $section validation passes"
            else
                add_test_result "config_section_$section" "FAIL" "Section validation fails: $section" "Section $section validation should pass"
            fi
        done
    else
        add_test_result "config_valid" "SKIP" "Tool or config not available" "Cannot test valid configuration"
        
        local sections=("dht11-only" "temp-only" "led-only" "network-only" "security-only" "system-only" "paths-only" "logging-only" "watchdog-only" "sel-only")
        for section in "${sections[@]}"; do
            add_test_result "config_section_$section" "SKIP" "Tool or config not available" "Cannot test section $section"
        done
    fi
}

# Test configuration validation with invalid config
test_config_validation_invalid_config() {
    echo "Testing configuration validation with invalid config..."
    
    local validation_tool="$BASE_DIR/tools/config/validate_config.sh"
    local invalid_config=$(mktemp)
    
    if [[ -x "$validation_tool" ]]; then
        # Create invalid config file
        cat > "$invalid_config" << EOF
# Invalid configuration file
DHT11_PIN=invalid_pin
CPU_LOAD_WARN=not_a_number
MEM_AVAIL_WARN_PCT=150
LED_RED_PIN=27
LED_GREEN_PIN=27
LED_BLUE_PIN=27
EOF
        
        # Test validation with invalid config
        if "$validation_tool" "$invalid_config" > /dev/null 2>&1; then
            add_test_result "config_invalid" "FAIL" "Invalid configuration passes validation" "Invalid config should fail validation"
        else
            add_test_result "config_invalid" "PASS" "Invalid configuration fails validation" "Invalid config properly rejected"
        fi
    else
        add_test_result "config_invalid" "SKIP" "Tool not available" "Cannot test invalid configuration"
    fi
    
    rm -f "$invalid_config"
}

# Test configuration validation with missing config
test_config_validation_missing_config() {
    echo "Testing configuration validation with missing config..."
    
    local validation_tool="$BASE_DIR/tools/config/validate_config.sh"
    local missing_config="/tmp/nonexistent_config.env"
    
    if [[ -x "$validation_tool" ]]; then
        # Test validation with missing config file
        if "$validation_tool" "$missing_config" > /dev/null 2>&1; then
            add_test_result "config_missing" "FAIL" "Missing configuration passes validation" "Missing config should fail validation"
        else
            add_test_result "config_missing" "PASS" "Missing configuration fails validation" "Missing config properly rejected"
        fi
    else
        add_test_result "config_missing" "SKIP" "Tool not available" "Cannot test missing configuration"
    fi
}

# Test configuration validation output formats
test_config_validation_output() {
    echo "Testing configuration validation output formats..."
    
    local validation_tool="$BASE_DIR/tools/config/validate_config.sh"
    
    if [[ -x "$validation_tool" && -f "$TEST_CONFIG_FILE" ]]; then
        # Test verbose output
        local verbose_output=$("$validation_tool" -v "$TEST_CONFIG_FILE" 2>&1)
        if [[ $? -eq 0 && "$verbose_output" =~ "INFO" ]]; then
            add_test_result "config_verbose_output" "PASS" "Verbose output works" "Verbose mode produces detailed output"
        else
            add_test_result "config_verbose_output" "FAIL" "Verbose output fails" "Verbose mode not working properly"
        fi
        
        # Test quiet output
        local quiet_output=$("$validation_tool" -q "$TEST_CONFIG_FILE" 2>&1)
        if [[ $? -eq 0 ]]; then
            # Check if quiet mode actually suppresses output
            if [[ ${#quiet_output} -lt 3000 ]]; then
                add_test_result "config_quiet_output" "PASS" "Quiet output works" "Quiet mode produces reasonable output (${#quiet_output} chars)"
            else
                add_test_result "config_quiet_output" "FAIL" "Quiet output too verbose" "Quiet mode should produce less output (${#quiet_output} chars)"
            fi
        else
            add_test_result "config_quiet_output" "FAIL" "Quiet output failed" "Quiet mode should complete successfully"
        fi
    else
        add_test_result "config_verbose_output" "SKIP" "Tool or config not available" "Cannot test verbose output"
        add_test_result "config_quiet_output" "SKIP" "Tool or config not available" "Cannot test quiet output"
    fi
}

# Test configuration validation error handling
test_config_validation_error_handling() {
    echo "Testing configuration validation error handling..."
    
    local validation_tool="$BASE_DIR/tools/config/validate_config.sh"
    
    if [[ -x "$validation_tool" ]]; then
        # Test with malformed config file
        local malformed_config=$(mktemp)
        echo "INVALID_SYNTAX" > "$malformed_config"
        
        if "$validation_tool" "$malformed_config" > /dev/null 2>&1; then
            add_test_result "config_error_handling" "FAIL" "Malformed config passes validation" "Malformed config should fail"
        else
            add_test_result "config_error_handling" "PASS" "Malformed config fails validation" "Malformed config properly rejected"
        fi
        
        rm -f "$malformed_config"
    else
        add_test_result "config_error_handling" "SKIP" "Tool not available" "Cannot test error handling"
    fi
}

# Test configuration validation performance
test_config_validation_performance() {
    echo "Testing configuration validation performance..."
    
    local validation_tool="$BASE_DIR/tools/config/validate_config.sh"
    
    if [[ -x "$validation_tool" && -f "$TEST_CONFIG_FILE" ]]; then
        # Measure validation time
        local start_time=$(date +%s%N)
        "$validation_tool" "$TEST_CONFIG_FILE" > /dev/null 2>&1
        local end_time=$(date +%s%N)
        local duration=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds
        
        if [[ $duration -lt 5000 ]]; then  # Should complete within 5 seconds
            add_test_result "config_performance" "PASS" "Performance acceptable" "Validation completed in ${duration}ms"
        else
            add_test_result "config_performance" "FAIL" "Performance too slow" "Validation took ${duration}ms (>5s)"
        fi
    else
        add_test_result "config_performance" "SKIP" "Tool or config not available" "Cannot test performance"
    fi
}

# Run all configuration validation tests
run_config_validation_tests() {
    echo "Running $TEST_NAME..."
    echo "===================="
    
    test_config_validation_tool_exists
    test_config_validation_help
    test_config_validation_valid_config
    test_config_validation_invalid_config
    test_config_validation_missing_config
    test_config_validation_output
    test_config_validation_error_handling
    test_config_validation_performance
    
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
    run_config_validation_tests
    
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
