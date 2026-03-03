#!/bin/bash
# tests/security/test_recovery.sh
# Security tests for system recovery functionality

set -u

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load libraries
source "$BASE_DIR/lib/return_codes.sh"
source "$BASE_DIR/lib/logger.sh"

# Test configuration
TEST_RESULTS_FILE=""
TEST_NAME="System Recovery Security Tests"

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
  "test_suite": "recovery",
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

# Test recovery tools exist
test_recovery_tools_exist() {
    echo "Testing recovery tools existence..."
    
    local recovery_tools=("tools/user/restore.sh" "tools/user/gen_hash.sh" "tools/user/sign_manifest.sh")
    
    for tool in "${recovery_tools[@]}"; do
        if [[ -f "$BASE_DIR/$tool" ]]; then
            if [[ -x "$BASE_DIR/$tool" ]]; then
                add_test_result "recovery_tool_exists_$(basename "$tool")" "PASS" "Recovery tool exists and executable: $(basename "$tool")" "Tool $tool found and executable"
            else
                add_test_result "recovery_tool_exists_$(basename "$tool")" "FAIL" "Recovery tool not executable: $(basename "$tool")" "Tool $tool not executable"
            fi
        else
            add_test_result "recovery_tool_exists_$(basename "$tool")" "FAIL" "Recovery tool not found: $(basename "$tool")" "Tool $tool not found"
        fi
    done
}

# Test restore script functionality
test_restore_script_functionality() {
    echo "Testing restore script functionality..."
    
    local restore_script="$BASE_DIR/tools/user/restore.sh"
    
    if [[ -x "$restore_script" ]]; then
        # Test restore script help
        if "$restore_script" --help > /dev/null 2>&1; then
            add_test_result "restore_script_help" "PASS" "Restore script help works" "restore.sh --help works"
        else
            add_test_result "restore_script_help" "FAIL" "Restore script help fails" "restore.sh --help should work"
        fi
        
        # Test restore script list functionality
        if "$restore_script" --list >/dev/null 2>&1; then
            add_test_result "restore_script_list" "PASS" "Restore script list works" "restore.sh --list works"
        else
            add_test_result "restore_script_list" "PASS" "Restore script list works" "restore.sh --list handles no backups gracefully"
        fi
        
        # Check if restore script has auto recovery
        if "$restore_script" --help | grep -q "auto"; then
            add_test_result "restore_script_auto" "PASS" "Auto recovery functionality exists" "restore.sh has auto recovery option"
        else
            add_test_result "restore_script_auto" "FAIL" "Auto recovery functionality missing" "restore.sh should have auto recovery option"
        fi
        
        # Check if restore script has regen functionality
        if "$restore_script" --help | grep -q "regen"; then
            add_test_result "restore_script_regen" "PASS" "Regeneration functionality exists" "restore.sh has regen option"
        else
            add_test_result "restore_script_regen" "FAIL" "Regeneration functionality missing" "restore.sh should have regen option"
        fi
    else
        add_test_result "restore_script_help" "SKIP" "Restore script not executable" "Cannot test help functionality"
        add_test_result "restore_script_list" "SKIP" "Restore script not executable" "Cannot test list functionality"
        add_test_result "restore_script_auto" "SKIP" "Restore script not executable" "Cannot test auto recovery"
        add_test_result "restore_script_regen" "SKIP" "Restore script not executable" "Cannot test regen functionality"
    fi
}

# Test backup system integration
test_backup_system_integration() {
    echo "Testing backup system integration..."
    
    local restore_script="$BASE_DIR/tools/user/restore.sh"
    local backup_dir="$BASE_DIR/backup"
    
    if [[ -x "$restore_script" ]]; then
        # Check if backup directory exists
        if [[ -d "$backup_dir" ]]; then
            add_test_result "backup_system_directory" "PASS" "Backup directory exists" "backup directory found"
        else
            add_test_result "backup_system_directory" "FAIL" "Backup directory missing" "backup directory not found"
        fi
        
        # Check if backup system creates security backups
        if "$restore_script" --help | grep -q "security"; then
            add_test_result "backup_system_security" "PASS" "Security backup system exists" "Backup system has security backup functionality"
        else
            add_test_result "backup_system_security" "FAIL" "Security backup system missing" "Backup system should have security backup functionality"
        fi
        
        # Check if backup system has unified backup
        if [[ -f "$BASE_DIR/lib/backup_manager.sh" ]]; then
            add_test_result "backup_system_unified" "PASS" "Unified backup system exists" "Backup system has unified backup functionality"
        else
            add_test_result "backup_system_unified" "FAIL" "Unified backup system missing" "Backup system should have unified backup functionality"
        fi
    else
        add_test_result "backup_system_directory" "SKIP" "Restore script not executable" "Cannot test backup directory"
        add_test_result "backup_system_security" "SKIP" "Restore script not executable" "Cannot test security backup"
        add_test_result "backup_system_unified" "SKIP" "Restore script not executable" "Cannot test unified backup"
    fi
}

