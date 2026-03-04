#!/bin/bash
# tests/test_runner.sh
# TrustMonitor Testing Framework - Main Test Runner
# Provides unified interface for running all test suites

set -u

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load libraries
source "$BASE_DIR/lib/return_codes.sh"
source "$BASE_DIR/lib/logger.sh"

# Test configuration
TEST_RESULTS_DIR="$BASE_DIR/tests/results"
TEST_LOG_DIR="$BASE_DIR/tests/logs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Initialize test environment
init_test_environment() {
    log_info "[TEST_RUNNER] Initializing test environment..."
    
    # Create results directory
    mkdir -p "$TEST_RESULTS_DIR"
    mkdir -p "$TEST_LOG_DIR"
    
    # Initialize test results file
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    TEST_RESULTS_FILE="$TEST_RESULTS_DIR/test_results_$timestamp.json"
    
    cat > "$TEST_RESULTS_FILE" << EOF
{
  "test_run": {
    "timestamp": "$(date -Iseconds)",
    "branch": "$(git branch --show-current)",
    "commit": "$(git rev-parse HEAD)",
    "environment": {
      "os": "$(uname -s)",
      "kernel": "$(uname -r)",
      "python": "$(python3 --version 2>&1 | head -n1)"
    }
  },
  "test_suites": []
}
EOF
    
    echo "$TEST_RESULTS_FILE"
}

# Run unit tests
run_unit_tests() {
    log_info "[TEST_RUNNER] Running unit tests..."
    
    local unit_tests=(
        "test_logger.sh"
        "test_return_codes.sh"
        "test_config_validation.sh"
        "test_backup_manager.sh"
        "test_path_manager.sh"
    )
    
    for test_script in "${unit_tests[@]}"; do
        if [[ -f "$SCRIPT_DIR/unit/$test_script" ]]; then
            log_info "[TEST_RUNNER] Running unit test: $test_script"
            bash "$SCRIPT_DIR/unit/$test_script" "$TEST_RESULTS_FILE" "append"
        else
            log_warn "[TEST_RUNNER] Unit test not found: $test_script"
            ((SKIPPED_TESTS++))
        fi
    done
}

# Run integration tests
run_integration_tests() {
    log_info "[TEST_RUNNER] Running integration tests..."
    
    local integration_tests=(
        "test_boot_sequence.sh"
        "test_integrity_check.sh"
        "test_monitoring_scripts.sh"
        "test_hardware_integration.sh"
    )
    
    for test_script in "${integration_tests[@]}"; do
        if [[ -f "$SCRIPT_DIR/integration/$test_script" ]]; then
            log_info "[TEST_RUNNER] Running integration test: $test_script"
            bash "$SCRIPT_DIR/integration/$test_script" "$TEST_RESULTS_FILE" "append"
        else
            log_warn "[TEST_RUNNER] Integration test not found: $test_script"
            ((SKIPPED_TESTS++))
        fi
    done
}

# Run security tests
run_security_tests() {
    log_info "[TEST_RUNNER] Running security tests..."
    
    local security_tests=(
        "test_integrity_verification.sh"
    )
    
    for test_script in "${security_tests[@]}"; do
        if [[ -f "$SCRIPT_DIR/security/$test_script" ]]; then
            log_info "[TEST_RUNNER] Running security test: $test_script"
            bash "$SCRIPT_DIR/security/$test_script" "$TEST_RESULTS_FILE" "append"
        else
            log_warn "[TEST_RUNNER] Security test not found: $test_script"
            ((SKIPPED_TESTS++))
        fi
    done
}

# Generate test report
generate_test_report() {
    log_info "[TEST_RUNNER] Generating test report..."
    
    # Parse JSON results to get actual test counts
    if [[ -f "$TEST_RESULTS_FILE" ]]; then
        # Count test results from the appended text format
        TOTAL_TESTS=$(grep -cE "^\[PASS\]|\[FAIL\]|\[SKIP\]" "$TEST_RESULTS_FILE" 2>/dev/null)
        PASSED_TESTS=$(grep -c "^\[PASS\]" "$TEST_RESULTS_FILE" 2>/dev/null)
        FAILED_TESTS=$(grep -c "^\[FAIL\]" "$TEST_RESULTS_FILE" 2>/dev/null)
        SKIPPED_TESTS=$(grep -c "^\[SKIP\]" "$TEST_RESULTS_FILE" 2>/dev/null)
        
        # Clean fallback for empty results
        TOTAL_TESTS=${TOTAL_TESTS:-0}
        PASSED_TESTS=${PASSED_TESTS:-0}
        FAILED_TESTS=${FAILED_TESTS:-0}
        SKIPPED_TESTS=${SKIPPED_TESTS:-0}
    else
        TOTAL_TESTS=0
        PASSED_TESTS=0
        FAILED_TESTS=0
        SKIPPED_TESTS=0
    fi
    
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local report_file="$TEST_RESULTS_DIR/test_report_$timestamp.txt"
    
    # Calculate success rate
    local success_rate=0
    if [[ $TOTAL_TESTS -gt 0 ]]; then
        success_rate=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
    fi
    
    cat > "$report_file" << EOF
TrustMonitor Test Report
====================
Run Date: $(date)
Branch: $(git branch --show-current)
Commit: $(git rev-parse --short HEAD)

Test Summary:
-------------
Total Tests: $TOTAL_TESTS
Passed: $PASSED_TESTS
Failed: $FAILED_TESTS
Skipped: $SKIPPED_TESTS
Success Rate: ${success_rate}%

Test Suites:
-----------
EOF
    
    # Add test suite results
    if [[ -f "$TEST_RESULTS_FILE" ]]; then
        echo "Unit Tests: $(grep -c '"test_type": "unit"' "$TEST_RESULTS_FILE" || echo 0)" >> "$report_file"
        echo "Integration Tests: $(grep -c '"test_type": "integration"' "$TEST_RESULTS_FILE" || echo 0)" >> "$report_file"
        echo "Security Tests: $(grep -c '"test_type": "security"' "$TEST_RESULTS_FILE" || echo 0)" >> "$report_file"
    fi
    
    echo "" >> "$report_file"
    echo "For detailed results, see: $TEST_RESULTS_FILE"
    echo "" >> "$report_file"
    
    log_info "[TEST_RUNNER] Test report generated: $report_file"
}

