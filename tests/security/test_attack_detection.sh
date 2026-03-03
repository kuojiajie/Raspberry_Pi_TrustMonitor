#!/bin/bash
# tests/security/test_attack_detection.sh
# Security tests for attack detection functionality

set -u

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load libraries
source "$BASE_DIR/lib/return_codes.sh"
source "$BASE_DIR/lib/logger.sh"

# Test configuration
TEST_RESULTS_FILE=""
TEST_NAME="Attack Detection Security Tests"

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
  "test_type": "security",
  "test_suite": "attack_detection",
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

# Test attack detection tools exist
test_attack_detection_tools_exist() {
    echo "Testing attack detection tools existence..."
    
    local attack_tools=("tools/security/attack.sh" "tools/user/demo.sh" "tools/user/restore.sh")
    
    for tool in "${attack_tools[@]}"; do
        if [[ -f "$BASE_DIR/$tool" ]]; then
            if [[ -x "$BASE_DIR/$tool" ]]; then
                add_test_result "attack_tool_exists_$(basename "$tool")" "PASS" "Attack tool exists and executable: $(basename "$tool")" "Tool $tool found and executable"
            else
                add_test_result "attack_tool_exists_$(basename "$tool")" "FAIL" "Attack tool not executable: $(basename "$tool")" "Tool $tool not executable"
            fi
        else
            add_test_result "attack_tool_exists_$(basename "$tool")" "FAIL" "Attack tool not found: $(basename "$tool")" "Tool $tool not found"
        fi
    done
}

# Test attack script functionality
test_attack_script_functionality() {
    echo "Testing attack script functionality..."
    
    local attack_script="$BASE_DIR/tools/security/attack.sh"
    
    if [[ -x "$attack_script" ]]; then
        # Test attack script help
        if "$attack_script" --help > /dev/null 2>&1; then
            add_test_result "attack_script_help" "PASS" "Attack script help works" "attack.sh --help works"
        else
            add_test_result "attack_script_help" "FAIL" "Attack script help fails" "attack.sh --help should work"
        fi
        
        # Test attack script list functionality
        if "$attack_script" --list > /dev/null 2>&1; then
            add_test_result "attack_script_list" "PASS" "Attack script list works" "attack.sh --list works"
        else
            add_test_result "attack_script_list" "FAIL" "Attack script list fails" "attack.sh --list should work"
        fi
        
        # Check if attack script has malicious_code attack
        if "$attack_script" --list | grep -q "malicious_code"; then
            add_test_result "attack_script_malicious_code" "PASS" "Malicious code attack available" "attack.sh has malicious_code attack"
        else
            add_test_result "attack_script_malicious_code" "FAIL" "Malicious code attack missing" "attack.sh should have malicious_code attack"
        fi
    else
        add_test_result "attack_script_help" "SKIP" "Attack script not executable" "Cannot test help functionality"
        add_test_result "attack_script_list" "SKIP" "Attack script not executable" "Cannot test list functionality"
        add_test_result "attack_script_malicious_code" "SKIP" "Attack script not executable" "Cannot test malicious code attack"
    fi
}

# Test malicious code attack detection
test_malicious_code_attack_detection() {
    echo "Testing malicious code attack detection..."
    
    local attack_script="$BASE_DIR/tools/security/attack.sh"
    local integrity_script="$BASE_DIR/scripts/integrity_check.sh"
    
    if [[ -x "$attack_script" && -x "$integrity_script" ]]; then
        # Run malicious code attack
        "$attack_script" malicious_code > /dev/null 2>&1
        
        # Check if attack was detected
        if "$integrity_script" > /dev/null 2>&1; then
            add_test_result "malicious_code_attack_detection" "FAIL" "Malicious code attack not detected" "Integrity check should detect malicious code"
        else
            add_test_result "malicious_code_attack_detection" "PASS" "Malicious code attack detected" "Integrity check properly detected malicious code"
        fi
        
        # Restore system
        "$BASE_DIR/tools/user/restore.sh" --auto > /dev/null 2>&1
        
        # Verify restoration
        if "$integrity_script" > /dev/null 2>&1; then
            add_test_result "malicious_code_attack_restoration" "PASS" "System restoration works" "System successfully restored after attack"
        else
            add_test_result "malicious_code_attack_restoration" "FAIL" "System restoration failed" "System restoration should work after attack"
        fi
    else
        add_test_result "malicious_code_attack_detection" "SKIP" "Scripts not available" "Cannot test attack detection"
        add_test_result "malicious_code_attack_restoration" "SKIP" "Scripts not available" "Cannot test restoration"
    fi
}

