#!/bin/bash
# scripts/sel_logger.sh
# System Event Log (SEL) for TrustMonitor BMC
# Provides IPMI-style event logging functionality

set -u

# Load TrustMonitor initialization system
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/trustmon_init.sh"

# Initialize this script
init_trustmon_script "sel_logger.sh"

# Load environment variables
load_script_config "sel_logger.sh"

# Plugin metadata
sel_logger_description() {
    echo "System Event Log (SEL) manager for BMC-style event logging and management"
}

# Configuration
SEL_MAX_ENTRIES="${SEL_MAX_ENTRIES:-1000}"           # Maximum log entries
SEL_RETENTION_DAYS="${SEL_RETENTION_DAYS:-30}"       # Log retention period
SEL_LOG_FILE="$RUNTIME_DIR/sel.log"                  # SEL log file
SEL_INDEX_FILE="$RUNTIME_DIR/sel.index"             # SEL index file
SEL_BACKUP_DIR="$BACKUP_DIR/sel"                     # SEL backup directory

# Event types and severity levels
declare -A EVENT_TYPES=(
    ["system"]="System Event"
    ["sensor"]="Sensor Event"
    ["security"]="Security Event"
    ["network"]="Network Event"
    ["power"]="Power Event"
    ["watchdog"]="Watchdog Event"
    ["boot"]="Boot Event"
    ["config"]="Configuration Event"
)

declare -A SEVERITY_LEVELS=(
    ["info"]="Informational"
    ["warning"]="Warning"
    ["critical"]="Critical"
    ["fatal"]="Fatal"
)

# SEL entry format: TIMESTAMP|ID|TYPE|SEVERITY|SOURCE|DESCRIPTION|ACTIONS
# Example: 2024-03-01T12:00:00Z|0001|system|warning|cpu_monitor|CPU load exceeded threshold|restart_service

# Initialize SEL system
init_sel_system() {
    # Create directories
    mkdir -p "$RUNTIME_DIR" "$BACKUP_DIR" "$SEL_BACKUP_DIR"
    
    # Initialize index file
    if [[ ! -f "$SEL_INDEX_FILE" ]]; then
        echo "1" > "$SEL_INDEX_FILE"
    fi
    
    # Initialize log file with header if doesn't exist
    if [[ ! -f "$SEL_LOG_FILE" ]]; then
        cat > "$SEL_LOG_FILE" << 'EOF'
# TrustMonitor System Event Log (SEL)
# Format: TIMESTAMP|ID|TYPE|SEVERITY|SOURCE|DESCRIPTION|ACTIONS
# Generated: $(date)
#
EOF
    fi
}

# Get next event ID
get_next_event_id() {
    local current_id
    current_id="$(cat "$SEL_INDEX_FILE" 2>/dev/null || echo "1")"
    local next_id=$((current_id + 1))
    echo "$next_id" > "$SEL_INDEX_FILE"
    echo "$current_id"
}

# Generate timestamp in ISO 8601 format
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Log event to SEL
log_sel_event() {
    local event_type="$1"
    local severity="$2"
    local source="$3"
    local description="$4"
    local actions="${5:-none}"
    
    # Validate inputs
    if [[ -z "${EVENT_TYPES[$event_type]:-}" ]]; then
        echo "ERROR: Invalid event type: $event_type" >&2
        return 1
    fi
    
    if [[ -z "${SEVERITY_LEVELS[$severity]:-}" ]]; then
        echo "ERROR: Invalid severity level: $severity" >&2
        return 1
    fi
    
    # Get event ID and timestamp
    local event_id timestamp
    event_id="$(get_next_event_id)"
    timestamp="$(get_timestamp)"
    
    # Create log entry
    local entry="$timestamp|$event_id|$event_type|$severity|$source|$description|$actions"
    
    # Write to log file
    echo "$entry" >> "$SEL_LOG_FILE"
    
    # Log to system logger
    log_info "[SEL] Event $event_id: $event_type/$severity from $source - $description"
    
    echo "$event_id"
}

# System event convenience functions
log_system_event() {
    local severity="$1"
    local source="$2"
    local description="$3"
    local actions="${4:-none}"
    log_sel_event "system" "$severity" "$source" "$description" "$actions"
}

log_sensor_event() {
    local severity="$1"
    local source="$2"
    local description="$3"
    local actions="${4:-none}"
    log_sel_event "sensor" "$severity" "$source" "$description" "$actions"
}

