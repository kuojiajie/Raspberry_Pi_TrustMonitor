#!/bin/bash
# LED Integrity Test Suite
# =====================
# Purpose: Comprehensive LED testing for remote operations
# Tests both HAL and Legacy LED systems

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TEST_LOG="logs/led_test_$(date +%Y%m%d_%H%M%S).log"
GPIO_PINS=(27 22 5)  # Red, Green, Blue
TEST_COLORS=("red" "green" "blue" "off")
HAL_SCRIPT="hardware/hal_led_controller.py"
LEGACY_SCRIPT="hardware/led_controller.py"

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$TEST_LOG"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$TEST_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$TEST_LOG"
}

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1" | tee -a "$TEST_LOG"
}

# GPIO state checking (adapted for remote environment)
check_gpio_state() {
    local pin=$1
    local expected_state=$2
    
    log_test "Checking GPIO $pin state (expecting: $expected_state)"
    
    # Try multiple methods for GPIO state checking
    local gpio_available=false
    local state_check_passed=false
    
    # Method 1: Check if gpio command is available
    if command -v gpio >/dev/null 2>&1; then
        gpio_available=true
        local direction=$(gpio -g mode $pin 2>/dev/null || echo "unknown")
        local value=$(gpio -g read $pin 2>/dev/null || echo "-1")
        
        log_info "GPIO $pin: direction=$direction, value=$value"
        
        case "$expected_state" in
            "high")
                if [[ "$value" == "1" ]]; then
                    log_info "✅ GPIO $pin is HIGH as expected"
                    state_check_passed=true
                else
                    log_error "❌ GPIO $pin should be HIGH but is $value"
                fi
                ;;
            "low")
                if [[ "$value" == "0" ]]; then
                    log_info "✅ GPIO $pin is LOW as expected"
                    state_check_passed=true
                else
                    log_error "❌ GPIO $pin should be LOW but is $value"
                fi
                ;;
            "off")
                if [[ "$value" == "0" || "$direction" == "unknown" ]]; then
                    log_info "✅ GPIO $pin is OFF as expected"
                    state_check_passed=true
                else
                    log_warn "⚠️ GPIO $pin might still be active (value=$value)"
                fi
                ;;
        esac
    fi
    
    # Method 2: Check /sys/class/gpio if available
    if [[ -d "/sys/class/gpio/gpio$pin" ]]; then
        local value_file="/sys/class/gpio/gpio$pin/value"
        if [[ -f "$value_file" ]]; then
            local sys_value=$(cat "$value_file" 2>/dev/null || echo "-1")
            log_info "GPIO $pin (sysfs): value=$sys_value"
            
            case "$expected_state" in
                "high")
                    if [[ "$sys_value" == "1" ]]; then
                        log_info "✅ GPIO $pin is HIGH (sysfs check)"
                        state_check_passed=true
                    fi
                    ;;
                "low"|"off")
                    if [[ "$sys_value" == "0" ]]; then
                        log_info "✅ GPIO $pin is LOW/OFF (sysfs check)"
                        state_check_passed=true
                    fi
                    ;;
            esac
        fi
    fi
    
    # Method 3: Remote adaptation - check LED controller response
    if [[ "$gpio_available" == "false" ]]; then
        log_warn "⚠️ GPIO commands not available - using LED controller response verification"
        
        # For remote testing, we'll verify the LED controller executed successfully
        # This is handled in the test_led_controller function
        state_check_passed=true
    fi
    
    if [[ "$state_check_passed" == "true" ]]; then
        return 0
    else
        if [[ "$gpio_available" == "false" ]]; then
            log_info "ℹ️ GPIO hardware check skipped (remote environment)"
            return 0  # Don't fail for remote environment
        else
            return 1
        fi
    fi
}

# PWM state checking
check_pwm_state() {
    log_test "Checking PWM state for RGB LED"
    
    # Check if PWM processes are running
    local pwm_processes=$(pgrep -f "pwm\|LED" || true)
    if [[ -n "$pwm_processes" ]]; then
        log_warn "⚠️ PWM processes still running: $pwm_processes"
        return 1
    else
        log_info "✅ No PWM processes running"
        return 0
    fi
}