# Test attack simulation logging
test_attack_simulation_logging() {
    echo "Testing attack simulation logging..."
    
    local attack_script="$BASE_DIR/tools/security/attack.sh"
    local restore_script="$BASE_DIR/tools/user/restore.sh"
    
    if [[ -x "$attack_script" ]]; then
        # Restore system first to ensure attack can run
        echo "Restoring system before attack simulation test..."
        "$restore_script" --auto >/dev/null 2>&1
        
        # Run attack with logging capture
        local log_output
        log_output=$("$attack_script" malicious_code 2>&1)
        
        # Check if attack simulation is logged
        if echo "$log_output" | grep -q "Starting attack"; then
            add_test_result "attack_simulation_logging_start" "PASS" "Attack start is logged" "Attack simulation properly logs start"
        else
            add_test_result "attack_simulation_logging_start" "FAIL" "Attack start not logged" "Attack simulation should log start"
        fi
        
        if echo "$log_output" | grep -q "ATTACK COMPLETED"; then
            add_test_result "attack_simulation_logging_end" "PASS" "Attack completion is logged" "Attack simulation properly logs completion"
        else
            add_test_result "attack_simulation_logging_end" "FAIL" "Attack completion not logged" "Attack simulation should log completion"
        fi
        
        # Check if attack type is logged
        if echo "$log_output" | grep -q "malicious_code"; then
            add_test_result "attack_simulation_logging_type" "PASS" "Attack type is logged" "Attack simulation properly logs attack type"
        else
            add_test_result "attack_simulation_logging_type" "FAIL" "Attack type not logged" "Attack simulation should log attack type"
        fi
    else
        add_test_result "attack_simulation_logging_start" "SKIP" "Attack script not executable" "Cannot test logging"
        add_test_result "attack_simulation_logging_end" "SKIP" "Attack script not executable" "Cannot test logging"
        add_test_result "attack_simulation_logging_type" "SKIP" "Attack script not executable" "Cannot test logging"
    fi
}

# Test attack script error handling
test_attack_script_error_handling() {
    echo "Testing attack script error handling..."
    
    local attack_script="$BASE_DIR/tools/security/attack.sh"
    
    if [[ -x "$attack_script" ]]; then
        # Test with invalid attack type
        if "$attack_script" invalid_attack_type > /dev/null 2>&1; then
            add_test_result "attack_script_invalid_attack" "FAIL" "Invalid attack type not rejected" "Attack script should reject invalid attack type"
        else
            add_test_result "attack_script_invalid_attack" "PASS" "Invalid attack type rejected" "Attack script properly rejects invalid attack type"
        fi
        
        # Test with missing dependencies
        local integrity_script="$BASE_DIR/scripts/integrity_check.sh"
        local backup_script=$(mktemp)
        
        if [[ -f "$integrity_script" ]]; then
            mv "$integrity_script" "$backup_script"
            
            if "$attack_script" malicious_code > /dev/null 2>&1; then
                add_test_result "attack_script_missing_dependency" "FAIL" "Missing dependency not detected" "Attack script should detect missing integrity_check.sh"
            else
                add_test_result "attack_script_missing_dependency" "PASS" "Missing dependency detected" "Attack script properly detects missing integrity_check.sh"
            fi
            
            mv "$backup_script" "$integrity_script"
        else
            add_test_result "attack_script_missing_dependency" "SKIP" "Integrity script not found" "Cannot test missing dependency"
        fi
        
        rm -f "$backup_script"
    else
        add_test_result "attack_script_invalid_attack" "SKIP" "Attack script not executable" "Cannot test invalid attack"
        add_test_result "attack_script_missing_dependency" "SKIP" "Attack script not executable" "Cannot test missing dependency"
    fi
}

