#!/bin/bash
# daemon/health_monitor.sh
# Main orchestrator: load modules, run checks, print results (journald will capture)

set -u

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Load environment file when running manually (development-friendly)
ENV_FILE="$BASE_DIR/config/health-monitor.env"
if [[ -z "${PING_TARGET:-}" && -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

# Add default fallback for all environment variables
: "${PING_TARGET:=8.8.8.8}"
: "${CHECK_INTERVAL:=30}"
: "${INTEGRITY_CHECK_INTERVAL:=3600}"  # Separate interval for integrity checks (1 hour)
: "${CPU_LOAD_WARN:=1.50}"
: "${CPU_LOAD_ERROR:=3.00}"
: "${MEM_AVAIL_WARN_PCT:=15}"
: "${MEM_AVAIL_ERROR_PCT:=5}"
: "${DISK_USED_WARN_PCT:=80}"
: "${DISK_USED_ERROR_PCT:=90}"
: "${CPU_TEMP_WARN:=65.0}"
: "${CPU_TEMP_ERROR:=75.0}"
: "${NETWORK_LATENCY_WARN_MS:=200}"
: "${NETWORK_LATENCY_ERROR_MS:=500}"
: "${NETWORK_PACKET_LOSS_WARN_PCT:=10}"
: "${NETWORK_PACKET_LOSS_ERROR_PCT:=30}"
: "${TEMP_WARNING:=40.0}"
: "${TEMP_ERROR:=45.0}"
: "${HUMIDITY_WARNING:=70.0}"
: "${HUMIDITY_ERROR:=80.0}"
: "${SENSOR_MAX_RETRIES:=3}"
: "${SENSOR_RETRY_DELAY:=1.0}"

# Dependency checking at startup
check_dependencies() {
    local missing_deps=()
    local warning_deps=()
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Checking system dependencies..."
    
    # Check system commands
    local system_commands=("python3" "pip3")
    for cmd in "${system_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    # Check Python packages
    local python_packages=("adafruit_dht" "RPi.GPIO")
    for package in "${python_packages[@]}"; do
        if ! python3 -c "import $package" &> /dev/null; then
            missing_deps+=("python3-$package")
        fi
    done
    
    # Check systemd availability
    if ! command -v systemctl &> /dev/null; then
        warning_deps+=("systemd (service management will be limited)")
    fi
    
    # Check hardware accessibility
    if [[ "$SENSOR_AVAILABLE" == "true" ]]; then
        if ! python3 -c "import adafruit_dht" &> /dev/null; then
            warning_deps+=("GPIO access (may need sudo or hardware not connected)")
        fi
    fi
    
    # Report results
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Missing required dependencies:"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] FATAL: Cannot start without required dependencies"
        exit 1
    fi
    
    if [[ ${#warning_deps[@]} -gt 0 ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: Optional dependencies missing:"
        for dep in "${warning_deps[@]}"; do
            echo "  - $dep"
        done
    fi
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] All required dependencies available"
}

# Overall health aggregation
aggregate_health_status() {
    local network_status="$1"
    local cpu_status="$2"
    local memory_status="$3"
    local disk_status="$4"
    local temp_status="$5"
    local sensor_status="$6"
    
    local overall_status=0
    local components=()
    local warnings=()
    local errors=()
    
    # Aggregate component statuses
    components+=("network:$network_status")
    components+=("cpu:$cpu_status")
    components+=("memory:$memory_status")
    components+=("disk:$disk_status")
    components+=("cpu_temp:$temp_status")
    
    # Handle sensor status if available
    if [[ "$SENSOR_AVAILABLE" == "true" ]]; then
        components+=("sensor:$sensor_status")
    fi
    
    # Determine overall status (worst status wins)
    for component in "${components[@]}"; do
        local name="${component%:*}"
        local status="${component#*:}"
        
        case "$status" in
            0) ;;  # OK, no action needed
            1) 
                warnings+=("$name")
                if [[ $overall_status -lt 1 ]]; then
                    overall_status=1
                fi
                ;;
            2) 
                errors+=("$name")
                overall_status=2
                ;;
            *) 
                errors+=("$name")
                overall_status=2
                ;;
        esac
    done
    
    # Output overall health status
    case "$overall_status" in
        0) 
            log_info "OVERALL HEALTH: OK - All systems operational"
            ;;
        1) 
            log_warn "OVERALL HEALTH: WARNING - Issues detected in: ${warnings[*]}"
            ;;
        2) 
            log_error "OVERALL HEALTH: ERROR - Critical issues in: ${errors[*]}"
            ;;
    esac
    
    return $overall_status
}

