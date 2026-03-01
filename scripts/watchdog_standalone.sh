#!/bin/bash
# scripts/watchdog_standalone.sh
# Standalone Watchdog for TrustMonitor (minimal dependencies)

set -u

# Basic configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Configuration with defaults
WATCHDOG_INTERVAL="${WATCHDOG_INTERVAL:-300}"
WATCHDOG_SERVICES="${WATCHDOG_SERVICES:-health-monitor.service}"
WATCHDOG_CPU_THRESHOLD="${WATCHDOG_CPU_THRESHOLD:-5.0}"
WATCHDOG_MEM_THRESHOLD="${WATCHDOG_MEM_THRESHOLD:-1.0}"
WATCHDOG_DISK_THRESHOLD="${WATCHDOG_DISK_THRESHOLD:-95}"

# Runtime directories
RUNTIME_DIR="$PROJECT_ROOT/data/runtime"
WATCHDOG_STATE_DIR="$RUNTIME_DIR/watchdog"
WATCHDOG_STATUS_FILE="$WATCHDOG_STATE_DIR/status"

# Logging
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] [WATCHDOG] $1"
}

log_warn() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] [WATCHDOG] $1"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] [WATCHDOG] $1"
}

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
    
    log_info "Service $service: $status - $details" >&2
    # Return only the status:details format
    echo "$status:$details"
}

# Check system metrics
check_system_metrics() {
    local cpu_load mem_avail disk_used
    local has_alerts=0
    
    # CPU load check
    cpu_load="$(awk '{print $1}' /proc/loadavg)"
    if (( $(awk "BEGIN {print ($cpu_load >= $WATCHDOG_CPU_THRESHOLD)}") )); then
        log_error "CPU load critical: $cpu_load"
        has_alerts=1
    fi
    
    # Memory availability check
    mem_avail="$(awk '/^MemAvailable:/ {printf "%.1f", $2/1024/1024}' /proc/meminfo)"
    if (( $(awk "BEGIN {print ($mem_avail <= $WATCHDOG_MEM_THRESHOLD)}") )); then
        log_error "Memory availability critical: ${mem_avail}GB"
        has_alerts=1
    fi
    
    # Disk usage check
    disk_used="$(df / | awk 'NR==2 {print $5}' | sed 's/%//')"
    if [[ $disk_used -ge $WATCHDOG_DISK_THRESHOLD ]]; then
        log_error "Disk usage critical: ${disk_used}%"
        has_alerts=1
    fi
    
    # Report status
    if [[ $has_alerts -eq 1 ]]; then
        update_watchdog_status "system_critical" "System alerts detected"
        return 1
    else
        log_info "System metrics within normal thresholds"
        return 0
    fi
}

# Main watchdog check function
watchdog_check() {
    log_info "Starting watchdog check cycle"
    
    # Initialize state
    init_watchdog_state
    
    local overall_status=0
    
    # Check service health
    log_info "Checking critical services..."
    for service in $WATCHDOG_SERVICES; do
        local service_result
        service_result="$(check_service_health "$service" 2>/dev/null)"
        local service_status="${service_result%%:*}"
        
        if [[ "$service_status" != "active" ]]; then
            log_warn "Service $service is not active"
            overall_status=1
        fi
    done
    
    # Check system metrics
    log_info "Checking system metrics..."
    if ! check_system_metrics; then
        overall_status=1
    fi
    
    # Update overall status
    if [[ $overall_status -eq 0 ]]; then
        update_watchdog_status "healthy" "All checks passed"
        log_info "Watchdog check completed - all systems healthy"
    else
        update_watchdog_status "issues_detected" "Issues detected during checks"
        log_warn "Watchdog check completed - issues detected"
    fi
    
    return $overall_status
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

# Main execution
main() {
    local command="${1:-check}"
    
    # Load environment if available
    if [[ -f "$PROJECT_ROOT/config/health-monitor.env" ]]; then
        source "$PROJECT_ROOT/config/health-monitor.env"
    fi
    
    case "$command" in
        "check")
            watchdog_check
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
            echo "Usage: $0 [check|report|status|help]"
            echo ""
            echo "Commands:"
            echo "  check   - Run single watchdog check"
            echo "  report  - Generate detailed watchdog report"
            echo "  status  - Show current watchdog status"
            echo "  help    - Show this help"
            ;;
        *)
            log_error "Unknown command: $command"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Plugin compatibility function
watchdog_standalone_check() {
    watchdog_check
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
