#!/bin/bash
# lib/return_codes.sh
# Unified return code constants for TrustMonitor system
# Provides standardized exit codes across all components

set -u

# Core system return codes
if [[ -z "${RC_OK:-}" ]]; then
    readonly RC_OK=0                    # Operation successful
    readonly RC_WARN=1                  # Warning condition
    readonly RC_ERROR=2                 # Error condition
    readonly RC_PLUGIN_ERROR=3          # Plugin system error

    # ROT Security return codes
    readonly RC_INTEGRITY_FAILED=4      # File integrity verification failed
    readonly RC_SIGNATURE_FAILED=5      # Digital signature verification failed
    readonly RC_BOOT_FAILED=6          # Secure boot sequence failed

    # Hardware return codes
    readonly RC_SENSOR_ERROR=7          # Sensor hardware error
    readonly RC_LED_ERROR=8             # LED hardware error

    # Network return codes
    readonly RC_NETWORK_FAILED=9        # Network connectivity failed

    # Configuration return codes
    readonly RC_CONFIG_ERROR=10         # Configuration error
    readonly RC_DEPENDENCY_ERROR=11     # Missing dependencies
fi

# Utility functions for return code handling
get_return_code_description() {
    local code="$1"
    case "$code" in
        $RC_OK) echo "SUCCESS" ;;
        $RC_WARN) echo "WARNING" ;;
        $RC_ERROR) echo "ERROR" ;;
        $RC_PLUGIN_ERROR) echo "PLUGIN_ERROR" ;;
        $RC_INTEGRITY_FAILED) echo "INTEGRITY_FAILED" ;;
        $RC_SIGNATURE_FAILED) echo "SIGNATURE_FAILED" ;;
        $RC_BOOT_FAILED) echo "BOOT_FAILED" ;;
        $RC_SENSOR_ERROR) echo "SENSOR_ERROR" ;;
        $RC_LED_ERROR) echo "LED_ERROR" ;;
        $RC_NETWORK_FAILED) echo "NETWORK_FAILED" ;;
        $RC_CONFIG_ERROR) echo "CONFIG_ERROR" ;;
        $RC_DEPENDENCY_ERROR) echo "DEPENDENCY_ERROR" ;;
        *) echo "UNKNOWN_CODE_$code" ;;
    esac
}

is_success_code() {
    local code="$1"
    [[ "$code" -eq "$RC_OK" ]]
}

is_warning_code() {
    local code="$1"
    [[ "$code" -eq "$RC_WARN" ]]
}

is_error_code() {
    local code="$1"
    [[ "$code" -ge "$RC_ERROR" && "$code" -le "$RC_DEPENDENCY_ERROR" ]]
}

is_critical_error() {
    local code="$1"
    [[ "$code" -ge "$RC_INTEGRITY_FAILED" && "$code" -le "$RC_BOOT_FAILED" ]]
}

# Logging functions with return code integration
log_with_rc() {
    local level="$1"
    local message="$2"
    local rc="${3:-$RC_OK}"
    local rc_desc
    rc_desc="$(get_return_code_description "$rc")"
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] [$rc_desc] $message"
}

log_info_with_rc() {
    log_with_rc "INFO" "$1" "${2:-$RC_OK}"
}

log_warn_with_rc() {
    log_with_rc "WARN" "$1" "${2:-$RC_WARN}"
}

log_error_with_rc() {
    log_with_rc "ERROR" "$1" "${2:-$RC_ERROR}"
}