# Periodic integrity check mechanism
check_integrity_periodically() {
    local last_check_file="$BASE_DIR/.last_integrity_check"
    local current_time
    current_time=$(date +%s)
    
    # Check if we need to run integrity check
    if [[ -f "$last_check_file" ]]; then
        local last_check_time
        last_check_time=$(cat "$last_check_file" 2>/dev/null || echo "0")
        local time_diff=$((current_time - last_check_time))
        
        if [[ $time_diff -lt $INTEGRITY_CHECK_INTERVAL ]]; then
            # Skip integrity check - not time yet
            return 0
        fi
    fi
    
    # Time to run integrity check
    log_info "Starting periodic integrity check..."
    
    # Execute integrity check in background to avoid blocking monitoring loop
    if integrity_check_check >/dev/null 2>&1; then
        log_info "Periodic integrity check PASSED"
        echo "$current_time" > "$last_check_file"
        return 0
    else
        log_error_with_rc "Periodic integrity check FAILED" $RC_INTEGRITY_FAILED
        # Don't update timestamp on failure to allow retry on next cycle
        return $RC_INTEGRITY_FAILED
    fi
}

# Load monitoring modules using plugin system
source "$BASE_DIR/lib/logger.sh"
source "$BASE_DIR/lib/return_codes.sh"
source "$BASE_DIR/lib/plugin_loader.sh"

# Auto-load all monitoring plugins
PLUGIN_DIR="$BASE_DIR/scripts"
load_plugins_from_dir "$PLUGIN_DIR"

# Load hardware sensor modules (if available)
SENSOR_SCRIPT="$BASE_DIR/hardware/sensor_monitor.py"
if [[ -f "$SENSOR_SCRIPT" ]]; then
    SENSOR_AVAILABLE=true
else
    SENSOR_AVAILABLE=false
    log_warn "Hardware sensor monitoring script not found: $SENSOR_SCRIPT"
fi

# Required environment variables (provided by systemd EnvironmentFile)
: "${PING_TARGET:?PING_TARGET is required (env)}"
: "${CHECK_INTERVAL:?CHECK_INTERVAL is required (env)}"

cleanup() {
  log_info "Health monitor stopping"
  exit 0
}
trap cleanup SIGINT SIGTERM

# Check dependencies before starting
check_dependencies

log_info "Health monitor started"

# Display loaded plugins
plugin_system_info

# --- Secure Boot Sequence (Phase 2 ROT Security) ---
log_info "Starting Secure Boot sequence..."
source "$BASE_DIR/scripts/boot_sequence.sh"

# Execute boot sequence check
if ! boot_sequence_check; then
    log_error_with_rc "Secure Boot sequence failed - system halted" $RC_BOOT_FAILED
    # boot_sequence_check should never return on failure (infinite loop)
    # But if it does, we exit with error
    exit $RC_BOOT_FAILED
fi

log_info "Secure Boot sequence completed successfully - entering monitoring loop"

