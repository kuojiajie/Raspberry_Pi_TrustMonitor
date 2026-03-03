#!/bin/bash
# tests/unit/test_backup_manager.sh
# Unit tests for backup_manager.sh library

set -u

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load libraries
source "$BASE_DIR/lib/return_codes.sh"
source "$BASE_DIR/lib/logger.sh"
source "$BASE_DIR/lib/backup_manager.sh"

# Test configuration
TEST_RESULTS_FILE=""
TEST_NAME="Backup Manager Unit Tests"

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
  "test_suite": "backup_manager",
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

# Test backup manager library exists
test_backup_manager_exists() {
    echo "Testing backup manager library existence..."
    
    local backup_manager_lib="$BASE_DIR/lib/backup_manager.sh"
    
    if [[ -f "$backup_manager_lib" ]]; then
        add_test_result "backup_manager_exists" "PASS" "Backup manager library exists" "backup_manager.sh found"
    else
        add_test_result "backup_manager_exists" "FAIL" "Backup manager library not found" "backup_manager.sh not found"
    fi
}

# Test backup manager functions exist
test_backup_manager_functions() {
    echo "Testing backup manager functions..."
    
    local functions=("init_backup_dirs" "create_security_backup" "cleanup_security_backups" "cleanup_demo_backups" "cleanup_all_backups")
    
    for func in "${functions[@]}"; do
        if declare -f "$func" >/dev/null 2>&1; then
            add_test_result "backup_manager_function_$func" "PASS" "Function exists: $func" "Function $func is defined"
        else
            add_test_result "backup_manager_function_$func" "FAIL" "Function not found: $func" "Function $func not defined"
        fi
    done
}

# Test backup directory creation
test_backup_directory_creation() {
    echo "Testing backup directory creation..."
    
    local test_backup_dir=$(mktemp -d)
    
    if init_backup_dirs >/dev/null 2>&1; then
        if [[ -d "$test_backup_dir" ]]; then
            add_test_result "backup_directory_creation" "PASS" "Backup directory created" "Backup directory creation works"
        else
            add_test_result "backup_directory_creation" "FAIL" "Backup directory not created" "Backup directory creation failed"
        fi
    else
        add_test_result "backup_directory_creation" "FAIL" "Backup creation failed" "Backup creation function failed"
    fi
    
    rm -rf "$test_backup_dir"
}

# Test backup listing functionality
test_backup_listing() {
    echo "Testing backup listing functionality..."
    
    local test_backup_dir=$(mktemp -d)
    
    # Create backup first
    init_backup_dirs >/dev/null 2>&1
    
    # Test listing
    if ls "$test_backup_dir" >/dev/null 2>&1; then
        add_test_result "backup_listing" "PASS" "Backup listing works" "Backup listing function works"
    else
        add_test_result "backup_listing" "FAIL" "Backup listing failed" "Backup listing function failed"
    fi
    
    rm -rf "$test_backup_dir"
}

# Test backup cleanup functionality
test_backup_cleanup() {
    echo "Testing backup cleanup functionality..."
    
    local test_backup_dir=$(mktemp -d)
    
    # Create some test backups first
    init_backup_dirs >/dev/null 2>&1
    
    # Test cleanup
    if cleanup_all_backups >/dev/null 2>&1; then
        add_test_result "backup_cleanup" "PASS" "Backup cleanup works" "Backup cleanup function works"
    else
        add_test_result "backup_cleanup" "FAIL" "Backup cleanup failed" "Backup cleanup function failed"
    fi
    
    rm -rf "$test_backup_dir"
}

# Test backup with invalid directory
test_backup_invalid_directory() {
    echo "Testing backup with invalid directory..."
    
    local invalid_dir="/tmp/nonexistent_directory_$(date +%s)"
    
    if create_backup "$invalid_dir" >/dev/null 2>&1; then
        add_test_result "backup_invalid_directory" "FAIL" "Invalid directory accepted" "Should reject invalid directory"
    else
        add_test_result "backup_invalid_directory" "PASS" "Invalid directory rejected" "Properly rejects invalid directory"
    fi
}

# Test backup performance
test_backup_performance() {
    echo "Testing backup performance..."
    
    local test_backup_dir=$(mktemp -d)
    
    # Create some test files
    echo "test content" > "$test_backup_dir/test_file.txt"
    
    # Measure backup time
    local start_time=$(date +%s%N)
    create_backup "$test_backup_dir" >/dev/null 2>&1
    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds
    
    if [[ $duration -lt 5000 ]]; then  # Should complete within 5 seconds
        add_test_result "backup_performance" "PASS" "Performance acceptable" "Backup completed in ${duration}ms"
    else
        add_test_result "backup_performance" "FAIL" "Performance too slow" "Backup took ${duration}ms (>5s)"
    fi
    
    rm -rf "$test_backup_dir"
}

# Run all backup manager tests
run_backup_manager_tests() {
    echo "Running $TEST_NAME..."
    echo "===================="
    
    test_backup_manager_exists
    test_backup_manager_functions
    test_backup_directory_creation
    test_backup_listing
    test_backup_cleanup
    test_backup_invalid_directory
    test_backup_performance
    
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
    run_backup_manager_tests
    
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
