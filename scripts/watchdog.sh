#!/bin/bash
# scripts/watchdog.sh
# BMC Watchdog System for TrustMonitor
# Monitors system health and takes corrective actions

set -u

# Load TrustMonitor initialization system
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/trustmon_init.sh"

# Initialize this script
init_trustmon_script "watchdog.sh"

# Load environment variables
load_script_config "watchdog.sh"

# Plugin metadata
watchdog_description() {
    echo "BMC Watchdog system that monitors critical components and takes corrective actions"
}

# Configuration
WATCHDOG_INTERVAL="${WATCHDOG_INTERVAL:-60}"           # Check interval (seconds)
WATCHDOG_TIMEOUT="${WATCHDOG_TIMEOUT:-300}"           # Service timeout (seconds)
WATCHDOG_MAX_RETRIES="${WATCHDOG_MAX_RETRIES:-3}"     # Max retry attempts
WATCHDOG_RECOVERY_DELAY="${WATCHDOG_RECOVERY_DELAY:-10}" # Delay between retries (seconds)

# Critical services to monitor
WATCHDOG_SERVICES="${WATCHDOG_SERVICES:-health-monitor.service}"

# System thresholds
WATCHDOG_CPU_THRESHOLD="${WATCHDOG_CPU_THRESHOLD:-5.0}"      # CPU load threshold
WATCHDOG_MEM_THRESHOLD="${WATCHDOG_MEM_THRESHOLD:-10}"      # Memory availability threshold
WATCHDOG_DISK_THRESHOLD="${WATCHDOG_DISK_THRESHOLD:-95}"     # Disk usage threshold

# Logging functions
watchdog_log_info() {
    log_info "[WATCHDOG] $1"
}

watchdog_log_warn() {
    log_warn "[WATCHDOG] $1"
}

watchdog_log_error() {
    log_error "[WATCHDOG] $1"
}

# Watchdog state file management
WATCHDOG_STATE_DIR="$RUNTIME_DIR/watchdog"
WATCHDOG_STATUS_FILE="$WATCHDOG_STATE_DIR/status.json"
WATCHDOG_LAST_CHECK="$WATCHDOG_STATE_DIR/last_check"

# Initialize watchdog state
init_watchdog_state() {
    mkdir -p "$WATCHDOG_STATE_DIR"
    
    if [[ ! -f "$WATCHDOG_STATUS_FILE" ]]; then
        cat > "$WATCHDOG_STATUS_FILE" << 'EOF'
# TrustMonitor Watchdog Status
# Format: key=value
status=initialized
last_check=null
last_action=System initialized
EOF
    fi
}

# Update watchdog status
update_watchdog_status() {
    local status="$1"
    local details="$2"
    local timestamp
    timestamp="$(date -Iseconds)"
    
    # Simple status update without JSON to avoid Python dependency issues
    {
        echo "status=$status"
        echo "last_check=$timestamp"
        echo "last_action=$details"
    } > "$WATCHDOG_STATUS_FILE"
}

# Check service health
check_service_health() {
    local service="$1"
    local status="unknown"
    local details=""
    
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl is-active --quiet "$service"; then
            status="active"
            details="Service is running normally"
        else
            status="inactive"
            details="Service is not running"
        fi
    else
        status="unknown"
        details="systemctl not available"
    fi
    
    watchdog_log_info "Service $service: $status - $details" >&2
    echo "$status:$details"
}

# Restart service with retry logic
restart_service() {
    local service="$1"
    local retry_count=0
    local max_retries="$WATCHDOG_MAX_RETRIES"
    
    watchdog_log_warn "Attempting to restart service: $service"
    
    while [[ $retry_count -lt $max_retries ]]; do
        ((retry_count++))
        
        watchdog_log_info "Restart attempt $retry_count/$max_retries for $service"
        
        if command -v systemctl >/dev/null 2>&1; then
            systemctl restart "$service"
            sleep "$WATCHDOG_RECOVERY_DELAY"
            
            if systemctl is-active --quiet "$service"; then
                watchdog_log_info "Service $service restarted successfully (attempt $retry_count)"
                update_watchdog_status "service_restarted" "$service restarted on attempt $retry_count"
                return 0
            else
                watchdog_log_warn "Service $service restart failed (attempt $retry_count)"
            fi
        fi
        
        if [[ $retry_count -lt $max_retries ]]; then
            sleep "$WATCHDOG_RECOVERY_DELAY"
        fi
    done
    
    watchdog_log_error "Failed to restart service $service after $max_retries attempts"
    update_watchdog_status "service_restart_failed" "$service failed to restart after $max_retries attempts"
    return 1
}

