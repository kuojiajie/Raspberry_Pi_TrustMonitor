#!/bin/bash
# Disk Monitoring Plugin
# ======================
# Purpose: Monitor disk usage
# Returns: 0=OK, 1=WARN, 2=ERROR

set -u

# Plugin metadata
disk_monitor_description() {
    echo "Monitors disk usage with configurable mount point and thresholds"
}

# Disk usage reading
disk_monitor_used_pct() {
    local mount_point="${1:-/}"
    df -P "$mount_point" | awk 'NR==2 {gsub(/%/,"",$5); print $5}'
}

# Disk check function (plugin interface)
disk_monitor_check() {
    local mount_point warn err used
    
    mount_point="${1:-/}"
    warn="${DISK_USED_WARN_PCT:-80}"
    err="${DISK_USED_ERROR_PCT:-90}"
    used="$(disk_monitor_used_pct "$mount_point")"
    
    # Sanity check
    if [[ -z "$used" ]]; then
        log_error_with_rc "Cannot read disk usage: $mount_point" $RC_ERROR
        return $RC_ERROR
    fi
    
    # Compare with thresholds
    if (( $(awk "BEGIN {print ($used >= $err)}") )); then
        log_error_with_rc "Disk usage critical: ${used}%" $RC_ERROR
        echo "Disk CRITICAL (used=${used}%)"
        return $RC_ERROR
    elif (( $(awk "BEGIN {print ($used >= $warn)}") )); then
        log_warn "Disk usage high: ${used}%"
        echo "Disk WARN (used=${used}%)"
        return $RC_WARN
    else
        log_info "Disk usage normal: ${used}%"
        echo "Disk OK (used=${used}%)"
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
    
    disk_monitor_check "${1:-/}"
    rc=$?
    echo "Disk usage: $(disk_monitor_used_pct "${1:-/}")% status code: $rc"
    exit $rc
fi