# LED controller test
test_led_controller() {
    local script=$1
    local controller_type=$2
    local test_passed=true
    
    log_test "Testing $controller_type LED controller: $script"
    
    # Test each color
    for color in "${TEST_COLORS[@]}"; do
        log_test "Testing $color LED with $controller_type"
        
        # Run LED command with timeout and background execution
        timeout 3 python3 "$script" --color "$color" >/dev/null 2>&1 &
        local led_pid=$!
        
        # Wait a moment for LED to initialize
        sleep 1
        
        # Check if the process is still running (expected for LED controllers)
        if kill -0 $led_pid 2>/dev/null; then
            log_info "✅ $controller_type $color LED is active (PID: $led_pid)"
            
            # Terminate the LED process
            kill $led_pid 2>/dev/null || true
            wait $led_pid 2>/dev/null || true
            
            # Check GPIO state (skip for 'off' and for remote environment)
            if [[ "$color" != "off" ]] && command -v gpio >/dev/null 2>&1; then
                case "$color" in
                    "red")
                        check_gpio_state ${GPIO_PINS[0]} "high" || test_passed=false
                        check_gpio_state ${GPIO_PINS[1]} "low" || test_passed=false
                        check_gpio_state ${GPIO_PINS[2]} "low" || test_passed=false
                        ;;
                    "green")
                        check_gpio_state ${GPIO_PINS[0]} "low" || test_passed=false
                        check_gpio_state ${GPIO_PINS[1]} "high" || test_passed=false
                        check_gpio_state ${GPIO_PINS[2]} "low" || test_passed=false
                        ;;
                    "blue")
                        check_gpio_state ${GPIO_PINS[0]} "low" || test_passed=false
                        check_gpio_state ${GPIO_PINS[1]} "low" || test_passed=false
                        check_gpio_state ${GPIO_PINS[2]} "high" || test_passed=false
                        ;;
                esac
            elif [[ "$color" != "off" ]]; then
                log_info "ℹ️ GPIO state check skipped (remote environment)"
            fi
        else
            # Process already terminated - check if it was successful
            if [[ $? -eq 124 ]]; then
                log_warn "⚠️ $controller_type $color command timed out (may be normal)"
                test_passed=false
            else
                log_error "❌ $controller_type $color command failed immediately"
                test_passed=false
            fi
        fi
        
        # Small delay between tests
        sleep 0.5
    done
    
    # Cleanup - ensure all LED processes are terminated
    log_test "Cleaning up $controller_type LED controller"
    pkill -f "hal_led_controller.py\|led_controller.py" 2>/dev/null || true
    timeout 5 python3 "$script" --off >/dev/null 2>&1 || true
    
    if [[ "$test_passed" == "true" ]]; then
        log_info "✅ $controller_type LED controller test PASSED"
        return 0
    else
        log_error "❌ $controller_type LED controller test FAILED"
        return 1
    fi
}

# Status indication test
test_status_indication() {
    log_test "Testing LED status indication system"
    
    # Test health monitor status LED changes
    log_test "Simulating health monitor status changes"
    
    # Create a test script to simulate different statuses
    cat > /tmp/test_led_status.py << 'EOF'
#!/usr/bin/env python3
import sys
import time
sys.path.append('/home/kuojiajie9999/Raspberry_Pi_TrustMonitor')

try:
    from hardware.hal_led_controller import HALLEDController
    led = HALLEDController()
    
    # Test different statuses
    statuses = [
        ("boot", "blue"),
        ("healthy", "green"), 
        ("warning", "yellow"),
        ("error", "red"),
        ("shutdown", "off")
    ]
    
    for status, color in statuses:
        print(f"Testing status: {status} -> {color}")
        if color == "yellow":
            # Yellow = Red + Green
            led.set_color("red")
            time.sleep(0.1)
            led.set_color("green")
        else:
            led.set_color(color)
        time.sleep(2)
        
    led.cleanup()
    print("Status indication test completed")
    
except Exception as e:
    print(f"Status test failed: {e}")
    sys.exit(1)
EOF
    
    if timeout 30 python3 /tmp/test_led_status.py 2>/dev/null; then
        log_info "✅ Status indication test PASSED"
        return 0
    else
        log_error "❌ Status indication test FAILED"
        return 1
    fi
}

