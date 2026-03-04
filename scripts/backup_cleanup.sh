#!/bin/bash
# scripts/backup_cleanup.sh
# Backup cleanup plugin for TrustMonitor
# Automatically cleans old backup files to prevent disk space issues

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

# Load logger, return codes, and backup manager
source "$BASE_DIR/lib/logger.sh"
source "$BASE_DIR/lib/return_codes.sh"
source "$BASE_DIR/lib/backup_manager.sh"

# Plugin metadata
backup_cleanup_description() {
    echo "Automatically cleans old backup files to prevent disk space issues"
}

# Plugin-specific logging
backup_cleanup_log_info() {
    log_info "[CLEANUP] $1"
}

backup_cleanup_log_warn() {
    log_warn "[CLEANUP] $1"
}

backup_cleanup_log_error() {
    log_error "[CLEANUP] $1"
}

# Check disk space before cleanup
check_disk_space() {
    local usage_threshold=${BACKUP_CLEANUP_DISK_THRESHOLD:-90}
    local current_usage
    current_usage=$(df "$BASE_DIR" | awk 'NR==2 {gsub(/%/,"",$5); print $5}')
    
    backup_cleanup_log_info "Current disk usage: ${current_usage}% (threshold: ${usage_threshold}%)"
    
    if [[ $current_usage -ge $usage_threshold ]]; then
        backup_cleanup_log_warn "Disk usage high (${current_usage}%), forcing cleanup"
        return 0  # Force cleanup
    else
        backup_cleanup_log_info "Disk usage normal, performing routine cleanup"
        return 0  # Still perform routine cleanup
    fi
}

# Backup cleanup check function (plugin interface)
backup_cleanup_check() {
    backup_cleanup_log_info "Starting backup cleanup process..."
    
    # Check disk space
    if ! check_disk_space; then
        backup_cleanup_log_warn "Disk space check failed, proceeding with cleanup anyway"
    fi
    
    # Initialize backup system
    if ! init_backup_dirs; then
        backup_cleanup_log_error "Failed to initialize backup directories"
        return $RC_ERROR
    fi
    
    # Perform cleanup
    local cleanup_result=0
    
    # Clean security backups
    if ! cleanup_security_backups; then
        backup_cleanup_log_error "Security backup cleanup failed"
        cleanup_result=$RC_ERROR
    fi
    
    # Clean demo backups
    if ! cleanup_demo_backups; then
        backup_cleanup_log_error "Demo backup cleanup failed"
        cleanup_result=$RC_ERROR
    fi
    
    # Show final statistics
    get_backup_stats
    
    if [[ $cleanup_result -eq $RC_OK ]]; then
        backup_cleanup_log_info "Backup cleanup completed successfully"
        echo "BACKUP CLEANUP: OK"
        return $RC_OK
    else
        backup_cleanup_log_error "Backup cleanup completed with errors"
        echo "BACKUP CLEANUP: ERROR"
        return $RC_ERROR
    fi
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    backup_cleanup_check
    rc=$?
    echo "Backup cleanup completed with status code: $rc"
    exit $rc
fi