log_security_event() {
    local severity="$1"
    local source="$2"
    local description="$3"
    local actions="${4:-none}"
    log_sel_event "security" "$severity" "$source" "$description" "$actions"
}

log_watchdog_event() {
    local severity="$1"
    local source="$2"
    local description="$3"
    local actions="${4:-none}"
    log_sel_event "watchdog" "$severity" "$source" "$description" "$actions"
}

# Query SEL entries
query_sel_events() {
    local filter_type="${1:-all}"
    local filter_severity="${2:-all}"
    local limit="${3:-50}"
    local since="${4:-}"
    
    local awk_filter=""
    
    # Build filter for event type
    if [[ "$filter_type" != "all" ]]; then
        awk_filter="$awk_filter && \$3 == \"$filter_type\""
    fi
    
    # Build filter for severity
    if [[ "$filter_severity" != "all" ]]; then
        awk_filter="$awk_filter && \$4 == \"$filter_severity\""
    fi
    
    # Build filter for time range
    if [[ -n "$since" ]]; then
        awk_filter="$awk_filter && \$1 >= \"$since\""
    fi
    
    # Remove leading " && "
    awk_filter="${awk_filter# && }"
    
    # Query with awk
    if [[ -n "$awk_filter" ]]; then
        awk -F'|' "NR > 4 && ($awk_filter) {print}" "$SEL_LOG_FILE" | tail -n "$limit"
    else
        awk -F'|' 'NR > 4 {print}' "$SEL_LOG_FILE" | tail -n "$limit"
    fi
}

# Generate SEL report
generate_sel_report() {
    local since="${1:-30 days ago}"
    local filter_type="${2:-all}"
    local filter_severity="${3:-all}"
    
    local since_timestamp
    since_timestamp="$(date -d "$since" -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "")"
    
    echo "========================================"
    echo "TrustMonitor System Event Log (SEL) Report"
    echo "Generated: $(date)"
    echo "Period: $since"
    echo "========================================"
    echo ""
    
    # Summary statistics
    echo "Event Summary:"
    local total_events critical_events warning_events info_events
    total_events="$(query_sel_events "$filter_type" "$filter_severity" "10000" "$since_timestamp" | wc -l)"
    critical_events="$(query_sel_events "$filter_type" "critical" "10000" "$since_timestamp" | wc -l)"
    warning_events="$(query_sel_events "$filter_type" "warning" "10000" "$since_timestamp" | wc -l)"
    info_events="$(query_sel_events "$filter_type" "info" "10000" "$since_timestamp" | wc -l)"
    
    echo "  Total Events: $total_events"
    echo "  Critical: $critical_events"
    echo "  Warning: $warning_events"
    echo "  Informational: $info_events"
    echo ""
    
    # Recent events
    echo "Recent Events (last 20):"
    echo "ID    | Timestamp           | Type    | Severity  | Source         | Description"
    echo "------|---------------------|---------|-----------|----------------|-------------"
    
    query_sel_events "$filter_type" "$filter_severity" "20" "$since_timestamp" | \
    awk -F'|' '{
        printf "%-6s| %-19s | %-7s | %-9s | %-14s | %s\n", 
               $2, substr($1, 1, 19), $3, $4, substr($5, 1, 14), $6
    }'
    
    echo ""
    echo "========================================"
}

# Clear SEL entries
clear_sel() {
    local confirm="${1:-false}"
    
    if [[ "$confirm" != "true" ]]; then
        echo "WARNING: This will clear all SEL entries!"
        echo "Use 'clear_sel true' to confirm."
        return 1
    fi
    
    # Backup current log
    local backup_file="$SEL_BACKUP_DIR/sel_backup_$(date +%Y%m%d_%H%M%S).log"
    cp "$SEL_LOG_FILE" "$backup_file"
    
    # Clear log and reset index
    > "$SEL_LOG_FILE"
    echo "1" > "$SEL_INDEX_FILE"
    
    log_info "SEL cleared - backup saved to $backup_file"
    echo "SEL cleared successfully"
}

# Rotate SEL logs
rotate_sel_logs() {
    local current_size
    current_size="$(wc -l < "$SEL_LOG_FILE" 2>/dev/null || echo "0")"
    
    # Check if rotation is needed
    if [[ $current_size -gt $SEL_MAX_ENTRIES ]]; then
        local backup_file="$SEL_BACKUP_DIR/sel_rotate_$(date +%Y%m%d_%H%M%S).log"
        cp "$SEL_LOG_FILE" "$backup_file"
        
        # Keep recent entries
        tail -n "$((SEL_MAX_ENTRIES / 2))" "$SEL_LOG_FILE" > "$SEL_LOG_FILE.tmp"
        mv "$SEL_LOG_FILE.tmp" "$SEL_LOG_FILE"
        
        log_info "SEL rotated - $current_size entries, backup saved to $backup_file"
        echo "SEL rotated successfully"
    else
        echo "SEL rotation not needed ($current_size/$SEL_MAX_ENTRIES entries)"
    fi
}

