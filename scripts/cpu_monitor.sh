#!/bin/bash
# CPU Monitoring Plugin
# =====================
# Purpose: Monitor CPU load
# Returns: 0=OK, 1=WARN, 2=ERROR

set -u

# Plugin metadata
cpu_monitor_description() {
    echo "Monitors CPU load with configurable warning and error thresholds"
}

# CPU load reading function
cpu_monitor_load1() {
    awk '{print $1}' /proc/loadavg
}

# CPU load check function (plugin interface)
cpu_monitor_check() {
    local load1 warn err
    
    load1="$(cpu_monitor_load1)"
    warn="${CPU_LOAD_WARN:-2.00}"
    err="${CPU_LOAD_ERROR:-3.00}"
    
    # Compare with thresholds
    if (( $(awk "BEGIN {print ($load1 >= $err)}") )); then
        log_error "CPU load critical: $load1"
        echo "CPU CRITICAL (load1=$load1)"
        return 2
    elif (( $(awk "BEGIN {print ($load1 >= $warn)}") )); then
        log_warn "CPU load warning: $load1"
        echo "CPU WARN (load1=$load1)"
        return 1
    else
        log_info "CPU load normal: $load1"
        echo "CPU OK (load1=$load1)"
        return 0
    fi
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Load environment variables for standalone execution
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
    
    # Load environment variables (if exists)
    ENV_FILE="$BASE_DIR/config/health-monitor.env"
    if [[ -f "$ENV_FILE" ]]; then
        # shellcheck disable=SC1090
        source "$ENV_FILE"
    fi
    
    # Load logger for standalone execution
    source "$BASE_DIR/lib/logger.sh"
    
    cpu_monitor_check
    rc=$?
    echo "CPU load: $(cpu_monitor_load1) status code: $rc"
    exit $rc
fi