# Check system metrics
check_system_metrics() {
    local cpu_load mem_avail disk_used
    local has_alerts=0
    
    # CPU load check
    cpu_load="$(awk '{print $1}' /proc/loadavg)"
    if (( $(awk "BEGIN {print ($cpu_load >= $WATCHDOG_CPU_THRESHOLD)}") )); then
        watchdog_log_error "CPU load critical: $cpu_load"
        has_alerts=1
    fi
    
    # Memory availability check
    mem_avail="$(awk '/^MemAvailable:/ {printf "%.1f", $2/1024/1024}' /proc/meminfo)"
    if (( $(awk "BEGIN {print ($mem_avail <= $WATCHDOG_MEM_THRESHOLD)}") )); then
        watchdog_log_error "Memory availability critical: ${mem_avail}GB"
        has_alerts=1
    fi
    
    # Disk usage check
    disk_used="$(df / | awk 'NR==2 {print $5}' | sed 's/%//')"
    if [[ $disk_used -ge $WATCHDOG_DISK_THRESHOLD ]]; then
        watchdog_log_error "Disk usage critical: ${disk_used}%"
        has_alerts=1
    fi
    
    # Report status
    if [[ $has_alerts -eq 1 ]]; then
        update_watchdog_status "system_critical" "System alerts detected"
        return 1
    else
        watchdog_log_info "System metrics within normal thresholds"
        return 0
    fi
}

# Check for hung processes
check_hung_processes() {
    local hung_count=0
    
    # Count processes in uninterruptible sleep state
    while IFS= read -r pid; do
        if [[ -n "$pid" ]]; then
            ((hung_count++))
        fi
    done < <(ps aux | awk '$8 ~ /D/ && $1 != "root" {print $2}' 2>/dev/null)
    
    if [[ $hung_count -gt 0 ]]; then
        watchdog_log_warn "Found $hung_count processes in uninterruptible sleep"
        update_watchdog_status "hung_processes" "Found $hung_count hung processes"
    fi
}

# Generate watchdog report
generate_watchdog_report() {
    local timestamp
    timestamp="$(date)"
    
    cat << EOF
========================================
TrustMonitor Watchdog Report
Generated: $timestamp
========================================

Service Status:
$(systemctl status "$WATCHDOG_SERVICES" --no-pager 2>/dev/null || echo "Service status unavailable")

System Metrics:
- CPU Load: $(awk '{print $1}' /proc/loadavg)
- Memory Available: $(awk '/^MemAvailable:/ {printf "%.1f GB", $2/1024/1024}' /proc/meminfo)
- Disk Usage: $(df / | awk 'NR==2 {print $5}')

Recent Actions:
$(cat "$WATCHDOG_STATUS_FILE" 2>/dev/null || echo "No recent actions")

========================================
EOF
}

# Main watchdog check function
watchdog_check() {
    watchdog_log_info "Starting watchdog check cycle"
    
    # Initialize state
    init_watchdog_state
    
    # Update last check time
    date +%s > "$WATCHDOG_LAST_CHECK"
    
    local overall_status=0
    
    # Check service health
    watchdog_log_info "Checking critical services..."
    for service in $WATCHDOG_SERVICES; do
        local service_result
        service_result="$(check_service_health "$service" 2>/dev/null)"
        local service_status="${service_result%%:*}"
        
        if [[ "$service_status" != "active" ]]; then
            watchdog_log_warn "Service $service is not active, attempting restart"
            if restart_service "$service"; then
                watchdog_log_info "Service $service restarted successfully"
            else
                watchdog_log_error "Failed to restart service $service"
                overall_status=1
            fi
        fi
    done
    
    # Check system metrics
    watchdog_log_info "Checking system metrics..."
    if ! check_system_metrics; then
        watchdog_log_warn "System metrics show issues"
        overall_status=1
    fi
    
    # Check for hung processes
    watchdog_log_info "Checking for hung processes..."
    check_hung_processes
    
    # Update overall status
    if [[ $overall_status -eq 0 ]]; then
        update_watchdog_status "healthy" "All checks passed"
        watchdog_log_info "Watchdog check completed - all systems healthy"
    else
        update_watchdog_status "issues_detected" "Issues detected during checks"
        watchdog_log_warn "Watchdog check completed - issues detected"
    fi
    
    return $overall_status
}

# Watchdog daemon mode
watchdog_daemon() {
    watchdog_log_info "Starting watchdog daemon mode"
    watchdog_log_info "Check interval: ${WATCHDOG_INTERVAL}s"
    watchdog_log_info "Timeout threshold: ${WATCHDOG_TIMEOUT}s"
    
    while true; do
        watchdog_check
        sleep "$WATCHDOG_INTERVAL"
    done
}

# Main execution
main() {
    local command="${1:-check}"
    
    case "$command" in
        "check")
            watchdog_check
            ;;
        "daemon")
            watchdog_daemon
            ;;
        "report")
            generate_watchdog_report
            ;;
        "status")
            if [[ -f "$WATCHDOG_STATUS_FILE" ]]; then
                cat "$WATCHDOG_STATUS_FILE"
            else
                echo "Watchdog status file not found"
            fi
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [check|daemon|report|status|help]"
            echo ""
            echo "Commands:"
            echo "  check   - Run single watchdog check"
            echo "  daemon  - Run watchdog in daemon mode"
            echo "  report  - Generate detailed watchdog report"
            echo "  status  - Show current watchdog status"
            echo "  help    - Show this help"
            ;;
        *)
            watchdog_log_error "Unknown command: $command"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