# Cleanup old SEL backups
cleanup_sel_backups() {
    find "$SEL_BACKUP_DIR" -name "sel_*.log" -mtime "+$SEL_RETENTION_DAYS" -delete 2>/dev/null
    log_info "SEL backup cleanup completed"
}

# SEL health check
sel_health_check() {
    local issues=0
    
    # Check log file exists and is writable
    if [[ ! -f "$SEL_LOG_FILE" ]]; then
        echo "ERROR: SEL log file does not exist"
        ((issues++))
    elif [[ ! -w "$SEL_LOG_FILE" ]]; then
        echo "ERROR: SEL log file is not writable"
        ((issues++))
    fi
    
    # Check index file
    if [[ ! -f "$SEL_INDEX_FILE" ]]; then
        echo "ERROR: SEL index file does not exist"
        ((issues++))
    fi
    
    # Check directory permissions
    if [[ ! -d "$RUNTIME_DIR" ]]; then
        echo "ERROR: Runtime directory does not exist"
        ((issues++))
    fi
    
    # Check log size
    local current_size
    current_size="$(wc -l < "$SEL_LOG_FILE" 2>/dev/null || echo "0")"
    if [[ $current_size -gt $((SEL_MAX_ENTRIES * 9 / 10)) ]]; then
        echo "WARNING: SEL log approaching size limit ($current_size/$SEL_MAX_ENTRIES)"
    fi
    
    if [[ $issues -eq 0 ]]; then
        echo "SEL system healthy"
        return 0
    else
        echo "SEL system has $issues issues"
        return 1
    fi
}

# Main SEL logger function (plugin interface)
sel_logger_check() {
    # Perform health check
    sel_health_check
}

# Main execution
main() {
    local command="${1:-help}"
    
    # Initialize SEL system
    init_sel_system
    
    case "$command" in
        "log")
            if [[ $# -lt 5 ]]; then
                echo "Usage: $0 log <type> <severity> <source> <description> [actions]"
                exit 1
            fi
            log_sel_event "$2" "$3" "$4" "$5" "${6:-none}"
            ;;
        "system")
            if [[ $# -lt 4 ]]; then
                echo "Usage: $0 system <severity> <source> <description> [actions]"
                exit 1
            fi
            log_system_event "$2" "$3" "$4" "${5:-none}"
            ;;
        "security")
            if [[ $# -lt 4 ]]; then
                echo "Usage: $0 security <severity> <source> <description> [actions]"
                exit 1
            fi
            log_security_event "$2" "$3" "$4" "${5:-none}"
            ;;
        "query")
            query_sel_events "${2:-all}" "${3:-all}" "${4:-50}" "${5:-}"
            ;;
        "report")
            generate_sel_report "${2:-30 days ago}" "${3:-all}" "${4:-all}"
            ;;
        "clear")
            clear_sel "${2:-false}"
            ;;
        "rotate")
            rotate_sel_logs
            ;;
        "cleanup")
            cleanup_sel_backups
            ;;
        "health")
            sel_health_check
            ;;
        "check")
            sel_logger_check
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [COMMAND] [OPTIONS]"
            echo ""
            echo "Commands:"
            echo "  log <type> <severity> <source> <description> [actions]  - Log event"
            echo "  system <severity> <source> <description> [actions]     - Log system event"
            echo "  security <severity> <source> <description> [actions]   - Log security event"
            echo "  query [type] [severity] [limit] [since]              - Query events"
            echo "  report [period] [type] [severity]                     - Generate report"
            echo "  clear [confirm]                                       - Clear SEL"
            echo "  rotate                                                - Rotate logs"
            echo "  cleanup                                               - Cleanup backups"
            echo "  health                                                - Health check"
            echo "  check                                                 - Plugin interface"
            echo "  help                                                  - Show help"
            echo ""
            echo "Event Types: ${!EVENT_TYPES[*]}"
            echo "Severity Levels: ${!SEVERITY_LEVELS[*]}"
            ;;
        *)
            echo "Unknown command: $command"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
