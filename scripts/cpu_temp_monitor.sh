#!/bin/bash
# CPU Temperature Monitoring Plugin
# ===============================
# Purpose: Monitor CPU temperature
# Returns: 0=OK, 1=WARN, 2=ERROR

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

# Set temperature thresholds
CPU_TEMP_WARN=${CPU_TEMP_WARN:-65.0}
CPU_TEMP_ERROR=${CPU_TEMP_ERROR:-75.0}

# Plugin metadata
cpu_temp_monitor_description() {
    echo "Monitors CPU temperature with floating point precision and configurable thresholds"
}

# CPU temperature reading
cpu_temp_monitor_read_cpu_temp() {
    local temp_file="/sys/class/thermal/thermal_zone0/temp"
    if [[ -f "$temp_file" ]]; then
        local temp_raw
        temp_raw=$(cat "$temp_file" 2>/dev/null)
        if [[ "$temp_raw" =~ ^[0-9]+$ ]]; then
            awk "BEGIN {printf \"%.1f\", $temp_raw/1000}"
        else
            echo "0.0"
        fi
    else
        echo "0.0"
    fi
}

# CPU temperature check
cpu_temp_monitor_check() {
    local cpu_temp
    
    cpu_temp=$(cpu_temp_monitor_read_cpu_temp)
    
    # Compare with thresholds
    if (( $(awk "BEGIN {print ($cpu_temp >= $CPU_TEMP_ERROR)}") )); then
        log_error_with_rc "CPU temperature too high: ${cpu_temp}°C (error threshold: ${CPU_TEMP_ERROR}°C)" $RC_ERROR
        echo "CPU Temperature CRITICAL (temp=${cpu_temp}°C)"
        return $RC_ERROR
    elif (( $(awk "BEGIN {print ($cpu_temp >= $CPU_TEMP_WARN)}") )); then
        log_warn "CPU temperature high: ${cpu_temp}°C (warning threshold: ${CPU_TEMP_WARN}°C)"
        echo "CPU Temperature WARN (temp=${cpu_temp}°C)"
        return $RC_WARN
    else
        log_info "CPU temperature normal: ${cpu_temp}°C"
        echo "CPU Temperature OK (temp=${cpu_temp}°C)"
        return $RC_OK
    fi
}

# Provide temperature value for other scripts
cpu_temp_monitor_value() {
    cpu_temp_monitor_read_cpu_temp
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    # Load logger and return codes
    source "$BASE_DIR/lib/logger.sh"
    source "$BASE_DIR/lib/return_codes.sh"
    
    cpu_temp_monitor_check
    rc=$?
    echo "CPU temperature: $(cpu_temp_monitor_value)°C status code: $rc"
    exit $rc
fi