# Show help
show_help() {
    cat << EOF
TrustMonitor Testing Framework

USAGE:
    $0 [OPTIONS] [TEST_TYPE]

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -q, --quiet         Suppress non-error output
    --report-only       Generate report without running tests
    --clean             Clean test results and logs

TEST TYPES:
    unit               Run unit tests only
    integration        Run integration tests only
    security           Run security tests only
    all                Run all tests (default)

EXAMPLES:
    # Run all tests
    $0

    # Run only unit tests
    $0 unit

    # Run only integration tests
    $0 integration

    # Generate report only
    $0 --report-only

    # Clean test results
    $0 --clean

EXIT CODES:
    0  - All tests passed
    1  - Some tests failed
    2  - Some tests skipped
    3  - Test environment error

EOF
}

# Clean test environment
clean_test_environment() {
    log_info "[TEST_RUNNER] Cleaning test environment..."
    
    if [[ -d "$TEST_RESULTS_DIR" ]]; then
        rm -rf "$TEST_RESULTS_DIR"/*
        log_info "[TEST_RUNNER] Test results cleaned"
    fi
    
    if [[ -d "$TEST_LOG_DIR" ]]; then
        rm -rf "$TEST_LOG_DIR"/*
        log_info "[TEST_RUNNER] Test logs cleaned"
    fi
}

# Main function
main() {
    local test_type="all"
    local verbose=false
    local quiet=false
    local report_only=false
    local clean=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                return $RC_OK
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -q|--quiet)
                quiet=true
                shift
                ;;
            --report-only)
                report_only=true
                shift
                ;;
            --clean)
                clean=true
                shift
                ;;
            unit|integration|security|all)
                test_type="$1"
                shift
                ;;
            *)
                log_error "[TEST_RUNNER] Unknown option: $1"
                show_help
                return $RC_ERROR
                ;;
        esac
    done
    
    # Handle clean option
    if [[ "$clean" == "true" ]]; then
        clean_test_environment
        return $RC_OK
    fi
    
    # Initialize test environment
    init_test_environment
    
    # Handle report-only option
    if [[ "$report_only" == "true" ]]; then
        generate_test_report
        return $RC_OK
    fi
    
    # Run tests based on type
    case "$test_type" in
        unit)
            run_unit_tests
            ;;
        integration)
            run_integration_tests
            ;;
        security)
            run_security_tests
            ;;
        all)
            run_unit_tests
            run_integration_tests
            run_security_tests
            ;;
    esac
    
    # Generate final report
    generate_test_report
    
    # Show summary
    if [[ "$quiet" != "true" ]]; then
        echo ""
        echo -e "${BLUE}Test Run Summary:${NC}"
        echo -e "  Total Tests: $TOTAL_TESTS"
        echo -e "  ${GREEN}Passed: $PASSED_TESTS${NC}"
        echo -e "  ${RED}Failed: $FAILED_TESTS${NC}"
        echo -e "  ${YELLOW}Skipped: $SKIPPED_TESTS${NC}"
        
        if [[ $TOTAL_TESTS -gt 0 ]]; then
            local success_rate=$(( (PASSED_TESTS * 100) / TOTAL_TESTS))
            echo -e "  Success Rate: ${success_rate}%"
        fi
        
        echo ""
        echo -e "${BLUE}Detailed Results:${NC} $TEST_RESULTS_FILE"
        echo -e "${BLUE}Test Report:${NC} $TEST_RESULTS_DIR/test_report_$(date '+%Y%m%d_%H%M%S').txt"
    fi
    
    # Return appropriate exit code
    if [[ $FAILED_TESTS -gt 0 ]]; then
        return $RC_ERROR
    elif [[ $SKIPPED_TESTS -gt 0 ]]; then
        return 2
    else
        return $RC_OK
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
