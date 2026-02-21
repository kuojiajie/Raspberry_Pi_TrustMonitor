#!/bin/bash
# Disk Monitoring Script
# =================
# Purpose: Monitor disk usage
# Returns: 0=OK, 1=WARN, 2=ERROR

set -u

# Global variables
SCRIPT_NAME="Disk Monitor"

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

# Disk usage reading
disk_used_pct() {
    local mount_point="${1:-/}"
    df -P "$mount_point" | awk 'NR==2 {gsub(/%/,"",$5); print $5}'
}

# Disk check
disk_check() {
    local mount_point warn err used
    
    mount_point="${1:-/}"
    warn="${DISK_USED_WARN_PCT:-80}"
    err="${DISK_USED_ERROR_PCT:-90}"
    used="$(disk_used_pct "$mount_point")"
    
    # Sanity check
    if [[ -z "$used" ]]; then
        log_error "Cannot read disk usage: $mount_point"
        return 2
    fi
    
    # Check disk usage
    if (( used >= err )); then
        log_error "Disk usage too high: ${used}% (error threshold: ${err}%)"
        return 2
    fi
    
    if (( used >= warn )); then
        log_warn "Disk usage high: ${used}% (warning threshold: ${warn}%)"
        return 1
    fi
    
    log_info "Disk usage normal: ${used}%"
    return 0
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    disk_check "${1:-/}"
    rc=$?
    echo "Disk usage: $(disk_used_pct "${1:-/}")% status code: $rc"
    exit $rc
fi
