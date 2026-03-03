#!/bin/bash
# scripts/boot_sequence.sh
# Secure Boot sequence controller for ROT security
# Handles startup integrity checking and LED status management

set -u

# Load environment variables for standalone execution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load environment variables (if exists)
ENV_FILE="$BASE_DIR/config/health-monitor.env"
if [[ -f "$ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$ENV_FILE"
fi

# Load logger and return codes
source "$BASE_DIR/lib/logger.sh"
source "$BASE_DIR/lib/return_codes.sh"
source "$BASE_DIR/scripts/integrity_check.sh"

# Boot sequence logging
boot_sequence_log_info() {
    log_info "[BOOT] $1"
}

boot_sequence_log_warn() {
    log_warn "[BOOT] $1"
}

boot_sequence_log_error() {
    log_error "[BOOT] $1"
}

# LED control functions
set_led_color() {
    local color="$1"
    boot_sequence_log_info "Setting LED color: $color"
    
    # Try HAL LED controller first, fallback to legacy if HAL fails
    local led_success=false
    
    # Try HAL LED controller (preferred method)
    if [[ -f "$BASE_DIR/hardware/hal_led_controller.py" ]]; then
        # Try HAL with proper timeout and error handling
        boot_sequence_log_info "Attempting HAL LED controller..."
        
        # Use timeout to prevent hanging, with daemon mode for non-interactive operation
        if timeout 30 python3 "$BASE_DIR/hardware/hal_led_controller.py" --color "$color" --daemon >/dev/null 2>&1; then
            boot_sequence_log_info "LED color set via HAL: $color"
            led_success=true
        else
            boot_sequence_log_warn "HAL LED controller failed or timed out, trying legacy method"
        fi
    fi
    
    # Fallback to legacy LED controller if HAL failed
    if [[ "$led_success" == "false" ]]; then
        boot_sequence_log_info "Attempting legacy LED controller..."
        
        if timeout 5 python3 "$BASE_DIR/hardware/led_controller.py" --color "$color" >/dev/null 2>&1; then
            boot_sequence_log_info "LED color set via legacy controller: $color"
            led_success=true
        else
            boot_sequence_log_error "Both HAL and legacy LED controllers failed"
        fi
    fi
    
    # Register hardware process if function exists (called from health_monitor.sh)
    if declare -f register_hardware_process >/dev/null; then
        # For boot sequence, we don't have a persistent process to register
        # This is mainly for the health monitor daemon
        boot_sequence_log_info "LED control completed for boot sequence"
    fi
    
    return 0
}

blink_led_error() {
    local times="${1:-5}"  # Default 5 blinks, use 999 for infinite
    boot_sequence_log_info "Starting LED error blink sequence: $times times"
    
    # Use legacy LED controller for blinking (more reliable for error conditions)
    if timeout 10 python3 "$BASE_DIR/hardware/led_controller.py" --blink red --times "$times" >/dev/null 2>&1; then
        boot_sequence_log_info "LED error blink completed"
    else
        boot_sequence_log_error "LED error blink failed"
    fi
}

# System halt function for integrity failures
system_halt() {
    boot_sequence_log_error "SYSTEM HALT: Integrity check failed - entering deadlock"
    boot_sequence_log_error "REFUSING SERVICE: System will not enter monitoring mode"
    
    # Start LED error indication in background for continuous blinking
    blink_led_error 999 >/dev/null 2>&1 &
    local blink_pid=$!
    
    # Infinite loop (deadlock) - system refuses to continue
    while true; do
        boot_sequence_log_error "SYSTEM HALTED: Manual intervention required"
        sleep 10
    done
}

# Integrity verification with error handling
verify_system_integrity() {
    boot_sequence_log_info "Starting system integrity verification..."
    
    # Execute integrity check
    if integrity_check_check; then
        boot_sequence_log_info "System integrity verification PASSED"
        return $RC_OK
    else
        boot_sequence_log_error "System integrity verification FAILED"
        return $RC_INTEGRITY_FAILED
    fi
}

# Main boot sequence function
boot_sequence_check() {
    boot_sequence_log_info "=== SECURE BOOT SEQUENCE STARTING ==="
    
    # Step 1: Set LED to blue (booting status)
    boot_sequence_log_info "Step 1: Setting boot status LED (blue)"
    set_led_color blue
    
    # Step 2: Verify system integrity
    boot_sequence_log_info "Step 2: Verifying system integrity"
    if verify_system_integrity; then
        # SUCCESS: System integrity verified
        boot_sequence_log_info "Step 3: Boot sequence SUCCESS - entering monitoring mode"
        
        # Set LED to green (normal status) - let monitoring system take over
        set_led_color green
        
        boot_sequence_log_info "=== SECURE BOOT SEQUENCE COMPLETED SUCCESSFULLY ==="
        return $RC_OK
    else
        # FAILURE: System integrity compromised
        boot_sequence_log_error "Step 3: Boot sequence FAILED - initiating system halt"
        
        # Set LED to red blinking and halt system
        system_halt
        
        # This should never be reached due to infinite loop in system_halt
        return $RC_BOOT_FAILED
    fi
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    boot_sequence_check
    rc=$?
    echo "Boot sequence completed with status code: $rc"
    exit $rc
fi