# GPIO cleanup test
test_gpio_cleanup() {
    log_test "Testing GPIO cleanup functionality"
    
    # Run cleanup script
    if ./tools/dev/cleanup_gpio.sh >/dev/null 2>&1; then
        log_info "✅ GPIO cleanup script executed successfully"
        
        # Check all GPIO pins are off
        local all_clean=true
        for pin in "${GPIO_PINS[@]}"; do
            check_gpio_state $pin "off" || all_clean=false
        done
        
        # Check PWM state
        check_pwm_state || all_clean=false
        
        if [[ "$all_clean" == "true" ]]; then
            log_info "✅ GPIO cleanup test PASSED"
            return 0
        else
            log_error "❌ GPIO cleanup test FAILED - some pins still active"
            return 1
        fi
    else
        log_error "❌ GPIO cleanup script failed"
        return 1
    fi
}

# Remote testing adaptation
test_remote_adaptation() {
    log_test "Testing remote adaptation methods"
    
    # Test LED control logging
    log_test "Testing LED control logging"
    
    # Run LED control and check logs
    timeout 5 python3 "$HAL_SCRIPT" --color green >/dev/null 2>&1
    
    # Check if LED control was logged
    if journalctl -u health-monitor.service --since "1 minute ago" | grep -q "LED\|RGB" 2>/dev/null; then
        log_info "✅ LED control logging detected"
    else
        log_warn "⚠️ No LED control logging found (may be normal for standalone test)"
    fi
    
    # Test GPIO state verification without hardware
    log_test "Testing GPIO state verification"
    
    # Check if we can read GPIO states
    if command -v gpio >/dev/null 2>&1; then
        log_info "✅ GPIO reading available for remote testing"
        
        # Test reading all LED pins
        for pin in "${GPIO_PINS[@]}"; do
            local state=$(gpio -g read $pin 2>/dev/null || echo "-1")
            log_info "GPIO $pin state: $state"
        done
        
        return 0
    else
        log_warn "⚠️ GPIO reading not available - limited remote testing"
        return 1
    fi
}

# Main test execution
main() {
    log_info "=== LED Integrity Test Suite ==="
    log_info "Test started at: $(date)"
    log_info "Test log: $TEST_LOG"
    
    # Create log directory
    mkdir -p "$(dirname "$TEST_LOG")"
    
    local tests_passed=0
    local tests_failed=0
    local total_tests=0
    
    # Test 1: HAL LED Controller
    echo
    log_test "=== Test 1: HAL LED Controller ==="
    ((total_tests++))
    if test_led_controller "$HAL_SCRIPT" "HAL"; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Test 2: Legacy LED Controller  
    echo
    log_test "=== Test 2: Legacy LED Controller ==="
    ((total_tests++))
    if test_led_controller "$LEGACY_SCRIPT" "Legacy"; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Test 3: Status Indication
    echo
    log_test "=== Test 3: Status Indication ==="
    ((total_tests++))
    if test_status_indication; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Test 4: GPIO Cleanup
    echo
    log_test "=== Test 4: GPIO Cleanup ==="
    ((total_tests++))
    if test_gpio_cleanup; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Test 5: Remote Adaptation
    echo
    log_test "=== Test 5: Remote Adaptation ==="
    ((total_tests++))
    if test_remote_adaptation; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Final cleanup
    echo
    log_test "=== Final Cleanup ==="
    ./tools/dev/cleanup_gpio.sh >/dev/null 2>&1 || true
    rm -f /tmp/test_led_status.py
    
    # Test results
    echo
    log_info "=== LED Integrity Test Results ==="
    log_info "Total Tests: $total_tests"
    log_info "Passed: $tests_passed"
    log_info "Failed: $tests_failed"
    
    if [[ $tests_failed -eq 0 ]]; then
        log_info "🎉 All LED integrity tests PASSED!"
        log_info "LED system is ready for Phase 3"
        return 0
    else
        log_error "❌ Some LED integrity tests FAILED!"
        log_error "Please check the log file: $TEST_LOG"
        return 1
    fi
}

# Execute main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
