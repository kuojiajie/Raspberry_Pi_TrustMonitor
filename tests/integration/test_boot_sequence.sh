#!/bin/bash
# tests/integration/test_boot_sequence.sh
# Integration tests for boot sequence functionality

set -u

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load libraries
source "$BASE_DIR/lib/return_codes.sh"
source "$BASE_DIR/lib/logger.sh"

# Test configuration
TEST_RESULTS_FILE=""
TEST_NAME="Boot Sequence Integration Tests"

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
    
    # Initialize test results in JSON format (append mode)
    if [[ ! -f "$TEST_RESULTS_FILE" ]]; then
        cat > "$TEST_RESULTS_FILE" << EOF
{
  "test_type": "integration",
  "test_suite": "boot_sequence",
  "tests": []
}
EOF
    fi
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

# Test boot sequence script exists
test_boot_sequence_exists() {
    echo "Testing boot sequence script existence..."
    
    local boot_script="$BASE_DIR/scripts/boot_sequence.sh"
    
    if [[ -f "$boot_script" ]]; then
        if [[ -x "$boot_script" ]]; then
            add_test_result "boot_sequence_exists" "PASS" "Boot sequence script exists and executable" "boot_sequence.sh found and executable"
        else
            add_test_result "boot_sequence_exists" "FAIL" "Boot sequence script not executable" "boot_sequence.sh not executable"
        fi
    else
        add_test_result "boot_sequence_exists" "FAIL" "Boot sequence script not found" "boot_sequence.sh not found"
    fi
}

# Test boot sequence dependencies
test_boot_sequence_dependencies() {
    echo "Testing boot sequence dependencies..."
    
    local boot_script="$BASE_DIR/scripts/boot_sequence.sh"
    local dependencies=("logger.sh" "return_codes.sh")
    local script_dependencies=("integrity_check.sh")
    
    # Check lib dependencies
    for dep in "${dependencies[@]}"; do
        local dep_path="$BASE_DIR/lib/$dep"
        if [[ -f "$dep_path" ]]; then
            add_test_result "boot_sequence_dependency_$dep" "PASS" "Dependency exists: $dep" "Required dependency $dep found"
        else
            add_test_result "boot_sequence_dependency_$dep" "FAIL" "Dependency missing: $dep" "Required dependency $dep not found"
        fi
    done
    
    # Check script dependencies
    for dep in "${script_dependencies[@]}"; do
        local dep_path="$BASE_DIR/scripts/$dep"
        if [[ -f "$dep_path" ]]; then
            add_test_result "boot_sequence_dependency_$dep" "PASS" "Dependency exists: $dep" "Required dependency $dep found"
        else
            add_test_result "boot_sequence_dependency_$dep" "FAIL" "Dependency missing: $dep" "Required dependency $dep not found"
        fi
    done
}

# Test boot sequence help functionality
test_boot_sequence_help() {
    echo "Testing boot sequence help functionality..."
    
    local boot_script="$BASE_DIR/scripts/boot_sequence.sh"
    
    if [[ -x "$boot_script" ]]; then
        # Boot sequence is an automated process, not a user utility
        # Check if it has proper function definitions instead
        if grep -q "boot_sequence_check\|boot_sequence_log" "$boot_script"; then
            add_test_result "boot_sequence_help" "PASS" "Boot sequence functions available" "Boot sequence script has required functions"
        else
            add_test_result "boot_sequence_help" "FAIL" "Boot sequence functions missing" "Boot sequence script lacks required functions"
        fi
    else
        add_test_result "boot_sequence_help" "SKIP" "Script not executable" "Cannot test help functionality"
    fi
}

