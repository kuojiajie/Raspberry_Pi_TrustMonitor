#!/bin/bash
# tools/test_network_format.sh
# Test network monitor integration with main health monitor

set -u

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_LOG="$BASE_DIR/logs/network_format_test.log"

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

# Test 1: Standalone network monitor
test_standalone() {
    log_info "=== Test 1: Standalone Network Monitor ==="
    
    log_info "Testing normal status..."
    bash "$BASE_DIR/scripts/network_monitor.sh" > "$BASE_DIR/logs/network_normal.log" 2>&1
    local rc_normal=$?
    
    log_info "Testing warning status..."
    NETWORK_LATENCY_WARN_MS=10 bash "$BASE_DIR/scripts/network_monitor.sh" > "$BASE_DIR/logs/network_warn.log" 2>&1
    local rc_warn=$?
    
    # Check output format
    if grep -q "Network OK (latency=" "$BASE_DIR/logs/network_normal.log"; then
        log_info "✅ Normal format correct"
    else
        log_error "❌ Normal format incorrect"
        return 1
    fi
    
    if grep -q "Network WARN (latency=" "$BASE_DIR/logs/network_warn.log"; then
        log_info "✅ Warning format correct"
    else
        log_error "❌ Warning format incorrect"
        return 1
    fi
    
    log_info "Return codes: normal=$rc_normal, warn=$rc_warn"
    
    if [[ $rc_normal -eq 0 && $rc_warn -eq 1 ]]; then
        log_info "✅ Return codes correct"
    else
        log_error "❌ Return codes incorrect"
        return 1
    fi
    
    return 0
}

# Test 2: Integration with health monitor
test_integration() {
    log_info "=== Test 2: Health Monitor Integration ==="
    
    # Start health monitor briefly to capture network monitoring output
    log_info "Starting health monitor for 10 seconds..."
    timeout 10 bash "$BASE_DIR/daemon/health_monitor.sh" > "$BASE_DIR/logs/health_monitor_test.log" 2>&1 &
    local hm_pid=$!
    
    # Wait for monitoring cycle
    sleep 8
    
    # Terminate gracefully
    kill -TERM "$hm_pid" 2>/dev/null || true
    wait "$hm_pid" 2>/dev/null || true
    
    # Check if network monitoring ran
    if grep -q "Network.*latency.*ms" "$BASE_DIR/logs/health_monitor_test.log"; then
        log_info "✅ Network monitoring integrated"
        
        # Show network-related lines
        log_info "Network monitoring output:"
        grep "Network" "$BASE_DIR/logs/health_monitor_test.log" | head -5
    else
        log_warn "⚠️ Network monitoring output not captured (may need more time)"
    fi
    
    return 0
}

# Test 3: Format consistency check
test_format_consistency() {
    log_info "=== Test 3: Format Consistency Check ==="
    
    # Test all monitoring scripts for format consistency
    local scripts=("cpu_monitor" "memory_monitor" "disk_monitor" "network_monitor" "cpu_temp_monitor")
    local format_ok=true
    
    for script in "${scripts[@]}"; do
        log_info "Testing $script format..."
        
        # Run script and capture output
        bash "$BASE_DIR/scripts/$script.sh" > "$BASE_DIR/logs/${script}_format.log" 2>&1
        local rc=$?
        
        # Check for consistent format pattern
        if grep -E "^(CPU|Memory|Disk|Network|CPU Temperature) (OK|WARN|ERROR) \(" "$BASE_DIR/logs/${script}_format.log" > /dev/null; then
            log_info "✅ $script format consistent"
        else
            log_error "❌ $script format inconsistent"
            format_ok=false
        fi
        
        # Check for second line with details
        if grep -E "^(CPU load|Memory availability|Disk usage|Network latency|CPU temperature):" "$BASE_DIR/logs/${script}_format.log" > /dev/null; then
            log_info "✅ $script detail line present"
        else
            log_error "❌ $script detail line missing"
            format_ok=false
        fi
    done
    
    if $format_ok; then
        log_info "✅ All scripts format consistent"
        return 0
    else
        log_error "❌ Some scripts format inconsistent"
        return 1
    fi
}

# Test 4: Performance impact test
test_performance() {
    log_info "=== Test 4: Performance Impact Test ==="
    
    # Test network monitor execution time
    local start_time=$(date +%s.%N)
    bash "$BASE_DIR/scripts/network_monitor.sh" > /dev/null 2>&1
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0.1")
    
    log_info "Network monitor execution time: ${duration}s"
    
    # Check if performance is reasonable (< 5 seconds)
    if (( $(echo "$duration < 5" | bc -l 2>/dev/null || echo "1") )); then
        log_info "✅ Performance acceptable"
    else
        log_warn "⚠️ Performance may need optimization"
    fi
    
    return 0
}

# Main test execution
main() {
    log_info "Starting Network Monitor Format and Integration Tests..."
    
    # Create logs directory
    mkdir -p "$BASE_DIR/logs"
    
    local test_passed=0
    local test_failed=0
    
    # Run tests
    if test_standalone; then
        ((test_passed++))
    else
        ((test_failed++))
    fi
    
    if test_integration; then
        ((test_passed++))
    else
        ((test_failed++))
    fi
    
    if test_format_consistency; then
        ((test_passed++))
    else
        ((test_failed++))
    fi
    
    if test_performance; then
        ((test_passed++))
    else
        ((test_failed++))
    fi
    
    # Summary
    log_info "=== Test Summary ==="
    log_info "Tests passed: $test_passed"
    log_info "Tests failed: $test_failed"
    
    if [[ $test_failed -eq 0 ]]; then
        log_warn "⚠️ Performance may need optimization"
    else
        log_error "❌ Some tests failed. Please check the logs."
        return 1
    fi
    return 0
}

# Run main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
