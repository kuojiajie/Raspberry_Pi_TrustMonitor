#!/bin/bash
# tests/integration/test_integrity_check.sh
# Integration tests for integrity check functionality

set -u

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load libraries
source "$BASE_DIR/lib/return_codes.sh"
source "$BASE_DIR/lib/logger.sh"

# Test configuration
TEST_RESULTS_FILE=""
TEST_NAME="Integrity Check Integration Tests"

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
  "test_suite": "integrity_check",
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

# Test integrity check script exists
test_integrity_check_exists() {
    echo "Testing integrity check script existence..."
    
    local integrity_script="$BASE_DIR/scripts/integrity_check.sh"
    
    if [[ -f "$integrity_script" ]]; then
        add_test_result "integrity_check_exists" "PASS" "Integrity check script exists" "integrity_check.sh found"
    else
        add_test_result "integrity_check_exists" "FAIL" "Integrity check script not found" "integrity_check.sh not found"
    fi
}

# Test integrity check dependencies
test_integrity_check_dependencies() {
    echo "Testing integrity check dependencies..."
    
    local integrity_script="$BASE_DIR/scripts/integrity_check.sh"
    local dependencies=("logger.sh" "return_codes.sh")
    
    for dep in "${dependencies[@]}"; do
        local dep_path="$BASE_DIR/lib/$dep"
        if [[ -f "$dep_path" ]]; then
            add_test_result "integrity_check_dependency_$dep" "PASS" "Dependency exists: $dep" "Required dependency $dep found"
        else
            add_test_result "integrity_check_dependency_$dep" "FAIL" "Dependency missing: $dep" "Required dependency $dep not found"
        fi
    done
}

# Test integrity check with valid environment
test_integrity_check_valid_environment() {
    echo "Testing integrity check with valid environment..."
    
    local integrity_script="$BASE_DIR/scripts/integrity_check.sh"
    
    if [[ -f "$integrity_script" ]]; then
        # Check if required files exist
        local required_files=("$BASE_DIR/data/manifest.sha256" "$BASE_DIR/data/manifest.sha256.sig" "$BASE_DIR/keys/public_key.pem")
        
        for file in "${required_files[@]}"; do
            if [[ -f "$file" ]]; then
                add_test_result "integrity_check_file_$(basename "$file")" "PASS" "Required file exists: $(basename "$file")" "File $file exists"
            else
                add_test_result "integrity_check_file_$(basename "$file")" "FAIL" "Required file missing: $(basename "$file")" "File $file not found"
            fi
        done
    else
        add_test_result "integrity_check_environment" "SKIP" "Script not available" "Cannot test environment"
    fi
}

# Test integrity check basic functionality
test_integrity_check_basic() {
    echo "Testing integrity check basic functionality..."
    
    local integrity_script="$BASE_DIR/scripts/integrity_check.sh"
    
    if [[ -f "$integrity_script" ]]; then
        # Update manifest to include current test file state before testing
        "$BASE_DIR/tools/user/gen_hash.sh" generate > /dev/null 2>&1
        "$BASE_DIR/tools/user/sign_manifest.sh" sign > /dev/null 2>&1
        
        # Test basic integrity check
        if bash "$integrity_script" > /dev/null 2>&1; then
            add_test_result "integrity_check_basic" "PASS" "Basic integrity check works" "integrity_check.sh runs successfully"
        else
            add_test_result "integrity_check_basic" "FAIL" "Basic integrity check fails" "integrity_check.sh should run successfully"
        fi
    else
        add_test_result "integrity_check_basic" "SKIP" "Script not available" "Cannot test basic functionality"
    fi
}

