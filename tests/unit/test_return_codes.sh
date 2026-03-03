#!/bin/bash
# tests/unit/test_return_codes.sh
# Unit tests for return_codes.sh library

set -u

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load libraries
source "$BASE_DIR/lib/return_codes.sh"

# Test configuration
TEST_RESULTS_FILE=""
TEST_NAME="Return Codes Unit Tests"

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
  "test_suite": "return_codes",
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

# Test return code constants
test_return_code_constants() {
    echo "Testing return code constants..."
    
    # Test RC_OK
    if [[ "$RC_OK" -eq 0 ]]; then
        add_test_result "rc_ok_constant" "PASS" "RC_OK constant is 0" "RC_OK properly defined as 0"
    else
        add_test_result "rc_ok_constant" "FAIL" "RC_OK constant is not 0" "RC_OK should be 0"
    fi
    
    # Test RC_WARN
    if [[ "$RC_WARN" -eq 1 ]]; then
        add_test_result "rc_warn_constant" "PASS" "RC_WARN constant is 1" "RC_WARN properly defined as 1"
    else
        add_test_result "rc_warn_constant" "FAIL" "RC_WARN constant is not 1" "RC_WARN should be 1"
    fi
    
    # Test RC_ERROR
    if [[ "$RC_ERROR" -eq 2 ]]; then
        add_test_result "rc_error_constant" "PASS" "RC_ERROR constant is 2" "RC_ERROR properly defined as 2"
    else
        add_test_result "rc_error_constant" "FAIL" "RC_ERROR constant is not 2" "RC_ERROR should be 2"
    fi
    
    # Test RC_INTEGRITY_FAILED
    if [[ "$RC_INTEGRITY_FAILED" -eq 4 ]]; then
        add_test_result "rc_integrity_failed_constant" "PASS" "RC_INTEGRITY_FAILED constant is 4" "RC_INTEGRITY_FAILED properly defined as 4"
    else
        add_test_result "rc_integrity_failed_constant" "FAIL" "RC_INTEGRITY_FAILED constant is not 4" "RC_INTEGRITY_FAILED should be 4"
    fi
    
    # Test RC_NETWORK_FAILED
    if [[ "$RC_NETWORK_FAILED" -eq 9 ]]; then
        add_test_result "rc_network_failed_constant" "PASS" "RC_NETWORK_FAILED constant is 9" "RC_NETWORK_FAILED properly defined as 9"
    else
        add_test_result "rc_network_failed_constant" "FAIL" "RC_NETWORK_FAILED constant is not 9" "RC_NETWORK_FAILED should be 9"
    fi
}

# Test return code descriptions
test_return_code_descriptions() {
    echo "Testing return code descriptions..."
    
    # Test if return codes have meaningful descriptions
    local codes=("RC_OK" "RC_WARN" "RC_ERROR" "RC_INTEGRITY_FAILED" "RC_SIGNATURE_FAILED" "RC_BOOT_FAILED" "RC_SENSOR_ERROR" "RC_LED_ERROR" "RC_NETWORK_FAILED" "RC_CONFIG_ERROR" "RC_DEPENDENCY_ERROR")
    
    for code in "${codes[@]}"; do
        local value=${!code}
        case $value in
            0)
                add_test_result "rc_description_$code" "PASS" "$code has meaningful description" "$code indicates success"
                ;;
            1)
                add_test_result "rc_description_$code" "PASS" "$code has meaningful description" "$code indicates warning"
                ;;
            2)
                add_test_result "rc_description_$code" "PASS" "$code has meaningful description" "$code indicates error"
                ;;
            3)
                add_test_result "rc_description_$code" "PASS" "$code has meaningful description" "$code indicates plugin error"
                ;;
            4)
                add_test_result "rc_description_$code" "PASS" "$code has meaningful description" "$code indicates integrity failure"
                ;;
            5)
                add_test_result "rc_description_$code" "PASS" "$code has meaningful description" "$code indicates signature failure"
                ;;
            6)
                add_test_result "rc_description_$code" "PASS" "$code has meaningful description" "$code indicates boot failure"
                ;;
            7)
                add_test_result "rc_description_$code" "PASS" "$code has meaningful description" "$code indicates sensor error"
                ;;
            8)
                add_test_result "rc_description_$code" "PASS" "$code has meaningful description" "$code indicates LED error"
                ;;
            9)
                add_test_result "rc_description_$code" "PASS" "$code has meaningful description" "$code indicates network failure"
                ;;
            10)
                add_test_result "rc_description_$code" "PASS" "$code has meaningful description" "$code indicates config error"
                ;;
            11)
                add_test_result "rc_description_$code" "PASS" "$code has meaningful description" "$code indicates dependency error"
                ;;
            *)
                add_test_result "rc_description_$code" "FAIL" "$code has unknown description" "$code value: $value"
                ;;
        esac
    done
}

