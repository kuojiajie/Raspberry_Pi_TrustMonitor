#!/bin/bash
# CPU Temperature Monitoring Script
# ===================
# Purpose: Monitor CPU temperature
# Returns: 0=OK, 1=WARN, 2=ERROR

set -u

# Global variables
SCRIPT_NAME="CPU Temperature Monitor"

# Load settings
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load environment variables (if exists)
ENV_FILE="$BASE_DIR/config/health-monitor.env"
if [[ -f "$ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$ENV_FILE"
fi

# Set temperature thresholds
CPU_TEMP_WARN=${CPU_TEMP_WARN:-65.0}
CPU_TEMP_ERROR=${CPU_TEMP_ERROR:-75.0}

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

# CPU temperature reading
read_cpu_temp() {
    local temp_file="/sys/class/thermal/thermal_zone0/temp"
    if [[ -f "$temp_file" ]]; then
        local temp_raw
        temp_raw=$(cat "$temp_file")
        # Use awk for floating point division, then round to 1 decimal place
        awk "BEGIN {printf \"%.1f\", $temp_raw / 1000}"
    else
        echo "0"
    fi
}

# CPU temperature check
cpu_temp_check() {
    local cpu_temp
    
    cpu_temp=$(read_cpu_temp)
    
    # Convert thresholds to float for comparison
    local warn_float=$(awk "BEGIN {printf \"%.1f\", $CPU_TEMP_WARN}")
    local error_float=$(awk "BEGIN {printf \"%.1f\", $CPU_TEMP_ERROR}")
    
    # Check temperature range using awk for floating point comparison
    local comparison_result=$(awk "BEGIN {print ($cpu_temp >= $error_float) ? 2 : (($cpu_temp >= $warn_float) ? 1 : 0)}")
    
    case "$comparison_result" in
        2) 
            log_error "CPU temperature too high: ${cpu_temp}°C (error threshold: ${CPU_TEMP_ERROR}°C)"
            return 2
            ;;
        1) 
            log_warn "CPU temperature high: ${cpu_temp}°C (warning threshold: ${CPU_TEMP_WARN}°C)"
            return 1
            ;;
        *) 
            log_info "CPU temperature normal: ${cpu_temp}°C"
            return 0
            ;;
    esac
}

# Provide temperature value for other scripts
cpu_temp_value() {
    read_cpu_temp
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    cpu_temp_check
    rc=$?
    echo "CPU temperature: $(cpu_temp_value)°C status code: $rc"
    exit $rc
fi