while true; do
  # Crash simulation hook (for restart testing)
  if [[ "${FORCE_CRASH:-0}" == "1" ]]; then
    log_error_with_rc "Simulating CRASH triggered by FORCE_CRASH env" $RC_ERROR
    exit $RC_ERROR
  fi

  # --- Plugin-based Monitoring ---
  declare -A plugin_results
  
  # Execute all loaded plugins except boot_sequence and integrity_check (handled separately)
  for plugin_name in $(get_loaded_plugins); do
    if [[ "$plugin_name" != "boot_sequence" && "$plugin_name" != "integrity_check" ]]; then
      execute_plugin_check "$plugin_name"
      plugin_results["$plugin_name"]=$?
    fi
  done
  
  # Extract results for aggregation
  network_rc=${plugin_results["network_monitor"]:-$RC_OK}
  cpu_rc=${plugin_results["cpu_monitor"]:-$RC_OK}
  memory_rc=${plugin_results["memory_monitor"]:-$RC_OK}
  disk_rc=${plugin_results["disk_monitor"]:-$RC_OK}
  temp_rc=${plugin_results["cpu_temp_monitor"]:-$RC_OK}
  
  # Get detailed information for logging
  if is_plugin_loaded "network_monitor"; then
    latency=$(network_monitor_latency_ms)
    packet_loss=$(network_monitor_packet_loss_pct)
    case "$network_rc" in
      $RC_OK) log_info  "Network OK (target=$PING_TARGET latency=${latency}ms loss=${packet_loss}%)" ;;
      $RC_WARN) log_warn  "Network WARN (target=$PING_TARGET latency=${latency}ms loss=${packet_loss}%)" ;;
      $RC_ERROR) 
        error_type=$(network_monitor_error_type)
        case "$error_type" in
          "connection_failed")
            log_error_with_rc "Network ERROR (target=$PING_TARGET connection failed)" $RC_NETWORK_FAILED ;;
          "high_latency")
            log_error_with_rc "Network ERROR (target=$PING_TARGET high latency=${latency}ms)" $RC_NETWORK_FAILED ;;
          "high_packet_loss")
            log_error_with_rc "Network ERROR (target=$PING_TARGET high packet loss=${packet_loss}%)" $RC_NETWORK_FAILED ;;
          *)
            log_error_with_rc "Network ERROR (target=$PING_TARGET unknown error)" $RC_NETWORK_FAILED ;;
        esac
        ;;
    esac
  fi
  
  # --- CPU ---
  if is_plugin_loaded "cpu_monitor"; then
    load1=$(cpu_monitor_load1)
    case "$cpu_rc" in
      $RC_OK) log_info  "CPU OK (load1=$load1)" ;;
      $RC_WARN) log_warn  "CPU WARN (load1=$load1 warn>=$CPU_LOAD_WARN)" ;;
      $RC_ERROR) log_error_with_rc "CPU ERROR (load1=$load1 error>=$CPU_LOAD_ERROR)" $RC_ERROR ;;
      *) log_error_with_rc "CPU UNKNOWN (rc=$cpu_rc load1=$load1)" $RC_PLUGIN_ERROR ;;
    esac
  fi

  # --- Memory ---
  if is_plugin_loaded "memory_monitor"; then
    avail_pct="$(memory_monitor_avail_pct)"
    case "$memory_rc" in
      $RC_OK) log_info  "Memory OK (avail=${avail_pct}%)" ;;
      $RC_WARN) log_warn  "Memory WARN (avail=${avail_pct}% warn<=${MEM_AVAIL_WARN_PCT}%)" ;;
      $RC_ERROR) log_error_with_rc "Memory ERROR (avail=${avail_pct}% error<=${MEM_AVAIL_ERROR_PCT}%)" $RC_ERROR ;;
      *) log_error_with_rc "Memory UNKNOWN (rc=$memory_rc avail=${avail_pct}%)" $RC_PLUGIN_ERROR ;;
    esac
  fi

  # --- Disk ---
  if is_plugin_loaded "disk_monitor"; then
    disk_used="$(disk_monitor_used_pct "/")"
    case "$disk_rc" in
      $RC_OK) log_info  "Disk OK (used=${disk_used}%)" ;;
      $RC_WARN) log_warn  "Disk WARN (used=${disk_used}% warn>=${DISK_USED_WARN_PCT}%)" ;;
      $RC_ERROR) log_error_with_rc "Disk ERROR (used=${disk_used}% error>=${DISK_USED_ERROR_PCT}%)" $RC_ERROR ;;
      *) log_error_with_rc "Disk UNKNOWN (rc=$disk_rc used=${disk_used}%)" $RC_PLUGIN_ERROR ;;
    esac
  fi

  # --- CPU Temperature ---
  if is_plugin_loaded "cpu_temp_monitor"; then
    cpu_temp=$(cpu_temp_monitor_value)
    case "$temp_rc" in
      $RC_OK) log_info  "CPU Temperature OK (temp=${cpu_temp}°C)" ;;
      $RC_WARN) log_warn  "CPU Temperature WARN (temp=${cpu_temp}°C warn>=${CPU_TEMP_WARN}°C)" ;;
      $RC_ERROR) log_error_with_rc "CPU Temperature ERROR (temp=${cpu_temp}°C error>=${CPU_TEMP_ERROR}°C)" $RC_ERROR ;;
      *) log_error_with_rc "CPU Temperature UNKNOWN (rc=$temp_rc temp=${cpu_temp}°C)" $RC_PLUGIN_ERROR ;;
    esac
  fi

  # --- Sensor Monitoring ---
  if [[ "$SENSOR_AVAILABLE" == "true" ]]; then
    sensor_rc=$RC_OK
    # Execute sensor monitoring (test mode)
    python3 "$SENSOR_SCRIPT" --test >/dev/null 2>&1 || sensor_rc=$?
    
    case "$sensor_rc" in
      $RC_OK) 
        # Parse sensor reading results
        sensor_output=$(python3 "$SENSOR_SCRIPT" --test 2>&1)
        if echo "$sensor_output" | grep -q "Sensor read successful"; then
          temp=$(echo "$sensor_output" | grep -E "Temperature: ([0-9.]+)°C" | sed -r 's/.*Temperature: ([0-9.]+)°C.*/\1/')
          humidity=$(echo "$sensor_output" | grep -E "Humidity: ([0-9.]+)%" | sed -r 's/.*Humidity: ([0-9.]+)%.*/\1/')
          status=$(echo "$sensor_output" | grep -E "Status: ([a-z]+)" | sed -r 's/.*Status: ([a-z]+).*/\1/')
          log_info "Sensor OK (temp=${temp}°C humidity=${humidity}% status=${status})"
        else
          log_warn "Sensor WARN (Read failed)"
        fi
        ;;
      *) 
        log_error_with_rc "Sensor ERROR (Execution failed)" $RC_SENSOR_ERROR ;;
    esac
  else
    log_warn "Sensor UNAVAILABLE (Script not found)"
  fi

  # --- Periodic Integrity Check ---
  check_integrity_periodically
  integrity_rc=$?

  # --- Overall Health Aggregation ---
  if [[ "$SENSOR_AVAILABLE" == "true" ]]; then
    aggregate_health_status "$network_rc" "$cpu_rc" "$memory_rc" "$disk_rc" "$temp_rc" "$sensor_rc"
  else
    aggregate_health_status "$network_rc" "$cpu_rc" "$memory_rc" "$disk_rc" "$temp_rc" "$RC_OK"
  fi

  sleep "$CHECK_INTERVAL"
done