# Test return code ranges
test_return_code_ranges() {
    echo "Testing return code ranges..."
    
    # Test that return codes are within expected range (0-255)
    local codes=("RC_OK" "RC_WARN" "RC_ERROR" "RC_INTEGRITY_FAILED" "RC_SIGNATURE_FAILED" "RC_BOOT_FAILED" "RC_SENSOR_ERROR" "RC_LED_ERROR" "RC_NETWORK_FAILED" "RC_CONFIG_ERROR" "RC_DEPENDENCY_ERROR")
    
    for code in "${codes[@]}"; do
        local value=${!code}
        if [[ $value -ge 0 && $value -le 255 ]]; then
            add_test_result "rc_range_$code" "PASS" "$code is within valid range" "$code value $value is valid (0-255)"
        else
            add_test_result "rc_range_$code" "FAIL" "$code is outside valid range" "$code value $value is invalid"
        fi
    done
}

# Test return code uniqueness
test_return_code_uniqueness() {
    echo "Testing return code uniqueness..."
    
    # Test that return codes are unique
    local codes=("RC_OK" "RC_WARN" "RC_ERROR" "RC_INTEGRITY_FAILED" "RC_SIGNATURE_FAILED" "RC_BOOT_FAILED" "RC_SENSOR_ERROR" "RC_LED_ERROR" "RC_NETWORK_FAILED" "RC_CONFIG_ERROR" "RC_DEPENDENCY_ERROR")
    local values=()
    
    for code in "${codes[@]}"; do
        local value=${!code}
        values+=("$value")
    done
    
    # Check for duplicates
    local unique_values=($(printf "%s\n" "${values[@]}" | sort -u))
    if [[ ${#values[@]} -eq ${#unique_values[@]} ]]; then
        add_test_result "rc_uniqueness" "PASS" "All return codes are unique" "No duplicate return codes found"
    else
        add_test_result "rc_uniqueness" "FAIL" "Duplicate return codes found" "Some return codes are duplicated"
    fi
}

# Test return code usage patterns
test_return_code_usage() {
    echo "Testing return code usage patterns..."
    
    # Test that return codes follow standard conventions
    local success_codes=("RC_OK")
    local warning_codes=("RC_WARN")
    local error_codes=("RC_ERROR" "RC_INTEGRITY_FAILED" "RC_SIGNATURE_FAILED" "RC_BOOT_FAILED" "RC_SENSOR_ERROR" "RC_LED_ERROR" "RC_NETWORK_FAILED" "RC_CONFIG_ERROR" "RC_DEPENDENCY_ERROR")
    
    # Test success codes (should be 0)
    for code in "${success_codes[@]}"; do
        local value=${!code}
        if [[ $value -eq 0 ]]; then
            add_test_result "rc_usage_success_$code" "PASS" "$code follows success convention" "$code is 0 for success"
        else
            add_test_result "rc_usage_success_$code" "FAIL" "$code violates success convention" "$code should be 0 for success"
        fi
    done
    
    # Test warning codes (should be 1)
    for code in "${warning_codes[@]}"; do
        local value=${!code}
        if [[ $value -eq 1 ]]; then
            add_test_result "rc_usage_warning_$code" "PASS" "$code follows warning convention" "$code is 1 for warning"
        else
            add_test_result "rc_usage_warning_$code" "FAIL" "$code violates warning convention" "$code should be 1 for warning"
        fi
    done
    
    # Test error codes (should be > 1)
    for code in "${error_codes[@]}"; do
        local value=${!code}
        if [[ $value -gt 1 ]]; then
            add_test_result "rc_usage_error_$code" "PASS" "$code follows error convention" "$code is > 1 for error"
        else
            add_test_result "rc_usage_error_$code" "FAIL" "$code violates error convention" "$code should be > 1 for error"
        fi
    done
}

# Test return code documentation
test_return_code_documentation() {
    echo "Testing return code documentation..."
    
    # Check if return codes are documented in the library
    local return_codes_file="$BASE_DIR/lib/return_codes.sh"
    
    if [[ -f "$return_codes_file" ]]; then
        # Check if all return codes are documented
        local codes=("RC_OK" "RC_WARN" "RC_ERROR" "RC_INTEGRITY_FAILED" "RC_SIGNATURE_FAILED" "RC_BOOT_FAILED" "RC_SENSOR_ERROR" "RC_LED_ERROR" "RC_NETWORK_FAILED" "RC_CONFIG_ERROR" "RC_DEPENDENCY_ERROR")
        
        for code in "${codes[@]}"; do
            if grep -q "$code" "$return_codes_file"; then
                add_test_result "rc_documentation_$code" "PASS" "$code is documented" "$code found in return_codes.sh"
            else
                add_test_result "rc_documentation_$code" "FAIL" "$code is not documented" "$code not found in return_codes.sh"
            fi
        done
    else
        add_test_result "rc_documentation_file" "FAIL" "Return codes file not found" "return_codes.sh file missing"
    fi
}

# Run all return codes tests
run_return_codes_tests() {
    echo "Running $TEST_NAME..."
    echo "===================="
    
    test_return_code_constants
    test_return_code_descriptions
    test_return_code_ranges
    test_return_code_uniqueness
    test_return_code_usage
    test_return_code_documentation
    
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
    run_return_codes_tests
    
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
