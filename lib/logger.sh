#!/bin/bash
# lib/logger.sh
# Unified logger for journald (stdout/stderr)
set -u

# Standardized logging function with component support
_log() {
    local level="$1"
    local message="$2"
    local component="${3:-}"
    local timestamp
    timestamp="$(date -Iseconds)"
    
    if [[ -n "$component" ]]; then
        echo "[$timestamp] [$level] [$component] $message"
    else
        echo "[$timestamp] [$level] $message"
    fi
}

# Standard logging functions (backward compatible)
log_info() { _log "INFO" "$1" "${2:-}"; }
log_warn() { _log "WARN" "$1" "${2:-}"; }
log_error() { _log "ERROR" "$1" "${2:-}"; }

# Enhanced logging with return code (for error handling)
log_error_with_rc() {
    local message="$1"
    local rc="$2"
    local component="${3:-}"
    _log "ERROR" "$message (rc=$rc)" "$component"
}

# Test logging function for test suites
log_test() {
    local level="$1"
    local message="$2"
    local component="${3:-}"
    _log "$level" "$message" "$component"
}