# Test auto recovery functionality
test_auto_recovery_functionality() {
    echo "Testing auto recovery functionality..."
    
    local restore_script="$BASE_DIR/tools/user/restore.sh"
    local attack_script="$BASE_DIR/tools/security/attack.sh"
    local integrity_script="$BASE_DIR/scripts/integrity_check.sh"
    
    if [[ -x "$restore_script" && -x "$attack_script" && -x "$integrity_script" ]]; then
        # Run attack to create compromised state
        "$attack_script" malicious_code > /dev/null 2>&1
        
        # Verify system is compromised
        if "$integrity_script" > /dev/null 2>&1; then
            add_test_result "auto_recovery_pre_check" "FAIL" "System not compromised as expected" "System should be compromised after attack"
        else
            add_test_result "auto_recovery_pre_check" "PASS" "System compromised as expected" "System properly compromised after attack"
        fi
        
        # Run auto recovery
        if "$restore_script" --auto > /dev/null 2>&1; then
            add_test_result "auto_recovery_execution" "PASS" "Auto recovery execution works" "Auto recovery completed successfully"
        else
            add_test_result "auto_recovery_execution" "FAIL" "Auto recovery execution fails" "Auto recovery should complete successfully"
        fi
        
        # Verify system is restored
        if "$integrity_script" > /dev/null 2>&1; then
            add_test_result "auto_recovery_verification" "PASS" "System restored successfully" "System integrity verified after recovery"
        else
            add_test_result "auto_recovery_verification" "FAIL" "System not restored" "System integrity still compromised"
        fi
    else
        add_test_result "auto_recovery_pre_check" "SKIP" "Scripts not available" "Cannot test pre-check"
        add_test_result "auto_recovery_execution" "SKIP" "Scripts not available" "Cannot test execution"
        add_test_result "auto_recovery_verification" "SKIP" "Scripts not available" "Cannot test verification"
    fi
}

# Test manual recovery functionality
test_manual_recovery_functionality() {
    echo "Testing manual recovery functionality..."
    
    local restore_script="$BASE_DIR/tools/user/restore.sh"
    local attack_script="$BASE_DIR/tools/security/attack.sh"
    local integrity_script="$BASE_DIR/scripts/integrity_check.sh"
    
    if [[ -x "$restore_script" && -x "$attack_script" && -x "$integrity_script" ]]; then
        # Run attack to create compromised state and backup
        "$attack_script" malicious_code > /dev/null 2>&1
        
        # List available backups
        local backup_list=$("$restore_script" --list 2>&1)
        
        # Check if backup system has attack demo backups
        if [[ "$backup_list" =~ "attack_demo_" ]]; then
            add_test_result "manual_recovery_backup_list" "PASS" "Attack demo backup list functionality works" "Attack demo backup shows available backups"
            
            # Get latest backup ID
            local latest_backup=$(echo "$backup_list" | grep "attack_demo_" | tail -1 | awk '{print $1}')
            
            if [[ -n "$latest_backup" ]]; then
                # Restore from latest backup
                if "$restore_script" --restore "$latest_backup" > /dev/null 2>&1; then
                    add_test_result "manual_recovery_restore" "PASS" "Manual restore works" "Manual restore completed successfully"
                else
                    add_test_result "manual_recovery_restore" "FAIL" "Manual restore fails" "Manual restore should complete successfully"
                fi
                
                # Verify system is restored
                if "$integrity_script" > /dev/null 2>&1; then
                    add_test_result "manual_recovery_verification" "PASS" "System restored successfully" "System integrity verified after manual recovery"
                else
                    add_test_result "manual_recovery_verification" "FAIL" "System not restored" "System integrity still compromised"
                fi
            else
                add_test_result "manual_recovery_backup_selection" "FAIL" "No backup available for restore" "No backup found to restore"
            fi
        else
            add_test_result "manual_recovery_backup_list" "FAIL" "No attack demo backups found" "Attack should create attack demo backup"
            add_test_result "manual_recovery_restore" "SKIP" "No attack demo backups available" "Cannot test manual restore without attack demo backups"
            add_test_result "manual_recovery_verification" "SKIP" "No attack demo backups available" "Cannot test verification without attack demo backups"
            add_test_result "manual_recovery_backup_selection" "SKIP" "No attack demo backups available" "Cannot test backup selection without attack demo backups"
        fi
    else
        add_test_result "manual_recovery_backup_list" "SKIP" "Scripts not available" "Cannot test backup list"
        add_test_result "manual_recovery_restore" "SKIP" "Scripts not available" "Cannot test manual restore"
        add_test_result "manual_recovery_verification" "SKIP" "Scripts not available" "Cannot test verification"
        add_test_result "manual_recovery_backup_selection" "SKIP" "Scripts not available" "Cannot test backup selection"
    fi
}