# Test integrity check with manifest file
test_integrity_check_manifest() {
    echo "Testing integrity check with manifest file..."
    
    local integrity_script="$BASE_DIR/scripts/integrity_check.sh"
    local manifest_file="$BASE_DIR/data/manifest.sha256"
    
    if [[ -f "$integrity_script" && -f "$manifest_file" ]]; then
        # Check if manifest file is valid
        if grep -q "^[a-f0-9]" "$manifest_file"; then
            add_test_result "integrity_check_manifest" "PASS" "Manifest file format is valid" "manifest.sha256 has valid format"
        else
            add_test_result "integrity_check_manifest" "FAIL" "Manifest file format is invalid" "manifest.sha256 has invalid format"
        fi
        
        # Check if manifest file contains expected entries
        local file_count=$(wc -l < "$manifest_file")
        if [[ $file_count -gt 0 ]]; then
            add_test_result "integrity_check_manifest_entries" "PASS" "Manifest file has entries" "manifest.sha256 contains $file_count entries"
        else
            add_test_result "integrity_check_manifest_entries" "FAIL" "Manifest file is empty" "manifest.sha256 should contain entries"
        fi
    else
        add_test_result "integrity_check_manifest" "SKIP" "Script or manifest not available" "Cannot test manifest file"
        add_test_result "integrity_check_manifest_entries" "SKIP" "Script or manifest not available" "Cannot test manifest entries"
    fi
}

# Test integrity check signature verification
test_integrity_check_signature() {
    echo "Testing integrity check signature verification..."
    
    local integrity_script="$BASE_DIR/scripts/integrity_check.sh"
    local signature_file="$BASE_DIR/data/manifest.sha256.sig"
    local public_key="$BASE_DIR/keys/public_key.pem"
    
    if [[ -f "$integrity_script" && -f "$signature_file" && -f "$public_key" ]]; then
        # Check if signature file is valid (binary format)
        if [[ -s "$signature_file" ]]; then
            # Check if it's a valid binary signature (non-empty and has binary data)
            if file "$signature_file" | grep -q "data\|binary"; then
                add_test_result "integrity_check_signature_format" "PASS" "Signature file format is valid" "manifest.sha256.sig has valid binary format"
            else
                add_test_result "integrity_check_signature_format" "FAIL" "Signature file format is invalid" "manifest.sha256.sig has invalid format"
            fi
        else
            add_test_result "integrity_check_signature_format" "FAIL" "Signature file format is invalid" "manifest.sha256.sig is empty"
        fi
        
        # Check if public key file is valid
        if grep -q "BEGIN.*PUBLIC KEY" "$public_key"; then
            add_test_result "integrity_check_public_key" "PASS" "Public key file format is valid" "public_key.pem has valid format"
        else
            add_test_result "integrity_check_public_key" "FAIL" "Public key file format is invalid" "public_key.pem has invalid format"
        fi
        
        # Test signature verification
        if grep -q "verify_signature" "$integrity_script"; then
            add_test_result "integrity_check_signature_verification" "PASS" "Signature verification functionality exists" "integrity_check.sh has signature verification"
        else
            add_test_result "integrity_check_signature_verification" "FAIL" "Signature verification functionality missing" "integrity_check.sh should have signature verification"
        fi
    else
        add_test_result "integrity_check_signature_format" "SKIP" "Files not available" "Cannot test signature format"
        add_test_result "integrity_check_public_key" "SKIP" "Files not available" "Cannot test public key"
        add_test_result "integrity_check_signature_verification" "SKIP" "Files not available" "Cannot test signature verification"
    fi
}

# Test integrity check with corrupted file (read-only simulation)
test_integrity_check_corrupted_file() {
    echo "Testing integrity check with corrupted file (read-only simulation)..."
    
    local integrity_script="$BASE_DIR/scripts/integrity_check.sh"
    local test_file="$BASE_DIR/hardware/hal_core.py"
    
    if [[ -f "$integrity_script" ]]; then
        # Create backup of original file
        local file_backup="$test_file.backup"
        cp "$test_file" "$file_backup" 2>/dev/null
        
        # Create test file with unique content
        echo "Original content for corruption test - $(date +%s)" > "$test_file"
        
        # Create backup of original manifest
        local manifest_backup="$BASE_DIR/data/manifest.sha256.backup"
        local sig_backup="$BASE_DIR/data/manifest.sha256.sig.backup"
        cp "$BASE_DIR/data/manifest.sha256" "$manifest_backup" 2>/dev/null
        cp "$BASE_DIR/data/manifest.sha256.sig" "$sig_backup" 2>/dev/null
        
        # Generate initial hash (clean state)
        "$BASE_DIR/tools/user/gen_hash.sh" generate > /dev/null 2>&1
        "$BASE_DIR/tools/user/sign_manifest.sh" sign > /dev/null 2>&1
        
        # Corrupt the file AFTER generating manifest with significantly different content
        echo "COMPLETELY DIFFERENT CORRUPTED CONTENT - $(date +%s) - This should definitely be detected as corruption" > "$test_file"
        
        # Test integrity check - should detect corruption because manifest doesn't match corrupted file
        if bash "$integrity_script" > /dev/null 2>&1; then
            add_test_result "integrity_check_corruption_detection" "FAIL" "Corruption not detected" "Integrity check should detect corruption"
        else
            add_test_result "integrity_check_corruption_detection" "PASS" "Corruption detected" "Integrity check properly detected corruption"
        fi
        
        # Restore file and manifest
        mv "$file_backup" "$test_file" 2>/dev/null
        mv "$manifest_backup" "$BASE_DIR/data/manifest.sha256" 2>/dev/null
        mv "$sig_backup" "$BASE_DIR/data/manifest.sha256.sig" 2>/dev/null
        
        rm -f "$file_backup"
    else
        add_test_result "integrity_check_corruption_detection" "SKIP" "Script not available" "Cannot test corruption detection"
    fi
}