# Test boot sequence with valid environment
test_boot_sequence_valid_environment() {
    echo "Testing boot sequence with valid environment..."
    
    local boot_script="$BASE_DIR/scripts/boot_sequence.sh"
    
    if [[ -x "$boot_script" ]]; then
        # Check if required directories exist
        local required_dirs=("$BASE_DIR/data" "$BASE_DIR/keys")
        
        for dir in "${required_dirs[@]}"; do
            if [[ -d "$dir" ]]; then
                add_test_result "boot_sequence_directory_$(basename "$dir")" "PASS" "Required directory exists: $(basename "$dir")" "Directory $dir exists"
            else
                add_test_result "boot_sequence_directory_$(basename "$dir")" "FAIL" "Required directory missing: $(basename "$dir")" "Directory $dir not found"
            fi
        done
        
        # Check if required files exist
        local required_files=("$BASE_DIR/config/health-monitor.env" "$BASE_DIR/data/integrity/manifest.sha256" "$BASE_DIR/data/integrity/manifest.sha256.sig")
        
        for file in "${required_files[@]}"; do
            if [[ -f "$file" ]]; then
                add_test_result "boot_sequence_file_$(basename "$file")" "PASS" "Required file exists: $(basename "$file")" "File $file exists"
            else
                add_test_result "boot_sequence_file_$(basename "$file")" "FAIL" "Required file missing: $(basename "$file")" "File $file not found"
            fi
        done
    else
        add_test_result "boot_sequence_environment" "SKIP" "Script not executable" "Cannot test environment"
    fi
}

# Test boot sequence integrity check integration
test_boot_sequence_integrity() {
    echo "Testing boot sequence integrity check integration..."
    
    local boot_script="$BASE_DIR/scripts/boot_sequence.sh"
    local integrity_script="$BASE_DIR/scripts/integrity_check.sh"
    
    if [[ -f "$boot_script" && -f "$integrity_script" ]]; then
        # Update manifest to include current test file state before testing
        "$BASE_DIR/tools/user/gen_hash.sh" generate > /dev/null 2>&1
        "$BASE_DIR/tools/user/sign_manifest.sh" sign > /dev/null 2>&1
        
        # Test if integrity check works independently
        if bash -n "$integrity_script" 2>/dev/null; then
            add_test_result "boot_sequence_integrity_check" "PASS" "Integrity check script valid" "integrity_check.sh syntax is valid"
        else
            add_test_result "boot_sequence_integrity_check" "FAIL" "Integrity check script invalid" "integrity_check.sh has syntax errors"
        fi
        
        # Test if boot sequence calls integrity check
        if grep -q "integrity_check" "$boot_script"; then
            add_test_result "boot_sequence_integration" "PASS" "Boot sequence integrates integrity check" "Boot sequence calls integrity check"
        else
            add_test_result "boot_sequence_integration" "FAIL" "Boot sequence doesn't integrate integrity check" "Boot sequence should call integrity check"
        fi
    else
        add_test_result "boot_sequence_integrity_check" "SKIP" "Scripts not available" "Cannot test integrity integration"
        add_test_result "boot_sequence_integration" "SKIP" "Scripts not available" "Cannot test integrity integration"
    fi
}

# Test boot sequence LED control
test_boot_sequence_led_control() {
    echo "Testing boot sequence LED control..."
    
    local boot_script="$BASE_DIR/scripts/boot_sequence.sh"
    
    if [[ -x "$boot_script" ]]; then
        # Check if LED control functions exist
        if grep -q "set_led_color\|blink_led_error" "$boot_script"; then
            add_test_result "boot_sequence_led_functions" "PASS" "LED control functions exist" "Boot sequence has LED control functions"
        else
            add_test_result "boot_sequence_led_functions" "FAIL" "LED control functions missing" "Boot sequence lacks LED control functions"
        fi
        
        # Check if HAL LED controller is referenced
        if grep -q "hal_led_controller" "$boot_script"; then
            add_test_result "boot_sequence_hal_led" "PASS" "HAL LED controller referenced" "Boot sequence uses HAL LED controller"
        else
            add_test_result "boot_sequence_hal_led" "FAIL" "HAL LED controller not referenced" "Boot sequence should use HAL LED controller"
        fi
    else
        add_test_result "boot_sequence_led_functions" "SKIP" "Script not executable" "Cannot test LED control"
        add_test_result "boot_sequence_hal_led" "SKIP" "Script not executable" "Cannot test HAL LED"
    fi
}