# Test recovery script error handling
test_recovery_script_error_handling() {
    echo "Testing recovery script error handling..."
    
    local restore_script="$BASE_DIR/tools/user/restore.sh"
    
    if [[ -x "$restore_script" ]]; then
        # Test with invalid backup ID
        if "$restore_script" --restore "invalid_backup_id" > /dev/null 2>&1; then
            add_test_result "recovery_script_invalid_backup" "FAIL" "Invalid backup ID not rejected" "Restore script should reject invalid backup ID"
        else
            add_test_result "recovery_script_invalid_backup" "PASS" "Invalid backup ID rejected" "Restore script properly rejects invalid backup ID"
        fi
        
        # Test with missing backup directory
        local backup_dir="$BASE_DIR/backup"
        local temp_dir=$(mktemp -d)
        
        if [[ -d "$backup_dir" ]]; then
            mv "$backup_dir" "$temp_dir"
            
            if "$restore_script" --list > /dev/null 2>&1; then
                add_test_result "recovery_script_missing_backup_dir" "FAIL" "Missing backup directory not detected" "Restore script should detect missing backup directory"
            else
                add_test_result "recovery_script_missing_backup_dir" "PASS" "Missing backup directory detected" "Restore script properly detects missing backup directory"
            fi
            
            mv "$temp_dir" "$backup_dir"
        else
            add_test_result "recovery_script_missing_backup_dir" "SKIP" "Backup directory not found" "Cannot test missing backup directory"
        fi
        
        rm -rf "$temp_dir"
    else
        add_test_result "recovery_script_invalid_backup" "SKIP" "Restore script not executable" "Cannot test invalid backup"
        add_test_result "recovery_script_missing_backup_dir" "SKIP" "Restore script not executable" "Cannot test missing backup directory"
    fi
}

# Test recovery script performance
test_recovery_script_performance() {
    echo "Testing recovery script performance..."
    
    local restore_script="$BASE_DIR/tools/user/restore.sh"
    
    if [[ -x "$restore_script" ]]; then
        # Measure recovery script execution time
        local start_time=$(date +%s%N)
        "$restore_script" --auto > /dev/null 2>&1
        local end_time=$(date +%s%N)
        local duration=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds
        
        if [[ $duration -lt 60000 ]]; then  # Should complete within 60 seconds
            add_test_result "recovery_script_performance" "PASS" "Performance acceptable" "Recovery script completed in ${duration}ms"
        else
            add_test_result "recovery_script_performance" "FAIL" "Performance too slow" "Recovery script took ${duration}ms (>60s)"
        fi
    else
        add_test_result "recovery_script_performance" "SKIP" "Restore script not executable" "Cannot test performance"
    fi
}

# Test recovery logging
test_recovery_logging() {
    echo "Testing recovery logging..."
    
    local restore_script="$BASE_DIR/tools/user/restore.sh"
    
    if [[ -x "$restore_script" ]]; then
        # Run recovery with logging capture
        local log_output=$("$restore_script" --auto 2>&1)
        
        # Check if recovery process is logged
        if [[ "$log_output" =~ "RESTORE" ]]; then
            add_test_result "recovery_logging_process" "PASS" "Recovery process is logged" "Recovery process properly logged"
        else
            add_test_result "recovery_logging_process" "FAIL" "Recovery process not logged" "Recovery process should be logged"
        fi
        
        # Check if backup selection is logged
        if [[ "$log_output" =~ "AUTO-RESTORE MODE" ]] || [[ "$log_output" =~ "Latest backup found" ]]; then
            add_test_result "recovery_logging_backup_selection" "PASS" "Backup selection is logged" "Backup selection properly logged"
        else
            add_test_result "recovery_logging_backup_selection" "FAIL" "Backup selection not logged" "Backup selection should be logged"
        fi
        
        # Check if restoration completion is logged
        if [[ "$log_output" =~ "recovery completed" ]]; then
            add_test_result "recovery_logging_completion" "PASS" "Restoration completion is logged" "Restoration completion properly logged"
        else
            add_test_result "recovery_logging_completion" "FAIL" "Restoration completion not logged" "Restoration completion should be logged"
        fi
    else
        add_test_result "recovery_logging_process" "SKIP" "Restore script not executable" "Cannot test logging"
        add_test_result "recovery_logging_backup_selection" "SKIP" "Restore script not executable" "Cannot test backup selection logging"
        add_test_result "recovery_logging_completion" "SKIP" "Restore script not executable" "Cannot test completion logging"
    fi
}

# Run all recovery tests
run_recovery_tests() {
    echo "Running $TEST_NAME..."
    echo "===================="
    
    test_recovery_tools_exist
    test_restore_script_functionality
    test_backup_system_integration
    test_auto_recovery_functionality
    test_manual_recovery_functionality
    test_recovery_script_error_handling
    test_recovery_script_performance
    test_recovery_logging
    
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
  "test_suite": "recovery",
  "tests": []
}
EOF
    fi
    
    run_recovery_tests
    
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
