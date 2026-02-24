#!/bin/bash
# Memory Monitoring Plugin
# ========================
# Purpose: Monitor memory availability
# Returns: 0=OK, 1=WARN, 2=ERROR

set -u

# Plugin metadata
memory_monitor_description() {
    echo "Monitors memory availability with percentage-based thresholds"
}

# Memory reading functions
memory_monitor_total_kb() {
    awk '/^MemTotal:/ {print $2}' /proc/meminfo
}

memory_monitor_avail_kb() {
    awk '/^MemAvailable:/ {print $2}' /proc/meminfo
}

memory_monitor_avail_pct() {
    local total avail
    
    total="$(memory_monitor_total_kb)"
    avail="$(memory_monitor_avail_kb)"
    
    if [[ "$total" -gt 0 ]]; then
        awk "BEGIN {printf \"%.1f\", ($avail/$total)*100}"
    else
        echo "0"
    fi
}

# Memory check function (plugin interface)
memory_monitor_check() {
    local warn_pct err_pct avail_pct
    
    warn_pct="${MEM_AVAIL_WARN_PCT:-15}"
    err_pct="${MEM_AVAIL_ERROR_PCT:-5}"
    avail_pct="$(memory_monitor_avail_pct)"
    
    # Compare with thresholds
    if (( $(awk "BEGIN {print ($avail_pct <= $err_pct)}") )); then
        log_error_with_rc "Memory availability critical: ${avail_pct}%" $RC_ERROR
        echo "Memory CRITICAL (avail=${avail_pct}%)"
        return $RC_ERROR
    elif (( $(awk "BEGIN {print ($avail_pct <= $warn_pct)}") )); then
        log_warn "Memory availability low: ${avail_pct}%"
        echo "Memory WARN (avail=${avail_pct}%)"
        return $RC_WARN
    else
        log_info "Memory availability normal: ${avail_pct}%"
        echo "Memory OK (avail=${avail_pct}%)"
        return $RC_OK
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
    
    # Load logger and return codes
    source "$BASE_DIR/lib/logger.sh"
    source "$BASE_DIR/lib/return_codes.sh"
    
    memory_monitor_check
    rc=$?
    echo "Memory availability: $(memory_monitor_avail_pct)% status code: $rc"
    exit $rc
fi
