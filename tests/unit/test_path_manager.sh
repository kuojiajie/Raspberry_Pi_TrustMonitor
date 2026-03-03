#!/bin/bash
# tests/unit/test_path_manager.sh
# Unit tests for path_manager.sh library

set -u

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load libraries
source "$BASE_DIR/lib/return_codes.sh"
source "$BASE_DIR/lib/logger.sh"
source "$BASE_DIR/lib/path_manager.sh"

# Test configuration
TEST_RESULTS_FILE=""
TEST_NAME="Path Manager Unit Tests"

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
  "test_suite": "path_manager",
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

# Test path manager library exists
test_path_manager_exists() {
    echo "Testing path manager library existence..."
    
    local path_manager_lib="$BASE_DIR/lib/path_manager.sh"
    
    if [[ -f "$path_manager_lib" ]]; then
        add_test_result "path_manager_exists" "PASS" "Path manager library exists" "path_manager.sh found"
    else
        add_test_result "path_manager_exists" "FAIL" "Path manager library not found" "path_manager.sh not found"
    fi
}

# Test path manager functions exist
test_path_manager_functions() {
    echo "Testing path manager functions..."
    
    local functions=("get_project_root" "validate_paths")
    
    for func in "${functions[@]}"; do
        if declare -f "$func" >/dev/null 2>&1; then
            add_test_result "path_manager_function_$func" "PASS" "Function exists: $func" "Function $func is defined"
        else
            add_test_result "path_manager_function_$func" "FAIL" "Function not found: $func" "Function $func not defined"
        fi
    done
}

# Test get_project_root function
test_get_project_root() {
    echo "Testing get_project_root function..."
    
    local project_root
    project_root=$(get_project_root)
    
    if [[ $? -eq 0 && -n "$project_root" ]]; then
        if [[ "$project_root" == "$BASE_DIR" ]]; then
            add_test_result "get_project_root" "PASS" "Project root path correct" "get_project_root returns correct path"
        else
            add_test_result "get_project_root" "FAIL" "Project root path incorrect" "get_project_root returns: $project_root"
        fi
    else
        add_test_result "get_project_root" "FAIL" "get_project_root function failed" "get_project_root failed to execute"
    fi
}

# Test get_data_dir function
test_get_data_dir() {
    echo "Testing get_data_dir function..."
    
    local data_dir="$BASE_DIR/data"
    
    if [[ -d "$data_dir" ]]; then
        add_test_result "get_data_dir" "PASS" "Data directory path correct" "get_data_dir returns correct path"
    else
        add_test_result "get_data_dir" "FAIL" "Data directory path incorrect" "get_data_dir returns: $data_dir"
    fi
}

# Test get_keys_dir function
test_get_keys_dir() {
    echo "Testing get_keys_dir function..."
    
    local keys_dir="$BASE_DIR/data/keys"
    
    if [[ -d "$keys_dir" ]]; then
        add_test_result "get_keys_dir" "PASS" "Keys directory path correct" "get_keys_dir returns correct path"
    else
        add_test_result "get_keys_dir" "FAIL" "Keys directory path incorrect" "get_keys_dir returns: $keys_dir"
    fi
}

# Test validate_paths function
test_validate_paths() {
    echo "Testing validate_paths function..."
    
    # Test with valid paths
    if validate_paths >/dev/null 2>&1; then
        add_test_result "validate_paths" "PASS" "Path validation works" "validate_paths function works"
    else
        add_test_result "validate_paths" "FAIL" "Path validation failed" "validate_paths function failed"
    fi
}

# Test path existence validation
test_path_existence() {
    echo "Testing path existence validation..."
    
    local test_dir=$(mktemp -d)
    local test_file=$(mktemp)
    
    # Test directory existence
    if [[ -d "$test_dir" ]]; then
        add_test_result "path_existence_directory" "PASS" "Test directory exists" "Directory creation works"
    else
        add_test_result "path_existence_directory" "FAIL" "Test directory not found" "Directory creation failed"
    fi
    
    # Test file existence
    if [[ -f "$test_file" ]]; then
        add_test_result "path_existence_file" "PASS" "Test file exists" "File creation works"
    else
        add_test_result "path_existence_file" "FAIL" "Test file not found" "File creation failed"
    fi
    
    rm -rf "$test_dir" "$test_file"
}

# Test path permissions
test_path_permissions() {
    echo "Testing path permissions..."
    
    local test_dir=$(mktemp -d)
    
    # Test directory permissions
    if [[ -r "$test_dir" && -w "$test_dir" && -x "$test_dir" ]]; then
        add_test_result "path_permissions_directory" "PASS" "Directory permissions correct" "Directory has correct permissions"
    else
        add_test_result "path_permissions_directory" "FAIL" "Directory permissions incorrect" "Directory lacks required permissions"
    fi
    
    rm -rf "$test_dir"
}

# Test invalid path handling
test_invalid_paths() {
    echo "Testing invalid path handling..."
    
    local invalid_dir="/tmp/nonexistent_directory_$(date +%s)"
    local invalid_file="/tmp/nonexistent_file_$(date +%s)"
    
    # Test invalid directory
    if [[ -d "$invalid_dir" ]]; then
        add_test_result "invalid_path_directory" "FAIL" "Invalid directory found" "Should not find nonexistent directory"
    else
        add_test_result "invalid_path_directory" "PASS" "Invalid directory not found" "Properly rejects nonexistent directory"
    fi
    
    # Test invalid file
    if [[ -f "$invalid_file" ]]; then
        add_test_result "invalid_path_file" "FAIL" "Invalid file found" "Should not find nonexistent file"
    else
        add_test_result "invalid_path_file" "PASS" "Invalid file not found" "Properly rejects nonexistent file"
    fi
}

# Run all path manager tests
run_path_manager_tests() {
    echo "Running $TEST_NAME..."
    echo "===================="
    
    test_path_manager_exists
    test_path_manager_functions
    test_get_project_root
    test_get_data_dir
    test_get_keys_dir
    test_validate_paths
    test_path_existence
    test_path_permissions
    test_invalid_paths
    
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
    run_path_manager_tests
    
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
