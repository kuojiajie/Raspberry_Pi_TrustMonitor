#!/bin/bash

# ==============================================================================
# TrustMonitor Development Test Suite
# ==============================================================================
# This script runs all development tests in the correct order
# Usage: ./run_all_tests.sh [--quick] [--verbose] [--help]
#
# Options:
#   --quick    Run only essential tests (skip comprehensive tests)
#   --verbose  Show detailed output from all tests
#   --help     Show this help message
#
# Exit codes:
#   0 - All tests passed
#   1 - Some tests failed
#   2 - Test environment error
# ==============================================================================

set -euo pipefail

# Script directory and project base
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load TrustMonitor initialization system
source "$PROJECT_ROOT/lib/trustmon_init.sh"

# Initialize this script
init_trustmon_script "run_all_tests.sh"

# Load environment variables
load_script_config "run_all_tests.sh"

# Load logger
source "$LIB_DIR/logger.sh"

# Test configuration
QUICK_MODE=false
VERBOSE_MODE=false
TEST_LOG="$LOGS_DIR/run_all_tests_$(date '+%Y%m%d_%H%M%S').log"
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Color variables for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test suite definitions
declare -a CORE_TESTS=(
    "test_hal_core.sh"
    "test_hal_refactor.sh"
    "test_system_integration.sh"
)

declare -a COMPREHENSIVE_TESTS=(
    "test_hardware_functionality.sh"
    "test_system_hardware_integration.sh"
)

declare -a ALL_TESTS=("${CORE_TESTS[@]}" "${COMPREHENSIVE_TESTS[@]}")

# Usage information
show_help() {
    cat << EOF
TrustMonitor Development Test Suite

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --quick     Run only essential tests (skip comprehensive tests)
    --verbose   Show detailed output from all tests
    --help      Show this help message

TESTS:
Core Tests (always run):
$(printf "  - %s\n" "${CORE_TESTS[@]}")

Comprehensive Tests (skipped with --quick):
$(printf "  - %s\n" "${COMPREHENSIVE_TESTS[@]}")

EXAMPLES:
    $0              # Run all tests
    $0 --quick      # Run only core tests
    $0 --verbose    # Run all tests with detailed output

EXIT CODES:
    0 - All tests passed
    1 - Some tests failed
    2 - Test environment error
EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --quick)
                QUICK_MODE=true
                shift
                ;;
            --verbose)
                VERBOSE_MODE=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 2
                ;;
        esac
    done
}

# Initialize test environment
init_test_env() {
    log_info "=== TrustMonitor Development Test Suite ==="
    log_info "Mode: $([ "$QUICK_MODE" = true ] && echo "QUICK" || echo "FULL")"
    log_info "Verbose: $([ "$VERBOSE_MODE" = true ] && echo "YES" || echo "NO")"
    log_info "Log file: $TEST_LOG"
    log_info "Project root: $PROJECT_ROOT"
    echo
    
    # Create log directory
    mkdir -p "$(dirname "$TEST_LOG")"
    
    # Initialize log file
    {
        echo "TrustMonitor Development Test Suite Log"
        echo "Started: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Mode: $([ "$QUICK_MODE" = true ] && echo "QUICK" || echo "FULL")"
        echo "Verbose: $([ "$VERBOSE_MODE" = true ] && echo "YES" || echo "NO")"
        echo "========================================"
        echo
    } > "$TEST_LOG"
}

# Run a single test
run_test() {
    local test_script="$1"
    local test_path="$SCRIPT_DIR/$test_script"
    
    ((TOTAL_TESTS++))
    
    log_test "TEST" "Running: $test_script"
    echo "[$(date '+%H:%M:%S')] Running: $test_script" >> "$TEST_LOG"
    
    if [[ ! -f "$test_path" ]]; then
        log_test "FAIL" "$test_script (script not found)"
        echo "ERROR: Test script not found: $test_path" >> "$TEST_LOG"
        ((FAILED_TESTS++))
        return 1
    fi
    
    # Make script executable
    chmod +x "$test_path"
    
    # Run test with appropriate options
    local test_output
    local test_exit_code
    
    if [[ "$VERBOSE_MODE" = true ]]; then
        # Run with verbose output
        "$test_path" > >(tee -a "$TEST_LOG") 2>&1
        test_exit_code=$?
        if [[ $test_exit_code -eq 0 ]]; then
            log_test "PASS" "$test_script"
            echo "PASS: $test_script" >> "$TEST_LOG"
            ((PASSED_TESTS++))
            return 0
        else
            log_test "FAIL" "$test_script (exit code: $test_exit_code)"
            echo "FAIL: $test_script (exit code: $test_exit_code)" >> "$TEST_LOG"
            ((FAILED_TESTS++))
            return 1
        fi
    else
        # Run with quiet output (only log results)
        if test_output=$("$test_path" 2>&1); then
            log_test "PASS" "$test_script"
            echo "PASS: $test_script" >> "$TEST_LOG"
            ((PASSED_TESTS++))
            return 0
        else
            log_test "FAIL" "$test_script (exit code: $?)"
            echo "FAIL: $test_script (exit code: $?)" >> "$TEST_LOG"
            echo "$test_output" >> "$TEST_LOG"
            ((FAILED_TESTS++))
            return 1
        fi
    fi
}

# Run test suite
run_test_suite() {
    local tests_to_run
    
    if [[ "$QUICK_MODE" = true ]]; then
        tests_to_run=("${CORE_TESTS[@]}")
        log_info "Running core tests only..."
    else
        tests_to_run=("${ALL_TESTS[@]}")
        log_info "Running all tests..."
    fi
    
    echo "Tests to run: ${#tests_to_run[@]}"
    echo "$(printf "  - %s\n" "${tests_to_run[@]}")"
    echo
    
    # Run each test
    for test_script in "${tests_to_run[@]}"; do
        run_test "$test_script"
        echo
    done
}

# Show final results
show_results() {
    echo "========================================"
    echo "Test Suite Results"
    echo "========================================"
    echo "Total tests: $TOTAL_TESTS"
    echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
    echo "Success rate: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%"
    echo
    
    # Log results
    {
        echo "========================================"
        echo "Test Suite Results"
        echo "========================================"
        echo "Total tests: $TOTAL_TESTS"
        echo "Passed: $PASSED_TESTS"
        echo "Failed: $FAILED_TESTS"
        echo "Success rate: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%"
        echo "Completed: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "========================================"
    } >> "$TEST_LOG"
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        log_info "🎉 All tests passed!"
        echo -e "${GREEN}🎉 All tests passed!${NC}"
        echo "Log file: $TEST_LOG"
        return 0
    else
        log_error "❌ Some tests failed!"
        echo -e "${RED}❌ Some tests failed!${NC}"
        echo "Check the log file for details: $TEST_LOG"
        echo
        echo "Failed tests:"
        grep "FAIL:" "$TEST_LOG" | tail -5
        return 1
    fi
}

# Main execution
main() {
    # Parse arguments
    parse_args "$@"
    
    # Initialize test environment
    init_test_env
    
    # Run test suite
    run_test_suite
    
    # Show results
    show_results
}

# Run main function with all arguments
main "$@"