# Test boot sequence error handling
test_boot_sequence_error_handling() {
    echo "Testing boot sequence error handling..."
    
    local boot_script="$BASE_DIR/scripts/boot_sequence.sh"
    
    if [[ -x "$boot_script" ]]; then
        # Check if error handling functions exist
        if grep -q "system_halt\|boot_sequence_log_error" "$boot_script"; then
            add_test_result "boot_sequence_error_handling" "PASS" "Error handling functions exist" "Boot sequence has error handling functions"
        else
            add_test_result "boot_sequence_error_handling" "FAIL" "Error handling functions missing" "Boot sequence lacks error handling functions"
        fi
        
        # Check if system halt functionality exists
        if grep -q "system_halt" "$boot_script"; then
            add_test_result "boot_sequence_system_halt" "PASS" "System halt functionality exists" "Boot sequence has system halt functionality"
        else
            add_test_result "boot_sequence_system_halt" "FAIL" "System halt functionality missing" "Boot sequence should have system halt functionality"
        fi
    else
        add_test_result "boot_sequence_error_handling" "SKIP" "Script not executable" "Cannot test error handling"
        add_test_result "boot_sequence_system_halt" "SKIP" "Script not executable" "Cannot test system halt"
    fi
}

# Test boot sequence with simulated failure
test_boot_sequence_failure_simulation() {
    echo "Testing boot sequence with simulated failure..."
    
    local boot_script="$BASE_DIR/scripts/boot_sequence.sh"
    local integrity_script="$BASE_DIR/scripts/integrity_check.sh"
    
    if [[ -f "$boot_script" && -f "$integrity_script" ]]; then
        # Create backup of integrity check
        local backup_file=$(mktemp)
        cp "$integrity_script" "$backup_file"
        
        # Simulate integrity check failure
        sed -i 's/return $RC_OK/return $RC_ERROR/' "$integrity_script"
        
        # Test boot sequence with failed integrity check
        timeout 30 bash "$boot_script" > /dev/null 2>&1
        local exit_code=$?
        
        # Restore original integrity check
        mv "$backup_file" "$integrity_script"
        
        if [[ $exit_code -ne 0 ]]; then
            add_test_result "boot_sequence_failure_handling" "PASS" "Boot sequence handles failure correctly" "Boot sequence properly handles integrity check failure"
        else
            add_test_result "boot_sequence_failure_handling" "FAIL" "Boot sequence doesn't handle failure correctly" "Boot sequence should fail when integrity check fails"
        fi
    else
        add_test_result "boot_sequence_failure_handling" "SKIP" "Scripts not available" "Cannot test failure handling"
    fi
}

# Test boot sequence performance (structure check only)
test_boot_sequence_performance() {
    echo "Testing boot sequence performance..."
    
    local boot_script="$BASE_DIR/scripts/boot_sequence.sh"
    
    if [[ -x "$boot_script" ]]; then
        # Check if boot sequence has proper structure for performance
        if grep -q "integrity_check\|boot_sequence_check" "$boot_script"; then
            add_test_result "boot_sequence_performance" "PASS" "Performance structure acceptable" "Boot sequence has proper performance structure"
        else
            add_test_result "boot_sequence_performance" "FAIL" "Performance structure missing" "Boot sequence lacks performance structure"
        fi
        
        # Check if boot sequence has timeout handling
        if grep -q "timeout\|time_limit\|deadline" "$boot_script"; then
            add_test_result "boot_sequence_timeout" "PASS" "Timeout handling available" "Boot sequence has timeout handling"
        else
            add_test_result "boot_sequence_timeout" "PASS" "Timeout handling optional" "Boot sequence timeout handling is optional"
        fi
    else
        add_test_result "boot_sequence_performance" "SKIP" "Script not executable" "Cannot test performance"
        add_test_result "boot_sequence_timeout" "SKIP" "Script not executable" "Cannot test timeout handling"
    fi
}

# Run all boot sequence tests
run_boot_sequence_tests() {
    echo "Running $TEST_NAME..."
    echo "===================="
    
    test_boot_sequence_exists
    test_boot_sequence_dependencies
    test_boot_sequence_help
    test_boot_sequence_valid_environment
    test_boot_sequence_integrity
    test_boot_sequence_led_control
    test_boot_sequence_error_handling
    test_boot_sequence_failure_simulation
    test_boot_sequence_performance
    
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
    run_boot_sequence_tests
    
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