# Test demo script attack detection
test_demo_script_attack_detection() {
    echo "Testing demo script attack detection..."
    
    local demo_script="$BASE_DIR/tools/user/demo.sh"
    
    if [[ -x "$demo_script" ]]; then
        # Test demo script help
        if "$demo_script" help > /dev/null 2>&1; then
            add_test_result "demo_script_help" "PASS" "Demo script help works" "demo.sh help works"
        else
            add_test_result "demo_script_help" "FAIL" "Demo script help fails" "demo.sh help should work"
        fi
        
        # Test demo script quick demo
        local integrity_script="$BASE_DIR/scripts/integrity_check.sh"
        
        if [[ -x "$integrity_script" ]]; then
            # Run quick demo
            "$demo_script" quick > /dev/null 2>&1
            
            # Check if attack was detected
            if "$integrity_script" > /dev/null 2>&1; then
                add_test_result "demo_script_attack_detection" "FAIL" "Quick demo attack not detected" "Quick demo attack should be detected"
            else
                add_test_result "demo_script_attack_detection" "PASS" "Quick demo attack detected" "Quick demo attack properly detected"
            fi
            
            # Restore system
            "$BASE_DIR/tools/user/restore.sh" --auto > /dev/null 2>&1
            
            # Verify restoration
            if "$integrity_script" > /dev/null 2>&1; then
                add_test_result "demo_script_restoration" "PASS" "Demo script restoration works" "System restored after quick demo"
            else
                add_test_result "demo_script_restoration" "FAIL" "Demo script restoration failed" "System restoration should work"
            fi
        else
            add_test_result "demo_script_attack_detection" "SKIP" "Integrity script not available" "Cannot test attack detection"
            add_test_result "demo_script_restoration" "SKIP" "Integrity script not available" "Cannot test restoration"
        fi
    else
        add_test_result "demo_script_help" "SKIP" "Demo script not executable" "Cannot test help"
        add_test_result "demo_script_attack_detection" "SKIP" "Demo script not executable" "Cannot test attack detection"
        add_test_result "demo_script_restoration" "SKIP" "Demo script not executable" "Cannot test restoration"
    fi
}

# Test attack script performance
test_attack_script_performance() {
    echo "Testing attack script performance..."
    
    local attack_script="$BASE_DIR/tools/security/attack.sh"
    
    if [[ -x "$attack_script" ]]; then
        # Measure attack script execution time
        local start_time=$(date +%s%N)
        "$attack_script" malicious_code > /dev/null 2>&1
        local end_time=$(date +%s%N)
        local duration=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds
        
        if [[ $duration -lt 30000 ]]; then  # Should complete within 30 seconds
            add_test_result "attack_script_performance" "PASS" "Performance acceptable" "Attack script completed in ${duration}ms"
        else
            add_test_result "attack_script_performance" "FAIL" "Performance too slow" "Attack script took ${duration}ms (>30s)"
        fi
    else
        add_test_result "attack_script_performance" "SKIP" "Attack script not executable" "Cannot test performance"
    fi
}

# Run all attack detection tests
run_attack_detection_tests() {
    echo "Running $TEST_NAME..."
    echo "===================="
    
    test_attack_detection_tools_exist
    test_attack_script_functionality
    test_malicious_code_attack_detection
    test_attack_simulation_logging
    test_attack_script_error_handling
    test_demo_script_attack_detection
    test_attack_script_performance
    
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
    local mode="${2:-init}"  # Default to init, but allow append mode
    
    if [[ -z "$results_file" ]]; then
        echo "Error: Test results file path required"
        echo "Usage: $0 <results_file> [mode]"
        return $RC_ERROR
    fi
    
    TEST_RESULTS_FILE="$results_file"
    
    # Initialize JSON file only in init mode
    if [[ "$mode" == "init" ]] && command -v jq >/dev/null 2>&1; then
        cat > "$TEST_RESULTS_FILE" << EOF
{
  "test_type": "security",
  "test_suite": "attack_detection",
  "tests": []
}
EOF
    fi
    
    # Run all tests
    run_attack_detection_tests
    
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
