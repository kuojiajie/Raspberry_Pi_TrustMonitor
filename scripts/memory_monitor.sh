#!/bin/bash
# Memory Monitoring Script
# ===================
# Purpose: Monitor system memory usage
# Returns: 0=OK, 1=WARN, 2=ERROR

set -u

# Global variables
SCRIPT_NAME="Memory Monitor"

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

# Memory reading functions
mem_total_kb() {
    awk '/^MemTotal:/ {print $2}' /proc/meminfo
}

mem_avail_kb() {
    awk '/^MemAvailable:/ {print $2}' /proc/meminfo
}

mem_avail_pct() {
    local total avail
    
    total="$(mem_total_kb)"
    avail="$(mem_avail_kb)"
    
    # Sanity check
    if [[ -z "$total" || "$total" -le 0 || -z "$avail" ]]; then
        echo "0"
        return
    fi
    
    echo $(( avail * 100 / total ))
}

# Memory check
memory_check() {
    local warn_pct err_pct avail_pct
    
    warn_pct="${MEM_AVAIL_WARN_PCT:-15}"
    err_pct="${MEM_AVAIL_ERROR_PCT:-5}"
    avail_pct="$(mem_avail_pct)"
    
    # Check memory availability
    if (( avail_pct <= err_pct )); then
        log_error "Memory availability too low: ${avail_pct}% (error threshold: ${err_pct}%)"
        return 2
    fi
    
    if (( avail_pct <= warn_pct )); then
        log_warn "Memory availability low: ${avail_pct}% (warning threshold: ${warn_pct}%)"
        return 1
    fi
    
    log_info "Memory availability normal: ${avail_pct}%"
    return 0
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    memory_check
    rc=$?
    echo "Memory availability: $(mem_avail_pct)% status code: $rc"
    exit $rc
fi