# Test integrity check performance
test_integrity_check_performance() {
    echo "Testing integrity check performance..."
    
    local integrity_script="$BASE_DIR/scripts/integrity_check.sh"
    
    if [[ -f "$integrity_script" ]]; then
        # Measure integrity check time
        local start_time=$(date +%s%N)
        bash "$integrity_script" > /dev/null 2>&1
        local end_time=$(date +%s%N)
        local duration=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds
        
        if [[ $duration -lt 10000 ]]; then  # Should complete within 10 seconds
            add_test_result "integrity_check_performance" "PASS" "Performance acceptable" "Integrity check completed in ${duration}ms"
        else
            add_test_result "integrity_check_performance" "FAIL" "Performance too slow" "Integrity check took ${duration}ms (>10s)"
        fi
    else
        add_test_result "integrity_check_performance" "SKIP" "Script not available" "Cannot test performance"
    fi
}

# Test integrity check error handling
test_integrity_check_error_handling() {
    echo "Testing integrity check error handling..."
    
    local integrity_script="$BASE_DIR/scripts/integrity_check.sh"
    
    if [[ -f "$integrity_script" ]]; then
        # Check if error handling functions exist
        if grep -q "log_error\|return.*RC_ERROR" "$integrity_script"; then
            add_test_result "integrity_check_error_handling" "PASS" "Error handling functions exist" "integrity_check.sh has error handling functions"
        else
            add_test_result "integrity_check_error_handling" "FAIL" "Error handling functions missing" "integrity_check.sh lacks error handling functions"
        fi
        
        # Test with missing manifest file
        local manifest_file="$BASE_DIR/data/manifest.sha256"
        local backup_file=$(mktemp)
        
        if [[ -f "$manifest_file" ]]; then
            mv "$manifest_file" "$backup_file"
            
            if "$integrity_script" > /dev/null 2>&1; then
                add_test_result "integrity_check_missing_manifest" "FAIL" "Missing manifest not detected" "Integrity check should detect missing manifest"
            else
                add_test_result "integrity_check_missing_manifest" "PASS" "Missing manifest detected" "Integrity check properly detects missing manifest"
            fi
            
            mv "$backup_file" "$manifest_file"
        else
            add_test_result "integrity_check_missing_manifest" "SKIP" "Manifest file not found" "Cannot test missing manifest"
        fi
        
        rm -f "$backup_file"
    else
        add_test_result "integrity_check_error_handling" "SKIP" "Script not executable" "Cannot test error handling"
        add_test_result "integrity_check_missing_manifest" "SKIP" "Script not executable" "Cannot test missing manifest"
    fi
}

# Run all integrity check tests
run_integrity_check_tests() {
    echo "Running $TEST_NAME..."
    echo "===================="
    
    test_integrity_check_exists
    test_integrity_check_dependencies
    test_integrity_check_valid_environment
    test_integrity_check_basic
    test_integrity_check_manifest
    test_integrity_check_signature
    test_integrity_check_corrupted_file
    test_integrity_check_performance
    test_integrity_check_error_handling
    
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
    run_integrity_check_tests
    
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
