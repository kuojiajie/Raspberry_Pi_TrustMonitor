#!/bin/bash
# tools/test_sigterm.sh
# Test script for SIGTERM graceful shutdown functionality

set -u

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_LOG="$BASE_DIR/logs/sigterm_test.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [TEST] $1" | tee -a "$TEST_LOG"
}

log_info() {
    echo -e "${GREEN}$(date '+%Y-%m-%d %H:%M:%S') [TEST] $1${NC}" | tee -a "$TEST_LOG"
}

log_warn() {
    echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S') [TEST] $1${NC}" | tee -a "$TEST_LOG"
}

log_error() {
    echo -e "${RED}$(date '+%Y-%m-%d %H:%M:%S') [TEST] $1${NC}" | tee -a "$TEST_LOG"
}

# Cleanup function
cleanup_test() {
    log_info "Cleaning up test environment..."
    
    # Kill any remaining health monitor processes
    pkill -f "health_monitor.sh" 2>/dev/null || true
    sleep 1
    
    # Clean up test files
    rm -f "$BASE_DIR/.last_shutdown" 2>/dev/null || true
    rm -f "$BASE_DIR/test.pid" 2>/dev/null || true
    
    log_info "Test cleanup completed"
}

# Test 1: Basic SIGTERM handling
test_basic_sigterm() {
    log_info "=== Test 1: Basic SIGTERM Handling ==="
    
    # Start health monitor in background
    log_info "Starting health monitor in background..."
    timeout 60 bash "$BASE_DIR/daemon/health_monitor.sh" > "$BASE_DIR/logs/test_output.log" 2>&1 &
    local hm_pid=$!
    echo "$hm_pid" > "$BASE_DIR/test.pid"
    
    log_info "Health monitor started with PID: $hm_pid"
    
    # Give it time to start
    sleep 5
    
    # Check if process is running
    if ! kill -0 "$hm_pid" 2>/dev/null; then
        log_error "Health monitor failed to start"
        return 1
    fi
    
    log_info "Sending SIGTERM to health monitor..."
    kill -TERM "$hm_pid"
    
    # Wait for graceful shutdown
    local wait_count=0
    while kill -0 "$hm_pid" 2>/dev/null && [[ $wait_count -lt 10 ]]; do
        sleep 1
        ((wait_count++))
        log_info "Waiting for shutdown... ($wait_count/10)"
    done
    
    # Check if process terminated gracefully
    if kill -0 "$hm_pid" 2>/dev/null; then
        log_error "Health monitor did not terminate gracefully"
        kill -KILL "$hm_pid" 2>/dev/null || true
        return 1
    else
        log_info "Health monitor terminated gracefully"
    fi
    
    # Check for shutdown timestamp file
    if [[ -f "$BASE_DIR/.last_shutdown" ]]; then
        local shutdown_time=$(cat "$BASE_DIR/.last_shutdown")
        log_info "Shutdown timestamp saved: $shutdown_time"
    else
        log_warn "Shutdown timestamp file not found"
    fi
    
    # Check logs for cleanup messages
    if grep -q "Cleaning up hardware resources" "$BASE_DIR/logs/test_output.log"; then
        log_info "Hardware cleanup was performed"
    else
        log_warn "Hardware cleanup message not found in logs"
    fi
    
    log_info "Test 1 completed"
    return 0
}

# Test 2: SIGINT handling
test_sigint() {
    log_info "=== Test 2: SIGINT Handling ==="
    
    # Start health monitor in background
    log_info "Starting health monitor in background..."
    timeout 60 bash "$BASE_DIR/daemon/health_monitor.sh" > "$BASE_DIR/logs/test_output2.log" 2>&1 &
    local hm_pid=$!
    
    log_info "Health monitor started with PID: $hm_pid"
    
    # Give it time to start
    sleep 5
    
    # Send SIGINT (Ctrl+C)
    log_info "Sending SIGINT to health monitor..."
    kill -INT "$hm_pid"
    
    # Wait for graceful shutdown
    local wait_count=0
    while kill -0 "$hm_pid" 2>/dev/null && [[ $wait_count -lt 10 ]]; do
        sleep 1
        ((wait_count++))
        log_info "Waiting for shutdown... ($wait_count/10)"
    done
    
    # Check result
    if kill -0 "$hm_pid" 2>/dev/null; then
        log_error "Health monitor did not terminate gracefully on SIGINT"
        kill -KILL "$hm_pid" 2>/dev/null || true
        return 1
    else
        log_info "Health monitor terminated gracefully on SIGINT"
    fi
    
    log_info "Test 2 completed"
    return 0
}

# Test 3: Multiple signal handling
test_multiple_signals() {
    log_info "=== Test 3: Multiple Signal Handling ==="
    
    # Start health monitor in background
    log_info "Starting health monitor in background..."
    timeout 60 bash "$BASE_DIR/daemon/health_monitor.sh" > "$BASE_DIR/logs/test_output3.log" 2>&1 &
    local hm_pid=$!
    
    log_info "Health monitor started with PID: $hm_pid"
    
    # Give it time to start
    sleep 3
    
    # Send multiple signals rapidly
    log_info "Sending multiple signals..."
    kill -TERM "$hm_pid"
    sleep 1
    kill -INT "$hm_pid"
    sleep 1
    kill -TERM "$hm_pid"
    
    # Wait for shutdown
    local wait_count=0
    while kill -0 "$hm_pid" 2>/dev/null && [[ $wait_count -lt 15 ]]; do
        sleep 1
        ((wait_count++))
        log_info "Waiting for shutdown... ($wait_count/15)"
    done
    
    # Check result
    if kill -0 "$hm_pid" 2>/dev/null; then
        log_error "Health monitor did not handle multiple signals properly"
        kill -KILL "$hm_pid" 2>/dev/null || true
        return 1
    else
        log_info "Health monitor handled multiple signals properly"
    fi
    
    log_info "Test 3 completed"
    return 0
}

# Main test execution
main() {
    log_info "Starting SIGTERM handling tests..."
    
    # Create logs directory
    mkdir -p "$BASE_DIR/logs"
    
    # Clean up any existing processes
    cleanup_test
    
    local test_passed=0
    local test_failed=0
    
    # Run tests
    if test_basic_sigterm; then
        ((test_passed++))
    else
        ((test_failed++))
    fi
    
    cleanup_test
    sleep 2
    
    if test_sigint; then
        ((test_passed++))
    else
        ((test_failed++))
    fi
    
    cleanup_test
    sleep 2
    
    if test_multiple_signals; then
        ((test_passed++))
    else
        ((test_failed++))
    fi
    
    # Final cleanup
    cleanup_test
    
    # Summary
    log_info "=== Test Summary ==="
    log_info "Tests passed: $test_passed"
    log_info "Tests failed: $test_failed"
    
    if [[ $test_failed -eq 0 ]]; then
        log_info "All tests passed! SIGTERM handling is working correctly."
        return 0
    else
        log_error "Some tests failed. Please check the logs."
        return 1
    fi
}

# Run main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
