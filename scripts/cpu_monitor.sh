#!/bin/bash
# CPU Load Monitoring Script
# =========================
# Purpose: Monitor system CPU load
# Returns: 0=OK, 1=WARN, 2=ERROR

set -u

# Global variables
SCRIPT_NAME="CPU Monitor"
SCRIPT_VERSION="1.0.0"

# Utility functions
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $SCRIPT_NAME: $1"
}

log_warn() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $SCRIPT_NAME: $1" >&2
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $SCRIPT_NAME: $1" >&2
}

# CPU load reading function
cpu_load1() {
    awk '{print $1}' /proc/loadavg
}

# CPU load check function
cpu_check() {
    local load1 warn err
    
    load1="$(cpu_load1)"
    warn="${CPU_LOAD_WARN:-2.00}"
    err="${CPU_LOAD_ERROR:-3.00}"
    
    # Compare with thresholds
    if (( $(echo "$load1 >= $err" | bc -l) )); then
        log_error "CPU load critical: $load1"
        echo "CPU CRITICAL (load1=$load1)"
        return 2
    elif (( $(echo "$load1 >= $warn" | bc -l) )); then
        log_warn "CPU load warning: $load1"
        echo "CPU WARN (load1=$load1)"
        return 1
    else
        log_info "CPU load normal: $load1"
        echo "CPU OK (load1=$load1)"
        return 0
    fi
}

# Main execution logic
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    cpu_check
    exit $?
fi

